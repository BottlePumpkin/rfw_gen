import 'package:rfw_gen/rfw_gen.dart';

/// The result of an RFW conversion, containing the generated rfwtxt output
/// and any diagnostic issues encountered during conversion.
class ConvertResult {
  /// The generated rfwtxt content.
  final String rfwtxt;

  /// Diagnostic issues collected during conversion.
  final List<RfwGenIssue> issues;

  /// Creates a [ConvertResult] with the given [rfwtxt] and [issues].
  ConvertResult({required this.rfwtxt, required this.issues});

  /// Whether any fatal issues were encountered during conversion.
  bool get hasErrors => issues.any((i) => i.isFatal);

  /// Whether any non-fatal warning issues were encountered during conversion.
  bool get hasWarnings => issues.any((i) => !i.isFatal);
}
