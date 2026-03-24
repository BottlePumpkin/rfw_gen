import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

/// Registers the `list_widgets` tool with [server].
void registerListWidgetsTool(McpServer server, WidgetRegistry registry) {
  server.registerTool(
    'list_widgets',
    description:
        'Lists all supported RFW widgets, optionally filtered by import category.',
    inputSchema: JsonObject(
      properties: {
        'category': JsonString(
          description:
              'Optional import category filter, e.g. "core.widgets" or "material".',
        ),
      },
    ),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleListWidgets(registry, args);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

/// Returns JSON-encoded list of widgets, optionally filtered by [args]['category'].
///
/// Output shape:
/// ```json
/// { "widgets": [...], "count": N }
/// ```
String handleListWidgets(WidgetRegistry registry, Map<String, dynamic> args) {
  final category = args['category'] as String?;

  final entries = registry.supportedWidgets.entries.where((e) {
    if (category == null || category.isEmpty) return true;
    return e.value.import == category;
  });

  final widgets = entries.map((e) {
    final m = e.value;
    return {
      'name': e.key,
      'rfwName': m.rfwName,
      'import': m.import,
      'childType': m.childType.name,
      'paramCount': m.params.length,
    };
  }).toList();

  return jsonEncode({'widgets': widgets, 'count': widgets.length});
}
