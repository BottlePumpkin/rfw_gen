# Type Safety Improvement Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce `ignore_for_file` entries from 6 to 2 in `@RfwWidget` template files.

**Architecture:** Add 5 RFW-only widget classes to eliminate `undefined_function`. Update Icon WidgetMapping to support positional param and fix Placeholder param aliases to eliminate `undefined_named_parameter` + `not_enough_positional_arguments`. Update example files accordingly.

**Tech Stack:** Dart, package:analyzer (AST), rfw_gen

---

### Task 1: Create RFW-only widget classes

**Files:**
- Create: `packages/rfw_gen/lib/src/rfw_only_widgets.dart`
- Modify: `packages/rfw_gen/lib/rfw_gen.dart`
- Test: `packages/rfw_gen/test/rfw_only_widgets_test.dart`

- [ ] **Step 1: Write the test file**

```dart
// packages/rfw_gen/test/rfw_only_widgets_test.dart
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('RFW-only widget classes', () {
    test('SizedBoxShrink can be constructed', () {
      const w = SizedBoxShrink();
      expect(w.child, isNull);
    });

    test('SizedBoxShrink with child', () {
      const w = SizedBoxShrink(child: 'placeholder');
      expect(w.child, equals('placeholder'));
    });

    test('SizedBoxExpand can be constructed', () {
      const w = SizedBoxExpand();
      expect(w.child, isNull);
    });

    test('Rotation accepts all params', () {
      const w = Rotation(
        turns: 0.25,
        alignment: 'center',
        duration: 300,
        curve: 'easeIn',
        child: 'placeholder',
        onEnd: 'handler',
      );
      expect(w.turns, equals(0.25));
      expect(w.alignment, equals('center'));
      expect(w.duration, equals(300));
      expect(w.curve, equals('easeIn'));
      expect(w.child, equals('placeholder'));
      expect(w.onEnd, equals('handler'));
    });

    test('Scale accepts all params', () {
      const w = Scale(
        scale: 2.0,
        alignment: 'center',
        duration: 300,
        curve: 'easeOut',
        child: 'placeholder',
        onEnd: 'handler',
      );
      expect(w.scale, equals(2.0));
      expect(w.child, equals('placeholder'));
    });

    test('AnimationDefaults accepts all params', () {
      const w = AnimationDefaults(
        duration: 600,
        curve: 'fastOutSlowIn',
        child: 'placeholder',
      );
      expect(w.duration, equals(600));
      expect(w.curve, equals('fastOutSlowIn'));
      expect(w.child, equals('placeholder'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen && dart test test/rfw_only_widgets_test.dart`
Expected: FAIL — classes not found

- [ ] **Step 3: Create rfw_only_widgets.dart**

```dart
// packages/rfw_gen/lib/src/rfw_only_widgets.dart

/// RFW-only widgets — widgets supported by RFW's `createCoreWidgets()`
/// that have no matching class name in Flutter.
///
/// These classes exist solely for build-time AST parsing by rfw_gen.
/// They are never instantiated at runtime.

/// RFW equivalent of `SizedBox.shrink()`. Constrains child to 0×0.
class SizedBoxShrink {
  final Object? child;
  const SizedBoxShrink({this.child});
}

/// RFW equivalent of `SizedBox.expand()`. Expands child to fill available space.
class SizedBoxExpand {
  final Object? child;
  const SizedBoxExpand({this.child});
}

/// Rotation transform with implicit animation support.
/// RFW equivalent of Flutter's `RotatedBox` / `RotationTransition`.
class Rotation {
  final Object? turns;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Rotation({this.turns, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// Scale transform with implicit animation support.
/// RFW equivalent of Flutter's `Transform.scale`.
class Scale {
  final Object? scale;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Scale({this.scale, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// Sets default animation duration and curve for descendant widgets.
/// RFW-only concept with no direct Flutter equivalent.
class AnimationDefaults {
  final Object? duration;
  final Object? curve;
  final Object? child;
  const AnimationDefaults({this.duration, this.curve, this.child});
}
```

- [ ] **Step 4: Add export to rfw_gen.dart**

Add this line to `packages/rfw_gen/lib/rfw_gen.dart`:

```dart
export 'src/rfw_only_widgets.dart';
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd packages/rfw_gen && dart test test/rfw_only_widgets_test.dart`
Expected: PASS

- [ ] **Step 6: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS

- [ ] **Step 7: Commit**

```bash
git add packages/rfw_gen/lib/src/rfw_only_widgets.dart packages/rfw_gen/lib/rfw_gen.dart packages/rfw_gen/test/rfw_only_widgets_test.dart
git commit -m "feat: add RFW-only widget classes (SizedBoxShrink, SizedBoxExpand, Rotation, Scale, AnimationDefaults)"
```

---

### Task 2: Add positional param support for Icon in WidgetRegistry

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart:518-528`
- Test: `packages/rfw_gen/test/widget_registry_test.dart`

현재 Icon WidgetMapping에 `positionalParam`이 없어서 `Icon(RfwIcon.home)` positional 사용 시 AST visitor가 icon 값을 무시한다. `positionalParam: 'icon'`을 추가해서 positional과 named 모두 지원하게 한다.

- [ ] **Step 1: Write failing test**

`packages/rfw_gen/test/widget_registry_test.dart`의 Icon 테스트 그룹에 추가:

```dart
test('Icon supports positional param for icon', () {
  final mapping = registry.supportedWidgets['Icon']!;
  expect(mapping.positionalParam, equals('icon'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "Icon supports positional"`
Expected: FAIL — `positionalParam` is null

- [ ] **Step 3: Add positionalParam to Icon WidgetMapping**

In `packages/rfw_gen/lib/src/widget_registry.dart`, find the `'Icon'` entry (line ~518) and add `positionalParam: 'icon'`:

```dart
'Icon': WidgetMapping(
  rfwName: 'core.Icon',
  import: 'core.widgets',
  childType: ChildType.none,
  positionalParam: 'icon',  // ← 추가
  params: {
    'icon': ParamMapping('iconData', transformer: 'iconData'),
    'size': ParamMapping.direct('size'),
    'color': ParamMapping('color', transformer: 'color'),
    'semanticLabel': ParamMapping.direct('semanticLabel'),
  },
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "Icon supports positional"`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "feat: add positional param support for Icon widget"
```

---

### Task 3: Add Placeholder Flutter param aliases

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart:567-577`
- Test: `packages/rfw_gen/test/widget_registry_test.dart`

Flutter의 `Placeholder`는 `fallbackWidth`/`fallbackHeight`를 사용하고, RFW는 `placeholderWidth`/`placeholderHeight`를 사용한다. Flutter 이름을 별칭으로 추가해서 사용자가 어느 쪽이든 쓸 수 있게 한다.

- [ ] **Step 1: Write failing test**

`packages/rfw_gen/test/widget_registry_test.dart`의 Placeholder 테스트에 추가:

```dart
test('Placeholder accepts both Flutter and RFW param names', () {
  final mapping = registry.supportedWidgets['Placeholder']!;
  expect(mapping.params.containsKey('fallbackWidth'), isTrue);
  expect(mapping.params.containsKey('fallbackHeight'), isTrue);
  expect(mapping.params['fallbackWidth']!.rfwName, equals('placeholderWidth'));
  expect(mapping.params['fallbackHeight']!.rfwName, equals('placeholderHeight'));
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "Placeholder accepts both"`
Expected: FAIL

- [ ] **Step 3: Add Flutter aliases to Placeholder**

In `packages/rfw_gen/lib/src/widget_registry.dart`, update the Placeholder entry:

```dart
'Placeholder': WidgetMapping(
  rfwName: 'core.Placeholder',
  import: 'core.widgets',
  childType: ChildType.none,
  params: {
    'color': ParamMapping('color', transformer: 'color'),
    'strokeWidth': ParamMapping.direct('strokeWidth'),
    'placeholderWidth': ParamMapping.direct('placeholderWidth'),
    'placeholderHeight': ParamMapping.direct('placeholderHeight'),
    // Flutter aliases
    'fallbackWidth': ParamMapping.direct('placeholderWidth'),
    'fallbackHeight': ParamMapping.direct('placeholderHeight'),
  },
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/rfw_gen && dart test test/widget_registry_test.dart --name "Placeholder accepts both"`
Expected: PASS

- [ ] **Step 5: Run full test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS

- [ ] **Step 6: Commit**

```bash
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "feat: add Flutter param aliases for Placeholder (fallbackWidth/fallbackHeight)"
```

---

### Task 4: Update example files — Icon usage

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`
- Modify: `example/lib/ecommerce/shop_widgets.dart`

모든 `Icon(icon: ...)` 패턴을 `Icon(...)` positional로 변경한다. 16개 변경 지점.

- [ ] **Step 1: Update catalog_widgets.dart Icon calls**

모든 `Icon(icon: X, ...)` → `Icon(X, ...)` 변경. 대상 라인:
- 367, 368, 369, 381, 382, 383, 615, 676, 679, 684, 717, 722

예시:
```dart
// Before
Icon(icon: RfwIcon.home, size: 32.0, color: const Color(0xFF2196F3))
// After
Icon(RfwIcon.home, size: 32.0, color: const Color(0xFF2196F3))
```

- [ ] **Step 2: Update shop_widgets.dart Icon calls**

대상 라인: 64, 350, 361, 415

예시:
```dart
// Before
Icon(icon: RfwIcon.check, size: 80.0, color: const Color(0xFF4CAF50))
// After
Icon(RfwIcon.check, size: 80.0, color: const Color(0xFF4CAF50))
```

주의: `cat['icon']` (LoopVar)도 positional로 변경:
```dart
// Before
Icon(icon: cat['icon'], size: 32.0, color: const Color(0xFF2196F3))
// After
Icon(cat['icon'], size: 32.0, color: const Color(0xFF2196F3))
```

- [ ] **Step 3: Update Placeholder to use Flutter param names**

`example/lib/catalog/catalog_widgets.dart` line 424-425:
```dart
// Before
placeholderWidth: 100.0,
placeholderHeight: 50.0,
// After
fallbackWidth: 100.0,
fallbackHeight: 50.0,
```

- [ ] **Step 4: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart example/lib/ecommerce/shop_widgets.dart
git commit -m "refactor: change Icon to positional param, Placeholder to Flutter aliases"
```

---

### Task 5: Clean up ignore_for_file and verify

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart:1`
- Modify: `example/lib/ecommerce/shop_widgets.dart:1`

- [ ] **Step 1: Update ignore_for_file in both files**

`example/lib/catalog/catalog_widgets.dart` line 1:
```dart
// Before
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments
// After
// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
```

`example/lib/ecommerce/shop_widgets.dart` line 1:
```dart
// Before
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments, list_element_type_not_assignable
// After
// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
```

- [ ] **Step 2: Add rfw_only_widgets import to example files**

Both files need to import rfw_gen (which now exports the RFW-only widgets). Verify existing import:
```dart
import 'package:rfw_gen/rfw_gen.dart';  // already present
```

이미 `rfw_gen.dart`를 import하고 있으므로 추가 작업 불필요.

- [ ] **Step 3: Run flutter analyze to verify only 2 ignore types needed**

Run: `cd example && flutter analyze 2>&1`
Expected: 0 errors (all remaining issues covered by the 2 ignores)

- [ ] **Step 4: Run rfw_gen test suite**

Run: `cd packages/rfw_gen && dart test`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart example/lib/ecommerce/shop_widgets.dart
git commit -m "chore: reduce ignore_for_file from 6 to 2"
```

---

### Task 6: Add integration test for RFW-only widgets through full pipeline

**Files:**
- Modify: `packages/rfw_gen/test/integration_test.dart`

RFW-only 위젯이 AST → IR → rfwtxt 전체 파이프라인을 통과하는지 검증한다.

- [ ] **Step 1: Check existing integration test patterns**

Read `packages/rfw_gen/test/integration_test.dart` to understand the test pattern.

- [ ] **Step 2: Add integration tests for RFW-only widgets**

```dart
test('Rotation widget converts to rfwtxt', () {
  final source = '''
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('rotationDemo')
Widget build() {
  return Rotation(
    turns: 0.25,
    child: Container(width: 60.0, height: 60.0),
  );
}
''';
  final result = convertSource(source);
  final expected = parseLibraryFile(result);
  expect(expected, isNotNull);
  expect(result, contains('Rotation('));
  expect(result, contains('turns: 0.25'));
});

test('AnimationDefaults widget converts to rfwtxt', () {
  final source = '''
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('animDefaultsDemo')
Widget build() {
  return AnimationDefaults(
    duration: const Duration(milliseconds: 600),
    curve: Curves.fastOutSlowIn,
    child: Container(width: 100.0, height: 100.0),
  );
}
''';
  final result = convertSource(source);
  final expected = parseLibraryFile(result);
  expect(expected, isNotNull);
  expect(result, contains('AnimationDefaults('));
});

test('SizedBoxShrink widget converts to rfwtxt', () {
  final source = '''
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('shrinkDemo')
Widget build() {
  return SizedBoxShrink();
}
''';
  final result = convertSource(source);
  final expected = parseLibraryFile(result);
  expect(expected, isNotNull);
  expect(result, contains('SizedBoxShrink('));
});
```

- [ ] **Step 3: Run integration tests**

Run: `cd packages/rfw_gen && dart test test/integration_test.dart`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen/test/integration_test.dart
git commit -m "test: add integration tests for RFW-only widgets through full pipeline"
```
