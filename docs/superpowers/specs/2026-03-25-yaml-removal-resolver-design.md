# rfw_gen.yaml Removal & Resolver-Based Widget Analysis Design

## Goal

Remove `rfw_gen.yaml` by switching the builder to `BuildStep.resolver` for cross-package widget analysis. Auto-generate `LocalWidgetBuilder` maps. External widget packages (e.g., mystique) require zero modification.

## Background

### Current State
- `rfw_gen.yaml` provides: `import` (RFW library name), `child_type`, `handlers`, `named_child_slots`
- Builder uses `parseString()` (AST only, no type resolution)
- `@RfwWidget` functions reference custom widgets via `undefined_class` pattern
- `LocalWidgetBuilder` maps are written manually (~150 lines of boilerplate)
- Both `rfw_gen_builder` and `rfw_gen_mcp` read `rfw_gen.yaml`

### Problems
- `rfw_gen.yaml` duplicates info already in class constructors
- Manual `LocalWidgetBuilder` is tedious and error-prone
- Adding a custom widget requires updating 3 places: class, yaml, builder

### After This Change
- `rfw_gen.yaml` removed entirely
- Builder uses Resolver to analyze class constructors across packages
- `child_type`, `handlers`, `named_child_slots` inferred from constructor types
- `import` (RFW library name) derived from Dart package name
- `LocalWidgetBuilder` auto-generated
- External packages unchanged

## Architecture

### Core Idea

When the builder processes an `@RfwWidget` function and encounters an unknown widget (e.g., `CouponCard(...)`):

```
@RfwWidget('couponDemo')
Widget demo() => CouponCard(title: 'hello', onTap: RfwHandler.event('tap', {}));
                 ^^^^^^^^^^
                 Not in core registry → resolve via BuildStep.resolver
```

1. **Resolver** finds `CouponCard` class in `package:mystique/...`
2. **Constructor analysis** extracts parameter types:
   - `String title` → regular param
   - `VoidCallback? onTap` → handler
   - `Widget child` → child (required)
   - `Widget? leading` → optionalChild / named slot
   - `List<Widget> children` → childList
3. **Import derivation**: package name `mystique` → rfwtxt `import mystique;`
4. **WidgetMapping** created and cached (same as yaml-based, just auto-populated)
5. **LocalWidgetBuilder** generated for all resolved custom widgets

### Type Inference Rules

From class constructor parameters, infer `ChildType` and handler info:

```
Parameter Type        → WidgetMapping Field
─────────────────────────────────────────────────
Widget (required)     → childType: child, childParam: paramName
Widget? (nullable)    → added to namedChildSlots (single)
List<Widget>          → childType: childList, childParam: paramName
VoidCallback?         → added to handlerParams
void Function()?      → added to handlerParams
String/int/double/bool → regular param (pass-through)
Key?                  → skip
```

**Child type resolution logic (priority order):**
1. Has `List<Widget>` param → `ChildType.childList`, childParam = param name
2. Has exactly 1 required `Widget` param named `child` → `ChildType.child`, childParam = `child`. Any additional `Widget?` params become `namedChildSlots`.
3. Has exactly 1 `Widget?` param named `child` (no other Widget params) → `ChildType.optionalChild`, childParam = `child`
4. Has multiple `Widget?` params (none named `child`) → `ChildType.namedSlots`, all become named slots
5. Has 0 Widget/List<Widget> params → `ChildType.none`

**Mixed case example** (`CustomCard`): `Widget child` + `Widget? leading` → `ChildType.child` with `childParam: 'child'`, `namedChildSlots: {'leading': false}`

### Import Name Derivation

RFW library name = Dart package name of the widget class.

```
Dart: import 'package:mystique/widgets/coupon.dart'
                       ^^^^^^^^
RFW:  import mystique;

Dart: same package (e.g., rfw_gen_example)
RFW:  import rfw_gen_example;
```

If multiple packages provide custom widgets, multiple imports are emitted:
```rfwtxt
import mystique;
import design_system;
```

## Component Design

### 1. WidgetResolver (NEW)

**File:** `packages/rfw_gen_builder/lib/src/widget_resolver.dart`

Wraps `BuildStep.resolver` to analyze widget classes.

```dart
class WidgetResolver {
  final Resolver resolver;
  final AssetId inputId;

  /// Resolves a widget class by name from the input library's imports.
  /// Returns a WidgetMapping with inferred child_type, handlers, etc.
  /// Returns null if the class cannot be resolved.
  ///
  /// Lookup strategy:
  /// 1. Resolve input file's library via resolver.libraryFor(inputId)
  /// 2. Walk LibraryElement.importedLibraries to find exported classes
  /// 3. Match by class name (widgetName)
  /// 4. Verify it extends StatelessWidget or StatefulWidget
  /// 5. Analyze the unnamed constructor (or first constructor)
  Future<WidgetMapping?> resolveWidget(String widgetName);

  /// Analyzes a class constructor and builds a WidgetMapping.
  WidgetMapping _buildMapping(ClassElement classElement, String packageName);

  /// Infers ChildType from constructor parameters.
  ChildType _inferChildType(List<ParameterElement> params);

  /// Extracts handler parameter names (VoidCallback? types).
  Set<String> _extractHandlers(List<ParameterElement> params);

  /// Extracts named child slots (Widget? params, excluding main child).
  Map<String, bool> _extractNamedSlots(List<ParameterElement> params);
}
```

### 2. LocalWidgetBuilderGenerator (NEW)

**File:** `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`

Generates `LocalWidgetBuilder` Dart code from resolved widget info.

```dart
class LocalWidgetBuilderGenerator {
  /// Generates a .rfw_library.dart file containing a
  /// Map<String, LocalWidgetBuilder> for all resolved custom widgets.
  String generate(Map<String, ResolvedWidget> widgets);
}

class ResolvedWidget {
  final String className;
  final String packageImport;  // e.g., 'package:mystique/widgets/coupon.dart'
  final List<ResolvedParam> constructorParams;
}

class ResolvedParam {
  final String name;
  final String typeName;     // String, int, Widget, VoidCallback, etc.
  final bool isRequired;
  final bool isNullable;
  final String? defaultValue;
}
```

### 3. RfwWidgetBuilder (MODIFY)

**File:** `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`

Changes:
- Remove yaml loading code (lines 46-66)
- Add Resolver-based widget discovery
- Generate `.rfw_library.dart` in addition to `.rfwtxt` and `.rfw`
- Cache resolved widgets per build step

```dart
// Before
final registry = WidgetRegistry.core();
// ... load yaml, registerFromConfig ...
final converter = RfwConverter(registry: registry);

// After
final registry = WidgetRegistry.core();
final widgetResolver = WidgetResolver(
  resolver: buildStep.resolver,
  inputId: buildStep.inputId,
);
// Resolve custom widgets on-demand during AST traversal
final converter = RfwConverter(
  registry: registry,
  widgetResolver: widgetResolver,  // NEW: lazy resolution
);
```

**Build extensions change:**
```yaml
# Before
build_extensions: {".dart": [".rfwtxt", ".rfw"]}

# After
build_extensions: {".dart": [".rfwtxt", ".rfw", ".rfw_library.dart", ".rfw_meta.json"]}
```

### 4. WidgetRegistry (MODIFY)

**File:** `packages/rfw_gen_builder/lib/src/widget_registry.dart`

Changes:
- Remove `registerFromConfig()` method
- Add `registerResolved(String name, WidgetMapping mapping)` (same as `register`, keeps API clean)
- Keep all core widget registrations unchanged

### 5. WidgetAstVisitor (MODIFY) — Two-Phase Approach

**File:** `packages/rfw_gen_builder/lib/src/ast_visitor.dart`

**Design choice:** Instead of making `WidgetAstVisitor` async (which would cascade through every recursive method), use a **two-phase approach**:

**Phase 1 — Pre-scan (async, in RfwWidgetBuilder):** Collect all unknown widget names from the AST synchronously, then batch-resolve them via Resolver before conversion begins.

```dart
// In RfwWidgetBuilder.build():
// Phase 1: Scan for unknown widget names
final unknownWidgets = _collectUnknownWidgetNames(parseResult.unit, registry);
// Batch resolve all at once
for (final name in unknownWidgets) {
  final mapping = await widgetResolver.resolveWidget(name);
  if (mapping != null) {
    registry.register(name, mapping);
    resolvedCustomWidgets[name] = mapping;
  }
}

// Phase 2: Run existing synchronous conversion (unchanged)
final converter = RfwConverter(registry: registry);
final result = converter.convertFromAst(function, source: source);
```

**Phase 2 — Convert (synchronous, unchanged):** The existing `WidgetAstVisitor` runs synchronously as before. All custom widgets are already registered in the registry.

This avoids the async cascade entirely. `WidgetAstVisitor`, `RfwConverter`, and `ExpressionConverter` remain synchronous.

**`_collectUnknownWidgetNames`** is a simple synchronous AST walk that finds all `MethodInvocation`/`InstanceCreationExpression` nodes with names not in the core registry.

Changes to `WidgetAstVisitor`:
- No async changes needed
- Existing `UnsupportedWidgetError` still thrown if a widget was not resolved in Phase 1

### 6. MCP Server (MODIFY)

**File:** `packages/rfw_gen_mcp/lib/src/server.dart`

The MCP server currently reads `rfw_gen.yaml` to know about custom widgets. After yaml removal:

**Option A (recommended):** Builder generates a metadata JSON file (`.rfw_meta.json`) alongside `.rfw_library.dart`. MCP reads this file.

```json
{
  "widgets": {
    "CouponCard": {
      "import": "mystique",
      "childType": "child",
      "handlers": ["onTap"],
      "params": [
        {"name": "title", "type": "String", "required": true},
        {"name": "onTap", "type": "VoidCallback", "required": false}
      ]
    }
  }
}
```

**Option B:** MCP uses its own AST parsing to scan source files (duplicates logic).

Option A is better — single source of analysis, MCP just reads the output.

**Behavior change:** MCP's `convert_to_rfwtxt` tool will only support custom widgets if `.rfw_meta.json` exists (i.e., after `build_runner` has run at least once). Without it, only core/material widgets are available. This is a documented regression from the yaml-based approach where MCP always had custom widget info.

### 7. @RfwWidget Annotation (NO CHANGE)

**File:** `packages/rfw_gen/lib/src/annotations.dart`

`@RfwWidget` stays as-is. `name` remains required. No annotation changes in this release — widget classes are discovered via `@RfwWidget` function usage + Resolver, not via class-level annotations.

```dart
// Unchanged
class RfwWidget {
  final String name;
  final Map<String, dynamic>? state;
  const RfwWidget(this.name, {this.state});
}
```

### 8. Example App Changes

**Create:** `example/lib/custom/custom_widget_classes.dart`
- 13 real Flutter `StatelessWidget` classes
- Move render logic from manual builders into classes
- No annotation needed on classes (builder discovers them from @RfwWidget function usage)

**Modify:** `example/lib/custom/custom_widgets.dart`
- Remove `ignore_for_file: undefined_class`
- Import real classes

**Delete:** `example/rfw_gen.yaml`

**Replace:** `example/lib/custom/custom_widget_builders.dart`
- Content replaced with import of generated `.rfw_library.dart`

## Data Flow

```
@RfwWidget('demo')
Widget buildDemo() => CouponCard(title: 'hi', onTap: handler);
                      ^^^^^^^^^^
                          │
                          ▼
              ┌─ In core registry? ──── YES ──→ Use existing mapping
              │
              NO
              │
              ▼
    BuildStep.resolver
    → Find CouponCard class in package:mystique
    → Analyze constructor:
        title: String (required)    → regular param
        onTap: VoidCallback?        → handler
        child: Widget               → childType: child
    → Package: mystique             → import: mystique
              │
              ▼
    ┌─────────────────────────────┐
    │ WidgetMapping created       │
    │ (same structure as before)  │
    │ cached in registry          │
    └────────┬────────────────────┘
             │
       ┌─────┴──────┐
       ▼             ▼
   .rfwtxt       .rfw_library.dart
   .rfw          (LocalWidgetBuilder)
```

## Testing Strategy

### Unit Tests

**WidgetResolver tests:**
- Resolve widget from same package
- Resolve widget from external package (cross-package)
- Resolve widget with various constructor patterns:
  - No children (ChildType.none)
  - Single required Widget child
  - Single optional Widget? child
  - List<Widget> children
  - Multiple Widget? params (namedSlots)
  - VoidCallback? handlers
  - Mixed params (handlers + children + primitives)
  - Key? parameter (should be skipped)
  - Empty constructor
  - Default values preservation
- Widget class not found → returns null
- Non-widget class (no StatelessWidget/StatefulWidget) → returns null
- Abstract widget class → returns null
- Widget with factory constructor → uses unnamed constructor
- Widget with multiple constructors → uses unnamed constructor
- Widget with `Key? key` as regular param (not super.key) → skipped

**LocalWidgetBuilderGenerator tests:**
- Generate builder for simple widget (primitives only)
- Generate builder with Widget child
- Generate builder with Widget? optionalChild
- Generate builder with List<Widget> children
- Generate builder with VoidCallback handlers
- Generate builder with named slots (multiple Widget? params)
- Generate builder with mixed param types
- Generate builder with default values
- Generate for multiple widgets in one file
- Import paths are correct
- Generated code compiles (dart analyze)

**Import derivation tests:**
- Same package → uses own package name
- External package → uses external package name
- Multiple packages → multiple imports

### Integration Tests

**Builder integration (build_test):**
- Single file with @RfwWidget function + widget class → generates .rfwtxt + .rfw + .rfw_library.dart
- Cross-file reference (class in different file, same package)
- Widget not found → appropriate error
- Mix of core + custom widgets → core uses existing mapping, custom uses Resolver
- Generated .rfw_library.dart compiles and contains correct builders

**Behavioral equivalence:**
- Generated LocalWidgetBuilder produces same widget tree as manual builder
- For each of the 13 example widgets, verify parameter passing is identical

**Regression:**
- All existing rfwtxt generation tests still pass
- All existing golden tests pass (note: widget tree has extra StatelessWidget layer, golden images need regeneration on Linux CI)

### MCP Tests
- MCP reads generated `.rfw_meta.json`
- Widget metadata matches resolved info
- MCP works without rfw_gen.yaml present

## Breaking Changes (v0.4.0)

1. `rfw_gen.yaml` no longer read — users should delete it
2. RFW import names change from arbitrary to package-name-based
3. `registerFromConfig()` removed from `WidgetRegistry`
4. Custom widgets must be real Flutter classes (no more `undefined_class` pattern)
5. Build requires Dart SDK with Resolver support (already met by `sdk: ^3.6.0`)
6. Golden test images will differ (extra StatelessWidget layer)
7. MCP `convert_to_rfwtxt` requires `.rfw_meta.json` for custom widgets (generated by build_runner)

## Migration Guide

### For users with rfw_gen.yaml:
1. Create real Flutter widget classes (if using `undefined_class` pattern)
2. Import real classes in `@RfwWidget` functions (remove `ignore_for_file`)
3. Delete `rfw_gen.yaml`
4. Run `build_runner build` — generates `.rfw_library.dart` + `.rfw_meta.json`
5. Replace manual `LocalWidgetBuilder` with import of generated file
6. Update runtime registration to use package-name-based library names:

```dart
// Before
runtime.update(
  LibraryName(['custom', 'widgets']),
  LocalWidgetLibrary(customWidgetBuilders),
);

// After (package name = rfw_gen_example)
runtime.update(
  LibraryName(['rfw_gen_example']),
  LocalWidgetLibrary(generatedLocalWidgetBuilders),
);
```

### For external widget packages (e.g., mystique):
- No changes needed. Packages are analyzed via Resolver automatically.

## File Changes Summary

### Create
- `packages/rfw_gen_builder/lib/src/widget_resolver.dart`
- `packages/rfw_gen_builder/lib/src/local_widget_builder_generator.dart`
- `packages/rfw_gen_builder/test/widget_resolver_test.dart`
- `packages/rfw_gen_builder/test/local_widget_builder_test.dart`
- `example/lib/custom/custom_widget_classes.dart`

### Modify
- `packages/rfw_gen/lib/src/annotations.dart` — no change (keep as-is)
- `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart` — Resolver integration, .rfw_library.dart output
- `packages/rfw_gen_builder/lib/src/widget_registry.dart` — remove registerFromConfig
- `packages/rfw_gen_builder/lib/src/ast_visitor.dart` — no async change (two-phase approach keeps it sync)
- `packages/rfw_gen_builder/lib/src/converter.dart` — no async change (stays sync)
- `packages/rfw_gen_builder/build.yaml` — add .rfw_library.dart extension
- `packages/rfw_gen_mcp/lib/src/server.dart` — read .rfw_meta.json instead of yaml
- `example/lib/custom/custom_widgets.dart` — import real classes
- `example/lib/custom/custom_widget_builders.dart` — re-export generated

### Delete
- `example/rfw_gen.yaml`

## Out of Scope
- Annotation on widget classes (not needed — builder discovers via @RfwWidget function usage)
- Custom RFW import name override (convention: package name. Can add later if needed)
- Multiple RFW libraries per package (one package = one RFW library for now)
