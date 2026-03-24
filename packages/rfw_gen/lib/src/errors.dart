/// Severity level for code generation diagnostics.
enum RfwGenSeverity {
  /// A fatal error that prevents code generation.
  fatal,

  /// A non-fatal warning that may indicate a potential problem.
  warning,
}

/// A single diagnostic issue reported during RFW code generation.
class RfwGenIssue {
  /// The severity of this issue.
  final RfwGenSeverity severity;

  /// Human-readable description of the problem.
  final String message;

  /// Optional suggestion for how to fix the issue.
  final String? suggestion;

  /// Optional source line number where the issue was detected.
  final int? line;

  /// Creates a diagnostic issue with the given [severity] and [message].
  const RfwGenIssue({
    required this.severity,
    required this.message,
    this.suggestion,
    this.line,
  });

  /// Whether this issue is fatal and blocks code generation.
  bool get isFatal => severity == RfwGenSeverity.fatal;

  @override
  String toString() {
    final buffer = StringBuffer('[rfw_gen] ');
    buffer.write(isFatal ? 'Error' : 'Warning');
    if (line != null) buffer.write(' (line $line)');
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
