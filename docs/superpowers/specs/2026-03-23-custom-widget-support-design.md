# Custom Widget Support for rfw_gen

## 배경

rfw_gen은 현재 56개 내장 위젯(38 core + 1 GestureDetector + 17 Material)을 지원한다.
프로덕션(3o3)에서는 `MystiqueText`, `SZSBounceTapper`, `NullConditionalWidget` 등 37+ 커스텀 위젯을 사용하고 있어, 범용 패키지로서 커스텀 위젯 등록 기능이 필요하다.

## 3o3 프로덕션 RFW 사용 현황

- rfwtxt 파일 70개, ~12,390 lines
- 4개 import: `core.widgets`, `material.widgets`, `mystique.widgets`, `custom.widgets`
- 커스텀 위젯 37개:
  - **단순 렌더링** (13개): `MystiqueText`, `MystiqueTag`, `MystiqueIcon`, `MystiqueFillIcon`, `MystiqueOutlineIcon`, `MystiqueBadge`, `MystiqueTransBadge`, `NetworkImage`, `DummySkeletonBox`, `SkeletonBanner`, `ProgressBar`, `MystiqueProgressStepper`, `MystiqueSpinner`
  - **인터랙션** (6개): `SZSBounceTapper`, `MystiqueBoxButton`, `MystiqueButton`, `MystiqueOutlineButton`, `MystiqueCtaButtonSocialKakao`, `SZSBounceTapperIgnoreArea`
  - **조건부 렌더링** (6개): `NullConditionalWidget`, `SkeletonConditionalWidget`, `ListConditionalWidget`, `TimeConditionalWidget`, `CompareWidget`, `ConditionalWidget`
  - **레이아웃** (5개): `CustomColumn`, `CustomRow`, `CustomSingleChildScrollView`, `CustomPositioned`, `SkeletonContainer`
  - **데이터/유틸** (4개): `ApiGetBuilder`, `CalcBuilder`, `PvContainer`, `DevStgWidget`
  - **기타** (3개): `SkeletonListCardLarge`, `SkeletonListGroupCardLarge`, `SZSBannerAdViewContainer`

### 파라미터 타입 분석 결과

프로덕션 커스텀 위젯 파라미터를 분석한 결과:

| 파라미터 타입 | 변환 필요 여부 | 설명 |
|-------------|--------------|------|
| 문자열, 숫자, 불리언 | 불필요 | rfwtxt에서 그대로 사용 |
| Color (`0xFFxxxxxx`) | 불필요 | 이미 hex int 형식으로 작성 |
| EdgeInsets (`[16.0, 8.0]`) | 불필요 | 이미 리스트 형식으로 작성 |
| Enum (`"center"`) | 불필요 | 이미 문자열 형식으로 작성 |
| data/args 참조 | 불필요 | 표준 RFW 구문 |
| **이벤트 핸들러** | **선언 필요** | `event 'name' {...}` 구문은 핸들러로 인식해야 변환 가능 |
| **위젯-값 파라미터** | **자동 감지** | `nullChild: Widget(...)` 같은 패턴은 코드 레벨에서 처리 |

**결론**: 파라미터 매핑(transformer)은 불필요. 핸들러 파라미터 선언만 추가하면 됨.

## 설계 결정

### 등록 방식: `rfw_gen.yaml` 별도 설정 파일

검토한 대안:
- ~~어노테이션 (`@RfwCustomWidget`)~~: 외부 패키지 위젯에 붙일 수 없고, `LocalWidgetLibrary` 빌더 함수로 등록한 위젯은 클래스 자체가 없을 수 있음
- ~~Dart 코드 등록~~: build_runner에 커스텀 레지스트리를 주입하는 방식이 까다로움
- ~~`build.yaml` options~~: build_runner 전용 — MCP 서버(v0.3)에서 별도 로직 필요, 키 이름 고정 문제
- **`rfw_gen.yaml` 별도 파일**: build_runner와 MCP 서버 모두 같은 파일을 읽을 수 있음. 스키마를 완전히 우리가 제어. build.yaml이 깔끔하게 유지됨

### 파라미터 매핑: 불필요 (pass-through)

커스텀 위젯의 파라미터는 rfwtxt에서 그대로 사용되는 값이다.
`Colors.white → 0xFFFFFFFF` 같은 변환은 core 위젯 전용이며, `expressionConverter.convert()`가 이미 처리한다.
커스텀 위젯은 **이름/import/child 타입/핸들러**만 등록하면 된다.

현재 `ast_visitor.dart:176-183`에서 unknown parameter를 이미 `expressionConverter`로 pass-through하고 있어서 구조적 변경이 최소화된다.

### 핸들러 파라미터: 선언 필요

프로덕션 분석 결과 6개 위젯이 이벤트 핸들러를 사용:

| 위젯 | 핸들러 |
|------|--------|
| SZSBounceTapper | `onTap` |
| MystiqueBoxButton | `onPressed` |
| MystiqueButton | `onPressed` |
| MystiqueOutlineButton | `onPressed` |
| MystiqueCtaButtonSocialKakao | `onPressed` |
| PvContainer | `onPv` |

핸들러를 선언하지 않으면 `event 'name' {...}` 구문이 `expressionConverter.convert()`로 처리되어 `UnsupportedExpressionError` → 무시됨. `convertHandler()`로 라우팅하려면 핸들러임을 알아야 한다.

## 사용자 인터페이스

### rfw_gen.yaml 설정

프로젝트 루트(`pubspec.yaml` 옆)에 `rfw_gen.yaml` 파일을 생성:

```yaml
# rfw_gen.yaml
widgets:
  MystiqueText:
    import: mystique.widgets
  MystiqueTag:
    import: mystique.widgets
  MystiqueIcon:
    import: mystique.widgets
  SZSBounceTapper:
    import: custom.widgets
    child_type: optionalChild
    handlers: [onTap]
  MystiqueBoxButton:
    import: mystique.widgets
    handlers: [onPressed]
  NullConditionalWidget:
    import: custom.widgets
    child_type: optionalChild
  SkeletonConditionalWidget:
    import: custom.widgets
    child_type: optionalChild
  ListConditionalWidget:
    import: custom.widgets
    child_type: optionalChild
  PvContainer:
    import: custom.widgets
    child_type: optionalChild
    handlers: [onPv]
```

각 위젯에 필요한 필드:

| 필드 | 필수 | 기본값 | 설명 |
|------|------|--------|------|
| `import` | O | - | rfwtxt import 라이브러리 이름 |
| `child_type` | X | `none` | `none`, `child`, `optionalChild`, `childList` (`namedSlots`는 미지원 — 에러 발생) |
| `child_param` | X | child_type에 따라 `child`/`children` | child 파라미터 이름 |
| `handlers` | X | `[]` | 이벤트 핸들러 파라미터 이름 리스트 |

파일이 없으면 에러 없이 core + material 위젯만 사용.

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

### 위젯-값 파라미터 예시

```dart
@RfwWidget('conditionalCard')
Widget buildConditionalCard() {
  return NullConditionalWidget(
    child: MystiqueText(text: 'hello'),
    nullChild: MystiqueText(text: '고객님'),  // ← 자동 감지, 선언 불필요
  );
}
```

```rfwtxt
import custom.widgets;
import mystique.widgets;

widget conditionalCard = NullConditionalWidget(
  child: MystiqueText(text: "hello"),
  nullChild: MystiqueText(text: "고객님")
);
```

### 핸들러 예시

```dart
@RfwWidget('tapCard')
Widget buildTapCard() {
  return SZSBounceTapper(
    onTap: RfwHandler.event('navigate', {'url': 'szsapp://home'}),
    child: MystiqueText(text: 'tap me'),
  );
}
```

```rfwtxt
import custom.widgets;
import mystique.widgets;

widget tapCard = SZSBounceTapper(
  onTap: event "navigate" { url: "szsapp://home" },
  child: MystiqueText(text: "tap me")
);
```

## 구현 항목

### 1. rfw_gen.yaml 파싱 + WidgetRegistry 연동

**파일**: `packages/rfw_gen/lib/src/widget_registry.dart`, `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`

core 패키지에 `registerFromConfig()` 메서드를 추가하여 build_runner와 MCP 서버 모두에서 재사용:

```dart
// widget_registry.dart
class WidgetRegistry {
  /// YAML config의 widgets Map을 파싱해서 등록.
  void registerFromConfig(Map<String, dynamic> widgetsConfig) {
    for (final entry in widgetsConfig.entries) {
      final name = entry.key;
      final config = entry.value as Map<String, dynamic>? ?? {};

      // import 필드 필수 검증
      final importLib = config['import'] as String?;
      if (importLib == null) {
        throw ArgumentError(
          'Widget "$name" in rfw_gen.yaml is missing required "import" field',
        );
      }

      final childType = _parseChildType(config['child_type'] as String?);
      final handlers = (config['handlers'] as List?)
          ?.cast<String>().toSet() ?? const <String>{};

      // child_param 기본값: child_type에 따라 자동 결정
      final childParam = config['child_param'] as String? ??
          (childType == ChildType.child || childType == ChildType.optionalChild
              ? 'child'
              : childType == ChildType.childList
                  ? 'children'
                  : null);

      register(name, WidgetMapping(
        rfwName: name,
        import: importLib,
        childType: childType,
        childParam: childParam,
        params: const {},
        handlerParams: handlers,
      ));
    }
  }

  static ChildType _parseChildType(String? value) => switch (value) {
    'child' => ChildType.child,
    'optionalChild' => ChildType.optionalChild,
    'childList' => ChildType.childList,
    'namedSlots' => throw ArgumentError(
      'namedSlots is not supported for custom widgets in rfw_gen.yaml',
    ),
    _ => ChildType.none,
  };
}
```

```dart
// rfw_widget_builder.dart
@override
FutureOr<void> build(BuildStep buildStep) async {
  final registry = WidgetRegistry.core();

  // rfw_gen.yaml에서 커스텀 위젯 로드
  final configId = AssetId(buildStep.inputId.package, 'rfw_gen.yaml');
  if (await buildStep.canRead(configId)) {
    final yamlStr = await buildStep.readAsString(configId);
    final yaml = loadYaml(yamlStr) as Map;
    final widgets = yaml['widgets'] as Map?;
    if (widgets != null) {
      registry.registerFromConfig(Map<String, dynamic>.from(widgets));
    }
  }

  final converter = RfwConverter(registry: registry);
  // ... 이하 기존 코드
}
```

### 2. 위젯-값 파라미터 자동 감지

**파일**: `packages/rfw_gen/lib/src/ast_visitor.dart`

**문제**: `nullChild`, `errorChild`, `emptyOrNullChild` 같은 위젯-값 파라미터가 `expressionConverter.convert()` 실패로 무시됨.

**해결**: unknown param 처리에서 등록된 위젯이면 재귀 변환:

```dart
// ast_visitor.dart _processNamedArgument의 step 5 (현재 lines 176-183)
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

이미 구현된 import 자동 수집(`converter.dart:74 _collectImports()`)이 IR 트리를 재귀 순회하므로, 위젯-값 파라미터에 사용된 커스텀 위젯의 import도 자동으로 수집된다.

## 구현 순서

1. **위젯-값 파라미터 자동 감지** — 커스텀 위젯 없이도 테스트 가능, 기존 core/material 위젯에도 적용
2. **rfw_gen.yaml 파싱 + registerFromConfig()** — core 패키지에 파싱 로직, builder에서 파일 읽기
3. **통합 테스트** — 커스텀 위젯 등록 + pass-through + 위젯-값 파라미터 + 핸들러 + import 생성

## 프로젝트 구조 (엔드유저)

```
my_app/
  pubspec.yaml
  rfw_gen.yaml          ← 커스텀 위젯 설정
  build.yaml            ← build_runner 설정 (rfw_gen 관련 옵션 없음)
  lib/
    widgets.dart        ← @RfwWidget 함수들
    widgets.rfwtxt      ← 자동 생성
    widgets.rfw         ← 자동 생성
```

## Config 공유: build_runner + MCP 서버

```dart
// build_runner
final yaml = loadYaml(await buildStep.readAsString(configId));
registry.registerFromConfig(yaml['widgets']);

// MCP 서버 (v0.3)
final yaml = loadYaml(File('rfw_gen.yaml').readAsStringSync());
registry.registerFromConfig(yaml['widgets']);

// 직접 API 호출
registry.registerFromConfig({'MyWidget': {'import': 'my.widgets'}});
```

세 곳 모두 같은 `registerFromConfig()` 메서드를 사용.

## 범위 외 (향후 고려)

- `data.xxx` 바인딩 표현: Dart 코드에서 rfwtxt의 `data.user.name` 참조를 어떻게 표현할지
- `state.xxx` / `event` 핸들러: 상태 관리와 이벤트 바인딩 코드젠
- `...for` 루프 / `switch` 표현식: rfwtxt 제어 구문 생성
- Builder 함수 패턴: `ABTestBuilder`, `CalcBuilder` 같은 빌더 패턴 지원
