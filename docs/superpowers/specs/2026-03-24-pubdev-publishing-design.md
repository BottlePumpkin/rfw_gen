# rfw_gen pub.dev Publishing Design Spec

**Date**: 2026-03-24
**Status**: Approved

## Problem

rfw_gen is technically mature (514 tests, 65 widgets, clean architecture) but cannot be published to pub.dev or used by external developers. The package mixes runtime and build-time code, lacks required pub.dev metadata, documentation, and CI/CD.

## Goal

Publish `rfw_gen` and `rfw_gen_builder` to pub.dev following Dart ecosystem conventions, while maintaining internal usability.

## 1. Package Split

### Motivation

Current `rfw_gen` bundles runtime helpers with build-time conversion engine. This forces `package:analyzer` (~heavy) into user's runtime dependencies. Following Dart conventions (`json_annotation` + `json_serializable`, `freezed_annotation` + `freezed`), we split into:

| Package | Role | User installs in | Key dependencies |
|---------|------|------------------|-----------------|
| `rfw_gen` | Annotations + runtime helpers | `dependencies` | `rfw` only |
| `rfw_gen_builder` | Conversion engine + build_runner | `dev_dependencies` | `analyzer`, `build`, `rfw`, `rfw_gen` |

### Files staying in rfw_gen (runtime)

| File | Public API |
|------|-----------|
| `annotations.dart` | `@RfwWidget` |
| `rfw_helpers.dart` | `DataRef`, `ArgsRef`, `StateRef`, `LoopVar`, `RfwConcat`, `RfwSwitch`, `RfwSwitchValue`, `RfwFor` |
| `rfw_handler.dart` | `RfwHandler`, `RfwSetState`, `RfwSetStateFromArg`, `RfwEvent` |
| `rfw_icons.dart` | `RfwIcon` constants |
| `rfw_only_widgets.dart` | `SizedBoxShrink`, `SizedBoxExpand`, `Rotation`, `Scale`, `AnimationDefaults` |
| `errors.dart` | `RfwGenException`, `RfwGenIssue` |

### Files moving to rfw_gen_builder (build-time)

| File | Public API |
|------|-----------|
| `converter.dart` | `RfwConverter` |
| `ast_visitor.dart` | `WidgetAstVisitor` |
| `expression_converter.dart` | `ExpressionConverter` |
| `rfwtxt_emitter.dart` | `RfwtxtEmitter` |
| `ir.dart` | `IrWidgetNode`, `IrValue`, etc. |
| `widget_registry.dart` | `WidgetRegistry`, `ParamMapping`, `WidgetMapping` |

### Existing builder files (unchanged)

These files already exist in `rfw_gen_builder` and stay as-is:

| File | Purpose |
|------|---------|
| `lib/builder.dart` | Factory function `rfwWidgetBuilder()` for build_runner |
| `lib/src/rfw_widget_builder.dart` | `RfwWidgetBuilder` — the actual `Builder` implementation |
| `build.yaml` | build_runner configuration (auto_apply: dependents, build_to: source) |

### Test split

Tests are split by what they test:

**Stay in rfw_gen/test/ (runtime code tests):**

| Test | Reason |
|------|--------|
| `annotations_test.dart` | Tests `@RfwWidget` annotation |
| `rfw_only_widgets_test.dart` | Tests RFW-only widget classes |

**Move to rfw_gen_builder/test/ (build-time code tests):**

| Test | Reason |
|------|--------|
| `ast_visitor_test.dart` | Tests `WidgetAstVisitor` |
| `expression_converter_test.dart` | Tests `ExpressionConverter` |
| `rfwtxt_emitter_test.dart` | Tests `RfwtxtEmitter` |
| `widget_registry_test.dart` | Tests `WidgetRegistry` |
| `ir_test.dart` | Tests IR classes |
| `converter_test.dart` | Tests `RfwConverter` |
| `integration_test.dart` | Tests full pipeline |
| `spec_sync_test.dart` | Tests registry ↔ converter consistency |
| `rfw_helpers_test.dart` | Tests runtime helpers but uses converter internals — move |

**Stay in rfw_gen_builder/test/ (existing):**

| Test | Reason |
|------|--------|
| `builder_test.dart` | Tests `RfwWidgetBuilder` (already here) |

### Dependency direction

```
rfw_gen_builder --> rfw_gen (forward dependency, correct)
rfw_gen_builder --> package:analyzer
rfw_gen_builder --> package:rfw (for parseLibraryFile in converter.dart)
rfw_gen --> package:rfw (runtime only, for type references)
```

No circular dependencies. `expression_converter.dart` imports `rfw_icons.dart` — clean forward dependency.

### Dependency changes after split

**rfw_gen/pubspec.yaml:**
- Remove `analyzer: ^9.0.0` (no longer needed)
- Remove `yaml` from dev_dependencies (no longer needed)
- Keep `rfw: ^1.0.0`

**rfw_gen_builder/pubspec.yaml:**
- Add `rfw: ^1.0.0` (needed by converter.dart for `parseLibraryFile`)
- Keep `analyzer: ^9.0.0`, `build: ^4.0.0`, `yaml: ^3.1.0`
- Change `rfw_gen` from path dependency to version: `rfw_gen: ^0.1.0`

### Barrel exports after split

**rfw_gen/lib/rfw_gen.dart**:
```dart
export 'src/annotations.dart';
export 'src/rfw_helpers.dart';
export 'src/rfw_handler.dart';
export 'src/rfw_icons.dart';
export 'src/rfw_only_widgets.dart';
export 'src/errors.dart';
```

**rfw_gen_builder/lib/rfw_gen_builder.dart**:
```dart
export 'src/rfw_widget_builder.dart'; // existing
export 'src/converter.dart';
export 'src/widget_registry.dart';
// Internal: ast_visitor, expression_converter, rfwtxt_emitter, ir
```

**rfw_gen_builder/lib/builder.dart** (unchanged):
```dart
import 'src/rfw_widget_builder.dart';
Builder rfwWidgetBuilder(BuilderOptions options) => RfwWidgetBuilder(options);
```

## 2. Metadata & Licensing

### LICENSE

BSD-3-Clause. One file at repository root, copied into each package directory for pub.dev.

### pubspec.yaml changes (both packages)

- Remove `publish_to: none`
- Add `homepage: <GitHub repo URL>`
- Add `repository: <GitHub repo URL>`
- Add `topics: [rfw, remote-flutter-widgets, code-generation]`
- Version: `0.1.0`

### .pubignore (both packages)

Exclude from published package:
- `docs/`
- `.claude/`
- `melos.yaml`
- Test fixtures / golden files
- CI configuration (`.github/`)
- Root `example/` (the Flutter app; distinct from per-package `example/example.dart`)

### SDK constraints

Verify minimum Dart SDK version matches actual language features used. Confirm with `dart pub publish --dry-run`.

## 3. Documentation

### README.md

**rfw_gen/README.md** (pub.dev main page, English):
- Project introduction (Flutter Widget → RFW conversion)
- Installation (rfw_gen in dependencies, rfw_gen_builder + build_runner in dev_dependencies)
- Quick start example (@RfwWidget usage)
- Supported widgets (65)
- Custom widgets (rfw_gen.yaml)
- Dynamic features (DataRef, StateRef, RfwFor, RfwSwitch, etc.)
- Pre-1.0 breaking change policy note

**rfw_gen_builder/README.md** (English):
- Brief description (build_runner integration for rfw_gen)
- Installation / setup
- Link to rfw_gen README for full docs

### CHANGELOG.md (both packages)

```markdown
## 0.1.0

- Initial release
- Support 65 widgets (Core + Material)
- Custom widget support via rfw_gen.yaml
- Dynamic features: DataRef, ArgsRef, StateRef, RfwFor, RfwSwitch, RfwConcat
- Event handlers: RfwHandler (setState, event)
- Binary (.rfw) and text (.rfwtxt) output
```

### dartdoc

Add `///` documentation comments to all public API in both packages. Internal/private members skipped.

### example/example.dart

`rfw_gen/example/example.dart` — minimal ~20 line example showing `@RfwWidget` basic usage. `rfw_gen_builder` does not need an example file.

## 4. CI/CD

### .github/workflows/ci.yml (PR / push to main)

Three parallel jobs:

**rfw_gen job:**
```yaml
steps:
  - dart pub get
  - dart analyze
  - dart format --set-exit-if-changed .
  - dart test
  - dart pub publish --dry-run
```

**rfw_gen_builder job:**
```yaml
steps:
  - dart pub get
  - dart analyze
  - dart format --set-exit-if-changed .
  - dart test
  - dart pub publish --dry-run
```

**golden_test job:**

An existing `.github/workflows/golden_test.yml` already handles golden tests (ubuntu-latest, Flutter 3.32.0, PR trigger + manual workflow_dispatch for updating goldens). Keep this as a separate workflow — do not merge into ci.yml. The ci.yml only runs the two package jobs above.

### .github/workflows/publish.yml (tag push v*)

Triggered on tag push (`v*`):
```yaml
steps:
  - dart pub publish --directory packages/rfw_gen        # first
  - dart pub publish --directory packages/rfw_gen_builder # second, depends on rfw_gen
```

Authentication via GitHub OIDC token (pub.dev official support, no secret keys).

Publish order: rfw_gen first → rfw_gen_builder second (dependency order).

### Note on `dart test` vs `flutter test`

Both `rfw_gen` and `rfw_gen_builder` are pure Dart packages (no Flutter SDK dependency). The `rfw` package is usable from pure Dart via `package:rfw/formats.dart`. All tests use `dart test`, not `flutter test`. Only the example app's golden tests require `flutter test`.

## 5. Version Strategy

- Start at `0.1.0`
- Pre-1.0: breaking changes allowed in minor versions (0.2.0, 0.3.0)
- README states: "This package is pre-1.0. Minor version bumps may include breaking changes."
- Both packages maintain same version number for simplicity

## Implementation Order

1. Package split — move build-time files from rfw_gen to rfw_gen_builder
2. Update barrel exports and internal imports
3. Update pubspec.yaml dependencies (remove analyzer from rfw_gen, add rfw to rfw_gen_builder)
4. Split tests — runtime tests stay, build-time tests move
5. Verify all tests pass in both packages (`dart test` in each)
6. Add LICENSE (BSD-3-Clause) to root and both packages
7. Update pubspec.yaml metadata (remove publish_to: none, add homepage/repository/topics)
8. Add .pubignore to both packages
9. Write README.md (both packages)
10. Write CHANGELOG.md (both packages)
11. Add dartdoc comments to public API
12. Add example/example.dart (rfw_gen only)
13. Set up CI/CD (ci.yml + publish.yml)
14. `dart pub publish --dry-run` validation for both packages
15. Publish (rfw_gen first → rfw_gen_builder second)
