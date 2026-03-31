import 'package:rfw_gen/rfw_gen.dart';

import 'ir.dart';
import 'metadata_collector.dart';

/// The result of an RFW conversion, containing the generated rfwtxt output
/// and any diagnostic issues encountered during conversion.
class ConvertResult {
  /// The generated rfwtxt content, or null if fatal errors prevented generation.
  final String? rfwtxt;

  /// Diagnostic issues collected during conversion.
  final List<RfwGenIssue> issues;

  /// The widget name extracted from @RfwWidget annotation or function name.
  final String widgetName;

  /// The state declaration map from @RfwWidget(state: {...}), or null.
  final Map<String, IrValue>? stateDecl;

  /// Metadata collected from the IR tree (dataRefs, stateRefs, events).
  final RfwWidgetMetadata metadata;

  /// Creates a [ConvertResult] with the given fields.
  ConvertResult({
    required this.rfwtxt,
    required this.issues,
    required this.widgetName,
    required this.stateDecl,
    required this.metadata,
  });

  /// Whether any fatal issues were encountered during conversion.
  bool get hasErrors => issues.any((i) => i.isFatal);

  /// Whether any non-fatal warning issues were encountered during conversion.
  bool get hasWarnings => issues.any((i) => !i.isFatal);
}
