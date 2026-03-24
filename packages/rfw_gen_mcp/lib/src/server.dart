import 'package:mcp_dart/mcp_dart.dart';

Future<void> runRfwGenMcpServer() async {
  final server = McpServer(
    const Implementation(name: 'rfw_gen', version: '0.1.0'),
    options: const McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  server.connect(StdioServerTransport());
}
