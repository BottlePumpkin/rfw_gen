import 'package:rfw_gen_mcp/rfw_gen_mcp.dart';

/// Example: Start the rfw_gen MCP server.
///
/// The server exposes these tools over stdio:
/// - `list_widgets` — list supported RFW widgets
/// - `get_widget_info` — detailed widget metadata
/// - `convert_to_rfwtxt` — Dart source to rfwtxt conversion
/// - `validate_rfwtxt` — rfwtxt syntax validation
///
/// Usage:
/// ```bash
/// dart pub global activate rfw_gen_mcp
/// rfw_gen_mcp
/// ```
void main() async {
  await runRfwGenMcpServer();
}
