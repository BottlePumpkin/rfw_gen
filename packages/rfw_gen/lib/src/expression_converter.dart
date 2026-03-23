import 'package:analyzer/dart/ast/ast.dart';

import 'ir.dart';
import 'rfw_icons.dart';

/// Thrown when an expression cannot be converted to an IR value.
class UnsupportedExpressionError implements Exception {
  final String message;
  final int? offset;
  UnsupportedExpressionError(this.message, {this.offset});

  @override
  String toString() => 'UnsupportedExpressionError: $message';
}

/// Converts Dart AST [Expression] nodes to [IrValue] instances.
///
/// Supports literals, known constructors (Color, EdgeInsets), and
/// known enum prefixes. Throws [UnsupportedExpressionError] for
/// unsupported expression types.
class ExpressionConverter {
  static const _knownEnumPrefixes = <String>{
    'MainAxisAlignment',
    'CrossAxisAlignment',
    'MainAxisSize',
    'VerticalDirection',
    'TextAlign',
    'TextOverflow',
    'TextDirection',
    'Axis',
    'Clip',
    'BoxFit',
    'StackFit',
    'FlexFit',
    'WrapAlignment',
    'WrapCrossAlignment',
    'ImageRepeat',
  };

  static const _knownGridDelegates = <String>{
    'SliverGridDelegateWithFixedCrossAxisCount',
    'SliverGridDelegateWithMaxCrossAxisExtent',
  };

  /// Converts an [Expression] to an [IrValue].
  IrValue convert(Expression expr) {
    return switch (expr) {
      SimpleStringLiteral() => IrStringValue(expr.value),
      IntegerLiteral() => IrIntValue(expr.value!),
      DoubleLiteral() => IrNumberValue(expr.value),
      BooleanLiteral() => IrBoolValue(expr.value),
      ListLiteral() => _convertListLiteral(expr),
      PrefixExpression() => _convertPrefixExpression(expr),
      MethodInvocation() => _convertMethodInvocation(expr),
      PrefixedIdentifier() => _convertPrefixedIdentifier(expr),
      _ => throw UnsupportedExpressionError(
          'Unsupported expression type: ${expr.runtimeType}',
          offset: expr.offset,
        ),
    };
  }

  IrListValue _convertListLiteral(ListLiteral expr) {
    return IrListValue(expr.elements.map((e) => convert(e as Expression)).toList());
  }

  IrValue _convertPrefixExpression(PrefixExpression expr) {
    if (expr.operator.lexeme == '-') {
      final operand = expr.operand;
      if (operand is DoubleLiteral) {
        return IrNumberValue(-operand.value);
      }
      if (operand is IntegerLiteral) {
        return IrIntValue(-operand.value!);
      }
    }
    throw UnsupportedExpressionError(
      'Unsupported prefix expression: ${expr.operator.lexeme}',
      offset: expr.offset,
    );
  }

  IrValue _convertMethodInvocation(MethodInvocation expr) {
    final target = expr.target;
    final methodName = expr.methodName.name;

    // Color(0xFFxxxxxx) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Color') {
      return _convertColor(expr);
    }

    // EdgeInsets.xxx(...) — parses as MethodInvocation with target 'EdgeInsets'
    if (target is SimpleIdentifier && target.name == 'EdgeInsets') {
      return _convertEdgeInsets(methodName, expr.argumentList);
    }

    // Duration(milliseconds: 300) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Duration') {
      return _convertDuration(expr);
    }

    // BorderRadius.xxx(...) — parses as MethodInvocation with target 'BorderRadius'
    if (target is SimpleIdentifier && target.name == 'BorderRadius') {
      return _convertBorderRadius(methodName, expr.argumentList);
    }

    // NetworkImage('url') — parses as MethodInvocation with no target
    if (target == null && methodName == 'NetworkImage') {
      return _convertImageProvider(expr);
    }

    // AssetImage('path') — parses as MethodInvocation with no target
    if (target == null && methodName == 'AssetImage') {
      return _convertImageProvider(expr);
    }

    // SliverGridDelegateWithXxx(...) — parses as MethodInvocation with no target
    if (target == null && _knownGridDelegates.contains(methodName)) {
      return _convertGridDelegate(expr);
    }

    throw UnsupportedExpressionError(
      'Unsupported method invocation: $methodName',
      offset: expr.offset,
    );
  }

  IrIntValue _convertColor(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    if (args.length == 1) {
      final arg = args.first;
      if (arg is IntegerLiteral) {
        return IrIntValue(arg.value!);
      }
    }
    throw UnsupportedExpressionError(
      'Color constructor expects a single integer argument',
      offset: expr.offset,
    );
  }

  IrListValue _convertEdgeInsets(String method, ArgumentList argList) {
    switch (method) {
      case 'all':
        return _convertEdgeInsetsAll(argList);
      case 'symmetric':
        return _convertEdgeInsetsSymmetric(argList);
      case 'only':
        return _convertEdgeInsetsOnly(argList);
      case 'fromLTRB':
        return _convertEdgeInsetsFromLTRB(argList);
      default:
        throw UnsupportedExpressionError(
          'Unsupported EdgeInsets constructor: $method',
        );
    }
  }

  IrListValue _convertEdgeInsetsAll(ArgumentList argList) {
    final value = _toDouble(argList.arguments.first);
    return IrListValue([IrNumberValue(value)]);
  }

  IrListValue _convertEdgeInsetsSymmetric(ArgumentList argList) {
    double horizontal = 0.0;
    double vertical = 0.0;

    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _toDouble(arg.expression);
        if (name == 'horizontal') {
          horizontal = value;
        } else if (name == 'vertical') {
          vertical = value;
        }
      }
    }

    // [left, top, right, bottom] = [h, v, h, v]
    return IrListValue([
      IrNumberValue(horizontal),
      IrNumberValue(vertical),
      IrNumberValue(horizontal),
      IrNumberValue(vertical),
    ]);
  }

  IrListValue _convertEdgeInsetsOnly(ArgumentList argList) {
    double left = 0.0;
    double top = 0.0;
    double right = 0.0;
    double bottom = 0.0;

    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _toDouble(arg.expression);
        switch (name) {
          case 'left':
            left = value;
          case 'top':
            top = value;
          case 'right':
            right = value;
          case 'bottom':
            bottom = value;
        }
      }
    }

    return IrListValue([
      IrNumberValue(left),
      IrNumberValue(top),
      IrNumberValue(right),
      IrNumberValue(bottom),
    ]);
  }

  IrListValue _convertEdgeInsetsFromLTRB(ArgumentList argList) {
    final args = argList.arguments;
    return IrListValue([
      IrNumberValue(_toDouble(args[0])),
      IrNumberValue(_toDouble(args[1])),
      IrNumberValue(_toDouble(args[2])),
      IrNumberValue(_toDouble(args[3])),
    ]);
  }

  IrValue _convertPrefixedIdentifier(PrefixedIdentifier expr) {
    final prefix = expr.prefix.name;
    final identifier = expr.identifier.name;

    if (_knownEnumPrefixes.contains(prefix)) {
      return IrEnumValue(identifier);
    }

    if (prefix == 'Curves') {
      return IrStringValue(identifier);
    }

    if (prefix == 'BorderRadius' && identifier == 'zero') {
      return IrListValue([IrMapValue({'x': IrNumberValue(0.0)})]);
    }

    if (prefix == 'RfwIcon') {
      return _convertRfwIcon(identifier);
    }

    throw UnsupportedExpressionError(
      'Unknown prefixed identifier: $prefix.$identifier',
      offset: expr.offset,
    );
  }

  IrMapValue _convertRfwIcon(String name) {
    final codepoint = RfwIcon.lookup(name);
    if (codepoint == null) {
      throw UnsupportedExpressionError('Unknown RfwIcon: $name');
    }
    return IrMapValue({
      'icon': IrIntValue(codepoint),
      'fontFamily': IrStringValue('MaterialIcons'),
    });
  }

  IrIntValue _convertDuration(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    for (final arg in args) {
      if (arg is NamedExpression && arg.name.label.name == 'milliseconds') {
        final value = arg.expression;
        if (value is IntegerLiteral) {
          return IrIntValue(value.value!);
        }
      }
    }
    throw UnsupportedExpressionError(
      'Duration requires a milliseconds named argument',
      offset: expr.offset,
    );
  }

  IrListValue _convertBorderRadius(String method, ArgumentList argList) {
    switch (method) {
      case 'circular':
        return _convertBorderRadiusCircular(argList);
      case 'only':
        return _convertBorderRadiusOnly(argList);
      default:
        throw UnsupportedExpressionError(
          'Unsupported BorderRadius constructor: $method',
        );
    }
  }

  IrListValue _convertBorderRadiusCircular(ArgumentList argList) {
    final value = _toDouble(argList.arguments.first);
    return IrListValue([IrMapValue({'x': IrNumberValue(value)})]);
  }

  IrListValue _convertBorderRadiusOnly(ArgumentList argList) {
    final corners = <IrValue>[
      IrMapValue({'x': IrNumberValue(0.0)}),
      IrMapValue({'x': IrNumberValue(0.0)}),
      IrMapValue({'x': IrNumberValue(0.0)}),
      IrMapValue({'x': IrNumberValue(0.0)}),
    ];
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final radiusValue = _extractRadiusValue(arg.expression);
        switch (name) {
          case 'topLeft':
            corners[0] = IrMapValue({'x': IrNumberValue(radiusValue)});
          case 'topRight':
            corners[1] = IrMapValue({'x': IrNumberValue(radiusValue)});
          case 'bottomLeft':
            corners[2] = IrMapValue({'x': IrNumberValue(radiusValue)});
          case 'bottomRight':
            corners[3] = IrMapValue({'x': IrNumberValue(radiusValue)});
        }
      }
    }
    return IrListValue(corners);
  }

  double _extractRadiusValue(Expression expr) {
    if (expr is MethodInvocation &&
        expr.target is SimpleIdentifier &&
        (expr.target as SimpleIdentifier).name == 'Radius' &&
        expr.methodName.name == 'circular') {
      return _toDouble(expr.argumentList.arguments.first);
    }
    throw UnsupportedExpressionError(
      'Expected Radius.circular(), got ${expr.runtimeType}',
      offset: expr.offset,
    );
  }

  IrMapValue _convertImageProvider(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    String? source;
    double scale = 1.0;
    for (final arg in args) {
      if (arg is SimpleStringLiteral) {
        source = arg.value;
      } else if (arg is NamedExpression && arg.name.label.name == 'scale') {
        scale = _toDouble(arg.expression);
      }
    }
    if (source == null) {
      throw UnsupportedExpressionError(
        'ImageProvider requires a string argument',
        offset: expr.offset,
      );
    }
    return IrMapValue({
      'source': IrStringValue(source),
      'scale': IrNumberValue(scale),
    });
  }

  IrMapValue _convertGridDelegate(MethodInvocation expr) {
    final entries = <String, IrValue>{};
    for (final arg in expr.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        entries[name] = convert(arg.expression);
      }
    }
    return IrMapValue(entries);
  }

  /// Converts a handler expression to an IR handler value.
  IrValue convertHandler(Expression expr) {
    if (expr is! MethodInvocation) {
      throw UnsupportedExpressionError(
        'Handler must be RfwHandler.setState/setStateFromArg/event',
        offset: expr.offset,
      );
    }

    final target = expr.target;
    final methodName = expr.methodName.name;

    if (target is SimpleIdentifier && target.name == 'RfwHandler') {
      if (methodName == 'setState') return _convertSetState(expr);
      if (methodName == 'setStateFromArg') return _convertSetStateFromArg(expr);
      if (methodName == 'event') return _convertEvent(expr);
    }

    if (target == null && methodName == 'RfwSetState') {
      return _convertSetState(expr);
    }
    if (target == null && methodName == 'RfwSetStateFromArg') {
      return _convertSetStateFromArg(expr);
    }
    if (target == null && methodName == 'RfwEvent') {
      return _convertEvent(expr);
    }

    throw UnsupportedExpressionError(
      'Unknown handler expression: $methodName',
      offset: expr.offset,
    );
  }

  IrSetStateValue _convertSetState(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    final field = (args[0] as SimpleStringLiteral).value;
    final value = convert(args[1]);
    return IrSetStateValue(field, value);
  }

  IrSetStateFromArgValue _convertSetStateFromArg(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    final field = (args[0] as SimpleStringLiteral).value;
    final argName =
        args.length > 1 ? (args[1] as SimpleStringLiteral).value : 'value';
    return IrSetStateFromArgValue(field, argName);
  }

  IrEventValue _convertEvent(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    final name = (args[0] as SimpleStringLiteral).value;
    if (args.length > 1) {
      final mapExpr = args[1];
      if (mapExpr is SetOrMapLiteral) {
        final entries = <String, IrValue>{};
        for (final entry in mapExpr.elements) {
          if (entry is MapLiteralEntry) {
            final key = (entry.key as SimpleStringLiteral).value;
            entries[key] = convert(entry.value);
          }
        }
        return IrEventValue(name, entries);
      }
    }
    return IrEventValue(name);
  }

  /// Extracts a double value from a numeric expression.
  /// Converts int literals to double for EdgeInsets consistency.
  double _toDouble(Expression expr) {
    if (expr is DoubleLiteral) return expr.value;
    if (expr is IntegerLiteral) return expr.value!.toDouble();
    throw UnsupportedExpressionError(
      'Expected numeric literal, got ${expr.runtimeType}',
      offset: expr.offset,
    );
  }
}
