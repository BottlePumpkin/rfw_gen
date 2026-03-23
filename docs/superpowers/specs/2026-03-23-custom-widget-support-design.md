# Custom Widget Support for rfw_gen

## 배경

rfw_gen은 현재 6개 core 위젯(Text, Column, Row, Container, SizedBox, Center)만 지원한다.
프로덕션(3o3)에서는 `MystiqueText`, `SZSBounceTapper`, `NullConditionalWidget` 등 40+ 커스텀 위젯을 사용하고 있어, 범용 패키지로서 커스텀 위젯 등록 기능이 필요하다.

## 3o3 프로덕션 RFW 사용 현황

- rfwtxt 파일 70개, ~12,390 lines
- 4개 import: `core.widgets`, `material.widgets`, `mystique.widgets`, `custom.widgets`
- 커스텀 위젯 유형:
  - **단순 렌더링**: `MystiqueText`, `MystiqueTag`, `MystiqueIcon`, `NetworkImage`
  - **인터랙션**: `SZSBounceTapper`, `MystiqueBoxButton`
  - **조건부 렌더링**: `NullConditionalWidget`, `SkeletonConditionalWidget`, `ListConditionalWidget`
  - **데이터/유틸**: `ApiGetBuilder`, `CalcBuilder`, `PvContainer`
- 커스텀 위젯 파라미터는 대부분 문자열/숫자/불리언 — Flutter→rfwtxt 변환(transformer)이 필요 없음

## 설계 결정

### 등록 방식: `build.yaml` options (YAML 선언)

검토한 대안:
- ~~어노테이션 (`@RfwCustomWidget`)~~: 외부 패키지 위젯에 붙일 수 없고, `LocalWidgetLibrary` 빌더 함수로 등록한 위젯은 클래스 자체가 없을 수 있음
- ~~Dart 코드 등록~~: build_runner에 커스텀 레지스트리를 주입하는 방식이 까다로움
- **YAML 선언**: build_runner 표준 방식(`build.yaml` options)으로 자연스럽게 전달 가능. 커스텀 위젯 매핑은 본질적으로 선언적 데이터(이름 + import + child 타입)

### 파라미터 매핑: 불필요 (pass-through)

커스텀 위젯의 파라미터는 대부분 rfwtxt에서 그대로 사용되는 값(문자열, 숫자 등)이다.
Flutter→rfwtxt 변환이 필요한 건 `Colors.white → 0xFFFFFFFF` 같은 core 위젯 전용 케이스뿐.
따라서 커스텀 위젯은 **파라미터 매핑 없이 이름/import/child 타입 3개만** 등록하면 된다.

현재 `ast_visitor.dart:149-155`에서 unknown parameter를 이미 pass-through하고 있어서 구조적 변경이 최소화된다.

## 사용자 인터페이스

### build.yaml 설정

```yaml
targets:
  $default:
    builders:
      rfw_gen_builder:
        options:
          custom_widgets:
            MystiqueText:
              import: mystique.widgets
            SZSBounceTapper:
              import: custom.widgets
              child_type: optionalChild
            NullConditionalWidget:
              import: custom.widgets
              child_type: optionalChild
            SkeletonConditionalWidget:
              import: custom.widgets
              child_type: optionalChild
```

각 위젯에 필요한 필드:

| 필드 | 필수 | 기본값 | 설명 |
|------|------|--------|------|
| `import` | O | - | rfwtxt import 라이브러리 이름 |
| `child_type` | X | `none` | `none`, `child`, `optionalChild`, `childList` |
| `child_param` | X | `child`/`children` | child 파라미터 이름 (기본값은 child_type에 따라 결정) |

### Dart 코드 (변경 없음)

```dart
@RfwWidget('myCard')
Widget buildMyCard() {
  return Container(
    child: MystiqueText(text: 'hello', fontType: 'heading24Bold'),
  );
}
```

### rfwtxt 출력

```rfwtxt
import core.widgets;
import mystique.widgets;

widget myCard = Container(
  child: MystiqueText(text: "hello", fontType: "heading24Bold")
);
```

## 구현 항목

### 1. build.yaml에서 custom_widgets 읽기

**파일**: `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`

현재:
```dart
final converter = RfwConverter(registry: WidgetRegistry.core());
```

변경: `BuilderOptions.config`에서 `custom_widgets` 맵을 읽어서 `registry.register()` 호출.

```dart
final registry = WidgetRegistry.core();
final customWidgets = options.config['custom_widgets'] as Map<String, dynamic>?;
if (customWidgets != null) {
  for (final entry in customWidgets.entries) {
    final config = entry.value as Map<String, dynamic>;
    registry.register(entry.key, WidgetMapping(
      rfwName: entry.key,
      import: config['import'] as String,
      childType: _parseChildType(config['child_type'] as String?),
      childParam: config['child_param'] as String?,
      params: const {},
    ));
  }
}
final converter = RfwConverter(registry: registry);
```

### 2. import 자동 수집

**파일**: `packages/rfw_gen/lib/src/converter.dart`

현재:
```dart
imports: {'core.widgets'},  // 하드코딩
```

변경: IR 트리를 순회하면서 사용된 위젯의 import를 수집.

```dart
Set<String> _collectImports(IrWidgetNode root) {
  final imports = <String>{};
  void visit(IrValue value) {
    if (value is IrWidgetNode) {
      final mapping = registry.supportedWidgets[value.name];
      if (mapping != null) imports.add(mapping.import);
      for (final prop in value.properties.values) {
        visit(prop);
      }
    } else if (value is IrListValue) {
      for (final item in value.values) {
        visit(item);
      }
    }
  }
  visit(root);
  return imports;
}
```

### 3. 위젯-값 파라미터 자동 감지 (핵심 발견)

**파일**: `packages/rfw_gen/lib/src/ast_visitor.dart`

**문제**: 3o3에서 아래 패턴을 많이 씀:
```dart
NullConditionalWidget(
  child: MystiqueText(text: 'hello'),       // ← child로 처리됨 ✅
  nullChild: MystiqueText(text: '고객님'),   // ← unknown param → 위젯인데 expressionConverter 실패 → 조용히 무시 ❌
)
```

`nullChild`, `errorChild`, `emptyOrNullChild` 같은 **child가 아닌 위젯-값 파라미터**가 출력에서 사라진다.
같은 문제가 `Scaffold`의 `appBar`, `body`, `floatingActionButton` 등 named slot에도 해당.

**해결**: `_processNamedArgument`의 unknown param 처리에서, 값이 등록된 위젯이면 위젯으로 변환:

```dart
// ast_visitor.dart _processNamedArgument의 마지막 부분 (lines 149-155)
// 현재:
try {
  final value = expressionConverter.convert(expression);
  properties[paramName] = value;
} on UnsupportedExpressionError {
  // Silently skip.
}

// 변경:
if (expression is MethodInvocation &&
    expression.target == null &&
    registry.isSupported(expression.methodName.name)) {
  properties[paramName] = _convertWidget(expression);
} else {
  try {
    final value = expressionConverter.convert(expression);
    properties[paramName] = value;
  } on UnsupportedExpressionError {
    // Silently skip.
  }
}
```

이 수정으로 YAML에 별도 선언 없이도 위젯-값 파라미터가 자동으로 재귀 변환된다.

## 구현 순서

1. 위젯-값 파라미터 자동 감지 (3번) — 커스텀 위젯 없이도 core 위젯의 named slot 문제를 해결
2. import 자동 수집 (2번) — 하드코딩 제거
3. build.yaml custom_widgets 읽기 (1번) — 커스텀 위젯 등록 연동
4. 테스트: 커스텀 위젯 등록 + pass-through + 위젯-값 파라미터 + import 생성

## 범위 외 (향후 고려)

- `data.xxx` 바인딩 표현: Dart 코드에서 rfwtxt의 `data.user.name` 참조를 어떻게 표현할지
- `state.xxx` / `event` 핸들러: 상태 관리와 이벤트 바인딩 코드젠
- `...for` 루프 / `switch` 표현식: rfwtxt 제어 구문 생성
- 별도 `rfw_gen.yaml` 파일 분리: 커스텀 위젯이 많아질 경우
