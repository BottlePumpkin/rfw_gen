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

- **Layout**: Column, Row, Wrap, Stack, Expanded, SizedBox, Align, AspectRatio, IntrinsicHeight/Width
- **Scrolling**: ListView, GridView, SingleChildScrollView, ListBody
- **Styling & Visual**: Container, Padding, Opacity, ClipRRect, Text, Icon, Image 등
- **Transform**: Rotation, Scale, FittedBox
- **Interaction**: GestureDetector, InkWell
- **Material**: Scaffold, AppBar, Card, Buttons, ListTile, Slider, Drawer 등
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
- 암시적 애니메이션 (`duration` / `curve`)
- Navigator.push 기반 화면 이동 (이벤트 → 호스트 앱)
