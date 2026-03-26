import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';

import 'package:rfw/formats.dart';

import 'ast_visitor.dart';
import 'converter.dart';
import 'widget_registry.dart';
import 'widget_resolver.dart';

/// A custom [Builder] that finds `@RfwWidget`-annotated top-level functions
/// and generates `.rfwtxt` (text) and `.rfw` (binary) output files.
class RfwWidgetBuilder implements Builder {
  /// The build_runner options passed from `build.yaml`.
  final BuilderOptions options;

  /// Creates a builder that converts `@RfwWidget`-annotated functions.
  RfwWidgetBuilder(this.options);

  /// Maps each `.dart` input to `.rfwtxt` (text) and `.rfw` (binary) outputs.
  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rfwtxt', '.rfw'],
      };

  /// Scans [buildStep] for `@RfwWidget` functions, converts each to rfwtxt,
  /// and writes both `.rfwtxt` and `.rfw` outputs.
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

    // Build registry: core + custom widgets discovered via Resolver.
    final registry = WidgetRegistry.core();
    final unknownNames = _collectUnknownWidgetNames(parseResult.unit, registry);
    if (unknownNames.isNotEmpty) {
      final inputLibrary = await buildStep.resolver.libraryFor(
        buildStep.inputId,
      );
      final resolver = WidgetResolver();
      for (final name in unknownNames) {
        ResolveResult? result = resolver.resolveFromLibrary(inputLibrary, name);
        if (result == null) {
          for (final libImport in inputLibrary.firstFragment.libraryImports) {
            final imported = libImport.importedLibrary;
            if (imported == null) continue;
            result = resolver.resolveFromLibrary(imported, name);
            if (result != null) break;
            for (final reExported in imported.exportedLibraries) {
              result = resolver.resolveFromLibrary(reExported, name);
              if (result != null) break;
            }
            if (result != null) break;
          }
        }
        if (result != null) {
          registry.register(name, result.widgetMapping);
        }
      }
    }

    final converter = RfwConverter(registry: registry);
    final parts = <String>[];

    for (final function in annotatedFunctions) {
      try {
        final result = converter.convertFromAst(function, source: source);
        parts.add(result.rfwtxt);
        for (final issue in result.issues) {
          if (issue.isFatal) {
            log.severe(issue.toString());
          } else {
            log.warning(issue.toString());
          }
        }
      } on UnsupportedWidgetError catch (e) {
        final hasGuidance = e.message != null;
        final suggestion = hasGuidance
            ? ''
            : '\n  Suggestion: Check that the widget class is imported';
        log.severe('${function.name.lexeme}: $e$suggestion');
      } catch (e) {
        log.severe('Failed to convert ${function.name.lexeme}: $e');
      }
    }

    if (parts.isEmpty) return;

    // When there are multiple widget outputs, each has its own import block.
    // Merge them into a single valid rfwtxt file: collect imports once at the
    // top, then all widget declarations below.
    final combined = _mergeRfwtxtParts(parts);

    // Validate generated rfwtxt
    try {
      parseLibraryFile(combined);
    } catch (e) {
      log.severe(
        'Generated rfwtxt is invalid (possible rfw_gen bug): $e\n'
        'Generated content:\n$combined',
      );
      return;
    }

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

/// Collects widget names from the AST that are not in the core registry.
Set<String> _collectUnknownWidgetNames(
  CompilationUnit unit,
  WidgetRegistry registry,
) {
  final collector = _WidgetNameCollector(registry);
  unit.accept(collector);
  return collector.unknownNames;
}

/// Visits all [MethodInvocation] nodes recursively and collects names
/// that look like widget constructors (uppercase first letter) but are
/// not registered in the core [WidgetRegistry].
class _WidgetNameCollector extends RecursiveAstVisitor<void> {
  final WidgetRegistry registry;
  final Set<String> unknownNames = {};

  _WidgetNameCollector(this.registry);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.target == null) {
      final name = node.methodName.name;
      // Uppercase first letter = likely a widget constructor call.
      if (name.isNotEmpty &&
          name[0] == name[0].toUpperCase() &&
          !registry.isSupported(name)) {
        unknownNames.add(name);
      }
    }
    super.visitMethodInvocation(node);
  }
}
