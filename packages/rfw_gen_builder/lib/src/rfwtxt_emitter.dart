import 'ir.dart';

/// Emits an IR widget tree as an rfwtxt string.
class RfwtxtEmitter {
  /// Emit a complete rfwtxt file with imports and widget declaration.
  ///
  /// [widgetName] is the name for the `widget` declaration.
  /// [root] is the top-level widget node.
  /// [imports] is the set of library names to import (e.g. `'core.widgets'`).
  String emit({
    required String widgetName,
    required IrWidgetNode root,
    required Set<String> imports,
    Map<String, IrValue>? stateDecl,
  }) {
    final buffer = StringBuffer();

    // Emit imports in sorted order.
    final sortedImports = imports.toList()..sort();
    for (final import in sortedImports) {
      buffer.writeln('import $import;');
    }

    if (sortedImports.isNotEmpty) {
      buffer.writeln();
    }

    // Emit widget declaration.
    buffer.write('widget $widgetName');
    if (stateDecl != null && stateDecl.isNotEmpty) {
      final stateEntries = stateDecl.entries
          .map((e) => '${e.key}: ${_emitValue(e.value, indent: 0)}')
          .join(', ');
      buffer.write(' { $stateEntries }');
    }
    buffer.write(' = ');
    buffer.write(_emitWidget(root, indent: 0));
    buffer.writeln(';');

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Emits a widget node as rfwtxt. [indent] is the current nesting level.
  String _emitWidget(IrWidgetNode node, {required int indent}) {
    final buffer = StringBuffer();
    buffer.write('${node.name}(');

    if (node.properties.isEmpty) {
      buffer.write('\n${_indentStr(indent)})');
      return buffer.toString();
    }

    buffer.writeln();
    final propIndent = indent + 1;
    final entries = node.properties.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      buffer.write('${_indentStr(propIndent)}${entry.key}: ');
      buffer.write(_emitValue(entry.value, indent: propIndent));
      if (i < entries.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.write('${_indentStr(indent)})');
    return buffer.toString();
  }

  /// Dispatches to the appropriate value emitter.
  String _emitValue(IrValue value, {required int indent}) {
    return switch (value) {
      IrStringValue v => _emitString(v.value),
      IrNumberValue v => _emitNumber(v.value),
      IrIntValue v => _emitInt(v.value),
      IrBoolValue v => v.value ? 'true' : 'false',
      IrEnumValue v => _emitString(v.value),
      IrListValue v => _emitList(v, indent: indent),
      IrMapValue v => _emitMap(v, indent: indent),
      IrWidgetNode v => _emitWidget(v, indent: indent),
      IrSetStateValue v =>
        'set state.${v.field} = ${_emitValue(v.value, indent: indent)}',
      IrSetStateFromArgValue v => 'set state.${v.field} = args.${v.argName}',
      IrEventValue v => _emitEvent(v, indent: indent),
      IrDataRef v => 'data.${v.path}',
      IrArgsRef v => 'args.${v.path}',
      IrStateRef v => 'state.${v.path}',
      IrLoopVarRef v => v.path,
      IrConcat v => _emitConcat(v, indent: indent),
      IrForLoop v => _emitForLoop(v, indent: indent),
      IrSwitchExpr v => _emitSwitchExpr(v, indent: indent),
    };
  }

  /// Emits a string literal with escaping for `\` and `"`.
  String _emitString(String s) {
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }

  /// Emits a double value. Whole numbers always show `.0`.
  String _emitNumber(double v) {
    if (v.isNaN || v.isInfinite) {
      throw StateError('Cannot emit special float value: $v');
    }
    if (v == v.truncateToDouble()) {
      // Whole number — format without scientific notation.
      return '${v.truncate().toString()}.0';
    }
    return v.toString();
  }

  /// Emits an integer value.
  ///
  /// Color-like values (ARGB with alpha channel, i.e. >= 0x01000000) and
  /// negative values are emitted as `0xXXXXXXXX` (uppercase hex, 8 digits).
  /// Small non-negative values are emitted as decimal for readability.
  String _emitInt(int v) {
    if (v >= 0x01000000 || v < 0) {
      // Color-like or negative → hex with 32-bit unsigned mask.
      final unsigned = v & 0xFFFFFFFF;
      final hex = unsigned.toRadixString(16).toUpperCase().padLeft(8, '0');
      return '0x$hex';
    }
    return v.toString();
  }

  /// Emits a list value.
  ///
  /// Short lists (≤4 items, all primitives) are emitted inline.
  /// All other lists are emitted multi-line.
  String _emitList(IrListValue list, {required int indent}) {
    if (list.values.isEmpty) {
      return '[]';
    }

    final isShort = list.values.length <= 4 && _allPrimitives(list.values);
    if (isShort) {
      final items = list.values.map((v) => _emitValue(v, indent: indent));
      return '[${items.join(', ')}]';
    }

    // Multi-line list.
    final buffer = StringBuffer();
    buffer.writeln('[');
    final itemIndent = indent + 1;
    for (var i = 0; i < list.values.length; i++) {
      buffer.write(_indentStr(itemIndent));
      buffer.write(_emitValue(list.values[i], indent: itemIndent));
      if (i < list.values.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.write('${_indentStr(indent)}]');
    return buffer.toString();
  }

  /// Emits a map value as a multi-line `{ key: value }` block.
  String _emitMap(IrMapValue map, {required int indent}) {
    if (map.entries.isEmpty) {
      return '{}';
    }

    final buffer = StringBuffer();
    buffer.writeln('{');
    final entryIndent = indent + 1;
    final mapEntries = map.entries.entries.toList();
    for (var i = 0; i < mapEntries.length; i++) {
      final entry = mapEntries[i];
      buffer.write('${_indentStr(entryIndent)}${entry.key}: ');
      buffer.write(_emitValue(entry.value, indent: entryIndent));
      if (i < mapEntries.length - 1) buffer.write(',');
      buffer.writeln();
    }
    buffer.write('${_indentStr(indent)}}');
    return buffer.toString();
  }

  /// Emits an event handler value.
  String _emitEvent(IrEventValue event, {required int indent}) {
    if (event.args.isEmpty) {
      return 'event "${event.name}" {}';
    }
    final buffer = StringBuffer();
    buffer.write('event "${event.name}" { ');
    final entries = event.args.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      buffer.write(
          '${entries[i].key}: ${_emitValue(entries[i].value, indent: indent)}');
      if (i < entries.length - 1) buffer.write(', ');
    }
    buffer.write(' }');
    return buffer.toString();
  }

  /// Emits a string concatenation as a list literal: `["Hello, ", data.name, "!"]`.
  String _emitConcat(IrConcat concat, {required int indent}) {
    final parts = concat.parts.map((p) => _emitValue(p, indent: indent));
    return '[${parts.join(', ')}]';
  }

  /// Emits a `...for item in source: body` loop entry.
  String _emitForLoop(IrForLoop loop, {required int indent}) {
    final items = _emitValue(loop.items, indent: indent);
    final body = _emitWidget(loop.body, indent: indent + 1);
    return '...for ${loop.itemName} in $items:\n${_indentStr(indent + 1)}$body';
  }

  /// Emits a `switch value { case1: result1, default: resultN }` expression.
  String _emitSwitchExpr(IrSwitchExpr expr, {required int indent}) {
    final buffer = StringBuffer();
    buffer.write('switch ${_emitValue(expr.value, indent: indent)} {');
    final caseIndent = indent + 1;
    for (final entry in expr.cases.entries) {
      buffer.writeln();
      buffer.write(
          '${_indentStr(caseIndent)}${_emitValue(entry.key, indent: caseIndent)}: ');
      buffer.write('${_emitValue(entry.value, indent: caseIndent)},');
    }
    if (expr.defaultCase != null) {
      buffer.writeln();
      buffer.write(
          '${_indentStr(caseIndent)}default: ${_emitValue(expr.defaultCase!, indent: caseIndent)},');
    }
    buffer.writeln();
    buffer.write('${_indentStr(indent)}}');
    return buffer.toString();
  }

  /// Returns `true` if every value in [values] is a primitive (not a widget or
  /// nested list/map).
  bool _allPrimitives(List<IrValue> values) {
    return values.every(
      (v) =>
          v is IrStringValue ||
          v is IrNumberValue ||
          v is IrIntValue ||
          v is IrBoolValue ||
          v is IrEnumValue,
    );
  }

  /// Returns a string of [level] × 2 spaces.
  String _indentStr(int level) => '  ' * level;
}
