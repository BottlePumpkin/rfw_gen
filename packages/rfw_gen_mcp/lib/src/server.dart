import 'dart:convert';
import 'dart:io';

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
///
/// Automatically searches for `.rfw_meta.json` files in the current working
/// directory and `lib/` subdirectories. If found, custom widgets are registered
/// into the registry.
Future<void> runRfwGenMcpServer() async {
  final server = McpServer(
    const Implementation(name: 'rfw_gen', version: '0.4.0'),
    options: const McpServerOptions(
      capabilities: ServerCapabilities(
        tools: ServerCapabilitiesTools(),
      ),
    ),
  );

  final registry = WidgetRegistry.core();
  _loadCustomWidgetsFromMeta(registry);
  final converter = RfwConverter(registry: registry);

  registerListWidgetsTool(server, registry);
  registerGetWidgetInfoTool(server, registry);
  registerConvertToRfwtxtTool(server, converter);
  registerValidateRfwtxtTool(server);

  server.connect(StdioServerTransport());
}

/// Searches for `.rfw_meta.json` files in the current directory and `lib/`
/// subdirectories, then registers custom widgets into the [registry].
///
/// Falls back to core widgets only if no meta files are found.
void _loadCustomWidgetsFromMeta(WidgetRegistry registry) {
  final metaFiles = <File>[];

  // Check current directory for .rfw_meta.json files.
  final currentDir = Directory.current;
  for (final entity in currentDir.listSync()) {
    if (entity is File && entity.path.endsWith('.rfw_meta.json')) {
      metaFiles.add(entity);
    }
  }

  // Recursively search lib/ subdirectories.
  final libDir = Directory('${currentDir.path}/lib');
  if (libDir.existsSync()) {
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.rfw_meta.json')) {
        metaFiles.add(entity);
      }
    }
  }

  if (metaFiles.isEmpty) return;

  for (final file in metaFiles) {
    try {
      final content = file.readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final widgets = json['widgets'] as Map<String, dynamic>?;
      if (widgets == null) continue;

      for (final entry in widgets.entries) {
        final name = entry.key;
        final config = entry.value as Map<String, dynamic>;

        final importName = config['import'] as String? ?? '';
        final childTypeStr = config['childType'] as String? ?? 'none';
        final handlers = (config['handlers'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toSet() ??
            const <String>{};
        final params = <String, ParamMapping>{};
        final paramsList = config['params'] as List<dynamic>?;
        if (paramsList != null) {
          for (final p in paramsList) {
            final paramMap = p as Map<String, dynamic>;
            final paramName = paramMap['name'] as String;
            params[paramName] = ParamMapping.direct(paramName);
          }
        }

        final childType = _parseChildType(childTypeStr);
        final childParam = switch (childType) {
          ChildType.child || ChildType.optionalChild => 'child',
          ChildType.childList => 'children',
          _ => null,
        };

        registry.register(
          name,
          WidgetMapping(
            rfwName: name,
            params: params,
            import: importName,
            childType: childType,
            childParam: childParam,
            handlerParams: handlers,
          ),
        );
      }
    } catch (e) {
      stderr.writeln('[rfw_gen_mcp] Warning: Failed to load ${file.path}: $e');
    }
  }
}

ChildType _parseChildType(String value) {
  return switch (value) {
    'child' => ChildType.child,
    'optionalChild' => ChildType.optionalChild,
    'childList' => ChildType.childList,
    'namedSlots' => ChildType.namedSlots,
    _ => ChildType.none,
  };
}
