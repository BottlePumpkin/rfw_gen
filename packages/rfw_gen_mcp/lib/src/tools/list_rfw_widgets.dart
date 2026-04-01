import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

/// Runtime contract for an @RfwWidget-declared remote widget.
class RfwWidgetContract {
  final Map<String, dynamic>? state;
  final List<String> dataRefs;
  final List<String> stateRefs;
  final List<String> events;

  const RfwWidgetContract({
    this.state,
    this.dataRefs = const [],
    this.stateRefs = const [],
    this.events = const [],
  });
}

/// In-memory store for remote widget contracts loaded from .rfw_meta.json.
class RfwWidgetStore {
  final _widgets = <String, RfwWidgetContract>{};

  void register(String name, RfwWidgetContract contract) {
    _widgets[name] = contract;
  }

  RfwWidgetContract? get(String name) => _widgets[name];

  Map<String, RfwWidgetContract> get all => Map.unmodifiable(_widgets);
}

/// Registers the `list_rfw_widgets` tool with [server].
void registerListRfwWidgetsTool(McpServer server, RfwWidgetStore store) {
  server.registerTool(
    'list_rfw_widgets',
    description: 'Lists all @RfwWidget-declared remote widgets in the project.',
    inputSchema: JsonObject(properties: {}),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleListRfwWidgets(store, args);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

/// Returns JSON-encoded list of remote widgets.
String handleListRfwWidgets(RfwWidgetStore store, Map<String, dynamic> args) {
  final widgets = store.all.entries.map((e) {
    return {
      'name': e.key,
      'hasState': e.value.state != null,
      'dataRefCount': e.value.dataRefs.length,
      'eventCount': e.value.events.length,
    };
  }).toList();

  return jsonEncode({'widgets': widgets, 'count': widgets.length});
}
