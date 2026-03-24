import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw/formats.dart';

/// Registers the `validate_rfwtxt` tool with [server].
void registerValidateRfwtxtTool(McpServer server) {
  server.registerTool(
    'validate_rfwtxt',
    description:
        'Validates rfwtxt source by parsing it with the rfw library and reports widget count and imports.',
    inputSchema: JsonObject(
      required: ['rfwtxt'],
      properties: {
        'rfwtxt': JsonString(
          description: 'The rfwtxt source string to validate.',
        ),
      },
    ),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleValidateRfwtxt(args);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

/// Validates rfwtxt source, returning a JSON string.
///
/// Output on valid:
/// ```json
/// { "valid": true, "widgetCount": N, "imports": [...] }
/// ```
///
/// Output on invalid:
/// ```json
/// { "valid": false, "error": "..." }
/// ```
String handleValidateRfwtxt(Map<String, dynamic> args) {
  final rfwtxt = args['rfwtxt'] as String?;
  if (rfwtxt == null || rfwtxt.isEmpty) {
    return jsonEncode({
      'valid': false,
      'error': 'Empty or missing rfwtxt input.',
    });
  }

  try {
    final library = parseLibraryFile(rfwtxt);
    final imports =
        library.imports.map((imp) => imp.name.parts.join('.')).toList();
    return jsonEncode({
      'valid': true,
      'widgetCount': library.widgets.length,
      'imports': imports,
    });
  } catch (e) {
    return jsonEncode({
      'valid': false,
      'error': e.toString(),
    });
  }
}
