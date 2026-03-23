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
    buffer.write('widget $widgetName = ');
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
    for (final entry in node.properties.entries) {
      buffer.write('${_indentStr(propIndent)}${entry.key}: ');
      buffer.write(_emitValue(entry.value, indent: propIndent));
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
    };
  }

  /// Emits a string literal with escaping for `\` and `"`.
  String _emitString(String s) {
    final escaped = s.replaceAll(r'\', r'\\').replaceAll('"', r'\"');
    return '"$escaped"';
  }

  /// Emits a double value. Whole numbers always show `.0`.
  String _emitNumber(double v) {
    if (v == v.truncateToDouble()) {
      // Whole number — format without scientific notation.
      return '${v.truncate().toString()}.0';
    }
    return v.toString();
  }

  /// Emits an integer as `0xXXXXXXXX` (uppercase hex, 8 digits zero-padded).
  String _emitInt(int v) {
    // toRadixString produces lowercase; convert to uppercase.
    // Use unsigned 32-bit representation so negative ints display correctly.
    final unsigned = v & 0xFFFFFFFF;
    final hex = unsigned.toRadixString(16).toUpperCase().padLeft(8, '0');
    return '0x$hex';
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
    for (final v in list.values) {
      buffer.write(_indentStr(itemIndent));
      buffer.write(_emitValue(v, indent: itemIndent));
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
    for (final entry in map.entries.entries) {
      buffer.write('${_indentStr(entryIndent)}${entry.key}: ');
      buffer.write(_emitValue(entry.value, indent: entryIndent));
      buffer.writeln();
    }
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
