# git-workflow Skill Design Spec

**Date**: 2026-03-24
**Status**: Approved

## Problem

When running multiple Claude Code sessions in parallel (separate terminals), all sessions share the same working directory and git HEAD. This causes:
- Commits landing on wrong branches
- Unintended branch creation
- Cherry-pick duplicates when trying to fix
- Stale branches accumulating after work completes

Root cause: single working directory + concurrent branch switching = context loss.

## Solution

A `/git-workflow` skill with 4 subcommands that uses git worktrees to isolate each session, plus a SessionStart hook for safety.

## Skill: `/git-workflow`

### `/git-workflow start <type/name>`

Creates an isolated worktree for a feature branch.

**Steps:**
1. Fetch latest main: `git fetch origin main`
2. Create worktree based on `origin/main`: `git worktree add .worktrees/<name> -b <type>/<name> origin/main`
3. If branch/worktree already exists, show path without creating
4. Output the worktree path for the user to `cd` into or start a new claude session
5. Remind to run `melos bootstrap` in the worktree if needed

**Branch naming:** User provides `<type>/<name>` (e.g., `feat/error-reporting`, `fix/offset-bug`). If no type prefix given, defaults to `feat/`. Supported types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`.

**Optional `--base` flag:** For branching off non-main branches (e.g., stacking PRs):
```
/git-workflow start feat/sub-feature --base feat/parent-feature
```

**Worktree location:** `.worktrees/<name>/` relative to repo root.

**Example:**
```
> /git-workflow start feat/error-reporting

Created worktree at .worktrees/error-reporting/
Branch: feat/error-reporting (based on origin/main)

Next steps:
  cd .worktrees/error-reporting && claude
  # Run melos bootstrap if needed
```

### `/git-workflow status`

Shows current git workflow state across all worktrees.

**Steps:**
1. `git worktree list` — active worktrees (including external ones)
2. For each worktree: `git -C <path> status --porcelain` to check dirty/clean
3. `git branch -vv` — local branches with tracking info
4. Identify: merged branches (via `git branch --merged main` + `gh pr list --state merged`), orphaned branches, local-only branches
5. Show summary with recommended actions

**Example output:**
```
Worktrees:
  /Users/.../rfw_gen                                main                 (clean)
  /Users/.../rfw_gen/.worktrees/error-reporting     feat/error-reporting (dirty, 3 ahead)
  /Users/.../rfw_gen_mcp                            feat/mcp-server      (clean, external)

Branches:
  main                    → origin/main (up to date)
  feat/error-reporting    → origin/feat/error-reporting (3 ahead)
  feat/widen-analyzer     → origin/feat/widen-analyzer (merged, can delete)

Recommended cleanup:
  - feat/widen-analyzer: merged into main, delete with /git-workflow cleanup
```

### `/git-workflow finish`

Pushes current branch and creates a PR.

**Steps:**
1. Check current branch is not main
2. Push branch: `git push -u origin <branch>`
3. Create PR via `gh pr create` with conventional title
4. Output PR URL
5. Suggest: "When PR is merged, run `/git-workflow cleanup` from the main worktree"

### `/git-workflow cleanup`

Removes completed worktrees and merged branches.

**Steps:**
1. Detect merged branches via:
   - `git branch --merged main` (fast-forward/true merge)
   - `gh pr list --state merged` (squash/rebase merge detection)
2. For each merged branch:
   - Check no open PRs: `gh pr list --head <branch> --state open`
   - Check worktree is clean (no uncommitted changes)
   - Remove associated worktree if exists: `git worktree remove .worktrees/<name>`
   - Delete local branch: `git branch -d <branch>`
   - Delete remote branch: `git push origin --delete <branch>` (with confirmation)
3. Prune stale remote refs: `git remote prune origin`
4. Clean up dangling worktrees: `git worktree prune`
5. Show summary of what was cleaned

**Safety:**
- Never delete main
- Never delete branches with open PRs
- Never delete worktrees with uncommitted changes (warn and skip)
- Ask for confirmation before deleting remote branches
- Handle squash-merged branches (GitHub default) via `gh pr list`

## Hook: SessionStart

**File:** `.claude/settings.local.json`

**Implementation:** A command hook on `SessionStart` event that checks if the current branch is main:

```json
{
  "hooks": {
    "SessionStart": [{
      "hooks": [{
        "type": "command",
        "command": "branch=$(git branch --show-current 2>/dev/null); if [ \"$branch\" = \"main\" ] || [ \"$branch\" = \"master\" ]; then echo '{\"systemMessage\": \"You are on the main branch. If starting feature work, run: /git-workflow start <type/name>\"}'; fi"
      }]
    }]
  }
}
```

This shows a reminder — does not block. Simple questions and reviews on main are fine.

## .gitignore

Add `.worktrees/` to `.gitignore` to exclude worktree directories from git tracking.

## Implementation Order

1. Add `.worktrees/` to `.gitignore`
2. Create `.claude/skills/git-workflow.md` skill file
3. Add SessionStart hook to `.claude/settings.local.json`
4. Test: start → work → finish → cleanup cycle
