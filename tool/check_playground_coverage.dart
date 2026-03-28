import 'dart:io';

/// Extracts widget names from WidgetRegistry source and compares
/// against playground gallery coverage.
void main(List<String> args) {
  final repoRoot = _findRepoRoot();

  final registryWidgets = _extractRegistryWidgets(repoRoot);
  final galleryWidgets = _extractGalleryWidgets(repoRoot);

  final missing = registryWidgets.difference(galleryWidgets);
  final extra = galleryWidgets.difference(registryWidgets);

  if (missing.isEmpty && extra.isEmpty) {
    print('OK: Playground gallery covers all ${registryWidgets.length} registry widgets');
    return;
  }

  if (missing.isNotEmpty) {
    print('WARNING: ${missing.length} widget(s) in WidgetRegistry but NOT in playground gallery:');
    for (final w in missing.toList()..sort()) {
      print('  - $w');
    }
  }

  if (extra.isNotEmpty) {
    print('NOTE: ${extra.length} widget(s) in playground gallery but NOT in WidgetRegistry:');
    for (final w in extra.toList()..sort()) {
      print('  - $w');
    }
  }

  print('');
  print('Total: ${registryWidgets.length} registered, ${galleryWidgets.length} in gallery, ${missing.length} missing');

  // Soft warning — exit 0 (not a CI failure)
  // Use --strict to fail on missing widgets
  if (args.contains('--strict') && missing.isNotEmpty) {
    exit(1);
  }
}

/// Parse widget_registry.dart for rfwName entries like 'core.Text', 'material.Scaffold'
Set<String> _extractRegistryWidgets(String repoRoot) {
  final file = File('$repoRoot/packages/rfw_gen_builder/lib/src/widget_registry.dart');
  if (!file.existsSync()) {
    print('ERROR: widget_registry.dart not found');
    exit(1);
  }
  final content = file.readAsStringSync();

  // Match rfwName entries like: rfwName: 'core.Text' or 'material.Scaffold'
  final regex = RegExp(r"rfwName:\s*'(core|material)\.(\w+)'");
  final matches = regex.allMatches(content);

  return matches.map((m) => m.group(2)!).toSet();
}

/// Scan playground gallery directory for widget_detail_*.dart files
/// and widget_gallery.dart for referenced widgets
Set<String> _extractGalleryWidgets(String repoRoot) {
  final widgets = <String>{};

  // Check gallery detail files: widget_detail_{name}.dart
  final galleryDir = Directory('$repoRoot/rfw_gen_playground/lib/screens/gallery');
  if (galleryDir.existsSync()) {
    for (final entity in galleryDir.listSync()) {
      if (entity is File && entity.path.endsWith('.dart')) {
        final fileName = entity.uri.pathSegments.last;
        final match = RegExp(r'widget_detail_(\w+)\.dart').firstMatch(fileName);
        if (match != null) {
          // Convert snake_case to PascalCase
          final snakeName = match.group(1)!;
          final pascalName = snakeName
              .split('_')
              .map((part) => part[0].toUpperCase() + part.substring(1))
              .join();
          widgets.add(pascalName);
        }
      }
    }
  }

  // Also check widget_gallery.dart for explicitly listed widgets
  final galleryFile = File('$repoRoot/rfw_gen_playground/lib/screens/widget_gallery.dart');
  if (galleryFile.existsSync()) {
    final content = galleryFile.readAsStringSync();
    // Look for widget name references in gallery listing
    final regex = RegExp(r"'(\w+)'.*//\s*gallery-widget");
    for (final match in regex.allMatches(content)) {
      widgets.add(match.group(1)!);
    }
  }

  return widgets;
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/VERSION').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) return Directory.current.path;
    dir = parent;
  }
}
