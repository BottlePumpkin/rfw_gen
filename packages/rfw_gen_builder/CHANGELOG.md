## 0.5.1

- Update homepage to GitHub Pages playground

## 0.5.0

- Fix: handle `Icons.xxx` expressions by converting to iconData map (#41)
- Fix: handle `double.infinity` with actionable error message (#41)
- Fix: translate Korean warning/error messages to English (#42)
- Fix: skip `.rfw_library.dart` and `.rfw_meta.json` generation for files without `@RfwWidget` (#42)
- Fix: improve handler error message and document RfwSwitch limitation (#44)

## 0.4.1

- Fix: use `show` directive in generated `.rfw_library.dart` imports to prevent name conflicts with Flutter built-in widgets (#23)
- Fix: improve error message when `DataRef`/`RfwConcat`/`StateRef` used as a widget (#24)
- Fix: clarify "no custom widgets found" message in empty `.rfw_library.dart` (#25)

## 0.4.0

- **Breaking**: Remove `rfw_gen.yaml` support and `yaml` dependency
- Add `WidgetResolver` for Resolver-based custom widget analysis
- Add `LocalWidgetBuilderGenerator` — auto-generates `LocalWidgetBuilder` maps
- Generate `.rfw_library.dart` and `.rfw_meta.json` per source file
- Require `analyzer >=9.0.0` for Resolver API compatibility

## 0.3.0

- No changes (version bump to match rfw_gen_mcp)

## 0.2.2

- No changes (version bump to match rfw_gen_mcp)

## 0.2.1

- Widen `analyzer` constraint from `^9.0.0` to `>=7.4.5 <10.0.0` for Flutter 3.32+ compatibility

## 0.2.0

- **Breaking**: `RfwConverter.convertFromSource()` and `convertFromAst()` now return `ConvertResult` instead of `String`
- Add `IssueCollector` for accumulating conversion errors with line:column info
- Replace silent `developer.log` with build-visible `log.warning`/`log.severe`
- Add suggestion messages for common unsupported patterns (ternary → RfwSwitch, etc.)
- Add `parseLibraryFile()` validation step for generated rfwtxt
- Fix missing offset in 7 `UnsupportedExpressionError` throw sites

## 0.1.0

- Initial release
- `build_runner` integration for rfw_gen
- Generates `.rfwtxt` (text) and `.rfw` (binary) output
- 65 built-in widget mappings (Core + Material)
- Custom widget support via `rfw_gen.yaml` (removed in 0.4.0)
