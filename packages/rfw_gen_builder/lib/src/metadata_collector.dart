import 'ir.dart';

/// Metadata extracted from an IR widget tree for a single @RfwWidget function.
class RfwWidgetMetadata {
  /// Unique DataRef paths used in the widget tree.
  final Set<String> dataRefs;

  /// Unique StateRef paths and setState/setStateFromArg fields.
  final Set<String> stateRefs;

  /// Unique event names dispatched via RfwHandler.event().
  final Set<String> events;

  const RfwWidgetMetadata({
    required this.dataRefs,
    required this.stateRefs,
    required this.events,
  });
}

/// Walks the IR tree rooted at [node] and collects metadata references.
RfwWidgetMetadata collectMetadata(IrValue node) {
  final dataRefs = <String>{};
  final stateRefs = <String>{};
  final events = <String>{};
  _walk(node, dataRefs, stateRefs, events);
  return RfwWidgetMetadata(
    dataRefs: dataRefs,
    stateRefs: stateRefs,
    events: events,
  );
}

void _walk(
  IrValue node,
  Set<String> dataRefs,
  Set<String> stateRefs,
  Set<String> events,
) {
  switch (node) {
    case IrDataRef():
      dataRefs.add(node.path);
    case IrStateRef():
      stateRefs.add(node.path);
    case IrSetStateValue():
      stateRefs.add(node.field);
      _walk(node.value, dataRefs, stateRefs, events);
    case IrSetStateFromArgValue():
      stateRefs.add(node.field);
    case IrEventValue():
      events.add(node.name);
      for (final v in node.args.values) {
        _walk(v, dataRefs, stateRefs, events);
      }
    case IrWidgetNode():
      for (final v in node.properties.values) {
        _walk(v, dataRefs, stateRefs, events);
      }
    case IrListValue():
      for (final v in node.values) {
        _walk(v, dataRefs, stateRefs, events);
      }
    case IrForLoop():
      _walk(node.items, dataRefs, stateRefs, events);
      _walk(node.body, dataRefs, stateRefs, events);
    case IrSwitchExpr():
      _walk(node.value, dataRefs, stateRefs, events);
      for (final v in node.cases.values) {
        _walk(v, dataRefs, stateRefs, events);
      }
      if (node.defaultCase != null) {
        _walk(node.defaultCase!, dataRefs, stateRefs, events);
      }
    case IrConcat():
      for (final v in node.parts) {
        _walk(v, dataRefs, stateRefs, events);
      }
    case IrMapValue():
      for (final v in node.entries.values) {
        _walk(v, dataRefs, stateRefs, events);
      }
    default:
      break; // IrStringValue, IrNumberValue, IrIntValue, IrBoolValue, etc.
  }
}
