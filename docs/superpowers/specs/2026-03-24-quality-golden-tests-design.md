# rfw_gen 품질 강화 — 골든 테스트 체계 구축

**Date**: 2026-03-24
**Status**: Draft
**선행 조건**: example app 미커밋 작업 완료

## Problem

rfw_gen 코어 엔진은 58개 위젯 변환, 동적 기능, 이벤트 핸들러, 커스텀 위젯 등록까지 기능적으로 완성되었다. 그러나 **변환 결과의 시각적 정확성**을 검증하는 골든 테스트가 없다.

현재 테스트 체계:
- ✅ 유닛 테스트 (5,048 LOC) — AST→IR→rfwtxt 변환 로직
- ✅ 통합 테스트 — `parseLibraryFile()` 라운드트립으로 문법 유효성 검증
- ❌ 골든 테스트 — 렌더링 결과 시각적 비교 **미구현** (placeholder만 존재)

"파싱 성공"과 "의도대로 렌더링"은 다른 문제다. `Padding(padding: EdgeInsets.all(16))` 이 파싱은 되지만 실제로 16px 여백이 적용되는지는 골든 테스트만이 검증할 수 있다.

## Goal

- 카탈로그 위젯 전체(41~43개) + 이커머스 화면(5개) = **46~48개 골든 테스트** 완성
- Linux CI 기준 렌더링 일관성 보장
- 골든 테스트 과정에서 발견되는 에지 케이스 수정
- `.claude/` 가이드로 향후 위젯 추가 시 골든 테스트 포함하는 워크플로우 정착

## Scope

### 포함
- 골든 테스트 인프라 (헬퍼, 폰트, 뷰포트, CI 워크플로우)
- 카탈로그 43개 위젯 골든 테스트 (7개 카테고리)
- 이커머스 5개 화면 골든 테스트
- CI (GitHub Actions) 골든 비교 + 업데이트 워크플로우
- `.claude/` 에이전트/스킬 가이드

### 제외
- Example app 마무리 (별도 선행 작업)
- MCP 서버 (후속 작업)
- pub.dev 배포

## Architecture

### 테스트 파일 구조

```
example/test/
├── helpers/
│   ├── golden_test_helper.dart   — RFW Runtime 초기화, 폰트 로드, 뷰포트 설정
│   └── test_data.dart            — mock_data.dart 재사용 또는 테스트 전용 데이터
├── golden_catalog_layout_test.dart      (9개 위젯)
├── golden_catalog_scrolling_test.dart   (4개 위젯)
├── golden_catalog_styling_test.dart     (10개 위젯)
├── golden_catalog_transform_test.dart   (3개 위젯)
├── golden_catalog_interaction_test.dart (2개 위젯)
├── golden_catalog_material_test.dart    (10개 위젯)
├── golden_catalog_other_test.dart       (5개 위젯)
├── golden_ecommerce_test.dart           (5개 화면)
└── goldens/
    ├── catalog/
    │   ├── layout/
    │   │   ├── column_demo.png
    │   │   ├── row_demo.png
    │   │   ├── wrap_demo.png
    │   │   ├── stack_demo.png
    │   │   ├── expanded_demo.png
    │   │   ├── sized_box_demo.png
    │   │   ├── align_demo.png
    │   │   ├── aspect_ratio_demo.png
    │   │   └── intrinsic_demo.png
    │   ├── scrolling/
    │   │   ├── list_view_demo.png
    │   │   ├── grid_view_demo.png
    │   │   ├── scroll_view_demo.png
    │   │   └── list_body_demo.png
    │   ├── styling/
    │   │   ├── container_demo.png
    │   │   ├── padding_opacity_demo.png
    │   │   ├── clip_r_rect_demo.png
    │   │   ├── default_text_style_demo.png
    │   │   ├── directionality_demo.png
    │   │   ├── icon_demo.png
    │   │   ├── icon_theme_demo.png
    │   │   ├── image_demo.png
    │   │   ├── text_demo.png
    │   │   └── colored_box_demo.png
    │   ├── transform/
    │   │   ├── rotation_demo.png
    │   │   ├── scale_demo.png
    │   │   └── fitted_box_demo.png
    │   ├── interaction/
    │   │   ├── gesture_detector_demo.png
    │   │   └── ink_well_demo.png
    │   ├── material/
    │   │   ├── scaffold_demo.png
    │   │   ├── material_demo.png
    │   │   ├── card_demo.png
    │   │   ├── button_demo.png
    │   │   ├── list_tile_demo.png
    │   │   ├── slider_demo.png
    │   │   ├── drawer_demo.png
    │   │   ├── divider_demo.png
    │   │   ├── progress_demo.png
    │   │   └── overflow_bar_demo.png
    │   └── other/
    │       ├── animation_defaults_demo.png
    │       ├── safe_area_demo.png
    │       ├── args_pattern_demo.png
    │       ├── composition_demo.png (*)
    │       └── custom_widget_demo.png (*)
    └── ecommerce/
        ├── shop_home.png
        ├── product_list.png
        ├── product_detail.png
        ├── cart.png
        └── order_complete.png
```

(*) example app 마무리 후 최종 위젯 목록에 따라 조정 가능

### GoldenTestHelper 설계

```dart
/// example/test/helpers/golden_test_helper.dart

class GoldenTestHelper {
  late Runtime runtime;
  late DynamicContent data;

  /// RFW Runtime 초기화
  /// - core.widgets + material 라이브러리 등록
  /// - catalog_widgets.rfw, shop_widgets.rfw 바이너리 로드
  /// - 커스텀 위젯 라이브러리 등록 (rfw_gen.yaml 기반)
  Future<void> setUp() async {
    runtime = Runtime();
    runtime.update(
      const LibraryName(['core', 'widgets']),
      createCoreWidgets(),
    );
    runtime.update(
      const LibraryName(['material']),
      createMaterialWidgets(),
    );

    // .rfw 바이너리 파일 시스템에서 직접 로드 (테스트 환경에서 rootBundle 사용 불가)
    final catalogBlob = File('assets/catalog_widgets.rfw').readAsBytesSync();
    final shopBlob = File('assets/shop_widgets.rfw').readAsBytesSync();
    runtime.update(
      const LibraryName(['catalog']),
      decodeLibraryBlob(catalogBlob),
    );
    runtime.update(
      const LibraryName(['shop']),
      decodeLibraryBlob(shopBlob),
    );

    data = DynamicContent();
    // mock data 바인딩 (test_data.dart에서 로드)
  }

  /// RemoteWidget을 고정 뷰포트에서 렌더링
  /// 뷰포트 설정 + tearDown 자동 등록 포함
  Future<void> pumpWidget(
    WidgetTester tester, {
    required String library,
    required String widget,
    Map<String, Object>? mockData,
  }) async {
    // 고정 뷰포트 설정 + tearDown 등록
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    if (mockData != null) {
      for (final entry in mockData.entries) {
        data.update(entry.key, entry.value);
      }
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: SizedBox(
          width: 400,
          height: 800,
          child: RemoteWidget(
            runtime: runtime,
            data: data,
            widget: FullyQualifiedWidgetName(
              LibraryName([library]),
              widget,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void dispose() {
    runtime.dispose();
    data = DynamicContent(); // stale data 방지
  }
}
```

### 폰트 전략

Flutter 골든 테스트는 기본적으로 Ahem 폰트를 사용한다 (모든 글자를 사각형으로 렌더링). rfw_gen은 텍스트 변환 정확성 검증이 중요하므로 **Roboto 폰트를 번들링**한다.

```
example/test/
└── fonts/
    ├── Roboto-Regular.ttf
    └── Roboto-Bold.ttf
```

테스트 setUp에서 `FontLoader`로 명시적 로드:

```dart
Future<void> loadFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final regular = File('test/fonts/Roboto-Regular.ttf').readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final bold = File('test/fonts/Roboto-Bold.ttf').readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final loader = FontLoader('Roboto')
    ..addFont(regular)
    ..addFont(bold);
  await loader.load();
}
```

**참고**: `FontLoader.addFont()`은 `Future<ByteData>`를 받으므로 `Uint8List` → `ByteData.view()` 변환이 필요하다. `TestWidgetsFlutterBinding.ensureInitialized()`는 폰트 로드 전에 반드시 호출해야 한다.

### 뷰포트

고정 뷰포트: **400 x 800** (모바일 기준). 모든 골든 테스트에서 동일 사이즈 사용.

```dart
await tester.binding.setSurfaceSize(const Size(400, 800));
```

### 테스트 태그

골든 테스트를 분리 실행하기 위해 태그 사용:

```dart
@Tags(['golden'])
library;
```

실행: `flutter test --tags golden`
제외: `flutter test --exclude-tags golden`

### 골든 테스트 패턴

각 위젯 테스트는 동일한 패턴:

```dart
@Tags(['golden'])
library;

import 'helpers/golden_test_helper.dart';

void main() {
  late GoldenTestHelper helper;

  setUpAll(() async {
    await loadFonts();
  });

  setUp(() async {
    helper = GoldenTestHelper();
    await helper.setUp();
    // 뷰포트는 helper.pumpWidget() 내부에서 설정됨 (각 테스트에서 중복 호출 불필요)
  });

  tearDown(() {
    helper.dispose();
  });

  testWidgets('columnDemo golden', (tester) async {
    await helper.pumpWidget(
      tester,
      library: 'catalog',
      widget: 'columnDemo',
    );
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/column_demo.png'),
    );
  });
}
```

### CI 워크플로우

```yaml
# .github/workflows/golden_test.yml
name: Golden Tests

on:
  pull_request:
    paths:
      - 'packages/rfw_gen/**'
      - 'example/**'
  workflow_dispatch:  # update-goldens 잡용 수동 트리거

jobs:
  golden:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.32.0'  # 골든 이미지 일관성을 위해 버전 고정
      - run: cd example && flutter test --tags golden

  update-goldens:
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.32.0'
      - run: cd example && flutter test --tags golden --update-goldens
      - uses: actions/upload-artifact@v4
        with:
          name: golden-images
          path: example/test/goldens/
```

**Flutter 버전 고정**: 골든 이미지는 Flutter 엔진 렌더링 변경에 민감하다. `flutter-version`을 고정하여 엔진 업데이트로 인한 flaky 방지. 버전 업그레이드 시 모든 골든 재생성 필요.

**골든 업데이트 프로세스**:
1. 위젯 변경 후 CI에서 골든 테스트 실패
2. `workflow_dispatch`로 `update-goldens` 잡 수동 실행
3. 아티팩트에서 새 골든 이미지 다운로드
4. 로컬에 복사 후 커밋

### DynamicContent 모킹

이커머스 화면은 DataRef 바인딩 사용. `example/lib/data/mock_data.dart`의 데이터를 테스트에서 재사용:

```dart
/// example/test/helpers/test_data.dart
///
/// mock_data.dart의 MockData 클래스를 직접 import하여 재사용.
/// MockData는 static 메서드로 DynamicContent를 직접 조작하는 패턴:
///   MockData.setupCatalog(data);  // catalog mock data 주입
///   MockData.setupShop(data);     // shop mock data 주입 (picsum URL 포함)

import 'package:rfw_gen_example/data/mock_data.dart';

void setupTestData(DynamicContent data) {
  MockData.setupCatalog(data);
  MockData.setupShop(data);
}
```

## 위젯 목록 (현재 기준)

### 카탈로그 위젯 (43개)

**Layout (9)**: columnDemo, rowDemo, wrapDemo, stackDemo, expandedDemo, sizedBoxDemo, alignDemo, aspectRatioDemo, intrinsicDemo

**Scrolling (4)**: listViewDemo, gridViewDemo, scrollViewDemo, listBodyDemo

**Styling (10)**: containerDemo, paddingOpacityDemo, clipRRectDemo, defaultTextStyleDemo, directionalityDemo, iconDemo, iconThemeDemo, imageDemo, textDemo, coloredBoxDemo

**Transform (3)**: rotationDemo, scaleDemo, fittedBoxDemo

**Interaction (2)**: gestureDetectorDemo, inkWellDemo

**Material (10)**: scaffoldDemo, materialDemo, cardDemo, buttonDemo, listTileDemo, sliderDemo, drawerDemo, dividerDemo, progressDemo, overflowBarDemo

**Other (3~5)**: animationDefaultsDemo, safeAreaDemo, argsPatternDemo, compositionDemo(*), customWidgetDemo(*)

(*) example app 마무리 후 확정. 현재 코드에는 41개 확정, compositionDemo/customWidgetDemo는 example app 작업에서 추가 여부 결정. 최종 위젯 수는 41~43개.

### 이커머스 화면 (5개)

shopHome, productList, productDetail, cart, orderComplete

## 네트워크 이미지 전략

이커머스 mock data에 `https://picsum.photos/...` URL이 사용되고 있다. 테스트 환경에서는 네트워크 접근이 불가하므로 구체적인 해결이 필요하다.

**해결 방법**: `HttpOverrides`를 사용하여 모든 네트워크 이미지 요청에 1x1 투명 PNG placeholder를 반환.

```dart
/// example/test/helpers/golden_test_helper.dart

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

// setUpAll에서 등록:
HttpOverrides.global = _TestHttpOverrides();
```

또는 더 간단하게 **테스트 전용 mock data 래퍼**에서 이미지 URL을 빈 문자열이나 로컬 asset 경로로 대체:

```dart
/// example/test/helpers/test_data.dart
void setupTestDataWithoutImages(DynamicContent data) {
  MockData.setupCatalog(data);
  MockData.setupShop(data);
  // shop data의 네트워크 이미지 URL을 빈 문자열로 덮어쓰기
  // (RFW Image는 빈 URL 시 빈 영역으로 렌더링)
}
```

**추천**: `HttpOverrides` 방식. mock data 수정 없이 원본 데이터 구조를 유지하면서 네트워크 의존성만 제거.

## 골든 비교 Tolerance

Flutter의 `matchesGoldenFile`은 기본적으로 exact match다. 그러나 Flutter 패치 버전 간 anti-aliasing 미세 차이로 flaky failure가 발생할 수 있다.

**해결**: 커스텀 `GoldenFileComparator`로 0.5% 픽셀 tolerance 설정.

```dart
/// setUpAll에서 등록
goldenFileComparator = _TolerantGoldenFileComparator(
  tolerance: 0.005, // 0.5% 허용
  basedir: Uri.parse('test/'),
);
```

Flutter 버전 고정(`flutter-version: 3.32.0`)과 함께 사용하면 flaky를 최소화하면서도 의미 있는 렌더링 차이는 잡을 수 있다.

## 에지 케이스 보강

골든 테스트 작성 과정에서 발견될 수 있는 잠재적 이슈:

1. **Image 위젯**: 네트워크 이미지 URL은 테스트 환경에서 로드 불가 → `HttpOverrides`로 placeholder 반환 (위 "네트워크 이미지 전략" 참조)
2. **Stateful 위젯** (gestureDetectorDemo, sliderDemo 등): 초기 상태만 골든으로 검증. 상태 변경 후 검증은 별도 테스트
3. **Scaffold/Drawer**: Drawer는 closed 상태만 골든으로. opened 상태는 별도 또는 제외
4. **SafeArea**: 테스트 환경에서 시스템 인셋 없음 → 실질적으로 SafeArea 효과 없을 수 있음
5. **DataRef 바인딩 없는 위젯**: 카탈로그 대부분은 정적 값이므로 mock data 불필요

## .claude/ 가이드

### .claude/agents/golden-test-writer.md

위젯 추가 시 골든 테스트를 자동으로 작성하는 에이전트 가이드. `widget-mapper.md`와 연계하여 매핑 → 유닛 테스트 → 골든 테스트 워크플로우 정립.

### .claude/skills/add-golden-test.md

`/add-golden-test [widgetName]` — 기존 위젯에 대한 골든 테스트를 추가하는 스킬. 해당 카테고리의 테스트 파일에 테스트 케이스 추가 + 골든 이미지 생성.

### CLAUDE.md 업데이트

개발 규칙에 골든 테스트 관련 항목 추가:
- 위젯 매핑 추가 시 반드시 유닛 + 통합 + **골든** 테스트 동반
- 골든 이미지는 Linux CI에서만 생성/업데이트
- `flutter test --tags golden`으로 골든 테스트 분리 실행

## Decisions

1. **Linux CI 기준 골든**: macOS 로컬 렌더링 차이로 인한 flaky test 방지. 골든 업데이트는 CI workflow_dispatch로.
2. **Roboto 폰트 번들링**: Ahem 폰트는 텍스트를 사각형으로 렌더링하여 변환 검증에 부적합. Apache 2.0 라이선스 파일을 `test/fonts/LICENSE` 에 포함.
3. **카테고리별 테스트 파일 분리**: 46~48개 테스트를 하나의 파일에 넣으면 비대. 카테고리별 분리로 관리성 향상.
4. **고정 뷰포트 400x800**: 모바일 기준 일관된 렌더링. 모든 골든에 동일 적용. 헬퍼의 `pumpWidget`에서 설정 + `addTearDown`으로 리셋.
5. **파일 시스템 직접 로드**: 테스트 환경에서 rootBundle 대신 File I/O로 .rfw 바이너리 로드.
6. **mock_data.dart 재사용**: 이커머스 테스트에서 example app의 mock data를 그대로 사용하여 데이터 일관성 보장.
7. **HttpOverrides로 네트워크 이미지 처리**: mock data의 picsum URL을 수정하지 않고, 테스트 환경에서 모든 HTTP 요청에 placeholder를 반환.
8. **Flutter 버전 고정**: CI에서 `flutter-version`을 고정하여 엔진 렌더링 변경으로 인한 골든 불일치 방지.
9. **0.5% 픽셀 tolerance**: 커스텀 `GoldenFileComparator`로 anti-aliasing 미세 차이 허용.

## Roadmap Update

| 버전 | 범위 | 상태 |
|------|------|------|
| v0.1 | 기본 파이프라인 + 6 위젯 | ✅ 완료 |
| v0.2 | Core 위젯 전체 (38개) | ✅ 완료 |
| v0.4 | Material 위젯 + 핸들러 (56개) | ✅ 완료 |
| — | Dynamic Features (DataRef, RfwFor, RfwSwitch 등) | ✅ 완료 |
| — | Custom Widget Support (rfw_gen.yaml) | ✅ 완료 |
| — | Example App Redesign | 🔄 진행 중 |
| **v0.5-quality** | **골든 테스트 체계 + 에지 케이스 보강** | **다음** |
| v0.6 | MCP 서버 (rfw_gen_mcp) | 예정 |
| v0.7 | Marionette 연동 | 예정 |
| v1.0 | pub.dev 배포 | 예정 |
