import 'dart:convert';

import 'widget_resolver.dart';

/// Generates Dart source and JSON metadata from [ResolvedWidget] objects.
///
/// Produces two outputs:
/// - `.rfw_library.dart` via [generate] — a `Map<String, LocalWidgetBuilder>`
///   that wires RFW's `DataSource` API to real Flutter widget constructors.
/// - `.rfw_meta.json` via [generateMeta] — machine-readable widget metadata
///   for MCP server consumption.
class LocalWidgetBuilderGenerator {
  /// Generates the `.rfw_library.dart` file content.
  ///
  /// [widgets] maps widget class name → [ResolvedWidget].
  String generate(Map<String, ResolvedWidget> widgets) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln();

    // Collect unique imports
    final imports = _collectImports(widgets);

    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln("import 'package:rfw/rfw.dart';");
    for (final import in imports) {
      buffer.writeln("import '$import';");
    }

    buffer.writeln();
    buffer.writeln('/// Auto-generated [LocalWidgetBuilder] map.');
    buffer.writeln(
        'Map<String, LocalWidgetBuilder> get generatedLocalWidgetBuilders =>');
    buffer.writeln('    <String, LocalWidgetBuilder>{');

    for (final entry in widgets.entries) {
      final widgetName = entry.key;
      final widget = entry.value;
      buffer.write(_generateBuilderEntry(widgetName, widget));
    }

    buffer.writeln('};');

    return buffer.toString();
  }

  /// Generates the `.rfw_meta.json` file content.
  ///
  /// [widgets] maps widget class name → [ResolvedWidget].
  String generateMeta(Map<String, ResolvedWidget> widgets) {
    final widgetsMap = <String, dynamic>{};

    for (final entry in widgets.entries) {
      final widgetName = entry.key;
      final widget = entry.value;
      widgetsMap[widgetName] = _buildWidgetMeta(widget);
    }

    final meta = {'widgets': widgetsMap};
    return const JsonEncoder.withIndent('  ').convert(meta);
  }

  // ---------------------------------------------------------------------------
  // Private helpers — code generation
  // ---------------------------------------------------------------------------

  /// Collects unique dart import URIs from all widgets.
  List<String> _collectImports(Map<String, ResolvedWidget> widgets) {
    final seen = <String>{};
    final result = <String>[];
    for (final widget in widgets.values) {
      if (seen.add(widget.dartImport)) {
        result.add(widget.dartImport);
      }
    }
    return result;
  }

  /// Generates a single map entry for [widgetName].
  String _generateBuilderEntry(String widgetName, ResolvedWidget widget) {
    final buffer = StringBuffer();
    buffer.writeln(
        "  '$widgetName': (BuildContext context, DataSource source) {");

    // Collect any widgetList params that need local variable declarations
    final widgetListParams =
        widget.params.where((p) => p.type == ResolvedParamType.widgetList);

    for (final param in widgetListParams) {
      buffer.writeln(
          '    final ${param.name} = <Widget>[];');
      buffer.writeln(
          "    for (var i = 0; i < source.length(['${param.name}']); i++) {");
      buffer.writeln(
          "      ${param.name}.add(source.child(['${param.name}', i]));");
      buffer.writeln('    }');
    }

    buffer.writeln('    return $widgetName(');

    for (final param in widget.params) {
      final line = _generateParamLine(param);
      if (line != null) {
        buffer.writeln('      $line,');
      }
    }

    buffer.writeln('    );');
    buffer.writeln('  },');

    return buffer.toString();
  }

  /// Generates the named argument line for a single [param].
  ///
  /// Returns `null` if the param should be skipped (e.g., widgetList — already
  /// declared as a local variable and passed directly).
  String? _generateParamLine(ResolvedParam param) {
    final name = param.name;

    switch (param.type) {
      case ResolvedParamType.string:
        final fallback = _primitiveFallback(param, "''");
        return "$name: source.v<String>(['$name'])$fallback";

      case ResolvedParamType.int:
        final fallback = _primitiveFallback(param, '0');
        return "$name: source.v<int>(['$name'])$fallback";

      case ResolvedParamType.double:
        final fallback = _primitiveFallback(param, '0.0');
        return "$name: source.v<double>(['$name'])$fallback";

      case ResolvedParamType.bool:
        final fallback = _primitiveFallback(param, 'false');
        return "$name: source.v<bool>(['$name'])$fallback";

      case ResolvedParamType.widget:
        return "$name: source.child(['$name'])";

      case ResolvedParamType.optionalWidget:
        return "$name: source.optionalChild(['$name'])";

      case ResolvedParamType.widgetList:
        // Already declared as a local variable above; pass directly.
        return '$name: $name';

      case ResolvedParamType.voidCallback:
        return "$name: source.voidHandler(['$name'])";

      case ResolvedParamType.other:
        return "$name: source.v<dynamic>(['$name'])";
    }
  }

  /// Returns the `?? fallback` suffix for a primitive param, or an empty
  /// string if the param is optional without a default value.
  String _primitiveFallback(ResolvedParam param, String typeFallback) {
    if (param.defaultValue != null) {
      return ' ?? ${param.defaultValue}';
    }
    if (param.isRequired) {
      return ' ?? $typeFallback';
    }
    // Optional, no default → omit fallback so null can propagate.
    return '';
  }

  // ---------------------------------------------------------------------------
  // Private helpers — JSON metadata
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _buildWidgetMeta(ResolvedWidget widget) {
    // Derive import package name from dartImport URI
    final importName = _extractPackageName(widget.dartImport);

    // Infer childType from params
    final childType = _inferChildTypeName(widget.params);

    // Collect handler names
    final handlers = widget.params
        .where((p) => p.type == ResolvedParamType.voidCallback)
        .map((p) => p.name)
        .toList();

    // Build params list (excluding widget/callback params)
    final params = widget.params
        .where((p) =>
            p.type != ResolvedParamType.widget &&
            p.type != ResolvedParamType.optionalWidget &&
            p.type != ResolvedParamType.widgetList &&
            p.type != ResolvedParamType.voidCallback)
        .map((p) => {
              'name': p.name,
              'type': _resolvedTypeToString(p.type),
              'required': p.isRequired,
            })
        .toList();

    return {
      'import': importName,
      'childType': childType,
      'handlers': handlers,
      'params': params,
    };
  }

  String _extractPackageName(String dartImport) {
    final uri = Uri.parse(dartImport);
    if (uri.scheme == 'package' && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.first;
    }
    return dartImport;
  }

  String _inferChildTypeName(List<ResolvedParam> params) {
    for (final p in params) {
      if (p.type == ResolvedParamType.widgetList) return 'childList';
      if (p.type == ResolvedParamType.widget) return 'child';
      if (p.type == ResolvedParamType.optionalWidget) return 'optionalChild';
    }
    return 'none';
  }

  String _resolvedTypeToString(ResolvedParamType type) {
    return switch (type) {
      ResolvedParamType.string => 'String',
      ResolvedParamType.int => 'int',
      ResolvedParamType.double => 'double',
      ResolvedParamType.bool => 'bool',
      ResolvedParamType.voidCallback => 'VoidCallback',
      ResolvedParamType.widget => 'Widget',
      ResolvedParamType.optionalWidget => 'Widget?',
      ResolvedParamType.widgetList => 'List<Widget>',
      ResolvedParamType.other => 'dynamic',
    };
  }
}
