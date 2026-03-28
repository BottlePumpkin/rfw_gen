# Version Sync Automation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automate version synchronization across all rfw_gen packages and playground with CI validation, plus playground content drift detection.

**Architecture:** A root `VERSION` file serves as single source of truth. A Dart script (`tool/sync_versions.dart`) reads it to update all pubspec.yaml files. CI validates consistency on every PR. After pub.dev publish, a GitHub Actions workflow automatically creates a PR to update playground dependencies. Additionally, CI detects playground content drift (missing widget examples), and existing skills (`/add-widget`, `/dogfood`) are extended to prevent/detect stale content.

**Tech Stack:** Dart (script), GitHub Actions (CI/CD), sed (playground update workflow)

**Spec:** `docs/superpowers/specs/2026-03-28-version-sync-automation-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `VERSION` | Create | Single source of truth for package version |
| `tool/sync_versions.dart` | Create | Read VERSION, update/check all pubspec.yaml files |
| `.github/workflows/ci.yml` | Modify | Add `check-versions` job |
| `.github/workflows/publish.yml` | Modify | Add tag-VERSION validation, skip-if-published |
| `.github/workflows/update-playground.yml` | Create | Auto-update playground deps after publish |
| `.claude/CLAUDE.md` | Modify | Update Release Rules section |
| `tool/check_playground_coverage.dart` | Create | Compare WidgetRegistry vs playground gallery coverage |
| `.claude/skills/add-widget/SKILL.md` | Modify | Add Step 6.5: playground gallery example (optional) |
| `.claude/skills/dogfood/SKILL.md` | Modify | Add playground freshness check category |

---

### Task 1: Create VERSION file

**Files:**
- Create: `VERSION`

- [ ] **Step 1: Create VERSION file with current version**

```
0.5.1
```

Write this single line (no trailing newline after the version, just the version string followed by a newline) to the root `VERSION` file.

- [ ] **Step 2: Verify the file**

Run: `cat VERSION`
Expected: `0.5.1`

- [ ] **Step 3: Commit**

```bash
git add VERSION
git commit -m "chore: add VERSION file as single source of truth"
```

---

### Task 2: Create sync_versions.dart script

**Files:**
- Create: `tool/sync_versions.dart`

**Context:** This Dart script is run directly (`dart tool/sync_versions.dart`), not via `dart run`. The root pubspec is a workspace pubspec so `dart run` won't find package context.

**Current pubspec.yaml state for reference:**
- `packages/rfw_gen/pubspec.yaml:3` → `version: 0.5.1`
- `packages/rfw_gen_builder/pubspec.yaml:3` → `version: 0.5.1`, line 21 → `rfw_gen: ^0.5.0`
- `packages/rfw_gen_mcp/pubspec.yaml:3` → `version: 0.5.1`, line 22 → `rfw_gen: ^0.5.0`, line 23 → `rfw_gen_builder: ^0.5.0`
- `packages/rfw_preview/pubspec.yaml:3` → `version: 0.5.1` (no cross-deps)

- [ ] **Step 1: Write the test — verify --check detects current state as in-sync**

Create a shell test that verifies the script works. We'll test it manually since this is a standalone Dart script (no test framework needed for a tool script).

First, create the script file `tool/sync_versions.dart`:

```dart
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
```

- [ ] **Step 2: Run --check to verify current state is in sync**

Run: `dart tool/sync_versions.dart --check`
Expected: `OK: All versions in sync (0.5.1)`

- [ ] **Step 3: Test mismatch detection — temporarily change VERSION**

Run:
```bash
echo "0.9.9" > VERSION
dart tool/sync_versions.dart --check
echo $?
echo "0.5.1" > VERSION
```
Expected: Exit code 1 with mismatch errors listing all 4 packages.

- [ ] **Step 4: Test --dry-run mode**

Run:
```bash
echo "0.9.9" > VERSION
dart tool/sync_versions.dart --dry-run
echo "0.5.1" > VERSION
```
Expected: Shows "Would update (dry-run):" with all changes listed, no files modified.

- [ ] **Step 5: Test actual sync — change VERSION, sync, verify, restore**

Run:
```bash
echo "0.9.9" > VERSION
dart tool/sync_versions.dart
dart tool/sync_versions.dart --check
# Should print "OK: All versions in sync (0.9.9)"
# Now restore
echo "0.5.1" > VERSION
dart tool/sync_versions.dart
dart tool/sync_versions.dart --check
# Should print "OK: All versions in sync (0.5.1)"
```
Expected: Both checks pass. Files are properly restored.

- [ ] **Step 6: Verify no diff remains after restore**

Run: `git diff packages/`
Expected: No output (all pubspec.yaml files are back to original state).

- [ ] **Step 7: Commit**

```bash
git add tool/sync_versions.dart
git commit -m "feat: add version sync script with --check and --dry-run modes"
```

---

### Task 3: Add check-versions job to CI

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: Read current ci.yml**

Read `.github/workflows/ci.yml` to confirm current structure.

- [ ] **Step 2: Add check-versions job**

Add a new job `check-versions` that runs **before** (or parallel to) `analyze-and-test`. This job only needs Dart (not Flutter) since it's just parsing files.

Add this job to the `jobs:` section in `ci.yml`:

```yaml
  check-versions:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - name: Check version consistency
        run: dart tool/sync_versions.dart --check
```

- [ ] **Step 3: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))"`
Expected: No error output.

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add version consistency check to CI pipeline"
```

---

### Task 4: Improve publish.yml

**Files:**
- Modify: `.github/workflows/publish.yml`

- [ ] **Step 1: Read current publish.yml**

Read `.github/workflows/publish.yml` to confirm current structure (lines 1-54).

- [ ] **Step 2: Add tag-VERSION validation step**

Add this step right after the checkout step (before any publish steps):

```yaml
      - name: Validate tag matches VERSION file
        run: |
          TAG_VERSION="${GITHUB_REF_NAME#v}"
          FILE_VERSION="$(cat VERSION)"
          if [ "$TAG_VERSION" != "$FILE_VERSION" ]; then
            echo "ERROR: Tag $GITHUB_REF_NAME does not match VERSION file ($FILE_VERSION)"
            exit 1
          fi
          echo "Tag $GITHUB_REF_NAME matches VERSION file"
```

- [ ] **Step 3: Replace continue-on-error with skip-if-published logic**

Replace each publish step. Example for rfw_gen (repeat pattern for all 4):

```yaml
      - name: Publish rfw_gen
        run: |
          if dart pub publish --dry-run --directory packages/rfw_gen 2>&1 | grep -q "has already been published"; then
            echo "rfw_gen already published, skipping"
          else
            dart pub publish --directory packages/rfw_gen --force
          fi
```

Remove `continue-on-error: true` from all 4 publish steps.

- [ ] **Step 4: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/publish.yml'))"`
Expected: No error output.

- [ ] **Step 5: Commit**

```bash
git add .github/workflows/publish.yml
git commit -m "ci: add tag-VERSION validation and skip-if-published to publish workflow"
```

---

### Task 5: Create update-playground.yml workflow

**Files:**
- Create: `.github/workflows/update-playground.yml`

- [ ] **Step 1: Create the workflow file**

Write `.github/workflows/update-playground.yml` with the full content from the spec (Section 4b). Copy verbatim from the spec:

```yaml
name: Update Playground Dependencies

on:
  workflow_run:
    workflows: ['Publish to pub.dev']
    types: [completed]
  workflow_dispatch:

jobs:
  update-playground:
    if: ${{ github.event_name == 'workflow_dispatch' || github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - name: Read VERSION
        id: version
        run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT

      - name: Update playground dependencies
        run: |
          VERSION=${{ steps.version.outputs.version }}
          sed -i "s/rfw_gen_builder: \^.*/rfw_gen_builder: ^${VERSION}/" rfw_gen_playground/pubspec.yaml
          sed -i "s/^  rfw_gen: \^.*/  rfw_gen: ^${VERSION}/" rfw_gen_playground/pubspec.yaml

      - name: Wait for pub.dev indexing
        working-directory: rfw_gen_playground
        run: |
          for i in {1..10}; do
            if flutter pub get 2>/dev/null; then
              echo "Dependencies resolved successfully"
              exit 0
            fi
            echo "Attempt $i/10: waiting for pub.dev indexing..."
            sleep 30
          done
          echo "ERROR: pub.dev indexing timeout after 5 minutes"
          exit 1

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v6
        with:
          title: "chore(playground): update dependencies to v${{ steps.version.outputs.version }}"
          body: |
            Automated update after [v${{ steps.version.outputs.version }}](https://github.com/${{ github.repository }}/releases/tag/v${{ steps.version.outputs.version }}) publish.

            Updates:
            - `rfw_gen: ^${{ steps.version.outputs.version }}`
            - `rfw_gen_builder: ^${{ steps.version.outputs.version }}`
          branch: chore/playground-v${{ steps.version.outputs.version }}
          commit-message: "chore(playground): update deps to v${{ steps.version.outputs.version }}"
```

- [ ] **Step 2: Verify YAML is valid**

Run: `python3 -c "import yaml; yaml.safe_load(open('.github/workflows/update-playground.yml'))"`
Expected: No error output.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/update-playground.yml
git commit -m "ci: add automatic playground dependency update after publish"
```

---

### Task 6: Update CLAUDE.md Release Rules

**Files:**
- Modify: `.claude/CLAUDE.md`

- [ ] **Step 1: Read current CLAUDE.md**

Read `.claude/CLAUDE.md` to find the Release Rules section.

- [ ] **Step 2: Update Release Rules**

Find the section that currently reads:
```
## Release Rules

- rfw_gen, rfw_gen_builder, rfw_gen_mcp, rfw_preview versions must always stay in sync
- Follow semver: breaking change → major, new feature → minor, bug fix → patch
- Release process: release/x.y.z branch → CHANGELOG + version bump → PR → main → tag → pub.dev
- Hotfixes also use release/x.y.z branches (patch version)
```

Replace with:
```
## Release Rules

- VERSION file (root) is the single source of truth for all package versions
- rfw_gen, rfw_gen_builder, rfw_gen_mcp, rfw_preview versions must always stay in sync
- Follow semver: breaking change → major, new feature → minor, bug fix → patch
- Version change: edit VERSION → `dart tool/sync_versions.dart` → PR
- CI automatically validates version consistency (`--check` mode)
- Release process: release/x.y.z branch → VERSION + sync + CHANGELOG → PR → main → tag → pub.dev
- After pub.dev publish, playground dependencies are updated via automatic PR
- Hotfixes also use release/x.y.z branches (patch version)
```

- [ ] **Step 3: Commit**

```bash
git add .claude/CLAUDE.md
git commit -m "docs: update CLAUDE.md release rules with version sync automation"
```

---

### Task 7: End-to-end verification

- [ ] **Step 1: Verify --check passes with current state**

Run: `dart tool/sync_versions.dart --check`
Expected: `OK: All versions in sync (0.5.1)`

- [ ] **Step 2: Test full sync cycle**

Run:
```bash
echo "0.6.0" > VERSION
dart tool/sync_versions.dart --dry-run
```
Expected: Lists all 7 fields that would be updated.

- [ ] **Step 3: Restore VERSION**

Run:
```bash
echo "0.5.1" > VERSION
```

- [ ] **Step 4: Validate all workflow YAML files**

Run:
```bash
for f in .github/workflows/*.yml; do
  echo "Checking $f..."
  python3 -c "import yaml; yaml.safe_load(open('$f'))"
done
```
Expected: No errors.

- [ ] **Step 5: Verify git status is clean**

Run: `git status`
Expected: Nothing to commit (VERSION should be back to 0.5.1).

---

### Task 8: Create playground coverage check script

**Files:**
- Create: `tool/check_playground_coverage.dart`

**Context:** This script compares widgets registered in `WidgetRegistry.core()` against playground gallery examples. It's a soft check (warning, not failure) used in CI and during releases.

- [ ] **Step 1: Create the script**

```dart
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

  // Match patterns like: 'core.WidgetName' or 'material.WidgetName'
  final regex = RegExp(r"'(core|material)\.(\w+)'");
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
```

- [ ] **Step 2: Run the script to verify it works**

Run: `dart tool/check_playground_coverage.dart`
Expected: Output listing registered widgets and any missing from playground gallery. Should show a significant number of missing widgets since playground only has custom widget gallery, not core/material gallery.

- [ ] **Step 3: Add soft check to CI**

Add to `.github/workflows/ci.yml` in the `check-versions` job (or as a separate job):

```yaml
      - name: Check playground widget coverage
        run: dart tool/check_playground_coverage.dart
        continue-on-error: true  # Soft warning, not a blocker
```

- [ ] **Step 4: Commit**

```bash
git add tool/check_playground_coverage.dart .github/workflows/ci.yml
git commit -m "feat: add playground widget coverage check (soft CI warning)"
```

---

### Task 9: Extend /add-widget skill with playground step

**Files:**
- Modify: `.claude/skills/add-widget/SKILL.md`

- [ ] **Step 1: Read current SKILL.md**

Read `.claude/skills/add-widget/SKILL.md` to find the exact location of Step 6.

- [ ] **Step 2: Add Step 6.5 after existing Step 6**

After the existing Step 6 (adding demo to `example/lib/catalog/catalog_widgets.dart`), add:

```markdown
### Step 6.5: (Optional) Add playground gallery example

If the widget is commonly used and would benefit from a live playground example:

1. Create `rfw_gen_playground/lib/screens/gallery/widget_detail_{snake_name}.dart`
   - Include an `@RfwWidget` function demonstrating the widget's key parameters
   - Show 2-3 usage variations (basic, with styling, with interaction if applicable)
2. Add entry to `rfw_gen_playground/remote/manifest.json` under `gallery_detail`:
   ```json
   {
     "id": "widget_detail_{snake_name}",
     "title": "{WidgetName}",
     "category": "gallery_detail",
     "rfwtxt": "screens/widget_detail_{snake_name}.rfwtxt",
     "keywords": ["{widget_name}", "gallery"]
   }
   ```
3. Run `cd rfw_gen_playground && flutter build web` to verify the example compiles

> **Skip this step** if the widget is niche (e.g., AnimationDefaults, Directionality) or if it's an animated alias of an already-covered widget.
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/add-widget/SKILL.md
git commit -m "docs: add optional playground gallery step to add-widget skill"
```

---

### Task 10: Extend /dogfood skill with freshness check

**Files:**
- Modify: `.claude/skills/dogfood/SKILL.md`

- [ ] **Step 1: Read current SKILL.md**

Read `.claude/skills/dogfood/SKILL.md` to find the issue categorization section.

- [ ] **Step 2: Add playground freshness category**

In the issue categorization section (Step 8 of run mode), add a new category:

```markdown
#### Playground Freshness Check (during dogfood run)

After completing the dogfood app, also check playground content:

1. **Stale examples**: Open `rfw_gen_playground/` in browser, navigate to widget gallery
   - Do examples use current API? (check parameter names, types, required/optional)
   - Do examples compile without deprecation warnings?
2. **Missing examples**: Run `dart tool/check_playground_coverage.dart`
   - Note any core/material widgets without playground gallery entries
3. **Categorize findings** as:
   - `playground` + `stale`: Example exists but uses outdated API
   - `playground` + `missing`: Widget registered but no playground example
   - `playground` + `broken`: Example doesn't compile or render correctly
```

- [ ] **Step 3: Commit**

```bash
git add .claude/skills/dogfood/SKILL.md
git commit -m "docs: add playground freshness check to dogfood skill"
```

---

### Task 11: Final verification (content sync additions)

- [ ] **Step 1: Run playground coverage check**

Run: `dart tool/check_playground_coverage.dart`
Expected: Lists all registered widgets and notes which are missing from playground.

- [ ] **Step 2: Verify all workflow YAML files are valid**

Run:
```bash
for f in .github/workflows/*.yml; do
  echo "Checking $f..."
  python3 -c "import yaml; yaml.safe_load(open('$f'))"
done
```
Expected: No errors.

- [ ] **Step 3: Verify skills are valid markdown**

Run:
```bash
head -5 .claude/skills/add-widget/SKILL.md
head -5 .claude/skills/dogfood/SKILL.md
```
Expected: Valid markdown with frontmatter intact.
