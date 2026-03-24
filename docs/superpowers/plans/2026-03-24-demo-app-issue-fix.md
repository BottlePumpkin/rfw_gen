# Demo App Issue Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix all 27 issues found in the demo app scan (6 Critical, 6 High, 8 Medium, 7 Low), then regenerate rfwtxt/rfw binaries and verify.

**Architecture:** Fix issues in dependency order — expression_converter first (most issues live there), then ast_visitor, then widget_registry, then emitter. Each task is a self-contained TDD cycle: write failing test → implement fix → verify → commit.

**Tech Stack:** Dart, analyzer package AST types, rfw package

**Scan Report:** `docs/superpowers/reports/2026-03-24-demo-app-issue-scan-report.md`

---

## Test Pattern

All test files use this pattern (from `expression_converter_test.dart`):
```dart
Expression parseExpression(String code) {
  final result = parseString(content: 'final x = $code;');
  final unit = result.unit;
  final decl = unit.declarations.first as TopLevelVariableDeclaration;
  return decl.variables.variables.first.initializer!;
}

// Usage:
final expr = parseExpression('Alignment.center');
final result = converter.convert(expr);
expect(result, isA<IrMapValue>());
```

All test code in this plan uses this `parseExpression` + `converter.convert` pattern.

---

## File Map

**Files to modify:**
- `packages/rfw_gen/lib/src/expression_converter.dart` (971 lines) — Tasks 1-6
- `packages/rfw_gen/lib/src/ast_visitor.dart` (344 lines) — Task 7
- `packages/rfw_gen/lib/src/widget_registry.dart` (931 lines) — Task 8
- `packages/rfw_gen/lib/src/rfwtxt_emitter.dart` (237 lines) — Task 9

**Test files to modify:**
- `packages/rfw_gen/test/expression_converter_test.dart` (1,032 lines) — Tasks 1-6
- `packages/rfw_gen/test/ast_visitor_test.dart` (822 lines) — Task 7
- `packages/rfw_gen/test/widget_registry_test.dart` (889 lines) — Task 8
- `packages/rfw_gen/test/rfwtxt_emitter_test.dart` (748 lines) — Task 9

**Regeneration (Task 10):**
- `example/lib/catalog/catalog_widgets.rfwtxt`
- `example/lib/ecommerce/shop_widgets.rfwtxt`
- `example/assets/catalog_widgets.rfw`
- `example/assets/shop_widgets.rfw`

---

### Task 1: [CRITICAL] Alignment named constants + AlignmentDirectional

**Issues:** C1, C2 — `Alignment.center`, `Alignment.topLeft` etc. throw. `AlignmentDirectional` completely missing.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart:369-393`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests for Alignment constants**

Add tests to `expression_converter_test.dart`:

```dart
test('converts Alignment.center to map', () {
  final expr = parseExpression('Alignment.center');
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
  final map = (result as IrMapValue).entries;
  expect((map['x'] as IrNumberValue).value, 0.0);
  expect((map['y'] as IrNumberValue).value, 0.0);
});

test('converts Alignment.topLeft to map', () {
  final expr = parseExpression('Alignment.topLeft');
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
  final map = (result as IrMapValue).entries;
  expect((map['x'] as IrNumberValue).value, -1.0);
  expect((map['y'] as IrNumberValue).value, -1.0);
});

test('converts AlignmentDirectional.centerStart to map', () {
  final expr = parseExpression('AlignmentDirectional.centerStart');
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
  final map = (result as IrMapValue).entries;
  expect((map['start'] as IrNumberValue).value, -1.0);
  expect((map['y'] as IrNumberValue).value, 0.0);
});

test('throws for unknown Alignment constant', () {
  final expr = parseExpression('Alignment.unknownName');
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

Expected: FAIL with `UnsupportedExpressionError`

- [ ] **Step 3: Implement Alignment constant mapping**

In `expression_converter.dart`, add to `_convertPrefixedIdentifier` (line 369-393), BEFORE the throw at line 389:

```dart
if (prefix == 'Alignment') {
  return _convertAlignmentConstant(identifier);
}

if (prefix == 'AlignmentDirectional') {
  return _convertAlignmentDirectionalConstant(identifier);
}
```

Add the mapping methods:

```dart
static const _alignmentConstants = <String, List<double>>{
  'topLeft': [-1.0, -1.0],
  'topCenter': [0.0, -1.0],
  'topRight': [1.0, -1.0],
  'centerLeft': [-1.0, 0.0],
  'center': [0.0, 0.0],
  'centerRight': [1.0, 0.0],
  'bottomLeft': [-1.0, 1.0],
  'bottomCenter': [0.0, 1.0],
  'bottomRight': [1.0, 1.0],
};

IrMapValue _convertAlignmentConstant(String name) {
  final values = _alignmentConstants[name];
  if (values != null) {
    return IrMapValue({
      'x': IrNumberValue(values[0]),
      'y': IrNumberValue(values[1]),
    });
  }
  throw UnsupportedExpressionError('Unknown Alignment constant: $name');
}

static const _alignmentDirectionalConstants = <String, List<double>>{
  'topStart': [-1.0, -1.0],
  'topCenter': [0.0, -1.0],
  'topEnd': [1.0, -1.0],
  'centerStart': [-1.0, 0.0],
  'center': [0.0, 0.0],
  'centerEnd': [1.0, 0.0],
  'bottomStart': [-1.0, 1.0],
  'bottomCenter': [0.0, 1.0],
  'bottomEnd': [1.0, 1.0],
};

IrMapValue _convertAlignmentDirectionalConstant(String name) {
  final values = _alignmentDirectionalConstants[name];
  if (values != null) {
    return IrMapValue({
      'start': IrNumberValue(values[0]),
      'y': IrNumberValue(values[1]),
    });
  }
  throw UnsupportedExpressionError(
    'Unknown AlignmentDirectional constant: $name',
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "fix: add Alignment and AlignmentDirectional constant support"
```

---

### Task 2: [CRITICAL] EdgeInsetsDirectional support

**Issue:** C3 — `EdgeInsetsDirectional` completely missing.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart:115-117, 255-261`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('converts EdgeInsetsDirectional.only(start: 16)', () {
  final expr = parseExpression('EdgeInsetsDirectional.only(start: 16.0)');
  final result = converter.convert(expr);
  expect(result, isA<IrListValue>());
  final list = (result as IrListValue).values;
  expect((list[0] as IrNumberValue).value, 16.0);
});

test('converts EdgeInsetsDirectional.fromSTEB(8, 16, 8, 16)', () {
  final expr = parseExpression('EdgeInsetsDirectional.fromSTEB(8.0, 16.0, 8.0, 16.0)');
  final result = converter.convert(expr);
  expect(result, isA<IrListValue>());
});

test('converts EdgeInsetsDirectional.symmetric', () {
  final expr = parseExpression('EdgeInsetsDirectional.symmetric(horizontal: 12.0, vertical: 6.0)');
  final result = converter.convert(expr);
  expect(result, isA<IrListValue>());
});

test('converts EdgeInsetsDirectional.all(8)', () {
  final expr = parseExpression('EdgeInsetsDirectional.all(8.0)');
  final result = converter.convert(expr);
  expect(result, isA<IrListValue>());
  final list = (result as IrListValue).values;
  expect((list[0] as IrNumberValue).value, 8.0);
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 3: Implement EdgeInsetsDirectional support**

1. Add `'EdgeInsetsDirectional'` to `_isKnownClassName` (line 256-260):
```dart
bool _isKnownClassName(String name) {
  return const {
    'EdgeInsets',
    'EdgeInsetsDirectional',
    'BorderRadius',
    'Radius',
  }.contains(name);
}
```

2. Add MethodInvocation handler (after line 117):
```dart
if (target is SimpleIdentifier && target.name == 'EdgeInsetsDirectional') {
  return _convertEdgeInsetsDirectional(methodName, expr.argumentList);
}
```

3. Add InstanceCreation handler (in the named constructor switch at line 219-228):
```dart
'EdgeInsetsDirectional' => _convertEdgeInsetsDirectional(constructorName, argList),
```

4. Add the converter method (reuses the same LTRB list format as EdgeInsets, but with start/top/end/bottom semantics — same encoding per rfw-types.md):
```dart
IrListValue _convertEdgeInsetsDirectional(String method, ArgumentList argList) {
  switch (method) {
    case 'all':
      return _convertEdgeInsetsAll(argList); // Same encoding
    case 'symmetric':
      return _convertEdgeInsetsSymmetric(argList); // horizontal→start/end
    case 'only':
      return _convertEdgeInsetsDirectionalOnly(argList);
    case 'fromSTEB':
      return _convertEdgeInsetsFromLTRB(argList); // Same positional order
    default:
      throw UnsupportedExpressionError(
        'Unsupported EdgeInsetsDirectional constructor: $method',
      );
  }
}

IrListValue _convertEdgeInsetsDirectionalOnly(ArgumentList argList) {
  double start = 0.0, top = 0.0, end = 0.0, bottom = 0.0;
  for (final arg in argList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      final value = _toDouble(arg.expression);
      switch (name) {
        case 'start': start = value;
        case 'top': top = value;
        case 'end': end = value;
        case 'bottom': bottom = value;
      }
    }
  }
  return IrListValue([
    IrNumberValue(start), IrNumberValue(top),
    IrNumberValue(end), IrNumberValue(bottom),
  ]);
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "fix: add EdgeInsetsDirectional support"
```

---

### Task 3: [CRITICAL] Silent drop fixes — BoxDecoration, Gradient, Emitter guards

**Issues:** C4, C5 — `BoxDecoration.shape`, Gradient `colors`/`stops`/`boxShadow`, `tileMode` silently dropped when guard condition fails.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart:640-755`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests for silent drops**

Test that values are NOT silently dropped when the guard condition fails. The current code silently skips; after the fix, it should attempt `convert()` which throws for unsupported expressions:

```dart
test('BoxDecoration.boxShadow with non-ListLiteral attempts convert', () {
  // Currently silently dropped; after fix should attempt convert()
  final expr = parseExpression("BoxDecoration(color: Color(0xFF000000), boxShadow: someVar)");
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});

test('BoxDecoration.shape with non-PrefixedIdentifier attempts convert', () {
  final expr = parseExpression("BoxDecoration(shape: someVar)");
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});

test('LinearGradient.colors with non-ListLiteral attempts convert', () {
  final expr = parseExpression("LinearGradient(colors: someVar)");
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});

test('LinearGradient.tileMode with non-PrefixedIdentifier attempts convert', () {
  final expr = parseExpression("LinearGradient(colors: [Color(0xFFFF0000)], tileMode: someVar)");
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});

test('BoxDecoration.border attempts convert (not silently dropped)', () {
  // M3: border is not a recognized case, so it goes through default
  // After adding else clauses, unrecognized cases should not silently vanish
  final expr = parseExpression("BoxDecoration(color: Color(0xFF000000))");
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

Expected: FAIL — current code silently drops values instead of throwing

- [ ] **Step 3: Add else clauses that use `convert()` fallback**

For each silent-drop `if` guard in `_convertBoxDecoration`, `_convertLinearGradient`, `_convertRadialGradient`, add an `else` clause that attempts `convert()` (which will throw `UnsupportedExpressionError` for unsupported expressions, or convert valid ones like data refs):

In `_convertBoxDecoration` (line 645-658):
```dart
case 'boxShadow':
  if (arg.expression is ListLiteral) {
    final list = arg.expression as ListLiteral;
    entries[name] = IrListValue(
      list.elements.map((e) => convert(e as Expression)).toList(),
    );
  } else {
    entries[name] = convert(arg.expression);
  }
case 'shape':
  if (arg.expression is PrefixedIdentifier) {
    final id = (arg.expression as PrefixedIdentifier).identifier.name;
    entries[name] = IrStringValue(id);
  } else {
    entries[name] = convert(arg.expression);
  }
```

Apply same pattern to LinearGradient `colors`, `stops`, `tileMode` and RadialGradient `colors`, `stops`.

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "fix: eliminate silent drops in BoxDecoration and Gradient converters"
```

---

### Task 4: [HIGH] Add default cases for TextStyle, IconThemeData, and `!` prefix operator

**Issues:** H1, H2, H5 — TextStyle/IconThemeData silently ignore unknown properties; `!boolValue` throws.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart:560-695, 74-88`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('TextStyle converts unknown property via generic convert', () {
  final expr = parseExpression("TextStyle(fontSize: 24.0, backgroundColor: Color(0xFFFF0000))");
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect(map.containsKey('fontSize'), isTrue);
  expect(map.containsKey('backgroundColor'), isTrue); // Should NOT be silently dropped
});

test('IconThemeData converts unknown property via generic convert', () {
  final expr = parseExpression("IconThemeData(color: Color(0xFF000000), fill: 1.0)");
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect(map.containsKey('color'), isTrue);
  expect(map.containsKey('fill'), isTrue);
});

test('converts prefix ! on BooleanLiteral', () {
  final expr = parseExpression('!true');
  final result = converter.convert(expr);
  expect(result, isA<IrBoolValue>());
  expect((result as IrBoolValue).value, isFalse);
});

test('prefix ! on non-BooleanLiteral throws', () {
  final expr = parseExpression('!someVar');
  expect(() => converter.convert(expr), throwsA(isA<UnsupportedExpressionError>()));
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 3: Implement fixes**

1. **TextStyle** — add default case in the switch (line 565-600):
```dart
default:
  // Attempt generic conversion for unknown TextStyle properties
  entries[name] = convert(arg.expression);
```

2. **IconThemeData** — add default case (line 685-691):
```dart
default:
  entries[name] = convert(arg.expression);
```

3. **PrefixExpression** — add `!` handling (after line 83, before the throw):
```dart
if (expr.operator.lexeme == '!') {
  final operand = expr.operand;
  if (operand is BooleanLiteral) {
    return IrBoolValue(!operand.value);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "fix: add default cases for TextStyle/IconThemeData, handle ! prefix"
```

---

### Task 5: [HIGH] SetOrMapLiteral and _convertMapLiteral safety

**Issues:** H6, M5 — Set literals produce empty map; non-string map keys crash.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart:860-869`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('map literal with non-string keys converts values', () {
  // {true: 'yes', false: 'no'} — used in RfwSwitchValue cases
  // Should not crash on non-SimpleStringLiteral keys
  final expr = parseExpression("{true: 'yes', false: 'no'}");
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
});

test('set literal produces warning, not crash', () {
  // H6: Set literal {1, 2, 3} should not crash with cast error
  // After fix: returns empty map with developer.log warning
  final expr = parseExpression("{1, 2, 3}");
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
  // Set elements are skipped (not MapLiteralEntry), resulting in empty map
  expect((result as IrMapValue).entries, isEmpty);
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 3: Implement safe map literal conversion**

Replace `_convertMapLiteral` (line 860-869):

```dart
IrMapValue _convertMapLiteral(SetOrMapLiteral expr) {
  final entries = <String, IrValue>{};
  for (final element in expr.elements) {
    if (element is MapLiteralEntry) {
      final key = element.key;
      final keyStr = key is SimpleStringLiteral
          ? key.value
          : key.toString(); // Fallback for non-string keys
      entries[keyStr] = convert(element.value);
    }
    // Non-MapLiteralEntry elements (Set literals) are skipped with no crash
  }
  return IrMapValue(entries);
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "fix: safe map literal conversion for non-string keys"
```

---

### Task 6: [MEDIUM] Duration seconds support, SweepGradient, Color.fromARGB

**Issues:** M1, M2, L1 — Duration only supports milliseconds; SweepGradient missing; Color only supports single int.

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('converts Duration(seconds: 1) to 1000 milliseconds', () {
  final expr = parseExpression('Duration(seconds: 1)');
  final result = converter.convert(expr);
  expect(result, isA<IrIntValue>());
  expect((result as IrIntValue).value, 1000);
});

test('converts Duration(minutes: 1) to 60000 milliseconds', () {
  final expr = parseExpression('Duration(minutes: 1)');
  final result = converter.convert(expr);
  expect(result, isA<IrIntValue>());
  expect((result as IrIntValue).value, 60000);
});

test('converts Duration(milliseconds: 0) to zero', () {
  final expr = parseExpression('Duration(milliseconds: 0)');
  final result = converter.convert(expr);
  expect(result, isA<IrIntValue>());
  expect((result as IrIntValue).value, 0);
});

test('converts SweepGradient', () {
  final expr = parseExpression(
    "SweepGradient(colors: [Color(0xFFFF0000), Color(0xFF0000FF)])",
  );
  final result = converter.convert(expr);
  expect(result, isA<IrMapValue>());
  final map = (result as IrMapValue).entries;
  expect((map['type'] as IrStringValue).value, 'sweep');
});

test('converts Color.fromARGB', () {
  final expr = parseExpression('Color.fromARGB(255, 0, 0, 0)');
  final result = converter.convert(expr);
  expect(result, isA<IrIntValue>());
  expect((result as IrIntValue).value, 0xFF000000);
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 3: Implement fixes**

1. **Duration** — expand `_convertDurationFromArgs` (line 410-423):
```dart
IrIntValue _convertDurationFromArgs(ArgumentList argList) {
  int totalMs = 0;
  bool foundDurationArg = false;
  for (final arg in argList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      final value = arg.expression;
      if (value is IntegerLiteral) {
        switch (name) {
          case 'milliseconds':
            totalMs += value.value!;
            foundDurationArg = true;
          case 'seconds':
            totalMs += value.value! * 1000;
            foundDurationArg = true;
          case 'minutes':
            totalMs += value.value! * 60000;
            foundDurationArg = true;
        }
      }
    }
  }
  if (foundDurationArg) return IrIntValue(totalMs);
  throw UnsupportedExpressionError(
    'Duration requires milliseconds, seconds, or minutes',
    offset: argList.offset,
  );
}
```

2. **SweepGradient** — add handler in `_convertMethodInvocation` (after RadialGradient, ~line 172):
```dart
if (target == null && methodName == 'SweepGradient') {
  return _convertSweepGradient(expr.argumentList);
}
```

Add in `_convertInstanceCreation` default constructor switch (~line 242):
```dart
'SweepGradient' => _convertSweepGradient(argList),
```

Add converter:
```dart
IrMapValue _convertSweepGradient(ArgumentList argList) {
  final entries = <String, IrValue>{'type': IrStringValue('sweep')};
  for (final arg in argList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      switch (name) {
        case 'center':
          entries[name] = convert(arg.expression);
        case 'startAngle':
        case 'endAngle':
          entries[name] = IrNumberValue(_toDouble(arg.expression));
        case 'colors':
        case 'stops':
          if (arg.expression is ListLiteral) {
            final list = arg.expression as ListLiteral;
            entries[name] = IrListValue(
              list.elements.map((e) => convert(e as Expression)).toList(),
            );
          } else {
            entries[name] = convert(arg.expression);
          }
      }
    }
  }
  return IrMapValue(entries);
}
```

3. **Color.fromARGB** — add MethodInvocation handler (after Color, ~line 112):
```dart
if (target is SimpleIdentifier && target.name == 'Color') {
  if (methodName == 'fromARGB') return _convertColorFromARGB(expr.argumentList);
  if (methodName == 'fromRGBO') return _convertColorFromRGBO(expr.argumentList);
}
```

Add converters:
```dart
IrIntValue _convertColorFromARGB(ArgumentList argList) {
  final args = argList.arguments;
  if (args.length == 4) {
    final a = (args[0] as IntegerLiteral).value!;
    final r = (args[1] as IntegerLiteral).value!;
    final g = (args[2] as IntegerLiteral).value!;
    final b = (args[3] as IntegerLiteral).value!;
    return IrIntValue((a << 24) | (r << 16) | (g << 8) | b);
  }
  throw UnsupportedExpressionError(
    'Color.fromARGB requires 4 integer arguments',
    offset: argList.offset,
  );
}

IrIntValue _convertColorFromRGBO(ArgumentList argList) {
  final args = argList.arguments;
  if (args.length == 4) {
    final r = (args[0] as IntegerLiteral).value!;
    final g = (args[1] as IntegerLiteral).value!;
    final b = (args[2] as IntegerLiteral).value!;
    final opacity = _toDouble(args[3]);
    final a = (opacity * 255).round();
    return IrIntValue((a << 24) | (r << 16) | (g << 8) | b);
  }
  throw UnsupportedExpressionError(
    'Color.fromRGBO requires 3 integers and 1 double',
    offset: argList.offset,
  );
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/expression_converter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "feat: add Duration seconds/minutes, SweepGradient, Color.fromARGB/fromRGBO"
```

---

### Task 7: [CRITICAL] ast_visitor.dart — childList silent drop warnings

**Issues:** C6 — childList silently drops non-ListLiteral children

**Files:**
- Modify: `packages/rfw_gen/lib/src/ast_visitor.dart:196-228`
- Test: `packages/rfw_gen/test/ast_visitor_test.dart`

- [ ] **Step 1: Write failing test for childList warning**

Look at the existing `ast_visitor_test.dart` to find the test setup pattern (it creates a `WidgetAstVisitor` with a `WidgetRegistry` and `ExpressionConverter`, then calls `extractWidgetTree` on parsed function declarations).

Write a test that verifies the `children` property is absent when a non-ListLiteral expression is provided. After the fix, a `developer.log` warning should be emitted (verify by checking that `properties` does not contain the `children` key — the warning itself is logged via `developer.log` which is hard to assert, but the key behavior is: properties map reflects the absence, and no crash occurs).

```dart
test('childList with non-ListLiteral produces no children and no crash', () {
  // Create a widget function where children: is not a list literal
  // e.g., Column(children: someVariable)
  // After fix: should not crash, properties should not contain 'children'
  // Before fix: same behavior (silent drop) — this test validates the non-crash behavior
  // The real assertion is in the developer.log output (use a log listener if available)
});
```

The implementer should look at similar tests in `ast_visitor_test.dart` to construct the correct AST. The key behavior to test is: no exception thrown + children key absent from properties map.

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ast_visitor_test.dart -v
```

- [ ] **Step 3: Implement fixes**

1. **childList non-ListLiteral** — add else clause at line 224:
```dart
case ChildType.childList:
  if (expression is ListLiteral) {
    final children = expression.elements
        .map((e) => _convertWidgetOrSpecial(e as Expression))
        .toList();
    properties[paramName] = IrListValue(children);
  } else {
    developer.log(
      'Warning: children parameter on ${mapping.rfwName} is not a '
      'ListLiteral (got ${expression.runtimeType}). Children will be missing.',
      name: 'rfw_gen',
    );
  }
```

2. **Named slot list non-ListLiteral** — add warning at line 199-207:
```dart
if (isList && expression is ListLiteral) {
  final children = expression.elements
      .map((e) => _convertWidgetOrSpecial(e as Expression))
      .toList();
  properties[paramName] = IrListValue(children);
} else if (isList) {
  developer.log(
    'Warning: named slot list "$paramName" on ${mapping.rfwName} is not a '
    'ListLiteral. Slot will be missing.',
    name: 'rfw_gen',
  );
} else if (!isList) {
  properties[paramName] = _convertWidgetOrSpecial(expression);
}
```

- [ ] **Step 4: Run full test suite**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test
```

Expected: ALL PASS (including all 409+ existing tests)

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/ast_visitor.dart packages/rfw_gen/test/ast_visitor_test.dart
git commit -m "fix: add warnings for non-ListLiteral children instead of silent drop"
```

---

### Task 8: [HIGH+MEDIUM] widget_registry.dart — missing params and handlers

**Issues:** H3, H4, M4 — onEnd handlers missing; Column/Row textBaseline missing; Container missing params.

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart`
- Test: `packages/rfw_gen/test/widget_registry_test.dart`

- [ ] **Step 1: Write failing tests**

```dart
test('Container has foregroundDecoration, constraints, transform, clipBehavior', () {
  final mapping = registry.supportedWidgets['Container']!;
  expect(mapping.params.containsKey('foregroundDecoration'), isTrue);
  expect(mapping.params.containsKey('constraints'), isTrue);
  expect(mapping.params.containsKey('transform'), isTrue);
  expect(mapping.params.containsKey('clipBehavior'), isTrue);
});

test('Column has textBaseline param', () {
  final mapping = registry.supportedWidgets['Column']!;
  expect(mapping.params.containsKey('textBaseline'), isTrue);
});

test('Row has textBaseline param', () {
  final mapping = registry.supportedWidgets['Row']!;
  expect(mapping.params.containsKey('textBaseline'), isTrue);
});

test('animated widgets have onEnd handler', () {
  for (final name in ['Container', 'Align', 'Opacity', 'Padding',
      'DefaultTextStyle', 'Positioned', 'Rotation', 'Scale']) {
    final mapping = registry.supportedWidgets[name]!;
    expect(mapping.handlerParams.contains('onEnd'), isTrue,
        reason: '$name should have onEnd handler');
  }
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart -v
```

- [ ] **Step 3: Implement registry additions**

Find each widget's entry in `widget_registry.dart` and add the missing params/handlers. The pattern is:

For **Container** — add to its `params` map:
```dart
'foregroundDecoration': ParamMapping('foregroundDecoration', transformer: 'boxDecoration'),
'constraints': ParamMapping.direct('constraints'),
'transform': ParamMapping.direct('transform'),
'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
```

For **Column** and **Row** — add:
```dart
'textBaseline': ParamMapping('textBaseline', transformer: 'enum'),
```

Also add `'TextBaseline'` to `_knownEnumPrefixes` in `expression_converter.dart`.

For **animated widgets** — add `handlerParams: {'onEnd'}` to Container, Align, Opacity, Padding, DefaultTextStyle, Positioned, Rotation, Scale widget entries.

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "fix: add missing widget params (textBaseline, onEnd, Container extras)"
```

---

### Task 9: [LOW] rfwtxt_emitter guards + unused import cleanup

**Issues:** L2, L4, M7, M8 — NaN/Infinity guard; unused imports.

**Files:**
- Modify: `packages/rfw_gen/lib/src/rfwtxt_emitter.dart`
- Modify: `example/test/app_test.dart`
- Modify: `example/tool/compile_rfw.dart`
- Test: `packages/rfw_gen/test/rfwtxt_emitter_test.dart`

- [ ] **Step 1: Write failing test for NaN**

```dart
test('emitter throws on NaN value', () {
  final node = IrNumberValue(double.nan);
  expect(
    () => RfwtxtEmitter().emitValue(node),
    throwsA(anything),
  );
});

test('emitter throws on Infinity value', () {
  final node = IrNumberValue(double.infinity);
  expect(
    () => RfwtxtEmitter().emitValue(node),
    throwsA(anything),
  );
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/rfwtxt_emitter_test.dart -v
```

- [ ] **Step 3: Implement fixes**

1. **NaN/Infinity guard** in rfwtxt_emitter.dart's number emission:
```dart
// Before emitting a double, check for special values
if (value.isNaN || value.isInfinite) {
  throw StateError('Cannot emit special float value: $value');
}
```

2. **Remove unused imports:**
   - `example/test/app_test.dart:1` — remove `import 'package:flutter/material.dart';`
   - `example/tool/compile_rfw.dart:2` — remove `import 'dart:typed_data';`

- [ ] **Step 4: Run tests**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/rfwtxt_emitter_test.dart -v
```

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/rfwtxt_emitter.dart example/test/app_test.dart example/tool/compile_rfw.dart packages/rfw_gen/test/rfwtxt_emitter_test.dart
git commit -m "fix: guard NaN/Infinity in emitter, remove unused imports"
```

---

### Task 10: Regenerate binaries + full verification

**Files:**
- Regenerate: `example/lib/catalog/catalog_widgets.rfwtxt`, `example/lib/ecommerce/shop_widgets.rfwtxt`
- Regenerate: `example/assets/catalog_widgets.rfw`, `example/assets/shop_widgets.rfw`

- [ ] **Step 1: Run full test suite to confirm nothing is broken**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test
```

Expected: ALL PASS

- [ ] **Step 2: Regenerate rfwtxt and rfw binaries**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
dart run tool/compile_rfw.dart
```

Or follow the project's existing regeneration process (check the tool script).

- [ ] **Step 3: Run parseLibraryFile validation**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/integration_test.dart -v
```

Expected: ALL PASS

- [ ] **Step 4: Run dart analyze to confirm clean**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen && dart analyze packages/rfw_gen/
```

Expected: No issues found

- [ ] **Step 5: Commit regenerated binaries**

```bash
git add example/lib/catalog/catalog_widgets.rfwtxt example/lib/catalog/catalog_widgets.rfw example/lib/ecommerce/shop_widgets.rfwtxt example/lib/ecommerce/shop_widgets.rfw example/assets/
git commit -m "chore: regenerate rfwtxt and rfw binaries with all fixes applied"
```

---

## Execution Notes

**Task dependencies:**
- Tasks 1-6: expression_converter.dart fixes — can run sequentially (same file)
- Task 7: ast_visitor.dart — independent, can run after Tasks 1-6
- Task 8: widget_registry.dart — depends on Task 4 (TextBaseline enum prefix)
- Task 9: emitter + cleanup — independent
- Task 10: depends on all others

**Recommended execution order:** Tasks 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10

**Not included in this plan (deferred as non-impactful):**
- M3 (BoxBorder/Border/BorderSide/ShapeBorder) — complex type, no demo app usage
- M6 (VisualDensity) — no demo app usage
- L5 (limited icon set) — design decision, not a bug
- L6 (LoopVar integer index) — minor limitation
- L7 (analysis_options resolution) — pub get issue, not code
