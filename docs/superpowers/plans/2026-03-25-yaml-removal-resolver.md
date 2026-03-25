# rfw_gen.yaml Removal & Resolver-Based Widget Analysis Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove `rfw_gen.yaml` by using `BuildStep.resolver` for cross-package widget analysis, and auto-generate `LocalWidgetBuilder` maps.

**Architecture:** Two builders: (1) existing `rfw_widget_builder` modified with two-phase Resolver integration for rfwtxt/rfw generation, (2) new `rfw_local_widget_builder` that generates `.rfw_library.dart` + `.rfw_meta.json`. Both share `WidgetResolver` for class analysis. MCP reads generated `.rfw_meta.json` instead of yaml.

**Tech Stack:** Dart analyzer (Resolver + AST), build_runner, build_test, rfw

**Spec:** `docs/superpowers/specs/2026-03-25-yaml-removal-resolver-design.md`

**Spike results:** Resolver cross-package analysis verified working. See `packages/rfw_gen_builder/test/resolver_spike_test.dart`.

**Analyzer API notes (v8.0.0):**
- `element2` not `element`
- `firstFragment.importedLibraries` for imports
- `formalParameters` not `parameters`
- `FormalParameterElement.name` returns `String?`
- `SuperFormalParameterElement` for `super.key`
- `FunctionType` with `alias.element.name` for `VoidCallback`

---

## File Structure

### Create
- `packages/rfw_gen_builder/lib/src/widget_resolver.dart` — Resolver-based widget class analysis
- `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart` — generates `.rfw_library.dart` code
- `packages/rfw_gen_builder/test/widget_resolver_test.dart` — WidgetResolver unit tests
- `packages/rfw_gen_builder/test/local_widget_builder_generator_test.dart` — generator unit tests
- `example/lib/custom/custom_widget_classes.dart` — 13 real Flutter widget classes

### Modify
- `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart` — two-phase Resolver integration for rfwtxt
- `packages/rfw_gen_builder/lib/src/widget_registry.dart` — remove `registerFromConfig()`
- `packages/rfw_gen_builder/lib/builder.dart` — add `rfwLocalWidgetBuilder` factory
- `packages/rfw_gen_builder/build.yaml` — add second builder for `.rfw_library.dart` + `.rfw_meta.json`
- `packages/rfw_gen_mcp/lib/src/server.dart` — read `.rfw_meta.json` instead of yaml
- `example/lib/custom/custom_widgets.dart` — remove `ignore_for_file`, import real classes
- `example/lib/custom/custom_widget_builders.dart` — re-export generated file

### Delete
- `example/rfw_gen.yaml`

---

### Task 1: Create WidgetResolver

Core component that uses `BuildStep.resolver` to analyze widget class constructors and produce `WidgetMapping` objects.

**Files:**
- Create: `packages/rfw_gen_builder/lib/src/widget_resolver.dart`
- Create: `packages/rfw_gen_builder/test/widget_resolver_test.dart`

- [ ] **Step 1: Write WidgetResolver unit tests**

Create `packages/rfw_gen_builder/test/widget_resolver_test.dart`. Since `BuildStep.resolver` requires a full build context, test the core logic (constructor analysis → WidgetMapping) using the analyzer directly (same approach as the spike test).

Tests to cover:
- Widget with primitives only → `ChildType.none`
- Widget with `Widget child` (required) → `ChildType.child`
- Widget with `Widget? child` only → `ChildType.optionalChild`
- Widget with `List<Widget> children` → `ChildType.childList`
- Widget with multiple `Widget?` params → `ChildType.namedSlots`
- Widget with `VoidCallback?` → extracted as handler
- Mixed: `Widget child` + `Widget? leading` → `ChildType.child` + namedSlots
- `Key?` / `super.key` → skipped
- Empty constructor → `ChildType.none`, no params
- Non-widget class → returns null
- Abstract class → returns null
- Package name extraction from library URI

Use `AnalysisContextCollection` with temp files (same pattern as spike test).

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen_builder && dart test test/widget_resolver_test.dart`
Expected: FAIL — `widget_resolver.dart` doesn't exist

- [ ] **Step 3: Implement WidgetResolver**

Create `packages/rfw_gen_builder/lib/src/widget_resolver.dart`:

Key methods:
- `resolveFromLibrary(LibraryElement library, String widgetName)` — finds class in resolved library, returns `ResolveResult?` containing both `WidgetMapping` and `ResolvedWidget`
- `batchResolve(LibraryElement library, Set<String> widgetNames)` — batch resolve, returns `Map<String, ResolveResult>`
- `_buildMapping(ClassElement, String packageName)` — analyzes constructor
- `_inferChildType(List<ParameterElement>)` — priority-based inference (see spec)
- `_extractHandlers(List<ParameterElement>)` — VoidCallback? detection
- `_extractNamedSlots(List<ParameterElement>)` — Widget? params excluding main child
- `_isWidgetType(DartType)` — checks StatelessWidget/StatefulWidget inheritance
- `_isVoidCallbackType(DartType)` — checks VoidCallback typedef or void Function()
- `_extractPackageName(LibraryElement)` — from `library.uri`

ChildType inference priority:
1. `List<Widget>` → `childList`
2. 1 required `Widget` named `child` → `child` (+ other Widget? → namedSlots)
3. 1 `Widget?` named `child` (no others) → `optionalChild`
4. Multiple `Widget?` → `namedSlots`
5. None → `none`

**ChildType inference behavioral changes (intentional corrections):**
Some widgets will get different ChildType values under Resolver inference vs the old yaml config:
- `NullConditionalWidget` (child: Widget?, nullChild: Widget?): yaml had `optionalChild` → now `namedSlots` (correct: both params are widget slots)
- `CompareWidget` (child: Widget?, trueChild: Widget?, falseChild: Widget?): yaml had `optionalChild` → now `namedSlots` (correct: all three are widget slots)

These changes produce MORE correct rfwtxt output because all Widget? params are properly treated as widget children, not as raw expressions. Verify that rfwtxt output and runtime behavior remain correct after the change.

- [ ] **Step 4: Run tests**

Run: `cd packages/rfw_gen_builder && dart test test/widget_resolver_test.dart`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/widget_resolver.dart
git add packages/rfw_gen_builder/test/widget_resolver_test.dart
git commit -m "feat(rfw_gen_builder): add WidgetResolver for Resolver-based widget analysis"
```

---

### Task 2: Create LocalWidgetBuilderGenerator

Generates Dart code for `Map<String, LocalWidgetBuilder>` from resolved widget info.

**Files:**
- Create: `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`
- Create: `packages/rfw_gen_builder/test/local_widget_builder_generator_test.dart`

- [ ] **Step 1: Write generator tests**

Create `packages/rfw_gen_builder/test/local_widget_builder_generator_test.dart`.

Test with `ResolvedWidget` objects (no analyzer needed — pure code generation logic):
- Simple widget with String/int/double/bool → `source.v<T>()` calls
- Widget with `Widget child` → `source.child()`
- Widget with `Widget? optionalChild` → `source.optionalChild()`
- Widget with `List<Widget> children` → loop with `source.length` + `source.child`
- Widget with `VoidCallback?` → `source.voidHandler()`
- Widget with named slots → `source.optionalChild()` for each
- Default values preserved in fallback (`?? defaultValue`)
- `Key?` params skipped
- Multiple widgets → all present in output map
- Generated imports include source file paths
- Output contains `// GENERATED CODE` header

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/rfw_gen_builder && dart test test/local_widget_builder_generator_test.dart`
Expected: FAIL

- [ ] **Step 3: Implement LocalWidgetBuilderGenerator**

Create `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`:

Data classes:
```dart
class ResolvedWidget {
  final String className;
  final String dartImport;  // e.g., 'package:mystique/widgets/coupon.dart'
  final List<ResolvedParam> params;
}

class ResolvedParam {
  final String name;
  final ResolvedParamType type;
  final bool isRequired;
  final bool isNullable;
  final String? defaultValue;
}

enum ResolvedParamType {
  string, int, double, bool,
  widget, optionalWidget, widgetList,
  voidCallback,
  other,
}
```

Generator logic:
- Emit `// GENERATED CODE - DO NOT MODIFY BY HAND`
- Emit imports: `package:flutter/material.dart`, `package:rfw/rfw.dart`, + each widget's `dartImport`
- Emit `Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders => { ... }`
- For each widget: `'WidgetName': (BuildContext context, DataSource source) { return WidgetName(...); },`
- Type mapping:
  - `string` → `source.v<String>(['name']) ?? defaultOrEmpty`
  - `int` → `source.v<int>(['name']) ?? defaultOr0`
  - `double` → `source.v<double>(['name']) ?? defaultOr0.0`
  - `bool` → `source.v<bool>(['name']) ?? defaultOrFalse`
  - `widget` → `source.child(['name'])`
  - `optionalWidget` → `source.optionalChild(['name'])`
  - `widgetList` → loop pattern
  - `voidCallback` → `source.voidHandler(['name'])`

- [ ] **Step 4: Run tests**

Run: `cd packages/rfw_gen_builder && dart test test/local_widget_builder_generator_test.dart`
Expected: All PASS

- [ ] **Step 5: Commit**

```bash
git add packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart
git add packages/rfw_gen_builder/test/local_widget_builder_generator_test.dart
git commit -m "feat(rfw_gen_builder): add LocalWidgetBuilderGenerator for auto-generated builders"
```

---

### Task 3: Create real Flutter widget classes for example

Move render logic from manual `custom_widget_builders.dart` into real `StatelessWidget` classes.

**Files:**
- Create: `example/lib/custom/custom_widget_classes.dart`

- [ ] **Step 1: Create widget classes file**

Create `example/lib/custom/custom_widget_classes.dart` with all 13 widget classes. Each class:
- Extends `StatelessWidget`
- Uses `int` for color params (RFW 0xAARRGGBB encoding)
- Uses `Widget`/`Widget?`/`List<Widget>` for children
- Uses `VoidCallback?` for handlers
- Has `super.key` in constructor
- Contains the full render logic from the manual builder

The 13 widgets: `CustomText`, `CustomBounceTapper`, `NullConditionalWidget`, `CustomButton`, `CustomBadge`, `CustomProgressBar`, `CustomColumn`, `SkeletonContainer`, `CompareWidget`, `PvContainer`, `CustomCard`, `CustomTile`, `CustomAppBar`.

Refer to `example/lib/custom/custom_widget_builders.dart` for the existing render logic to move into each class.

- [ ] **Step 2: Verify compilation**

Run: `cd example && dart analyze lib/custom/custom_widget_classes.dart`
Expected: No errors

- [ ] **Step 3: Commit**

```bash
git add example/lib/custom/custom_widget_classes.dart
git commit -m "feat(example): create 13 real Flutter widget classes"
```

---

### Task 4: Integrate Resolver into RfwWidgetBuilder + new LocalWidgetBuilder builder

Two changes: (1) modify existing builder for Resolver-based registry population, (2) create a separate builder for `.rfw_library.dart` + `.rfw_meta.json` generation.

**Why separate builders:** build_runner requires all declared `build_extensions` outputs to be written. The `.rfw_library.dart`/`.rfw_meta.json` are only needed when custom widgets exist. A separate builder with its own extensions avoids the "must always write" constraint.

**Files:**
- Modify: `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`
- Create: `packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart`
- Modify: `packages/rfw_gen_builder/lib/src/widget_registry.dart`
- Modify: `packages/rfw_gen_builder/lib/builder.dart`
- Modify: `packages/rfw_gen_builder/build.yaml`

- [ ] **Step 1: Update build.yaml — add second builder**

In `packages/rfw_gen_builder/build.yaml`, keep existing builder unchanged and add:

```yaml
builders:
  rfw_widget_builder:
    import: "package:rfw_gen_builder/builder.dart"
    builder_factories: ["rfwWidgetBuilder"]
    build_extensions: {".dart": [".rfwtxt", ".rfw"]}
    auto_apply: dependents
    build_to: source
  rfw_local_widget_builder:
    import: "package:rfw_gen_builder/builder.dart"
    builder_factories: ["rfwLocalWidgetBuilder"]
    build_extensions: {".dart": [".rfw_library.dart", ".rfw_meta.json"]}
    auto_apply: dependents
    build_to: source
```

- [ ] **Step 2: Create LocalWidgetBuilderBuilder**

Create `packages/rfw_gen_builder/lib/src/local_widget_builder_builder.dart`:

This builder:
1. Reads source file, checks for `@RfwWidget` annotations
2. Collects unknown widget names using `RecursiveAstVisitor<void>` (walks all `MethodInvocation` nodes recursively through nested widget trees)
3. Uses `BuildStep.resolver` to resolve classes
4. Uses `WidgetResolver.batchResolve()` to analyze constructors
5. Generates `.rfw_library.dart` and `.rfw_meta.json`
6. If no custom widgets found, writes minimal empty files (build_runner requirement)

```dart
class LocalWidgetBuilderBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => const {
    '.dart': ['.rfw_library.dart', '.rfw_meta.json'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);
    if (!source.contains('RfwWidget')) return _writeEmptyOutputs(buildStep);

    final parseResult = parseString(content: source);
    final registry = WidgetRegistry.core();
    final unknownNames = _collectUnknownWidgetNames(parseResult.unit, registry);

    if (unknownNames.isEmpty) return _writeEmptyOutputs(buildStep);

    final library = await buildStep.resolver.libraryFor(buildStep.inputId);
    final resolver = WidgetResolver();
    final results = resolver.batchResolve(library, unknownNames);

    if (results.isEmpty) return _writeEmptyOutputs(buildStep);

    // Generate .rfw_library.dart
    final generator = LocalWidgetBuilderGenerator();
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_library.dart'),
      generator.generate(results),
    );

    // Generate .rfw_meta.json (for MCP)
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_meta.json'),
      generator.generateMeta(results),
    );
  }

  Future<void> _writeEmptyOutputs(BuildStep buildStep) async {
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_library.dart'),
      '// GENERATED - no custom widgets found\n',
    );
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_meta.json'),
      '{"widgets":{}}\n',
    );
  }
}
```

`_collectUnknownWidgetNames` uses `RecursiveAstVisitor<void>`:
```dart
class _WidgetNameCollector extends RecursiveAstVisitor<void> {
  final WidgetRegistry registry;
  final Set<String> unknownNames = {};

  _WidgetNameCollector(this.registry);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      final name = node.methodName.name;
      if (!registry.isSupported(name) && name[0] == name[0].toUpperCase()) {
        unknownNames.add(name);
      }
    }
    super.visitMethodInvocation(node);  // recurse into children
  }
}
```

- [ ] **Step 3: Add builder factory**

Add to `packages/rfw_gen_builder/lib/builder.dart`:

```dart
import 'src/local_widget_builder_builder.dart';

Builder rfwLocalWidgetBuilder(BuilderOptions options) =>
    LocalWidgetBuilderBuilder(options);
```

- [ ] **Step 4: Modify existing RfwWidgetBuilder for Resolver**

In `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`:

Replace yaml loading (lines 46-66) with Resolver-based widget discovery:

```dart
// Phase 1: Collect unknown widget names
final unknownNames = _collectUnknownWidgetNames(parseResult.unit, registry);

// Phase 1b: Batch-resolve unknown widgets via Resolver
if (unknownNames.isNotEmpty) {
  final library = await buildStep.resolver.libraryFor(buildStep.inputId);
  final resolver = WidgetResolver();
  final results = resolver.batchResolve(library, unknownNames);
  for (final entry in results.entries) {
    registry.register(entry.key, entry.value.widgetMapping);
  }
}

// Phase 2: Existing synchronous conversion (unchanged)
```

Remove imports: `dart:io`, `package:yaml/yaml.dart`
Add import: `widget_resolver.dart`

- [ ] **Step 5: Remove `registerFromConfig` from WidgetRegistry**

In `packages/rfw_gen_builder/lib/src/widget_registry.dart`:
- Remove the `registerFromConfig()` method (lines 110-187)
- Remove the `_parseChildType()` helper
- Keep `register()` method and all core widget registrations

- [ ] **Step 6: Run existing tests**

Run: `cd packages/rfw_gen_builder && dart test`
Expected: Most tests pass. Tests that depend on yaml config (in `builder_test.dart`) may fail — fix in next step.

- [ ] **Step 7: Update builder tests**

In `packages/rfw_gen_builder/test/builder_test.dart`:
- Remove tests that pass `rfw_gen.yaml` config
- Update tests to use synthetic source files that import real widget classes
- Tests are self-contained (don't rely on example app)

Note: `build_test`'s `testBuilder` may not support Resolver. If so, test builder components individually using `AnalysisContextCollection`.

- [ ] **Step 8: Run all builder tests**

Run: `cd packages/rfw_gen_builder && dart test`
Expected: All PASS

- [ ] **Step 9: Commit**

```bash
git add packages/rfw_gen_builder/lib/
git add packages/rfw_gen_builder/build.yaml
git add packages/rfw_gen_builder/test/
git commit -m "feat(rfw_gen_builder): integrate Resolver, add LocalWidgetBuilder builder, remove yaml"
```

---

### Task 5: Update example app

Wire up the example app to use real classes and generated builders.

**Files:**
- Modify: `example/lib/custom/custom_widgets.dart`
- Modify: `example/lib/custom/custom_widget_builders.dart`
- Modify: `example/lib/main.dart` — update library name if needed
- Delete: `example/rfw_gen.yaml`

- [ ] **Step 1: Update custom_widgets.dart**

In `example/lib/custom/custom_widgets.dart`:
- Replace line 1 (`// ignore_for_file: ...`) with `import 'custom_widget_classes.dart';`
- Keep existing `import 'package:flutter/material.dart';` and `import 'package:rfw_gen/rfw_gen.dart';`

- [ ] **Step 2: Run build_runner**

Run: `cd example && dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `.rfwtxt`, `.rfw`, `.rfw_library.dart`, `.rfw_meta.json`

- [ ] **Step 3: Replace manual builders with generated**

Replace entire content of `example/lib/custom/custom_widget_builders.dart`:

```dart
import 'package:rfw/rfw.dart';

import 'custom_widget_classes.rfw_library.dart';

/// Custom widget library name used in rfwtxt imports.
const customWidgetsLibraryName = LibraryName(<String>['rfw_gen_example']);

/// Auto-generated [LocalWidgetBuilder]s from @rfwLocalWidget-annotated classes.
final Map<String, LocalWidgetBuilder> customWidgetBuilders =
    generatedLocalWidgetBuilders;
```

Note: library name changes from `['custom', 'widgets']` to `['rfw_gen_example']` (package-name-based).

- [ ] **Step 4: Update main.dart library name references**

**Library name architecture (important):**
- `customWidgetsLibraryName` (`['custom', 'widgets']` → `['rfw_gen_example']`) — the RFW library name for `LocalWidgetLibrary` registration. This MUST match the rfwtxt `import` statement.
- `_customLibrary` (`['customdemo']`) — the library name for the `.rfw` binary containing demo widgets. This is the name under which the BINARY is loaded, separate from the widget builder library.

In `example/lib/main.dart`:
- `customWidgetsLibraryName` is imported from `custom_widget_builders.dart` (already updated in Step 3)
- `_customLibrary` stays as `['customdemo']` — this is for the binary demos, NOT the widget builders
- BUT: the rfwtxt `import` inside the binary will now say `import rfw_gen_example;` instead of `import custom.widgets;`. So the binary will try to look up widgets from the `rfw_gen_example` library. This means `customWidgetsLibraryName` MUST be `['rfw_gen_example']` for resolution to work.
- Check that `_customWidgetNames` set still works (widget names are unchanged)

Also update `example/test/helpers/golden_test_helper.dart`:
- `customWidgetsLibraryName` is imported and used for `LocalWidgetLibrary` registration — no change needed (it comes from the import)

Also check golden test files for hardcoded library name references:
```bash
grep -r "customdemo\|custom.*widgets" example/test/ --include="*.dart"
```
Update any that reference `custom.widgets` library name.

- [ ] **Step 5: Delete rfw_gen.yaml**

```bash
rm example/rfw_gen.yaml
```

- [ ] **Step 6: Verify compilation**

Run: `cd example && dart analyze`
Expected: No errors. All 4 consumers of `custom_widget_builders.dart` compile:
- `main.dart`
- `preview_page.dart`
- `preview_app.dart`
- `golden_test_helper.dart`

- [ ] **Step 7: Run example tests**

Run: `cd example && flutter test --exclude-tags golden`
Expected: All pass

- [ ] **Step 8: Commit**

```bash
git add example/
git rm example/rfw_gen.yaml
git commit -m "feat(example): use generated LocalWidgetBuilders, remove rfw_gen.yaml"
```

---

### Task 6: Update MCP server

Switch MCP from yaml to `.rfw_meta.json`.

**Files:**
- Modify: `packages/rfw_gen_mcp/lib/src/server.dart`

- [ ] **Step 1: Replace `_loadCustomWidgets` with `_loadCustomWidgetsFromMeta`**

In `packages/rfw_gen_mcp/lib/src/server.dart`:

Replace the yaml-based `_loadCustomWidgets` with a JSON-based version:

```dart
/// Loads custom widgets from generated .rfw_meta.json files.
///
/// Searches for .rfw_meta.json in the current directory and lib/ subdirectories.
/// Falls back to core widgets only if no meta files found.
void _loadCustomWidgetsFromMeta(WidgetRegistry registry) {
  // Search for .rfw_meta.json files
  // Parse JSON, register widgets with registry
  // Use registry.register() with WidgetMapping constructed from JSON data
}
```

- [ ] **Step 2: Remove yaml dependency**

In `packages/rfw_gen_mcp/lib/src/server.dart`:
- Remove `import 'package:yaml/yaml.dart';`

In `packages/rfw_gen_mcp/pubspec.yaml`:
- Remove `yaml` dependency (if no other files use it)

- [ ] **Step 3: Run MCP tests**

Run: `cd packages/rfw_gen_mcp && dart test`
Expected: All pass (existing tests may need updates)

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen_mcp/
git commit -m "feat(rfw_gen_mcp): read .rfw_meta.json instead of rfw_gen.yaml"
```

---

### Task 7: Clean up and remove yaml from builder package

Remove yaml dependency from rfw_gen_builder.

**Files:**
- Modify: `packages/rfw_gen_builder/pubspec.yaml`

- [ ] **Step 1: Remove yaml dependency**

In `packages/rfw_gen_builder/pubspec.yaml`:
- Remove `yaml: ^3.1.0` from dependencies (if no other files use it)

- [ ] **Step 2: Clean up any remaining yaml references**

Search for remaining yaml references:
```bash
grep -r "yaml" packages/rfw_gen_builder/ --include="*.dart"
grep -r "rfw_gen.yaml" packages/ --include="*.dart"
```

Remove any remaining references.

- [ ] **Step 3: Run all tests across packages**

Run: `cd packages/rfw_gen_builder && dart test`
Run: `cd packages/rfw_gen_mcp && dart test`
Run: `dart analyze`
Expected: All pass, no errors

- [ ] **Step 4: Commit**

```bash
git add packages/rfw_gen_builder/pubspec.yaml
git commit -m "chore(rfw_gen_builder): remove yaml dependency"
```

---

### Task 8: Final verification and version bump

- [ ] **Step 1: Run full test suite**

```bash
cd packages/rfw_gen_builder && dart test
cd packages/rfw_gen && dart test
cd packages/rfw_gen_mcp && dart test
cd example && flutter test --exclude-tags golden
dart analyze
```

Expected: All pass

- [ ] **Step 2: Verify build_runner end-to-end**

```bash
cd example && dart run build_runner clean
cd example && dart run build_runner build --delete-conflicting-outputs
```

Expected: Generates all output files (.rfwtxt, .rfw, .rfw_library.dart, .rfw_meta.json)

- [ ] **Step 3: Verify generated files**

Check:
- `.rfw_library.dart` contains all 13 custom widgets
- `.rfw_meta.json` contains valid JSON with widget metadata
- `.rfwtxt` imports use package name (not `custom.widgets`)
- No references to `rfw_gen.yaml` remain

- [ ] **Step 4: Version bump to 0.4.0**

Update version in:
- `packages/rfw_gen/pubspec.yaml`
- `packages/rfw_gen_builder/pubspec.yaml`
- `packages/rfw_gen_mcp/pubspec.yaml`

Update version references:
- `packages/rfw_gen_builder/pubspec.yaml` → `rfw_gen: ^0.4.0`
- `packages/rfw_gen_mcp/lib/src/server.dart` → version string

- [ ] **Step 5: Delete spike test**

```bash
rm packages/rfw_gen_builder/test/resolver_spike_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "release: bump all packages to 0.4.0 (breaking: remove rfw_gen.yaml)"
```
