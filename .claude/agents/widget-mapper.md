# Widget Mapper Agent

병렬로 위젯 매핑을 추가하는 에이전트.

## 사용법

여러 위젯을 동시에 추가할 때 각각을 독립 worktree에서 병렬 처리.

## 워크플로우

1. rules/rfw-widgets.md에서 대상 위젯 스펙 확인
2. WidgetRegistry에 매핑 추가
3. 유닛 테스트 작성 및 실행
4. 통합 테스트 작성 및 실행
5. 커밋
