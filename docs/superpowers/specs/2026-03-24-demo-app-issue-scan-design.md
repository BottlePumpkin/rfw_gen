# Demo App Issue Scan Design

## Summary

rfw_gen 데모 앱(Catalog 56개 위젯 + Shop 5개 화면)에서 남은 이슈를 체계적으로 탐지하기 위한 3-레이어 병렬 스캔 전략.

## Background

최근 수정된 버그:
1. `InstanceCreationExpression` 미처리로 const 생성자 값(Color, EdgeInsets, TextStyle 등) silent drop
2. Icon/Image의 iconData/imageProvider가 중첩 구조로 변환되어 RFW 런타임에서 렌더링 실패
3. 정수 리터럴이 double로 변환되지 않아 RFW 인코딩 오류

이런 이슈가 다른 위젯/표현식에도 남아 있을 수 있어 전수 스캔이 필요.

## Approach

3개 병렬 에이전트로 동시 스캔 후 통합 리포트 작성.

## Layer 1: Code Gap Analysis

### Target Files
- `expression_converter.dart` (33K) — Dart 표현식 → RFW 변환 핵심
- `ast_visitor.dart` (12K) — AST 트리 순회 및 위젯 파라미터 추출
- `widget_registry.dart` (35K) — 56개 위젯 파라미터 매핑 정의
- `rfwtxt_emitter.dart` (8K) — IR → rfwtxt 직렬화 (타입별 출력 처리 누락 가능)
- `rfw_icons.dart` — Icon 관련 유틸리티 (Icon/Image 구조 관련)

### Excluded (참고)
- `converter.dart` — 오케스트레이터로 변환 로직 자체는 없음
- `rfw_handler.dart` — 이벤트 핸들러 전용, 파라미터 변환과 무관

### Analysis Points
- `switch`/`if-else` 분기에서 `default`/`else`가 silent drop하는 케이스
- `catch` 블록이 에러를 삼키고 빈 값 반환하는 곳
- 미처리 Expression 타입 (ConditionalExpression, BinaryExpression, IndexExpression 등)
- widget_registry 등록 파라미터 vs expression_converter 처리 가능 타입의 불일치
- `// TODO`, `// FIXME` 마커

### Output
미처리 케이스 목록 + 영향받는 위젯 매핑

## Layer 2: rfwtxt Output Verification

### Target Files
- `catalog_widgets.dart` (771줄) ↔ `catalog_widgets.rfwtxt`
- `shop_widgets.dart` (440줄) ↔ `shop_widgets.rfwtxt`

### Verification Method
- 원본에서 명시적으로 설정한 파라미터가 rfwtxt에 존재하는지 위젯별 대조
- 의심 패턴 탐지:
  - 빈 중괄호 `{}` — 파라미터 전체 누락
  - 값 없는 키 — 변환 실패로 기본값만 남은 경우
  - `null` 리터럴 — 변환 못 해서 null로 빠진 경우
  - 중첩 구조 이상 — flat해야 할 구조가 중첩된 경우
- 카테고리별(Layout, Scrolling, Styling, Material 등) 누락률 집계

### Output
위젯별 파라미터 누락/이상 목록 + 카테고리별 요약

## Layer 2.5: RFW Binary Validation

### Actions
- 현재 생성된 `.rfw` 바이너리를 `parseLibraryFile()`로 파싱
- 파싱 실패 또는 경고 발생 시 인코딩 이상으로 분류

### Target Files
- `example/assets/catalog_widgets.rfw` (21K)
- `example/assets/shop_widgets.rfw` (11K)

### Output
바이너리 파싱 에러/경고 목록

## Layer 3: Build & Static Analysis

### Actions
- `flutter analyze` — 데모 앱 lint 경고, 미사용 import, 타입 에러
- `flutter build apk --debug` — 컴파일 에러 확인
- `dart analyze` — 코어 패키지(rfw_gen) 정적 분석

### Scope
- `example/` — 데모 앱
- `packages/rfw_gen/` — 코어 라이브러리

### Output
빌드 에러/경고 목록

## Integrated Report

### Severity Levels
1. **Critical** — 변환 시 데이터가 에러 없이 사라지는 silent drop (예: 미처리 Expression 타입)
2. **High** — 변환은 되지만 RFW 런타임에서 렌더링 깨지는 구조 불일치, 또는 빌드 자체가 실패하는 인코딩 오류
3. **Medium** — 빌드 경고, 미사용 코드, 타입 불일치
4. **Low** — TODO/FIXME, 코드 스타일, 개선 가능 사항

### Fix Flow
1. 리포트 제시
2. 우선순위/범위 승인
3. Critical → High → Medium 순으로 수정
4. rfwtxt/rfw 바이너리 재생성
5. 검증 체크리스트:
   - Critical: 유닛 테스트 + rfwtxt diff + `parseLibraryFile()` 파싱 + 데모 앱 렌더링 확인
   - High: 유닛 테스트 + rfwtxt diff + `parseLibraryFile()` 파싱
   - Medium: `dart analyze` + `flutter analyze` 통과
6. 발견된 Critical/High 이슈별 회귀 테스트 추가
