import 'dart:io';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:yaml/yaml.dart';

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
///
/// Automatically loads `rfw_gen.yaml` from the current working directory
/// if present, registering custom widgets into the registry.
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
  _loadCustomWidgets(registry);
  final converter = RfwConverter(registry: registry);

  registerListWidgetsTool(server, registry);
  registerGetWidgetInfoTool(server, registry);
  registerConvertToRfwtxtTool(server, converter);
  registerValidateRfwtxtTool(server);

  server.connect(StdioServerTransport());
}

/// Loads custom widgets from `rfw_gen.yaml` in the current working directory.
void _loadCustomWidgets(WidgetRegistry registry) {
  final configFile = File('rfw_gen.yaml');
  if (!configFile.existsSync()) return;

  try {
    final yamlContent = configFile.readAsStringSync();
    final yaml = loadYaml(yamlContent);
    if (yaml is! YamlMap) return;

    final widgets = yaml['widgets'];
    if (widgets is! YamlMap) return;

    final widgetsConfig = <String, dynamic>{};
    for (final entry in widgets.entries) {
      final key = entry.key.toString();
      if (entry.value is YamlMap) {
        widgetsConfig[key] = Map<String, dynamic>.from(entry.value as YamlMap);
      } else {
        widgetsConfig[key] = <String, dynamic>{};
      }
    }

    registry.registerFromConfig(widgetsConfig);
  } catch (_) {
    // Silently ignore config errors — fall back to core widgets only
  }
}
