import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen/rfw_gen.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

/// Registers the `convert_to_rfwtxt` tool with [server].
void registerConvertToRfwtxtTool(McpServer server, RfwConverter converter) {
  server.registerTool(
    'convert_to_rfwtxt',
    description:
        'Converts Dart source code containing an @RfwWidget function to rfwtxt format.',
    inputSchema: JsonObject(
      required: ['source'],
      properties: {
        'source': JsonString(
          description:
              'Dart source code containing a function annotated with @RfwWidget.',
        ),
      },
    ),
    callback: (Map<String, dynamic> args, RequestHandlerExtra extra) async {
      final result = handleConvertToRfwtxt(converter, args);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

/// Converts Dart source to rfwtxt, returning a JSON string.
///
/// Output on success:
/// ```json
/// { "success": true, "rfwtxt": "...", "warnings": [...] }
/// ```
///
/// Output on failure:
/// ```json
/// { "success": false, "errors": [...], "warnings": [...] }
/// ```
String handleConvertToRfwtxt(
  RfwConverter converter,
  Map<String, dynamic> args,
) {
  final source = args['source'] as String?;
  if (source == null || source.isEmpty) {
    return jsonEncode({
      'success': false,
      'errors': [
        {'message': 'Missing required argument: source'}
      ],
      'warnings': [],
    });
  }

  try {
    final result = converter.convertFromSource(source);

    final warnings = result.issues
        .where((i) => !i.isFatal)
        .map((i) => _issueToMap(i))
        .toList();

    if (result.hasErrors) {
      final errors = result.issues
          .where((i) => i.isFatal)
          .map((i) => _issueToMap(i))
          .toList();
      return jsonEncode({
        'success': false,
        'errors': errors,
        'warnings': warnings,
      });
    }

    return jsonEncode({
      'success': true,
      'rfwtxt': result.rfwtxt,
      'warnings': warnings,
    });
  } on StateError catch (e) {
    return jsonEncode({
      'success': false,
      'errors': [
        {'message': e.message}
      ],
      'warnings': [],
    });
  } catch (e) {
    return jsonEncode({
      'success': false,
      'errors': [
        {'message': e.toString()}
      ],
      'warnings': [],
    });
  }
}

Map<String, dynamic> _issueToMap(RfwGenIssue issue) {
  return {
    'message': issue.message,
    if (issue.line != null) 'line': issue.line,
    if (issue.column != null) 'column': issue.column,
    if (issue.suggestion != null) 'suggestion': issue.suggestion,
  };
}
