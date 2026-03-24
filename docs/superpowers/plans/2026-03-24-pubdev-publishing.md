# pub.dev Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish rfw_gen and rfw_gen_builder to pub.dev with proper package split, documentation, and CI/CD.

**Architecture:** Split rfw_gen into runtime annotations (rfw_gen) and build-time engine (rfw_gen_builder), following the json_annotation/json_serializable pattern. Add pub.dev metadata, documentation, and GitHub Actions CI/CD.

**Tech Stack:** Dart 3, build_runner, GitHub Actions, pub.dev OIDC publishing

**Spec:** `docs/superpowers/specs/2026-03-24-pubdev-publishing-design.md`

---

## File Structure

### rfw_gen (runtime — stays)
```
packages/rfw_gen/
├── lib/
│   ├── rfw_gen.dart              ← barrel export (MODIFY: remove build-time exports)
│   └── src/
│       ├── annotations.dart       ← stays
│       ├── rfw_helpers.dart       ← stays
│       ├── rfw_handler.dart       ← stays
│       ├── rfw_icons.dart         ← stays
│       ├── rfw_only_widgets.dart  ← stays
│       └── errors.dart            ← stays
├── test/
│   ├── annotations_test.dart      ← stays
│   └── rfw_only_widgets_test.dart ← stays
├── example/
│   └── example.dart               ← CREATE
├── pubspec.yaml                   ← MODIFY
├── README.md                      ← CREATE
├── CHANGELOG.md                   ← CREATE
├── LICENSE                        ← CREATE (copy from root)
└── .pubignore                     ← CREATE
```

### rfw_gen_builder (build-time — receives moved files)
```
packages/rfw_gen_builder/
├── lib/
│   ├── builder.dart               ← unchanged
│   ├── rfw_gen_builder.dart        ← MODIFY: add exports
│   └── src/
│       ├── rfw_widget_builder.dart ← MODIFY: update imports
│       ├── converter.dart          ← MOVE from rfw_gen
│       ├── ast_visitor.dart        ← MOVE from rfw_gen
│       ├── expression_converter.dart ← MOVE from rfw_gen
│       ├── rfwtxt_emitter.dart     ← MOVE from rfw_gen
│       ├── ir.dart                 ← MOVE from rfw_gen
│       └── widget_registry.dart    ← MOVE from rfw_gen
├── test/
│   ├── builder_test.dart           ← unchanged
│   ├── ast_visitor_test.dart       ← MOVE from rfw_gen
│   ├── expression_converter_test.dart ← MOVE from rfw_gen
│   ├── rfwtxt_emitter_test.dart    ← MOVE from rfw_gen
│   ├── widget_registry_test.dart   ← MOVE from rfw_gen
│   ├── ir_test.dart                ← MOVE from rfw_gen
│   ├── converter_test.dart         ← MOVE from rfw_gen
│   ├── integration_test.dart       ← MOVE from rfw_gen
│   ├── spec_sync_test.dart         ← MOVE from rfw_gen
│   └── rfw_helpers_test.dart       ← MOVE from rfw_gen
├── pubspec.yaml                    ← MODIFY
├── README.md                       ← CREATE
├── CHANGELOG.md                    ← CREATE
├── LICENSE                         ← CREATE (copy from root)
└── .pubignore                      ← CREATE
```

### Root level
```
rfw_gen/
├── LICENSE                         ← CREATE
└── .github/
    └── workflows/
        ├── ci.yml                  ← CREATE
        ├── publish.yml             ← CREATE
        └── golden_test.yml         ← unchanged
```

---

## Task 1: Move build-time source files to rfw_gen_builder

**Files:**
- Move: `packages/rfw_gen/lib/src/{converter,ast_visitor,expression_converter,rfwtxt_emitter,ir,widget_registry}.dart` → `packages/rfw_gen_builder/lib/src/`
- Modify: `packages/rfw_gen/lib/rfw_gen.dart` (barrel export)
- Modify: `packages/rfw_gen_builder/lib/rfw_gen_builder.dart` (barrel export)

- [ ] **Step 1: Move 6 source files**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
for f in converter.dart ast_visitor.dart expression_converter.dart rfwtxt_emitter.dart ir.dart widget_registry.dart; do
  mv packages/rfw_gen/lib/src/$f packages/rfw_gen_builder/lib/src/$f
done
```

- [ ] **Step 2: Update relative imports in moved files**

The moved files use relative imports to each other. Since they all move together to the same directory, relative imports between them stay the same. Only one cross-package import needs updating:

In `packages/rfw_gen_builder/lib/src/expression_converter.dart`, change:
```dart
// FROM:
import 'rfw_icons.dart';
// TO:
import 'package:rfw_gen/src/rfw_icons.dart';
```

- [ ] **Step 3: Update rfw_gen barrel export**

Replace `packages/rfw_gen/lib/rfw_gen.dart` with:
```dart
export 'src/annotations.dart';
export 'src/errors.dart';
export 'src/rfw_handler.dart';
export 'src/rfw_helpers.dart';
export 'src/rfw_icons.dart';
export 'src/rfw_only_widgets.dart';
```

- [ ] **Step 4: Update rfw_gen_builder barrel export**

Replace `packages/rfw_gen_builder/lib/rfw_gen_builder.dart` with:
```dart
export 'src/rfw_widget_builder.dart';
export 'src/converter.dart';
export 'src/widget_registry.dart';
```

- [ ] **Step 5: Update rfw_widget_builder.dart imports**

In `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`, the existing import `package:rfw_gen/rfw_gen.dart` previously gave access to `WidgetRegistry` and `RfwConverter`. After the move, these are local. Update:
```dart
// FROM:
import 'package:rfw_gen/rfw_gen.dart';
// TO:
import 'package:rfw_gen/rfw_gen.dart';  // annotations, RfwWidget detection
import 'converter.dart';                 // RfwConverter (now local)
import 'widget_registry.dart';           // WidgetRegistry (now local)
```

Note: keep the `package:rfw_gen/rfw_gen.dart` import — it's still needed for `RfwWidget` annotation detection in AST parsing. But `RfwConverter` and `WidgetRegistry` are now local imports.

- [ ] **Step 6: Update rfw_gen/pubspec.yaml**

Remove `analyzer` dependency (no longer needed). Remove `yaml` from dev_dependencies:
```yaml
name: rfw_gen
description: Convert Flutter Widget code to RFW (Remote Flutter Widgets) format.
version: 0.1.0
publish_to: none  # removed in Task 5

environment:
  sdk: ^3.0.0

dependencies:
  rfw: ^1.0.0

dev_dependencies:
  lints: ^5.0.0
  test: ^1.25.0
```

- [ ] **Step 7: Update rfw_gen_builder/pubspec.yaml**

Add `rfw` dependency. Keep path dependency for local/CI use (only switch to version constraint at publish time):
```yaml
name: rfw_gen_builder
description: build_runner generator for rfw_gen.
version: 0.1.0
publish_to: none  # removed in Task 5

environment:
  sdk: ^3.0.0

dependencies:
  analyzer: ^9.0.0
  build: ^4.0.0
  rfw: ^1.0.0
  yaml: ^3.1.0
  rfw_gen:
    path: ../rfw_gen

dev_dependencies:
  build_runner: ^2.4.0
  build_test: ^3.5.0
  lints: ^5.0.0
  test: ^1.25.0
```

Note: The path dependency is kept for local development and CI. The publish.yml workflow will use `--directory` which resolves from pub.dev. At publish time, temporarily change to `rfw_gen: ^0.1.0` or use `dependency_overrides`.

- [ ] **Step 8: Run pub get and verify both packages resolve**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart pub get
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart pub get
```

Expected: Both resolve successfully with no errors.

- [ ] **Step 9: Run dart analyze on both packages**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart analyze
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart analyze
```

Expected: No issues found. This confirms the file moves and import changes are correct.

- [ ] **Step 10: Commit file moves + dependency updates together**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/lib/ packages/rfw_gen_builder/lib/ packages/rfw_gen/pubspec.yaml packages/rfw_gen_builder/pubspec.yaml
git commit -m "refactor: split build-time code into rfw_gen_builder

Move converter, ast_visitor, expression_converter, rfwtxt_emitter, ir,
widget_registry from rfw_gen to rfw_gen_builder. Update barrel exports,
imports, and dependencies."
```

---

## Task 2: Move test files

**Files:**
- Move: 9 test files from `packages/rfw_gen/test/` → `packages/rfw_gen_builder/test/`
- Keep: `annotations_test.dart`, `rfw_only_widgets_test.dart` in rfw_gen

- [ ] **Step 1: Move 9 test files**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
for f in ast_visitor_test.dart expression_converter_test.dart rfwtxt_emitter_test.dart widget_registry_test.dart ir_test.dart converter_test.dart integration_test.dart spec_sync_test.dart rfw_helpers_test.dart; do
  mv packages/rfw_gen/test/$f packages/rfw_gen_builder/test/$f
done
```

- [ ] **Step 2: Update imports in moved test files**

Each test file needs its `package:rfw_gen/rfw_gen.dart` import updated. The rule: if the test uses a class that moved to rfw_gen_builder, change that import.

**Tests that need BOTH imports** (use runtime helpers AND build-time classes):
- `rfw_helpers_test.dart` — tests `DataRef`, `ArgsRef` (runtime) but also tests their conversion via `RfwConverter` (build-time). Change to:
  ```dart
  import 'package:rfw_gen/rfw_gen.dart';              // DataRef, ArgsRef, etc.
  import 'package:rfw_gen_builder/rfw_gen_builder.dart'; // RfwConverter
  ```
- `integration_test.dart` — tests full pipeline using runtime helpers + converter
- `spec_sync_test.dart` — tests registry ↔ converter consistency, references runtime types
- `converter_test.dart` — tests RfwConverter with runtime helper inputs

**Tests that only need builder import** (build-time classes only):
- `ir_test.dart` — only IR classes
- `rfwtxt_emitter_test.dart` — only RfwtxtEmitter + IR
- `widget_registry_test.dart` — only WidgetRegistry
- `ast_visitor_test.dart` — only WidgetAstVisitor + IR
- `expression_converter_test.dart` — only ExpressionConverter + IR

For these, change:
```dart
// FROM:
import 'package:rfw_gen/rfw_gen.dart';
// TO:
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
```

Also check for direct `src/` imports (e.g., `import 'package:rfw_gen/src/ir.dart'`) and update to `package:rfw_gen_builder/src/ir.dart`.

- [ ] **Step 3: Verify rfw_gen tests pass (2 remaining)**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart test
```

Expected: All tests pass (annotations_test + rfw_only_widgets_test).

- [ ] **Step 4: Verify rfw_gen_builder tests pass**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart test
```

Expected: All tests pass (builder_test + 9 moved tests).

- [ ] **Step 5: Commit**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/test/ packages/rfw_gen_builder/test/
git commit -m "refactor: split tests between rfw_gen and rfw_gen_builder"
```

---

## Task 3: Add LICENSE

**Files:**
- Create: `LICENSE` (root)
- Create: `packages/rfw_gen/LICENSE` (copy)
- Create: `packages/rfw_gen_builder/LICENSE` (copy)

- [ ] **Step 1: Create BSD-3-Clause LICENSE at root**

```
BSD 3-Clause License

Copyright (c) 2026, rfw_gen contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

- [ ] **Step 2: Copy to both packages**

```bash
cp LICENSE packages/rfw_gen/LICENSE
cp LICENSE packages/rfw_gen_builder/LICENSE
```

- [ ] **Step 3: Commit**

```bash
git add LICENSE packages/rfw_gen/LICENSE packages/rfw_gen_builder/LICENSE
git commit -m "chore: add BSD-3-Clause LICENSE"
```

---

## Task 4: Update pubspec.yaml metadata

**Files:**
- Modify: `packages/rfw_gen/pubspec.yaml`
- Modify: `packages/rfw_gen_builder/pubspec.yaml`

- [ ] **Step 1: Update rfw_gen/pubspec.yaml**

Remove `publish_to: none`, add pub.dev metadata:
```yaml
name: rfw_gen
description: Convert Flutter Widget code to RFW (Remote Flutter Widgets) format. Annotations and runtime helpers for use with rfw_gen_builder.
version: 0.1.0
homepage: https://github.com/<owner>/rfw_gen
repository: https://github.com/<owner>/rfw_gen
topics:
  - rfw
  - remote-flutter-widgets
  - code-generation

environment:
  sdk: ^3.0.0

dependencies:
  rfw: ^1.0.0

dev_dependencies:
  lints: ^5.0.0
  test: ^1.25.0
```

Note: Replace `<owner>` with actual GitHub username/org.

- [ ] **Step 2: Update rfw_gen_builder/pubspec.yaml**

Remove `publish_to: none`, add metadata. Keep path dependency for development/CI:
```yaml
name: rfw_gen_builder
description: build_runner code generator for rfw_gen. Converts @RfwWidget-annotated Flutter functions to RFW format.
version: 0.1.0
homepage: https://github.com/<owner>/rfw_gen
repository: https://github.com/<owner>/rfw_gen
topics:
  - rfw
  - remote-flutter-widgets
  - code-generation
  - build-runner

environment:
  sdk: ^3.0.0

dependencies:
  analyzer: ^9.0.0
  build: ^4.0.0
  rfw: ^1.0.0
  rfw_gen:
    path: ../rfw_gen
  yaml: ^3.1.0

dev_dependencies:
  build_runner: ^2.4.0
  build_test: ^3.5.0
  lints: ^5.0.0
  test: ^1.25.0
```

Note: Path dependency is kept in the repo. The publish.yml workflow patches this to `rfw_gen: ^0.1.0` at publish time.

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen/pubspec.yaml packages/rfw_gen_builder/pubspec.yaml
git commit -m "chore: add pub.dev metadata, remove publish_to: none"
```

---

## Task 5: Add .pubignore

**Files:**
- Create: `packages/rfw_gen/.pubignore`
- Create: `packages/rfw_gen_builder/.pubignore`

- [ ] **Step 1: Create rfw_gen/.pubignore**

```
docs/
.claude/
.github/
melos.yaml
```

- [ ] **Step 2: Create rfw_gen_builder/.pubignore**

```
docs/
.claude/
.github/
melos.yaml
```

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen/.pubignore packages/rfw_gen_builder/.pubignore
git commit -m "chore: add .pubignore for pub.dev publishing"
```

---

## Task 6: Write README.md for rfw_gen

**Files:**
- Create: `packages/rfw_gen/README.md`

- [ ] **Step 1: Write README.md**

Content sections:
1. Title + badges (pub.dev version, build status)
2. One-paragraph description
3. Installation (dependencies: rfw_gen, dev_dependencies: rfw_gen_builder + build_runner)
4. Quick Start (@RfwWidget example with code block)
5. Supported Widgets (65 total: Core + Material, link to full list)
6. Custom Widgets (rfw_gen.yaml configuration)
7. Dynamic Features (DataRef, ArgsRef, StateRef, RfwFor, RfwSwitch, RfwConcat, RfwHandler)
8. Pre-1.0 note: "This package is pre-1.0. Minor version bumps may include breaking changes."

Language: English. Keep concise — pub.dev README should be scannable.

- [ ] **Step 2: Commit**

```bash
git add packages/rfw_gen/README.md
git commit -m "docs: add rfw_gen README for pub.dev"
```

---

## Task 7: Write README.md for rfw_gen_builder

**Files:**
- Create: `packages/rfw_gen_builder/README.md`

- [ ] **Step 1: Write README.md**

Short README (~30 lines):
1. Title
2. Description: "build_runner code generator for rfw_gen"
3. Installation: `dev_dependencies: rfw_gen_builder: ^0.1.0, build_runner: ^2.4.0`
4. Usage: `dart run build_runner build`
5. Link: "See [rfw_gen](https://pub.dev/packages/rfw_gen) for full documentation."

- [ ] **Step 2: Commit**

```bash
git add packages/rfw_gen_builder/README.md
git commit -m "docs: add rfw_gen_builder README for pub.dev"
```

---

## Task 8: Write CHANGELOG.md for both packages

**Files:**
- Create: `packages/rfw_gen/CHANGELOG.md`
- Create: `packages/rfw_gen_builder/CHANGELOG.md`

- [ ] **Step 1: Create rfw_gen/CHANGELOG.md**

```markdown
## 0.1.0

- Initial release
- Support 65 widgets (Core + Material)
- Custom widget support via `rfw_gen.yaml`
- Dynamic features: `DataRef`, `ArgsRef`, `StateRef`, `RfwFor`, `RfwSwitch`, `RfwConcat`
- Event handlers: `RfwHandler` (`setState`, `setStateFromArg`, `event`)
- RFW-only widget aliases: `SizedBoxExpand`, `SizedBoxShrink`, `Rotation`, `Scale`, `AnimationDefaults`
```

- [ ] **Step 2: Create rfw_gen_builder/CHANGELOG.md**

```markdown
## 0.1.0

- Initial release
- `build_runner` integration for rfw_gen
- Generates `.rfwtxt` (text) and `.rfw` (binary) output
- 65 built-in widget mappings (Core + Material)
- Custom widget support via `rfw_gen.yaml`
```

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen/CHANGELOG.md packages/rfw_gen_builder/CHANGELOG.md
git commit -m "docs: add CHANGELOG.md for both packages"
```

---

## Task 9: Add dartdoc comments to rfw_gen public API

**Files:**
- Modify: `packages/rfw_gen/lib/src/annotations.dart`
- Modify: `packages/rfw_gen/lib/src/rfw_helpers.dart`
- Modify: `packages/rfw_gen/lib/src/rfw_handler.dart`
- Modify: `packages/rfw_gen/lib/src/rfw_icons.dart`
- Modify: `packages/rfw_gen/lib/src/rfw_only_widgets.dart`
- Modify: `packages/rfw_gen/lib/src/errors.dart`

- [ ] **Step 1: Add `///` comments to all public classes, methods, and properties**

Every public member needs a `///` doc comment. Focus on:
- Class-level: what it does, when to use it
- Constructor params: what each param means
- Methods: what they return, any side effects

Check which files already have docs and only add where missing.

- [ ] **Step 2: Run dart analyze to verify no warnings**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart analyze
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen/lib/
git commit -m "docs: add dartdoc comments to rfw_gen public API"
```

---

## Task 10: Add dartdoc comments to rfw_gen_builder public API

**Files:**
- Modify: `packages/rfw_gen_builder/lib/src/converter.dart`
- Modify: `packages/rfw_gen_builder/lib/src/widget_registry.dart`
- Modify: `packages/rfw_gen_builder/lib/src/rfw_widget_builder.dart`
- Modify: `packages/rfw_gen_builder/lib/builder.dart`

- [ ] **Step 1: Add `///` comments to public API**

Focus on `RfwConverter`, `WidgetRegistry`, `RfwWidgetBuilder` — the main public-facing classes. Internal files (ir.dart, ast_visitor.dart, etc.) are not exported and can be skipped.

- [ ] **Step 2: Run dart analyze**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart analyze
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add packages/rfw_gen_builder/lib/
git commit -m "docs: add dartdoc comments to rfw_gen_builder public API"
```

---

## Task 11: Add example/example.dart for rfw_gen

**Files:**
- Create: `packages/rfw_gen/example/example.dart`

- [ ] **Step 1: Create minimal example**

```dart
import 'package:rfw_gen/rfw_gen.dart';

// Annotate a top-level function with @RfwWidget to generate RFW output.
// Run: dart run build_runner build
@RfwWidget('greeting')
Widget buildGreeting() {
  return Container(
    color: Color(0xFF2196F3),
    padding: EdgeInsets.all(16.0),
    child: Text('Hello, RFW!'),
  );
}
```

Note: This file won't compile standalone (no Flutter SDK), but pub.dev displays it as a code sample which is the convention.

- [ ] **Step 2: Commit**

```bash
git add packages/rfw_gen/example/example.dart
git commit -m "docs: add example for pub.dev"
```

---

## Task 12: Set up CI/CD — ci.yml

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create ci.yml**

Note: `rfw_gen_builder` depends on `rfw_gen` via path dependency. CI uses `melos bootstrap` to resolve local dependencies, then runs checks per-package.

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - name: Install melos
        run: dart pub global activate melos
      - name: Bootstrap
        run: melos bootstrap

      - name: Analyze rfw_gen
        run: dart analyze packages/rfw_gen
      - name: Format rfw_gen
        run: dart format --set-exit-if-changed packages/rfw_gen
      - name: Test rfw_gen
        working-directory: packages/rfw_gen
        run: dart test

      - name: Analyze rfw_gen_builder
        run: dart analyze packages/rfw_gen_builder
      - name: Format rfw_gen_builder
        run: dart format --set-exit-if-changed packages/rfw_gen_builder
      - name: Test rfw_gen_builder
        working-directory: packages/rfw_gen_builder
        run: dart test
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add CI workflow for rfw_gen and rfw_gen_builder"
```

---

## Task 13: Set up CI/CD — publish.yml

**Files:**
- Create: `.github/workflows/publish.yml`

- [ ] **Step 1: Create publish.yml**

Note: Before publishing, the workflow patches rfw_gen_builder's pubspec to use a version constraint instead of path dependency. A 60s delay between publishes ensures pub.dev indexes rfw_gen before rfw_gen_builder resolves it.

```yaml
name: Publish to pub.dev

on:
  push:
    tags:
      - 'v*'

jobs:
  publish:
    runs-on: ubuntu-latest
    permissions:
      id-token: write  # Required for OIDC authentication
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1

      - name: Publish rfw_gen
        run: dart pub publish --directory packages/rfw_gen --force

      - name: Wait for pub.dev indexing
        run: sleep 60

      - name: Patch rfw_gen_builder dependency
        run: |
          sed -i 's|rfw_gen:\n    path: ../rfw_gen|rfw_gen: ^0.1.0|' packages/rfw_gen_builder/pubspec.yaml

      - name: Publish rfw_gen_builder
        run: dart pub publish --directory packages/rfw_gen_builder --force
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/publish.yml
git commit -m "ci: add automated pub.dev publish workflow"
```

---

## Task 14: Final validation

- [ ] **Step 1: Run dart pub publish --dry-run for rfw_gen**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart pub publish --dry-run
```

Expected: "Package has 0 warnings." If warnings appear, fix them before proceeding.

- [ ] **Step 2: Run dart pub publish --dry-run for rfw_gen_builder**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart pub publish --dry-run
```

Expected: "Package has 0 warnings."

- [ ] **Step 3: Run all tests one final time**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart test
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart test
```

Expected: All tests pass in both packages.

- [ ] **Step 4: Run dart analyze on both packages**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart analyze
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen_builder && dart analyze
```

Expected: No issues found.

- [ ] **Step 5: Commit any final fixes (if needed)**

```bash
git add packages/rfw_gen/ packages/rfw_gen_builder/
git commit -m "chore: final validation fixes for pub.dev publishing"
```
