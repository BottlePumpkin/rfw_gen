# rfw_gen Dynamic Features (DSL Extension) Design

## 1. Problem Statement

rfw 패키지(`package:rfw`)는 다음 동적 기능을 공식 지원한다:

| rfwtxt 기능 | 문법 예시 |
|---|---|
| 데이터 바인딩 | `data.user.name` |
| 인자 참조 | `args.item.title` |
| 상태 참조 | `state.isOpen` |
| 상태 변경 | `set state.isOpen = true` |
| for 루프 | `...for item in data.items:` |
| switch 조건부 | `switch data.status { ... }` |
| 이벤트 동적 페이로드 | `event "tap" { id: args.item.id }` |
| 문자열 연결 | `["Hello, ", data.name]` |
| 위젯 상태 선언 | `widget Btn { down: false }` |

rfw_gen은 현재 **정적 값만** rfwtxt로 변환 가능하다. Flutter 개발자가 위 동적 기능을 사용하려면 rfwtxt를 직접 작성해야 하며, 이는 rfw_gen의 목적("Flutter 코드로 작성하면 자동 변환")에 반한다.

### 목표

Flutter 개발자가 rfwtxt 문법을 몰라도, Dart 헬퍼 클래스를 통해 rfw의 모든 동적 기능을 표현할 수 있도록 한다.

## 2. Design Approach

### 빌드 타임 마커 클래스

Dart 헬퍼 클래스를 `rfw_gen` 패키지에 추가한다. 이 클래스들은:

- **빌드 타임에만 의미가 있다** — AST 분석기가 생성자 호출을 인식하고 rfwtxt로 변환
- **런타임에는 관여하지 않는다** — 생성된 rfwtxt가 CDN 등으로 전달되어 `parseLibraryFile()`로 파싱됨
- **`dev_dependencies`로 추가** — 앱 바이너리에 포함되지 않음

### 타입 처리

- `RfwFor`, `RfwSwitch` → `StatelessWidget` extend (위젯 트리의 children에 배치 가능)
- `RfwSwitchValue<T>` → 일반 클래스 (값 위치에서 switch 사용 시)
- `DataRef`, `ArgsRef`, `StateRef`, `LoopVar`, `RfwConcat` → 일반 클래스
- 타입 불일치 (예: `Text(DataRef(...))`) → `// ignore_for_file: argument_type_not_assignable`로 처리
- `@RfwWidget` 함수는 build_runner 전용이므로, 런타임 실행은 고려하지 않음

## 3. Helper Class API

### 3.1 DataRef / ArgsRef / StateRef (값 참조)

```dart
class DataRef {
  final String path;
  const DataRef(this.path);
}

class ArgsRef {
  final String path;
  const ArgsRef(this.path);
}

class StateRef {
  final String path;
  const StateRef(this.path);
}
```

**사용 예시:**

```dart
Text(DataRef('user.name'))              // → Text(text: data.user.name)
Text(ArgsRef('item.title'))             // → Text(text: args.item.title)
Container(color: StateRef('bgColor'))   // → Container(color: state.bgColor)
```

### 3.2 LoopVar (for 루프 변수)

rfw 공식 문법에서 for 루프 변수는 prefix 없이 참조된다:

```rfwtxt
...for item in data.items:
    ListTile(title: Text(text: item.name)),
```

이를 위해 `LoopVar` 클래스를 제공한다:

```dart
class LoopVar {
  final String name;
  const LoopVar(this.name);
  LoopVar operator [](String path) => LoopVar('$name.$path');
}
```

`RfwFor`의 `builder` 콜백 파라미터로 사용된다.

**제한사항:** `LoopVar`는 `RfwFor.builder` 내부에서만 유효하다. 외부에서 사용 시 빌드 타임 에러를 발생시킨다.

### 3.3 RfwFor (리스트 반복)

```dart
class RfwFor extends StatelessWidget {
  final Object items;       // DataRef 또는 ArgsRef
  final String itemName;
  final Widget Function(LoopVar) builder;

  const RfwFor({
    required this.items,
    required this.itemName,
    required this.builder,
    super.key,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

**사용 예시:**

```dart
Column(
  children: [
    Text('Header'),
    RfwFor(
      items: DataRef('items'),
      itemName: 'item',
      builder: (item) => ListTile(
        title: Text(item['name']),          // → item.name
        subtitle: Text(item['description']), // → item.description
      ),
    ),
  ],
)
```

**생성 rfwtxt:**

```rfwtxt
Column(
  children: [
    Text(text: "Header"),
    ...for item in data.items:
      ListTile(
        title: Text(text: item.name),
        subtitle: Text(text: item.description),
      ),
  ],
)
```

**제한사항:** `builder`는 단일 위젯만 반환한다. rfw 공식 문법에서 `...for`는 반복당 하나의 위젯을 생성한다.

### 3.4 RfwSwitch / RfwSwitchValue (조건부 렌더링/값)

위젯 위치와 값 위치에서의 타입 충돌을 해결하기 위해 두 클래스를 제공한다:

**RfwSwitch — 위젯 위치용 (children, child 등):**

```dart
class RfwSwitch extends StatelessWidget {
  final Object value;                      // DataRef, ArgsRef, StateRef, LoopVar
  final Map<Object, Widget> cases;
  final Widget? defaultCase;

  const RfwSwitch({
    required this.value,
    required this.cases,
    this.defaultCase,
    super.key,
  });

  @override
  Widget build(BuildContext context) => const SizedBox();
}
```

**RfwSwitchValue<T> — 값 위치용 (padding, color 등):**

```dart
class RfwSwitchValue<T> {
  final Object value;                      // DataRef, ArgsRef, StateRef, LoopVar
  final Map<Object, T> cases;
  final T? defaultCase;

  const RfwSwitchValue({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}
```

**사용 예시 — 위젯 위치 (RfwSwitch):**

```dart
RfwSwitch(
  value: DataRef('status'),
  cases: {
    'active': Container(color: Color(0xFF00FF00)),
    'inactive': Container(color: Color(0xFFFF0000)),
  },
  defaultCase: SizedBox(),
)
```

**사용 예시 — 값 위치 (RfwSwitchValue):**

```dart
Container(
  padding: RfwSwitchValue(
    value: ArgsRef('index'),
    cases: {
      0: EdgeInsets.all(16),
      1: EdgeInsets.all(8),
    },
    defaultCase: EdgeInsets.all(4),
  ),
)
```

**생성 rfwtxt (동일):**

```rfwtxt
switch data.status {
  "active": Container(color: 0xFF00FF00),
  "inactive": Container(color: 0xFFFF0000),
  default: SizedBox(),
}

switch args.index {
  0: [16.0],
  1: [8.0],
  default: [4.0],
}
```

AST 분석기는 `RfwSwitch`와 `RfwSwitchValue` 모두 동일한 `IrSwitchExpr`로 변환한다.

### 3.5 RfwConcat (문자열 연결)

```dart
class RfwConcat {
  final List<Object> parts;  // String, DataRef, ArgsRef, LoopVar
  const RfwConcat(this.parts);
}
```

**사용 예시:**

```dart
Text(RfwConcat(['Hello, ', DataRef('user.name'), '!']))
// → Text(text: ["Hello, ", data.user.name, "!"])
```

### 3.6 RfwStateDecl (위젯 상태 선언)

`@RfwWidget` 어노테이션에 `state` 파라미터를 추가한다:

```dart
class RfwWidget {
  final String name;
  final Map<String, dynamic>? state;
  const RfwWidget(this.name, {this.state});
}
```

**사용 예시:**

```dart
@RfwWidget('toggleButton', state: {'down': false})
Widget toggleButton() {
  return GestureDetector(
    onTapDown: RfwHandler.setState('down', true),
    onTapUp: RfwHandler.setState('down', false),
    child: Container(
      color: RfwSwitch(
        value: StateRef('down'),
        cases: {true: Color(0xFFFF0000)},
        defaultCase: Color(0xFF00FF00),
      ),
    ),
  );
}
```

**생성 rfwtxt:**

```rfwtxt
widget toggleButton { down: false } = GestureDetector(
  onTapDown: set state.down = true,
  onTapUp: set state.down = false,
  child: Container(
    color: switch state.down {
      true: 0xFFFF0000,
      default: 0xFF00FF00,
    },
  ),
);
```

### 3.7 RfwHandler 확장 (동적 이벤트 페이로드)

기존 `RfwHandler.event()`의 args에서 `DataRef`/`ArgsRef`/`LoopVar`를 허용한다. 중첩 맵 리터럴도 지원한다:

```dart
RfwHandler.event('onTap', {
  'landingAction': {'url': ArgsRef('item.landingUrl')},
  'event': {
    'eventName': 'main_service',
    'eventProps': {'code': ArgsRef('item.serviceCode')},
  },
  'count': 1,
})
```

**생성 rfwtxt:**

```rfwtxt
event "onTap" {
  landingAction: {url: args.item.landingUrl},
  event: {eventName: "main_service", eventProps: {code: args.item.serviceCode}},
  count: 1,
}
```

기존 정적 값 페이로드는 하위 호환 유지.

## 4. Implementation Scope

### 신규 파일

| 파일 | 내용 |
|------|------|
| `lib/src/rfw_helpers.dart` | `DataRef`, `ArgsRef`, `StateRef`, `LoopVar`, `RfwFor`, `RfwSwitch`, `RfwSwitchValue`, `RfwConcat` |

### 수정 파일

| 파일 | 변경 |
|------|------|
| `lib/src/ir.dart` | sealed class `IrValue`에 추가: `IrDataRef(path)`, `IrArgsRef(path)`, `IrStateRef(path)`, `IrLoopVarRef(path)`, `IrForLoop(items, itemName, body)`, `IrSwitchExpr(value, cases, defaultCase)`, `IrConcat(parts)`, `IrStateDecl(fields)` |
| `lib/src/expression_converter.dart` | `convert()` 메서드에 `DataRef`, `ArgsRef`, `StateRef`, `RfwConcat`, `LoopVar[]`, `RfwSwitchValue` 인식 추가. `MethodInvocation`과 `InstanceCreationExpression` 모두 처리. `SetOrMapLiteral` 지원 추가 (중첩 맵). `convertHandler()` 내부의 `_convertEvent()`에서 event args의 동적 참조 지원 — `convert()`를 재귀 호출하여 `DataRef`/`ArgsRef` 인식 |
| `lib/src/ast_visitor.dart` | `_convertWidget()`에서 `RfwFor`, `RfwSwitch` 생성자를 위젯이 아닌 특수 IR 노드로 변환 |
| `lib/src/rfwtxt_emitter.dart` | `_emitValue()` switch에 새 IR 타입별 emit 추가: `IrDataRef` → `data.path`, `IrArgsRef` → `args.path`, `IrStateRef` → `state.path`, `IrLoopVarRef` → `path` (prefix 없음), `IrForLoop` → `...for ... in ...:`, `IrSwitchExpr` → `switch ... { ... }`, `IrConcat` → `[..., ...]`. `emit()` 시그니처에 `Map<String, IrValue>? stateDecl` 파라미터 추가 → `widget name { ... } =` 출력 |
| `lib/src/annotations.dart` | `RfwWidget`에 `state` optional 파라미터 추가 |
| `lib/src/converter.dart` | `convertFromAst()`에서 `@RfwWidget`의 state 추출 후 emitter의 `emit(stateDecl: ...)` 전달. `_collectImports()`에서 `IrForLoop`, `IrSwitchExpr`, `IrConcat` 내부 순회 추가 |
| `lib/src/rfw_handler.dart` | `RfwEvent.args`의 value 타입을 `dynamic`으로 유지하되, `DataRef`/`ArgsRef`/`LoopVar` 인스턴스 허용 |

### 변경하지 않는 파일

- `WidgetRegistry` — 커스텀 위젯 등록 기능과 무관
- 기존 정적 변환 로직 — 모든 기존 테스트 통과 유지 (하위 호환)

## 5. Testing Strategy

CLAUDE.md 규칙: "rfwtxt 출력은 반드시 `parseLibraryFile()`로 파싱 검증"

### 단위 테스트

- `rfw_helpers_test.dart` — 헬퍼 클래스 생성자, LoopVar `[]` 연산자
- `expression_converter_test.dart` — DataRef/ArgsRef/StateRef/RfwConcat/LoopVar/RfwSwitchValue 인식, SetOrMapLiteral 처리
- `rfwtxt_emitter_test.dart` — 새 IR 타입별 rfwtxt 출력 정확성, stateDecl이 포함된 emit() 출력

### 통합 테스트 (`integration_test.dart`)

각 기능별 Dart 소스 → rfwtxt → `parseLibraryFile()` 파싱 검증:

1. DataRef 단독 사용
2. ArgsRef 단독 사용
3. StateRef + RfwHandler.setState 조합
4. RfwFor + LoopVar 조합
5. RfwSwitch (위젯 위치)
6. RfwSwitchValue (값 위치)
7. RfwConcat
8. @RfwWidget state 선언
9. RfwHandler.event 동적 페이로드 (중첩 맵 포함)
10. 복합: RfwFor 내부에 RfwSwitch + DataRef + 이벤트

## 6. End-to-End Usage Example

```dart
// ignore_for_file: argument_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('home_service_area')
Widget homeServiceArea() {
  return SkeletonConditionalWidget(
    target: DataRef('serviceList'),
    child: Column(
      children: [
        RfwFor(
          items: DataRef('serviceList'),
          itemName: 'service',
          builder: (service) => Padding(
            padding: EdgeInsets.all(16),
            child: ServiceList(service: service),
          ),
        ),
      ],
    ),
  );
}

@RfwWidget('serviceCard')
Widget serviceCard() {
  return SZSBounceTapper(
    onTap: RfwHandler.event('onTap', {
      'landingAction': {'url': ArgsRef('item.landingUrl')},
      'event': {
        'eventName': 'main_service',
        'eventProps': {'code': ArgsRef('item.serviceCode')},
      },
    }),
    child: RfwSwitch(
      value: ArgsRef('item.status'),
      cases: {
        'ACTIVE': Container(
          color: Color(0xFF4169FF),
          child: Text(ArgsRef('item.title')),
        ),
        'INACTIVE': Container(
          color: Color(0xFF888888),
          child: Text('서비스 준비중'),
        ),
      },
      defaultCase: SizedBox(),
    ),
  );
}
```

**생성 rfwtxt:**

```rfwtxt
import core.widgets;
import custom.widgets;

widget home_service_area = SkeletonConditionalWidget(
  target: data.serviceList,
  child: Column(
    children: [
      ...for service in data.serviceList:
        Padding(
          padding: [16.0],
          child: ServiceList(service: service),
        ),
    ],
  ),
);

widget serviceCard = SZSBounceTapper(
  onTap: event "onTap" {
    landingAction: {url: args.item.landingUrl},
    event: {eventName: "main_service", eventProps: {code: args.item.serviceCode}},
  },
  child: switch args.item.status {
    "ACTIVE": Container(
      color: 0xFF4169FF,
      child: Text(text: args.item.title),
    ),
    "INACTIVE": Container(
      color: 0xFF888888,
      child: Text(text: "서비스 준비중"),
    ),
    default: SizedBox(),
  },
);
```
