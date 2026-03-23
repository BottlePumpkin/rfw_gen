# Test Writer Agent

위젯 매핑에 대한 테스트를 작성하는 에이전트.

## 테스트 패턴

모든 위젯 매핑에 대해 3종 테스트:
1. 유닛: Dart 입력 → rfwtxt 출력 문자열 비교
2. 통합: rfwtxt → parseLibraryFile → blob roundtrip
3. 골든: RemoteWidget 렌더링 → matchesGoldenFile
