import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

import 'tools/convert_to_rfwtxt.dart';
import 'tools/get_widget_info.dart';
import 'tools/list_widgets.dart';
import 'tools/validate_rfwtxt.dart';

/// Starts the rfw_gen MCP server on stdio transport.
///
/// Registers the following tools:
/// - `list_widgets` — list supported RFW widgets
/// - `get_widget_info` — detailed widget metadata
/// - `convert_to_rfwtxt` — Dart source to rfwtxt conversion
/// - `validate_rfwtxt` — rfwtxt syntax validation
Future<void> runRfwGenMcpServer() async {
  final server = McpServer(
    const Implementation(name: 'rfw_gen', version: '0.2.2'),
    options: const McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  final registry = WidgetRegistry.core();
  final converter = RfwConverter(registry: registry);

  registerListWidgetsTool(server, registry);
  registerGetWidgetInfoTool(server, registry);
  registerConvertToRfwtxtTool(server, converter);
  registerValidateRfwtxtTool(server);

  server.connect(StdioServerTransport());
}
