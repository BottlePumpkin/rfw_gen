import 'package:analyzer/dart/ast/ast.dart';

import 'ir.dart';

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

    throw UnsupportedExpressionError(
      'Unknown prefixed identifier: $prefix.$identifier',
      offset: expr.offset,
    );
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
