import 'dart:async';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';

import 'local_widget_builder_generator.dart';
import 'widget_registry.dart';
import 'widget_resolver.dart';

/// A [Builder] that generates `.rfw_library.dart` (LocalWidgetBuilder map)
/// and `.rfw_meta.json` (machine-readable metadata) for `@RfwWidget`-annotated
/// files containing custom (non-core) widgets.
///
/// Uses the Dart analyzer's Resolver to inspect imported widget classes
/// and extract constructor parameter information automatically.
class LocalWidgetBuilderBuilder implements Builder {
  /// The build_runner options passed from `build.yaml`.
  final BuilderOptions options;

  /// Creates a builder that generates local widget builder code.
  LocalWidgetBuilderBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => const {
        '.dart': ['.rfw_library.dart', '.rfw_meta.json'],
      };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final source = await buildStep.readAsString(buildStep.inputId);

    // Quick check: skip files without @RfwWidget annotation.
    if (!source.contains('RfwWidget')) {
      return _skipOutputs();
    }

    // Parse the source and collect unknown widget names.
    final parseResult = parseString(content: source);
    final registry = WidgetRegistry.core();
    final unknownNames = _collectUnknownWidgetNames(parseResult.unit, registry);

    if (unknownNames.isEmpty) {
      return _skipOutputs();
    }

    // Resolve: get input library, walk imports to find widget classes.
    final inputLibrary = await buildStep.resolver.libraryFor(
      buildStep.inputId,
    );
    final resolver = WidgetResolver();
    final results = <String, ResolveResult>{};

    // Search in input library first, then its imports.
    for (final name in unknownNames) {
      var result = resolver.resolveFromLibrary(inputLibrary, name);
      if (result == null) {
        // Walk imported libraries via the library fragment.
        for (final libImport in inputLibrary.firstFragment.libraryImports) {
          final imported = libImport.importedLibrary;
          if (imported == null) continue;
          result = resolver.resolveFromLibrary(imported, name);
          if (result != null) break;
          // Also check re-exported libraries.
          for (final reExported in imported.exportedLibraries) {
            result = resolver.resolveFromLibrary(reExported, name);
            if (result != null) break;
          }
          if (result != null) break;
        }
      }
      if (result != null) results[name] = result;
    }

    if (results.isEmpty) {
      return _skipOutputs();
    }

    final generator = LocalWidgetBuilderGenerator();
    final resolvedWidgets = {
      for (final e in results.entries) e.key: e.value.resolvedWidget,
    };

    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_library.dart'),
      generator.generate(resolvedWidgets),
    );
    await buildStep.writeAsString(
      buildStep.inputId.changeExtension('.rfw_meta.json'),
      generator.generateMeta(resolvedWidgets),
    );
  }

  /// Skips output generation when no custom widgets are found.
  ///
  /// Previously wrote empty placeholder files, but this cluttered projects
  /// with unnecessary .rfw_library.dart and .rfw_meta.json files for every
  /// .dart file without @RfwWidget annotations.
  void _skipOutputs() {
    // Intentionally empty — do not generate files for non-@RfwWidget sources.
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
