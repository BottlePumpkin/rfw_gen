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

A `/git-workflow` skill with 3 subcommands that uses git worktrees to isolate each session, plus a SessionStart hook for safety.

## Skill: `/git-workflow`

### `/git-workflow start <name>`

Creates an isolated worktree for a feature branch.

**Steps:**
1. Ensure on latest main: `git checkout main && git pull`
2. Create worktree: `git worktree add .worktrees/<name> -b feat/<name>`
3. If branch/worktree already exists, show path without creating
4. Output the worktree path for the user to `cd` into or start a new claude session

**Branch naming:** `feat/<name>` based on main. User provides `<name>`.

**Worktree location:** `.worktrees/<name>/` relative to repo root.

**Example:**
```
> /git-workflow start error-reporting

Created worktree at .worktrees/error-reporting/
Branch: feat/error-reporting (based on main)

Start a new session there:
  cd .worktrees/error-reporting && claude
```

### `/git-workflow status`

Shows current git workflow state across all worktrees.

**Steps:**
1. `git worktree list` — active worktrees
2. `git branch -vv` — local branches with tracking info
3. Identify: merged branches (safe to delete), branches with no worktree (orphaned), branches with no remote (local only)
4. Show summary with recommended actions

**Example output:**
```
Worktrees:
  /Users/.../rfw_gen              main        (clean)
  /Users/.../rfw_gen/.worktrees/error-reporting  feat/error-reporting  (3 commits ahead)

Branches:
  main                    → origin/main (up to date)
  feat/error-reporting    → origin/feat/error-reporting (3 ahead)
  feat/widen-analyzer     → origin/feat/widen-analyzer (merged, can delete)

Recommended cleanup:
  - feat/widen-analyzer: merged into main, delete with /git-workflow cleanup
```

### `/git-workflow cleanup`

Removes completed worktrees and merged branches.

**Steps:**
1. List merged branches: `git branch --merged main`
2. For each merged branch:
   - Remove associated worktree if exists: `git worktree remove .worktrees/<name>`
   - Delete local branch: `git branch -d <branch>`
   - Delete remote branch: `git push origin --delete <branch>`
3. Prune stale remote refs: `git remote prune origin`
4. Clean up dangling worktrees: `git worktree prune`
5. Show summary of what was cleaned

**Safety:**
- Never delete main
- Never delete branches that aren't fully merged
- Never delete worktrees with uncommitted changes (warn and skip)
- Ask for confirmation before deleting remote branches

## Hook: SessionStart

**File:** `.claude/settings.json` or `.claude/settings.local.json`

**Behavior:** When a session starts, check if the current directory is the main worktree and the branch is main. If so, show a reminder:

```
You're on the main branch. If you're starting feature work, run:
  /git-workflow start <feature-name>
```

**Implementation:** SessionStart hook that runs a shell command checking `git branch --show-current`.

## .gitignore

Add `.worktrees/` to `.gitignore` to exclude worktree directories from git tracking.

## Implementation Order

1. Add `.worktrees/` to `.gitignore`
2. Create `.claude/skills/git-workflow.md` skill file
3. Add SessionStart hook to settings
4. Test: start → work → cleanup cycle
