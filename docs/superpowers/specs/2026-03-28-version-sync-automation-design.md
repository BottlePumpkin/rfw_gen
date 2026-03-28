# Version Sync Automation Design

## Problem

rfw_gen monorepo의 4개 코어 패키지와 playground 간 버전 동기화가 완전 수동이다. 릴리즈 시 5개 pubspec.yaml을 일일이 수정해야 하고, playground는 현재 v0.4.0에 멈춰있다 (코어는 v0.5.1). 버전 불일치를 잡아주는 CI 검증도 없다.

## Goals

1. 버전의 single source of truth 확립
2. 모든 패키지 버전을 한 번에 동기화하는 스크립트
3. CI에서 버전 불일치를 자동 감지
4. pub.dev 게시 후 playground 의존성 자동 업데이트

## Non-Goals

- CHANGELOG 자동 생성 (내용은 수동 작성)
- melos versioning 기능 도입 (현재 minimal 사용 유지)
- playground를 melos workspace에 포함

---

## Design

### 1. Single Source of Truth: `VERSION` 파일

루트에 `VERSION` 파일 생성. 내용은 버전 문자열 한 줄만:

```
0.5.1
```

이 파일이 모든 패키지 버전의 유일한 원천이 된다.

### 2. 동기화 스크립트: `tool/sync_versions.dart`

Dart 스크립트가 `VERSION` 파일을 읽어서 모든 pubspec.yaml을 업데이트한다.

**업데이트 대상 (코어 패키지만):**

| 파일 | 필드 | 규칙 |
|------|------|------|
| `packages/rfw_gen/pubspec.yaml` | `version:` | exact (`0.6.0`) |
| `packages/rfw_gen_builder/pubspec.yaml` | `version:` | exact (`0.6.0`) |
| `packages/rfw_gen_builder/pubspec.yaml` | `rfw_gen:` dep | caret minor floor (`^0.6.0`) |
| `packages/rfw_gen_mcp/pubspec.yaml` | `version:` | exact (`0.6.0`) |
| `packages/rfw_gen_mcp/pubspec.yaml` | `rfw_gen:` dep | caret minor floor (`^0.6.0`) |
| `packages/rfw_gen_mcp/pubspec.yaml` | `rfw_gen_builder:` dep | caret minor floor (`^0.6.0`) |
| `packages/rfw_preview/pubspec.yaml` | `version:` | exact (`0.6.0`) |

**의존성 버전 규칙:**
- 코어 패키지 간: `^{major}.{minor}.0` (minor floor) — patch 버전 간 호환성 보장
- playground: 별도 workflow에서 exact caret (`^0.6.0`) 사용

**playground는 건드리지 않는다** — pub.dev에 아직 없는 버전으로 업데이트하면 빌드 실패.

**스크립트 동작:**
1. `VERSION` 파일 읽기
2. 정규식으로 각 pubspec.yaml의 `version:` 필드 교체
3. 크로스 의존성 버전도 규칙에 따라 교체
4. 변경 사항 출력 (dry-run 모드 지원: `--dry-run`)
5. 변경 없으면 "Already in sync" 메시지

**사용법:**
```bash
# 릴리즈 준비 시
echo "0.6.0" > VERSION
dart run tool/sync_versions.dart

# 확인만 하고 싶을 때
dart run tool/sync_versions.dart --dry-run
```

### 3. CI 버전 검증: `check-versions` job

`.github/workflows/ci.yml`에 `check-versions` job 추가. 모든 PR에서 실행된다.

**검증 항목:**

1. **VERSION 파일 존재 여부**
2. **코어 4개 패키지 version 필드가 VERSION과 일치하는지**
3. **크로스 의존성 버전이 호환되는지** (minor floor 규칙 준수)

**구현 방식:** Dart 스크립트 `tool/check_versions.dart`

- sync_versions.dart와 동일한 파싱 로직 공유 (공통 유틸)
- 불일치 발견 시 구체적 에러 메시지 출력:
  ```
  ERROR: Version mismatch detected!
    VERSION file: 0.6.0
    packages/rfw_gen_builder/pubspec.yaml version: 0.5.1 (expected: 0.6.0)
    packages/rfw_gen_mcp/pubspec.yaml rfw_gen dep: ^0.5.0 (expected: ^0.6.0)

  Run: dart run tool/sync_versions.dart
  ```
- exit code 1로 CI 실패

**CI workflow 추가:**
```yaml
check-versions:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: dart-lang/setup-dart@v1
    - name: Check version consistency
      run: dart run tool/check_versions.dart
```

### 4. Publish → Playground 자동 업데이트

#### 4a. publish.yml 개선

현재 `continue-on-error: true`는 부분 실패를 감춘다. 개선:
- `continue-on-error` 제거
- 이미 게시된 버전이면 skip하는 로직 추가 (멱등성)
- 전체 workflow 성공/실패가 명확해짐

#### 4b. 새 workflow: `update-playground.yml`

```yaml
name: Update Playground Dependencies

on:
  workflow_run:
    workflows: ['Publish to pub.dev']
    types: [completed]

jobs:
  update-playground:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
    steps:
      - uses: actions/checkout@v4

      - name: Read VERSION
        id: version
        run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT

      - name: Wait for pub.dev indexing
        run: |
          VERSION=${{ steps.version.outputs.version }}
          for i in {1..10}; do
            if dart pub deps --directory=rfw_gen_playground 2>/dev/null; then
              echo "Dependencies resolved successfully"
              exit 0
            fi
            echo "Attempt $i: waiting for pub.dev indexing..."
            sleep 30
          done
          echo "ERROR: pub.dev indexing timeout"
          exit 1

      - name: Update playground dependencies
        run: |
          VERSION=${{ steps.version.outputs.version }}
          sed -i "s/rfw_gen: \^.*/rfw_gen: ^${VERSION}/" rfw_gen_playground/pubspec.yaml
          sed -i "s/rfw_gen_builder: \^.*/rfw_gen_builder: ^${VERSION}/" rfw_gen_playground/pubspec.yaml

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

#### 4c. deploy-playground.yml 변경 없음

기존 `push` + `paths` 트리거 유지. playground PR 머지 시 자동 배포된다.

### 5. 파일 구조

```
rfw_gen/
├── VERSION                              # NEW: single source of truth
├── tool/
│   ├── sync_versions.dart               # NEW: 버전 동기화 스크립트
│   ├── check_versions.dart              # NEW: CI 검증 스크립트
│   └── version_utils.dart               # NEW: 공통 파싱 유틸
├── .github/workflows/
│   ├── ci.yml                           # MODIFIED: check-versions job 추가
│   ├── publish.yml                      # MODIFIED: continue-on-error 제거
│   ├── update-playground.yml            # NEW: 자동 playground 업데이트
│   └── deploy-playground.yml            # UNCHANGED
```

---

## 릴리즈 플로우 (End-to-End)

```
개발자 작업:
  1. VERSION 파일 수정 (0.5.1 → 0.6.0)
  2. dart run tool/sync_versions.dart
  3. CHANGELOG.md 수동 작성
  4. release/0.6.0 브랜치 → PR 생성

자동화:
  5. CI: check-versions job 실행 → 버전 일치 확인 ✅
  6. CI: analyze-and-test job 실행 → 테스트 통과 ✅
  7. PR 머지 → main
  8. tag v0.6.0 생성 → publish.yml 트리거
  9. pub.dev 순차 게시 (rfw_gen → builder → mcp → preview)
  10. publish 완료 → update-playground.yml 트리거
  11. pub.dev 인덱싱 대기 (retry with backoff, max 5분)
  12. playground pubspec.yaml 업데이트 PR 자동 생성
  13. PR 리뷰 + 머지
  14. deploy-playground.yml → GitHub Pages 재배포
```

## Edge Cases

| 시나리오 | 대응 |
|----------|------|
| VERSION 파일 없이 PR 생성 | CI check-versions 실패, 명확한 에러 메시지 |
| sync_versions 실행 안 하고 PR | CI 불일치 감지, `Run: dart run tool/sync_versions.dart` 안내 |
| pub.dev 인덱싱 5분 초과 | update-playground workflow 실패, 수동 재실행 (workflow_dispatch) |
| publish 부분 실패 | workflow_run conclusion != success → playground 업데이트 안 함 |
| playground 외 다른 의존성도 업데이트 필요 | update-playground.yml에서 sed 패턴 추가 |

## CLAUDE.md 업데이트

Release Rules 섹션에 추가:
```
- VERSION 파일이 모든 패키지 버전의 single source of truth
- 버전 변경 시: VERSION 수정 → dart run tool/sync_versions.dart → PR
- CI가 자동으로 버전 일치 검증
- pub.dev 게시 후 playground 의존성은 자동 PR로 업데이트됨
```
