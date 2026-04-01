/// Severity level for code generation diagnostics.
enum RfwGenSeverity {
  /// A fatal error that prevents code generation.
  fatal,

  /// A non-fatal warning that may indicate a potential problem.
  warning,
}

/// Machine-readable error codes for programmatic handling.
///
/// Each code corresponds to a specific category of issue that can occur
/// during @RfwWidget conversion. MCP servers and IDE integrations can
/// use these codes to provide targeted suggestions and auto-fixes.
enum RfwGenIssueCode {
  // ── Widget Resolution ──
  /// Widget expression is not a MethodInvocation.
  widgetNotMethodInvocation,

  /// DataRef/ArgsRef/StateRef/RfwConcat/RfwSwitchValue used in widget position.
  helperUsedAsWidget,

  /// Widget name not found in WidgetRegistry.
  widgetNotRegistered,

  // ── Expression Type ──
  /// Dart expression type not supported for RFW conversion.
  unsupportedExpression,

  /// Prefix expression (e.g., `!value`) not supported.
  unsupportedPrefixExpression,

  /// Method invocation not supported in this context.
  unsupportedMethodInvocation,

  /// Const constructor not supported for RFW conversion.
  unsupportedConstConstructor,

  /// Index expression base type not supported.
  unsupportedIndexExpression,

  // ── Color ──
  /// Color() expects a single integer argument.
  colorInvalidConstructor,

  /// Color.fromARGB() requires 4 integer arguments.
  colorFromArgbInvalid,

  /// Color.fromRGBO() requires 3 integers + 1 double.
  colorFromRgboInvalid,

  // ── EdgeInsets ──
  /// Unsupported EdgeInsets constructor variant.
  edgeInsetsUnsupportedConstructor,

  /// Unsupported EdgeInsetsDirectional constructor variant.
  edgeInsetsDirectionalUnsupported,

  // ── BoxConstraints ──
  /// Unsupported BoxConstraints constructor variant.
  boxConstraintsUnsupportedConstructor,

  /// BoxConstraints.tight/loose expects Size argument.
  boxConstraintsTightLooseInvalid,

  /// Size() expects (width, height) arguments.
  sizeInvalidArguments,

  // ── Alignment ──
  /// Alignment() requires two positional arguments.
  alignmentInvalidArguments,

  /// Unknown Alignment constant (e.g., Alignment.xyz).
  alignmentUnknownConstant,

  /// Unknown AlignmentDirectional constant.
  alignmentDirectionalUnknown,

  // ── Other Constructors ──
  /// Offset() requires two positional arguments.
  offsetInvalidArguments,

  /// Duration requires milliseconds/seconds/minutes named argument.
  durationInvalidArguments,

  /// Unsupported BorderRadius constructor variant.
  borderRadiusUnsupported,

  /// Expected Radius.circular() constructor.
  radiusExpectedCircular,

  /// ImageProvider requires source argument.
  imageProviderMissingSource,

  // ── Identifiers & Constants ──
  /// Icons.xxx could not be resolved to a codepoint.
  iconNotResolved,

  /// Unknown RfwIcon name.
  rfwIconUnknown,

  /// double.infinity not supported in RFW.
  doubleInfinityUnsupported,

  /// Unknown prefixed identifier (e.g., Foo.bar).
  unknownPrefixedIdentifier,

  /// Unknown enum value.
  enumValueUnknown,

  /// Unknown TextDecoration value.
  textDecorationUnknown,

  /// Unsupported ShapeBorder variant.
  shapeBorderUnsupported,

  /// Expected numeric literal.
  numericLiteralExpected,

  // ── Handler ──
  /// Handler position requires RfwHandler.setState/setStateFromArg/event.
  handlerInvalidExpression,

  /// Unsupported handler method.
  handlerUnsupportedMethod,

  // ── Dynamic References ──
  /// Unknown reference type (not DataRef/ArgsRef/StateRef).
  unknownRefType,

  /// Reference requires a single string argument.
  refInvalidArgument,

  /// DataRef used with loop variable name — use item['field'] instead.
  loopVariableMisuse,

  // ── Special Constructs ──
  /// RfwFor missing required parameters (items/itemName/builder).
  rfwForMissingParameters,

  /// RfwSwitch missing required value parameter.
  rfwSwitchMissingValue,

  /// RfwConcat requires a single list argument.
  rfwConcatInvalidArgument,

  /// RfwSwitchValue missing required value parameter.
  rfwSwitchValueMissingValue,

  // ── Structural ──
  /// No return expression found in @RfwWidget function body.
  functionNoReturn,

  /// No FunctionDeclaration found in source.
  sourceNoFunction,

  /// Cannot emit NaN or Infinity float values.
  invalidFloatValue,

  // ── State ──
  /// State field initial value could not be converted.
  stateFieldConversionFailed,
}

/// A single diagnostic issue reported during RFW code generation.
class RfwGenIssue {
  /// The severity of this issue.
  final RfwGenSeverity severity;

  /// Machine-readable error code for programmatic handling.
  final RfwGenIssueCode code;

  /// Human-readable description of the problem.
  final String message;

  /// Optional suggestion for how to fix the issue.
  final String? suggestion;

  /// Optional source line number where the issue was detected.
  final int? line;

  /// Optional source column number where the issue was detected.
  final int? column;

  /// Creates a diagnostic issue with the given [severity], [code], and [message].
  const RfwGenIssue({
    required this.severity,
    required this.code,
    required this.message,
    this.suggestion,
    this.line,
    this.column,
  });

  /// Whether this issue is fatal and blocks code generation.
  bool get isFatal => severity == RfwGenSeverity.fatal;

  @override
  String toString() {
    final buffer = StringBuffer('[rfw_gen] ');
    buffer.write(isFatal ? 'Error' : 'Warning');
    buffer.write(' ${code.name}');
    if (line != null) {
      if (column != null) {
        buffer.write(' (line $line, col $column)');
      } else {
        buffer.write(' (line $line)');
      }
    }
    buffer.write(': $message');
    if (suggestion != null) buffer.write('\n  Suggestion: $suggestion');
    return buffer.toString();
  }
}

/// Exception thrown when RFW code generation encounters one or more issues.
///
/// Contains a list of [RfwGenIssue]s describing all problems found.
class RfwGenException implements Exception {
  /// The list of issues that caused this exception.
  final List<RfwGenIssue> issues;

  /// Creates an exception from the given [issues].
  const RfwGenException(this.issues);

  @override
  String toString() => issues.map((i) => i.toString()).join('\n');
}
