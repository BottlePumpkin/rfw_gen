# Demo App Issue Scan Report — 2026-03-24

## Summary

| Severity | Count |
|----------|-------|
| Critical | 6 |
| High     | 6 |
| Medium   | 8 |
| Low      | 7 |
| **Total** | **27** |

**Scan scope:** 41 catalog widgets + 5 shop screens, 7 core library files, 414 unit tests
**rfwtxt output:** 0 parameter mismatches found (all 41+5 widgets verified)
**Tests:** 414/414 passing, 0 failures
**Binary validation:** parseLibraryFile() PASS for both catalog and shop

**Key insight:** The demo app's current output is correct because it doesn't exercise the discovered code gaps. The gaps are latent — they will surface when users write widgets using Alignment constants, EdgeInsetsDirectional, complex BoxDecoration, etc.

---

## Critical Issues

### C1: Alignment named constants unhandled
- **Source:** `expression_converter.dart:369-393`
- **Impact:** 8+ widgets (Container, Align, FittedBox, FractionallySizedBox, Stack, Image, Rotation, Scale)
- **Evidence:** `_convertPrefixedIdentifier` has no `if (prefix == 'Alignment')` branch. `Alignment.center`, `Alignment.topLeft`, `Alignment.bottomRight` etc. all throw `UnsupportedExpressionError`
- **Suggested Fix:** Add Alignment named constant mapping: `center` → `{x: 0.0, y: 0.0}`, `topLeft` → `{x: -1.0, y: -1.0}`, etc.

### C2: AlignmentDirectional completely unhandled
- **Source:** `expression_converter.dart` (no mention anywhere)
- **Impact:** RFW supports `{start: double, y: double}` per rfw-types.md
- **Evidence:** No `AlignmentDirectional` handling in any code path
- **Suggested Fix:** Add converter for `AlignmentDirectional` constants and constructors

### C3: EdgeInsetsDirectional completely unhandled
- **Source:** `expression_converter.dart:115-117, 255-261`
- **Impact:** `EdgeInsetsDirectional.only()`, `.fromSTEB()` throw
- **Evidence:** `_isKnownClassName` only contains `EdgeInsets`, `BorderRadius`, `Radius`
- **Suggested Fix:** Add `EdgeInsetsDirectional` to known classes, add converter methods

### C4: BoxDecoration.shape silent drop
- **Source:** `expression_converter.dart:653-658`
- **Impact:** `shape:` silently ignored when not a PrefixedIdentifier
- **Evidence:** `case 'shape': if (arg.expression is PrefixedIdentifier) { ... }` — no else clause
- **Suggested Fix:** Add else clause with warning or error

### C5: Gradient colors/stops/boxShadow silent drop
- **Source:** `expression_converter.dart:647-651, 708-719, 745-750`
- **Impact:** `colors:`, `stops:`, `boxShadow:` silently dropped when not direct ListLiteral
- **Evidence:** Multiple `if (arg.expression is ListLiteral)` guards with no else
- **Suggested Fix:** Add else clauses that throw or warn

### C6: childList silently drops non-ListLiteral children
- **Source:** `ast_visitor.dart:217-224`
- **Impact:** Column, Row, ListView, Stack, Wrap, GridView — all children vanish if `children:` is not a direct list literal
- **Evidence:** `if (expression is ListLiteral) { ... }` with no else clause
- **Suggested Fix:** Add else clause with error/warning

---

## High Issues

### H1: TextStyle silently ignores unknown properties
- **Source:** `expression_converter.dart:560-603`
- **Impact:** `backgroundColor`, `shadows`, `textBaseline` etc. silently vanish
- **Evidence:** Switch has no `default` case — unrecognized properties fall through silently
- **Suggested Fix:** Add default case with developer.log warning

### H2: IconThemeData silently ignores unknown properties
- **Source:** `expression_converter.dart:680-695`
- **Impact:** Properties beyond `color`, `size`, `opacity` silently dropped
- **Evidence:** Switch only handles 3 properties, no default
- **Suggested Fix:** Add default case with warning

### H3: Missing onEnd handler for animated widgets
- **Source:** `widget_registry.dart` (Container, Align, Opacity, Padding, DefaultTextStyle, Positioned, Rotation, Scale)
- **Impact:** `onEnd` handler not available despite RFW runtime support
- **Evidence:** All animated widget entries have empty `handlerParams`
- **Suggested Fix:** Add `onEnd` to handlerParams for all animated widgets

### H4: Column/Row missing textBaseline param
- **Source:** `widget_registry.dart:211-240`
- **Impact:** `textBaseline: TextBaseline.alphabetic` passed without transformer
- **Evidence:** No `textBaseline` entry in Column/Row param maps
- **Suggested Fix:** Add textBaseline with enum transformer

### H5: PrefixExpression only handles `-`
- **Source:** `expression_converter.dart:74-88`
- **Impact:** `!boolValue` throws
- **Evidence:** Only checks `expr.operator.lexeme == '-'`
- **Suggested Fix:** Add `!` operator handling

### H6: SetOrMapLiteral always treated as map
- **Source:** `expression_converter.dart:860-869`
- **Impact:** Set literals `{1, 2, 3}` produce empty map
- **Evidence:** Only processes `MapLiteralEntry` elements, ignores others
- **Suggested Fix:** Add Set literal detection and handling

---

## Medium Issues

### M1: Duration only supports milliseconds parameter
- **Source:** `expression_converter.dart:410-423`
- **Impact:** `Duration(seconds: 1)` throws
- **Suggested Fix:** Add seconds/minutes conversion to milliseconds

### M2: SweepGradient not handled
- **Source:** `expression_converter.dart` (absent)
- **Impact:** RFW supports `type: "sweep"` but no converter exists
- **Suggested Fix:** Add SweepGradient converter

### M3: BoxBorder/Border/BorderSide/ShapeBorder not handled
- **Source:** `expression_converter.dart`
- **Impact:** BoxDecoration `border` property cannot be converted
- **Suggested Fix:** Add Border/BorderSide converters

### M4: Container missing foregroundDecoration, constraints, transform, clipBehavior in registry
- **Source:** `widget_registry.dart:393-408`
- **Impact:** These params registered in RFW but not in widget_registry
- **Suggested Fix:** Add missing params with appropriate transformers

### M5: _convertMapLiteral assumes string keys
- **Source:** `expression_converter.dart:860-869`
- **Impact:** Non-string map keys crash with cast error
- **Suggested Fix:** Add type check before cast

### M6: VisualDensity type not handled
- **Source:** `expression_converter.dart` / `widget_registry.dart`
- **Impact:** RFW supports VisualDensity but no handling exists

### M7: Unused import in app_test.dart
- **Source:** `example/test/app_test.dart:1:8`
- **Impact:** `package:flutter/material.dart` imported but unused

### M8: Unused import in compile_rfw.dart
- **Source:** `example/tool/compile_rfw.dart:2:8`
- **Impact:** `dart:typed_data` imported but unused

---

## Low Issues

### L1: Color only supports single integer constructor
- `Color.fromARGB()`, `Color.fromRGBO()` throw

### L2: NaN/Infinity not guarded in rfwtxt_emitter
- Special float values would produce invalid rfwtxt

### L3: Integer hex encoding for small values (cosmetic)
- `flex: 2` → `0x00000002` — valid but unusual

### L4: 32-bit integer mask in emitter
- Large integers truncated (unlikely in practice)

### L5: Limited icon set (50/2000+)
- Users needing unlisted icons must use raw codepoints

### L6: LoopVar only supports string index
- `item[0]` integer index not supported

### L7: analysis_options include_file_not_found
- `package:lints/recommended.yaml` resolution issue

---

## Category Coverage

| Category | Widgets | Params Verified | Missing Params | Output Issues |
|----------|---------|-----------------|----------------|---------------|
| Layout | 9 | ~45 | 0 | 0 |
| Scrolling | 4 | ~15 | 0 | 0 |
| Styling | 11 | ~60 | 0 | 0 |
| Transform | 3 | ~12 | 0 | 0 |
| Interaction | 2 | ~10 | 0 | 0 |
| Material | 9 | ~40 | 0 | 0 |
| Other | 3 | ~12 | 0 | 0 |
| **Total** | **41** | **~194** | **0** | **0** |

| Shop Screen | Params Verified | Data Bindings | Events | Issues |
|-------------|-----------------|---------------|--------|--------|
| Home | verified | correct | correct | 0 |
| Product List | verified | correct | correct | 0 |
| Product Detail | verified | correct | correct | 0 |
| Cart | verified | correct | correct | 0 |
| Order Complete | verified | correct | correct | 0 |

---

## Pending Manual Checks

The following require manual execution (sandbox limitation):

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter analyze
flutter build apk --debug
flutter test
```
