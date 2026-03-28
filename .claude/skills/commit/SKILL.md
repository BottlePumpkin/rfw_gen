---
name: commit
description: Create a git commit without Co-Authored-By attribution. Use when the user says /commit, "commit this", "make a commit", or asks to save changes to git. Triggers on any commit-related request.
user_invocable: true
---

# Commit Skill

Create a clean git commit. Never include Co-Authored-By lines.

## Process

1. Run `git status` and `git diff --staged` to see what's being committed
2. If nothing is staged, show status and ask what to stage
3. Review the changes and write a concise commit message following conventional commits (feat:, fix:, refactor:, docs:, chore:, ci:, test:)
4. Commit using HEREDOC format:
   ```bash
   git commit -m "$(cat <<'EOF'
   <type>: <description>
   EOF
   )"
   ```

## Rules

- NEVER include Co-Authored-By, Signed-off-by, or any trailer lines
- NEVER include attribution to Claude, Anthropic, or any AI
- Keep the first line under 72 characters
- Use imperative mood ("add feature" not "added feature")
- If args are provided (e.g., `/commit -m "message"`), use that message directly
