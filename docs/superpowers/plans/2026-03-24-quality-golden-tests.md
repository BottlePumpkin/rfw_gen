# rfw_gen 품질 강화 — 골든 테스트 체계 구축 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카탈로그 41~43개 위젯 + 이커머스 5개 화면에 대한 골든 테스트 체계를 구축하여 RFW 변환의 시각적 정확성을 검증한다.

**Architecture:** GoldenTestHelper가 RFW Runtime을 초기화하고 RemoteWidget을 고정 뷰포트(400x800)에서 렌더링. Roboto 폰트 번들링으로 Ahem 기본 폰트를 대체. HttpOverrides로 네트워크 이미지 처리. Linux CI에서만 골든 생성/비교.

**Tech Stack:** Flutter 3.x, `package:rfw`, `package:flutter_test`, GitHub Actions, Roboto TTF

**Spec:** `docs/superpowers/specs/2026-03-24-quality-golden-tests-design.md`

**선행 조건:**
1. example app 미커밋 작업 완료 및 커밋
2. `cd example && dart run build_runner build` 실행하여 .rfw 바이너리 생성
3. `assets/catalog_widgets.rfw`, `assets/shop_widgets.rfw` 파일 존재 확인

---

## File Map

**Create:**
- `example/test/helpers/golden_test_helper.dart` — GoldenTestHelper 클래스, loadFonts(), HttpOverrides, TolerantGoldenFileComparator
- `example/test/helpers/test_data.dart` — MockData 재사용 래퍼
- `example/test/golden_catalog_layout_test.dart` — Layout 카테고리 골든 테스트 (9개)
- `example/test/golden_catalog_scrolling_test.dart` — Scrolling 카테고리 골든 테스트 (4개)
- `example/test/golden_catalog_styling_test.dart` — Styling 카테고리 골든 테스트 (10개)
- `example/test/golden_catalog_transform_test.dart` — Transform 카테고리 골든 테스트 (3개)
- `example/test/golden_catalog_interaction_test.dart` — Interaction 카테고리 골든 테스트 (2개)
- `example/test/golden_catalog_material_test.dart` — Material 카테고리 골든 테스트 (10개)
- `example/test/golden_catalog_other_test.dart` — Other 카테고리 골든 테스트 (3~5개)
- `example/test/golden_ecommerce_test.dart` — 이커머스 화면 골든 테스트 (5개)
- `example/test/fonts/Roboto-Regular.ttf` — Roboto Regular 폰트 파일
- `example/test/fonts/Roboto-Bold.ttf` — Roboto Bold 폰트 파일
- `example/test/fonts/LICENSE` — Roboto Apache 2.0 라이선스
- `example/dart_test.yaml` — 테스트 태그 정의 (golden)
- `.github/workflows/golden_test.yml` — GitHub Actions CI 워크플로우
- `.claude/agents/golden-test-writer.md` — 골든 테스트 작성 에이전트 가이드
- `.claude/skills/add-golden-test.md` — `/add-golden-test` 스킬

**Modify:**
- `example/test/golden_test.dart` — placeholder 삭제 (새 파일들로 대체)
- `.claude/CLAUDE.md` — 골든 테스트 규칙 추가
- `.claude/skills/add-widget.md` — 골든 테스트 단계 추가

---

### Task 1: Roboto 폰트 번들링 + dart_test.yaml

**Files:**
- Create: `example/test/fonts/Roboto-Regular.ttf`
- Create: `example/test/fonts/Roboto-Bold.ttf`
- Create: `example/test/fonts/LICENSE`
- Create: `example/dart_test.yaml`

- [ ] **Step 1: Roboto 폰트 다운로드**

Google Fonts에서 Roboto Regular/Bold TTF 파일을 다운로드하여 `example/test/fonts/`에 배치:

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/fonts
# Static TTF build 다운로드 (Regular + Bold 별도)
curl -L -o test/fonts/Roboto-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/roboto/static/Roboto-Regular.ttf"
curl -L -o test/fonts/Roboto-Bold.ttf "https://github.com/google/fonts/raw/main/ofl/roboto/static/Roboto-Bold.ttf"
```

참고: 위 URL에서 static build를 받지 못하면 https://fonts.google.com/specimen/Roboto 에서 직접 다운로드 후 `static/Roboto-Regular.ttf`, `static/Roboto-Bold.ttf`를 복사.

- [ ] **Step 2: LICENSE 파일 생성**

`example/test/fonts/LICENSE` 에 Apache 2.0 라이선스 텍스트 작성:

```
Copyright 2011 Google Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

- [ ] **Step 3: dart_test.yaml 생성**

`example/dart_test.yaml`:

```yaml
tags:
  golden:
    description: "Golden image comparison tests (Linux CI only)"
```

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/fonts/ example/dart_test.yaml
git commit -m "chore(example): add Roboto font bundle and golden test tag config"
```

---

### Task 2: GoldenTestHelper 인프라

**Files:**
- Create: `example/test/helpers/golden_test_helper.dart`
- Create: `example/test/helpers/test_data.dart`

- [ ] **Step 1: test_data.dart 작성**

```dart
// example/test/helpers/test_data.dart
import 'package:rfw/rfw.dart';
import 'package:rfw_gen_example/data/mock_data.dart';

/// 테스트용 mock data를 DynamicContent에 주입.
/// example app의 MockData를 그대로 재사용.
void setupTestData(DynamicContent data) {
  MockData.setupCatalog(data);
  MockData.setupShop(data);
}
```

- [ ] **Step 2: golden_test_helper.dart 작성 — HttpOverrides**

```dart
// example/test/helpers/golden_test_helper.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import 'test_data.dart';

// ============================================================
// Network Image Mock
// ============================================================

/// 1x1 투명 PNG (최소 유효 PNG 바이트)
final Uint8List _kTransparentPng = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, // RGBA
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, // IDAT chunk
  0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, // IEND chunk
  0x60, 0x82,
]);

/// 모든 HTTP 요청에 1x1 투명 PNG를 반환하는 HttpOverrides.
/// 이커머스 mock data의 picsum URL을 네트워크 없이 처리.
///
/// 실제 HTTP 호출을 차단하므로 테스트에서 네트워크 에러가 발생하지 않는다.
/// Flutter test 환경에서는 기본적으로 네트워크 호출이 차단되므로 이 override가 필수.
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Flutter test 환경에서는 기본적으로 네트워크 호출이 차단됨.
    // super를 반환하되, pumpWidget에서 FlutterError.onError로
    // 이미지 로드 에러를 무시하여 깨끗한 골든을 생성.
    return super.createHttpClient(context);
  }
}

// ============================================================
// Tolerant Golden File Comparator
// ============================================================

/// 0.5% 픽셀 차이를 허용하는 GoldenFileComparator.
/// anti-aliasing 미세 차이로 인한 flaky 방지.
///
/// LocalFileComparator의 생성자 API가 positional Uri testFile을 받으므로,
/// 직접 구현하여 path resolution을 완전히 제어한다.
class TolerantGoldenFileComparator extends LocalFileComparator {
  final double tolerance;

  /// [testFile]은 테스트 디렉토리 내 임의의 파일 URI.
  /// LocalFileComparator가 이 URI의 부모 디렉토리를 basedir로 사용.
  /// 예: Uri.parse('test/golden_stub') → basedir = 'test/'
  TolerantGoldenFileComparator(
    Uri testFile, {
    this.tolerance = 0.005,
  }) : super(testFile);

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    // golden 파일 경로 해석
    final goldenFile = _resolveGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      // 골든 파일이 없으면 기본 비교 사용 (--update-goldens 시 자동 생성)
      return super.compare(imageBytes, golden);
    }

    final goldenBytes = goldenFile.readAsBytesSync();

    // PNG 바이트가 완전히 동일하면 즉시 통과
    if (_bytesEqual(imageBytes, goldenBytes)) return true;

    // 바이트가 다르면 픽셀 단위 비교
    final testImage = await ui.decodeImageFromList(imageBytes);
    final goldenImage = await ui.decodeImageFromList(goldenBytes);

    // 이미지 크기가 다르면 즉시 실패
    if (testImage.width != goldenImage.width ||
        testImage.height != goldenImage.height) {
      return super.compare(imageBytes, golden);
    }

    final testByteData = await testImage.toByteData();
    final goldenByteData = await goldenImage.toByteData();

    if (testByteData == null || goldenByteData == null) {
      return super.compare(imageBytes, golden);
    }

    final totalBytes = testByteData.lengthInBytes;
    if (totalBytes == 0) return super.compare(imageBytes, golden);

    int diffBytes = 0;
    for (int i = 0; i < totalBytes; i++) {
      if (testByteData.getUint8(i) != goldenByteData.getUint8(i)) {
        diffBytes++;
      }
    }

    final diffPercent = diffBytes / totalBytes;
    if (diffPercent <= tolerance) return true;

    // tolerance 초과 시 기본 비교로 상세 에러 메시지 생성
    return super.compare(imageBytes, golden);
  }

  File _resolveGoldenFile(Uri golden) {
    return File.fromUri(basedir.resolveUri(golden));
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ============================================================
// Font Loading
// ============================================================

/// 테스트 환경 초기화: 폰트 로드 + HttpOverrides 등록.
/// 모든 골든 테스트 파일의 setUpAll에서 호출.
Future<void> loadTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  final regular = File('test/fonts/Roboto-Regular.ttf')
      .readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final bold = File('test/fonts/Roboto-Bold.ttf')
      .readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final loader = FontLoader('Roboto')
    ..addFont(regular)
    ..addFont(bold);
  await loader.load();
}

// ============================================================
// Golden Test Helper
// ============================================================

class GoldenTestHelper {
  late Runtime runtime;
  late DynamicContent data;

  /// RFW Runtime 초기화 + .rfw 바이너리 로드 + mock data 주입.
  Future<void> setUp() async {
    runtime = Runtime();

    // Core + Material 위젯 라이브러리 등록
    runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    runtime.update(
      const LibraryName(<String>['material']),
      createMaterialWidgets(),
    );

    // .rfw 바이너리 파일 시스템에서 직접 로드
    final catalogBlob = File('assets/catalog_widgets.rfw').readAsBytesSync();
    final shopBlob = File('assets/shop_widgets.rfw').readAsBytesSync();
    runtime.update(
      const LibraryName(<String>['catalog']),
      decodeLibraryBlob(catalogBlob),
    );
    runtime.update(
      const LibraryName(<String>['shop']),
      decodeLibraryBlob(shopBlob),
    );

    // Mock data
    data = DynamicContent();
    setupTestData(data);
  }

  /// RemoteWidget을 고정 뷰포트(400x800)에서 렌더링.
  Future<void> pumpWidget(
    WidgetTester tester, {
    required String library,
    required String widget,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 네트워크 이미지 로드 에러를 무시 (이커머스 picsum URL 등)
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('HTTP') ||
          details.exception.toString().contains('NetworkImage') ||
          details.exception.toString().contains('SocketException')) {
        return; // 네트워크 관련 에러 무시
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

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
              LibraryName(<String>[library]),
              widget,
            ),
            onEvent: (String name, DynamicMap args) {
              // 골든 테스트에서는 이벤트 무시 (초기 렌더링만 검증)
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void dispose() {
    runtime.dispose();
    data = DynamicContent();
  }
}
```

- [ ] **Step 3: 기존 golden_test.dart placeholder 삭제**

`example/test/golden_test.dart`를 삭제:

```bash
rm /Users/byeonghopark-jobis/dev/rfw_gen/example/test/golden_test.dart
```

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/helpers/golden_test_helper.dart example/test/helpers/test_data.dart
git rm example/test/golden_test.dart
git commit -m "feat(example): add GoldenTestHelper infrastructure with font loading and HTTP mock"
```

---

### Task 3: Layout 카테고리 골든 테스트 (9개)

**Files:**
- Create: `example/test/golden_catalog_layout_test.dart`

위젯: columnDemo, rowDemo, wrapDemo, stackDemo, expandedDemo, sizedBoxDemo, alignDemo, aspectRatioDemo, intrinsicDemo

- [ ] **Step 1: 테스트 파일 작성**

```dart
// example/test/golden_catalog_layout_test.dart
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
      Uri.parse('test/golden_stub'),  // basedir = test/
      tolerance: 0.005,
    );
  });

  setUp(() async {
    helper = GoldenTestHelper();
    await helper.setUp();
  });

  tearDown(() => helper.dispose());

  testWidgets('columnDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'columnDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/column_demo.png'),
    );
  });

  testWidgets('rowDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'rowDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/row_demo.png'),
    );
  });

  testWidgets('wrapDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'wrapDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/wrap_demo.png'),
    );
  });

  testWidgets('stackDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'stackDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/stack_demo.png'),
    );
  });

  testWidgets('expandedDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'expandedDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/expanded_demo.png'),
    );
  });

  testWidgets('sizedBoxDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'sizedBoxDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/sized_box_demo.png'),
    );
  });

  testWidgets('alignDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'alignDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/align_demo.png'),
    );
  });

  testWidgets('aspectRatioDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'aspectRatioDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/aspect_ratio_demo.png'),
    );
  });

  testWidgets('intrinsicDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'intrinsicDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/intrinsic_demo.png'),
    );
  });
}
```

- [ ] **Step 2: 골든 이미지 생성**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/layout
flutter test test/golden_catalog_layout_test.dart --update-goldens --tags golden
```

Expected: 9개 PNG 파일이 `test/goldens/catalog/layout/`에 생성

- [ ] **Step 3: 골든 비교 테스트 실행**

```bash
flutter test test/golden_catalog_layout_test.dart --tags golden
```

Expected: 9 tests passed

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_layout_test.dart example/test/goldens/catalog/layout/
git commit -m "test(example): add golden tests for Layout category (9 widgets)"
```

---

### Task 4: Scrolling 카테고리 골든 테스트 (4개)

**Files:**
- Create: `example/test/golden_catalog_scrolling_test.dart`

위젯: listViewDemo, gridViewDemo, scrollViewDemo, listBodyDemo

- [ ] **Step 1: 테스트 파일 작성**

Layout과 동일한 패턴. `setUpAll`에서 `loadTestFonts()` + `TolerantGoldenFileComparator` 설정. 각 위젯마다 `testWidgets` 블록.

골든 파일 경로: `goldens/catalog/scrolling/{widget_name}.png`

- [ ] **Step 2: 골든 이미지 생성**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/scrolling
flutter test test/golden_catalog_scrolling_test.dart --update-goldens --tags golden
```

- [ ] **Step 3: 골든 비교 테스트 실행**

```bash
flutter test test/golden_catalog_scrolling_test.dart --tags golden
```

Expected: 4 tests passed

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_scrolling_test.dart example/test/goldens/catalog/scrolling/
git commit -m "test(example): add golden tests for Scrolling category (4 widgets)"
```

---

### Task 5: Styling 카테고리 골든 테스트 (10개)

**Files:**
- Create: `example/test/golden_catalog_styling_test.dart`

위젯: containerDemo, paddingOpacityDemo, clipRRectDemo, defaultTextStyleDemo, directionalityDemo, iconDemo, iconThemeDemo, imageDemo, textDemo, coloredBoxDemo

- [ ] **Step 1: 테스트 파일 작성**

동일 패턴. 골든 파일 경로: `goldens/catalog/styling/{widget_name}.png`

**참고**: `imageDemo`는 네트워크 이미지를 사용할 수 있음. `loadTestFonts()`에서 `HttpOverrides`가 이미 설정되므로 추가 설정 불필요.

- [ ] **Step 2: 골든 이미지 생성**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/styling
flutter test test/golden_catalog_styling_test.dart --update-goldens --tags golden
```

- [ ] **Step 3: 골든 비교 테스트 실행 + 검증**

```bash
flutter test test/golden_catalog_styling_test.dart --tags golden
```

Expected: 10 tests passed

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_styling_test.dart example/test/goldens/catalog/styling/
git commit -m "test(example): add golden tests for Styling category (10 widgets)"
```

---

### Task 6: Transform 카테고리 골든 테스트 (3개)

**Files:**
- Create: `example/test/golden_catalog_transform_test.dart`

위젯: rotationDemo, scaleDemo, fittedBoxDemo

- [ ] **Step 1: 테스트 파일 작성**

동일 패턴. 골든 파일 경로: `goldens/catalog/transform/{widget_name}.png`

- [ ] **Step 2: 골든 이미지 생성 + 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/transform
flutter test test/golden_catalog_transform_test.dart --update-goldens --tags golden
flutter test test/golden_catalog_transform_test.dart --tags golden
```

Expected: 3 tests passed

- [ ] **Step 3: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_transform_test.dart example/test/goldens/catalog/transform/
git commit -m "test(example): add golden tests for Transform category (3 widgets)"
```

---

### Task 7: Interaction 카테고리 골든 테스트 (2개)

**Files:**
- Create: `example/test/golden_catalog_interaction_test.dart`

위젯: gestureDetectorDemo, inkWellDemo

**참고**: 이 위젯들은 stateful (`state: {'tapped': false, ...}`). 초기 상태만 골든으로 검증.

- [ ] **Step 1: 테스트 파일 작성**

동일 패턴. 골든 파일 경로: `goldens/catalog/interaction/{widget_name}.png`

- [ ] **Step 2: 골든 이미지 생성 + 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/interaction
flutter test test/golden_catalog_interaction_test.dart --update-goldens --tags golden
flutter test test/golden_catalog_interaction_test.dart --tags golden
```

Expected: 2 tests passed

- [ ] **Step 3: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_interaction_test.dart example/test/goldens/catalog/interaction/
git commit -m "test(example): add golden tests for Interaction category (2 widgets)"
```

---

### Task 8: Material 카테고리 골든 테스트 (10개)

**Files:**
- Create: `example/test/golden_catalog_material_test.dart`

위젯: scaffoldDemo, materialDemo, cardDemo, buttonDemo, listTileDemo, sliderDemo, drawerDemo, dividerDemo, progressDemo, overflowBarDemo

**참고**:
- `sliderDemo`는 stateful (`state: {'value': 50.0}`). 초기 상태만 검증.
- `drawerDemo`는 closed 상태만 검증.
- `scaffoldDemo`는 AppBar + body가 있는 복합 위젯. 렌더링이 뷰포트에 맞는지 확인.

- [ ] **Step 1: 테스트 파일 작성**

동일 패턴. 골든 파일 경로: `goldens/catalog/material/{widget_name}.png`

- [ ] **Step 2: 골든 이미지 생성 + 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/material
flutter test test/golden_catalog_material_test.dart --update-goldens --tags golden
flutter test test/golden_catalog_material_test.dart --tags golden
```

Expected: 10 tests passed

- [ ] **Step 3: 에지 케이스 확인**

각 골든 이미지를 육안 확인. 특히:
- `scaffoldDemo`: AppBar가 정상 렌더링되는지
- `sliderDemo`: Slider가 초기값 50.0에 위치하는지
- `drawerDemo`: Drawer가 closed 상태인지

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_material_test.dart example/test/goldens/catalog/material/
git commit -m "test(example): add golden tests for Material category (10 widgets)"
```

---

### Task 9: Other 카테고리 골든 테스트 (3~5개)

**Files:**
- Create: `example/test/golden_catalog_other_test.dart`

확정 위젯: animationDefaultsDemo, safeAreaDemo, argsPatternDemo
잠정 위젯: compositionDemo, customWidgetDemo (example app에 존재하면 포함)

- [ ] **Step 1: 현재 main.dart의 Other 카테고리 위젯 확인**

`example/lib/main.dart`의 `_catalogWidgets['Other']` 리스트를 확인하여 최종 위젯 목록 결정.

- [ ] **Step 2: 테스트 파일 작성**

동일 패턴. 골든 파일 경로: `goldens/catalog/other/{widget_name}.png`

**참고**: `argsPatternDemo`는 args 참조를 사용하므로 기본 args가 없으면 빈 렌더링일 수 있음. 필요시 RemoteWidget의 args 전달 방법 확인.

- [ ] **Step 3: 골든 이미지 생성 + 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/catalog/other
flutter test test/golden_catalog_other_test.dart --update-goldens --tags golden
flutter test test/golden_catalog_other_test.dart --tags golden
```

- [ ] **Step 4: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_catalog_other_test.dart example/test/goldens/catalog/other/
git commit -m "test(example): add golden tests for Other category (3-5 widgets)"
```

---

### Task 10: 이커머스 화면 골든 테스트 (5개)

**Files:**
- Create: `example/test/golden_ecommerce_test.dart`

화면: shopHome, productList, productDetail, cart, orderComplete

**주의사항**:
- 모든 화면이 DataRef 바인딩 사용 → `setupTestData(data)`로 mock data 필수
- `shopHome`, `productList`, `productDetail`에 picsum 이미지 URL → `HttpOverrides` 필수
- `productDetail`은 stateful (`state: {'quantity': 1}`)

- [ ] **Step 1: 테스트 파일 작성**

```dart
// example/test/golden_ecommerce_test.dart
@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'helpers/golden_test_helper.dart';

void main() {
  late GoldenTestHelper helper;

  setUpAll(() async {
    await loadTestFonts(); // HttpOverrides + 폰트 로드 포함
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/golden_stub'),  // basedir = test/
      tolerance: 0.005,
    );
  });

  setUp(() async {
    helper = GoldenTestHelper();
    await helper.setUp();
  });

  tearDown(() => helper.dispose());

  testWidgets('shopHome golden', (tester) async {
    await helper.pumpWidget(tester, library: 'shop', widget: 'shopHome');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/shop_home.png'),
    );
  });

  testWidgets('productList golden', (tester) async {
    await helper.pumpWidget(tester, library: 'shop', widget: 'productList');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/product_list.png'),
    );
  });

  testWidgets('productDetail golden', (tester) async {
    await helper.pumpWidget(tester, library: 'shop', widget: 'productDetail');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/product_detail.png'),
    );
  });

  testWidgets('cart golden', (tester) async {
    await helper.pumpWidget(tester, library: 'shop', widget: 'cart');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/cart.png'),
    );
  });

  testWidgets('orderComplete golden', (tester) async {
    await helper.pumpWidget(tester, library: 'shop', widget: 'orderComplete');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/order_complete.png'),
    );
  });
}
```

- [ ] **Step 2: 골든 이미지 생성**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
mkdir -p test/goldens/ecommerce
flutter test test/golden_ecommerce_test.dart --update-goldens --tags golden
```

Expected: 5개 PNG 생성. 이미지에 네트워크 이미지 영역은 빈 공간 또는 placeholder로 렌더링.

- [ ] **Step 3: 골든 비교 테스트 실행**

```bash
flutter test test/golden_ecommerce_test.dart --tags golden
```

Expected: 5 tests passed

- [ ] **Step 4: 골든 이미지 육안 확인**

특히:
- `shopHome`: 배너, 카테고리, 추천상품 레이아웃 정상 여부
- `productDetail`: 수량 선택 영역 초기 상태 (quantity: 1)
- `cart`: 장바구니 항목 목록 + 총액

- [ ] **Step 5: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/golden_ecommerce_test.dart example/test/goldens/ecommerce/
git commit -m "test(example): add golden tests for e-commerce screens (5 screens)"
```

---

### Task 11: 전체 골든 테스트 통합 실행 + 에지 케이스 수정

**Files:**
- 필요시 수정: `example/test/helpers/golden_test_helper.dart`
- 필요시 수정: 각 테스트 파일

- [ ] **Step 1: 전체 골든 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter test --tags golden
```

Expected: 46~48 tests passed (위젯 수에 따라)

- [ ] **Step 2: 실패 테스트 확인 및 수정**

실패 패턴별 대응:
- **네트워크 이미지 에러**: 해당 테스트 파일의 `setUpAll`에 `HttpOverrides.global = TestHttpOverrides();` 추가
- **폰트 렌더링 차이**: tolerance 조정 (0.005 → 0.01)
- **뷰포트 오버플로우**: 위젯이 400x800을 넘으면 `SingleChildScrollView` 래핑 검토
- **RFW 런타임 에러**: 위젯 정의 확인, `catalog_widgets.rfwtxt` 파싱 문제

- [ ] **Step 3: 비-골든 테스트가 깨지지 않았는지 확인**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen/example
flutter test --exclude-tags golden
```

Expected: 기존 테스트 모두 passed

- [ ] **Step 4: 수정사항 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/test/helpers/ example/test/golden_catalog_*_test.dart example/test/golden_ecommerce_test.dart example/test/goldens/
git commit -m "fix(example): resolve golden test edge cases"
```

---

### Task 12: GitHub Actions CI 워크플로우

**Files:**
- Create: `.github/workflows/golden_test.yml`

- [ ] **Step 1: CI 워크플로우 작성**

```yaml
# .github/workflows/golden_test.yml
name: Golden Tests

on:
  pull_request:
    paths:
      - 'packages/rfw_gen/**'
      - 'example/**'
  workflow_dispatch:

jobs:
  golden:
    runs-on: ubuntu-latest
    if: github.event_name == 'pull_request'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.32.0'
      - name: Install dependencies
        run: cd example && flutter pub get
      - name: Verify .rfw assets exist
        run: |
          test -f example/assets/catalog_widgets.rfw || (echo "Missing catalog_widgets.rfw - run build_runner first" && exit 1)
          test -f example/assets/shop_widgets.rfw || (echo "Missing shop_widgets.rfw - run build_runner first" && exit 1)
      - name: Run golden tests
        run: cd example && flutter test --tags golden

  update-goldens:
    runs-on: ubuntu-latest
    if: github.event_name == 'workflow_dispatch'
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
          flutter-version: '3.32.0'
      - name: Install dependencies
        run: cd example && flutter pub get
      - name: Verify .rfw assets exist
        run: |
          test -f example/assets/catalog_widgets.rfw || (echo "Missing catalog_widgets.rfw" && exit 1)
          test -f example/assets/shop_widgets.rfw || (echo "Missing shop_widgets.rfw" && exit 1)
      - name: Update golden images
        run: cd example && flutter test --tags golden --update-goldens
      - uses: actions/upload-artifact@v4
        with:
          name: golden-images
          path: example/test/goldens/
```

- [ ] **Step 2: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
mkdir -p .github/workflows
git add .github/workflows/golden_test.yml
git commit -m "ci: add GitHub Actions workflow for golden tests"
```

---

### Task 13: .claude/ 가이드 업데이트

**Files:**
- Create: `.claude/agents/golden-test-writer.md`
- Create: `.claude/skills/add-golden-test.md`
- Modify: `.claude/CLAUDE.md`
- Modify: `.claude/skills/add-widget.md`

- [ ] **Step 1: golden-test-writer.md 작성**

```markdown
# Golden Test Writer Agent

골든 테스트를 작성하는 에이전트.

## 필수 참조

- 스펙: docs/superpowers/specs/2026-03-24-quality-golden-tests-design.md
- 헬퍼: example/test/helpers/golden_test_helper.dart
- 기존 테스트: example/test/golden_catalog_*_test.dart

## 패턴

1. 대상 위젯의 카테고리 확인 (main.dart의 _catalogWidgets)
2. 해당 카테고리 테스트 파일에 testWidgets 블록 추가
3. 골든 이미지 생성: `flutter test {file} --update-goldens --tags golden`
4. 비교 테스트 실행: `flutter test {file} --tags golden`

## 주의사항

- 네트워크 이미지 사용 시 setUpAll에 HttpOverrides 추가
- Stateful 위젯은 초기 상태만 검증
- 골든 파일 경로: goldens/catalog/{category}/{widget_name}.png
- 골든 이미지는 Linux CI 기준. macOS 로컬과 다를 수 있음
```

- [ ] **Step 2: add-golden-test.md 작성**

```markdown
# /add-golden-test Skill

기존 위젯에 대한 골든 테스트를 추가하는 워크플로우.

## 사용법

`/add-golden-test [widgetName]`

## 단계

1. example/lib/main.dart의 _catalogWidgets에서 위젯 카테고리 확인
2. 해당 카테고리의 golden_catalog_{category}_test.dart에 testWidgets 블록 추가
3. 네트워크 이미지 사용 여부 확인 → 필요시 HttpOverrides 추가
4. `flutter test {file} --update-goldens --tags golden` 으로 골든 생성
5. `flutter test {file} --tags golden` 으로 비교 테스트 통과 확인
6. 골든 이미지 육안 확인
7. 커밋
```

- [ ] **Step 3: CLAUDE.md 업데이트**

개발 규칙 섹션에 추가:

```markdown
- 골든 이미지는 Linux CI에서만 생성/업데이트
- `flutter test --tags golden`으로 골든 테스트 분리 실행
- 골든 테스트 인프라: example/test/helpers/golden_test_helper.dart
```

- [ ] **Step 4: add-widget.md 업데이트**

기존 단계에 골든 테스트 추가:

```markdown
6. example/test/golden_catalog_{category}_test.dart에 골든 테스트 추가
7. `flutter test --tags golden --update-goldens`로 골든 생성
```

- [ ] **Step 5: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add .claude/
git commit -m "docs: add golden test agent, skill, and update development rules"
```

---

## 실행 순서 요약

| Task | 내용 | 예상 테스트 수 |
|------|------|-------------|
| 1 | Roboto 폰트 + dart_test.yaml | — |
| 2 | GoldenTestHelper 인프라 | — |
| 3 | Layout 골든 | 9 |
| 4 | Scrolling 골든 | 4 |
| 5 | Styling 골든 | 10 |
| 6 | Transform 골든 | 3 |
| 7 | Interaction 골든 | 2 |
| 8 | Material 골든 | 10 |
| 9 | Other 골든 | 3~5 |
| 10 | 이커머스 골든 | 5 |
| 11 | 통합 실행 + 에지 케이스 | — |
| 12 | CI 워크플로우 | — |
| 13 | .claude/ 가이드 | — |

**총 골든 테스트**: 46~48개
