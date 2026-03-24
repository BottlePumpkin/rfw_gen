# Golden Test Writer Agent

골든 테스트를 작성하는 에이전트.

## 필수 참조

- 스펙: docs/superpowers/specs/2026-03-24-quality-golden-tests-design.md
- 플랜: docs/superpowers/plans/2026-03-24-quality-golden-tests.md
- 헬퍼: example/test/helpers/golden_test_helper.dart
- 기존 테스트: example/test/golden_catalog_*_test.dart

## 테스트 패턴

```dart
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'helpers/golden_test_helper.dart';

void main() {
  late GoldenTestHelper helper;

  setUpAll(() async {
    await loadTestFonts();
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/golden_stub'),
      tolerance: 0.005,
    );
  });

  setUp(() async {
    helper = GoldenTestHelper();
    await helper.setUp();
  });

  tearDown(() => helper.dispose());

  testWidgets('widgetName golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'widgetName');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/{category}/widget_name.png'),
    );
  });
}
```

## 워크플로우

1. 대상 위젯의 카테고리 확인 (main.dart의 _catalogWidgets)
2. 해당 카테고리 테스트 파일에 testWidgets 블록 추가
3. 골든 이미지 생성: `cd example && flutter test {file} --update-goldens --tags golden`
4. 비교 테스트 실행: `cd example && flutter test {file} --tags golden`
5. 골든 이미지 육안 확인
6. 커밋

## 카테고리 → 테스트 파일 매핑

| main.dart 카테고리 키 | 테스트 파일명 slug |
|----------------------|------------------|
| Layout | layout |
| Scrolling | scrolling |
| Styling & Visual | styling |
| Transform | transform |
| Interaction | interaction |
| Material | material |
| Other | other |

## 주의사항

- 골든 이미지는 Linux CI 기준. macOS 로컬과 다를 수 있음
- Stateful 위젯은 초기 상태만 검증
- 네트워크 이미지는 loadTestFonts()의 HttpOverrides로 처리됨
- 골든 파일 경로: goldens/catalog/{category}/{widget_name}.png
- 이커머스: goldens/ecommerce/{screen_name}.png
