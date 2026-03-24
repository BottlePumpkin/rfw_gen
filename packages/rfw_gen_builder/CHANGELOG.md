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
- Custom widget support via `rfw_gen.yaml`
