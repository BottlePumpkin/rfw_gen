# Demo App Issue Scan Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Systematically find all remaining issues in the rfw_gen demo app (Catalog 56 widgets + Shop 5 screens) across code, output, and build layers.

**Architecture:** 3-layer parallel scan — (1) code gap analysis of converter/visitor/emitter, (2) rfwtxt output + binary verification, (3) build & static analysis — followed by integrated report aggregation.

**Tech Stack:** Dart, Flutter, rfw package (`parseLibraryFile`), dart analyze, flutter analyze

**Spec:** `docs/superpowers/specs/2026-03-24-demo-app-issue-scan-design.md`

---

## File Map

All scan targets (read-only analysis, no modifications until report approval):

**Layer 1 — Core library** (`packages/rfw_gen/lib/src/`):
- `expression_converter.dart` (971 lines) — Expression type handling, silent drops
- `ast_visitor.dart` (344 lines) — AST traversal, catch blocks
- `widget_registry.dart` (931 lines) — Widget param definitions
- `rfwtxt_emitter.dart` (237 lines) — IR → rfwtxt serialization
- `rfw_icons.dart` (104 lines) — Icon utilities
- `rfw_helpers.dart` (78 lines) — Type encoding utilities
- `ir.dart` (124 lines) — IR node type definitions (reference for emitter analysis)

**Excluded** (no conversion logic):
- `converter.dart` (165 lines) — Orchestrator only, calls visitor → emitter → blob
- `rfw_handler.dart` (53 lines) — Event handler mapping only

**Layer 2 — Demo app source ↔ output**:
- `example/lib/catalog/catalog_widgets.dart` (771 lines) — Original Flutter code
- `example/lib/catalog/catalog_widgets.rfwtxt` — Conversion output
- `example/lib/ecommerce/shop_widgets.dart` (440 lines) — Original Flutter code
- `example/lib/ecommerce/shop_widgets.rfwtxt` — Conversion output
- `example/assets/catalog_widgets.rfw` (21K binary) — Binary output
- `example/assets/shop_widgets.rfw` (11K binary) — Binary output

**Layer 3 — Build scope**:
- `example/` — Demo app
- `packages/rfw_gen/` — Core library

**Report output** (to create):
- `docs/superpowers/reports/2026-03-24-demo-app-issue-scan-report.md`

---

### Task 1: Layer 1 — Code Gap Analysis (expression_converter.dart)

**Files:**
- Read: `packages/rfw_gen/lib/src/expression_converter.dart` (971 lines)
- Read: `packages/rfw_gen/test/expression_converter_test.dart` (1,032 lines) — for coverage context

This is the highest-priority file. The recent `InstanceCreationExpression` bug lived here.

- [ ] **Step 1: Map all Expression type handling**

Read `expression_converter.dart` and document every Expression subtype that has explicit handling (e.g., `MethodInvocation`, `InstanceCreationExpression`, `PrefixedIdentifier`, `StringLiteral`, `IntegerLiteral`, `DoubleLiteral`, `BooleanLiteral`, `ListLiteral`, `SetOrMapLiteral`, `ConditionalExpression`, `BinaryExpression`, `IndexExpression`, `PropertyAccess`, `SimpleIdentifier`, `NullLiteral`, `ParenthesizedExpression`, `PrefixExpression`, `FunctionExpressionInvocation`, `NamedExpression`, `InterpolationExpression`).

For each, note:
- Is it handled? (yes/no)
- If yes, does the handler cover all sub-cases?
- If no, what happens? (silent drop / error / fallback)

- [ ] **Step 2: Find silent drop patterns**

Search for:
- `default:` or `else` branches that return empty string, null, or empty map without logging
- `catch` blocks that swallow errors (return `''`, return `{}`, return `null`)
- Functions that can return empty results without warning
- `// TODO`, `// FIXME`, `// HACK` comments

- [ ] **Step 3: Cross-reference with widget_registry param types**

Read `widget_registry.dart`. Parameter types are registered in widget param maps as string keys (e.g., `'color'`, `'padding'`, `'decoration'`). Each widget's entry maps param names to their expected types and how they should be converted. Look for the registry map structure to extract all unique value types (Color, EdgeInsets, TextStyle, BoxDecoration, Alignment, Duration, Curve, IconData, ImageProvider, BorderRadius, BoxShadow, Gradient, ShapeBorder, etc.).

In `expression_converter.dart`, converters are dispatched based on the constructor/method name of the Dart expression (e.g., `Color(...)` → `_convertColor()`, `EdgeInsets.all(...)` → `_convertEdgeInsets()`). Check each unique type from widget_registry has a matching converter function. Flag any types registered but not convertible.

- [ ] **Step 4: Document findings for expression_converter**

Create a findings list in this format:
```
[CRITICAL/HIGH/MEDIUM/LOW] <description>
  - File: expression_converter.dart:<line>
  - Impact: <which widgets affected>
  - Evidence: <code snippet or pattern>
```

---

### Task 2: Layer 1 — Code Gap Analysis (ast_visitor.dart, rfwtxt_emitter.dart, rfw_icons.dart)

**Files:**
- Read: `packages/rfw_gen/lib/src/ast_visitor.dart` (344 lines)
- Read: `packages/rfw_gen/lib/src/rfwtxt_emitter.dart` (237 lines)
- Read: `packages/rfw_gen/lib/src/rfw_icons.dart` (104 lines)
- Read: `packages/rfw_gen/lib/src/rfw_helpers.dart` (78 lines)

- [ ] **Step 1: Analyze ast_visitor.dart**

Search for:
- `catch` blocks — are any silently swallowing errors? (Recent fix replaced silent catches with `developer.log`)
- `visitMethodDeclaration`, `visitFunctionDeclaration` — are all widget parameter extraction paths covered?
- Conditions where widget params get skipped (e.g., unrecognized annotation, unexpected AST structure)

- [ ] **Step 2: Analyze rfwtxt_emitter.dart**

IR node types are defined in `packages/rfw_gen/lib/src/ir.dart` (124 lines). Read it first to get the full list of IR classes (e.g., `RfwWidget`, `RfwParam`, `RfwExpression`, etc.).

Then search `rfwtxt_emitter.dart` for:
- Type-specific emission logic — does it handle all IR node types from `ir.dart`?
- Are there IR types that get serialized as empty/default values?
- String escaping or encoding edge cases

- [ ] **Step 3: Analyze rfw_icons.dart and rfw_helpers.dart**

- `rfw_icons.dart`: Is the icon mapping complete? Are there MaterialIcons codepoints that could be wrong?
- `rfw_helpers.dart`: Are type encoding utility functions handling all edge cases (e.g., negative numbers, very large numbers, special float values)?

- [ ] **Step 4: Document findings for supporting files**

Same format as Task 1 Step 4.

---

### Task 3: Layer 2 — rfwtxt Output Verification (Catalog)

**Files:**
- Read: `example/lib/catalog/catalog_widgets.dart` (771 lines) — source of truth
- Read: `example/lib/catalog/catalog_widgets.rfwtxt` — conversion output

- [ ] **Step 1: Extract explicit parameters from catalog source**

There are 56 `@RfwWidget`-annotated top-level functions in `catalog_widgets.dart`. The annotation pattern is: `@RfwWidget('widgetName')` on a function that returns a Widget. Verify you find all 56.

For each `@RfwWidget` function, list every explicitly set parameter. Example:
```
containerDemo:
  - color: Color(0xFF1565C0)
  - padding: EdgeInsets.all(16)
  - width: 200.0
  - height: 100.0
  - decoration: BoxDecoration(...)
```

- [ ] **Step 2: Verify each parameter exists in rfwtxt output**

For each widget, find the corresponding `widget` block in `catalog_widgets.rfwtxt` and check:
- Does each source parameter appear in the output?
- Is the value correctly encoded? (Color → `0xFF...`, EdgeInsets → `[...]`, etc.)
- Flag any parameter present in source but missing in output

- [ ] **Step 3: Scan for suspicious patterns in rfwtxt**

Search `catalog_widgets.rfwtxt` for:
- Empty maps `{}`
- Bare widget names with no params (when source had params)
- `null` values
- Nested structures that should be flat (like the Icon/Image bug)

- [ ] **Step 4: Summarize catalog findings by category**

Group findings by widget category (Layout, Scrolling, Styling, Transform, Interaction, Material, Other) with counts.

---

### Task 4: Layer 2 — rfwtxt Output Verification (Shop) + Binary Validation

**Files:**
- Read: `example/lib/ecommerce/shop_widgets.dart` (440 lines)
- Read: `example/lib/ecommerce/shop_widgets.rfwtxt`
- Read: `example/assets/catalog_widgets.rfw` (binary)
- Read: `example/assets/shop_widgets.rfw` (binary)
- Read: `example/test/catalog_conversion_test.dart` (14 lines)
- Read: `example/test/shop_conversion_test.dart` (14 lines)

- [ ] **Step 1: Verify shop_widgets.dart ↔ shop_widgets.rfwtxt**

Same verification process as Task 3 Steps 1-3, but for the 5 e-commerce screens (home, list, detail, cart, complete).

Pay special attention to:
- Data binding expressions (`data.products`, `args.product`) — are they correctly converted to RFW data references?
- List rendering (`RfwFor`) — are loop variables properly scoped?
- Event handlers — are `event` calls correctly structured?

- [ ] **Step 2: Run existing conversion tests**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter test test/catalog_conversion_test.dart test/shop_conversion_test.dart -v
```

Check if these tests actually validate conversion correctness (they may be placeholder tests at 14 lines each).

- [ ] **Step 3: Validate .rfw binary files with parseLibraryFile()**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
dart run tool/compile_rfw.dart --validate
```

If no validation tool exists, run the existing integration test:
```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
dart test packages/rfw_gen/test/integration_test.dart -v
```

**Interpretation:** `parseLibraryFile()` throws a `ParserException` on invalid rfwtxt. If it returns without error, the binary is structurally valid. Test failures will show the specific parse error and location. Silent success = pass.

- [ ] **Step 4: Document shop + binary findings**

Same format as previous tasks.

---

### Task 5: Layer 3 — Build & Static Analysis

**Files:**
- Scope: `example/`, `packages/rfw_gen/`

- [ ] **Step 1: Run dart analyze on core library**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
dart analyze packages/rfw_gen/
```

Capture all info, warning, error level findings.

- [ ] **Step 2: Run flutter analyze on demo app**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter analyze
```

Capture all findings.

- [ ] **Step 2.5: Run flutter build to check compilation**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter build apk --debug
```

This catches compilation errors that `flutter analyze` may miss (e.g., asset loading failures, missing dependencies at build time). Capture any build errors.

- [ ] **Step 3: Run full test suite**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
melos exec -- dart test
```

Or if melos is not set up:
```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/packages/rfw_gen && dart test
cd /Users/byeonghopark-jobis/dev/rfw_gen/example && flutter test
```

Capture any test failures.

- [ ] **Step 4: Document build & analysis findings**

List all warnings/errors with severity classification.

---

### Task 6: Integrated Report

**Files:**
- Create: `docs/superpowers/reports/2026-03-24-demo-app-issue-scan-report.md`

- [ ] **Step 1: Aggregate all findings from Tasks 1-5**

Combine all findings into a single report organized by severity:

```markdown
# Demo App Issue Scan Report — 2026-03-24

## Summary
- Critical: N issues
- High: N issues
- Medium: N issues
- Low: N issues

## Critical Issues
### C1: [description]
- **Source:** [file:line]
- **Impact:** [affected widgets]
- **Evidence:** [code/output snippet]
- **Suggested Fix:** [brief description]

## High Issues
...

## Medium Issues
...

## Low Issues
...

## Category Coverage
| Category | Widgets | Params Verified | Issues Found |
|----------|---------|-----------------|--------------|
| Layout   | 9       | ...             | ...          |
| ...      | ...     | ...             | ...          |
```

- [ ] **Step 2: Commit the report**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
mkdir -p docs/superpowers/reports
git add docs/superpowers/reports/2026-03-24-demo-app-issue-scan-report.md
git commit -m "docs: add demo app issue scan report"
```

- [ ] **Step 3: Present report to user for review**

Show the summary section and ask for approval on which issues to fix and in what order.

---

## Execution Notes

**Parallelization:** Tasks 1-2 (code analysis) can run in parallel with Tasks 3-4 (output verification) and Task 5 (build analysis). Task 6 depends on all others completing first.

**Parallel groups:**
- Group A: Task 1 + Task 2 (code gap analysis)
- Group B: Task 3 + Task 4 (rfwtxt + binary verification)
- Group C: Task 5 (build & static analysis)
- Sequential: Task 6 (after A + B + C complete)

**Important:** This plan is a READ-ONLY scan. No code modifications until the report is approved. The fix phase will be planned separately based on findings.
