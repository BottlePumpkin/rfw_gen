import 'package:analyzer/dart/ast/ast.dart';

import 'icon_resolver.dart';
import 'ir.dart';
import 'package:rfw_gen/rfw_gen.dart' show RfwGenIssueCode, RfwIcon;

/// Thrown when an expression cannot be converted to an IR value.
class UnsupportedExpressionError implements Exception {
  final String message;
  final int? offset;
  final RfwGenIssueCode code;
  UnsupportedExpressionError(this.message, {this.offset, required this.code});

  @override
  String toString() => 'UnsupportedExpressionError: $message';
}

/// Converts Dart AST [Expression] nodes to [IrValue] instances.
///
/// Supports literals, known constructors (Color, EdgeInsets), and
/// known enum prefixes. Throws [UnsupportedExpressionError] for
/// unsupported expression types.
class ExpressionConverter {
  /// Optional resolver for `Icons.xxx` constants via the Dart analyzer.
  /// When set, unmapped `Icons.xxx` are resolved at build time instead of
  /// failing with an error.
  final IconResolver? iconResolver;

  /// Stack of active loop variable names for DataRef misuse detection.
  final List<String> loopVarNames = [];

  /// Optional callback for emitting warnings during conversion.
  final void Function(String message, {int? offset, RfwGenIssueCode? code})?
      onWarning;

  ExpressionConverter({this.iconResolver, this.onWarning});

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
    'HitTestBehavior',
    'MaterialType',
    'TextBaseline',
    'BorderStyle',
    'VisualDensity',
  };

  static const _knownGridDelegates = <String>{
    'SliverGridDelegateWithFixedCrossAxisCount',
    'SliverGridDelegateWithMaxCrossAxisExtent',
  };

  static const _knownDynamicRefs = <String>{'DataRef', 'ArgsRef', 'StateRef'};

  /// Converts an [Expression] to an [IrValue].
  IrValue convert(Expression expr) {
    return switch (expr) {
      SimpleStringLiteral() => IrStringValue(expr.value),
      IntegerLiteral() => IrIntValue(expr.value!),
      DoubleLiteral() => IrNumberValue(expr.value),
      BooleanLiteral() => IrBoolValue(expr.value),
      ListLiteral() => _convertListLiteral(expr),
      SetOrMapLiteral() => _convertMapLiteral(expr),
      PrefixExpression() => _convertPrefixExpression(expr),
      MethodInvocation() => _convertMethodInvocation(expr),
      InstanceCreationExpression() => _convertInstanceCreation(expr),
      PrefixedIdentifier() => _convertPrefixedIdentifier(expr),
      IndexExpression() => _convertIndexExpression(expr),
      _ => throw UnsupportedExpressionError(
          'Unsupported expression type: ${expr.runtimeType}',
          offset: expr.offset,
          code: RfwGenIssueCode.unsupportedExpression,
        ),
    };
  }

  IrListValue _convertListLiteral(ListLiteral expr) {
    return IrListValue(
        expr.elements.map((e) => convert(e as Expression)).toList());
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
    if (expr.operator.lexeme == '!') {
      final operand = expr.operand;
      if (operand is BooleanLiteral) {
        return IrBoolValue(!operand.value);
      }
    }
    throw UnsupportedExpressionError(
      'Unsupported prefix expression: ${expr.operator.lexeme}',
      offset: expr.offset,
      code: RfwGenIssueCode.unsupportedPrefixExpression,
    );
  }

  IrValue _convertMethodInvocation(MethodInvocation expr) {
    final target = expr.target;
    final methodName = expr.methodName.name;

    // Dynamic references: DataRef, ArgsRef, StateRef
    if (target == null && _knownDynamicRefs.contains(methodName)) {
      return _convertDynamicRef(methodName, expr);
    }

    // RfwConcat(['Hello, ', DataRef('name'), '!'])
    if (target == null && methodName == 'RfwConcat') {
      return _convertConcat(expr);
    }

    // RfwSwitchValue(value: ..., cases: {...}, defaultCase: ...)
    if (target == null && methodName == 'RfwSwitchValue') {
      return _convertSwitchValue(expr);
    }

    // Color.fromARGB / Color.fromRGBO — parses as MethodInvocation with target 'Color'
    if (target is SimpleIdentifier && target.name == 'Color') {
      if (methodName == 'fromARGB') {
        return _convertColorFromARGB(expr.argumentList);
      }
      if (methodName == 'fromRGBO') {
        return _convertColorFromRGBO(expr.argumentList);
      }
    }

    // Color(0xFFxxxxxx) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Color') {
      return _convertColor(expr);
    }

    // EdgeInsets.xxx(...) — parses as MethodInvocation with target 'EdgeInsets'
    if (target is SimpleIdentifier && target.name == 'EdgeInsets') {
      return _convertEdgeInsets(methodName, expr.argumentList,
          offset: expr.offset);
    }

    // EdgeInsetsDirectional.xxx(...) — parses as MethodInvocation with target 'EdgeInsetsDirectional'
    if (target is SimpleIdentifier && target.name == 'EdgeInsetsDirectional') {
      return _convertEdgeInsetsDirectional(methodName, expr.argumentList,
          offset: expr.offset);
    }

    // Duration(milliseconds: 300) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Duration') {
      return _convertDuration(expr);
    }

    // BorderRadius.xxx(...) — parses as MethodInvocation with target 'BorderRadius'
    if (target is SimpleIdentifier && target.name == 'BorderRadius') {
      return _convertBorderRadius(methodName, expr.argumentList,
          offset: expr.offset);
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

    // TextStyle(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'TextStyle') {
      return _convertTextStyle(expr.argumentList);
    }

    // BoxDecoration(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'BoxDecoration') {
      return _convertBoxDecoration(expr.argumentList);
    }

    // Alignment(x, y) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Alignment') {
      return _convertAlignment(expr.argumentList);
    }

    // IconThemeData(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'IconThemeData') {
      return _convertIconThemeData(expr.argumentList);
    }

    // LinearGradient(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'LinearGradient') {
      return _convertLinearGradient(expr.argumentList);
    }

    // RadialGradient(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'RadialGradient') {
      return _convertRadialGradient(expr.argumentList);
    }

    // SweepGradient(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'SweepGradient') {
      return _convertSweepGradient(expr.argumentList);
    }

    // BoxShadow(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'BoxShadow') {
      return _convertBoxShadow(expr.argumentList);
    }

    // Offset(x, y) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Offset') {
      return _convertOffset(expr.argumentList);
    }

    // BorderSide(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'BorderSide') {
      return _convertBorderSide(expr.argumentList);
    }

    // BoxConstraints.xxx(...) — parses as MethodInvocation with target 'BoxConstraints'
    if (target is SimpleIdentifier && target.name == 'BoxConstraints') {
      return _convertBoxConstraintsNamed(methodName, expr.argumentList,
          offset: expr.offset);
    }

    // Border.all(...) — parses as MethodInvocation with target 'Border'
    if (target is SimpleIdentifier && target.name == 'Border') {
      if (methodName == 'all') return _convertBorderAll(expr.argumentList);
    }

    // Border(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'Border') {
      return _convertBorder(expr.argumentList);
    }

    // VisualDensity(horizontal: ..., vertical: ...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'VisualDensity') {
      return _convertVisualDensity(expr.argumentList);
    }

    // RoundedRectangleBorder/CircleBorder/StadiumBorder(...) — ShapeBorder types
    if (target == null &&
        const {'RoundedRectangleBorder', 'CircleBorder', 'StadiumBorder'}
            .contains(methodName)) {
      return _convertShapeBorder(methodName, expr.argumentList);
    }

    // BoxConstraints(...) — parses as MethodInvocation with no target
    if (target == null && methodName == 'BoxConstraints') {
      return _convertBoxConstraints(expr.argumentList);
    }

    throw UnsupportedExpressionError(
      'Unsupported method invocation: $methodName',
      offset: expr.offset,
      code: RfwGenIssueCode.unsupportedMethodInvocation,
    );
  }

  /// Routes [InstanceCreationExpression] (produced by `const` constructors)
  /// to the same conversion logic used for [MethodInvocation].
  ///
  /// Without type resolution, the analyzer represents named constructors
  /// like `const EdgeInsets.all(16.0)` as:
  /// - `importPrefix` = "EdgeInsets", `typeName` = "all", `constructorName` = null
  /// So we check `importPrefix` to reconstruct the real class + constructor.
  IrValue _convertInstanceCreation(InstanceCreationExpression expr) {
    final rawTypeName = expr.constructorName.type.name.lexeme;
    final rawConstructorName = expr.constructorName.name?.name;
    final importPrefix = expr.constructorName.type.importPrefix?.name.lexeme;
    final argList = expr.argumentList;

    // Reconstruct real class name and constructor name.
    // Without resolution: `const EdgeInsets.all(16)` → prefix="EdgeInsets", type="all"
    // With resolution or no prefix: `const Color(0xFF)` → prefix=null, type="Color"
    final String className;
    final String? constructorName;
    if (importPrefix != null && _isKnownClassName(importPrefix)) {
      className = importPrefix;
      constructorName = rawTypeName; // e.g., "all", "circular", "symmetric"
    } else {
      className = rawTypeName;
      constructorName = rawConstructorName;
    }

    // Named constructors (e.g., EdgeInsets.all, BorderRadius.circular)
    if (constructorName != null) {
      return switch (className) {
        'EdgeInsets' =>
          _convertEdgeInsets(constructorName, argList, offset: expr.offset),
        'EdgeInsetsDirectional' => _convertEdgeInsetsDirectional(
            constructorName, argList,
            offset: expr.offset),
        'BorderRadius' =>
          _convertBorderRadius(constructorName, argList, offset: expr.offset),
        'Radius' when constructorName == 'circular' =>
          IrMapValue({'x': IrNumberValue(_toDouble(argList.arguments.first))}),
        'Border' when constructorName == 'all' => _convertBorderAll(argList),
        'BoxConstraints' => _convertBoxConstraintsNamed(
            constructorName, argList,
            offset: expr.offset),
        _ => throw UnsupportedExpressionError(
            'Unsupported const constructor: $className.$constructorName',
            offset: expr.offset,
            code: RfwGenIssueCode.unsupportedConstConstructor,
          ),
      };
    }

    // Default constructors (no named constructor)
    return switch (className) {
      'Color' => _convertColorFromArgs(argList),
      'Duration' => _convertDurationFromArgs(argList),
      'NetworkImage' => _convertImageProviderFromArgs(argList),
      'AssetImage' => _convertImageProviderFromArgs(argList),
      'TextStyle' => _convertTextStyle(argList),
      'BoxDecoration' => _convertBoxDecoration(argList),
      'Alignment' => _convertAlignment(argList),
      'IconThemeData' => _convertIconThemeData(argList),
      'LinearGradient' => _convertLinearGradient(argList),
      'RadialGradient' => _convertRadialGradient(argList),
      'SweepGradient' => _convertSweepGradient(argList),
      'BoxShadow' => _convertBoxShadow(argList),
      'Offset' => _convertOffset(argList),
      'BorderSide' => _convertBorderSide(argList),
      'Border' => _convertBorder(argList),
      'VisualDensity' => _convertVisualDensity(argList),
      'RoundedRectangleBorder' => _convertShapeBorder(className, argList),
      'CircleBorder' => _convertShapeBorder(className, argList),
      'StadiumBorder' => _convertShapeBorder(className, argList),
      'BoxConstraints' => _convertBoxConstraints(argList),
      _ when _knownGridDelegates.contains(className) =>
        _convertGridDelegateFromArgs(argList),
      _ => throw UnsupportedExpressionError(
          'Unsupported const constructor: $className',
          offset: expr.offset,
          code: RfwGenIssueCode.unsupportedConstConstructor,
        ),
    };
  }

  /// Known class names that appear as import prefixes in unresolved AST.
  bool _isKnownClassName(String name) {
    return const {
      'EdgeInsets',
      'EdgeInsetsDirectional',
      'BorderRadius',
      'Radius',
      'Border',
      'BoxConstraints',
    }.contains(name);
  }

  IrIntValue _convertColor(MethodInvocation expr) {
    return _convertColorFromArgs(expr.argumentList);
  }

  IrIntValue _convertColorFromArgs(ArgumentList argList) {
    final args = argList.arguments;
    if (args.length == 1) {
      final arg = args.first;
      if (arg is IntegerLiteral) {
        return IrIntValue(arg.value!);
      }
    }
    throw UnsupportedExpressionError(
      'Color constructor expects a single integer argument',
      offset: argList.offset,
      code: RfwGenIssueCode.colorInvalidConstructor,
    );
  }

  IrIntValue _convertColorFromARGB(ArgumentList argList) {
    final args = argList.arguments;
    if (args.length == 4) {
      final a = (args[0] as IntegerLiteral).value!;
      final r = (args[1] as IntegerLiteral).value!;
      final g = (args[2] as IntegerLiteral).value!;
      final b = (args[3] as IntegerLiteral).value!;
      return IrIntValue((a << 24) | (r << 16) | (g << 8) | b);
    }
    throw UnsupportedExpressionError(
      'Color.fromARGB requires 4 integer arguments',
      offset: argList.offset,
      code: RfwGenIssueCode.colorFromArgbInvalid,
    );
  }

  IrIntValue _convertColorFromRGBO(ArgumentList argList) {
    final args = argList.arguments;
    if (args.length == 4) {
      final r = (args[0] as IntegerLiteral).value!;
      final g = (args[1] as IntegerLiteral).value!;
      final b = (args[2] as IntegerLiteral).value!;
      final opacity = _toDouble(args[3]);
      final a = (opacity * 255).round();
      return IrIntValue((a << 24) | (r << 16) | (g << 8) | b);
    }
    throw UnsupportedExpressionError(
      'Color.fromRGBO requires 3 integers and 1 double',
      offset: argList.offset,
      code: RfwGenIssueCode.colorFromRgboInvalid,
    );
  }

  IrListValue _convertEdgeInsets(String method, ArgumentList argList,
      {int? offset}) {
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
          offset: offset,
          code: RfwGenIssueCode.edgeInsetsUnsupportedConstructor,
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

  IrListValue _convertEdgeInsetsDirectional(String method, ArgumentList argList,
      {int? offset}) {
    switch (method) {
      case 'all':
        return _convertEdgeInsetsAll(argList);
      case 'symmetric':
        return _convertEdgeInsetsSymmetric(argList);
      case 'only':
        return _convertEdgeInsetsDirectionalOnly(argList);
      case 'fromSTEB':
        return _convertEdgeInsetsFromLTRB(argList);
      default:
        throw UnsupportedExpressionError(
          'Unsupported EdgeInsetsDirectional constructor: $method',
          offset: offset,
          code: RfwGenIssueCode.edgeInsetsDirectionalUnsupported,
        );
    }
  }

  IrListValue _convertEdgeInsetsDirectionalOnly(ArgumentList argList) {
    double start = 0.0, top = 0.0, end = 0.0, bottom = 0.0;
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = _toDouble(arg.expression);
        switch (name) {
          case 'start':
            start = value;
          case 'top':
            top = value;
          case 'end':
            end = value;
          case 'bottom':
            bottom = value;
        }
      }
    }
    return IrListValue([
      IrNumberValue(start),
      IrNumberValue(top),
      IrNumberValue(end),
      IrNumberValue(bottom),
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
      return IrListValue([
        IrMapValue({'x': IrNumberValue(0.0)})
      ]);
    }

    if (prefix == 'RfwIcon') {
      return _convertRfwIcon(identifier, offset: expr.offset);
    }

    // Icons.xxx → auto-convert via RfwIcon lookup, then analyzer fallback
    if (prefix == 'Icons') {
      // Fast path: check hardcoded RfwIcon map
      final codepoint = RfwIcon.lookup(identifier);
      if (codepoint != null) {
        return IrMapValue({
          'icon': IrIntValue(codepoint),
          'fontFamily': IrStringValue('MaterialIcons'),
        });
      }
      // Fallback: resolve via Dart analyzer at build time
      final resolved = iconResolver?.resolve(identifier);
      if (resolved != null) {
        return IrMapValue({
          'icon': IrIntValue(resolved),
          'fontFamily': IrStringValue('MaterialIcons'),
        });
      }
      throw UnsupportedExpressionError(
        'Icons.$identifier could not be resolved. '
        'Ensure the icon name is correct and flutter/material.dart is imported.',
        offset: expr.offset,
        code: RfwGenIssueCode.iconNotResolved,
      );
    }

    // double.infinity is not supported in RFW
    if (prefix == 'double' && identifier == 'infinity') {
      throw UnsupportedExpressionError(
        'double.infinity is not supported in RFW. '
        'Use SizedBoxExpand to fill available space, or set a fixed size.',
        offset: expr.offset,
        code: RfwGenIssueCode.doubleInfinityUnsupported,
      );
    }

    if (prefix == 'Alignment') {
      return _convertAlignmentConstant(identifier, offset: expr.offset);
    }

    if (prefix == 'AlignmentDirectional') {
      return _convertAlignmentDirectionalConstant(identifier,
          offset: expr.offset);
    }

    throw UnsupportedExpressionError(
      'Unknown prefixed identifier: $prefix.$identifier',
      offset: expr.offset,
      code: RfwGenIssueCode.unknownPrefixedIdentifier,
    );
  }

  IrMapValue _convertRfwIcon(String name, {int? offset}) {
    final codepoint = RfwIcon.lookup(name);
    if (codepoint == null) {
      throw UnsupportedExpressionError('Unknown RfwIcon: $name',
          offset: offset, code: RfwGenIssueCode.rfwIconUnknown);
    }
    return IrMapValue({
      'icon': IrIntValue(codepoint),
      'fontFamily': IrStringValue('MaterialIcons'),
    });
  }

  static const _alignmentConstants = <String, List<double>>{
    'topLeft': [-1.0, -1.0],
    'topCenter': [0.0, -1.0],
    'topRight': [1.0, -1.0],
    'centerLeft': [-1.0, 0.0],
    'center': [0.0, 0.0],
    'centerRight': [1.0, 0.0],
    'bottomLeft': [-1.0, 1.0],
    'bottomCenter': [0.0, 1.0],
    'bottomRight': [1.0, 1.0],
  };

  IrMapValue _convertAlignmentConstant(String name, {int? offset}) {
    final values = _alignmentConstants[name];
    if (values != null) {
      return IrMapValue({
        'x': IrNumberValue(values[0]),
        'y': IrNumberValue(values[1]),
      });
    }
    throw UnsupportedExpressionError('Unknown Alignment constant: $name',
        offset: offset, code: RfwGenIssueCode.alignmentUnknownConstant);
  }

  static const _alignmentDirectionalConstants = <String, List<double>>{
    'topStart': [-1.0, -1.0],
    'topCenter': [0.0, -1.0],
    'topEnd': [1.0, -1.0],
    'centerStart': [-1.0, 0.0],
    'center': [0.0, 0.0],
    'centerEnd': [1.0, 0.0],
    'bottomStart': [-1.0, 1.0],
    'bottomCenter': [0.0, 1.0],
    'bottomEnd': [1.0, 1.0],
  };

  IrMapValue _convertAlignmentDirectionalConstant(String name, {int? offset}) {
    final values = _alignmentDirectionalConstants[name];
    if (values != null) {
      return IrMapValue({
        'start': IrNumberValue(values[0]),
        'y': IrNumberValue(values[1]),
      });
    }
    throw UnsupportedExpressionError(
      'Unknown AlignmentDirectional constant: $name',
      offset: offset,
      code: RfwGenIssueCode.alignmentDirectionalUnknown,
    );
  }

  IrIntValue _convertDuration(MethodInvocation expr) {
    return _convertDurationFromArgs(expr.argumentList);
  }

  IrIntValue _convertDurationFromArgs(ArgumentList argList) {
    int totalMs = 0;
    bool foundDurationArg = false;
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        final value = arg.expression;
        if (value is IntegerLiteral) {
          switch (name) {
            case 'milliseconds':
              totalMs += value.value!;
              foundDurationArg = true;
            case 'seconds':
              totalMs += value.value! * 1000;
              foundDurationArg = true;
            case 'minutes':
              totalMs += value.value! * 60000;
              foundDurationArg = true;
          }
        }
      }
    }
    if (foundDurationArg) return IrIntValue(totalMs);
    throw UnsupportedExpressionError(
      'Duration requires milliseconds, seconds, or minutes',
      offset: argList.offset,
      code: RfwGenIssueCode.durationInvalidArguments,
    );
  }

  IrListValue _convertBorderRadius(String method, ArgumentList argList,
      {int? offset}) {
    switch (method) {
      case 'circular':
        return _convertBorderRadiusCircular(argList);
      case 'all':
        return _convertBorderRadiusAll(argList);
      case 'only':
        return _convertBorderRadiusOnly(argList);
      default:
        throw UnsupportedExpressionError(
          'Unsupported BorderRadius constructor: $method',
          offset: offset,
          code: RfwGenIssueCode.borderRadiusUnsupported,
        );
    }
  }

  IrListValue _convertBorderRadiusAll(ArgumentList argList) {
    final radiusValue = _extractRadiusValue(argList.arguments.first);
    return IrListValue([
      IrMapValue({'x': IrNumberValue(radiusValue)})
    ]);
  }

  IrListValue _convertBorderRadiusCircular(ArgumentList argList) {
    final value = _toDouble(argList.arguments.first);
    return IrListValue([
      IrMapValue({'x': IrNumberValue(value)})
    ]);
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
    // MethodInvocation: Radius.circular(20) without const
    if (expr is MethodInvocation &&
        expr.target is SimpleIdentifier &&
        (expr.target as SimpleIdentifier).name == 'Radius' &&
        expr.methodName.name == 'circular') {
      return _toDouble(expr.argumentList.arguments.first);
    }
    // InstanceCreationExpression: const Radius.circular(20) or inside const context
    if (expr is InstanceCreationExpression &&
        expr.constructorName.type.name.lexeme == 'Radius' &&
        expr.constructorName.name?.name == 'circular') {
      return _toDouble(expr.argumentList.arguments.first);
    }
    throw UnsupportedExpressionError(
      'Expected Radius.circular(), got ${expr.runtimeType}',
      offset: expr.offset,
      code: RfwGenIssueCode.radiusExpectedCircular,
    );
  }

  IrMapValue _convertImageProvider(MethodInvocation expr) {
    return _convertImageProviderFromArgs(expr.argumentList);
  }

  IrMapValue _convertImageProviderFromArgs(ArgumentList argList) {
    IrValue? source;
    double scale = 1.0;
    for (final arg in argList.arguments) {
      if (arg is SimpleStringLiteral) {
        source = IrStringValue(arg.value);
      } else if (arg is NamedExpression && arg.name.label.name == 'scale') {
        scale = _toDouble(arg.expression);
      } else if (arg is! NamedExpression && source == null) {
        // Dynamic source (e.g., product['image'] → LoopVarRef/DataRef).
        source = convert(arg);
      }
    }
    if (source == null) {
      throw UnsupportedExpressionError(
        'ImageProvider requires a source argument',
        offset: argList.offset,
        code: RfwGenIssueCode.imageProviderMissingSource,
      );
    }
    return IrMapValue({
      'source': source,
      'scale': IrNumberValue(scale),
    });
  }

  IrMapValue _convertGridDelegate(MethodInvocation expr) {
    return _convertGridDelegateFromArgs(expr.argumentList);
  }

  IrMapValue _convertGridDelegateFromArgs(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        entries[name] = convert(arg.expression);
      }
    }
    return IrMapValue(entries);
  }

  // ---------------------------------------------------------------------------
  // Complex type converters (TextStyle, BoxDecoration, Alignment, etc.)
  // ---------------------------------------------------------------------------

  /// Known TextStyle font weight values mapped to rfwtxt strings.
  static const _fontWeightMap = <String, String>{
    'w100': 'w100',
    'w200': 'w200',
    'w300': 'w300',
    'w400': 'w400',
    'w500': 'w500',
    'w600': 'w600',
    'w700': 'w700',
    'w800': 'w800',
    'w900': 'w900',
    'normal': 'normal',
    'bold': 'bold',
  };

  /// Converts `TextStyle(fontSize: 24.0, color: Color(...), ...)` to IrMapValue.
  IrMapValue _convertTextStyle(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'fontSize':
          case 'letterSpacing':
          case 'wordSpacing':
          case 'height':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          case 'color':
          case 'decorationColor':
            entries[name] = convert(arg.expression);
          case 'fontWeight':
            entries[name] = _convertFontEnum(arg.expression, _fontWeightMap);
          case 'fontStyle':
            entries[name] = _convertFontEnum(arg.expression, const {
              'normal': 'normal',
              'italic': 'italic',
            });
          case 'fontFamily':
            entries[name] = convert(arg.expression);
          case 'decoration':
            entries[name] = _convertTextDecorationEnum(arg.expression);
          case 'decorationStyle':
            entries[name] = _convertFontEnum(arg.expression, const {
              'solid': 'solid',
              'double': 'double',
              'dotted': 'dotted',
              'dashed': 'dashed',
              'wavy': 'wavy',
            });
          case 'overflow':
            entries[name] = _convertFontEnum(arg.expression, const {
              'clip': 'clip',
              'fade': 'fade',
              'ellipsis': 'ellipsis',
              'visible': 'visible',
            });
          default:
            entries[name] = convert(arg.expression);
        }
      }
    }
    return IrMapValue(entries);
  }

  IrStringValue _convertFontEnum(Expression expr, Map<String, String> map) {
    if (expr is PrefixedIdentifier) {
      final id = expr.identifier.name;
      if (map.containsKey(id)) return IrStringValue(map[id]!);
    }
    throw UnsupportedExpressionError(
      'Unknown enum value: $expr',
      offset: expr.offset,
      code: RfwGenIssueCode.enumValueUnknown,
    );
  }

  IrStringValue _convertTextDecorationEnum(Expression expr) {
    if (expr is PrefixedIdentifier) {
      final id = expr.identifier.name;
      const known = {
        'none': 'none',
        'underline': 'underline',
        'overline': 'overline',
        'lineThrough': 'lineThrough',
      };
      if (known.containsKey(id)) return IrStringValue(known[id]!);
    }
    throw UnsupportedExpressionError(
      'Unknown TextDecoration: $expr',
      offset: expr.offset,
      code: RfwGenIssueCode.textDecorationUnknown,
    );
  }

  /// Converts `BoxDecoration(color: ..., gradient: ..., borderRadius: ..., boxShadow: [...])`.
  IrMapValue _convertBoxDecoration(ArgumentList argList) {
    final entries = <String, IrValue>{'type': IrStringValue('box')};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'color':
          case 'gradient':
          case 'borderRadius':
          case 'border':
            entries[name] = convert(arg.expression);
          case 'boxShadow':
            // List of BoxShadow
            if (arg.expression is ListLiteral) {
              final list = arg.expression as ListLiteral;
              entries[name] = IrListValue(
                list.elements.map((e) => convert(e as Expression)).toList(),
              );
            } else {
              entries[name] = convert(arg.expression);
            }
          case 'shape':
            if (arg.expression is PrefixedIdentifier) {
              final id = (arg.expression as PrefixedIdentifier).identifier.name;
              entries[name] = IrStringValue(id);
            } else {
              entries[name] = convert(arg.expression);
            }
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `BoxConstraints(minWidth: ..., maxWidth: ..., ...)` to IrMapValue.
  ///
  /// Only includes params that are explicitly provided.
  /// RFW runtime defaults: minWidth=0.0, maxWidth=infinity,
  /// minHeight=0.0, maxHeight=infinity.
  IrMapValue _convertBoxConstraints(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'minWidth':
          case 'maxWidth':
          case 'minHeight':
          case 'maxHeight':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts named BoxConstraints constructors to IrMapValue.
  ///
  /// Supported: `.tight(Size)`, `.loose(Size)`, `.tightFor(width:, height:)`,
  /// `.expand(width:, height:)`.
  IrMapValue _convertBoxConstraintsNamed(
    String constructorName,
    ArgumentList argList, {
    required int? offset,
  }) {
    switch (constructorName) {
      case 'tight':
        final sizeArgs = _extractSizeArgs(argList, offset: offset);
        return IrMapValue({
          'minWidth': IrNumberValue(sizeArgs.$1),
          'maxWidth': IrNumberValue(sizeArgs.$1),
          'minHeight': IrNumberValue(sizeArgs.$2),
          'maxHeight': IrNumberValue(sizeArgs.$2),
        });
      case 'loose':
        final sizeArgs = _extractSizeArgs(argList, offset: offset);
        return IrMapValue({
          'maxWidth': IrNumberValue(sizeArgs.$1),
          'maxHeight': IrNumberValue(sizeArgs.$2),
        });
      case 'tightFor':
        final entries = <String, IrValue>{};
        for (final arg in argList.arguments) {
          if (arg is NamedExpression) {
            final name = arg.name.label.name;
            final value = IrNumberValue(_toDouble(arg.expression));
            if (name == 'width') {
              entries['minWidth'] = value;
              entries['maxWidth'] = value;
            } else if (name == 'height') {
              entries['minHeight'] = value;
              entries['maxHeight'] = value;
            }
          }
        }
        return IrMapValue(entries);
      case 'expand':
        final entries = <String, IrValue>{};
        for (final arg in argList.arguments) {
          if (arg is NamedExpression) {
            final name = arg.name.label.name;
            final value = IrNumberValue(_toDouble(arg.expression));
            if (name == 'width') {
              entries['minWidth'] = value;
              entries['maxWidth'] = value;
            } else if (name == 'height') {
              entries['minHeight'] = value;
              entries['maxHeight'] = value;
            }
          }
        }
        return IrMapValue(entries);
      default:
        throw UnsupportedExpressionError(
          'Unsupported BoxConstraints constructor: BoxConstraints.$constructorName',
          offset: offset,
          code: RfwGenIssueCode.boxConstraintsUnsupportedConstructor,
        );
    }
  }

  /// Extracts (width, height) from a Size(w, h) positional argument.
  (double, double) _extractSizeArgs(
    ArgumentList argList, {
    required int? offset,
  }) {
    final args = argList.arguments;
    if (args.length != 1) {
      throw UnsupportedExpressionError(
        'BoxConstraints.tight/loose expects exactly one Size argument',
        offset: offset,
        code: RfwGenIssueCode.boxConstraintsTightLooseInvalid,
      );
    }
    final sizeExpr = args.first;
    // Handle: BoxConstraints.tight(Size(100.0, 200.0))
    if (sizeExpr is MethodInvocation && sizeExpr.methodName.name == 'Size') {
      final sizeArgs = sizeExpr.argumentList.arguments;
      if (sizeArgs.length == 2) {
        return (_toDouble(sizeArgs[0]), _toDouble(sizeArgs[1]));
      }
    }
    // Handle: const BoxConstraints.tight(Size(100.0, 200.0))
    if (sizeExpr is InstanceCreationExpression) {
      final typeName = sizeExpr.constructorName.type.name.lexeme;
      if (typeName == 'Size') {
        final sizeArgs = sizeExpr.argumentList.arguments;
        if (sizeArgs.length == 2) {
          return (_toDouble(sizeArgs[0]), _toDouble(sizeArgs[1]));
        }
      }
    }
    throw UnsupportedExpressionError(
      'Expected Size(width, height) argument',
      offset: offset,
      code: RfwGenIssueCode.sizeInvalidArguments,
    );
  }

  /// Converts `Alignment(x, y)` to `{x: double, y: double}`.
  IrMapValue _convertAlignment(ArgumentList argList) {
    final args = argList.arguments;
    if (args.length >= 2) {
      return IrMapValue({
        'x': IrNumberValue(_toDouble(args[0])),
        'y': IrNumberValue(_toDouble(args[1])),
      });
    }
    throw UnsupportedExpressionError(
      'Alignment requires two positional arguments (x, y)',
      offset: argList.offset,
      code: RfwGenIssueCode.alignmentInvalidArguments,
    );
  }

  /// Converts `IconThemeData(color: ..., size: ...)`.
  IrMapValue _convertIconThemeData(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'color':
            entries[name] = convert(arg.expression);
          case 'size':
          case 'opacity':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          default:
            entries[name] = convert(arg.expression);
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `LinearGradient(begin: ..., end: ..., colors: [...], stops: [...])`.
  IrMapValue _convertLinearGradient(ArgumentList argList) {
    final entries = <String, IrValue>{'type': IrStringValue('linear')};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'begin':
          case 'end':
            entries[name] = convert(arg.expression);
          case 'colors':
            if (arg.expression is ListLiteral) {
              final list = arg.expression as ListLiteral;
              entries[name] = IrListValue(
                list.elements.map((e) => convert(e as Expression)).toList(),
              );
            } else {
              entries[name] = convert(arg.expression);
            }
          case 'stops':
            if (arg.expression is ListLiteral) {
              final list = arg.expression as ListLiteral;
              entries[name] = IrListValue(
                list.elements.map((e) => convert(e as Expression)).toList(),
              );
            } else {
              entries[name] = convert(arg.expression);
            }
          case 'tileMode':
            if (arg.expression is PrefixedIdentifier) {
              final id = (arg.expression as PrefixedIdentifier).identifier.name;
              entries[name] = IrStringValue(id);
            } else {
              entries[name] = convert(arg.expression);
            }
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `RadialGradient(center: ..., radius: ..., colors: [...])`.
  IrMapValue _convertRadialGradient(ArgumentList argList) {
    final entries = <String, IrValue>{'type': IrStringValue('radial')};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'center':
            entries[name] = convert(arg.expression);
          case 'radius':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          case 'colors':
          case 'stops':
            if (arg.expression is ListLiteral) {
              final list = arg.expression as ListLiteral;
              entries[name] = IrListValue(
                list.elements.map((e) => convert(e as Expression)).toList(),
              );
            } else {
              entries[name] = convert(arg.expression);
            }
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `SweepGradient(center: ..., startAngle: ..., endAngle: ..., colors: [...])`.
  IrMapValue _convertSweepGradient(ArgumentList argList) {
    final entries = <String, IrValue>{'type': IrStringValue('sweep')};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'center':
            entries[name] = convert(arg.expression);
          case 'startAngle':
          case 'endAngle':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          case 'colors':
          case 'stops':
            if (arg.expression is ListLiteral) {
              final list = arg.expression as ListLiteral;
              entries[name] = IrListValue(
                list.elements.map((e) => convert(e as Expression)).toList(),
              );
            } else {
              entries[name] = convert(arg.expression);
            }
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `BoxShadow(color: ..., blurRadius: ..., offset: Offset(...))`.
  IrMapValue _convertBoxShadow(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'color':
            entries[name] = convert(arg.expression);
          case 'blurRadius':
          case 'spreadRadius':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          case 'offset':
            entries[name] = convert(arg.expression);
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `Offset(x, y)` to `{x: double, y: double}`.
  IrMapValue _convertOffset(ArgumentList argList) {
    final args = argList.arguments;
    if (args.length >= 2) {
      return IrMapValue({
        'x': IrNumberValue(_toDouble(args[0])),
        'y': IrNumberValue(_toDouble(args[1])),
      });
    }
    throw UnsupportedExpressionError(
      'Offset requires two positional arguments (x, y)',
      offset: argList.offset,
      code: RfwGenIssueCode.offsetInvalidArguments,
    );
  }

  IrMapValue _convertVisualDensity(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'horizontal' || name == 'vertical') {
          entries[name] = IrNumberValue(_toDouble(arg.expression));
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts a handler expression to an IR handler value.
  ///
  /// Returns null for empty function literals (`() {}` or `() => null`),
  /// which are silently skipped — they are no-op handlers used as placeholders
  /// in Flutter but have no RFW equivalent.
  IrValue? convertHandler(Expression expr) {
    // Empty function literal — silently skip (no-op placeholder handler).
    if (_isEmptyFunctionLiteral(expr)) return null;

    if (expr is! MethodInvocation) {
      throw UnsupportedExpressionError(
        'Handler must be RfwHandler.setState/setStateFromArg/event',
        offset: expr.offset,
        code: RfwGenIssueCode.handlerInvalidExpression,
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
      'Unsupported handler expression: $methodName. '
      'RFW handlers only support RfwHandler.setState, '
      'RfwHandler.setStateFromArg, and RfwHandler.event. '
      'RfwSwitchValue/RfwSwitch cannot be used in handler positions — '
      'use RfwSwitch to swap entire widgets with different handlers instead.',
      offset: expr.offset,
      code: RfwGenIssueCode.handlerUnsupportedMethod,
    );
  }

  /// Returns true if [expr] is an empty function literal that should be
  /// silently skipped as a handler.
  ///
  /// Matches:
  /// - `() {}` — empty block body
  /// - `(_) {}` — empty block body with ignored parameter
  /// - `() => null` — expression body returning null
  bool _isEmptyFunctionLiteral(Expression expr) {
    if (expr is! FunctionExpression) return false;
    final body = expr.body;
    if (body is BlockFunctionBody) {
      return body.block.statements.isEmpty;
    }
    if (body is ExpressionFunctionBody) {
      return body.expression is NullLiteral;
    }
    return false;
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

  IrMapValue _convertMapLiteral(SetOrMapLiteral expr) {
    final entries = <String, IrValue>{};
    for (final element in expr.elements) {
      if (element is MapLiteralEntry) {
        final key = element.key;
        final keyStr = key is SimpleStringLiteral ? key.value : key.toString();
        entries[keyStr] = convert(element.value);
      }
      // Non-MapLiteralEntry elements (Set literals) are skipped safely
    }
    return IrMapValue(entries);
  }

  IrValue _convertDynamicRef(String refType, MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    if (args.length == 1 && args.first is SimpleStringLiteral) {
      final path = (args.first as SimpleStringLiteral).value;
      // Warn if DataRef path starts with a known loop variable name
      if (refType == 'DataRef' && loopVarNames.isNotEmpty) {
        final firstSegment = path.split('.').first;
        if (loopVarNames.contains(firstSegment)) {
          final suggestion = path.length > firstSegment.length + 1
              ? "Use $firstSegment['${path.substring(firstSegment.length + 1)}'] instead."
              : "Use $firstSegment directly instead of DataRef('$firstSegment').";
          onWarning?.call(
            "'$firstSegment' is a loop variable — "
            "DataRef('$path') generates data.$path which is incorrect. "
            "$suggestion",
            offset: expr.offset,
            code: RfwGenIssueCode.loopVariableMisuse,
          );
        }
      }
      return switch (refType) {
        'DataRef' => IrDataRef(path),
        'ArgsRef' => IrArgsRef(path),
        'StateRef' => IrStateRef(path),
        _ => throw UnsupportedExpressionError('Unknown ref type: $refType',
            offset: expr.offset, code: RfwGenIssueCode.unknownRefType),
      };
    }
    throw UnsupportedExpressionError(
      '$refType requires a single string argument',
      offset: expr.offset,
      code: RfwGenIssueCode.refInvalidArgument,
    );
  }

  IrConcat _convertConcat(MethodInvocation expr) {
    final args = expr.argumentList.arguments;
    if (args.length == 1 && args.first is ListLiteral) {
      final list = args.first as ListLiteral;
      final parts = list.elements.map((e) => convert(e as Expression)).toList();
      return IrConcat(parts);
    }
    throw UnsupportedExpressionError(
      'RfwConcat requires a single list argument',
      offset: expr.offset,
      code: RfwGenIssueCode.rfwConcatInvalidArgument,
    );
  }

  IrSwitchExpr _convertSwitchValue(MethodInvocation expr) {
    IrValue? value;
    final cases = <IrValue, IrValue>{};
    IrValue? defaultCase;

    for (final arg in expr.argumentList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (name == 'value') {
          value = convert(arg.expression);
        } else if (name == 'cases') {
          if (arg.expression is SetOrMapLiteral) {
            for (final entry in (arg.expression as SetOrMapLiteral).elements) {
              if (entry is MapLiteralEntry) {
                cases[convert(entry.key)] = convert(entry.value);
              }
            }
          }
        } else if (name == 'defaultCase') {
          defaultCase = convert(arg.expression);
        }
      }
    }

    if (value == null) {
      throw UnsupportedExpressionError(
        'RfwSwitchValue requires a value parameter',
        offset: expr.offset,
        code: RfwGenIssueCode.rfwSwitchValueMissingValue,
      );
    }

    return IrSwitchExpr(value: value, cases: cases, defaultCase: defaultCase);
  }

  IrValue _convertIndexExpression(IndexExpression expr) {
    // Build the path by walking the chain: item['a']['b'] -> 'item.a.b'
    final parts = <String>[];
    Expression current = expr;
    while (current is IndexExpression) {
      if (current.index is SimpleStringLiteral) {
        parts.insert(0, (current.index as SimpleStringLiteral).value);
      }
      current = current.target!;
    }
    // The base should be a SimpleIdentifier (the loop var name)
    if (current is SimpleIdentifier) {
      parts.insert(0, current.name);
      return IrLoopVarRef(parts.join('.'));
    }
    throw UnsupportedExpressionError(
      'Unsupported index expression base: ${current.runtimeType}',
      offset: expr.offset,
      code: RfwGenIssueCode.unsupportedIndexExpression,
    );
  }

  // ---------------------------------------------------------------------------
  // Border / BorderSide converters
  // ---------------------------------------------------------------------------

  /// Converts `BorderSide(color: ..., width: ..., style: ...)` to IrMapValue.
  IrMapValue _convertBorderSide(ArgumentList argList) {
    final entries = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'color':
            entries[name] = convert(arg.expression);
          case 'width':
            entries[name] = IrNumberValue(_toDouble(arg.expression));
          case 'style':
            if (arg.expression is PrefixedIdentifier) {
              entries[name] = IrStringValue(
                (arg.expression as PrefixedIdentifier).identifier.name,
              );
            }
          default:
            entries[name] = convert(arg.expression);
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Converts `Border.all({color, width, style})` to 4 identical sides.
  IrMapValue _convertBorderAll(ArgumentList argList) {
    final side = _convertBorderSide(argList);
    return IrMapValue({
      'type': IrStringValue('box'),
      'sides': IrListValue([side, side, side, side]),
    });
  }

  /// Converts `Border(top: ..., right: ..., bottom: ..., left: ...)`.
  IrMapValue _convertBorder(ArgumentList argList) {
    final sides = <String, IrValue>{};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        if (['top', 'right', 'bottom', 'left'].contains(name)) {
          sides[name] = convert(arg.expression);
        }
      }
    }
    // Build [top, right, bottom, left] list
    final defaultSide = IrMapValue({});
    return IrMapValue({
      'type': IrStringValue('box'),
      'sides': IrListValue([
        sides['top'] ?? defaultSide,
        sides['right'] ?? defaultSide,
        sides['bottom'] ?? defaultSide,
        sides['left'] ?? defaultSide,
      ]),
    });
  }

  /// Converts `RoundedRectangleBorder(side: ..., borderRadius: ...)`,
  /// `CircleBorder(side: ...)`, and `StadiumBorder(side: ...)`.
  IrMapValue _convertShapeBorder(String className, ArgumentList argList) {
    final type = switch (className) {
      'RoundedRectangleBorder' => 'rounded',
      'CircleBorder' => 'circle',
      'StadiumBorder' => 'stadium',
      _ => throw UnsupportedExpressionError(
          'Unsupported ShapeBorder: $className',
          offset: argList.offset,
          code: RfwGenIssueCode.shapeBorderUnsupported,
        ),
    };
    final entries = <String, IrValue>{'type': IrStringValue(type)};
    for (final arg in argList.arguments) {
      if (arg is NamedExpression) {
        final name = arg.name.label.name;
        switch (name) {
          case 'side':
            entries[name] = convert(arg.expression);
          case 'borderRadius':
            entries[name] = convert(arg.expression);
        }
      }
    }
    return IrMapValue(entries);
  }

  /// Extracts a double value from a numeric expression.
  /// Converts int literals to double for EdgeInsets consistency.
  /// Handles negative values (PrefixExpression with '-').
  double _toDouble(Expression expr) {
    if (expr is DoubleLiteral) return expr.value;
    if (expr is IntegerLiteral) return expr.value!.toDouble();
    if (expr is PrefixExpression && expr.operator.lexeme == '-') {
      return -_toDouble(expr.operand);
    }
    throw UnsupportedExpressionError(
      'Expected numeric literal, got ${expr.runtimeType}',
      offset: expr.offset,
      code: RfwGenIssueCode.numericLiteralExpected,
    );
  }
}
