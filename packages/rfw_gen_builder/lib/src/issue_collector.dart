import 'package:rfw_gen/rfw_gen.dart';

/// Accumulates [RfwGenIssue] instances during conversion, converting AST
/// offsets to line:column positions within the given [source].
class IssueCollector {
  /// The source code being analyzed, used for offset-to-line/column conversion.
  final String source;

  /// The list of issues accumulated so far.
  final List<RfwGenIssue> issues = [];

  /// Creates a collector for the given [source] text.
  IssueCollector(this.source);

  /// Records a [RfwGenSeverity.warning] issue.
  ///
  /// If [offset] is provided and valid, it is converted to a line and column.
  void warning(String message, {int? offset, String? suggestion}) {
    _add(RfwGenSeverity.warning, message, offset: offset, suggestion: suggestion);
  }

  /// Records a [RfwGenSeverity.fatal] issue.
  ///
  /// If [offset] is provided and valid, it is converted to a line and column.
  void fatal(String message, {int? offset, String? suggestion}) {
    _add(RfwGenSeverity.fatal, message, offset: offset, suggestion: suggestion);
  }

  /// Whether any of the accumulated issues are fatal.
  bool get hasFatal => issues.any((i) => i.isFatal);

  /// Whether any issues have been accumulated.
  bool get hasIssues => issues.isNotEmpty;

  void _add(
    RfwGenSeverity severity,
    String message, {
    int? offset,
    String? suggestion,
  }) {
    int? line;
    int? column;
    if (offset != null && source.isNotEmpty && offset < source.length) {
      final pos = _offsetToLineColumn(offset);
      line = pos.line;
      column = pos.column;
    }
    issues.add(RfwGenIssue(
      severity: severity,
      message: message,
      suggestion: suggestion,
      line: line,
      column: column,
    ));
  }

  ({int line, int column}) _offsetToLineColumn(int offset) {
    final before = source.substring(0, offset);
    final line = '\n'.allMatches(before).length + 1;
    final lastNewline = before.lastIndexOf('\n');
    final column = lastNewline == -1 ? offset + 1 : offset - lastNewline;
    return (line: line, column: column);
  }
}
