# Spec-Implementation Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 7 gaps between rfw spec docs and implementation, and add sync tests to prevent future gaps.

**Architecture:** Phase 1 fixes missing params (Column/Row textDirection, Card shape) and adds ShapeBorder type converters. Phase 2 adds `spec_sync_test.dart` with 3 sync tests that automatically verify WidgetRegistry ↔ ExpressionConverter consistency.

**Tech Stack:** Dart, package:analyzer (AST parsing), package:test, package:rfw (parseLibraryFile)

**Spec:** `docs/superpowers/specs/2026-03-24-spec-impl-sync-design.md`

---

## File Structure

### Modified Files
- `packages/rfw_gen/lib/src/widget_registry.dart` — Add textDirection to Column/Row, shape to Card
- `packages/rfw_gen/lib/src/expression_converter.dart` — Add ShapeBorder converters (3 types)
- `packages/rfw_gen/test/expression_converter_test.dart` — ShapeBorder unit tests
- `packages/rfw_gen/test/widget_registry_test.dart` — Updated param tests, widget count 56→56 (params increase)
- `.claude/rules/rfw-widgets.md` — Add visualDensity to ListTile table

### New Files
- `packages/rfw_gen/test/spec_sync_test.dart` — 3 sync tests (Registry↔Converter, regression guard, e2e)

---

### Task 1: Add textDirection param to Column and Row in WidgetRegistry

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart:216-225` (Column), `:232-241` (Row)
- Test: `packages/rfw_gen/test/widget_registry_test.dart`

- [ ] **Step 1: Write failing tests for Column and Row textDirection**

In `packages/rfw_gen/test/widget_registry_test.dart`, add inside the existing `group('Missing params and handlers', ...)` (after the Row textBaseline test ~line 711, before the Container additional params test ~line 714):

```dart
test('Column has textDirection param', () {
  final mapping = registry.supportedWidgets['Column']!;
  expect(mapping.params.containsKey('textDirection'), isTrue);
  expect(mapping.params['textDirection']!.transformer, equals('enum'));
});

test('Row has textDirection param', () {
  final mapping = registry.supportedWidgets['Row']!;
  expect(mapping.params.containsKey('textDirection'), isTrue);
  expect(mapping.params['textDirection']!.transformer, equals('enum'));
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "textDirection"`
Expected: FAIL — `textDirection` not found in params

- [ ] **Step 3: Add textDirection to Column params**

In `packages/rfw_gen/lib/src/widget_registry.dart`, inside `Column`'s params map (after `textBaseline` line ~224):

```dart
'textBaseline': ParamMapping('textBaseline', transformer: 'enum'),
'textDirection': ParamMapping('textDirection', transformer: 'enum'),
```

- [ ] **Step 4: Add textDirection to Row params**

Same location in `Row`'s params map (after `textBaseline` line ~240):

```dart
'textBaseline': ParamMapping('textBaseline', transformer: 'enum'),
'textDirection': ParamMapping('textDirection', transformer: 'enum'),
```

- [ ] **Step 5: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart`
Expected: ALL PASS

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "fix: add missing textDirection param to Column and Row"
```

---

### Task 2: Add ShapeBorder converters to ExpressionConverter

**Files:**
- Modify: `packages/rfw_gen/lib/src/expression_converter.dart`
- Test: `packages/rfw_gen/test/expression_converter_test.dart`

- [ ] **Step 1: Write failing tests for RoundedRectangleBorder**

In `packages/rfw_gen/test/expression_converter_test.dart`, add a new group after the `'VisualDensity'` group (after ~line 1489, before the closing `}` of `main()`):

```dart
group('ShapeBorder', () {
  test('converts RoundedRectangleBorder() with no args', () {
    final expr = parseExpression('RoundedRectangleBorder()');
    final result = converter.convert(expr);
    expect(result, isA<IrMapValue>());
    final map = (result as IrMapValue).entries;
    expect((map['type'] as IrStringValue).value, 'rounded');
  });

  test('converts RoundedRectangleBorder with borderRadius', () {
    final expr = parseExpression(
      'RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))',
    );
    final result = converter.convert(expr);
    final map = (result as IrMapValue).entries;
    expect((map['type'] as IrStringValue).value, 'rounded');
    expect(map.containsKey('borderRadius'), isTrue);
    expect(map['borderRadius'], isA<IrListValue>());
  });

  test('converts RoundedRectangleBorder with side and borderRadius', () {
    final expr = parseExpression(
      'RoundedRectangleBorder('
      '  side: BorderSide(color: Color(0xFF000000), width: 2.0),'
      '  borderRadius: BorderRadius.circular(12.0),'
      ')',
    );
    final result = converter.convert(expr);
    final map = (result as IrMapValue).entries;
    expect((map['type'] as IrStringValue).value, 'rounded');
    expect(map.containsKey('side'), isTrue);
    final side = (map['side'] as IrMapValue).entries;
    expect((side['color'] as IrIntValue).value, 0xFF000000);
    expect((side['width'] as IrNumberValue).value, 2.0);
    expect(map.containsKey('borderRadius'), isTrue);
  });
});
```

- [ ] **Step 2: Write failing tests for CircleBorder and StadiumBorder**

Add to the same `'ShapeBorder'` group:

```dart
test('converts CircleBorder() with no args', () {
  final expr = parseExpression('CircleBorder()');
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect((map['type'] as IrStringValue).value, 'circle');
});

test('converts CircleBorder with side', () {
  final expr = parseExpression(
    'CircleBorder(side: BorderSide(color: Color(0xFFFF0000), width: 1.0))',
  );
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect((map['type'] as IrStringValue).value, 'circle');
  expect(map.containsKey('side'), isTrue);
  final side = (map['side'] as IrMapValue).entries;
  expect((side['color'] as IrIntValue).value, 0xFFFF0000);
});

test('converts StadiumBorder() with no args', () {
  final expr = parseExpression('StadiumBorder()');
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect((map['type'] as IrStringValue).value, 'stadium');
});

test('converts StadiumBorder with side', () {
  final expr = parseExpression(
    'StadiumBorder(side: BorderSide(color: Color(0xFF0000FF), width: 3.0))',
  );
  final result = converter.convert(expr);
  final map = (result as IrMapValue).entries;
  expect((map['type'] as IrStringValue).value, 'stadium');
  expect(map.containsKey('side'), isTrue);
});
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `cd packages/rfw_gen && dart test test/expression_converter_test.dart --name "ShapeBorder"`
Expected: FAIL — `Unsupported method invocation: RoundedRectangleBorder`

- [ ] **Step 4: Implement ShapeBorder converter method**

In `packages/rfw_gen/lib/src/expression_converter.dart`, add after the `_convertBorder()` method (after line ~1276):

```dart
/// Converts `RoundedRectangleBorder(side: ..., borderRadius: ...)`,
/// `CircleBorder(side: ...)`, and `StadiumBorder(side: ...)`.
IrMapValue _convertShapeBorder(String className, ArgumentList argList) {
  final type = switch (className) {
    'RoundedRectangleBorder' => 'rounded',
    'CircleBorder' => 'circle',
    'StadiumBorder' => 'stadium',
    _ => throw UnsupportedExpressionError(
        'Unsupported ShapeBorder: $className',
        offset: argList.offset,
      ),
  };
  final entries = <String, IrValue>{'type': IrStringValue(type)};
  for (final arg in argList.arguments) {
    if (arg is NamedExpression) {
      final name = arg.name.label.name;
      switch (name) {
        case 'side':
          entries[name] = convert(arg.expression);
        case 'borderRadius':
          entries[name] = convert(arg.expression);
      }
    }
  }
  return IrMapValue(entries);
}
```

- [ ] **Step 5: Register ShapeBorder in _convertMethodInvocation**

In `_convertMethodInvocation()`, add before the final `throw` (before line ~229):

```dart
// RoundedRectangleBorder/CircleBorder/StadiumBorder(...) — ShapeBorder types
if (target == null && const {'RoundedRectangleBorder', 'CircleBorder', 'StadiumBorder'}.contains(methodName)) {
  return _convertShapeBorder(methodName, expr.argumentList);
}
```

- [ ] **Step 6: Register ShapeBorder in _convertInstanceCreation**

In `_convertInstanceCreation()`, add to the default constructor switch after the `'VisualDensity'` case (~line 295), before the `_ when _knownGridDelegates` catch-all (~line 296):

```dart
'RoundedRectangleBorder' => _convertShapeBorder(className, argList),
'CircleBorder' => _convertShapeBorder(className, argList),
'StadiumBorder' => _convertShapeBorder(className, argList),
```

- [ ] **Step 7: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/expression_converter_test.dart --name "ShapeBorder"`
Expected: ALL PASS

- [ ] **Step 8: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: ALL PASS

- [ ] **Step 9: Commit**

```bash
git add packages/rfw_gen/lib/src/expression_converter.dart packages/rfw_gen/test/expression_converter_test.dart
git commit -m "feat: add ShapeBorder converters (RoundedRectangleBorder, CircleBorder, StadiumBorder)"
```

---

### Task 3: Add shape param to Card in WidgetRegistry

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart:846-856`
- Test: `packages/rfw_gen/test/widget_registry_test.dart`

- [ ] **Step 1: Write failing test for Card.shape**

In `packages/rfw_gen/test/widget_registry_test.dart`, add inside `group('Material widgets', ...)`:

```dart
test('Card has shape param with shapeBorder transformer', () {
  final w = registry.supportedWidgets['Card']!;
  expect(w.params.containsKey('shape'), isTrue);
  expect(w.params['shape']!.transformer, equals('shapeBorder'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "Card has shape"`
Expected: FAIL

- [ ] **Step 3: Add shape param to Card**

In `packages/rfw_gen/lib/src/widget_registry.dart`, inside `Card`'s params map (after `margin` line ~854):

```dart
'margin': ParamMapping('margin', transformer: 'edgeInsets'),
'shape': ParamMapping('shape', transformer: 'shapeBorder'),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart`
Expected: ALL PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "fix: add missing shape param to Card widget"
```

---

### Task 4: Update rfw-widgets.md documentation

**Files:**
- Modify: `.claude/rules/rfw-widgets.md`

- [ ] **Step 1: Add visualDensity to ListTile in rfw-widgets.md**

In `.claude/rules/rfw-widgets.md`, find the ListTile row and update:

Change:
```
| **ListTile** | dense, enabled, selected, contentPadding |
```
To:
```
| **ListTile** | dense, enabled, selected, contentPadding, visualDensity |
```

- [ ] **Step 2: Commit**

```bash
git add .claude/rules/rfw-widgets.md
git commit -m "docs: add visualDensity to ListTile in rfw-widgets.md"
```

---

### Task 5: Create spec_sync_test.dart — Test 1 (Registry ↔ Converter consistency)

**Files:**
- Create: `packages/rfw_gen/test/spec_sync_test.dart`

This is the most important test. It verifies that every transformer key registered in WidgetRegistry has a working ExpressionConverter path.

- [ ] **Step 1: Write the sync test file with Test 1**

Create `packages/rfw_gen/test/spec_sync_test.dart`:

```dart
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

Expression parseExpression(String code) {
  final result = parseString(content: 'final x = $code;');
  final unit = result.unit;
  final decl = unit.declarations.first as TopLevelVariableDeclaration;
  return decl.variables.variables.first.initializer!;
}

/// Maps each transformer key to a representative Flutter expression.
/// If a new transformer key is added to WidgetRegistry without an entry here,
/// Test 1 will fail — forcing the developer to also add converter support.
const _sampleExpressions = <String?, String>{
  'color': 'Color(0xFF000000)',
  'edgeInsets': 'EdgeInsets.all(8.0)',
  'enum': '"start"',
  'alignment': 'Alignment.center',
  'borderRadius': 'BorderRadius.circular(8.0)',
  'textStyle': 'TextStyle(fontSize: 14.0)',
  'boxDecoration': 'BoxDecoration(color: Color(0xFF000000))',
  'shapeBorder': 'RoundedRectangleBorder()',
  'duration': 'Duration(milliseconds: 300)',
  'curve': 'Curves.easeInOut',
  'iconData': 'RfwIcon.home',
  'imageProvider': 'NetworkImage("https://example.com/img.png")',
  'visualDensity': 'VisualDensity.compact',
  'gridDelegate':
      'SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)',
  null: '16.0', // direct pass-through (ParamMapping.direct)
};

void main() {
  late WidgetRegistry registry;
  late ExpressionConverter converter;

  setUp(() {
    registry = WidgetRegistry.core();
    converter = ExpressionConverter();
  });

  group('Spec sync: Registry ↔ Converter consistency', () {
    test('every transformer key has a sample expression', () {
      final allTransformers = <String?>{};
      for (final widget in registry.supportedWidgets.values) {
        for (final param in widget.params.values) {
          allTransformers.add(param.transformer);
        }
      }

      for (final key in allTransformers) {
        expect(
          _sampleExpressions.containsKey(key),
          isTrue,
          reason: 'Transformer "$key" has no sample expression in '
              '_sampleExpressions. Add one to ensure converter coverage.',
        );
      }
    });

    test('every sample expression converts without error', () {
      for (final entry in _sampleExpressions.entries) {
        final key = entry.key;
        final code = entry.value;
        final expr = parseExpression(code);
        expect(
          () => converter.convert(expr),
          returnsNormally,
          reason: 'Converter failed for transformer "$key" '
              'with expression: $code',
        );
      }
    });

    test('every widget param can be converted via its transformer', () {
      for (final entry in registry.supportedWidgets.entries) {
        final widgetName = entry.key;
        final widget = entry.value;
        for (final paramEntry in widget.params.entries) {
          final paramName = paramEntry.key;
          final transformer = paramEntry.value.transformer;
          final code = _sampleExpressions[transformer];
          if (code == null) continue; // covered by first test

          final expr = parseExpression(code);
          expect(
            () => converter.convert(expr),
            returnsNormally,
            reason: '$widgetName.$paramName (transformer: $transformer) '
                'failed with expression: $code',
          );
        }
      }
    });
  });
}
```

- [ ] **Step 2: Run Test 1 to verify it passes**

Run: `cd packages/rfw_gen && dart test test/spec_sync_test.dart`
Expected: ALL PASS (since we just fixed all gaps in Tasks 1-3)

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen/test/spec_sync_test.dart
git commit -m "test: add Registry ↔ Converter consistency sync test"
```

---

### Task 6: Add Test 2 (regression guard) to spec_sync_test.dart

**Files:**
- Modify: `packages/rfw_gen/test/spec_sync_test.dart`

- [ ] **Step 1: Calculate current param + handler counts**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "contains exactly"`
Note the widget count (should be 56).

Then add a temporary test to calculate total params. Or just count from the registry — we need the exact number after Task 1 and Task 3 changes.

- [ ] **Step 2: Add regression guard tests**

Append to `packages/rfw_gen/test/spec_sync_test.dart`, inside `main()`:

```dart
group('Spec sync: Regression guard', () {
  test('widget count does not regress', () {
    expect(
      registry.supportedWidgets.length,
      greaterThanOrEqualTo(56),
      reason: 'Widget count decreased. Did you accidentally remove a widget?',
    );
  });

  test('total param + handler count does not regress', () {
    var totalParams = 0;
    var totalHandlers = 0;
    for (final widget in registry.supportedWidgets.values) {
      totalParams += widget.params.length;
      totalHandlers += widget.handlerParams.length;
    }
    // Print for visibility when updating the baseline
    // ignore: avoid_print
    print('Current counts: params=$totalParams, handlers=$totalHandlers, '
        'total=${totalParams + totalHandlers}');
    expect(
      totalParams + totalHandlers,
      greaterThanOrEqualTo(145), // baseline after gap fixes, update when adding
      reason: 'Total param+handler count decreased. '
          'Did you accidentally remove params?',
    );
  });
});
```

Note: The `145` baseline should be verified at implementation time by running the print statement. Adjust the number to match the actual count after Tasks 1-3.

- [ ] **Step 3: Run to verify it passes and note actual counts**

Run: `cd packages/rfw_gen && dart test test/spec_sync_test.dart --name "Regression"`
Expected: PASS. Note the printed counts and adjust the baseline if needed.

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen/test/spec_sync_test.dart
git commit -m "test: add widget/param regression guard"
```

---

### Task 7: Add Test 3 (e2e rfwtxt parsing) to spec_sync_test.dart

**Files:**
- Modify: `packages/rfw_gen/test/spec_sync_test.dart`

This test verifies that key widgets with all their params produce valid rfwtxt that `parseLibraryFile()` can parse.

- [ ] **Step 1: Add e2e sync test for core widgets**

Append to `packages/rfw_gen/test/spec_sync_test.dart`, add import at top:

```dart
import 'package:rfw/formats.dart';
```

Then add inside `main()`:

```dart
group('Spec sync: End-to-end rfwtxt parsing', () {
  late RfwConverter rfwConverter;

  setUp(() {
    rfwConverter = RfwConverter(registry: WidgetRegistry.core());
  });

  test('Container with all params produces parseable rfwtxt', () {
    const input = '''
Widget build() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.all(8.0),
    color: Color(0xFF000000),
    width: 100.0,
    height: 50.0,
    clipBehavior: Clip.hardEdge,
    margin: EdgeInsets.symmetric(horizontal: 4.0),
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: Text('hello'),
  );
}
''';
    final rfwtxt = rfwConverter.convertFromSource(input);
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('Card with shape produces parseable rfwtxt', () {
    const input = '''
Widget build() {
  return Card(
    color: Color(0xFFFFFFFF),
    elevation: 4.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: Color(0xFF000000), width: 1.0),
    ),
    margin: EdgeInsets.all(8.0),
    child: Text('card'),
  );
}
''';
    final rfwtxt = rfwConverter.convertFromSource(input);
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });

  test('Row with textDirection produces parseable rfwtxt', () {
    const input = '''
Widget build() {
  return Row(
    textDirection: TextDirection.rtl,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('a'), Text('b')],
  );
}
''';
    final rfwtxt = rfwConverter.convertFromSource(input);
    expect(() => parseLibraryFile(rfwtxt), returnsNormally);
  });
});
```

- [ ] **Step 2: Run e2e tests**

Run: `cd packages/rfw_gen && dart test test/spec_sync_test.dart --name "End-to-end"`
Expected: ALL PASS

- [ ] **Step 3: Run full test suite to ensure nothing is broken**

Run: `cd packages/rfw_gen && dart test`
Expected: ALL PASS

- [ ] **Step 4: Run dart analyze**

Run: `cd packages/rfw_gen && dart analyze`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen/test/spec_sync_test.dart
git commit -m "test: add e2e rfwtxt parsing sync tests for gap-fixed widgets"
```

---

### Task 8: Update widget_registry_test.dart widget count

**Files:**
- Modify: `packages/rfw_gen/test/widget_registry_test.dart:87-88`

The widget count is still 56 (we added params, not widgets), but verify and update if needed.

- [ ] **Step 1: Verify widget count test still passes**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "contains exactly"`
Expected: PASS with 56

- [ ] **Step 2: Run complete test suite one final time**

Run: `cd packages/rfw_gen && dart test`
Expected: ALL PASS

- [ ] **Step 3: Final commit if any adjustments were needed**

Only commit if there were changes:
```bash
git add packages/rfw_gen/test/widget_registry_test.dart
git commit -m "chore: finalize spec-impl sync gap fixes and tests"
```
