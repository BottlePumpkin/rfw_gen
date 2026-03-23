# Example App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the rfw_gen example app into a 2-tab structure (widget catalog + e-commerce demo) showcasing all 56 supported widgets and real-world RFW patterns.

**Architecture:** Two-tab app with BottomNavigationBar. Catalog tab uses native Flutter for navigation with RemoteWidget for individual demos. E-commerce tab uses event-based Navigator.push/pop for 5 screens, all rendered as RemoteWidget. Two separate .rfw binaries (catalog/shop) loaded into shared Runtime.

**Tech Stack:** Flutter, rfw, rfw_gen, rfw_gen_builder, build_runner

**Spec:** `docs/superpowers/specs/2026-03-23-example-app-redesign-design.md`

---

## Review Errata — 구현 시 반드시 적용할 수정사항

계획 리뷰에서 발견된 이슈. **각 Task 실행 시 아래 규칙을 적용할 것.**

### 파일 헤더 (모든 위젯 파일)
```dart
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class
```
`undefined_class` 추가 필수 (Rotation, Scale, AnimationDefaults 등 RFW 전용 클래스).

### Icon 사용법
```dart
// ❌ 잘못됨
Icon(Icons.home, size: 32.0)

// ✅ 올바름
Icon(icon: RfwIcon.home, size: 32.0)
```
- `Icons.xxx` → `RfwIcon.xxx` 전부 교체
- `icon:` named parameter 필수
- 사용 가능 아이콘: home, menu, arrowBack, arrowForward, close, chevronLeft, chevronRight, expandMore, expandLess, search, settings, delete, add, remove, edit, check, refresh, done, save, copy, filterList, favorite, favoriteBorder, share, send, star, starBorder, bookmark, bookmarkBorder, link, flag, email, phone, chat, notifications, notificationsNone, message, image, camera, playArrow, pause, volumeUp, volumeOff, info, warning, error, help, visibility, visibilityOff, lock, lockOpen
- 없는 아이콘(thumb_up, thumb_down, grade, remove_circle_outline, add_circle_outline, check_circle, person 등)은 사용 가능한 것으로 대체

### Text 위젯
```dart
// ❌ 잘못됨
Text(text: 'Hello')

// ✅ 올바름 (positional)
Text('Hello')
```

### RfwFor spread 문법
```dart
// ❌ 잘못됨 (RfwFor는 Iterable이 아님)
children: [
  ...RfwFor(items: DataRef('list'), itemName: 'x', builder: (x) => ...),
]

// ✅ 올바름
children: [
  RfwFor(items: DataRef('list'), itemName: 'x', builder: (x) => ...),
]
```

### double.infinity 미지원
`double.infinity` 대신 레이아웃 위젯으로 대체:
- `width: double.infinity` → `SizedBox.expand` 또는 `Expanded` 래핑
- 혹은 충분히 큰 고정값 사용 (예: `width: 400`)

### SizedBox 변형
```dart
// ❌ 잘못됨 (named constructor 미지원)
SizedBox.expand()
SizedBox.shrink()

// ✅ 올바름 (별도 위젯명 사용)
SizedBoxExpand()
SizedBoxShrink()
```

### Container duration/curve
Container 위젯 레지스트리에 `duration`/`curve` 매핑이 없음. 암시적 애니메이션 데모는 `Opacity`, `Padding`, `Rotation`, `Scale` 등 지원되는 위젯에서 시연. `AnimationDefaults`로 감싸는 패턴 사용.

### Placeholder 파라미터
```dart
// ❌ 잘못됨
Placeholder(fallbackWidth: 100, fallbackHeight: 50)

// ✅ 올바름
Placeholder(placeholderWidth: 100, placeholderHeight: 50)
```

### 누락 위젯 추가
- `IntrinsicWidth` 데모를 `intrinsicDemo`에 추가
- `SizedBoxShrink` 데모를 `sizedBoxDemo`에 추가

### argsPatternDemo 수정
실제 `ArgsRef` 사용하는 위젯 합성 예제로 변경해야 함.

### Golden/Widget 테스트 asset 로딩
```dart
// ❌ 잘못됨 (테스트에서 rootBundle 사용 불가)
final bytes = await rootBundle.load('assets/catalog_widgets.rfw');

// ✅ 올바름
import 'dart:io';
final bytes = File('assets/catalog_widgets.rfw').readAsBytesSync();
```

### main.dart 카테고리명
`'Styling'` → `'Styling & Visual'`로 스펙과 일치시킬 것.

---

## File Structure

```
example/lib/
├── main.dart                        — App shell: MaterialApp, BottomNavigationBar, Runtime init, onEvent router
├── catalog/
│   └── catalog_widgets.dart         — All @RfwWidget catalog demos (7 categories, ~45 widgets)
├── ecommerce/
│   └── shop_widgets.dart            — All @RfwWidget e-commerce screens (5 screens)
└── data/
    └── mock_data.dart               — All DynamicContent mock data (catalog + e-commerce)

example/test/
├── catalog_conversion_test.dart     — parseLibraryFile() validation for catalog widgets
├── shop_conversion_test.dart        — parseLibraryFile() validation for shop widgets
├── golden_test.dart                 — Golden snapshot tests (min 12)
├── goldens/                         — Golden reference images
├── app_test.dart                    — Widget tests for main.dart (tabs, navigation, events)
└── (delete widget_test.dart, old golden_test.dart, old goldens/)

example/assets/
├── catalog_widgets.rfw              — Generated catalog binary
└── shop_widgets.rfw                 — Generated shop binary
```

---

## Task 1: Clean up existing example files

**Files:**
- Delete: `example/lib/widgets.dart`, `example/lib/widgets.rfwtxt`, `example/lib/widgets.rfw`
- Delete: `example/assets/widgets.rfw`
- Delete: `example/test/widget_test.dart`, `example/test/golden_test.dart`, `example/test/goldens/`
- Modify: `example/pubspec.yaml` — update assets section

- [ ] **Step 1: Delete old widget files**

```bash
rm example/lib/widgets.dart example/lib/widgets.rfwtxt example/lib/widgets.rfw
rm example/assets/widgets.rfw
rm example/test/widget_test.dart example/test/golden_test.dart
rm -rf example/test/goldens/
```

- [ ] **Step 2: Create new directory structure**

```bash
mkdir -p example/lib/catalog example/lib/ecommerce example/lib/data
mkdir -p example/test/goldens
```

- [ ] **Step 3: Update pubspec.yaml assets section**

In `example/pubspec.yaml`, change the assets section:
```yaml
  assets:
    - assets/catalog_widgets.rfw
    - assets/shop_widgets.rfw
```

- [ ] **Step 4: Commit**

```bash
git add -A example/
git commit -m "chore: clean up old example files and create new directory structure"
```

---

## Task 2: Create mock data

**Files:**
- Create: `example/lib/data/mock_data.dart`

- [ ] **Step 1: Create mock_data.dart with all DynamicContent data**

```dart
import 'package:rfw/rfw.dart';

/// All mock data for the example app.
/// Catalog data is for widget demos, e-commerce data is for the shop demo.
class MockData {
  static void setupCatalog(DynamicContent data) {
    data.update('catalog', <String, Object>{
      'sampleItems': [
        <String, Object>{'name': 'Apple', 'description': 'A fresh red apple'},
        <String, Object>{'name': 'Banana', 'description': 'A ripe yellow banana'},
        <String, Object>{'name': 'Cherry', 'description': 'Sweet dark cherries'},
      ],
      'tags': ['Flutter', 'RFW', 'Dart', 'Widget', 'Remote', 'Server-Driven'],
    });
  }

  static void setupShop(DynamicContent data) {
    data.update('banners', <String, Object>{
      'items': [
        <String, Object>{
          'title': '여름 세일 50%',
          'subtitle': '전 상품 할인 중',
          'color': 0xFFFF6B6B,
        },
        <String, Object>{
          'title': '신상품 입고',
          'subtitle': '이번 주 신상품을 만나보세요',
          'color': 0xFF4ECDC4,
        },
      ],
    });

    data.update('categories', <String, Object>{
      'items': [
        <String, Object>{'name': '의류', 'icon': 0xe14f},
        <String, Object>{'name': '전자기기', 'icon': 0xe1e3},
        <String, Object>{'name': '식품', 'icon': 0xe532},
        <String, Object>{'name': '도서', 'icon': 0xe02d},
      ],
    });

    data.update('recommended', <String, Object>{
      'items': [
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'image': 'https://picsum.photos/seed/earbuds/200',
          'inStock': true,
        },
        <String, Object>{
          'id': 2,
          'name': '스마트 워치',
          'price': 89000,
          'image': 'https://picsum.photos/seed/watch/200',
          'inStock': true,
        },
        <String, Object>{
          'id': 3,
          'name': '블루투스 스피커',
          'price': 35000,
          'image': 'https://picsum.photos/seed/speaker/200',
          'inStock': false,
        },
      ],
    });

    data.update('products', <String, Object>{
      'items': [
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'description': '고음질 블루투스 이어폰. 노이즈 캔슬링 지원.',
          'image': 'https://picsum.photos/seed/earbuds/400',
          'inStock': true,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 2,
          'name': '스마트 워치',
          'price': 89000,
          'description': '건강 모니터링과 알림 기능을 갖춘 스마트 워치.',
          'image': 'https://picsum.photos/seed/watch/400',
          'inStock': true,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 3,
          'name': '블루투스 스피커',
          'price': 35000,
          'description': '휴대용 방수 블루투스 스피커.',
          'image': 'https://picsum.photos/seed/speaker/400',
          'inStock': false,
          'category': '전자기기',
        },
        <String, Object>{
          'id': 4,
          'name': '코튼 티셔츠',
          'price': 25000,
          'description': '편안한 100% 면 티셔츠.',
          'image': 'https://picsum.photos/seed/tshirt/400',
          'inStock': true,
          'category': '의류',
        },
      ],
    });

    data.update('cart', <String, Object>{
      'items': [
        <String, Object>{
          'id': 1,
          'name': '무선 이어폰',
          'price': 45000,
          'quantity': 2,
        },
        <String, Object>{
          'id': 4,
          'name': '코튼 티셔츠',
          'price': 25000,
          'quantity': 1,
        },
      ],
      'totalPrice': 115000,
      'itemCount': 3,
    });

    data.update('order', <String, Object>{
      'orderNumber': 'ORD-2026-0001',
      'itemCount': 3,
      'totalPrice': 115000,
    });

    // Product detail (loaded per-product via event args)
    data.update('product', <String, Object>{
      'id': 1,
      'name': '무선 이어폰',
      'price': 45000,
      'description': '고음질 블루투스 이어폰. 노이즈 캔슬링 지원.',
      'image': 'https://picsum.photos/seed/earbuds/400',
      'inStock': true,
    });
  }
}
```

- [ ] **Step 2: Verify the file compiles**

```bash
cd example && dart analyze lib/data/mock_data.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/data/mock_data.dart
git commit -m "feat(example): add mock data for catalog and e-commerce demo"
```

---

## Task 3: Create catalog widgets — Layout category

**Files:**
- Create: `example/lib/catalog/catalog_widgets.dart`

Catalog widgets use the `@RfwWidget('xxxDemo')` naming convention. All catalog widgets go in a single file. This task adds the Layout category; subsequent tasks add remaining categories to the same file.

- [ ] **Step 1: Create catalog_widgets.dart with Layout demos**

```dart
// ignore_for_file: argument_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// Layout Category
// ============================================================

@RfwWidget('columnDemo')
Widget buildColumnDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    mainAxisSize: MainAxisSize.max,
    children: [
      Container(width: 60, height: 60, color: const Color(0xFF2196F3)),
      Container(width: 60, height: 60, color: const Color(0xFF4CAF50)),
      Container(width: 60, height: 60, color: const Color(0xFFFF9800)),
    ],
  );
}

@RfwWidget('rowDemo')
Widget buildRowDemo() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Container(width: 50, height: 80, color: const Color(0xFFE91E63)),
      Container(width: 50, height: 60, color: const Color(0xFF9C27B0)),
      Container(width: 50, height: 40, color: const Color(0xFF673AB7)),
    ],
  );
}

@RfwWidget('wrapDemo')
Widget buildWrapDemo() {
  return Wrap(
    spacing: 8.0,
    runSpacing: 8.0,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF2196F3),
        child: const Text('Flutter', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF4CAF50),
        child: const Text('RFW', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFFFF9800),
        child: const Text('Dart', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFFE91E63),
        child: const Text('Widget', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF9C27B0),
        child: const Text('Remote', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ],
  );
}

@RfwWidget('stackDemo')
Widget buildStackDemo() {
  return Stack(
    alignment: const Alignment(0.0, 0.0),
    children: [
      Container(width: 200, height: 200, color: const Color(0xFF2196F3)),
      Container(width: 150, height: 150, color: const Color(0xFF4CAF50)),
      Positioned(
        top: 10.0,
        end: 10.0,
        child: Container(width: 40, height: 40, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('expandedDemo')
Widget buildExpandedDemo() {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Container(height: 60, color: const Color(0xFF2196F3)),
      ),
      Expanded(
        flex: 1,
        child: Container(height: 60, color: const Color(0xFF4CAF50)),
      ),
      Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Container(width: 30, height: 60, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('sizedBoxDemo')
Widget buildSizedBoxDemo() {
  return Column(
    children: [
      const SizedBox(
        width: 100,
        height: 50,
        child: ColoredBox(color: Color(0xFF2196F3)),
      ),
      const Spacer(flex: 1),
      const SizedBox.expand(
        child: ColoredBox(color: Color(0xFFE8EAF6)),
      ),
    ],
  );
}

@RfwWidget('alignDemo')
Widget buildAlignDemo() {
  return SizedBox(
    width: 200,
    height: 200,
    child: Stack(
      children: [
        Container(color: const Color(0xFFE8EAF6)),
        Align(
          alignment: const Alignment(-1.0, -1.0),
          child: Container(width: 40, height: 40, color: const Color(0xFFFF5722)),
        ),
        const Center(
          child: Text('Center'),
        ),
        Align(
          alignment: const Alignment(1.0, 1.0),
          child: Container(width: 40, height: 40, color: const Color(0xFF4CAF50)),
        ),
      ],
    ),
  );
}

@RfwWidget('aspectRatioDemo')
Widget buildAspectRatioDemo() {
  return Column(
    children: [
      AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(color: const Color(0xFF2196F3)),
      ),
      const SizedBox(height: 8),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: Container(height: 40, color: const Color(0xFF4CAF50)),
      ),
    ],
  );
}

@RfwWidget('intrinsicDemo')
Widget buildIntrinsicDemo() {
  return IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(width: 50, color: const Color(0xFF2196F3)),
        Column(
          children: [
            Container(width: 100, height: 30, color: const Color(0xFF4CAF50)),
            Container(width: 100, height: 60, color: const Color(0xFFFF9800)),
          ],
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Verify the file compiles**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add Layout category catalog widgets"
```

---

## Task 4: Add catalog widgets — Scrolling category

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`

Append Scrolling category widgets after the Layout section.

- [ ] **Step 1: Add Scrolling widgets**

Append to `catalog_widgets.dart`:

```dart
// ============================================================
// Scrolling Category
// ============================================================

@RfwWidget('listViewDemo')
Widget buildListViewDemo() {
  return ListView(
    padding: const EdgeInsets.all(8),
    children: [
      Container(height: 50, color: const Color(0xFF2196F3), margin: const EdgeInsets.only(bottom: 4)),
      Container(height: 50, color: const Color(0xFF4CAF50), margin: const EdgeInsets.only(bottom: 4)),
      Container(height: 50, color: const Color(0xFFFF9800), margin: const EdgeInsets.only(bottom: 4)),
      Container(height: 50, color: const Color(0xFFE91E63)),
    ],
  );
}

@RfwWidget('gridViewDemo')
Widget buildGridViewDemo() {
  return GridView(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
    shrinkWrap: true,
    children: [
      Container(color: const Color(0xFF2196F3), margin: const EdgeInsets.all(4)),
      Container(color: const Color(0xFF4CAF50), margin: const EdgeInsets.all(4)),
      Container(color: const Color(0xFFFF9800), margin: const EdgeInsets.all(4)),
      Container(color: const Color(0xFFE91E63), margin: const EdgeInsets.all(4)),
    ],
  );
}

@RfwWidget('scrollViewDemo')
Widget buildScrollViewDemo() {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Container(height: 100, color: const Color(0xFF2196F3)),
        const SizedBox(height: 8),
        Container(height: 100, color: const Color(0xFF4CAF50)),
        const SizedBox(height: 8),
        Container(height: 100, color: const Color(0xFFFF9800)),
      ],
    ),
  );
}

@RfwWidget('listBodyDemo')
Widget buildListBodyDemo() {
  return ListBody(
    children: [
      Container(height: 40, color: const Color(0xFF2196F3), margin: const EdgeInsets.only(bottom: 4)),
      Container(height: 40, color: const Color(0xFF4CAF50), margin: const EdgeInsets.only(bottom: 4)),
      Container(height: 40, color: const Color(0xFFFF9800)),
    ],
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add Scrolling category catalog widgets"
```

---

## Task 5: Add catalog widgets — Styling & Visual category

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`

- [ ] **Step 1: Add Styling & Visual widgets**

Append to `catalog_widgets.dart`:

```dart
// ============================================================
// Styling & Visual Category
// ============================================================

@RfwWidget('containerDemo')
Widget buildContainerDemo() {
  return Container(
    width: 200,
    height: 200,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.all(8),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment(-1.0, -1.0),
        end: Alignment(1.0, 1.0),
        colors: [Color(0xFF2196F3), Color(0xFF9C27B0)],
      ),
      borderRadius: BorderRadius.all(Radius.circular(16)),
      boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 4))],
    ),
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: const Center(
      child: Text('Container', style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18.0)),
    ),
  );
}

@RfwWidget('paddingOpacityDemo')
Widget buildPaddingOpacityDemo() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(24),
        child: Container(width: 100, height: 50, color: const Color(0xFF2196F3)),
      ),
      Opacity(
        opacity: 0.5,
        child: Container(width: 100, height: 50, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('clipRRectDemo')
Widget buildClipRRectDemo() {
  return ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(20)),
    child: Container(
      width: 150,
      height: 100,
      color: const Color(0xFF4CAF50),
      child: const Center(
        child: Text('Clipped', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ),
  );
}

@RfwWidget('defaultTextStyleDemo')
Widget buildDefaultTextStyleDemo() {
  return DefaultTextStyle(
    style: const TextStyle(fontSize: 20.0, color: Color(0xFF1565C0), fontWeight: FontWeight.bold),
    child: Column(
      children: const [
        Text(text: 'Inherited Style'),
        Text(text: 'Same Style Here'),
      ],
    ),
  );
}

@RfwWidget('directionalityDemo')
Widget buildDirectionalityDemo() {
  return Column(
    children: [
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: const [
            Text(text: 'LTR → '),
            Text(text: 'Left to Right'),
          ],
        ),
      ),
      Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: const [
            Text(text: 'RTL ← '),
            Text(text: 'Right to Left'),
          ],
        ),
      ),
    ],
  );
}

@RfwWidget('iconDemo')
Widget buildIconDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [
      Icon(Icons.home, size: 32.0, color: Color(0xFF2196F3)),
      Icon(Icons.favorite, size: 32.0, color: Color(0xFFE91E63)),
      Icon(Icons.star, size: 32.0, color: Color(0xFFFF9800)),
    ],
  );
}

@RfwWidget('iconThemeDemo')
Widget buildIconThemeDemo() {
  return IconTheme(
    data: const IconThemeData(color: Color(0xFF9C27B0), size: 40.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: const [
        Icon(Icons.thumb_up),
        Icon(Icons.thumb_down),
        Icon(Icons.grade),
      ],
    ),
  );
}

@RfwWidget('imageDemo')
Widget buildImageDemo() {
  return Image(
    image: const NetworkImage('https://picsum.photos/seed/rfw/300/200'),
    width: 300,
    height: 200,
    fit: BoxFit.cover,
  );
}

@RfwWidget('textDemo')
Widget buildTextDemo() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: const [
      Text(text: 'Regular Text', style: TextStyle(fontSize: 16.0)),
      Text(text: 'Bold Text', style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
      Text(text: 'Italic Colored', style: TextStyle(fontSize: 16.0, fontStyle: FontStyle.italic, color: Color(0xFFE91E63))),
      Text(text: 'Overflow ellipsis for very long text that should be truncated', maxLines: 1, overflow: TextOverflow.ellipsis),
    ],
  );
}

@RfwWidget('coloredBoxDemo')
Widget buildColoredBoxDemo() {
  return Column(
    children: [
      const ColoredBox(
        color: Color(0xFF2196F3),
        child: SizedBox(width: 100, height: 50),
      ),
      const SizedBox(height: 8),
      const Placeholder(
        color: Color(0xFFFF5722),
        strokeWidth: 2.0,
        fallbackWidth: 100,
        fallbackHeight: 50,
      ),
    ],
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add Styling & Visual category catalog widgets"
```

---

## Task 6: Add catalog widgets — Transform, Interaction, Other categories

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`

- [ ] **Step 1: Add Transform, Interaction, and Other widgets**

Append to `catalog_widgets.dart`:

```dart
// ============================================================
// Transform Category
// ============================================================

@RfwWidget('rotationDemo')
Widget buildRotationDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Rotation(
        turns: 0.125,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: Container(width: 60, height: 60, color: const Color(0xFF2196F3)),
      ),
      Rotation(
        turns: 0.25,
        child: Container(width: 60, height: 60, color: const Color(0xFF4CAF50)),
      ),
    ],
  );
}

@RfwWidget('scaleDemo')
Widget buildScaleDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      Scale(
        scale: 1.5,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: Container(width: 40, height: 40, color: const Color(0xFFE91E63)),
      ),
      Scale(
        scale: 0.5,
        child: Container(width: 80, height: 80, color: const Color(0xFF9C27B0)),
      ),
    ],
  );
}

@RfwWidget('fittedBoxDemo')
Widget buildFittedBoxDemo() {
  return SizedBox(
    width: 200,
    height: 100,
    child: FittedBox(
      fit: BoxFit.contain,
      child: const Text(text: 'FittedBox', style: TextStyle(fontSize: 60.0)),
    ),
  );
}

// ============================================================
// Interaction Category
// ============================================================

@RfwWidget('gestureDetectorDemo', state: {'tapped': false, 'longPressed': false})
Widget buildGestureDetectorDemo() {
  return GestureDetector(
    onTap: RfwHandler.setState('tapped', true),
    onLongPress: RfwHandler.setState('longPressed', true),
    onDoubleTap: RfwHandler.event('gesture.doubleTap', {}),
    child: Container(
      width: 200,
      height: 80,
      color: RfwSwitchValue<int>(
        value: StateRef('tapped'),
        cases: {true: 0xFF4CAF50, false: 0xFF2196F3},
      ),
      child: const Center(
        child: Text(text: 'Tap / Long Press / Double Tap', style: TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ),
  );
}

@RfwWidget('inkWellDemo', state: {'pressed': false})
Widget buildInkWellDemo() {
  return InkWell(
    onTap: RfwHandler.setState('pressed', true),
    onLongPress: RfwHandler.event('inkwell.longPress', {}),
    splashColor: const Color(0x402196F3),
    child: Container(
      padding: const EdgeInsets.all(16),
      child: const Text(text: 'InkWell with Ripple', style: TextStyle(fontSize: 16.0)),
    ),
  );
}

// ============================================================
// Other Category
// ============================================================

@RfwWidget('animationDefaultsDemo')
Widget buildAnimationDefaultsDemo() {
  return AnimationDefaults(
    duration: const Duration(milliseconds: 600),
    curve: Curves.fastOutSlowIn,
    child: Column(
      children: [
        Opacity(
          opacity: 0.5,
          child: Container(width: 120, height: 40, color: const Color(0xFF2196F3)),
        ),
        const SizedBox(height: 8),
        Container(
          width: 120,
          height: 40,
          color: const Color(0xFF4CAF50),
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        ),
      ],
    ),
  );
}

@RfwWidget('safeAreaDemo')
Widget buildSafeAreaDemo() {
  return SafeArea(
    child: Container(
      color: const Color(0xFFE8EAF6),
      child: const Center(
        child: Text(text: 'Inside SafeArea', style: TextStyle(fontSize: 16.0)),
      ),
    ),
  );
}
```

Note: `Rotation`, `Scale` are RFW-specific widget names (not standard Flutter). They map to animated rotation/scale in RFW. The code uses `// ignore_for_file: argument_type_not_assignable` at the top of the file to handle RfwSwitchValue and other marker class type mismatches.

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add Transform, Interaction, Other category catalog widgets"
```

---

## Task 7: Add catalog widgets — Material category

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`

- [ ] **Step 1: Add Material widgets**

Append to `catalog_widgets.dart`:

```dart
// ============================================================
// Material Category
// ============================================================

@RfwWidget('scaffoldDemo')
Widget buildScaffoldDemo() {
  return Scaffold(
    appBar: AppBar(
      title: const Text(text: 'Scaffold Demo'),
      backgroundColor: const Color(0xFF2196F3),
    ),
    body: const Center(
      child: Text(text: 'Scaffold Body', style: TextStyle(fontSize: 18.0)),
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: RfwHandler.event('fab.pressed', {}),
      child: const Icon(Icons.add),
    ),
  );
}

@RfwWidget('materialDemo')
Widget buildMaterialDemo() {
  return Material(
    elevation: 4.0,
    color: const Color(0xFFFFFFFF),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: const Text(text: 'Material Surface', style: TextStyle(fontSize: 16.0)),
    ),
  );
}

@RfwWidget('cardDemo')
Widget buildCardDemo() {
  return Column(
    children: [
      Card(
        elevation: 4.0,
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(text: 'Rounded Card', style: TextStyle(fontSize: 16.0)),
        ),
      ),
      Card(
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const SizedBox(
          width: 80,
          height: 80,
          child: Center(child: Text(text: 'Circle')),
        ),
      ),
    ],
  );
}

@RfwWidget('buttonDemo')
Widget buildButtonDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      ElevatedButton(
        onPressed: RfwHandler.event('button.elevated', {}),
        child: const Text(text: 'Elevated'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: RfwHandler.event('button.text', {}),
        child: const Text(text: 'Text Button'),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: RfwHandler.event('button.outlined', {}),
        child: const Text(text: 'Outlined'),
      ),
    ],
  );
}

@RfwWidget('listTileDemo')
Widget buildListTileDemo() {
  return Column(
    children: [
      ListTile(
        leading: const Icon(Icons.person, size: 40.0, color: Color(0xFF2196F3)),
        title: const Text(text: 'List Tile Title'),
        subtitle: const Text(text: 'Subtitle text here'),
        trailing: const Icon(Icons.chevron_right),
        onTap: RfwHandler.event('listTile.tap', {}),
      ),
      const Divider(),
      ListTile(
        leading: const Icon(Icons.settings, size: 40.0, color: Color(0xFF757575)),
        title: const Text(text: 'Settings'),
        onTap: RfwHandler.event('listTile.settings', {}),
      ),
    ],
  );
}

@RfwWidget('sliderDemo', state: {'value': 50.0})
Widget buildSliderDemo() {
  return Column(
    children: [
      Slider(
        min: 0.0,
        max: 100.0,
        value: StateRef('value'),
        onChanged: RfwHandler.setStateFromArg('value'),
        onChangeStart: RfwHandler.event('slider.start', {}),
        onChangeEnd: RfwHandler.event('slider.end', {}),
      ),
      Text(text: RfwConcat(['Value: ', StateRef('value')])),
    ],
  );
}

@RfwWidget('drawerDemo')
Widget buildDrawerDemo() {
  return Scaffold(
    appBar: AppBar(title: const Text(text: 'Drawer Demo')),
    drawer: Drawer(
      child: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text(text: 'Home'),
            onTap: RfwHandler.event('drawer.home', {}),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text(text: 'Settings'),
            onTap: RfwHandler.event('drawer.settings', {}),
          ),
        ],
      ),
    ),
    body: const Center(
      child: Text(text: 'Swipe or tap menu to open drawer'),
    ),
  );
}

@RfwWidget('dividerDemo')
Widget buildDividerDemo() {
  return Column(
    children: [
      const Text(text: 'Above Divider'),
      const Divider(thickness: 2.0, color: Color(0xFF2196F3)),
      const Text(text: 'Below Divider'),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text(text: 'Left'),
          SizedBox(
            height: 40,
            child: VerticalDivider(thickness: 2.0, color: Color(0xFFFF9800)),
          ),
          Text(text: 'Right'),
        ],
      ),
    ],
  );
}

@RfwWidget('progressDemo')
Widget buildProgressDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: const [
      CircularProgressIndicator(value: 0.7, color: Color(0xFF2196F3), strokeWidth: 6.0),
      SizedBox(height: 16),
      LinearProgressIndicator(value: 0.4, color: Color(0xFF4CAF50), backgroundColor: Color(0xFFE0E0E0)),
    ],
  );
}

@RfwWidget('overflowBarDemo')
Widget buildOverflowBarDemo() {
  return OverflowBar(
    spacing: 8.0,
    overflowSpacing: 4.0,
    children: [
      ElevatedButton(
        onPressed: RfwHandler.event('overflow.1', {}),
        child: const Text(text: 'Action 1'),
      ),
      OutlinedButton(
        onPressed: RfwHandler.event('overflow.2', {}),
        child: const Text(text: 'Action 2'),
      ),
      TextButton(
        onPressed: RfwHandler.event('overflow.3', {}),
        child: const Text(text: 'Action 3'),
      ),
    ],
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add Material category catalog widgets"
```

---

## Task 8: Add catalog widgets — Widget composition (args pattern)

**Files:**
- Modify: `example/lib/catalog/catalog_widgets.dart`

- [ ] **Step 1: Add args pattern demo**

Append to `catalog_widgets.dart`:

```dart
// ============================================================
// Widget Composition (args pattern)
// ============================================================

@RfwWidget('argsPatternDemo')
Widget buildArgsPatternDemo() {
  return Column(
    children: [
      // data.list.0 index access
      Text(text: DataRef('catalog.sampleItems.0.name')),
      const SizedBox(height: 8),
      // RfwSwitch with default case
      Container(
        width: 100,
        height: 40,
        color: RfwSwitchValue<int>(
          value: DataRef('catalog.sampleItems.0.name'),
          cases: {'Apple': 0xFFFF0000, 'Banana': 0xFFFFEB3B},
          defaultCase: 0xFF9E9E9E,
        ),
      ),
    ],
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/catalog/catalog_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/catalog/catalog_widgets.dart
git commit -m "feat(example): add widget composition / args pattern demo"
```

---

## Task 9: Create e-commerce widgets — shopHome

**Files:**
- Create: `example/lib/ecommerce/shop_widgets.dart`

- [ ] **Step 1: Create shop_widgets.dart with shopHome screen**

```dart
// ignore_for_file: argument_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// Screen 1: Shop Home
// ============================================================

@RfwWidget('shopHome')
Widget buildShopHome() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Promotion Banner
        Container(
          width: double.infinity,
          height: 160,
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, 0.0),
              end: Alignment(1.0, 0.0),
              colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                text: DataRef('banners.items.0.title'),
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 4),
              Text(
                text: DataRef('banners.items.0.subtitle'),
                style: const TextStyle(fontSize: 14.0, color: Color(0xFFFFFFFF)),
              ),
            ],
          ),
        ),

        // Categories
        Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            text: '카테고리',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...RfwFor(
                items: DataRef('categories.items'),
                itemName: 'cat',
                builder: (cat) => GestureDetector(
                  onTap: RfwHandler.event('navigate', {'page': 'productList'}),
                  child: Column(
                    children: [
                      Icon(cat['icon'], size: 32.0, color: const Color(0xFF2196F3)),
                      const SizedBox(height: 4),
                      Text(text: cat['name'], style: const TextStyle(fontSize: 12.0)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Recommended Products
        Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            text: '추천 상품',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              ...RfwFor(
                items: DataRef('recommended.items'),
                itemName: 'product',
                builder: (product) => GestureDetector(
                  onTap: RfwHandler.event('navigate', {'page': 'productDetail'}),
                  child: Container(
                    width: 140,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Image(
                            image: NetworkImage(product['image']),
                            width: 140,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          text: product['name'],
                          style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          text: RfwConcat([product['price'], '원']),
                          style: const TextStyle(fontSize: 13.0, color: Color(0xFF757575)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/ecommerce/shop_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/ecommerce/shop_widgets.dart
git commit -m "feat(example): add shopHome e-commerce screen"
```

---

## Task 10: Add e-commerce widgets — productList + productDetail

**Files:**
- Modify: `example/lib/ecommerce/shop_widgets.dart`

- [ ] **Step 1: Add productList and productDetail screens**

Append to `shop_widgets.dart`:

```dart
// ============================================================
// Screen 2: Product List
// ============================================================

@RfwWidget('productList')
Widget buildProductList() {
  return Column(
    children: [
      // Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF2196F3),
        child: const Text(
          text: '상품 목록',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
      ),
      // Product Grid
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ...RfwFor(
              items: DataRef('products.items'),
              itemName: 'item',
              builder: (item) => GestureDetector(
                onTap: RfwHandler.event('navigate', {'page': 'productDetail'}),
                child: Card(
                  margin: const EdgeInsets.all(4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                          child: Image(
                            image: NetworkImage(item['image']),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text: item['name'],
                                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                text: RfwConcat([item['price'], '원']),
                                style: const TextStyle(fontSize: 14.0, color: Color(0xFF757575)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                color: RfwSwitchValue<int>(
                                  value: item['inStock'],
                                  cases: {true: 0xFF4CAF50, false: 0xFFFF5722},
                                ),
                                child: Text(
                                  text: RfwSwitchValue<String>(
                                    value: item['inStock'],
                                    cases: {true: '재고 있음', false: '품절'},
                                  ),
                                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 12.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================
// Screen 3: Product Detail
// ============================================================

@RfwWidget('productDetail', state: {'quantity': 1})
Widget buildProductDetail() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Image(
          image: NetworkImage(DataRef('product.image')),
          width: double.infinity,
          height: 300,
          fit: BoxFit.cover,
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name + Price
              Text(
                text: DataRef('product.name'),
                style: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                text: RfwConcat([DataRef('product.price'), '원']),
                style: const TextStyle(fontSize: 20.0, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Stock status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                color: RfwSwitchValue<int>(
                  value: DataRef('product.inStock'),
                  cases: {true: 0xFF4CAF50, false: 0xFFFF5722},
                ),
                child: Text(
                  text: RfwSwitchValue<String>(
                    value: DataRef('product.inStock'),
                    cases: {true: '재고 있음', false: '품절'},
                  ),
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                text: DataRef('product.description'),
                style: const TextStyle(fontSize: 15.0, color: Color(0xFF616161)),
              ),

              const SizedBox(height: 24),

              // Quantity selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: RfwHandler.event('quantity.decrease', {}),
                    child: const Text(text: '-'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      text: StateRef('quantity'),
                      style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: RfwHandler.event('quantity.increase', {}),
                    child: const Text(text: '+'),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Add to cart button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: RfwHandler.event('addToCart', {'id': DataRef('product.id')}),
                  child: const Text(text: '장바구니에 담기'),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/ecommerce/shop_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/ecommerce/shop_widgets.dart
git commit -m "feat(example): add productList and productDetail e-commerce screens"
```

---

## Task 11: Add e-commerce widgets — cart + orderComplete

**Files:**
- Modify: `example/lib/ecommerce/shop_widgets.dart`

- [ ] **Step 1: Add cart and orderComplete screens**

Append to `shop_widgets.dart`:

```dart
// ============================================================
// Screen 4: Cart
// ============================================================

@RfwWidget('cart')
Widget buildCart() {
  return Column(
    children: [
      // Header
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        color: const Color(0xFF2196F3),
        child: const Text(
          text: '장바구니',
          style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
      ),

      // Cart items
      Expanded(
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            ...RfwFor(
              items: DataRef('cart.items'),
              itemName: 'cartItem',
              builder: (cartItem) => Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  title: Text(text: cartItem['name']),
                  subtitle: Text(text: RfwConcat([cartItem['price'], '원 × ', cartItem['quantity']])),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: RfwHandler.event('cart.decrease', {'id': cartItem['id']}),
                        child: const Icon(Icons.remove_circle_outline, color: Color(0xFF757575)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          text: cartItem['quantity'],
                          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                      GestureDetector(
                        onTap: RfwHandler.event('cart.increase', {'id': cartItem['id']}),
                        child: const Icon(Icons.add_circle_outline, color: Color(0xFF2196F3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Total + Checkout
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF),
          boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  text: '총 금액',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  text: RfwConcat([DataRef('cart.totalPrice'), '원']),
                  style: const TextStyle(fontSize: 20.0, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: RfwHandler.event('checkout', {}),
                child: Text(text: RfwConcat(['주문하기 (', DataRef('cart.itemCount'), '개)'])),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

// ============================================================
// Screen 5: Order Complete
// ============================================================

@RfwWidget('orderComplete')
Widget buildOrderComplete() {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80.0, color: Color(0xFF4CAF50)),
          const SizedBox(height: 24),
          const Text(
            text: '주문이 완료되었습니다!',
            style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            text: RfwConcat(['주문번호: ', DataRef('order.orderNumber')]),
            style: const TextStyle(fontSize: 16.0, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 8),
          Text(
            text: RfwConcat(['총 ', DataRef('order.itemCount'), '개 상품 / ', DataRef('order.totalPrice'), '원']),
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF757575)),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: RfwHandler.event('navigate', {'page': 'shopHome'}),
            child: const Text(text: '홈으로 돌아가기'),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/ecommerce/shop_widgets.dart
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/ecommerce/shop_widgets.dart
git commit -m "feat(example): add cart and orderComplete e-commerce screens"
```

---

## Task 12: Rewrite main.dart

**Files:**
- Rewrite: `example/lib/main.dart`

- [ ] **Step 1: Write main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import 'data/mock_data.dart';

void main() {
  runApp(const RfwGenExampleApp());
}

class RfwGenExampleApp extends StatelessWidget {
  const RfwGenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rfw_gen Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();
  bool _isLoaded = false;
  String? _error;

  // Catalog state
  String _selectedCategory = 'Layout';
  String? _selectedWidget;

  // E-commerce navigation stack managed by host
  String _currentShopPage = 'shopHome';

  static const _catalogLibrary = LibraryName(<String>['catalog']);
  static const _shopLibrary = LibraryName(<String>['shop']);

  static const Map<String, List<String>> _catalogWidgets = {
    'Layout': [
      'columnDemo', 'rowDemo', 'wrapDemo', 'stackDemo',
      'expandedDemo', 'sizedBoxDemo', 'alignDemo',
      'aspectRatioDemo', 'intrinsicDemo',
    ],
    'Scrolling': [
      'listViewDemo', 'gridViewDemo', 'scrollViewDemo', 'listBodyDemo',
    ],
    'Styling': [
      'containerDemo', 'paddingOpacityDemo', 'clipRRectDemo',
      'defaultTextStyleDemo', 'directionalityDemo',
      'iconDemo', 'iconThemeDemo', 'imageDemo',
      'textDemo', 'coloredBoxDemo',
    ],
    'Transform': [
      'rotationDemo', 'scaleDemo', 'fittedBoxDemo',
    ],
    'Interaction': [
      'gestureDetectorDemo', 'inkWellDemo',
    ],
    'Material': [
      'scaffoldDemo', 'materialDemo', 'cardDemo', 'buttonDemo',
      'listTileDemo', 'sliderDemo', 'drawerDemo', 'dividerDemo',
      'progressDemo', 'overflowBarDemo',
    ],
    'Other': [
      'animationDefaultsDemo', 'safeAreaDemo', 'argsPatternDemo',
    ],
  };

  @override
  void initState() {
    super.initState();
    _runtime.update(const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
    _runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());
    MockData.setupCatalog(_data);
    MockData.setupShop(_data);
    _loadRfwBinaries();
  }

  Future<void> _loadRfwBinaries() async {
    try {
      final catalogBytes = await rootBundle.load('assets/catalog_widgets.rfw');
      final shopBytes = await rootBundle.load('assets/shop_widgets.rfw');
      _runtime.update(_catalogLibrary, decodeLibraryBlob(catalogBytes.buffer.asUint8List()));
      _runtime.update(_shopLibrary, decodeLibraryBlob(shopBytes.buffer.asUint8List()));
      setState(() => _isLoaded = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _handleCatalogEvent(String name, DynamicMap args) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Event: $name ${args.isNotEmpty ? args : ""}')),
    );
  }

  void _handleShopEvent(String name, DynamicMap args) {
    switch (name) {
      case 'navigate':
        final page = args['page'] as String;
        if (page == 'shopHome') {
          // Pop back to home
          setState(() => _currentShopPage = 'shopHome');
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => _ShopPage(
                runtime: _runtime,
                data: _data,
                library: _shopLibrary,
                widgetName: page,
                onEvent: _handleShopEvent,
              ),
            ),
          );
        }
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Shop Event: $name ${args.isNotEmpty ? args : ""}')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _tabIndex == 0 ? _buildCatalogTab() : _buildShopTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() {
          _tabIndex = i;
          _selectedWidget = null;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.widgets), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Shop'),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        AppBar(
          title: Text(_selectedWidget ?? 'Widget Catalog'),
          leading: _selectedWidget != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedWidget = null),
                )
              : null,
        ),
        if (_selectedWidget == null) ...[
          // Category chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: _catalogWidgets.keys.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          // Widget list
          Expanded(
            child: ListView.builder(
              itemCount: _catalogWidgets[_selectedCategory]!.length,
              itemBuilder: (context, i) {
                final name = _catalogWidgets[_selectedCategory]![i];
                return ListTile(
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selectedWidget = name),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: RemoteWidget(
              runtime: _runtime,
              data: _data,
              widget: FullyQualifiedWidgetName(_catalogLibrary, _selectedWidget!),
              onEvent: _handleCatalogEvent,
            ),
          ),
      ],
    );
  }

  Widget _buildShopTab() {
    return RemoteWidget(
      runtime: _runtime,
      data: _data,
      widget: FullyQualifiedWidgetName(_shopLibrary, _currentShopPage),
      onEvent: _handleShopEvent,
    );
  }
}

class _ShopPage extends StatelessWidget {
  const _ShopPage({
    required this.runtime,
    required this.data,
    required this.library,
    required this.widgetName,
    required this.onEvent,
  });

  final Runtime runtime;
  final DynamicContent data;
  final LibraryName library;
  final String widgetName;
  final void Function(String name, DynamicMap args) onEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widgetName)),
      body: RemoteWidget(
        runtime: runtime,
        data: data,
        widget: FullyQualifiedWidgetName(library, widgetName),
        onEvent: (name, args) {
          if (name == 'navigate') {
            final page = args['page'] as String;
            if (page == 'shopHome') {
              Navigator.popUntil(context, (route) => route.isFirst);
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _ShopPage(
                    runtime: runtime,
                    data: data,
                    library: library,
                    widgetName: page,
                    onEvent: onEvent,
                  ),
                ),
              );
            }
          } else {
            onEvent(name, args);
          }
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Verify compilation**

```bash
cd example && dart analyze lib/
```

- [ ] **Step 3: Commit**

```bash
git add example/lib/main.dart
git commit -m "feat(example): rewrite main.dart with 2-tab structure and event navigation"
```

---

## Task 13: Run build_runner and generate .rfw binaries

**Files:**
- Generate: `example/lib/catalog/catalog_widgets.rfwtxt`, `catalog_widgets.rfw`
- Generate: `example/lib/ecommerce/shop_widgets.rfwtxt`, `shop_widgets.rfw`
- Copy to: `example/assets/catalog_widgets.rfw`, `example/assets/shop_widgets.rfw`

- [ ] **Step 1: Run build_runner**

```bash
cd example && dart run build_runner build --delete-conflicting-outputs
```

Expected: generates `.rfwtxt` and `.rfw` files alongside source files.

- [ ] **Step 2: Copy .rfw binaries to assets**

```bash
cp example/lib/catalog/catalog_widgets.rfw example/assets/catalog_widgets.rfw
cp example/lib/ecommerce/shop_widgets.rfw example/assets/shop_widgets.rfw
```

- [ ] **Step 3: Verify rfwtxt output is valid**

```bash
# Quickly check the generated files exist and have content
wc -l example/lib/catalog/catalog_widgets.rfwtxt example/lib/ecommerce/shop_widgets.rfwtxt
```

- [ ] **Step 4: Fix any build errors**

If build_runner fails, read the error output, fix the widget code, and re-run.

- [ ] **Step 5: Commit**

```bash
git add example/lib/catalog/catalog_widgets.rfwtxt example/lib/catalog/catalog_widgets.rfw
git add example/lib/ecommerce/shop_widgets.rfwtxt example/lib/ecommerce/shop_widgets.rfw
git add example/assets/
git commit -m "chore(example): generate rfwtxt and rfw binaries for catalog and shop"
```

---

## Task 14: Write conversion validation tests

**Files:**
- Create: `example/test/catalog_conversion_test.dart`
- Create: `example/test/shop_conversion_test.dart`

These tests validate that every generated rfwtxt can be parsed by `parseLibraryFile()`.

- [ ] **Step 1: Write catalog conversion test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

void main() {
  test('catalog_widgets.rfwtxt is valid rfwtxt', () {
    final file = File('lib/catalog/catalog_widgets.rfwtxt');
    expect(file.existsSync(), isTrue, reason: 'Run build_runner first');
    final content = file.readAsStringSync();
    expect(content.isNotEmpty, isTrue);
    // This will throw if the rfwtxt is invalid
    final result = parseLibraryFile(content);
    expect(result, isNotNull);
  });
}
```

- [ ] **Step 2: Write shop conversion test**

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

void main() {
  test('shop_widgets.rfwtxt is valid rfwtxt', () {
    final file = File('lib/ecommerce/shop_widgets.rfwtxt');
    expect(file.existsSync(), isTrue, reason: 'Run build_runner first');
    final content = file.readAsStringSync();
    expect(content.isNotEmpty, isTrue);
    final result = parseLibraryFile(content);
    expect(result, isNotNull);
  });
}
```

- [ ] **Step 3: Run tests**

```bash
cd example && flutter test test/catalog_conversion_test.dart test/shop_conversion_test.dart
```

Expected: both pass.

- [ ] **Step 4: Commit**

```bash
git add example/test/catalog_conversion_test.dart example/test/shop_conversion_test.dart
git commit -m "test(example): add conversion validation tests for catalog and shop widgets"
```

---

## Task 15: Write app widget tests

**Files:**
- Create: `example/test/app_test.dart`

- [ ] **Step 1: Write widget tests for main.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_example/main.dart';

void main() {
  testWidgets('app renders with two navigation tabs', (tester) async {
    await tester.pumpWidget(const RfwGenExampleApp());
    await tester.pumpAndSettle();

    // Should have bottom navigation
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Shop'), findsOneWidget);
  });

  testWidgets('catalog tab shows category chips', (tester) async {
    await tester.pumpWidget(const RfwGenExampleApp());
    await tester.pumpAndSettle();

    // Default tab is catalog, should show categories
    expect(find.text('Layout'), findsOneWidget);
    expect(find.text('Material'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
  });

  testWidgets('tapping category shows widget list', (tester) async {
    await tester.pumpWidget(const RfwGenExampleApp());
    await tester.pumpAndSettle();

    // Tap Scrolling category
    await tester.tap(find.text('Scrolling'));
    await tester.pumpAndSettle();

    expect(find.text('listViewDemo'), findsOneWidget);
    expect(find.text('gridViewDemo'), findsOneWidget);
  });

  testWidgets('switching to shop tab works', (tester) async {
    await tester.pumpWidget(const RfwGenExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shop'));
    await tester.pumpAndSettle();

    // Shop tab should be active (RFW widget renders)
    // Verify no crash and tab switch works
    expect(find.text('Shop'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run tests**

```bash
cd example && flutter test test/app_test.dart
```

- [ ] **Step 3: Fix any failures and re-run**

- [ ] **Step 4: Commit**

```bash
git add example/test/app_test.dart
git commit -m "test(example): add widget tests for app navigation and catalog"
```

---

## Task 16: Write golden tests

**Files:**
- Create: `example/test/golden_test.dart`

- [ ] **Step 1: Write golden tests for catalog and e-commerce**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'package:rfw_gen_example/data/mock_data.dart';

Future<Runtime> _setupRuntime() async {
  final runtime = Runtime();
  runtime.update(const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
  runtime.update(const LibraryName(<String>['material']), createMaterialWidgets());

  final catalogBytes = await rootBundle.load('assets/catalog_widgets.rfw');
  runtime.update(
    const LibraryName(<String>['catalog']),
    decodeLibraryBlob(catalogBytes.buffer.asUint8List()),
  );

  final shopBytes = await rootBundle.load('assets/shop_widgets.rfw');
  runtime.update(
    const LibraryName(<String>['shop']),
    decodeLibraryBlob(shopBytes.buffer.asUint8List()),
  );

  return runtime;
}

void main() {
  const catalogLib = LibraryName(<String>['catalog']);
  const shopLib = LibraryName(<String>['shop']);

  // Catalog golden tests (one per category)
  for (final entry in {
    'columnDemo': 'layout',
    'listViewDemo': 'scrolling',
    'containerDemo': 'styling',
    'rotationDemo': 'transform',
    'gestureDetectorDemo': 'interaction',
    'buttonDemo': 'material',
    'safeAreaDemo': 'other',
  }.entries) {
    testWidgets('golden: catalog/${entry.value}/${entry.key}', (tester) async {
      final runtime = await _setupRuntime();
      final data = DynamicContent();
      MockData.setupCatalog(data);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RemoteWidget(
            runtime: runtime,
            data: data,
            widget: FullyQualifiedWidgetName(catalogLib, entry.key),
            onEvent: (_, __) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RemoteWidget),
        matchesGoldenFile('goldens/catalog_${entry.value}.png'),
      );
    });
  }

  // E-commerce golden tests
  for (final screen in ['shopHome', 'productList', 'productDetail', 'cart', 'orderComplete']) {
    testWidgets('golden: shop/$screen', (tester) async {
      final runtime = await _setupRuntime();
      final data = DynamicContent();
      MockData.setupShop(data);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: RemoteWidget(
            runtime: runtime,
            data: data,
            widget: FullyQualifiedWidgetName(shopLib, screen),
            onEvent: (_, __) {},
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(RemoteWidget),
        matchesGoldenFile('goldens/shop_$screen.png'),
      );
    });
  }
}
```

- [ ] **Step 2: Generate golden files**

```bash
cd example && flutter test test/golden_test.dart --update-goldens
```

- [ ] **Step 3: Verify goldens pass**

```bash
cd example && flutter test test/golden_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add example/test/golden_test.dart example/test/goldens/
git commit -m "test(example): add golden tests for catalog and e-commerce screens"
```

---

## Task 17: Rewrite README

**Files:**
- Rewrite: `example/README.md`

- [ ] **Step 1: Write README**

```markdown
# rfw_gen Example App

rfw_gen의 모든 기능을 showcase하는 예제 앱입니다.

## 구조

| 탭 | 내용 |
|----|------|
| **Catalog** | 56개 지원 위젯을 7개 카테고리별로 분류하여 개별 데모 |
| **Shop** | 이커머스 시나리오 5개 화면 — 실전 RFW 패턴 시연 |

## 실행

```bash
# 1. 의존성 설치
cd example && flutter pub get

# 2. 코드 생성 (rfwtxt + rfw 바이너리)
dart run build_runner build --delete-conflicting-outputs

# 3. 에셋 복사
cp lib/catalog/catalog_widgets.rfw assets/catalog_widgets.rfw
cp lib/ecommerce/shop_widgets.rfw assets/shop_widgets.rfw

# 4. 앱 실행
flutter run
```

## 프로젝트 구조

```
lib/
├── main.dart                    — 앱 셸 (2탭 + Runtime + 이벤트 라우터)
├── catalog/
│   └── catalog_widgets.dart     — 카탈로그 @RfwWidget 데모
├── ecommerce/
│   └── shop_widgets.dart        — 이커머스 @RfwWidget 화면
└── data/
    └── mock_data.dart           — DynamicContent mock 데이터
```

## 카탈로그 카테고리

- **Layout**: Column, Row, Wrap, Stack, Expanded, SizedBox, Align, AspectRatio, IntrinsicHeight
- **Scrolling**: ListView, GridView, SingleChildScrollView, ListBody
- **Styling & Visual**: Container, Padding, Opacity, ClipRRect, Text, Icon, Image, etc.
- **Transform**: Rotation, Scale, FittedBox
- **Interaction**: GestureDetector, InkWell
- **Material**: Scaffold, AppBar, Card, Buttons, ListTile, Slider, Drawer, etc.
- **Other**: AnimationDefaults, SafeArea, Widget Composition (args pattern)

## 이커머스 데모 화면

1. **shopHome** — 배너 + 카테고리 + 추천 상품
2. **productList** — 상품 카드 리스트 + 재고 상태
3. **productDetail** — 상품 상세 + 수량 선택 + 장바구니
4. **cart** — 장바구니 목록 + 수량 조절 + 결제
5. **orderComplete** — 주문 완료 확인

## 시연하는 rfw_gen 기능

- `@RfwWidget` 어노테이션 + `state` 선언
- `DataRef`, `ArgsRef`, `StateRef` — 데이터 바인딩
- `RfwFor` — 리스트 루프
- `RfwSwitch` / `RfwSwitchValue` — 조건부 렌더링
- `RfwConcat` — 문자열 연결
- `RfwHandler.setState` / `setStateFromArg` / `event` — 이벤트 핸들링
- 암시적 애니메이션 (`duration` / `curve` / `onEnd`)
- Navigator.push 기반 화면 이동 (이벤트 → 호스트 앱)
```

- [ ] **Step 2: Commit**

```bash
git add example/README.md
git commit -m "docs(example): rewrite README with project structure and usage guide"
```

---

## Task 18: Final verification

- [ ] **Step 1: Run all tests**

```bash
cd example && flutter test
```

Expected: all tests pass.

- [ ] **Step 2: Run static analysis**

```bash
cd example && dart analyze
```

Expected: no errors.

- [ ] **Step 3: Run the app**

```bash
cd example && flutter run -d chrome
```

Verify:
- Catalog tab: category chips work, widget demos render
- Shop tab: home screen renders, navigation events work
- Event SnackBars appear on interactions

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A example/
git commit -m "fix(example): final adjustments from verification"
```
