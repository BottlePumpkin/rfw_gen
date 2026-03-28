# RfwSwitch 루트 위젯 지원

**Issue**: #57 — RfwSwitch build error: 'not registered' despite being documented in README
**Date**: 2026-03-26
**Scope**: packages/rfw_gen_builder

## 문제

`RfwSwitch`를 `@RfwWidget` 함수의 루트 위젯으로 사용하면 `UnsupportedWidgetError: RfwSwitch is not registered` 에러 발생.

```dart
@RfwWidget('typingIndicator', state: {'isTyping': false})
Widget buildTypingIndicator() {
  return RfwSwitch(  // ← "not registered" 에러
    value: StateRef('isTyping'),
    cases: {
      true: Container(child: Text('입력 중...')),
      false: SizedBox(height: 0.0),
    },
  );
}
```

## 원인

`extractWidgetTree()`(ast_visitor.dart:45)가 루트 표현식을 `_convertWidget()`으로 직접 처리. 이 메서드는 WidgetRegistry에서 위젯 이름을 조회하므로 특수 헬퍼인 RfwSwitch를 인식하지 못함.

반면, children 리스트 내에서는 `_convertWidgetOrSpecial()`을 통해 처리되어 RfwSwitch/RfwFor가 정상 동작.

## RFW 파서 지원 확인

RFW 파서(`rfw-1.1.3/lib/src/dart/text.dart`)의 `_readWidgetDeclaration()`은 루트에서 switch를 명시적으로 지원:

```dart
_expectSymbol(_SymbolToken.equals);
if (_foundIdentifier('switch')) {
  root = _readSwitch(switchStart);  // 루트 switch 허용
} else {
  root = _readConstructorCall();
}
```

테스트도 존재: `parseLibraryFile('widget a = switch 0 { 0: a() };')`

따라서 rfw_gen_builder만 수정하면 루트 RfwSwitch가 동작.

## 설계

### 변경 1: ast_visitor.dart — extractWidgetTree()

반환 타입을 `IrWidgetNode` → `IrValue`로 변경하고, `_convertWidgetOrSpecial()`을 호출.

**Before** (line 45):
```dart
IrWidgetNode extractWidgetTree(FunctionDeclaration function) {
  final expr = _findReturnExpression(function);
  if (expr == null) { ... }
  return _convertWidget(expr);
}
```

**After**:
```dart
IrValue extractWidgetTree(FunctionDeclaration function) {
  final expr = _findReturnExpression(function);
  if (expr == null) { ... }
  return _convertWidgetOrSpecial(expr);
}
```

### 변경 2: rfwtxt_emitter.dart — emit()

root 파라미터 타입을 `IrWidgetNode` → `IrValue`로 변경. 루트가 `IrSwitchExpr`이면 `_emitSwitchExpr()`로 emit.

**Before** (line 10):
```dart
String emit({
  required String widgetName,
  required IrWidgetNode root,
  ...
})
```

**After**:
```dart
String emit({
  required String widgetName,
  required IrValue root,
  ...
})
```

위젯 선언 emit 부분 (line 37):
```dart
// Before
buffer.write(_emitWidget(root, indent: 0));

// After
buffer.write(_emitValue(root, indent: 0));
```

`_emitValue()`는 이미 `IrWidgetNode`, `IrSwitchExpr`, `IrForLoop` 등 모든 `IrValue` 서브타입을 처리하므로 추가 로직 불필요.

### 변경 3: extractWidgetTree() 호출부

`extractWidgetTree()`를 호출하는 코드에서 반환 타입 변경에 맞게 수정. `emit()`에 전달하는 부분이 주 대상.

## 생성될 rfwtxt

```rfwtxt
widget typingIndicator { isTyping: false } = switch state.isTyping {
  true: Container(
    child: Text(text: "입력 중..."),
  ),
  false: SizedBox(
    height: 0.0,
  ),
};
```

## 테스트

### 단위 테스트 (ast_visitor_test.dart)

```dart
test('converts RfwSwitch at root position', () {
  final fn = parseFunction('''
Widget build() {
  return RfwSwitch(
    value: StateRef('isTyping'),
    cases: {
      true: Container(),
      false: SizedBox(),
    },
  );
}
''');
  final root = visitor.extractWidgetTree(fn);
  expect(root, isA<IrSwitchExpr>());
  final sw = root as IrSwitchExpr;
  expect(sw.cases, hasLength(2));
});
```

### 통합 테스트 (integration_test.dart)

```dart
test('RfwSwitch at root produces parseable rfwtxt', () {
  const source = '''
Widget buildToggle() {
  return RfwSwitch(
    value: StateRef('active'),
    cases: {
      true: Text('Active'),
      false: Text('Inactive'),
    },
  );
}
''';
  final result = converter.convertFromSource(source);
  expect(result.rfwtxt, contains('switch state.active'));
  expect(() => parseLibraryFile(result.rfwtxt), returnsNormally);
});
```

### RfwFor 루트 테스트 (보너스)

동일 원인으로 RfwFor도 루트에서 사용 불가할 수 있음. 함께 테스트 추가:

```dart
test('RfwFor at root produces parseable rfwtxt', () {
  const source = '''
Widget buildList() {
  return RfwFor(
    items: DataRef('items'),
    itemName: 'item',
    builder: (item) => Text(item['name']),
  );
}
''';
  final result = converter.convertFromSource(source);
  expect(result.rfwtxt, contains('...for item in data.items'));
  expect(() => parseLibraryFile(result.rfwtxt), returnsNormally);
});
```

## 수정 범위

| 파일 | 변경 내용 | 규모 |
|------|-----------|------|
| `ast_visitor.dart` | `extractWidgetTree()` 반환 타입 + 호출 변경 | ~2줄 |
| `rfwtxt_emitter.dart` | `emit()` root 타입 + emit 호출 변경 | ~2줄 |
| 호출부 (builder 내) | 타입 변경에 맞게 수정 | ~1-3줄 |
| `ast_visitor_test.dart` | 루트 RfwSwitch 테스트 추가 | ~15줄 |
| `integration_test.dart` | 루트 RfwSwitch + RfwFor 파싱 테스트 추가 | ~30줄 |

총 변경: ~50줄 이내
