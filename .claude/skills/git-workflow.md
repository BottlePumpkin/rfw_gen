---
name: git-workflow
description: Manage git worktrees for parallel development sessions. Create isolated workspaces, check status, finish work with PRs, and clean up merged branches.
user_invocable: true
---

# Git Workflow Skill

Manage parallel development sessions using git worktrees. Each session gets its own isolated working directory and branch.

## Subcommands

Parse the user's arguments to determine which subcommand to run. If no argument, run `status`.

---

### `/git-workflow start <type/name>` or `/git-workflow start <name>`

Create an isolated worktree for a new feature branch.

**Steps:**

1. Parse the name. If it contains `/` (e.g., `fix/offset-bug`), use as-is. If not, prefix with `feat/` (e.g., `error-reporting` → `feat/error-reporting`).
2. Extract the short name (part after `/`) for the worktree directory name.
3. Check if worktree already exists at `.worktrees/<short-name>/`. If yes, just show the path.
4. Check if `--base <branch>` was specified. Default base is `origin/main`.
5. Fetch the base: `git fetch origin`
6. Create worktree:
   ```bash
   git worktree add .worktrees/<short-name> -b <type/name> <base>
   ```
7. Output:
   ```
   Created worktree at .worktrees/<short-name>/
   Branch: <type/name> (based on <base>)

   Next steps:
     cd .worktrees/<short-name> && claude
   ```

**Supported branch types:** feat, fix, docs, chore, refactor, test, release

---

### `/git-workflow status`

Show all worktrees, branches, and recommended cleanup actions.

**Steps:**

1. Run `git worktree list` to get all worktrees
2. For each worktree, check dirty/clean: `git -C <path> status --porcelain`
3. Run `git branch -vv` for branch tracking info
4. Check for merged branches:
   - `git branch --merged main` for fast-forward merges
   - `gh pr list --state merged --json headRefName -q '.[].headRefName'` for squash merges
5. Show summary with recommended actions (which branches can be cleaned up)

---

### `/git-workflow finish`

Push the current branch and create a PR.

**Steps:**

1. Verify current branch is not main: `git branch --show-current`
2. Push with tracking: `git push -u origin <branch>`
3. Create PR: `gh pr create --fill` (or ask user for title/body)
4. Output the PR URL
5. Remind: "When PR is merged, run `/git-workflow cleanup` from the main worktree"

---

### `/git-workflow cleanup`

Remove completed worktrees and merged branches.

**Steps:**

1. Detect merged branches:
   ```bash
   git branch --merged main
   gh pr list --state merged --json headRefName -q '.[].headRefName'
   ```
2. For each merged branch (excluding main):
   - Check no open PRs: `gh pr list --head <branch> --state open`
   - Check worktree is clean: `git -C .worktrees/<name> status --porcelain`
   - If dirty, warn and skip
   - Remove worktree: `git worktree remove .worktrees/<name>`
   - Delete local branch: `git branch -d <branch>`
   - Ask user before deleting remote: `git push origin --delete <branch>`
3. Prune: `git remote prune origin && git worktree prune`
4. Show summary of what was cleaned

**Safety rules:**
- NEVER delete main
- NEVER delete branches with open PRs
- NEVER delete worktrees with uncommitted changes
- ALWAYS ask before deleting remote branches

---

## Rules

- Always use `origin/main` as base (not `git checkout main`) — avoids branch conflict with existing worktrees
- Worktree directory: `.worktrees/<short-name>/` relative to repo root
- One branch per worktree — git enforces this automatically
- Run `melos bootstrap` in new worktrees if the project uses melos
