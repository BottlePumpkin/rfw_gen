import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:rfw/formats.dart';

void main() {
  final sourceDir = Directory('lib/screens');
  final targetDir = Directory('remote/screens');
  final dataDir = Directory('remote/data');

  if (!sourceDir.existsSync()) {
    stderr.writeln('Error: lib/screens/ not found');
    exit(1);
  }
  if (!targetDir.existsSync()) {
    targetDir.createSync(recursive: true);
  }

  final screens = <Map<String, dynamic>>[];
  var hasErrors = false;

  for (final file in sourceDir.listSync(recursive: true)..sort((a, b) => a.path.compareTo(b.path))) {
    if (file is! File || !file.path.endsWith('.rfwtxt')) continue;

    final name = path.basename(file.path);
    final id = path.basenameWithoutExtension(name);
    final content = file.readAsStringSync();

    // Validate rfwtxt
    try {
      parseLibraryFile(content);
      stdout.writeln('✓ $name');
    } catch (e) {
      stderr.writeln('✗ $name — $e');
      hasErrors = true;
      continue;
    }

    // Copy to remote
    file.copySync(path.join(targetDir.path, name));

    // Check for corresponding data JSON
    final dataFile = File(path.join(dataDir.path, '$id.json'));
    final dataPath = dataFile.existsSync() ? 'data/$id.json' : null;

    screens.add({
      'id': id,
      'title': _titleCase(id),
      'category': _inferCategory(id),
      'rfwtxt': 'screens/$name',
      if (dataPath != null) 'data': dataPath,
      'keywords': _inferKeywords(id),
    });
  }

  if (hasErrors) {
    stderr.writeln('\nDeploy aborted due to validation errors.');
    exit(1);
  }

  // Write manifest
  final manifest = {
    'version': DateTime.now().millisecondsSinceEpoch,
    'baseUrl': '',
    'categories': [
      {'id': 'overview', 'title': 'Overview'},
      {'id': 'guides', 'title': 'Guides'},
      {'id': 'packages', 'title': 'Packages'},
      {'id': 'reference', 'title': 'Reference'},
      {'id': 'gallery', 'title': 'RFW Custom Widget Gallery'},
    ],
    'screens': screens,
  };

  File('remote/manifest.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(manifest));
  stdout.writeln('\n✓ manifest.json updated (${screens.length} screens)');
}

String _titleCase(String id) {
  const overrides = {
    'widget_gallery': 'Supported Widgets',
    'builder_guide': 'rfw_gen_builder Guide',
    'rfw_gen_guide': 'rfw_gen Guide',
    'mcp_guide': 'rfw_gen_mcp Guide',
    'preview_guide': 'rfw_preview Guide',
    'widget_gallery_custom': 'Gallery',
  };
  if (overrides.containsKey(id)) return overrides[id]!;
  return id
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _inferCategory(String id) {
  if (id == 'home') return 'overview';
  if (id == 'getting_started') return 'guides';
  if (id.endsWith('_guide')) return 'packages';
  if (id == 'widget_gallery_custom') return 'gallery';
  if (id.startsWith('widget_detail_')) return 'gallery_detail';
  return 'reference';
}

List<String> _inferKeywords(String id) {
  return id.split('_');
}
