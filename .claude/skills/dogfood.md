---
name: dogfood
description: Simulate a first-time user trying rfw_gen packages, discover issues, and file them as GitHub Issues. Use /dogfood run to start a collection cycle, /dogfood fix to resolve filed issues.
user_invocable: true
---

# Dogfood Skill

Simulate a first-time rfw_gen user to discover DX issues, bugs, and feature gaps.

## Argument Parsing

Parse user arguments to determine mode:
- `/dogfood run` → Run a collection cycle (Section: Run Mode)
- `/dogfood fix` → Fix filed issues (Section: Fix Mode)
- `/dogfood` (no args) → Show help: "Usage: /dogfood run | /dogfood fix"

## Prerequisites (both modes)

Before any operation, verify:

1. **gh auth**: Run `gh auth status`. If not authenticated, tell user to run `! gh auth login` and stop.
2. **GitHub labels**: Run `gh label list --search dogfood`. If `dogfood` label doesn't exist, create all needed labels:
   ```bash
   gh label create dogfood --color 0E8A16 --description "Dogfood cycle issue"
   gh label create dx --color D93F0B --description "Developer experience issue"
   ```
   Also check for `bug`, `feature`, `docs` labels — these likely already exist. Only create if missing.
3. **.gitignore**: Check `example2/` is in `.gitignore`. If not, add it and commit.

## Run Mode

### Step 1: Clean up previous example2

```bash
rm -rf example2/
```

### Step 2: Determine cycle number

Search existing dogfood issues for the latest cycle number:

```bash
gh issue list --label dogfood --state all --limit 100 --json body -q '.[].body'
```

Parse `사이클: #N` from issue bodies. New cycle = max(N) + 1. If no issues exist, start at #1.

### Step 3: Select persona (random)

Pick ONE randomly. Do not repeat the same persona in consecutive cycles if you can recall the previous one.

**Persona A — 신규 사용자 (First-time user)**
- Flutter experienced, never used rfw_gen
- Can ONLY reference: README.md, pubspec.yaml, pub.dev page
- CANNOT read: package source code, internal docs, generated files
- Behavior: Starts from `pub.dev/packages/rfw_gen`, follows getting started guide

**Persona B — 문서 읽은 사용자 (Doc-reader)**
- Flutter experienced, has read rfw_gen docs
- Can reference: README, CHANGELOG, doc/, example/ code
- CANNOT read: package source code internals
- Behavior: Understands @RfwWidget concept, tries intermediate patterns

**Persona C — 코드젠 경험자 (Code-gen veteran)**
- Has used build_runner, freezed, json_serializable
- Can reference: everything including source code
- Behavior: Compares rfw_gen conventions with other code-gen packages, tries advanced patterns

### Step 4: Select app topic (random)

Pick a topic NOT used in previous cycles. Check existing dogfood issues for past topics:

```bash
gh issue list --label dogfood --state all --limit 100 --json body -q '.[].body'
```

Parse `주제: {topic}` from bodies and avoid duplicates.

Topic examples: 투두 앱, 날씨 대시보드, SNS 피드, 레시피 북, 운동 트래커, 음악 플레이어 UI, 설정 화면, 뉴스 리더, 채팅 UI, 가계부, 일기장, 영화 목록, 학습 카드, 타이머 앱, 식단 관리

**Constraint:** The topic must exercise at least 5-8 different RFW widgets and include both layout and interaction patterns.

### Step 5: Create example2 project

```bash
flutter create example2 --project-name dogfood_app
```

Then update `example2/pubspec.yaml` dependencies. **IMPORTANT: Check pub.dev for the latest versions of each package before writing the pubspec. Do not use the example versions below — always use the actual latest published versions.**

```yaml
dependencies:
  flutter:
    sdk: flutter
  rfw: ^<LATEST>
  rfw_gen: ^<LATEST>

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^<LATEST>
  rfw_gen_builder: ^<LATEST>
```

If the persona attempts to use `rfw_preview`, add it to dependencies as well.

If `flutter create` fails, output the error and stop the cycle.

Run:
```bash
cd example2 && flutter pub get
```

If `pub get` fails, output the error (likely a pub.dev version issue) and stop the cycle.

### Step 6: Develop the app as the selected persona

**CRITICAL: Stay in character.** Only use information your persona has access to.

Development process:
1. Create Dart files with `@RfwWidget`-annotated functions for each screen/component
2. Run `dart run build_runner build` to generate rfwtxt and binary files
3. Attempt to use generated RFW content with rfw_preview if relevant
4. Try at least 5-8 different widgets from the RFW widget set
5. Include both layout widgets (Row, Column, Stack, etc.) and interaction widgets (GestureDetector, ElevatedButton, etc.)

**As you work, record every friction point:**
- Build errors or confusing error messages
- Documentation that was missing or unclear
- API patterns that felt unintuitive
- Widgets you wanted but weren't supported
- Behavior that differed from what you expected
- Error messages that didn't help you fix the problem
- Anything you had to guess or figure out by trial and error

**Important:** Don't just note the problem — also note what you tried, what you expected, and what actually happened. This context is essential for the issue report.

### Step 7: Compile and categorize issues

Organize discovered issues into categories:
- `bug` — Build errors, codegen failures, incorrect output
- `dx` — Poor documentation, unintuitive API, bad error messages
- `feature` — Unsupported widgets, missing functionality
- `docs` — Documentation improvements, missing examples

**Maximum 7 issues per cycle.** If more than 7, keep the top 7 by priority (bug > dx > feature > docs). Note the rest as "deferred to next cycle" in the summary.

For each issue, prepare:
- Title: `[dogfood/{category}] {concise summary}`
- Problem description (what you tried, what happened)
- Reproduction steps
- Suggested fix
- Affected packages

### Step 8: Check for duplicate issues

Before filing, search existing open dogfood issues:

```bash
gh issue list --label dogfood --state open --json title,number -q '.[] | "\(.number)\t\(.title)"'
```

Compare each new issue title/keywords against existing ones. If a likely duplicate exists, skip it and note in the summary.

### Step 9: File GitHub Issues

For each non-duplicate issue, create a GitHub Issue. **Replace all `{...}` placeholders with actual values before running the command:**

```bash
gh issue create \
  --title "[dogfood/{category}] {summary}" \
  --label "dogfood,{category}" \
  --body "$(cat <<'EOF'
## 발견 컨텍스트
- 사이클: #{cycle_number}
- 주제: {topic}
- 페르소나: {persona_name}

## 문제
{description of what you tried and what went wrong}

## 재현 방법
{step by step reproduction}

## 제안하는 해결 방안
{suggested fix approach}

## 영향받는 패키지
- [ ] rfw_gen
- [ ] rfw_gen_builder
- [ ] rfw_gen_mcp
- [ ] rfw_preview
EOF
)"
```

If `gh issue create` fails, retry once. If it fails again, output the issue content to the terminal and tell the user to create it manually.

### Step 10: Output cycle summary

```
## Dogfood Cycle #{N} Summary

📋 주제: {topic}
🎭 페르소나: {persona name}
📦 의존성: rfw_gen ^x.y.z, rfw_preview ^x.y.z

### 발견된 이슈 ({count}건)
| # | 카테고리 | 이슈 | GitHub |
|---|---------|------|--------|
| 1 | {cat}   | {summary} | #{issue_number} |

### 다음 사이클로 이연 ({count}건)
- {deferred issues, if any}

### 중복으로 스킵 ({count}건)
- {skipped duplicates, if any}
```

If zero issues were found, output:

```
## Dogfood Cycle #{N} Summary — Clean Cycle ✅

📋 주제: {topic}
🎭 페르소나: {persona name}

No issues discovered. All tested patterns worked as expected.
```

## Fix Mode

### Step 1: List open dogfood issues

```bash
gh issue list --label dogfood --state open --json number,title,labels -q '.[] | "\(.number)\t\(.title)\t\([.labels[].name] | join(","))"'
```

### Step 2: Present issues sorted by priority

Sort by category priority: bug > dx > feature > docs

Present the list to the user and recommend which issue to tackle first (highest priority). Let the user choose.

### Step 3: Start work on selected issue

Read the full issue body:

```bash
gh issue view {number} --json body,title -q '.title + "\n\n" + .body'
```

Then delegate to the git-workflow skill to create a worktree:

> Use `/git-workflow start fix/dogfood-{issue_number}` to create an isolated worktree.

### Step 4: Implement the fix

Work in the worktree to fix the issue. Follow the "제안하는 해결 방안" from the issue body as a starting point. Run tests to verify:

```bash
melos exec -- dart test
dart analyze
```

### Step 5: Create PR and link to issue

Use `/git-workflow finish` to push and create a PR.

After the PR is created, add a comment to the issue:

```bash
gh issue comment {number} --body "Fix submitted in PR #{pr_number}"
```
