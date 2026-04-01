import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen/rfw_gen.dart' show RfwGenIssueCode;

import 'expression_converter.dart';
import 'ir.dart';
import 'issue_collector.dart';
import 'widget_registry.dart';

/// Thrown when a widget is not found in the [WidgetRegistry].
class UnsupportedWidgetError implements Exception {
  final String widgetName;
  final String? message;
  final RfwGenIssueCode code;
  UnsupportedWidgetError(this.widgetName, {this.message, required this.code});

  @override
  String toString() => message != null
      ? 'UnsupportedWidgetError: $message'
      : 'UnsupportedWidgetError: $widgetName is not registered';
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
  final IssueCollector? collector;

  WidgetAstVisitor({
    required this.registry,
    required this.expressionConverter,
    this.collector,
  });

  /// Extract the widget tree from a function's return statement.
  ///
  /// Supports both block function bodies (with a `return` statement) and
  /// expression function bodies (arrow syntax `=>`).
  ///
  /// Throws [StateError] if no return expression is found.
  /// Throws [UnsupportedWidgetError] if the root expression is not a
  /// registered widget or supported special construct (e.g. RfwSwitch,
  /// RfwFor).
  IrValue extractWidgetTree(FunctionDeclaration function) {
    final expr = _findReturnExpression(function);
    if (expr == null) {
      throw UnsupportedWidgetError(
        '',
        message: 'No return expression found in function body',
        code: RfwGenIssueCode.functionNoReturn,
      );
    }
    return _convertWidgetOrSpecial(expr);
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

  /// Converts an expression that could be a widget OR a special construct
  /// (RfwFor, RfwSwitch).
  IrValue _convertWidgetOrSpecial(Expression expr) {
    if (expr is MethodInvocation && expr.target == null) {
      final name = expr.methodName.name;
      if (name == 'RfwFor') return _convertRfwFor(expr);
      if (name == 'RfwSwitch') return _convertRfwSwitch(expr);
    }
    return _convertWidget(expr);
  }

  /// Converts a [MethodInvocation] (widget constructor) to an [IrWidgetNode].
  IrWidgetNode _convertWidget(Expression expr) {
    if (expr is! MethodInvocation || expr.target != null) {
      throw UnsupportedWidgetError(
        expr.toString(),
        code: RfwGenIssueCode.widgetNotMethodInvocation,
      );
    }

    final widgetName = expr.methodName.name;

    const helperNames = {
      'DataRef',
      'ArgsRef',
      'StateRef',
      'RfwConcat',
      'RfwSwitchValue',
    };
    if (helperNames.contains(widgetName)) {
      throw UnsupportedWidgetError(
        widgetName,
        message: '$widgetName cannot be used as a widget. '
            'It can only be used as a parameter value of core/material widgets. '
            'If used inside a custom widget, pass a constant value instead.',
        code: RfwGenIssueCode.helperUsedAsWidget,
      );
    }

    if (!registry.isSupported(widgetName)) {
      throw UnsupportedWidgetError(
        widgetName,
        code: RfwGenIssueCode.widgetNotRegistered,
      );
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
          } on UnsupportedExpressionError catch (e) {
            collector?.warning(
              'Failed to convert positional parameter "${mapping.positionalParam}" of $widgetName: ${e.message}',
              code: e.code,
              offset: e.offset,
              suggestion: _suggestFor(e.message),
            );
          }
        }
        positionalIndex++;
      }
    }

    // Post-process: spread iconData and imageProvider maps to root level.
    // RFW runtime reads icon/fontFamily and source/scale at root, not nested.
    _spreadIconData(properties);
    _spreadImageProvider(properties);

    // Use the RFW widget name (e.g., 'core.Padding' → 'Padding')
    // so animated aliases map to their RFW equivalents in output.
    final rfwWidgetName = mapping.rfwName.split('.').last;
    return IrWidgetNode(name: rfwWidgetName, properties: properties);
  }

  /// Spreads `iconData` map entries to root level for RFW Icon compatibility.
  ///
  /// RFW runtime reads `source.v<int>(['icon'])` at root level, not nested
  /// under `iconData`. For data references, creates sub-references
  /// (e.g., `cat.icon` → `cat.icon.icon` + `cat.icon.fontFamily`).
  void _spreadIconData(Map<String, IrValue> properties) {
    final iconData = properties.remove('iconData');
    if (iconData == null) return;

    if (iconData is IrMapValue) {
      // Hardcoded icon: spread {icon: ..., fontFamily: ...} to root.
      properties.addAll(iconData.entries);
    } else if (iconData is IrLoopVarRef) {
      properties['icon'] = IrLoopVarRef('${iconData.path}.icon');
      properties['fontFamily'] = IrLoopVarRef('${iconData.path}.fontFamily');
    } else if (iconData is IrDataRef) {
      properties['icon'] = IrDataRef('${iconData.path}.icon');
      properties['fontFamily'] = IrDataRef('${iconData.path}.fontFamily');
    } else if (iconData is IrArgsRef) {
      properties['icon'] = IrArgsRef('${iconData.path}.icon');
      properties['fontFamily'] = IrArgsRef('${iconData.path}.fontFamily');
    } else {
      // Unknown type — keep as-is under original key.
      properties['iconData'] = iconData;
    }
  }

  /// Spreads `imageProvider` map entries to root level for RFW Image compatibility.
  ///
  /// RFW runtime reads `source.v<String>(['source'])` at root level.
  void _spreadImageProvider(Map<String, IrValue> properties) {
    final imageProvider = properties.remove('imageProvider');
    if (imageProvider == null) return;

    if (imageProvider is IrMapValue) {
      // Hardcoded image: spread {source: ..., scale: ...} to root.
      properties.addAll(imageProvider.entries);
    } else {
      // Unknown type — keep as-is.
      properties['imageProvider'] = imageProvider;
    }
  }

  /// Processes a named argument, handling handler params, named child slots,
  /// child parameters, and regular params.
  void _processNamedArgument(
    NamedExpression arg,
    WidgetMapping mapping,
    Map<String, IrValue> properties,
  ) {
    final paramName = arg.name.label.name;
    final expression = arg.expression;

    // 1. Handler params — use convertHandler instead of convert.
    if (mapping.handlerParams.contains(paramName)) {
      try {
        final handler = expressionConverter.convertHandler(expression);
        // null means an empty no-op handler — skip it silently.
        if (handler != null) {
          properties[paramName] = handler;
        }
      } on UnsupportedExpressionError catch (e) {
        collector?.warning(
          'Failed to convert handler "$paramName" of ${mapping.rfwName}: ${e.message}',
          code: e.code,
          offset: e.offset,
          suggestion: _suggestFor(e.message),
        );
      }
      return;
    }

    // 2. Named child slots — convert widgets in named slots.
    if (mapping.childType == ChildType.namedSlots &&
        mapping.namedChildSlots.containsKey(paramName)) {
      final isList = mapping.namedChildSlots[paramName]!;
      if (isList && expression is ListLiteral) {
        final children = expression.elements
            .map((e) => _convertWidgetOrSpecial(
                  e is SpreadElement ? e.expression : (e as Expression),
                ))
            .toList();
        properties[paramName] = IrListValue(children);
      } else if (isList) {
        collector?.warning(
          'Named slot "$paramName" of ${mapping.rfwName} is not a list (${expression.runtimeType})',
          code: RfwGenIssueCode.unsupportedExpression,
          suggestion: 'Use a list literal [...] for list slots',
        );
      } else {
        properties[paramName] = _convertWidgetOrSpecial(expression);
      }
      return;
    }

    // 3. Regular child/children parameter.
    if (mapping.childParam != null && paramName == mapping.childParam) {
      switch (mapping.childType) {
        case ChildType.child:
        case ChildType.optionalChild:
          // Single child: recurse to convert the widget or special construct.
          properties[paramName] = _convertWidgetOrSpecial(expression);
        case ChildType.childList:
          // List of children: expect a ListLiteral.
          if (expression is ListLiteral) {
            final children = expression.elements
                .map((e) => _convertWidgetOrSpecial(
                      e is SpreadElement ? e.expression : (e as Expression),
                    ))
                .toList();
            properties[paramName] = IrListValue(children);
          } else {
            collector?.warning(
              'children parameter of ${mapping.rfwName} is not a list (${expression.runtimeType})',
              code: RfwGenIssueCode.unsupportedExpression,
              suggestion: 'Use a list literal [...] for the children parameter',
            );
          }
        case ChildType.none:
        case ChildType.namedSlots:
          break;
      }
      return;
    }

    // 4. Known params in the mapping.
    if (mapping.params.containsKey(paramName)) {
      try {
        final value = expressionConverter.convert(expression);
        final paramMapping = mapping.params[paramName]!;
        properties[paramMapping.rfwName] = value;
      } on UnsupportedExpressionError catch (e) {
        collector?.warning(
          'Failed to convert parameter "$paramName" of ${mapping.rfwName}: ${e.message}',
          code: e.code,
          offset: e.offset,
          suggestion: _suggestFor(e.message),
        );
      }
      return;
    }

    // 5. Unknown parameter — check if it's a widget or special construct first,
    // then try expression.
    if (expression is MethodInvocation && expression.target == null) {
      final exprName = expression.methodName.name;
      if (registry.isSupported(exprName) ||
          exprName == 'RfwFor' ||
          exprName == 'RfwSwitch') {
        properties[paramName] = _convertWidgetOrSpecial(expression);
        return;
      }
    }
    try {
      final value = expressionConverter.convert(expression);
      properties[paramName] = value;
    } on UnsupportedExpressionError catch (e) {
      collector?.warning(
        'Failed to convert unknown parameter "$paramName": ${e.message}',
        code: e.code,
        offset: e.offset,
        suggestion: _suggestFor(e.message),
      );
    }
  }

  /// Returns a suggestion string based on the error message pattern.
  String? _suggestFor(String errorMessage) {
    if (errorMessage.contains('ConditionalExpression')) {
      return 'Use RfwSwitch instead of ternary operator';
    }
    if (errorMessage.contains('FunctionExpressionInvocation')) {
      return 'Function call results are not supported. Use const values directly';
    }
    if (errorMessage.contains('Unsupported EdgeInsets constructor')) {
      return 'Supported constructors: .all, .symmetric, .only, .fromLTRB';
    }
    if (errorMessage.contains('Unsupported BorderRadius constructor')) {
      return 'Supported constructors: .circular, .all, .only';
    }
    if (errorMessage.contains('Alignment') &&
        errorMessage.contains('constant')) {
      return 'Supported values: topLeft, topCenter, topRight, centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight';
    }
    if (errorMessage.contains('Unsupported method invocation')) {
      return 'Unsupported method. Supported: Color, EdgeInsets, TextStyle, etc.';
    }
    if (errorMessage.contains('Unsupported const constructor')) {
      return 'Unsupported constructor';
    }
    return null;
  }

  IrForLoop _convertRfwFor(MethodInvocation expr) {
    IrValue? items;
    String? itemName;
    IrWidgetNode? body;

    // First pass: extract itemName so we can track loop variable
    for (final arg in expr.argumentList.arguments) {
      if (arg is NamedExpression && arg.name.label.name == 'itemName') {
        itemName = (arg.expression as SimpleStringLiteral).value;
      }
    }

    // Second pass: convert items and builder with loop variable context
    if (itemName != null) {
      expressionConverter.loopVarNames.add(itemName);
    }

    for (final arg in expr.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'items') {
          items = expressionConverter.convert(arg.expression);
        } else if (name == 'builder') {
          final funcExpr = arg.expression as FunctionExpression;
          final funcBody = funcExpr.body;
          Expression? bodyExpr;
          if (funcBody is ExpressionFunctionBody) {
            bodyExpr = funcBody.expression;
          } else if (funcBody is BlockFunctionBody) {
            for (final stmt in funcBody.block.statements) {
              if (stmt is ReturnStatement) {
                bodyExpr = stmt.expression;
                break;
              }
            }
          }
          if (bodyExpr != null) {
            body = _convertWidget(bodyExpr);
          }
        }
      }
    }

    if (itemName != null) {
      expressionConverter.loopVarNames.remove(itemName);
    }

    if (items == null || itemName == null || body == null) {
      throw UnsupportedWidgetError(
        'RfwFor',
        message: 'RfwFor requires items, itemName, and builder',
        code: RfwGenIssueCode.rfwForMissingParameters,
      );
    }

    return IrForLoop(items: items, itemName: itemName, body: body);
  }

  IrSwitchExpr _convertRfwSwitch(MethodInvocation expr) {
    IrValue? value;
    final cases = <IrValue, IrValue>{};
    IrValue? defaultCase;

    for (final arg in expr.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'value') {
          value = expressionConverter.convert(arg.expression);
        } else if (name == 'cases') {
          if (arg.expression is SetOrMapLiteral) {
            for (final entry in (arg.expression as SetOrMapLiteral).elements) {
              if (entry is MapLiteralEntry) {
                final key = expressionConverter.convert(entry.key);
                final val = _convertWidgetOrSpecial(entry.value);
                cases[key] = val;
              }
            }
          }
        } else if (name == 'defaultCase') {
          defaultCase = _convertWidgetOrSpecial(arg.expression);
        }
      }
    }

    if (value == null) {
      throw UnsupportedWidgetError(
        'RfwSwitch',
        message: 'RfwSwitch requires a value parameter',
        code: RfwGenIssueCode.rfwSwitchMissingValue,
      );
    }

    return IrSwitchExpr(value: value, cases: cases, defaultCase: defaultCase);
  }
}
