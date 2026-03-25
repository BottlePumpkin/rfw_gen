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
