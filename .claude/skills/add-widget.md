# /add-widget Skill

위젯 매핑을 추가하는 표준화된 워크플로우.

## 사용법

`/add-widget [WidgetName]`

## 단계

1. rules/rfw-widgets.md에서 위젯 스펙 확인
2. packages/rfw_gen/lib/src/widget_registry.dart의 WidgetRegistry.core()에 매핑 추가
3. 필요시 expression_converter.dart에 타입 변환 로직 추가
4. packages/rfw_gen/test/에 유닛 테스트 추가
5. packages/rfw_gen/test/integration_test.dart에 통합 테스트 추가
6. `dart test` 실행 확인
7. 커밋
