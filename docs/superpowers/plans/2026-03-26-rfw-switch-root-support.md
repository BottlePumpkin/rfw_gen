# RfwSwitch Root Widget Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow RfwSwitch (and RfwFor) to be used as the root widget of `@RfwWidget` functions, fixing #57.

**Architecture:** Change `extractWidgetTree()` return type from `IrWidgetNode` to `IrValue` and route through `_convertWidgetOrSpecial()`. Update emitter and converter call sites to accept `IrValue` root.

**Tech Stack:** Dart, package:rfw, package:analyzer

---

### Task 1: Failing unit test — RfwSwitch at root

**Files:**
- Modify: `packages/rfw_gen_builder/test/ast_visitor_test.dart`

- [ ] **Step 1: Add failing test for root RfwSwitch**

Add this test inside the existing `'WidgetAstVisitor'` group, after the `'converts RfwSwitch in child position'` test (around line 541):

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
      expect(sw.value, isA<IrStateRef>());
      expect(sw.cases, hasLength(2));
    });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen_builder && dart test test/ast_visitor_test.dart --name "converts RfwSwitch at root position"`

Expected: FAIL with `UnsupportedWidgetError: RfwSwitch is not registered`

- [ ] **Step 3: Commit failing test**

```bash
git add packages/rfw_gen_builder/test/ast_visitor_test.dart
git commit -m "test: add failing test for RfwSwitch at root position (#57)"
```

---

### Task 2: Fix extractWidgetTree() to support special constructs at root

**Files:**
- Modify: `packages/rfw_gen_builder/lib/src/ast_visitor.dart:43-54`

- [ ] **Step 1: Change return type and call site**

In `ast_visitor.dart`, change `extractWidgetTree()`:

```dart
  /// Throws [StateError] if no return expression is found.
  /// Throws [UnsupportedWidgetError] if the root expression is not a
  /// supported widget or special construct (RfwSwitch, RfwFor).
  IrValue extractWidgetTree(FunctionDeclaration function) {
    final expr = _findReturnExpression(function);
    if (expr == null) {
      throw StateError(
        'No return expression found in function '
        '"${function.name.lexeme}"',
      );
    }
    return _convertWidgetOrSpecial(expr);
  }
```

Changes:
- Return type: `IrWidgetNode` → `IrValue`
- Call: `_convertWidget(expr)` → `_convertWidgetOrSpecial(expr)`
- Doc comment: mention special constructs

- [ ] **Step 2: Run the failing test to verify it passes**

Run: `cd packages/rfw_gen_builder && dart test test/ast_visitor_test.dart --name "converts RfwSwitch at root position"`

Expected: PASS

- [ ] **Step 3: Run all ast_visitor tests to check for regressions**

Run: `cd packages/rfw_gen_builder && dart test test/ast_visitor_test.dart`

Expected: ALL PASS — existing tests assign `extractWidgetTree()` result to `final node` (type inferred), so the type change is compatible. Tests that do `node.properties[...]` still work because `IrWidgetNode` extends `IrValue`.

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/ast_visitor.dart
git commit -m "fix: allow RfwSwitch and RfwFor at root widget position (#57)"
```

---

### Task 3: Update emitter to accept IrValue root

**Files:**
- Modify: `packages/rfw_gen_builder/lib/src/rfwtxt_emitter.dart:10-37`

- [ ] **Step 1: Change emit() root parameter type and emission**

In `rfwtxt_emitter.dart`, change the `emit()` method:

```dart
  String emit({
    required String widgetName,
    required IrValue root,
    required Set<String> imports,
    Map<String, IrValue>? stateDecl,
  }) {
```

And change line 37 from:

```dart
    buffer.write(_emitWidget(root, indent: 0));
```

to:

```dart
    buffer.write(_emitValue(root, indent: 0));
```

`_emitValue()` already handles all `IrValue` subtypes exhaustively (`IrWidgetNode`, `IrSwitchExpr`, `IrForLoop`, etc.), so no additional logic needed.

- [ ] **Step 2: Run all emitter tests**

Run: `cd packages/rfw_gen_builder && dart test test/rfwtxt_emitter_test.dart`

Expected: ALL PASS — existing tests pass `IrWidgetNode` which is a subtype of `IrValue`.

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/rfwtxt_emitter.dart
git commit -m "fix: accept IrValue root in rfwtxt emitter (#57)"
```

---

### Task 4: Failing integration test — parseable rfwtxt

**Files:**
- Modify: `packages/rfw_gen_builder/test/integration_test.dart`

- [ ] **Step 1: Add integration test for root RfwSwitch**

Add after the existing `'RfwSwitch with widget cases produces parseable rfwtxt'` test (around line 515):

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
      expect(result.rfwtxt, contains('Text('));
      expect(() => parseLibraryFile(result.rfwtxt), returnsNormally);
    });
```

- [ ] **Step 2: Run it to verify it passes**

Run: `cd packages/rfw_gen_builder && dart test test/integration_test.dart --name "RfwSwitch at root"`

Expected: PASS (implementation already done in Tasks 2-3)

- [ ] **Step 3: Add integration test for root RfwSwitch with defaultCase**

```dart
    test('RfwSwitch at root with defaultCase produces parseable rfwtxt', () {
      const source = '''
Widget buildStatus() {
  return RfwSwitch(
    value: DataRef('status'),
    cases: {
      'loading': CircularProgressIndicator(),
      'done': Text('Complete'),
    },
    defaultCase: SizedBox(),
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('switch data.status'));
      expect(result.rfwtxt, contains('default:'));
      expect(() => parseLibraryFile(result.rfwtxt), returnsNormally);
    });
```

- [ ] **Step 4: Run it to verify**

Run: `cd packages/rfw_gen_builder && dart test test/integration_test.dart --name "RfwSwitch at root with defaultCase"`

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen_builder/test/integration_test.dart
git commit -m "test: add integration tests for root RfwSwitch (#57)"
```

---

### Task 5: Bonus — RfwFor at root test

Same root cause affects RfwFor. Add a test to confirm it also works now.

**Files:**
- Modify: `packages/rfw_gen_builder/test/integration_test.dart`

- [ ] **Step 1: Add integration test for root RfwFor**

Add after the RfwSwitch root tests:

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

- [ ] **Step 2: Run it to verify**

Run: `cd packages/rfw_gen_builder && dart test test/integration_test.dart --name "RfwFor at root"`

Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen_builder/test/integration_test.dart
git commit -m "test: add integration test for root RfwFor (#57)"
```

---

### Task 6: Full regression check

- [ ] **Step 1: Run all rfw_gen_builder tests**

Run: `cd packages/rfw_gen_builder && dart test`

Expected: ALL PASS

- [ ] **Step 2: Run static analysis**

Run: `cd packages/rfw_gen_builder && dart analyze`

Expected: No errors

- [ ] **Step 3: Run rfw_gen tests (core package)**

Run: `cd packages/rfw_gen && dart test`

Expected: ALL PASS (no changes in this package, but verify no coupling issues)
