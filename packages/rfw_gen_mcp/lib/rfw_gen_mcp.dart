/// MCP server for rfw_gen — exposes widget registry, code conversion,
/// and rfwtxt validation as tools for AI agents and IDE integrations.
///
/// ## Quick start
///
/// ```bash
/// dart pub global activate rfw_gen_mcp
/// rfw_gen_mcp
/// ```
///
/// See the [README](https://pub.dev/packages/rfw_gen_mcp) for
/// Claude Code and Cursor configuration.
library;

export 'src/server.dart' show runRfwGenMcpServer;
