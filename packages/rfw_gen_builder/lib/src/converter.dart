import 'dart:typed_data';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw/formats.dart';

import 'ast_visitor.dart';
import 'convert_result.dart';
import 'expression_converter.dart';
import 'icon_resolver.dart';
import 'ir.dart';
import 'issue_collector.dart';
import 'rfwtxt_emitter.dart';
import 'widget_registry.dart';

/// Complete conversion pipeline: Dart source -> rfwtxt -> binary blob.
///
/// Ties together [WidgetAstVisitor] and [RfwtxtEmitter] into a single
/// entry point for both build_runner and MCP usage.
class RfwConverter {
  /// The widget registry used to resolve Flutter widget names to rfwtxt mappings.
  final WidgetRegistry registry;

  /// Optional resolver for `Icons.xxx` constants via the Dart analyzer.
  final IconResolver? iconResolver;

  /// Creates a converter backed by the given [registry].
  RfwConverter({required this.registry, this.iconResolver});

  /// Converts a Dart source string containing a widget-building function
  /// to a [ConvertResult] containing the rfwtxt string and any diagnostic issues.
  ///
  /// Parses the source, finds the first [FunctionDeclaration], and
  /// delegates to [convertFromAst].
  ///
  /// Throws [StateError] if no [FunctionDeclaration] is found.
  ConvertResult convertFromSource(String dartSource) {
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

    return convertFromAst(function, source: dartSource);
  }

  /// Converts a parsed [FunctionDeclaration] AST node to a [ConvertResult].
  ///
  /// Extracts the widget name from an `@RfwWidget('name')` annotation or
  /// falls back to deriving it from the function name. Then uses
  /// [WidgetAstVisitor] to extract the IR widget tree and [RfwtxtEmitter]
  /// to emit the rfwtxt output.
  ///
  /// Any diagnostic issues (e.g. unsupported state initialiser expressions)
  /// are collected in [ConvertResult.issues] rather than thrown.
  ConvertResult convertFromAst(FunctionDeclaration function, {String? source}) {
    final collector = IssueCollector(source ?? '');
    final widgetName = _extractWidgetName(function, collector);
    final stateDecl = _extractStateDecl(function, collector);

    final visitor = WidgetAstVisitor(
      registry: registry,
      expressionConverter: ExpressionConverter(
        iconResolver: iconResolver,
        onWarning: (message, {int? offset}) {
          collector.warning(message, offset: offset);
        },
      ),
      collector: collector,
    );
    final irTree = visitor.extractWidgetTree(function);

    final imports = _collectImports(irTree);
    final emitter = RfwtxtEmitter();
    final rfwtxt = emitter.emit(
      widgetName: widgetName,
      root: irTree,
      imports: imports,
      stateDecl: stateDecl,
    );

    return ConvertResult(rfwtxt: rfwtxt, issues: collector.issues);
  }

  /// Extracts the state declaration map from the `@RfwWidget` annotation,
  /// if a `state` named argument is present.
  ///
  /// Entries whose values cannot be converted are skipped and a
  /// [RfwGenSeverity.warning] is added to [collector].
  Map<String, IrValue>? _extractStateDecl(
    FunctionDeclaration function,
    IssueCollector collector,
  ) {
    for (final annotation in function.metadata) {
      if (annotation.name.name == 'RfwWidget') {
        final arguments = annotation.arguments;
        if (arguments == null) continue;
        for (final arg in arguments.arguments) {
          if (arg is NamedExpression && arg.name.label.name == 'state') {
            if (arg.expression is SetOrMapLiteral) {
              final map = arg.expression as SetOrMapLiteral;
              final entries = <String, IrValue>{};
              final exprConverter = ExpressionConverter();
              for (final entry in map.elements) {
                if (entry is MapLiteralEntry) {
                  final key = (entry.key as SimpleStringLiteral).value;
                  try {
                    entries[key] = exprConverter.convert(entry.value);
                  } on UnsupportedExpressionError catch (e) {
                    collector.warning(
                      'Failed to convert state field "$key": ${e.message}',
                      offset: e.offset,
                      suggestion:
                          'State initial values only support literals (string, number, boolean)',
                    );
                  }
                }
              }
              return entries;
            }
          }
        }
      }
    }
    return null;
  }

  /// Recursively collects the set of rfwtxt import libraries required by
  /// the widget tree rooted at [node].
  Set<String> _collectImports(IrValue node) {
    final imports = <String>{};
    if (node is IrWidgetNode) {
      final mapping = registry.supportedWidgets[node.name];
      if (mapping != null) imports.add(mapping.import);
      for (final value in node.properties.values) {
        imports.addAll(_collectImports(value));
      }
    } else if (node is IrListValue) {
      for (final item in node.values) {
        imports.addAll(_collectImports(item));
      }
    } else if (node is IrForLoop) {
      imports.addAll(_collectImports(node.body));
    } else if (node is IrSwitchExpr) {
      for (final caseValue in node.cases.values) {
        imports.addAll(_collectImports(caseValue));
      }
      if (node.defaultCase != null) {
        imports.addAll(_collectImports(node.defaultCase!));
      }
    }
    return imports;
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
  String _extractWidgetName(FunctionDeclaration function,
      [IssueCollector? collector]) {
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
        // @RfwWidget() with empty parentheses — warn and use fallback.
        if (arguments != null && arguments.arguments.isEmpty) {
          collector?.warning(
            '@RfwWidget() requires a name parameter',
            suggestion: "Use @RfwWidget('widgetName'). "
                'Falling back to function name: '
                '${_deriveNameFromFunction(function)}',
          );
        }
      }
    }

    // Fallback: derive from function name.
    return _deriveNameFromFunction(function);
  }

  /// Derives widget name from function name by stripping 'build' prefix.
  String _deriveNameFromFunction(FunctionDeclaration function) {
    final name = function.name.lexeme;
    if (name.startsWith('build') && name.length > 5) {
      return name[5].toLowerCase() + name.substring(6);
    }
    return name;
  }
}
