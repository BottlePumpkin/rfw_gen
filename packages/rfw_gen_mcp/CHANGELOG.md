## 0.5.0

- No changes (version bump to match rfw_gen ecosystem)

## 0.4.1

- No changes (version bump to match rfw_gen_builder)

## 0.4.0

- **Breaking**: Read `.rfw_meta.json` instead of `rfw_gen.yaml` for custom widget metadata

## 0.3.0

- Auto-load `rfw_gen.yaml` from cwd to register custom widgets in MCP server

## 0.2.2

- Support `dart pub global activate` for use in external projects
- Add `analysis_options.yaml` with `package:lints/recommended.yaml`
- Add dartdoc comments on public API
- Simplify MCP client configuration (just `"command": "rfw_gen_mcp"`)

## 0.2.1

- Initial release (version aligned with rfw_gen/rfw_gen_builder)
- MCP server exposing 4 tools via `mcp_dart`:
  - `list_widgets` — list supported RFW widgets with optional category filter
  - `get_widget_info` — get detailed widget info (params, children, handlers)
  - `convert_to_rfwtxt` — convert Dart source with @RfwWidget to rfwtxt
  - `validate_rfwtxt` — validate rfwtxt syntax
- stdio transport for Claude Code, Cursor, and other MCP clients
