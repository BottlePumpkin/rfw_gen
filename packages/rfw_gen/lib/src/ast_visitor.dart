import 'package:analyzer/dart/ast/ast.dart';

import 'expression_converter.dart';
import 'ir.dart';
import 'widget_registry.dart';

/// Thrown when a widget is not found in the [WidgetRegistry].
class UnsupportedWidgetError implements Exception {
  final String widgetName;
  UnsupportedWidgetError(this.widgetName);

  @override
  String toString() => 'UnsupportedWidgetError: $widgetName is not registered';
}

/// Extracts an [IrWidgetNode] tree from a [FunctionDeclaration]'s AST.
///
/// Traverses the return statement, identifies widget constructor calls
/// (which parse as [MethodInvocation] nodes without type resolution),
/// maps their parameters using [WidgetRegistry], and converts argument
/// values using [ExpressionConverter].
class WidgetAstVisitor {
  final WidgetRegistry registry;
  final ExpressionConverter expressionConverter;

  WidgetAstVisitor({
    required this.registry,
    required this.expressionConverter,
  });

  /// Extract the widget tree from a function's return statement.
  ///
  /// Supports both block function bodies (with a `return` statement) and
  /// expression function bodies (arrow syntax `=>`).
  ///
  /// Throws [StateError] if no return expression is found.
  /// Throws [UnsupportedWidgetError] if the root expression is not a
  /// registered widget.
  IrWidgetNode extractWidgetTree(FunctionDeclaration function) {
    final expr = _findReturnExpression(function);
    if (expr == null) {
      throw StateError(
        'No return expression found in function '
        '"${function.name.lexeme}"',
      );
    }
    return _convertWidget(expr);
  }

  /// Finds the return expression from either a block body or arrow body.
  Expression? _findReturnExpression(FunctionDeclaration function) {
    final body = function.functionExpression.body;

    if (body is ExpressionFunctionBody) {
      return body.expression;
    }

    if (body is BlockFunctionBody) {
      for (final statement in body.block.statements) {
        if (statement is ReturnStatement) {
          return statement.expression;
        }
      }
    }

    return null;
  }

  /// Converts a [MethodInvocation] (widget constructor) to an [IrWidgetNode].
  IrWidgetNode _convertWidget(Expression expr) {
    if (expr is! MethodInvocation || expr.target != null) {
      throw UnsupportedWidgetError(expr.toString());
    }

    final widgetName = expr.methodName.name;

    if (!registry.isSupported(widgetName)) {
      throw UnsupportedWidgetError(widgetName);
    }

    final mapping = registry.supportedWidgets[widgetName]!;
    final properties = <String, IrValue>{};

    final arguments = expr.argumentList.arguments;
    int positionalIndex = 0;

    for (final arg in arguments) {
      if (arg is NamedExpression) {
        _processNamedArgument(arg, mapping, properties);
      } else {
        // Positional argument — map to positionalParam if defined.
        if (mapping.positionalParam != null && positionalIndex == 0) {
          try {
            final value = expressionConverter.convert(arg);
            properties[mapping.positionalParam!] = value;
          } on UnsupportedExpressionError {
            // Silently skip unsupported positional arguments.
          }
        }
        positionalIndex++;
      }
    }

    return IrWidgetNode(name: widgetName, properties: properties);
  }

  /// Processes a named argument, handling child parameters and regular params.
  void _processNamedArgument(
    NamedExpression arg,
    WidgetMapping mapping,
    Map<String, IrValue> properties,
  ) {
    final paramName = arg.name.label.name;
    final expression = arg.expression;

    // Check if this is the child/children parameter.
    if (mapping.childParam != null && paramName == mapping.childParam) {
      switch (mapping.childType) {
        case ChildType.child:
        case ChildType.optionalChild:
          // Single child: recurse to convert the widget.
          properties[paramName] = _convertWidget(expression);
        case ChildType.childList:
          // List of children: expect a ListLiteral.
          if (expression is ListLiteral) {
            final children = expression.elements
                .map((e) => _convertWidget(e as Expression))
                .toList();
            properties[paramName] = IrListValue(children);
          }
        case ChildType.none:
          break;
      }
      return;
    }

    // Check if this is a known parameter in the mapping.
    if (mapping.params.containsKey(paramName)) {
      try {
        final value = expressionConverter.convert(expression);
        final paramMapping = mapping.params[paramName]!;
        properties[paramMapping.rfwName] = value;
      } on UnsupportedExpressionError {
        // Silently skip unsupported expressions.
      }
      return;
    }

    // Unknown parameter — try ExpressionConverter, silently skip if unsupported.
    try {
      final value = expressionConverter.convert(expression);
      properties[paramName] = value;
    } on UnsupportedExpressionError {
      // Silently skip.
    }
  }
}
