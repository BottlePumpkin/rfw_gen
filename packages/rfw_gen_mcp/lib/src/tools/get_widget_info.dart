import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

/// Simple result type for tool handlers.
class ToolResult {
  final String text;
  final bool isError;

  const ToolResult({required this.text, this.isError = false});
}

/// Registers the `get_widget_info` tool with [server].
void registerGetWidgetInfoTool(McpServer server, WidgetRegistry registry) {
  server.registerTool(
    'get_widget_info',
    description:
        'Returns detailed information about a specific RFW widget by name.',
    inputSchema: JsonObject(
      required: ['widget'],
      properties: {
        'widget': JsonString(
          description: 'The Flutter widget class name, e.g. "Container".',
        ),
      },
    ),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleGetWidgetInfo(registry, args);
      return CallToolResult(
        content: [TextContent(text: result.text)],
        isError: result.isError,
      );
    },
  );
}

/// Returns widget detail as a [ToolResult].
///
/// Output on found:
/// ```json
/// { "name": "...", "rfwName": "...", "import": "...", "childType": "...",
///   "params": {...}, "handlerParams": [...],
///   "positionalParam": "..." (if any),
///   "namedChildSlots": {...} (if any) }
/// ```
///
/// Output on not found:
/// ```json
/// { "error": "...", "availableWidgets": [...] }
/// ```
ToolResult handleGetWidgetInfo(
  WidgetRegistry registry,
  Map<String, dynamic> args,
) {
  final widgetName = args['widget'] as String?;
  if (widgetName == null || widgetName.isEmpty) {
    return ToolResult(
      text: jsonEncode({
        'error': 'Missing required argument: widget',
        'availableWidgets': registry.supportedWidgets.keys.toList()..sort(),
      }),
      isError: true,
    );
  }

  final mapping = registry.supportedWidgets[widgetName];
  if (mapping == null) {
    final available = registry.supportedWidgets.keys.toList()..sort();
    return ToolResult(
      text: jsonEncode({
        'error': 'Widget "$widgetName" is not supported.',
        'availableWidgets': available,
      }),
      isError: true,
    );
  }

  final paramsMap = <String, dynamic>{};
  for (final entry in mapping.params.entries) {
    paramsMap[entry.key] = {
      'rfwName': entry.value.rfwName,
      if (entry.value.transformer != null)
        'transformer': entry.value.transformer,
    };
  }

  final info = <String, dynamic>{
    'name': widgetName,
    'rfwName': mapping.rfwName,
    'import': mapping.import,
    'childType': mapping.childType.name,
    'params': paramsMap,
    'handlerParams': mapping.handlerParams.toList()..sort(),
    if (mapping.positionalParam != null)
      'positionalParam': mapping.positionalParam,
    if (mapping.namedChildSlots.isNotEmpty)
      'namedChildSlots': mapping.namedChildSlots,
  };

  return ToolResult(text: jsonEncode(info));
}
