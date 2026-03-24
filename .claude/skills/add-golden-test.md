# /add-golden-test Skill

기존 위젯에 대한 골든 테스트를 추가하는 워크플로우.

## 사용법

`/add-golden-test [widgetName]`

## 단계

1. example/lib/main.dart의 `_catalogWidgets`에서 위젯 카테고리 확인
2. 해당 카테고리의 `example/test/golden_catalog_{category}_test.dart`에 testWidgets 블록 추가
3. 네트워크 이미지 사용 여부 확인 (loadTestFonts()에서 HttpOverrides 이미 설정됨)
4. `cd example && flutter test {file} --update-goldens --tags golden` 으로 골든 생성
5. `cd example && flutter test {file} --tags golden` 으로 비교 테스트 통과 확인
6. 생성된 골든 이미지(goldens/catalog/{category}/{widget_name}.png) 육안 확인
7. 커밋

## 참조

- 헬퍼: example/test/helpers/golden_test_helper.dart
- 스펙: docs/superpowers/specs/2026-03-24-quality-golden-tests-design.md
- 에이전트: .claude/agents/golden-test-writer.md
