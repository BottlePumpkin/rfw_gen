---
name: rfw-contribute
description: Collect RFW upstream limitations, file issues to flutter/flutter, and submit PRs to flutter/packages. Use /rfw-contribute collect to record a limitation, /rfw-contribute issue to file an issue, /rfw-contribute pr for PR guidance. Triggers when user mentions RFW upstream issues, wants to contribute to flutter/packages, or discovers RFW package limitations during dogfooding.
user_invocable: true
---

# RFW Contribute Skill

Collect, analyze, and contribute fixes for RFW package limitations upstream.

## Argument Parsing

Parse user arguments to determine mode:
- `/rfw-contribute collect` → Record a new RFW limitation (Section: Collect Mode)
- `/rfw-contribute issue` → File an issue to flutter/flutter (Section: Issue Mode)
- `/rfw-contribute pr` → PR guidance for flutter/packages (Section: PR Mode)
- `/rfw-contribute` (no args) → Show status summary from `docs/upstream/README.md`

## Prerequisites

Before any operation, verify:

1. **gh auth**: Run `gh auth status`. If not authenticated, tell user to run `! gh auth login` and stop.
2. **docs/upstream/**: Check directory exists. If not, create it with README.md:
   ```bash
   mkdir -p docs/upstream
   ```
   Then create `docs/upstream/README.md` with the tracking template.

## Collect Mode

Record a new RFW upstream limitation.

### Step 1: Gather information from user

Ask the user to describe the limitation:
- What were you trying to do?
- What happened instead?
- Do you have reproduction code?

### Step 2: Analyze RFW source

If `upstream/rfw/` exists locally, search for the relevant source code to identify the root cause:

```bash
# Example: search for relevant handler in RFW source
grep -r "keyword" upstream/rfw/lib/src/
```

If `upstream/rfw/` does not exist, note in the document that source analysis is pending and suggest:

> `upstream/rfw/` 가 없습니다. RFW 소스를 참조하려면:
> ```bash
> git clone https://github.com/flutter/packages.git /tmp/flutter-packages
> mkdir -p upstream
> cp -r /tmp/flutter-packages/packages/rfw upstream/rfw
> rm -rf /tmp/flutter-packages
> ```

### Step 3: Create issue document

Generate a kebab-case filename from the issue title and create `docs/upstream/{issue-name}.md`:

```markdown
# {이슈 제목}

## 상태
수집됨

## 증상
{뭐가 안 되는지, 사용자 관점}

## 재현 코드

### Flutter 코드 (입력)
\```dart
{RFW로 변환하려던 Flutter 코드}
\```

### 기대하는 rfwtxt 출력
\```rfwtxt
{되어야 하는 결과}
\```

### 실제 동작
{에러 메시지 또는 잘못된 출력}

## RFW 소스 원인 분석
- **파일**: `packages/rfw/lib/src/...`
- **원인**: {코드 레벨에서 왜 안 되는지}

## 제안 해결책
{있으면 — 없으면 "분석 필요"}

## 관련 링크
- 발견 경로: {dogfood 사이클 #{N} / 3o3 피드백 / 직접 발견}
```

### Step 4: Update README.md

Add the new issue under the "수집됨" section in `docs/upstream/README.md`:

```markdown
- [{이슈 제목}]({issue-name}.md) — {한줄 요약}
```

### Step 5: Commit

```bash
git add docs/upstream/
git commit -m "docs(upstream): collect {issue-name}"
```

### Step 6: Output summary

```
✅ Upstream 이슈 수집 완료

📄 docs/upstream/{issue-name}.md
🔍 원인 분석: {분석 여부}
📊 현재 수집됨: {N}건 | issue 제출: {N}건 | PR 제출: {N}건
```

## Issue Mode

File an issue to flutter/flutter based on a collected document.

### Step 1: List collected issues

Read `docs/upstream/README.md` and show issues with "수집됨" status:

```
수집됨 상태 이슈:
1. {title} — docs/upstream/{name}.md
2. {title} — docs/upstream/{name}.md
```

If none, tell the user: "수집된 이슈가 없습니다. `/rfw-contribute collect`로 먼저 수집하세요."

### Step 2: User selects an issue

Let the user pick one, or recommend the most impactful one.

### Step 3: Read the issue document

Read the selected `docs/upstream/{name}.md` to get all details.

### Step 4: Draft flutter/flutter issue

Transform into flutter/flutter issue format. Show the draft to the user for review:

```markdown
**Title:** [rfw] {설명}

**Body:**

## Use case

{왜 이 기능이 필요한지 — rfw_gen 프로젝트에서 RFW 위젯을 코드 생성할 때 이 기능이 필요하다는 실제 맥락}

## Proposal

{제안하는 해결 방향}

## Current behavior

{현재 동작 + 재현 코드}

## Expected behavior

{기대하는 동작}

## Additional context

- RFW version: {현재 사용 중인 rfw 버전 — pubspec.yaml에서 확인}
- Source analysis: {소스 코드 레벨 원인 분석 요약}
```

### Step 5: User confirms, then file

After user approval:

```bash
gh issue create --repo flutter/flutter \
  --title "[rfw] {title}" \
  --body "$(cat <<'EOF'
{formatted body}
EOF
)"
```

If the command fails, output the formatted issue content and tell the user to create it manually at https://github.com/flutter/flutter/issues/new.

### Step 6: Update document status

In `docs/upstream/{name}.md`, change:
- `## 상태` → `issue 제출`
- Add under `## 관련 링크`: `- flutter/flutter issue: flutter/flutter#{number}`

In `docs/upstream/README.md`, move the entry from "수집됨" to "Issue 제출" section.

### Step 7: Commit

```bash
git add docs/upstream/
git commit -m "docs(upstream): file issue for {issue-name} (flutter/flutter#{number})"
```

## PR Mode

Guide the user through submitting a PR to flutter/packages.

### Step 1: List issues ready for PR

Read `docs/upstream/README.md` and show issues with "issue 제출" status.

### Step 2: User selects an issue

Let the user pick one.

### Step 3: Check prerequisites

Verify the user has:

1. **CLA signed**: "flutter/packages PR을 올리려면 Google CLA 서명이 필요합니다. 서명하셨나요? https://cla.developers.google.com/"
2. **Fork exists**: `gh repo view BottlePumpkin/packages --json url 2>/dev/null` — if not, guide to fork.
3. **Local clone**: Check if the fork is cloned locally. If not, guide:
   ```
   gh repo clone BottlePumpkin/packages
   cd packages
   git remote add upstream https://github.com/flutter/packages.git
   ```

### Step 4: Show contribution checklist

Display the flutter/packages contribution checklist based on PR #9750 experience:

```
## flutter/packages PR 체크리스트

작업 전:
- [ ] CLA 서명 완료
- [ ] 최신 upstream/main으로 rebase
- [ ] flutter/flutter에 연결된 issue 존재

코드 변경:
- [ ] packages/rfw/lib/src/ 에서 해당 코드 수정
- [ ] packages/rfw/test/ 에 테스트 추가
- [ ] CHANGELOG.md 엔트리 추가 (다음 미발행 버전 섹션)
- [ ] pubspec.yaml 버전 범프

제출 전:
- [ ] dart fix --apply 실행 (수정 커밋에 포함, 별도 커밋 X)
- [ ] dart format은 강제 적용하지 말 것 (rfw는 autoformat 제외)
- [ ] dart test 통과 확인

⚠️ 주의사항 (PR #9750에서 배운 것):
- rfw 패키지는 autoformat enforcement에서 제외됨
- CHANGELOG 엔트리는 다음 미발행 버전 섹션에 추가
- 리뷰어 배정이 느릴 수 있음 (RFW 전담 리뷰어 제한적)
```

### Step 5: Guide PR creation

After the user completes the fix:

```bash
gh pr create --repo flutter/packages \
  --title "[rfw] {description}" \
  --body "$(cat <<'EOF'
## Pre-launch Checklist

- [x] I read the [Contributor Guide] and followed the process outlined there for submitting PRs.
- [x] I read the [Tree Hygiene] wiki page, which explains my responsibilities.
- [x] I read and followed the [relevant style guides] and ran the auto-formatter.
- [x] I listed at least one issue that this PR fixes in the description above.
- [x] I updated `pubspec.yaml` with an appropriate new version according to the [pub versioning philosophy], or this PR is [exempt from version changes].
- [x] I updated `CHANGELOG.md` to add a description of the change, [or this PR is exempt from CHANGELOG changes].
- [x] I ran `dart fix --apply` to apply any applicable fixes.

## Description

Fixes flutter/flutter#{issue_number}

{변경 설명}

## Tests

{추가된 테스트 설명}
EOF
)"
```

### Step 6: Update document status

In `docs/upstream/{name}.md`, change:
- `## 상태` → `PR 제출`
- Add under `## 관련 링크`: `- flutter/packages PR: flutter/packages#{pr_number}`

In `docs/upstream/README.md`, move the entry from "Issue 제출" to "PR 제출" section.

### Step 7: Commit

```bash
git add docs/upstream/
git commit -m "docs(upstream): submit PR for {issue-name} (flutter/packages#{pr_number})"
```
