# Example App Redesign — Design Spec

## Overview

rfw_gen example 앱을 **위젯 카탈로그 + 이커머스 데모** 구조로 전면 재설계한다.
기존 28개 위젯을 삭제하고 처음부터 체계적으로 새로 작성한다.

### 목표
- **평가용**: rfw_gen이 뭘 할 수 있는지 빠르게 파악
- **레퍼런스용**: 실전 사용 패턴(데이터 바인딩, 이벤트, 상태관리) 참고

### 비목표
- 프로덕션 앱 수준의 UI 완성도
- Widgetbook 통합 (별도 작업)
- 개발자 도구 (rfwtxt 뷰어 등, 향후 확장)
- Custom Widget 데모 (rfw_gen.yaml 기반, 별도 작업으로 분리)

---

## 프로젝트 구조

```
example/lib/
├── main.dart                    — MaterialApp + BottomNavigationBar (2탭)
├── catalog/
│   └── catalog_widgets.dart     — 카탈로그 @RfwWidget (6개 카테고리)
├── ecommerce/
│   └── shop_widgets.dart        — 이커머스 @RfwWidget (5개 화면)
└── data/
    └── mock_data.dart           — DynamicContent 모든 mock 데이터
```

### 빌드 출력
- `catalog_widgets.rfwtxt` / `catalog_widgets.rfw`
- `shop_widgets.rfwtxt` / `shop_widgets.rfw`

### Runtime 설정
```dart
// 라이브러리 등록
runtime.update(const LibraryName(['core', 'widgets']), createCoreWidgets());
runtime.update(const LibraryName(['material']), createMaterialWidgets());
runtime.update(const LibraryName(['catalog']), catalogBlob);   // catalog_widgets.rfw
runtime.update(const LibraryName(['shop']), shopBlob);         // shop_widgets.rfw
```

위젯 참조 시 FullyQualifiedWidgetName 사용:
- 카탈로그: `FullyQualifiedWidgetName(LibraryName(['catalog']), 'columnDemo')`
- 이커머스: `FullyQualifiedWidgetName(LibraryName(['shop']), 'shopHome')`

위젯 이름 충돌 방지: 카탈로그는 `xxxDemo` 접미사, 이커머스는 화면명 그대로 사용.

### main.dart 역할
- `MaterialApp` + `BottomNavigationBar` 2탭 (카탈로그 / 이커머스)
- RFW Runtime 초기화: core + material + catalog + shop 라이브러리
- 카탈로그 UI(카테고리 칩, 위젯 리스트)는 **네이티브 Flutter**로 구현, 개별 위젯 데모만 RemoteWidget으로 렌더링
- `onEvent` 핸들러:
  - `"navigate"` → `Navigator.push()` 로 새 페이지에 RemoteWidget 렌더링
  - 기타 이벤트 → SnackBar 표시
- 각 탭은 자체 Navigator 스택으로 독립 네비게이션

---

## 탭 1: 위젯 카탈로그

rfw-widgets.md 공식 분류 7개 카테고리. 56개 지원 위젯 전체 커버리지 목표.

카탈로그 UI: 네이티브 Flutter로 카테고리 칩 선택 → 해당 카테고리 위젯 리스트 → 각 위젯 탭 시 RemoteWidget 렌더링.

### Layout
| 위젯 | 보여줄 핵심 |
|------|------------|
| Column | mainAxisAlignment 옵션들 |
| Row | crossAxisAlignment + spacing |
| Wrap | 태그 목록 (자동 줄바꿈) |
| Stack + Positioned | 오버레이 레이아웃 |
| Expanded + Flexible | 비율 배분 |
| SizedBox / SizedBoxExpand / SizedBoxShrink / Spacer | 고정/확장/축소 크기 + 간격 |
| Center / Align | 정렬 옵션 |
| AspectRatio / FractionallySizedBox | 비율 기반 사이징 |
| IntrinsicHeight / IntrinsicWidth | 내재 크기 |

### Scrolling
| 위젯 | 보여줄 핵심 |
|------|------------|
| ListView | 스크롤 리스트 |
| GridView | 그리드 레이아웃 |
| SingleChildScrollView | 스크롤 영역 |
| ListBody | mainAxis + reverse |

### Styling & Visual
| 위젯 | 보여줄 핵심 |
|------|------------|
| Container | decoration, gradient (linear + radial), boxShadow, duration/curve 애니메이션 |
| Padding / Opacity | 기본 스타일링 + duration/curve 암시적 애니메이션 |
| ClipRRect | borderRadius 라운딩 |
| DefaultTextStyle | 텍스트 스타일 상속 + duration/curve |
| Directionality | RTL/LTR 텍스트 방향 |
| Icon | MaterialIcons 아이콘 |
| IconTheme | 아이콘 테마 전파 |
| Image | 네트워크 이미지 |
| Text | TextStyle 다양한 옵션 |
| ColoredBox / Placeholder | 단순 컬러/플레이스홀더 |

### Transform
| 위젯 | 보여줄 핵심 |
|------|------------|
| Rotation | turns 기반 회전 + duration/curve 애니메이션 |
| Scale | 확대/축소 + duration/curve 애니메이션 |
| FittedBox | fit 옵션 |

### Interaction
| 위젯 | 보여줄 핵심 |
|------|------------|
| GestureDetector | onTap, onLongPress, onDoubleTap + setState |
| InkWell | Material ripple 효과 + onTap, onLongPress |

### Material
| 위젯 | 보여줄 핵심 |
|------|------------|
| Scaffold + AppBar | 기본 Material 페이지 + bottomNavigationBar 슬롯 |
| Material | type, elevation, color |
| Card | elevation + shape (rounded, circle) |
| ElevatedButton / TextButton / OutlinedButton | 버튼 3종 |
| ListTile | leading/title/subtitle/trailing |
| Slider | onChanged + onChangeStart + onChangeEnd + setStateFromArg |
| Drawer | 사이드 메뉴 (Scaffold.drawer 슬롯) |
| Divider / VerticalDivider | 구분선 |
| CircularProgressIndicator / LinearProgressIndicator | 로딩 |
| FloatingActionButton | FAB |
| OverflowBar | 버튼 그룹 |

### Other
| 위젯 | 보여줄 핵심 |
|------|------------|
| AnimationDefaults | duration/curve 기본값 설정 (하위 위젯 암시적 애니메이션 제어) |
| SafeArea | 노치/상태바 안전 영역 |

### 암시적 애니메이션 데모
Container, Opacity, Rotation 등에서 `duration`/`curve` 파라미터 + `onEnd` 핸들러를 명시적으로 시연.
AnimationDefaults와 함께 사용하는 패턴도 포함.

### 위젯 합성 (args 패턴)
카탈로그에 위젯 합성 예제 1개 포함: 한 RFW 위젯이 다른 위젯을 `args.paramName`으로 참조하는 패턴 시연.
리스트 인덱스 접근 (`data.list.0`)과 switch default 케이스도 함께 시연.

---

## 탭 2: 이커머스 데모

5개 화면, 이벤트 기반 Navigator.push/pop 네비게이션.

### 네비게이션 플로우
```
홈 → 카테고리 클릭 → 상품 리스트 → 상품 클릭 → 상품 상세
                                                    ↓
                                    장바구니 담기 → 장바구니 → 주문 완료 → 홈
```

### 화면 1: shopHome (홈)
- 프로모션 배너: Container + Stack + Positioned
- 카테고리 아이콘 목록: Row + Column + Icon
- 추천 상품 가로 스크롤: ListView horizontal
- 사용 기능: `DataRef`, `RfwFor`, `RfwHandler.event("navigate", {page: "productList", category: ...})`

### 화면 2: productList (상품 리스트)
- 상품 카드 그리드: GridView
- 각 카드: 이미지 + 이름 + 가격 + 재고 상태
- 사용 기능: `RfwFor`, `RfwSwitch` (재고 여부 색상), `DataRef`, `event "navigate" {page: "productDetail", id: ...}`

### 화면 3: productDetail (상품 상세)
- 상품 이미지: Image
- 이름/가격/설명: Text + TextStyle
- 수량 선택: 버튼 + StateRef + setState
- 장바구니 담기 버튼: ElevatedButton + event
- 사용 기능: `DataRef`, `StateRef`, `RfwSwitchValue`, `RfwConcat`, `RfwHandler.event("addToCart", {id, quantity})`

### 화면 4: cart (장바구니)
- 장바구니 아이템 목록: RfwFor + ListTile
- 수량 조절: +/- 버튼 + event
- 총 금액 표시: DataRef
- 주문하기 버튼: event "checkout"
- 사용 기능: `RfwFor`, `DataRef`, `RfwConcat`, 다양한 `event`

### 화면 5: orderComplete (주문 완료)
- 완료 아이콘 + 메시지: Center + Column + Icon
- 주문 번호: DataRef
- 홈으로 돌아가기: event "navigate" {page: "shopHome"}
- 사용 기능: `DataRef`, `RfwConcat`, `event`

### 호스트 앱 onEvent 처리
```dart
onEvent: (name, args) {
  switch (name) {
    case 'navigate':
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => RfwPage(widget: args['page'], data: loadData(args)),
      ));
    case 'addToCart':
      // DynamicContent 업데이트 → RFW 리렌더
    case 'checkout':
      // 주문 처리 → orderComplete 화면으로 이동
  }
}
```

---

## Mock 데이터 (data/mock_data.dart)

### 이커머스 데이터
```dart
// 홈 화면
'banners': [
  { 'title': '여름 세일 50%', 'color': 0xFFFF6B6B, 'icon': ... },
  { 'title': '신상품 입고', 'color': 0xFF4ECDC4, 'icon': ... },
],
'categories': [
  { 'name': '의류', 'icon': 0xe14f },
  { 'name': '전자기기', 'icon': 0xe1e3 },
  { 'name': '식품', 'icon': 0xe532 },
  { 'name': '도서', 'icon': 0xe02d },
],
'recommended': [
  { 'id': 1, 'name': '무선 이어폰', 'price': 45000, 'image': '...', 'inStock': true },
  ...
],

// 상품 리스트
'products': [
  { 'id': 1, 'name': '...', 'price': ..., 'description': '...', 'inStock': true, 'category': '전자기기' },
  ...
],

// 장바구니
'cart': {
  'items': [
    { 'id': 1, 'name': '...', 'price': ..., 'quantity': 2 },
  ],
  'totalPrice': 90000,
},

// 주문 완료
'order': {
  'orderNumber': 'ORD-2026-0001',
  'itemCount': 3,
},
```

### 카탈로그 데이터
카탈로그 위젯은 대부분 정적 데이터. Dynamic 기능을 보여주는 일부 위젯에서 간단한 데이터 사용:
```dart
'catalog': {
  'sampleItems': [
    { 'name': 'Item 1', 'description': '...' },
    { 'name': 'Item 2', 'description': '...' },
  ],
}
```

---

## 테스트 전략

### 기존 테스트 처리
- `widget_test.dart` (Flutter 보일러플레이트) → 삭제
- `golden_test.dart` (3개) → 삭제 후 새로 작성

### 새 테스트 구성

테스트 파일 위치: `example/test/`

**1. 변환 검증 테스트 (필수)**
- 모든 @RfwWidget 출력을 `parseLibraryFile()`로 파싱 검증
- 카탈로그 + 이커머스 전체 대상
- 기존 integration_test.dart 패턴 따름

**2. 골든 테스트 (최소 12개)**
- 카탈로그: 카테고리별 대표 위젯 1개씩 (7개)
- 이커머스: 5개 화면 각각 (5개)

**3. 위젯 테스트**
- main.dart: 탭 전환, 카테고리 선택 동작
- 이커머스: 네비게이션 이벤트 → Navigator.push 호출 확인
- onEvent 핸들러: navigate / addToCart / checkout 이벤트 처리 검증
- DynamicContent 업데이트 시 RemoteWidget 리렌더 검증

### README
기존 보일러플레이트 → 전면 재작성:
- rfw_gen 소개
- example 앱 실행 방법
- 프로젝트 구조 설명
- 코드 생성 워크플로우

---

## 기술 검증 결과

| 항목 | 결과 | 비고 |
|------|------|------|
| 멀티 파일 @RfwWidget | ✅ | 파일별 독립 빌드 |
| Runtime 멀티 라이브러리 | ✅ | runtime.update() 다중 호출 |
| Navigator + RemoteWidget | ✅ | onEvent → Navigator.push 가능 |
| Slider setStateFromArg | ✅ | 통합 테스트 검증됨 |
| Image + NetworkImage | ✅ | { source: "url" } 변환 |
| Drawer | ✅ | Scaffold.drawer 슬롯 사용 |

---

## 요약

| 항목 | 내용 |
|------|------|
| 구조 | 완전 분리형 (catalog/ + ecommerce/ + data/) |
| 탭 | 카탈로그 + 이커머스 데모 |
| 카탈로그 | 7개 카테고리, 56개 지원 위젯 전체 커버리지 |
| 이커머스 | 5개 화면, Navigator.push 네비게이션 |
| 데이터 | mock_data.dart에 DynamicContent 집중 |
| 테스트 | 변환 검증 + 골든 (최소 12개) + 위젯 테스트 |
| 기존 위젯 | 전부 삭제, 처음부터 재작성 |
