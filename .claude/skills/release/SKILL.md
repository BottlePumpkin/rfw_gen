---
name: release
description: Release a new version of the rfw_gen monorepo. Handles version bump, CHANGELOG, PR creation, and post-merge tagging. Use when the user says /release, "release", "new version", "version bump", "publish", or wants to prepare a release. Also triggers for /release tag after PR merge.
user_invocable: true
---

# Release Skill

Automate the rfw_gen monorepo release process. All 4 packages (rfw_gen, rfw_gen_builder, rfw_gen_mcp, rfw_preview) must always have the same version.

## Subcommands

Parse arguments to determine which subcommand to run. Default (no args or a version number) runs the full release flow.

---

### `/release [version]` — Prepare a release

Create a release branch, bump versions, update CHANGELOGs, run tests, and open a PR.

**Step 1: Analyze changes since last tag**

```bash
# Current versions
grep -r "version:" packages/*/pubspec.yaml

# Latest tag
git tag --sort=-v:refname | head -1

# Changes since last tag (code only, exclude docs/skills/chores)
git log <last-tag>..HEAD --oneline --no-merges
```

**Step 2: Determine version**

If the user provided a version (e.g., `/release 0.5.2`), use it. Otherwise, suggest a version based on the changes:
- Breaking change in any commit → **major** bump
- `feat:` commits with code changes → **minor** bump
- `fix:` commits only → **patch** bump

Show the suggestion and ask user to confirm before proceeding.

**Step 3: Create release branch**

```bash
git checkout -b release/<version>
```

**Step 4: Bump versions in all 4 packages**

Update `version:` in each pubspec.yaml:
- `packages/rfw_gen/pubspec.yaml`
- `packages/rfw_gen_builder/pubspec.yaml`
- `packages/rfw_gen_mcp/pubspec.yaml`
- `packages/rfw_preview/pubspec.yaml`

**Step 5: Update CHANGELOGs**

For each package, check if there were actual code changes (in `lib/` or `test/`):

```bash
git log <last-tag>..HEAD --oneline --no-merges -- packages/<pkg>/lib packages/<pkg>/test
```

- **If changes exist**: Write descriptive changelog entries from commit messages
- **If no changes**: Write `- No changes (version bump to match <package-with-changes>)`

Prepend the new section at the top of each CHANGELOG.md:
```markdown
## <version>

- <entries>
```

**Step 6: Run tests**

```bash
melos exec -- dart test
```

Verify all tests pass. `dart analyze` warnings from `upstream/` directory are expected and can be ignored.

**Step 7: Commit, push, and create PR**

```bash
git add packages/*/pubspec.yaml packages/*/CHANGELOG.md
git commit -m "$(cat <<'EOF'
release: v<version>
EOF
)"
git push -u origin release/<version>
gh pr create --title "release: v<version>" --body "$(cat <<'EOF'
## Summary

- Bump all 4 packages to <version>
- <package>: <brief list of changes>

## Test plan

- [x] `melos exec -- dart test` — all tests passed
EOF
)"
```

Output the PR URL.

---

### `/release tag` — Tag after PR merge

Run this after the release PR has been merged to main.

**Steps:**

1. Switch to main and pull:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Detect the version from pubspec.yaml:
   ```bash
   grep "version:" packages/rfw_gen/pubspec.yaml
   ```

3. Check the tag doesn't already exist:
   ```bash
   git tag -l "v<version>"
   ```

4. Create and push the tag:
   ```bash
   git tag v<version>
   git push origin v<version>
   ```

5. Confirm: "Tag `v<version>` pushed. The publish workflow will automatically deploy to pub.dev and create a GitHub Release."

---

## Rules

- NEVER release from main directly — always use a `release/<version>` branch + PR
- All 4 package versions must match exactly
- CHANGELOG format: `## <version>` header, `-` prefixed items
- Commit message: `release: v<version>` (no other content)
- The publish workflow (`.github/workflows/publish.yml`) triggers on tag push matching `v*` — tagging is the final step that deploys to pub.dev
