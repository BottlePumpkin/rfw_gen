enum RfwGenSeverity { fatal, warning }

class RfwGenIssue {
  final RfwGenSeverity severity;
  final String message;
  final String? suggestion;
  final int? line;

  const RfwGenIssue({
    required this.severity,
    required this.message,
    this.suggestion,
    this.line,
  });

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

class RfwGenException implements Exception {
  final List<RfwGenIssue> issues;
  const RfwGenException(this.issues);

  @override
  String toString() => issues.map((i) => i.toString()).join('\n');
}
