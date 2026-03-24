# Branch Strategy & Release Rules Design Spec

## Problem

main 브랜치에 직접 커밋이 가능하여 실수로 스펙/구현이 main에 들어갈 수 있다. 브랜치 네이밍, 릴리스 전략, 보호 규칙이 정의되어 있지 않다.

## Solution

### 브랜치 네이밍 규칙

```
feat/error-reporting       — 새 기능
fix/offset-missing         — 버그 수정
docs/publishing-spec       — 문서
chore/ci-golden-tests      — CI, 의존성, 설정
refactor/expression-converter — 리팩터링
test/collector-unit-tests  — 테스트 추가/수정
release/0.5.0              — 릴리스 준비 (핫픽스 포함)
```

타입: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`

패키지 접두사는 사용하지 않는다. `rfw_gen`과 `rfw_gen_builder`는 tightly coupled이며 대부분 함께 변경된다.

### 버전 전략

- 두 패키지(`rfw_gen`, `rfw_gen_builder`) 버전을 항상 동일하게 유지
- semver 준수: breaking change → major, 기능 추가 → minor, 버그 수정 → patch
- `melos version`으로 동시 버전 범프
- 핫픽스도 `release/x.y.z` 브랜치 사용 (patch 버전)

### 릴리스 흐름

```
main (보호됨, PR만 허용)
  ├── feat/error-reporting → PR → main
  ├── fix/offset-bug → PR → main
  └── release/0.5.0 → CHANGELOG + 버전 범프 → PR → main → tag v0.5.0 → pub.dev
```

### main 브랜치 보호

#### 1. Git pre-commit hook

`.githooks/pre-commit`에 main 직접 커밋 차단 스크립트를 추가한다. `.git/hooks/`가 아닌 `.githooks/`에 두어 git으로 공유 가능하게 한다.

```bash
#!/bin/sh
branch=$(git branch --show-current)
if [ "$branch" = "main" ] || [ "$branch" = "master" ]; then
  echo "ERROR: main 브랜치에 직접 커밋할 수 없습니다."
  echo "브랜치를 만드세요: git checkout -b feat/your-feature"
  exit 1
fi
```

`git config core.hooksPath .githooks`로 활성화한다.

#### 2. CLAUDE.md 규칙 추가

개발 규칙 섹션에 브랜치/릴리스 규칙을 추가한다.

#### 3. GitHub branch protection

`gh api`로 main 브랜치 보호 규칙을 설정한다:
- PR 필수
- 직접 push 차단

## 변경 파일

| 파일 | 변경 |
|------|------|
| `.githooks/pre-commit` (신규) | main 직접 커밋 차단 hook |
| `.claude/CLAUDE.md` | 브랜치/릴리스 규칙 추가 |
| GitHub settings | branch protection rule 추가 |

## 테스트

- hook이 main에서 커밋 차단하는지 확인
- hook이 feature 브랜치에서는 커밋 허용하는지 확인
