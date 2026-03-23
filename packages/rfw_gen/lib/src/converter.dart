import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw/formats.dart';

import 'ast_visitor.dart';
import 'expression_converter.dart';
import 'rfwtxt_emitter.dart';
import 'widget_registry.dart';

/// Complete conversion pipeline: Dart source -> rfwtxt -> binary blob.
///
/// Ties together [WidgetAstVisitor] and [RfwtxtEmitter] into a single
/// entry point for both build_runner and MCP usage.
class RfwConverter {
  final WidgetRegistry registry;

  RfwConverter({required this.registry});

  /// Converts a Dart source string containing a widget-building function
  /// to an rfwtxt string.
  ///
  /// Parses the source, finds the first [FunctionDeclaration], and
  /// delegates to [convertFromAst].
  ///
  /// Throws [StateError] if no [FunctionDeclaration] is found.
  String convertFromSource(String dartSource) {
    final parseResult = parseString(content: dartSource);
    final unit = parseResult.unit;

    FunctionDeclaration? function;
    for (final declaration in unit.declarations) {
      if (declaration is FunctionDeclaration) {
        function = declaration;
        break;
      }
    }

    if (function == null) {
      throw StateError('No FunctionDeclaration found in source');
    }

    return convertFromAst(function);
  }

  /// Converts a parsed [FunctionDeclaration] AST node to an rfwtxt string.
  ///
  /// Extracts the widget name from an `@RfwWidget('name')` annotation or
  /// falls back to deriving it from the function name. Then uses
  /// [WidgetAstVisitor] to extract the IR widget tree and [RfwtxtEmitter]
  /// to emit the rfwtxt output.
  String convertFromAst(FunctionDeclaration function) {
    final widgetName = _extractWidgetName(function);

    final visitor = WidgetAstVisitor(
      registry: registry,
      expressionConverter: ExpressionConverter(),
    );
    final irTree = visitor.extractWidgetTree(function);

    final emitter = RfwtxtEmitter();
    return emitter.emit(
      widgetName: widgetName,
      root: irTree,
      imports: {'core.widgets'},
    );
  }

  /// Converts an rfwtxt string to an RFW binary blob.
  ///
  /// Uses `parseLibraryFile` and `encodeLibraryBlob` from `package:rfw`.
  Uint8List toBlob(String rfwtxt) {
    final library = parseLibraryFile(rfwtxt);
    return encodeLibraryBlob(library);
  }

  /// Extracts the widget name from the function declaration.
  ///
  /// Priority:
  /// 1. `@RfwWidget('name')` annotation value
  /// 2. Function name with 'build' prefix stripped and first letter lowercased
  /// 3. Function name as-is if no 'build' prefix
  String _extractWidgetName(FunctionDeclaration function) {
    // Check for @RfwWidget annotation.
    for (final annotation in function.metadata) {
      if (annotation.name.name == 'RfwWidget') {
        final arguments = annotation.arguments;
        if (arguments != null && arguments.arguments.isNotEmpty) {
          final arg = arguments.arguments.first;
          if (arg is SimpleStringLiteral) {
            return arg.value;
          }
        }
      }
    }

    // Fallback: derive from function name.
    final name = function.name.lexeme;
    if (name.startsWith('build') && name.length > 5) {
      // Strip 'build' prefix and lowercase the first character.
      return name[5].toLowerCase() + name.substring(6);
    }
    return name;
  }
}
