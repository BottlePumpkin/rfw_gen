# Dynamic Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable rfw_gen to convert Dart helper classes (`DataRef`, `ArgsRef`, `RfwFor`, `RfwSwitch`, etc.) into rfwtxt dynamic features (`data.*`, `args.*`, `...for`, `switch`, etc.).

**Architecture:** Build-time marker classes added to `rfw_gen` package. AST visitor recognizes these class constructors and converts to new IR nodes. Emitter outputs the corresponding rfwtxt syntax. All new rfwtxt output is validated with `parseLibraryFile()`.

**Tech Stack:** Dart, `package:analyzer` (AST parsing), `package:rfw` (parseLibraryFile validation)

**Spec:** `docs/superpowers/specs/2026-03-23-dynamic-features-design.md`

---

### Task 1: IR Nodes for Dynamic References

Add new `IrValue` subclasses for `data.*`, `args.*`, `state.*`, and loop variable references.

**Files:**
- Modify: `packages/rfw_gen/lib/src/ir.dart`
- Test: `packages/rfw_gen/test/ir_test.dart`

- [ ] **Step 1: Write failing tests for new IR nodes**

```dart
// In test/ir_test.dart — add to existing file
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  // ... existing tests ...

  group('dynamic reference IR nodes', () {
    test('IrDataRef stores path', () {
      final ref = IrDataRef('user.name');
      expect(ref.path, 'user.name');
      expect(ref, isA<IrValue>());
    });

    test('IrArgsRef stores path', () {
      final ref = IrArgsRef('item.title');
      expect(ref.path, 'item.title');
      expect(ref, isA<IrValue>());
    });

    test('IrStateRef stores path', () {
      final ref = IrStateRef('isOpen');
      expect(ref.path, 'isOpen');
      expect(ref, isA<IrValue>());
    });

    test('IrLoopVarRef stores path without prefix', () {
      final ref = IrLoopVarRef('item.name');
      expect(ref.path, 'item.name');
      expect(ref, isA<IrValue>());
    });

    test('IrConcat stores list of parts', () {
      final concat = IrConcat([
        IrStringValue('Hello, '),
        IrDataRef('user.name'),
        IrStringValue('!'),
      ]);
      expect(concat.parts, hasLength(3));
      expect(concat, isA<IrValue>());
    });

    test('IrForLoop stores items, itemName, and body', () {
      final loop = IrForLoop(
        items: IrDataRef('items'),
        itemName: 'item',
        body: IrWidgetNode(name: 'Text'),
      );
      expect(loop.items, isA<IrDataRef>());
      expect(loop.itemName, 'item');
      expect(loop.body, isA<IrWidgetNode>());
      expect(loop, isA<IrValue>());
    });

    test('IrSwitchExpr stores value, cases, and defaultCase', () {
      final sw = IrSwitchExpr(
        value: IrDataRef('status'),
        cases: {
          IrStringValue('active'): IrWidgetNode(name: 'SizedBox'),
        },
        defaultCase: IrWidgetNode(name: 'SizedBox'),
      );
      expect(sw.value, isA<IrDataRef>());
      expect(sw.cases, hasLength(1));
      expect(sw.defaultCase, isNotNull);
      expect(sw, isA<IrValue>());
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/ir_test.dart`
Expected: Compilation errors — `IrDataRef`, `IrArgsRef`, etc. are not defined.

- [ ] **Step 3: Implement new IR nodes**

Add to `packages/rfw_gen/lib/src/ir.dart` after the existing `IrEventValue` class:

```dart
/// A `data.path` reference to DynamicContent.
class IrDataRef extends IrValue {
  final String path;
  IrDataRef(this.path);
}

/// An `args.path` reference to widget constructor arguments.
class IrArgsRef extends IrValue {
  final String path;
  IrArgsRef(this.path);
}

/// A `state.path` reference to widget-local state.
class IrStateRef extends IrValue {
  final String path;
  IrStateRef(this.path);
}

/// A loop variable reference (no prefix). Used inside `...for` loops.
class IrLoopVarRef extends IrValue {
  final String path;
  IrLoopVarRef(this.path);
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
class IrConcat extends IrValue {
  final List<IrValue> parts;
  IrConcat(this.parts);
}

/// A `...for item in source: body` loop.
class IrForLoop extends IrValue {
  final IrValue items;      // IrDataRef or IrArgsRef
  final String itemName;
  final IrWidgetNode body;
  IrForLoop({required this.items, required this.itemName, required this.body});
}

/// A `switch value { case1: result1, default: resultN }` expression.
class IrSwitchExpr extends IrValue {
  final IrValue value;       // IrDataRef, IrArgsRef, IrStateRef, IrLoopVarRef
  final Map<IrValue, IrValue> cases;
  final IrValue? defaultCase;
  IrSwitchExpr({required this.value, required this.cases, this.defaultCase});
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/ir_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/ir.dart packages/rfw_gen/test/ir_test.dart
git commit -m "feat: add IR nodes for dynamic references (DataRef, ArgsRef, ForLoop, Switch, etc.)"
```

---

### Task 2: Emitter — Emit New IR Nodes

Teach `RfwtxtEmitter` to output rfwtxt for the new IR types, and add `stateDecl` support to `emit()`.

**Files:**
- Modify: `packages/rfw_gen/lib/src/rfwtxt_emitter.dart`
- Test: `packages/rfw_gen/test/rfwtxt_emitter_test.dart`

- [ ] **Step 1: Write failing tests for emitting new IR nodes**

```dart
// In test/rfwtxt_emitter_test.dart — add to existing file
group('dynamic reference emission', () {
  late RfwtxtEmitter emitter;

  setUp(() {
    emitter = RfwtxtEmitter();
  });

  test('emits data reference', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Text', properties: {
        'text': IrDataRef('user.name'),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('text: data.user.name'));
  });

  test('emits args reference', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Text', properties: {
        'text': IrArgsRef('item.title'),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('text: args.item.title'));
  });

  test('emits state reference', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Container', properties: {
        'color': IrStateRef('bgColor'),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('color: state.bgColor'));
  });

  test('emits loop var reference without prefix', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Text', properties: {
        'text': IrLoopVarRef('item.name'),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('text: item.name'));
  });

  test('emits concat as list with mixed types', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Text', properties: {
        'text': IrConcat([
          IrStringValue('Hello, '),
          IrDataRef('user.name'),
          IrStringValue('!'),
        ]),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('text: ["Hello, ", data.user.name, "!"]'));
  });

  test('emits for loop', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Column', properties: {
        'children': IrListValue([
          IrForLoop(
            items: IrDataRef('items'),
            itemName: 'item',
            body: IrWidgetNode(name: 'Text', properties: {
              'text': IrLoopVarRef('item.name'),
            }),
          ),
        ]),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('...for item in data.items:'));
    expect(result, contains('Text('));
    expect(result, contains('text: item.name'));
  });

  test('emits switch expression with default', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Container', properties: {
        'color': IrSwitchExpr(
          value: IrDataRef('status'),
          cases: {
            IrStringValue('active'): IrIntValue(0xFF00FF00),
          },
          defaultCase: IrIntValue(0xFFFF0000),
        ),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('switch data.status {'));
    expect(result, contains('"active": 0x'));
    expect(result, contains('default: 0x'));
  });

  test('emits switch expression with widget cases', () {
    final result = emitter.emit(
      widgetName: 'test',
      root: IrWidgetNode(name: 'Column', properties: {
        'children': IrListValue([
          IrSwitchExpr(
            value: IrArgsRef('item.status'),
            cases: {
              IrStringValue('active'): IrWidgetNode(name: 'SizedBox'),
            },
            defaultCase: IrWidgetNode(name: 'SizedBox'),
          ),
        ]),
      }),
      imports: {'core.widgets'},
    );
    expect(result, contains('switch args.item.status {'));
  });

  test('emits state declaration', () {
    final result = emitter.emit(
      widgetName: 'toggleButton',
      root: IrWidgetNode(name: 'SizedBox'),
      imports: {'core.widgets'},
      stateDecl: {
        'down': IrBoolValue(false),
        'count': IrIntValue(0),
      },
    );
    expect(result, contains('widget toggleButton { down: false, count: 0x00000000 } = SizedBox('));
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/rfwtxt_emitter_test.dart`
Expected: FAIL — emitter doesn't handle new IR types and `stateDecl` parameter doesn't exist.

- [ ] **Step 3: Update emitter to handle new IR types**

Modify `packages/rfw_gen/lib/src/rfwtxt_emitter.dart`:

1. Add `stateDecl` parameter to `emit()`:

```dart
String emit({
  required String widgetName,
  required IrWidgetNode root,
  required Set<String> imports,
  Map<String, IrValue>? stateDecl,
}) {
  final buffer = StringBuffer();

  final sortedImports = imports.toList()..sort();
  for (final import in sortedImports) {
    buffer.writeln('import $import;');
  }

  if (sortedImports.isNotEmpty) {
    buffer.writeln();
  }

  // Emit widget declaration with optional state.
  buffer.write('widget $widgetName');
  if (stateDecl != null && stateDecl.isNotEmpty) {
    final stateEntries = stateDecl.entries
        .map((e) => '${e.key}: ${_emitValue(e.value, indent: 0)}')
        .join(', ');
    buffer.write(' { $stateEntries }');
  }
  buffer.write(' = ');
  buffer.write(_emitWidget(root, indent: 0));
  buffer.writeln(';');

  return buffer.toString();
}
```

2. Add cases to `_emitValue()`:

```dart
String _emitValue(IrValue value, {required int indent}) {
  return switch (value) {
    IrStringValue v => _emitString(v.value),
    IrNumberValue v => _emitNumber(v.value),
    IrIntValue v => _emitInt(v.value),
    IrBoolValue v => v.value ? 'true' : 'false',
    IrEnumValue v => _emitString(v.value),
    IrListValue v => _emitList(v, indent: indent),
    IrMapValue v => _emitMap(v, indent: indent),
    IrWidgetNode v => _emitWidget(v, indent: indent),
    IrSetStateValue v =>
        'set state.${v.field} = ${_emitValue(v.value, indent: indent)}',
    IrSetStateFromArgValue v =>
        'set state.${v.field} = args.${v.argName}',
    IrEventValue v => _emitEvent(v, indent: indent),
    IrDataRef v => 'data.${v.path}',
    IrArgsRef v => 'args.${v.path}',
    IrStateRef v => 'state.${v.path}',
    IrLoopVarRef v => v.path,
    IrConcat v => _emitConcat(v, indent: indent),
    IrForLoop v => _emitForLoop(v, indent: indent),
    IrSwitchExpr v => _emitSwitch(v, indent: indent),
  };
}
```

3. Add new emit methods:

```dart
String _emitConcat(IrConcat concat, {required int indent}) {
  final items = concat.parts.map((p) => _emitValue(p, indent: indent));
  return '[${items.join(', ')}]';
}

String _emitForLoop(IrForLoop loop, {required int indent}) {
  final buffer = StringBuffer();
  buffer.write('...for ${loop.itemName} in ${_emitValue(loop.items, indent: indent)}:\n');
  buffer.write(_indentStr(indent + 1));
  buffer.write(_emitWidget(loop.body, indent: indent + 1));
  return buffer.toString();
}

String _emitSwitch(IrSwitchExpr sw, {required int indent}) {
  final buffer = StringBuffer();
  buffer.writeln('switch ${_emitValue(sw.value, indent: indent)} {');
  final caseIndent = indent + 1;
  for (final entry in sw.cases.entries) {
    buffer.write(_indentStr(caseIndent));
    buffer.write('${_emitValue(entry.key, indent: caseIndent)}: ');
    buffer.write(_emitValue(entry.value, indent: caseIndent));
    buffer.writeln(',');
  }
  if (sw.defaultCase != null) {
    buffer.write(_indentStr(caseIndent));
    buffer.write('default: ');
    buffer.write(_emitValue(sw.defaultCase!, indent: caseIndent));
    buffer.writeln(',');
  }
  buffer.write('${_indentStr(indent)}}');
  return buffer.toString();
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/rfwtxt_emitter_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run all existing tests to verify no regressions**

Run: `cd packages/rfw_gen && dart test`
Expected: All existing tests still PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/rfwtxt_emitter.dart packages/rfw_gen/test/rfwtxt_emitter_test.dart
git commit -m "feat: emit rfwtxt for dynamic references, for loops, switch, concat, stateDecl"
```

---

### Task 3: Helper Classes

Create the Dart marker classes that developers will use in `@RfwWidget` functions.

**Files:**
- Create: `packages/rfw_gen/lib/src/rfw_helpers.dart`
- Modify: `packages/rfw_gen/lib/rfw_gen.dart` (add export)
- Test: `packages/rfw_gen/test/rfw_helpers_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// test/rfw_helpers_test.dart
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('DataRef', () {
    test('stores path', () {
      final ref = DataRef('user.name');
      expect(ref.path, 'user.name');
    });
  });

  group('ArgsRef', () {
    test('stores path', () {
      final ref = ArgsRef('item.title');
      expect(ref.path, 'item.title');
    });
  });

  group('StateRef', () {
    test('stores path', () {
      final ref = StateRef('isOpen');
      expect(ref.path, 'isOpen');
    });
  });

  group('LoopVar', () {
    test('stores name', () {
      final v = LoopVar('item');
      expect(v.name, 'item');
    });

    test('[] operator builds dot path', () {
      final v = LoopVar('item');
      final nested = v['name'];
      expect(nested.name, 'item.name');
    });

    test('chained [] builds deep path', () {
      final v = LoopVar('item');
      final deep = v['address']['city'];
      expect(deep.name, 'item.address.city');
    });
  });

  group('RfwConcat', () {
    test('stores parts list', () {
      final concat = RfwConcat(['Hello, ', DataRef('name'), '!']);
      expect(concat.parts, hasLength(3));
    });
  });

  group('RfwSwitchValue', () {
    test('stores value, cases, and defaultCase', () {
      final sw = RfwSwitchValue<int>(
        value: DataRef('index'),
        cases: {0: 16, 1: 8},
        defaultCase: 4,
      );
      expect(sw.cases, hasLength(2));
      expect(sw.defaultCase, 4);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/rfw_helpers_test.dart`
Expected: Compilation errors — classes not defined.

- [ ] **Step 3: Create helper classes**

Create `packages/rfw_gen/lib/src/rfw_helpers.dart`:

```dart
import 'package:flutter/widgets.dart';

/// Reference to `data.path` in rfwtxt.
class DataRef {
  final String path;
  const DataRef(this.path);
}

/// Reference to `args.path` in rfwtxt.
class ArgsRef {
  final String path;
  const ArgsRef(this.path);
}

/// Reference to `state.path` in rfwtxt.
class StateRef {
  final String path;
  const StateRef(this.path);
}

/// Loop variable reference for use inside [RfwFor.builder].
///
/// Use `[]` operator to access nested paths:
/// ```dart
/// RfwFor(
///   items: DataRef('items'),
///   itemName: 'item',
///   builder: (item) => Text(item['name']),  // → item.name
/// )
/// ```
class LoopVar {
  final String name;
  const LoopVar(this.name);
  LoopVar operator [](String path) => LoopVar('$name.$path');
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
class RfwConcat {
  final List<Object> parts;
  const RfwConcat(this.parts);
}

/// Switch expression for widget positions (children, child).
///
/// Extends [StatelessWidget] so it can be placed in widget tree.
class RfwSwitch extends StatelessWidget {
  final Object value;
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

/// Switch expression for value positions (padding, color, etc.).
class RfwSwitchValue<T> {
  final Object value;
  final Map<Object, T> cases;
  final T? defaultCase;

  const RfwSwitchValue({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}

/// For loop: `...for itemName in items: builder(itemName)`.
///
/// Extends [StatelessWidget] so it can be placed in children lists.
class RfwFor extends StatelessWidget {
  final Object items;
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

- [ ] **Step 4: Add export to barrel file**

Add to `packages/rfw_gen/lib/rfw_gen.dart`:

```dart
export 'src/rfw_helpers.dart';
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/rfw_helpers_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/rfw_helpers.dart packages/rfw_gen/lib/rfw_gen.dart packages/rfw_gen/test/rfw_helpers_test.dart
git commit -m "feat: add helper marker classes (DataRef, ArgsRef, RfwFor, RfwSwitch, etc.)"
```

---

### Task 4: ExpressionConverter — Recognize Dynamic References

Teach `ExpressionConverter.convert()` to recognize `DataRef(...)`, `ArgsRef(...)`, `StateRef(...)`, `RfwConcat(...)`, `LoopVar[...]`, and `RfwSwitchValue(...)`. Also add `SetOrMapLiteral` support for nested maps.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests for DataRef/ArgsRef/StateRef recognition**

```dart
// In test/expression_converter_test.dart — add group to existing file
group('dynamic reference recognition', () {
  late ExpressionConverter converter;

  setUp(() {
    converter = ExpressionConverter();
  });

  test('converts DataRef to IrDataRef', () {
    final source = "DataRef('user.name')";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrDataRef>());
    expect((result as IrDataRef).path, 'user.name');
  });

  test('converts ArgsRef to IrArgsRef', () {
    final source = "ArgsRef('item.title')";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrArgsRef>());
    expect((result as IrArgsRef).path, 'item.title');
  });

  test('converts StateRef to IrStateRef', () {
    final source = "StateRef('isOpen')";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrStateRef>());
    expect((result as IrStateRef).path, 'isOpen');
  });

  test('converts RfwConcat to IrConcat', () {
    final source = "RfwConcat(['Hello, ', DataRef('name'), '!'])";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrConcat>());
    final concat = result as IrConcat;
    expect(concat.parts, hasLength(3));
    expect(concat.parts[0], isA<IrStringValue>());
    expect(concat.parts[1], isA<IrDataRef>());
    expect(concat.parts[2], isA<IrStringValue>());
  });

  test('converts SetOrMapLiteral to IrMapValue', () {
    final source = "{'key': 'value', 'count': 1}";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrMapValue>());
    final map = result as IrMapValue;
    expect(map.entries, hasLength(2));
  });

  test('converts nested map with DataRef values', () {
    final source = "{'url': DataRef('item.url'), 'label': 'click'}";
    final expr = _parseExpression(source);
    final result = converter.convert(expr);
    expect(result, isA<IrMapValue>());
    final map = result as IrMapValue;
    expect(map.entries['url'], isA<IrDataRef>());
    expect(map.entries['label'], isA<IrStringValue>());
  });
});

/// Helper to parse a single expression from source.
Expression _parseExpression(String source) {
  final unit = parseString(content: 'var x = $source;').unit;
  final decl = unit.declarations.first as TopLevelVariableDeclaration;
  return decl.variables.variables.first.initializer!;
}
```

Note: `_parseExpression` helper may already exist in the test file. If so, reuse it. The import for `parseString` is from `package:analyzer/dart/analysis/utilities.dart`.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/expression_converter_test.dart`
Expected: FAIL — converter throws `UnsupportedExpressionError` for `DataRef`, etc.

- [ ] **Step 3: Add recognition to ExpressionConverter.convert()**

Modify `packages/rfw_gen/lib/src/expression_converter.dart`:

1. Add `_knownDynamicRefs` set and update `_convertMethodInvocation()`:

```dart
static const _knownDynamicRefs = <String>{
  'DataRef',
  'ArgsRef',
  'StateRef',
};

IrValue _convertMethodInvocation(MethodInvocation expr) {
  final target = expr.target;
  final methodName = expr.methodName.name;

  // Dynamic reference constructors: DataRef('path'), ArgsRef('path'), StateRef('path')
  if (target == null && _knownDynamicRefs.contains(methodName)) {
    return _convertDynamicRef(methodName, expr);
  }

  // RfwConcat(['...', DataRef('...'), '...'])
  if (target == null && methodName == 'RfwConcat') {
    return _convertConcat(expr);
  }

  // RfwSwitchValue(value: ..., cases: {...}, defaultCase: ...)
  if (target == null && methodName == 'RfwSwitchValue') {
    return _convertSwitchValue(expr);
  }

  // Color(0xFFxxxxxx)
  if (target == null && methodName == 'Color') {
    return _convertColor(expr);
  }

  // ... rest of existing code ...
}
```

2. Add the conversion methods:

```dart
IrValue _convertDynamicRef(String refType, MethodInvocation expr) {
  final args = expr.argumentList.arguments;
  if (args.length == 1 && args.first is SimpleStringLiteral) {
    final path = (args.first as SimpleStringLiteral).value;
    return switch (refType) {
      'DataRef' => IrDataRef(path),
      'ArgsRef' => IrArgsRef(path),
      'StateRef' => IrStateRef(path),
      _ => throw UnsupportedExpressionError('Unknown ref type: $refType'),
    };
  }
  throw UnsupportedExpressionError(
    '$refType requires a single string argument',
    offset: expr.offset,
  );
}

IrConcat _convertConcat(MethodInvocation expr) {
  final args = expr.argumentList.arguments;
  if (args.length == 1 && args.first is ListLiteral) {
    final list = args.first as ListLiteral;
    final parts = list.elements.map((e) => convert(e as Expression)).toList();
    return IrConcat(parts);
  }
  throw UnsupportedExpressionError(
    'RfwConcat requires a single list argument',
    offset: expr.offset,
  );
}

IrSwitchExpr _convertSwitchValue(MethodInvocation expr) {
  IrValue? value;
  final cases = <IrValue, IrValue>{};
  IrValue? defaultCase;

  for (final arg in expr.argumentList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      if (name == 'value') {
        value = convert(arg.expression);
      } else if (name == 'cases') {
        if (arg.expression is SetOrMapLiteral) {
          for (final entry in (arg.expression as SetOrMapLiteral).elements) {
            if (entry is MapLiteralEntry) {
              cases[convert(entry.key)] = convert(entry.value);
            }
          }
        }
      } else if (name == 'defaultCase') {
        defaultCase = convert(arg.expression);
      }
    }
  }

  if (value == null) {
    throw UnsupportedExpressionError(
      'RfwSwitchValue requires a value parameter',
      offset: expr.offset,
    );
  }

  return IrSwitchExpr(value: value, cases: cases, defaultCase: defaultCase);
}
```

3. Add `SetOrMapLiteral` to `convert()` switch:

```dart
IrValue convert(Expression expr) {
  return switch (expr) {
    SimpleStringLiteral() => IrStringValue(expr.value),
    IntegerLiteral() => IrIntValue(expr.value!),
    DoubleLiteral() => IrNumberValue(expr.value),
    BooleanLiteral() => IrBoolValue(expr.value),
    ListLiteral() => _convertListLiteral(expr),
    SetOrMapLiteral() => _convertMapLiteral(expr),
    PrefixExpression() => _convertPrefixExpression(expr),
    MethodInvocation() => _convertMethodInvocation(expr),
    PrefixedIdentifier() => _convertPrefixedIdentifier(expr),
    _ => throw UnsupportedExpressionError(
        'Unsupported expression type: ${expr.runtimeType}',
        offset: expr.offset,
      ),
  };
}

IrMapValue _convertMapLiteral(SetOrMapLiteral expr) {
  final entries = <String, IrValue>{};
  for (final element in expr.elements) {
    if (element is MapLiteralEntry) {
      final key = (element.key as SimpleStringLiteral).value;
      entries[key] = convert(element.value);
    }
  }
  return IrMapValue(entries);
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/expression_converter_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run all tests to verify no regressions**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "feat: recognize DataRef, ArgsRef, StateRef, RfwConcat, SetOrMapLiteral in ExpressionConverter"
```

---

### Task 5: AST Visitor — Recognize RfwFor and RfwSwitch

Teach `WidgetAstVisitor` to handle `RfwFor(...)` and `RfwSwitch(...)` as special constructs (not widget lookups).

**Files:**
- Modify: `packages/rfw_gen/lib/src/ast_visitor.dart`
- Test: `packages/rfw_gen/test/ast_visitor_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// In test/ast_visitor_test.dart — add group to existing file
group('dynamic feature recognition', () {
  late WidgetAstVisitor visitor;

  setUp(() {
    final registry = WidgetRegistry.core();
    visitor = WidgetAstVisitor(
      registry: registry,
      expressionConverter: ExpressionConverter(),
    );
  });

  test('converts RfwFor in children list', () {
    final source = '''
Widget build() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Text('hello'),
      ),
    ],
  );
}
''';
    final func = _parseFunction(source);
    final result = visitor.extractWidgetTree(func);
    final children = result.properties['children'] as IrListValue;
    expect(children.values.first, isA<IrForLoop>());
    final loop = children.values.first as IrForLoop;
    expect(loop.items, isA<IrDataRef>());
    expect(loop.itemName, 'item');
    expect(loop.body, isA<IrWidgetNode>());
  });

  test('converts RfwSwitch in child position', () {
    final source = '''
Widget build() {
  return Container(
    child: RfwSwitch(
      value: DataRef('status'),
      cases: {
        'active': SizedBox(),
      },
      defaultCase: SizedBox(),
    ),
  );
}
''';
    final func = _parseFunction(source);
    final result = visitor.extractWidgetTree(func);
    expect(result.properties['child'], isA<IrSwitchExpr>());
  });

  test('converts DataRef as pass-through param', () {
    final source = '''
Widget build() {
  return Container(
    color: DataRef('theme.primary'),
  );
}
''';
    final func = _parseFunction(source);
    final result = visitor.extractWidgetTree(func);
    expect(result.properties['color'], isA<IrDataRef>());
  });
});

FunctionDeclaration _parseFunction(String source) {
  final unit = parseString(content: source).unit;
  return unit.declarations.whereType<FunctionDeclaration>().first;
}
```

Note: `_parseFunction` helper may already exist in the test file. Reuse if so.

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/ast_visitor_test.dart`
Expected: FAIL — `RfwFor` and `RfwSwitch` are not registered widgets, so `UnsupportedWidgetError` is thrown.

- [ ] **Step 3: Update AST visitor to handle special constructs**

Modify `packages/rfw_gen/lib/src/ast_visitor.dart`:

1. Add a method to detect and convert special constructs. Update `_convertWidget()` to check for `RfwFor`/`RfwSwitch` before the registry lookup:

```dart
IrWidgetNode _convertWidget(Expression expr) {
  if (expr is! MethodInvocation || expr.target != null) {
    throw UnsupportedWidgetError(expr.toString());
  }

  final widgetName = expr.methodName.name;

  // Special constructs: RfwFor, RfwSwitch — not in WidgetRegistry.
  if (widgetName == 'RfwFor') {
    // Return a sentinel widget node; the for loop is handled differently.
    // We actually need to return IrValue, but _convertWidget returns IrWidgetNode.
    // Handle this at the call site instead.
  }

  // ... existing code ...
}
```

Actually, the challenge is that `_convertWidget` returns `IrWidgetNode`, but `RfwFor` and `RfwSwitch` produce `IrForLoop` and `IrSwitchExpr`. The cleanest approach: add a new method `_convertExpression` that can return any `IrValue`, and use it in child/children processing:

```dart
/// Converts an expression that could be a widget OR a special construct (RfwFor, RfwSwitch).
IrValue _convertWidgetOrSpecial(Expression expr) {
  if (expr is MethodInvocation && expr.target == null) {
    final name = expr.methodName.name;
    if (name == 'RfwFor') return _convertRfwFor(expr);
    if (name == 'RfwSwitch') return _convertRfwSwitch(expr);
  }
  return _convertWidget(expr);
}

IrForLoop _convertRfwFor(MethodInvocation expr) {
  IrValue? items;
  String? itemName;
  IrWidgetNode? body;

  for (final arg in expr.argumentList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      if (name == 'items') {
        items = expressionConverter.convert(arg.expression);
      } else if (name == 'itemName') {
        itemName = (arg.expression as SimpleStringLiteral).value;
      } else if (name == 'builder') {
        // builder: (item) => Widget(...)
        // The FunctionExpression body contains the widget to convert.
        final funcExpr = arg.expression as FunctionExpression;
        final funcBody = funcExpr.body;
        Expression? bodyExpr;
        if (funcBody is ExpressionFunctionBody) {
          bodyExpr = funcBody.expression;
        } else if (funcBody is BlockFunctionBody) {
          for (final stmt in funcBody.block.statements) {
            if (stmt is ReturnStatement) {
              bodyExpr = stmt.expression;
              break;
            }
          }
        }
        if (bodyExpr != null) {
          body = _convertWidget(bodyExpr);
        }
      }
    }
  }

  if (items == null || itemName == null || body == null) {
    throw UnsupportedWidgetError('RfwFor requires items, itemName, and builder');
  }

  return IrForLoop(items: items, itemName: itemName, body: body);
}

IrSwitchExpr _convertRfwSwitch(MethodInvocation expr) {
  IrValue? value;
  final cases = <IrValue, IrValue>{};
  IrValue? defaultCase;

  for (final arg in expr.argumentList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      if (name == 'value') {
        value = expressionConverter.convert(arg.expression);
      } else if (name == 'cases') {
        if (arg.expression is SetOrMapLiteral) {
          for (final entry in (arg.expression as SetOrMapLiteral).elements) {
            if (entry is MapLiteralEntry) {
              final key = expressionConverter.convert(entry.key);
              final val = _convertWidgetOrSpecial(entry.value);
              cases[key] = val;
            }
          }
        }
      } else if (name == 'defaultCase') {
        defaultCase = _convertWidgetOrSpecial(arg.expression);
      }
    }
  }

  if (value == null) {
    throw UnsupportedWidgetError('RfwSwitch requires a value parameter');
  }

  return IrSwitchExpr(value: value, cases: cases, defaultCase: defaultCase);
}
```

2. Update all call sites that use `_convertWidget` for child/children processing to use `_convertWidgetOrSpecial`:

In `_processNamedArgument`, change:
- `properties[paramName] = _convertWidget(expression);` → `properties[paramName] = _convertWidgetOrSpecial(expression);`
- `_convertWidget(e as Expression)` in list → `_convertWidgetOrSpecial(e as Expression)`

In step 5 (unknown parameter widget check), also check for special constructs.

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/ast_visitor_test.dart`
Expected: All tests PASS.

- [ ] **Step 5: Run all tests to verify no regressions**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/ast_visitor.dart packages/rfw_gen/test/ast_visitor_test.dart
git commit -m "feat: recognize RfwFor and RfwSwitch in AST visitor"
```

---

### Task 6: Annotation + Converter — State Declaration and Import Collection

Update `@RfwWidget` to support `state` parameter. Update `RfwConverter` to extract state and pass to emitter. Update `_collectImports` to traverse new IR types.

**Files:**
- Modify: `packages/rfw_gen/lib/src/annotations.dart`
- Modify: `packages/rfw_gen/lib/src/converter.dart`
- Test: `packages/rfw_gen/test/converter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
// In test/converter_test.dart — add group to existing file
group('state declaration', () {
  test('extracts state from @RfwWidget annotation', () {
    final source = '''
@RfwWidget('toggle', state: {'down': false})
Widget toggle() {
  return SizedBox();
}
''';
    final converter = RfwConverter(registry: WidgetRegistry.core());
    final result = converter.convertFromSource(source);
    expect(result, contains('widget toggle { down: false } = SizedBox('));
  });
});

group('import collection with dynamic features', () {
  test('collects imports from widgets inside IrForLoop body', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => ElevatedButton(
          child: Text('hello'),
        ),
      ),
    ],
  );
}
''';
    final converter = RfwConverter(registry: WidgetRegistry.core());
    final result = converter.convertFromSource(source);
    expect(result, contains('import core.widgets;'));
    expect(result, contains('import material;'));
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/converter_test.dart`
Expected: FAIL — state parameter not recognized, imports not collected from for loop body.

- [ ] **Step 3: Update annotations.dart**

```dart
class RfwWidget {
  final String name;
  final Map<String, dynamic>? state;
  const RfwWidget(this.name, {this.state});
}
```

- [ ] **Step 4: Update converter.dart**

1. Update `convertFromAst()` to extract state and pass to emitter:

```dart
String convertFromAst(FunctionDeclaration function) {
  final widgetName = _extractWidgetName(function);
  final stateDecl = _extractStateDecl(function);

  final visitor = WidgetAstVisitor(
    registry: registry,
    expressionConverter: ExpressionConverter(),
  );
  final irTree = visitor.extractWidgetTree(function);

  final imports = _collectImports(irTree);
  final emitter = RfwtxtEmitter();
  return emitter.emit(
    widgetName: widgetName,
    root: irTree,
    imports: imports,
    stateDecl: stateDecl,
  );
}

Map<String, IrValue>? _extractStateDecl(FunctionDeclaration function) {
  for (final annotation in function.metadata) {
    if (annotation.name.name == 'RfwWidget') {
      final arguments = annotation.arguments;
      if (arguments == null) continue;
      for (final arg in arguments.arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'state') {
          if (arg.expression is SetOrMapLiteral) {
            final map = arg.expression as SetOrMapLiteral;
            final entries = <String, IrValue>{};
            final exprConverter = ExpressionConverter();
            for (final entry in map.elements) {
              if (entry is MapLiteralEntry) {
                final key = (entry.key as SimpleStringLiteral).value;
                entries[key] = exprConverter.convert(entry.value);
              }
            }
            return entries;
          }
        }
      }
    }
  }
  return null;
}
```

2. Update `_collectImports()` to traverse new IR types:

```dart
Set<String> _collectImports(IrValue node) {
  final imports = <String>{};

  if (node is IrWidgetNode) {
    final mapping = registry.supportedWidgets[node.name];
    if (mapping != null) imports.add(mapping.import);
    for (final value in node.properties.values) {
      imports.addAll(_collectImports(value));
    }
  } else if (node is IrListValue) {
    for (final item in node.values) {
      imports.addAll(_collectImports(item));
    }
  } else if (node is IrForLoop) {
    imports.addAll(_collectImports(node.body));
  } else if (node is IrSwitchExpr) {
    for (final caseValue in node.cases.values) {
      imports.addAll(_collectImports(caseValue));
    }
    if (node.defaultCase != null) {
      imports.addAll(_collectImports(node.defaultCase!));
    }
  }

  return imports;
}
```

Note: The method signature changes from `_collectImports(IrWidgetNode node)` to `_collectImports(IrValue node)` to support recursive traversal of all IR types.

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/converter_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Run all tests**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS.

- [ ] **Step 7: Commit**

```bash
git add packages/rfw_gen/lib/src/annotations.dart packages/rfw_gen/lib/src/converter.dart packages/rfw_gen/test/converter_test.dart
git commit -m "feat: support @RfwWidget state declaration and import collection for dynamic IR types"
```

---

### Task 7: Integration Tests — Full Pipeline with parseLibraryFile Validation

End-to-end tests: Dart source → rfwtxt → `parseLibraryFile()` verification.

**Files:**
- Modify: `packages/rfw_gen/test/integration_test.dart`

- [ ] **Step 1: Write integration tests**

```dart
// In test/integration_test.dart — add group to existing file
group('dynamic features integration', () {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  test('DataRef produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return Text(DataRef('user.name'));
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('data.user.name'));
    // Validate parseLibraryFile doesn't throw
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('ArgsRef produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return Text(ArgsRef('item.title'));
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('args.item.title'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('RfwFor with LoopVar produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Text('hello'),
      ),
    ],
  );
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('...for item in data.items:'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('RfwSwitch with widget cases produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return RfwSwitch(
    value: DataRef('status'),
    cases: {
      'active': SizedBox(),
    },
    defaultCase: SizedBox(),
  );
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('switch data.status'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('RfwConcat produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return Text(RfwConcat(['Hello, ', DataRef('name'), '!']));
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('["Hello, ", data.name, "!"]'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('state declaration produces parseable rfwtxt', () {
    final source = """
@RfwWidget('toggle', state: {'down': false})
Widget toggle() {
  return GestureDetector(
    onTapDown: RfwHandler.setState('down', true),
    child: SizedBox(),
  );
}
""";
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('widget toggle { down: false }'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('event with dynamic payload produces parseable rfwtxt', () {
    final source = '''
@RfwWidget('test')
Widget test() {
  return GestureDetector(
    onTap: RfwHandler.event('tap', {
      'id': ArgsRef('item.id'),
      'label': 'click',
    }),
    child: SizedBox(),
  );
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('args.item.id'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('complex: RfwFor + RfwSwitch + DataRef + event', () {
    final source = '''
@RfwWidget('complex')
Widget complex() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('list'),
        itemName: 'item',
        builder: (item) => RfwSwitch(
          value: DataRef('mode'),
          cases: {
            'a': Text('A'),
          },
          defaultCase: Text('default'),
        ),
      ),
    ],
  );
}
''';
    final rfwtxt = converter.convertFromSource(source);
    expect(rfwtxt, contains('...for item in data.list:'));
    expect(rfwtxt, contains('switch data.mode'));
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });
});
```

- [ ] **Step 2: Run integration tests**

Run: `cd packages/rfw_gen && dart test test/integration_test.dart`
Expected: All tests PASS.

- [ ] **Step 3: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS including all existing tests (no regressions).

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen/test/integration_test.dart
git commit -m "test: add integration tests for dynamic features with parseLibraryFile validation"
```

---

### Task 8: Event Handler Dynamic Payload Support

Update `_convertEvent` in `ExpressionConverter` to handle nested maps containing `DataRef`/`ArgsRef`. This is needed because the existing `_convertEvent` calls `convert()` for values, which now already handles `DataRef` etc. from Task 4. But nested `SetOrMapLiteral` in event args also needs to work.

**Files:**
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write test for event with dynamic payload**

```dart
group('event handler dynamic payload', () {
  late ExpressionConverter converter;

  setUp(() {
    converter = ExpressionConverter();
  });

  test('event with ArgsRef in payload', () {
    final source = "RfwHandler.event('tap', {'id': ArgsRef('item.id'), 'label': 'click'})";
    final expr = _parseExpression(source);
    final result = converter.convertHandler(expr);
    expect(result, isA<IrEventValue>());
    final event = result as IrEventValue;
    expect(event.args['id'], isA<IrArgsRef>());
    expect(event.args['label'], isA<IrStringValue>());
  });

  test('event with nested map containing DataRef', () {
    final source = "RfwHandler.event('tap', {'action': {'url': DataRef('item.url')}, 'count': 1})";
    final expr = _parseExpression(source);
    final result = converter.convertHandler(expr);
    expect(result, isA<IrEventValue>());
    final event = result as IrEventValue;
    expect(event.args['action'], isA<IrMapValue>());
    final innerMap = event.args['action'] as IrMapValue;
    expect(innerMap.entries['url'], isA<IrDataRef>());
  });
});
```

- [ ] **Step 2: Run tests**

Run: `cd packages/rfw_gen && dart test test/expression_converter_test.dart`
Expected: PASS — because Task 4 already added `SetOrMapLiteral` support to `convert()`, and `_convertEvent` calls `convert()` for map values. If tests fail, the `SetOrMapLiteral` case needs to be verified.

- [ ] **Step 3: Fix if needed, then commit**

```bash
git add packages/rfw_gen/test/expression_converter_test.dart
git commit -m "test: verify event handler dynamic payload with DataRef/ArgsRef"
```

---

### Task 9: Final Validation — dart analyze + All Tests

Run static analysis and full test suite.

**Files:** None (validation only)

- [ ] **Step 1: Run dart analyze**

Run: `cd packages/rfw_gen && dart analyze`
Expected: No errors.

- [ ] **Step 2: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS.

- [ ] **Step 3: Run melos test across all packages**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && melos exec -- dart test`
Expected: All packages pass.

- [ ] **Step 4: Final commit if any cleanup was needed**

```bash
git commit -m "chore: final cleanup after dynamic features implementation"
```
