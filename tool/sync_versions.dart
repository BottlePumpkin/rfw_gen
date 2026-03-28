import 'dart:io';

/// Paths to all core package pubspec.yaml files (relative to repo root).
const _packagePubspecs = [
  'packages/rfw_gen/pubspec.yaml',
  'packages/rfw_gen_builder/pubspec.yaml',
  'packages/rfw_gen_mcp/pubspec.yaml',
  'packages/rfw_preview/pubspec.yaml',
];

/// Cross-package dependency rules.
/// Key: pubspec path, Value: list of dependency names to update.
const _crossDeps = {
  'packages/rfw_gen_builder/pubspec.yaml': ['rfw_gen'],
  'packages/rfw_gen_mcp/pubspec.yaml': ['rfw_gen', 'rfw_gen_builder'],
};

void main(List<String> args) {
  final mode = _parseMode(args);
  final repoRoot = _findRepoRoot();
  final version = _readVersion(repoRoot);
  final minorFloor = _toMinorFloor(version);

  var hasChanges = false;
  var hasErrors = false;
  final messages = <String>[];

  for (final pubspecPath in _packagePubspecs) {
    final file = File('$repoRoot/$pubspecPath');
    if (!file.existsSync()) {
      messages.add('  WARNING: $pubspecPath not found, skipping');
      continue;
    }

    var content = file.readAsStringSync();
    var modified = false;

    // Update version: field
    final versionRegex = RegExp(r'^version:\s+\S+', multiLine: true);
    final versionMatch = versionRegex.firstMatch(content);
    if (versionMatch != null) {
      final currentVersion = versionMatch.group(0)!;
      final expectedVersion = 'version: $version';
      if (currentVersion != expectedVersion) {
        if (mode == _Mode.check) {
          messages.add('  $pubspecPath version: ${currentVersion.split(' ').last} (expected: $version)');
          hasErrors = true;
        } else {
          content = content.replaceFirst(versionRegex, expectedVersion);
          modified = true;
          messages.add('  $pubspecPath version: ${currentVersion.split(' ').last} → $version');
        }
      }
    }

    // Update cross-package dependencies
    final deps = _crossDeps[pubspecPath];
    if (deps != null) {
      for (final dep in deps) {
        // Match "  dep_name: ^x.y.z" in YAML (indented, under dependencies:)
        final depRegex = RegExp('^(  $dep: )\\^\\S+', multiLine: true);
        final depMatch = depRegex.firstMatch(content);
        if (depMatch != null) {
          final currentDep = depMatch.group(0)!;
          final expectedDep = '  $dep: ^$minorFloor';
          if (currentDep != expectedDep) {
            if (mode == _Mode.check) {
              final currentVal = currentDep.split('^').last;
              messages.add('  $pubspecPath $dep dep: ^$currentVal (expected: ^$minorFloor)');
              hasErrors = true;
            } else {
              content = content.replaceFirst(depRegex, expectedDep);
              modified = true;
              final currentVal = currentDep.split('^').last;
              messages.add('  $pubspecPath $dep dep: ^$currentVal → ^$minorFloor');
            }
          }
        }
      }
    }

    if (modified) {
      hasChanges = true;
      if (mode == _Mode.sync) {
        file.writeAsStringSync(content);
      }
    }
  }

  // Output
  if (mode == _Mode.check) {
    if (hasErrors) {
      print('ERROR: Version mismatch detected!');
      print('  VERSION file: $version');
      for (final msg in messages) {
        print(msg);
      }
      print('');
      print('Run: dart tool/sync_versions.dart');
      exit(1);
    } else {
      print('OK: All versions in sync ($version)');
    }
  } else if (mode == _Mode.dryRun) {
    if (messages.isEmpty) {
      print('Already in sync ($version)');
    } else {
      print('Would update (dry-run):');
      for (final msg in messages) {
        print(msg);
      }
    }
  } else {
    if (!hasChanges) {
      print('Already in sync ($version)');
    } else {
      print('Updated to $version:');
      for (final msg in messages) {
        print(msg);
      }
    }
  }
}

enum _Mode { sync, check, dryRun }

_Mode _parseMode(List<String> args) {
  if (args.contains('--check')) return _Mode.check;
  if (args.contains('--dry-run')) return _Mode.dryRun;
  return _Mode.sync;
}

String _findRepoRoot() {
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/VERSION').existsSync() &&
        File('${dir.path}/pubspec.yaml').existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) {
      // Fallback to current directory
      return Directory.current.path;
    }
    dir = parent;
  }
}

String _readVersion(String repoRoot) {
  final file = File('$repoRoot/VERSION');
  if (!file.existsSync()) {
    print('ERROR: VERSION file not found at $repoRoot/VERSION');
    exit(1);
  }
  final version = file.readAsStringSync().trim();
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
    print('ERROR: Invalid version format in VERSION file: "$version"');
    print('Expected format: major.minor.patch (e.g., 0.6.0)');
    exit(1);
  }
  return version;
}

/// Converts "1.2.3" → "1.2.0" (minor floor for caret dependency).
String _toMinorFloor(String version) {
  final parts = version.split('.');
  return '${parts[0]}.${parts[1]}.0';
}
