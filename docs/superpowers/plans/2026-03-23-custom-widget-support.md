# Custom Widget Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable rfw_gen users to register custom widgets via `rfw_gen.yaml` so Dart code using those widgets converts to valid rfwtxt.

**Architecture:** Three changes — (1) widget-value param auto-detection in `ast_visitor.dart`, (2) `registerFromConfig()` in `widget_registry.dart`, (3) `rfw_gen.yaml` loading in builder. Changes are ordered so each step is independently testable.

**Tech Stack:** Dart, `package:analyzer`, `package:build`, `package:yaml`, `package:test`, `package:build_test`

**Spec:** `docs/superpowers/specs/2026-03-23-custom-widget-support-design.md`

---

## File Structure

| Action | File | Responsibility |
|--------|------|----------------|
| Modify | `packages/rfw_gen/lib/src/ast_visitor.dart` | Add widget-value param detection in step 5 of `_processNamedArgument` |
| Modify | `packages/rfw_gen/lib/src/widget_registry.dart` | Add `registerFromConfig()` and `_parseChildType()` |
| Modify | `packages/rfw_gen/lib/rfw_gen.dart` | Export nothing new (already exports all needed) |
| Modify | `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart` | Load `rfw_gen.yaml` and register custom widgets |
| Modify | `packages/rfw_gen_builder/pubspec.yaml` | Add `yaml` dependency |
| Modify | `packages/rfw_gen/test/ast_visitor_test.dart` | Widget-value param tests |
| Modify | `packages/rfw_gen/test/widget_registry_test.dart` | `registerFromConfig()` tests |
| Modify | `packages/rfw_gen/test/integration_test.dart` | End-to-end custom widget tests |
| Modify | `packages/rfw_gen_builder/test/builder_test.dart` | Builder with rfw_gen.yaml tests |

---

### Task 1: Widget-Value Parameter Auto-Detection

Unknown params that are registered widgets should be recursively converted instead of silently dropped.

**Files:**
- Modify: `packages/rfw_gen/lib/src/ast_visitor.dart` — step 5 in `_processNamedArgument`
- Modify: `packages/rfw_gen/test/ast_visitor_test.dart`

- [ ] **Step 1: Write failing test — widget-value param with core widgets**

Add to `packages/rfw_gen/test/ast_visitor_test.dart`:

```dart
test('widget-value param: unknown param with registered widget is converted', () {
  // Register a custom widget with optionalChild that has a non-standard widget param
  registry.register('ConditionalWidget', const WidgetMapping(
    rfwName: 'ConditionalWidget',
    import: 'custom.widgets',
    childType: ChildType.optionalChild,
    childParam: 'child',
    params: {},
  ));
  visitor = WidgetAstVisitor(
    registry: registry,
    expressionConverter: expressionConverter,
  );

  final fn = parseFunction('''
Widget build() {
  return ConditionalWidget(
    child: Text('visible'),
    nullChild: Text('fallback'),
  );
}
''');

  final node = visitor.extractWidgetTree(fn);
  expect(node.name, 'ConditionalWidget');
  // child is handled by childParam
  expect(node.properties['child'], isA<IrWidgetNode>());
  // nullChild should also be converted as a widget (not dropped)
  expect(node.properties['nullChild'], isA<IrWidgetNode>());
  final nullChild = node.properties['nullChild'] as IrWidgetNode;
  expect(nullChild.name, 'Text');
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ast_visitor_test.dart --name "widget-value param"`
Expected: FAIL — `nullChild` is not in properties (silently dropped)

- [ ] **Step 3: Implement widget-value detection**

In `packages/rfw_gen/lib/src/ast_visitor.dart`, replace the step 5 block in `_processNamedArgument` (the final fallback after known params check):

```dart
    // 5. Unknown parameter — check if it's a widget first, then try expression.
    if (expression is MethodInvocation &&
        expression.target == null &&
        registry.isSupported(expression.methodName.name)) {
      properties[paramName] = _convertWidget(expression);
      return;
    }
    try {
      final value = expressionConverter.convert(expression);
      properties[paramName] = value;
    } on UnsupportedExpressionError {
      // Silently skip.
    }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ast_visitor_test.dart --name "widget-value param"`
Expected: PASS

- [ ] **Step 5: Write test — nested widget-value params**

```dart
test('widget-value param: deeply nested widget-value params are converted', () {
  registry.register('Outer', const WidgetMapping(
    rfwName: 'Outer',
    import: 'custom.widgets',
    childType: ChildType.none,
    params: {},
  ));
  registry.register('Inner', const WidgetMapping(
    rfwName: 'Inner',
    import: 'custom.widgets',
    childType: ChildType.none,
    params: {},
  ));
  visitor = WidgetAstVisitor(
    registry: registry,
    expressionConverter: expressionConverter,
  );

  final fn = parseFunction('''
Widget build() {
  return Outer(
    slot: Inner(label: 'hello'),
  );
}
''');

  final node = visitor.extractWidgetTree(fn);
  final slot = node.properties['slot'] as IrWidgetNode;
  expect(slot.name, 'Inner');
  expect((slot.properties['label'] as IrStringValue).value, 'hello');
});
```

- [ ] **Step 6: Run test — should pass with existing implementation**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ast_visitor_test.dart --name "deeply nested"`
Expected: PASS

- [ ] **Step 7: Write test — non-widget unknown params still pass through**

```dart
test('widget-value param: non-widget unknown params still pass through', () {
  registry.register('MyWidget', const WidgetMapping(
    rfwName: 'MyWidget',
    import: 'custom.widgets',
    childType: ChildType.none,
    params: {},
  ));
  visitor = WidgetAstVisitor(
    registry: registry,
    expressionConverter: expressionConverter,
  );

  final fn = parseFunction('''
Widget build() {
  return MyWidget(
    title: 'hello',
    count: 42,
    active: true,
  );
}
''');

  final node = visitor.extractWidgetTree(fn);
  expect(node.name, 'MyWidget');
  expect((node.properties['title'] as IrStringValue).value, 'hello');
  expect((node.properties['count'] as IrIntValue).value, 42);
  expect((node.properties['active'] as IrBoolValue).value, true);
});
```

- [ ] **Step 8: Run test — should pass**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ast_visitor_test.dart --name "non-widget unknown"`
Expected: PASS

- [ ] **Step 9: Run all existing tests to verify no regressions**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/`
Expected: All tests PASS (296+ tests)

- [ ] **Step 10: Commit**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/lib/src/ast_visitor.dart packages/rfw_gen/test/ast_visitor_test.dart
git commit -m "feat: auto-detect widget-value params in unknown param handler"
```

---

### Task 2: WidgetRegistry.registerFromConfig()

Add a method to parse YAML config maps into widget registrations.

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart`
- Modify: `packages/rfw_gen/pubspec.yaml` — add `yaml` dev_dependency (for YamlMap round-trip test)
- Modify: `packages/rfw_gen/test/widget_registry_test.dart` — add `import 'package:yaml/yaml.dart';`

- [ ] **Step 1: Write failing test — basic registerFromConfig**

Add to `packages/rfw_gen/test/widget_registry_test.dart`:

```dart
group('registerFromConfig', () {
  test('registers widget with import only', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'MystiqueText': {'import': 'mystique.widgets'},
    });

    expect(registry.isSupported('MystiqueText'), isTrue);
    final mapping = registry.supportedWidgets['MystiqueText']!;
    expect(mapping.import, 'mystique.widgets');
    expect(mapping.childType, ChildType.none);
    expect(mapping.childParam, isNull);
    expect(mapping.handlerParams, isEmpty);
    expect(mapping.params, isEmpty);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart --name "registers widget with import only"`
Expected: FAIL — `registerFromConfig` not defined

- [ ] **Step 3: Implement registerFromConfig and _parseChildType**

Add to `packages/rfw_gen/lib/src/widget_registry.dart` inside `WidgetRegistry` class:

```dart
  /// Registers custom widgets from a YAML config map.
  ///
  /// Each entry maps a widget name to its configuration:
  /// ```yaml
  /// MystiqueText:
  ///   import: mystique.widgets
  ///   child_type: optionalChild   # optional, default: none
  ///   child_param: child          # optional, auto-derived from child_type
  ///   handlers: [onTap]           # optional, default: []
  /// ```
  void registerFromConfig(Map<String, dynamic> widgetsConfig) {
    for (final entry in widgetsConfig.entries) {
      final name = entry.key;
      final config = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};

      final importLib = config['import'] as String?;
      if (importLib == null) {
        throw ArgumentError(
          'Widget "$name" in rfw_gen.yaml is missing required "import" field',
        );
      }

      final childType = _parseChildType(config['child_type'] as String?);
      final handlers = (config['handlers'] as List?)
              ?.cast<String>()
              .toSet() ??
          const <String>{};

      final childParam = config['child_param'] as String? ??
          (childType == ChildType.child ||
                  childType == ChildType.optionalChild
              ? 'child'
              : childType == ChildType.childList
                  ? 'children'
                  : null);

      register(
        name,
        WidgetMapping(
          rfwName: name,
          import: importLib,
          childType: childType,
          childParam: childParam,
          params: const {},
          handlerParams: handlers,
        ),
      );
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart --name "registers widget with import only"`
Expected: PASS

- [ ] **Step 5: Write remaining tests**

```dart
  test('registers widget with child_type and auto-derived child_param', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'Wrapper': {'import': 'custom.widgets', 'child_type': 'optionalChild'},
    });

    final mapping = registry.supportedWidgets['Wrapper']!;
    expect(mapping.childType, ChildType.optionalChild);
    expect(mapping.childParam, 'child');
  });

  test('registers widget with childList and auto-derived children param', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'CustomColumn': {'import': 'custom.widgets', 'child_type': 'childList'},
    });

    final mapping = registry.supportedWidgets['CustomColumn']!;
    expect(mapping.childType, ChildType.childList);
    expect(mapping.childParam, 'children');
  });

  test('registers widget with explicit child_param override', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'Special': {
        'import': 'custom.widgets',
        'child_type': 'optionalChild',
        'child_param': 'content',
      },
    });

    final mapping = registry.supportedWidgets['Special']!;
    expect(mapping.childParam, 'content');
  });

  test('registers widget with handlers', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'Tapper': {
        'import': 'custom.widgets',
        'child_type': 'optionalChild',
        'handlers': ['onTap', 'onLongPress'],
      },
    });

    final mapping = registry.supportedWidgets['Tapper']!;
    expect(mapping.handlerParams, {'onTap', 'onLongPress'});
  });

  test('throws when import is missing', () {
    final registry = WidgetRegistry();
    expect(
      () => registry.registerFromConfig({'Bad': {'child_type': 'none'}}),
      throwsA(isA<ArgumentError>().having(
        (e) => e.message,
        'message',
        contains('missing required "import"'),
      )),
    );
  });

  test('throws when namedSlots is used', () {
    final registry = WidgetRegistry();
    expect(
      () => registry.registerFromConfig({
        'Bad': {'import': 'x', 'child_type': 'namedSlots'},
      }),
      throwsA(isA<ArgumentError>().having(
        (e) => e.message,
        'message',
        contains('namedSlots is not supported'),
      )),
    );
  });

  test('handles null config value (YAML key with no value)', () {
    final registry = WidgetRegistry();
    // In YAML, `MystiqueText:` without value gives null
    // registerFromConfig should handle this gracefully
    expect(
      () => registry.registerFromConfig({'MystiqueText': null}),
      throwsA(isA<ArgumentError>().having(
        (e) => e.message,
        'message',
        contains('missing required "import"'),
      )),
    );
  });

  test('registers multiple widgets at once', () {
    final registry = WidgetRegistry();
    registry.registerFromConfig({
      'A': {'import': 'lib.a'},
      'B': {'import': 'lib.b', 'child_type': 'child'},
      'C': {'import': 'lib.c', 'handlers': ['onTap']},
    });

    expect(registry.isSupported('A'), isTrue);
    expect(registry.isSupported('B'), isTrue);
    expect(registry.isSupported('C'), isTrue);
    expect(registry.supportedWidgets['B']!.childType, ChildType.child);
    expect(registry.supportedWidgets['B']!.childParam, 'child');
    expect(registry.supportedWidgets['C']!.handlerParams, {'onTap'});
  });

  test('works with YamlMap from loadYaml (round-trip)', () {
    // Simulates what happens when YAML is parsed by package:yaml
    // YamlMap is Map<dynamic, dynamic>, not Map<String, dynamic>
    final registry = WidgetRegistry();
    final yamlStr = '''
MystiqueText:
  import: mystique.widgets
Tapper:
  import: custom.widgets
  child_type: optionalChild
  handlers:
    - onTap
''';
    final parsed = loadYaml(yamlStr) as Map;
    registry.registerFromConfig(Map<String, dynamic>.from(parsed));

    expect(registry.isSupported('MystiqueText'), isTrue);
    expect(registry.supportedWidgets['MystiqueText']!.import, 'mystique.widgets');
    expect(registry.isSupported('Tapper'), isTrue);
    expect(registry.supportedWidgets['Tapper']!.handlerParams, {'onTap'});
    expect(registry.supportedWidgets['Tapper']!.childParam, 'child');
  });
```

- [ ] **Step 6: Run all registerFromConfig tests**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart --name "registerFromConfig"`
Expected: All PASS

- [ ] **Step 7: Run full test suite**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/`
Expected: All PASS

- [ ] **Step 8: Commit**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "feat: add WidgetRegistry.registerFromConfig() for YAML-based custom widget registration"
```

---

### Task 3: End-to-End Integration Tests (Custom Widget → rfwtxt)

Verify the full pipeline: custom widget registration → Dart source → rfwtxt with correct imports.

**Files:**
- Modify: `packages/rfw_gen/test/integration_test.dart`

- [ ] **Step 1: Write integration test — custom widget pass-through**

Add a new group to `packages/rfw_gen/test/integration_test.dart`:

```dart
group('custom widget support', () {
  late RfwConverter converter;

  setUp(() {
    final registry = WidgetRegistry.core();
    registry.registerFromConfig({
      'MystiqueText': {'import': 'mystique.widgets'},
      'NullConditionalWidget': {
        'import': 'custom.widgets',
        'child_type': 'optionalChild',
      },
      'SZSBounceTapper': {
        'import': 'custom.widgets',
        'child_type': 'optionalChild',
        'handlers': ['onTap'],
      },
    });
    converter = RfwConverter(registry: registry);
  });

  test('simple custom widget with pass-through params', () {
    const input = '''
Widget build() {
  return MystiqueText(text: 'hello', fontType: 'heading24Bold', color: 0xFF141618);
}
''';
    final rfwtxt = converter.convertFromSource(input);
    expect(rfwtxt, contains('import mystique.widgets;'));
    expect(rfwtxt, contains('MystiqueText('));
    expect(rfwtxt, contains('text: "hello"'));
    expect(rfwtxt, contains('fontType: "heading24Bold"'));
    expect(rfwtxt, contains('color: 0xFF141618'));
    // Must parse without error
    parseLibraryFile(rfwtxt);
  });

  test('custom widget nested inside core widget generates both imports', () {
    const input = '''
Widget build() {
  return Container(
    child: MystiqueText(text: 'hello'),
  );
}
''';
    final rfwtxt = converter.convertFromSource(input);
    expect(rfwtxt, contains('import core.widgets;'));
    expect(rfwtxt, contains('import mystique.widgets;'));
    parseLibraryFile(rfwtxt);
  });

  test('widget-value param (nullChild) is preserved in output', () {
    const input = '''
Widget build() {
  return NullConditionalWidget(
    child: MystiqueText(text: 'visible'),
    nullChild: MystiqueText(text: 'fallback'),
  );
}
''';
    final rfwtxt = converter.convertFromSource(input);
    expect(rfwtxt, contains('nullChild: MystiqueText('));
    expect(rfwtxt, contains('import custom.widgets;'));
    expect(rfwtxt, contains('import mystique.widgets;'));
    parseLibraryFile(rfwtxt);
  });

  test('custom widget with handler param', () {
    const input = '''
Widget build() {
  return SZSBounceTapper(
    onTap: RfwHandler.event('navigate', {'url': 'szsapp://home'}),
    child: MystiqueText(text: 'tap me'),
  );
}
''';
    final rfwtxt = converter.convertFromSource(input);
    expect(rfwtxt, contains('onTap: event "navigate"'));
    expect(rfwtxt, contains('url: "szsapp://home"'));
    parseLibraryFile(rfwtxt);
  });

  test('only used imports are generated', () {
    const input = '''
Widget build() {
  return MystiqueText(text: 'hello');
}
''';
    final rfwtxt = converter.convertFromSource(input);
    expect(rfwtxt, contains('import mystique.widgets;'));
    // core.widgets should NOT be present since no core widget is used
    expect(rfwtxt, isNot(contains('import core.widgets;')));
    parseLibraryFile(rfwtxt);
  });
});
```

- [ ] **Step 2: Run integration tests**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/integration_test.dart --name "custom widget support"`
Expected: All PASS

- [ ] **Step 3: Run full rfw_gen test suite**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/`
Expected: All PASS

- [ ] **Step 4: Commit**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/test/integration_test.dart
git commit -m "test: add end-to-end integration tests for custom widget support"
```

---

### Task 4: Builder — Load rfw_gen.yaml

Wire the builder to read `rfw_gen.yaml` and register custom widgets before conversion.

**Files:**
- Modify: `packages/rfw_gen_builder/pubspec.yaml` — add `yaml` dependency
- Modify: `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`
- Modify: `packages/rfw_gen_builder/test/builder_test.dart`

- [ ] **Step 1: Add yaml dependency**

In `packages/rfw_gen_builder/pubspec.yaml`, add `yaml` under `dependencies`:

```yaml
dependencies:
  analyzer: ^9.0.0
  build: ^4.0.0
  yaml: ^3.1.0
  rfw_gen:
    path: ../rfw_gen
```

- [ ] **Step 2: Run melos bootstrap**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && melos bootstrap`
Expected: Success

- [ ] **Step 3: Write failing builder test — with rfw_gen.yaml**

Add to `packages/rfw_gen_builder/test/builder_test.dart`:

```dart
test('loads custom widgets from rfw_gen.yaml', () async {
  final result = await testBuilder(
    rfwWidgetBuilder(BuilderOptions.empty),
    {
      'a|rfw_gen.yaml': '''
widgets:
  MystiqueText:
    import: mystique.widgets
''',
      'a|lib/widgets.dart': '''
@RfwWidget('card')
Widget buildCard() {
  return MystiqueText(text: 'hello', fontType: 'heading24Bold');
}
''',
    },
    outputs: {
      'a|lib/widgets.rfwtxt': decodedMatches(
        allOf(
          contains('import mystique.widgets;'),
          contains('widget card'),
          contains('MystiqueText('),
          contains('text: "hello"'),
          contains('fontType: "heading24Bold"'),
        ),
      ),
      'a|lib/widgets.rfw': isNotEmpty,
    },
  );
  expect(result.succeeded, isTrue);
});
```

- [ ] **Step 4: Run test to verify it fails**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen_builder/test/builder_test.dart --name "loads custom widgets"`
Expected: FAIL — MystiqueText is not registered, builder throws UnsupportedWidgetError

- [ ] **Step 5: Implement rfw_gen.yaml loading in builder**

Update `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`:

Add import at top:
```dart
import 'package:yaml/yaml.dart';
```

Replace the `build` method body:

```dart
  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);

    // Parse the Dart source and find @RfwWidget-annotated functions.
    final parseResult = parseString(content: source);
    final annotatedFunctions = parseResult.unit.declarations
        .whereType<FunctionDeclaration>()
        .where((f) => f.metadata.any((a) => a.name.name == 'RfwWidget'))
        .toList();

    if (annotatedFunctions.isEmpty) return;

    // Build registry: core + custom widgets from rfw_gen.yaml.
    final registry = WidgetRegistry.core();
    final configId = AssetId(buildStep.inputId.package, 'rfw_gen.yaml');
    if (await buildStep.canRead(configId)) {
      final yamlStr = await buildStep.readAsString(configId);
      final yaml = loadYaml(yamlStr);
      if (yaml is Map) {
        final widgets = yaml['widgets'];
        if (widgets is Map) {
          registry
              .registerFromConfig(Map<String, dynamic>.from(widgets));
        }
      }
    }

    final converter = RfwConverter(registry: registry);
    final parts = <String>[];

    for (final function in annotatedFunctions) {
      try {
        parts.add(converter.convertFromAst(function));
      } catch (e) {
        log.severe('Failed to convert ${function.name.lexeme}: $e');
      }
    }

    if (parts.isEmpty) return;

    final combined = _mergeRfwtxtParts(parts);

    // Write .rfwtxt text output.
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfwtxt'),
      combined,
    );

    // Write .rfw binary output.
    try {
      final blob = converter.toBlob(combined);
      await buildStep.writeAsBytes(
        buildStep.inputId.changeExtension('.rfw'),
        blob,
      );
    } catch (e) {
      log.warning('Failed to encode binary: $e');
    }
  }
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen_builder/test/builder_test.dart --name "loads custom widgets"`
Expected: PASS

- [ ] **Step 7: Write test — builder works without rfw_gen.yaml**

```dart
test('works without rfw_gen.yaml (core widgets only)', () async {
  final result = await testBuilder(
    rfwWidgetBuilder(BuilderOptions.empty),
    {
      'a|lib/widgets.dart': '''
@RfwWidget('greeting')
Widget buildGreeting() {
  return Text('Hello');
}
''',
    },
    outputs: {
      'a|lib/widgets.rfwtxt': decodedMatches(
        allOf(
          contains('widget greeting'),
          contains('Text('),
        ),
      ),
      'a|lib/widgets.rfw': isNotEmpty,
    },
  );
  expect(result.succeeded, isTrue);
});
```

- [ ] **Step 8: Write test — builder with widget-value params**

```dart
test('custom widget with widget-value param in rfw_gen.yaml', () async {
  final result = await testBuilder(
    rfwWidgetBuilder(BuilderOptions.empty),
    {
      'a|rfw_gen.yaml': '''
widgets:
  NullConditional:
    import: custom.widgets
    child_type: optionalChild
  MyText:
    import: mystique.widgets
''',
      'a|lib/widgets.dart': '''
@RfwWidget('card')
Widget buildCard() {
  return NullConditional(
    child: MyText(text: 'visible'),
    nullChild: MyText(text: 'fallback'),
  );
}
''',
    },
    outputs: {
      'a|lib/widgets.rfwtxt': decodedMatches(
        allOf(
          contains('import custom.widgets;'),
          contains('import mystique.widgets;'),
          contains('nullChild: MyText('),
        ),
      ),
      'a|lib/widgets.rfw': isNotEmpty,
    },
  );
  expect(result.succeeded, isTrue);
});
```

- [ ] **Step 9: Run all builder tests**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen_builder/test/`
Expected: All PASS

- [ ] **Step 10: Run entire test suite (both packages)**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && melos exec -- dart test`
Expected: All PASS

- [ ] **Step 11: Commit**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen_builder/pubspec.yaml packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart packages/rfw_gen_builder/test/builder_test.dart
git commit -m "feat: load custom widgets from rfw_gen.yaml in builder"
```

---

### Task 5: Final Validation & Cleanup

- [ ] **Step 1: Run dart analyze on both packages**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && melos exec -- dart analyze`
Expected: No issues

- [ ] **Step 2: Run full test suite**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && melos exec -- dart test`
Expected: All PASS

- [ ] **Step 3: Verify test count increased**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/ 2>&1 | tail -1 && dart test packages/rfw_gen_builder/test/ 2>&1 | tail -1`
Expected: More than 296 tests total (was 296 before)

- [ ] **Step 4: Commit plan as complete**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add docs/superpowers/plans/2026-03-23-custom-widget-support.md
git commit -m "docs: add custom widget support implementation plan"
```
