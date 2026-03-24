import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

import 'tools/convert_to_rfwtxt.dart';
import 'tools/get_widget_info.dart';
import 'tools/list_widgets.dart';
import 'tools/validate_rfwtxt.dart';

Future<void> runRfwGenMcpServer() async {
  final server = McpServer(
    const Implementation(name: 'rfw_gen', version: '0.1.0'),
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
