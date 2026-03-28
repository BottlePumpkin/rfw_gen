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

**rfw_preview 참고:** rfw_preview는 현재 다른 코어 패키지에 대한 의존성이 없다 (rfw만 의존). 향후 rfw_gen 의존성이 추가되면 위 테이블에 항목 추가 필요.

**스크립트 동작:**
1. `VERSION` 파일 읽기
2. 정규식으로 각 pubspec.yaml의 `version:` 필드 교체
3. 크로스 의존성 버전도 규칙에 따라 교체
4. 변경 사항 출력
5. 변경 없으면 "Already in sync" 메시지

**모드:**
- `--check`: 파일 수정 없이 불일치만 검사, exit code 1로 실패 (CI용)
- `--dry-run`: 변경 내용 미리보기 (수정 없음)
- (기본): 실제 파일 수정

> `--check` 모드가 CI 검증도 담당하므로 별도 `check_versions.dart`는 필요 없다.
> 검증과 동기화 로직이 하나의 스크립트에 있어 드리프트 위험이 없다.

**사용법:**
```bash
# 릴리즈 준비 시
echo "0.6.0" > VERSION
dart tool/sync_versions.dart

# CI 검증 (불일치 시 exit 1)
dart tool/sync_versions.dart --check

# 미리보기
dart tool/sync_versions.dart --dry-run
```

> **호출 방식 주의:** `dart run tool/...`이 아닌 `dart tool/...`을 사용한다.
> 루트가 workspace pubspec이므로 `dart run`은 패키지 컨텍스트를 찾지 못한다.

### 3. CI 버전 검증: `check-versions` job

`.github/workflows/ci.yml`에 `check-versions` job 추가. 모든 PR에서 실행된다.

**검증 항목:**

1. **VERSION 파일 존재 여부**
2. **코어 4개 패키지 version 필드가 VERSION과 일치하는지**
3. **크로스 의존성 버전이 호환되는지** (minor floor 규칙 준수)

**구현:** `sync_versions.dart --check` 모드 사용 (별도 스크립트 불필요).

불일치 발견 시 구체적 에러 메시지 출력:
```
ERROR: Version mismatch detected!
  VERSION file: 0.6.0
  packages/rfw_gen_builder/pubspec.yaml version: 0.5.1 (expected: 0.6.0)
  packages/rfw_gen_mcp/pubspec.yaml rfw_gen dep: ^0.5.0 (expected: ^0.6.0)

Run: dart tool/sync_versions.dart
```

**CI workflow 추가:**
```yaml
check-versions:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: dart-lang/setup-dart@v1
    - name: Check version consistency
      run: dart tool/sync_versions.dart --check
```

### 4. Publish → Playground 자동 업데이트

#### 4a. publish.yml 개선

현재 `continue-on-error: true`는 부분 실패를 감춘다. 개선:
- `continue-on-error` 제거
- 이미 게시된 버전이면 skip하는 로직 추가 (멱등성):
  ```bash
  if dart pub publish --dry-run --directory packages/rfw_gen 2>&1 | grep -q "already been published"; then
    echo "Already published, skipping"
  else
    dart pub publish --directory packages/rfw_gen --force
  fi
  ```
- 전체 workflow 성공/실패가 명확해짐
- **tag-VERSION 일치 검증 추가:** publish 시작 전에 `VERSION` 파일 내용과 tag 버전이 일치하는지 확인. 불일치 시 즉시 실패:
  ```bash
  TAG_VERSION="${GITHUB_REF_NAME#v}"  # v0.6.0 → 0.6.0
  FILE_VERSION="$(cat VERSION)"
  if [ "$TAG_VERSION" != "$FILE_VERSION" ]; then
    echo "ERROR: Tag $GITHUB_REF_NAME does not match VERSION file ($FILE_VERSION)"
    exit 1
  fi
  ```

#### 4b. 새 workflow: `update-playground.yml`

```yaml
name: Update Playground Dependencies

on:
  workflow_run:
    workflows: ['Publish to pub.dev']
    types: [completed]
  workflow_dispatch:  # 수동 재실행 지원 (인덱싱 타임아웃 시)

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

      # 1) 먼저 pubspec.yaml 업데이트 (sed 순서 중요: builder를 먼저 처리)
      - name: Update playground dependencies
        run: |
          VERSION=${{ steps.version.outputs.version }}
          # rfw_gen_builder를 먼저 교체 (rfw_gen의 substring이므로)
          sed -i "s/rfw_gen_builder: \^.*/rfw_gen_builder: ^${VERSION}/" rfw_gen_playground/pubspec.yaml
          # 그 후 rfw_gen 교체 (이미 builder는 처리됨, 정확한 키 매칭)
          sed -i "s/^  rfw_gen: \^.*/  rfw_gen: ^${VERSION}/" rfw_gen_playground/pubspec.yaml

      # 2) 업데이트된 pubspec으로 pub.dev 가용성 확인
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

> **sed 순서가 중요한 이유:** `rfw_gen`은 `rfw_gen_builder`의 substring이다.
> `rfw_gen:` 패턴을 먼저 적용하면 `rfw_gen_builder:` 행도 매칭되어 파일이 깨진다.
> 따라서 `rfw_gen_builder`를 먼저 처리하고, `rfw_gen` 교체 시에는 행 시작 인덴트(`^  rfw_gen:`)로 정확히 매칭한다.

#### 4c. deploy-playground.yml 변경 없음

기존 `push` + `paths` 트리거 유지. playground PR 머지 시 자동 배포된다.

### 5. 파일 구조

```
rfw_gen/
├── VERSION                              # NEW: single source of truth
├── tool/
│   └── sync_versions.dart               # NEW: 동기화 + 검증 (--check 모드)
├── .github/workflows/
│   ├── ci.yml                           # MODIFIED: check-versions job 추가
│   ├── publish.yml                      # MODIFIED: tag-VERSION 검증, skip-if-published
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
| pub.dev 인덱싱 5분 초과 | update-playground workflow 실패, `workflow_dispatch`로 수동 재실행 |
| tag와 VERSION 불일치 | publish.yml 시작 시 즉시 실패, 에러 메시지로 안내 |
| publish 부분 실패 | workflow_run conclusion != success → playground 업데이트 안 함 |
| playground 외 다른 의존성도 업데이트 필요 | update-playground.yml에서 sed 패턴 추가 |

## Playground 콘텐츠 동기화 전략

버전 동기화 외에, playground의 **콘텐츠**(위젯 예제, API 사용법)가 코어 패키지 변경과 맞지 않는 문제도 해결한다.

### 문제

- `WidgetRegistry`에 ~60개 위젯이 등록되어 있지만, playground gallery는 커스텀 위젯만 커버
- 코어 위젯의 파라미터가 변경되어도 playground 예제가 구 버전 문법을 사용할 수 있음
- 위젯 추가 시 playground 예제 생성이 수동이라 누락됨

### 해결: 3-layer 방어

#### Layer 1: CI Drift Detection (자동 감지)

CI에 `check-playground-coverage` job 추가. `WidgetRegistry.core()`에 등록된 위젯 목록과 playground의 `widget_gallery.dart` 또는 gallery 예제 목록을 비교한다.

**구현:** `tool/sync_versions.dart`에 `--check-playground` 모드 추가 (또는 별도 스크립트 `tool/check_playground_coverage.dart`).

- `widget_registry.dart`에서 등록된 위젯 이름 추출 (정규식: `'core.XXX'` 또는 `'material.XXX'`)
- `rfw_gen_playground/lib/screens/widget_gallery.dart` 및 `gallery/` 디렉토리에서 커버된 위젯 추출
- 누락된 위젯 목록 출력
- **soft warning** (CI 실패는 아님) — 모든 위젯에 playground 예제가 필수는 아님
- 릴리즈 PR에서 "이 위젯들은 playground에 예제가 없습니다" 리마인더 역할

#### Layer 2: `/add-widget` 스킬 확장 (원천 차단)

현재 `/add-widget` 스킬의 10단계 workflow에 playground 단계 추가:

**기존 Step 6**: `example/lib/catalog/catalog_widgets.dart`에 데모 함수 추가
**새 Step 6.5**: playground gallery에 해당 위젯 예제 화면 추가 (선택적)

- `rfw_gen_playground/lib/screens/gallery/widget_detail_{name}.dart` 생성
- `rfw_gen_playground/remote/manifest.json`에 엔트리 추가
- 위젯의 주요 파라미터와 사용 패턴을 보여주는 예제 코드 포함
- 이 단계는 **optional**로 표시 — 모든 위젯이 gallery 예제가 필요하진 않음

#### Layer 3: `/dogfood` 스킬에 freshness 카테고리 추가

dogfood run 모드의 friction point 수집 시, playground content freshness를 추가 체크 카테고리로 포함:

- playground 예제가 현재 API와 맞는지 확인 (파라미터 이름, 타입, 필수/선택 여부)
- 빌드는 되지만 deprecated 패턴을 사용하는 stale 예제 감지
- 발견된 이슈는 기존 dogfood 파이프라인으로 GitHub Issue 생성 (label: `playground`, `stale`)

### 시나리오별 해결 수단

| 시나리오 | 해결 수단 |
|----------|-----------|
| 새 위젯 추가, 예제 누락 | `/add-widget` Step 6.5 (원천 차단) |
| 스킬 안 쓰고 수동 추가 | CI drift detection (soft warning) |
| 기존 예제가 API 변경으로 stale | `/dogfood` freshness 카테고리 |
| 빌드 깨질 정도의 변경 | 기존 CI 빌드가 이미 감지 |

## CLAUDE.md 업데이트

Release Rules 섹션에 추가:
```
- VERSION 파일이 모든 패키지 버전의 single source of truth
- 버전 변경 시: VERSION 수정 → dart tool/sync_versions.dart → PR
- CI가 자동으로 버전 일치 검증
- pub.dev 게시 후 playground 의존성은 자동 PR로 업데이트됨
```
