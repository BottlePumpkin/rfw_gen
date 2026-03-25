# rfw_gen

Flutter Widget 코드를 RFW(Remote Flutter Widgets) 형식으로 변환하는 코드 생성기.

## 아키텍처

모노레포 구조:
- `packages/rfw_gen/` — 코어: 어노테이션(@RfwWidget) + 변환 엔진(RfwConverter) + 위젯 매핑(WidgetRegistry)
- `packages/rfw_gen_builder/` — build_runner generator
- `example/` — 예제 앱 + Widgetbook 디버깅

## 브랜치 규칙

- **main 직접 커밋 금지** — 반드시 feature 브랜치에서 PR로 머지
- 작업 시작 전 반드시 `git checkout -b <type>/<description>` 으로 브랜치 생성
- 브랜치 타입: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`
- 예시: `feat/error-reporting`, `fix/offset-missing`, `release/0.5.0`
- 패키지 접두사 불필요 (rfw_gen + rfw_gen_builder는 대부분 함께 변경)
- `.githooks/pre-commit`이 main 직접 커밋을 차단함

## 릴리스 규칙

- `rfw_gen`, `rfw_gen_builder`, `rfw_gen_mcp` 버전은 항상 동일하게 유지
- semver 준수: breaking change → major, 기능 추가 → minor, 버그 수정 → patch
- 릴리스 절차: `release/x.y.z` 브랜치 → CHANGELOG + 버전 범프 → PR → main → tag → pub.dev
- 핫픽스도 `release/x.y.z` 브랜치 사용 (patch 버전)

## 개발 규칙

- 위젯 매핑 추가 시 반드시 유닛 + 통합 + 골든 테스트 동반
- rfwtxt 출력은 반드시 `parseLibraryFile()`로 파싱 검증
- 지원 안 되는 패턴은 빌드 타임 에러 + 대안 제안
- `@RfwWidget`은 top-level 함수에만 사용
- 골든 이미지는 Linux CI에서만 생성/업데이트
- `flutter test --tags golden`으로 골든 테스트 분리 실행
- 골든 테스트 인프라: example/test/helpers/golden_test_helper.dart

## 명령어

- `melos bootstrap` — 패키지 의존성 설치
- `melos exec -- dart test` — 전체 테스트
- `dart analyze` — 정적 분석
- `cd example && flutter test --tags golden` — 골든 테스트 실행
- `cd example && flutter test --exclude-tags golden` — 골든 제외 테스트

## 참고

- @rules/rfw-syntax.md: rfwtxt 문법
- @rules/rfw-widgets.md: 위젯 목록 + 파라미터
- @rules/rfw-types.md: 인자 타입 인코딩
- @agents/golden-test-writer.md: 골든 테스트 작성 에이전트
- @skills/add-golden-test.md: 골든 테스트 추가 스킬
