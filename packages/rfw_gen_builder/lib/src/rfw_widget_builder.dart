import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:build/build.dart';
import 'package:yaml/yaml.dart';

import 'converter.dart';
import 'widget_registry.dart';

/// A custom [Builder] that finds `@RfwWidget`-annotated top-level functions
/// and generates `.rfwtxt` (text) and `.rfw` (binary) output files.
class RfwWidgetBuilder implements Builder {
  final BuilderOptions options;

  RfwWidgetBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rfwtxt', '.rfw'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);

    // Parse the Dart source and find @RfwWidget-annotated functions.
    final parseResult = parseString(content: source);
    final annotatedFunctions = parseResult.unit.declarations
        .whereType<FunctionDeclaration>()
        .where((f) => f.metadata.any((a) => a.name.name == 'RfwWidget'))
        .toList();

    if (annotatedFunctions.isEmpty) return;

    // Build registry: core + custom widgets from rfw_gen.yaml.
    final registry = WidgetRegistry.core();
    final configId = AssetId(buildStep.inputId.package, 'rfw_gen.yaml');
    String? yamlStr;
    if (await buildStep.canRead(configId)) {
      yamlStr = await buildStep.readAsString(configId);
    } else {
      // Fallback: read from filesystem for root-level files not in build graph.
      final file = File('rfw_gen.yaml');
      if (file.existsSync()) {
        yamlStr = file.readAsStringSync();
      }
    }
    if (yamlStr != null) {
      final yaml = loadYaml(yamlStr);
      if (yaml is Map) {
        final widgets = yaml['widgets'];
        if (widgets is Map) {
          registry.registerFromConfig(Map<String, dynamic>.from(widgets));
        }
      }
    }

    final converter = RfwConverter(registry: registry);
    final parts = <String>[];

    for (final function in annotatedFunctions) {
      try {
        parts.add(converter.convertFromAst(function));
      } catch (e) {
        log.severe('Failed to convert ${function.name.lexeme}: $e');
      }
    }

    if (parts.isEmpty) return;

    // When there are multiple widget outputs, each has its own import block.
    // Merge them into a single valid rfwtxt file: collect imports once at the
    // top, then all widget declarations below.
    final combined = _mergeRfwtxtParts(parts);

    // Write .rfwtxt text output.
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfwtxt'),
      combined,
    );

    // Write .rfw binary output.
    try {
      final blob = converter.toBlob(combined);
      await buildStep.writeAsBytes(
        buildStep.inputId.changeExtension('.rfw'),
        blob,
      );
    } catch (e) {
      log.warning('Failed to encode binary: $e');
    }
  }

  /// Merges multiple complete rfwtxt outputs into a single valid file.
  ///
  /// Each part may contain `import` lines followed by `widget` declarations.
  /// This collects all unique imports at the top and concatenates widget
  /// declarations below.
  static String _mergeRfwtxtParts(List<String> parts) {
    if (parts.length == 1) return parts.first;

    final imports = <String>{};
    final widgetDeclarations = <String>[];

    for (final part in parts) {
      final lines = part.split('\n');
      final widgetLines = <String>[];
      var inWidgetSection = false;

      for (final line in lines) {
        if (line.startsWith('import ')) {
          imports.add(line);
        } else if (line.startsWith('widget ') || inWidgetSection) {
          inWidgetSection = true;
          widgetLines.add(line);
        }
      }

      if (widgetLines.isNotEmpty) {
        widgetDeclarations.add(widgetLines.join('\n').trimRight());
      }
    }

    final buffer = StringBuffer();
    final sortedImports = imports.toList()..sort();
    for (final imp in sortedImports) {
      buffer.writeln(imp);
    }
    if (sortedImports.isNotEmpty) {
      buffer.writeln();
    }
    buffer.writeln(widgetDeclarations.join('\n\n'));

    return buffer.toString();
  }
}
