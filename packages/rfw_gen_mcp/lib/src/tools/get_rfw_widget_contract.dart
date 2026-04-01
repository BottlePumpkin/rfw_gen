import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';

import 'get_widget_info.dart';
import 'list_rfw_widgets.dart';

/// Registers the `get_rfw_widget_contract` tool with [server].
void registerGetRfwWidgetContractTool(McpServer server, RfwWidgetStore store) {
  server.registerTool(
    'get_rfw_widget_contract',
    description: 'Returns the runtime contract (state, dataRefs, events) for a '
        'specific @RfwWidget-declared remote widget.',
    inputSchema: JsonObject(
      required: ['widget'],
      properties: {
        'widget': JsonString(
          description: 'The remote widget name, e.g. "movieDetail".',
        ),
      },
    ),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleGetRfwWidgetContract(store, args);
      return CallToolResult(
        content: [TextContent(text: result.text)],
        isError: result.isError,
      );
    },
  );
}

/// Returns widget contract as a [ToolResult].
ToolResult handleGetRfwWidgetContract(
  RfwWidgetStore store,
  Map<String, dynamic> args,
) {
  final widgetName = args['widget'] as String?;
  if (widgetName == null || widgetName.isEmpty) {
    return ToolResult(
      text: jsonEncode({'error': 'Missing required argument: widget'}),
      isError: true,
    );
  }

  final contract = store.get(widgetName);
  if (contract == null) {
    final available = store.all.keys.toList()..sort();
    return ToolResult(
      text: jsonEncode({
        'error': 'Remote widget "$widgetName" not found.',
        'availableWidgets': available,
      }),
      isError: true,
    );
  }

  return ToolResult(
    text: jsonEncode({
      'name': widgetName,
      'state': contract.state,
      'dataRefs': contract.dataRefs,
      'stateRefs': contract.stateRefs,
      'events': contract.events,
    }),
  );
}
