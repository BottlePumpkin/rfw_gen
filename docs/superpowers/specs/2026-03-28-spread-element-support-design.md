# SpreadElement 지원 (#79)

**Issue**: #79 — Spread operator on RfwFor crashes builder with unhelpful internal error
**Date**: 2026-03-28
**Scope**: packages/rfw_gen_builder

## 문제

children 리스트에서 `...RfwFor()` 스프레드 구문 사용 시 `SpreadElementImpl is not a subtype of Expression in type cast` 크래시.

## 원인

`ast_visitor.dart`의 children 처리 2곳에서 list elements를 `e as Expression`으로 캐스트. `SpreadElement`는 `Expression`이 아닌 `CollectionElement` 서브타입이므로 캐스트 실패.

## 설계

### 변경: ast_visitor.dart (2곳)

Line 226 (named child slots):
```dart
// Before
.map((e) => _convertWidgetOrSpecial(e as Expression))

// After
.map((e) => _convertWidgetOrSpecial(
  e is SpreadElement ? e.expression : (e as Expression)
))
```

Line 251 (regular children):
```dart
// 동일 변경
```

`SpreadElement.expression`은 스프레드 내부의 실제 표현식 (e.g., `RfwFor(...)`)을 반환하므로, 기존 `_convertWidgetOrSpecial()` 로직이 그대로 적용됨.

## 테스트

### 단위 테스트 (ast_visitor_test.dart)

```dart
test('converts spread RfwFor in children list', () {
  final fn = parseFunction('''
Widget build() {
  return Column(
    children: [
      Text('Header'),
      ...RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Text(item['name']),
      ),
    ],
  );
}
''');
  final root = visitor.extractWidgetTree(fn) as IrWidgetNode;
  final children = root.properties['children'] as IrListValue;
  expect(children.values, hasLength(2));
  expect(children.values[0], isA<IrWidgetNode>());
  expect(children.values[1], isA<IrForLoop>());
});
```

### 통합 테스트 (integration_test.dart)

```dart
test('spread RfwFor in children produces parseable rfwtxt', () {
  const source = '''
Widget buildList() {
  return ListView(
    children: [
      Text('Header'),
      ...RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => ListTile(title: Text(item['name'])),
      ),
    ],
  );
}
''';
  final result = converter.convertFromSource(source);
  expect(result.rfwtxt, contains('...for item in data.items'));
  expect(result.rfwtxt, contains('Text(\n      text: "Header"'));
  expect(() => parseLibraryFile(result.rfwtxt), returnsNormally);
});
```

## 수정 범위

| 파일 | 변경 | 규모 |
|------|------|------|
| `ast_visitor.dart` | SpreadElement 언래핑 (2곳) | ~4줄 |
| `ast_visitor_test.dart` | spread RfwFor 테스트 | ~15줄 |
| `integration_test.dart` | spread rfwtxt 파싱 테스트 | ~20줄 |
