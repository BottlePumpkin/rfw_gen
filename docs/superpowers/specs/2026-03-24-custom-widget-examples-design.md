# namedSlots 확장 + Custom Widget 예제 추가

## 배경

rfw_gen의 custom widget 지원(v0.2)은 구현 완료 상태이나:
1. `rfw_gen.yaml`의 `child_type: namedSlots`가 에러로 차단됨 — YAML 스키마에 `named_child_slots` 필드가 없어서
2. example 앱 리뉴얼 시 기존 3개 custom widget 데모가 빠짐
3. rfw_gen의 다양한 custom widget 기능을 커버하는 종합적인 예제가 없음

## Part 1: namedSlots 지원 확장

### 현재 상태

- `WidgetMapping.namedChildSlots` 필드 존재 (widget_registry.dart:67-69)
- `ast_visitor.dart:196-214`에서 namedSlots 처리 로직 완비
- Scaffold/AppBar/ListTile이 namedSlots로 정상 동작 중
- **차단 지점**: `registerFromConfig()`의 `_parseChildType()`에서 `namedSlots` → throw

### 변경 사항

**파일**: `packages/rfw_gen/lib/src/widget_registry.dart`

1. `_parseChildType`: throw 제거 → `ChildType.namedSlots` 반환
2. `registerFromConfig`: `named_child_slots` 맵 파싱 추가
   - `child_type: namedSlots`인데 `named_child_slots` 없거나 빈 맵이면 `ArgumentError`
   - `named_child_slots`의 값이 bool이 아니면 `ArgumentError` (타입 검증)
   - `child_type`이 `namedSlots`가 아닌데 `named_child_slots`가 있으면 `ArgumentError` (설정 오류)
   - 각 엔트리: `슬롯이름: bool` (true = 리스트 슬롯, false = 단일 슬롯)
   - `namedSlots`일 때 `childParam`은 `null` (core 위젯과 동일 — namedSlots는 개별 슬롯이므로 단일 childParam 불필요)
3. 파싱된 `namedChildSlots` 맵을 `WidgetMapping` 생성자에 전달

**rfw_gen.yaml 스키마 확장**:

```yaml
CustomTile:
  import: custom.widgets
  child_type: namedSlots
  named_child_slots:
    header: false      # 단일 위젯
    content: false     # 단일 위젯
    actions: true      # 위젯 리스트
  handlers: [onTap]
```

| 필드 | 필수 | 기본값 | 설명 |
|------|------|--------|------|
| `import` | O | - | rfwtxt import 라이브러리 이름 |
| `child_type` | X | `none` | `none`, `child`, `optionalChild`, `childList`, `namedSlots` |
| `child_param` | X | 자동 | child 파라미터 이름 |
| `handlers` | X | `[]` | 핸들러 파라미터 이름 리스트 |
| `named_child_slots` | namedSlots일 때 필수 | - | 슬롯명 → 리스트 여부(bool) 맵 |

**기존 스펙과의 차이**: `2026-03-23-custom-widget-support-design.md`에서 `namedSlots`는 "미지원 — 에러 발생"으로 명시. 본 스펙은 이를 확장하여 `named_child_slots` 필드로 지원. 기술적으로 이미 파이프라인(ast_visitor, emitter)이 namedSlots를 처리하므로, YAML 파싱만 열어주면 됨.

**테스트 변경**: `widget_registry_test.dart`
- 기존 "throws when namedSlots is used" → namedSlots 성공 케이스로 변경
- 추가 테스트:
  - `child_type: namedSlots` + `named_child_slots` 누락 → `ArgumentError`
  - `child_type: namedSlots` + `named_child_slots: {}` (빈 맵) → `ArgumentError`
  - `named_child_slots` 값이 bool이 아닌 경우 → `ArgumentError`
  - `child_type: child` + `named_child_slots` 제공 → `ArgumentError`
  - 정상 케이스: 단일 슬롯 + 리스트 슬롯 혼합 → `WidgetMapping` 정상 생성

### 변경하지 않는 것

- `ast_visitor.dart` — 이미 namedSlots 처리 완비
- `rfwtxt_emitter.dart` — 변경 불필요
- `converter.dart` — 변경 불필요
- `rfw_widget_builder.dart` — 변경 불필요

## Part 2: Custom Widget 예제 13개

### 위젯 목록

| # | 위젯 | import | child_type | handlers | 데모 포인트 |
|---|------|--------|------------|----------|------------|
| 1 | `CustomText` | custom.widgets | none | - | 다양한 pass-through (text, fontType, color, maxLines) |
| 2 | `CustomBounceTapper` | custom.widgets | optionalChild | onTap | 기본 핸들러 + child |
| 3 | `NullConditionalWidget` | custom.widgets | optionalChild | - | 위젯-값 param (nullChild) |
| 4 | `CustomButton` | custom.widgets | child | onPressed, onLongPress | 복수 핸들러 |
| 5 | `CustomBadge` | custom.widgets | none | - | Color, 숫자, 문자열 조합 |
| 6 | `CustomProgressBar` | custom.widgets | none | - | value, color, enum(shape) |
| 7 | `CustomColumn` | custom.widgets | childList | - | childList 데모 |
| 8 | `SkeletonContainer` | custom.widgets | optionalChild | - | 불리언(isLoading) |
| 9 | `CompareWidget` | custom.widgets | optionalChild | - | 다중 위젯-값 (trueChild, falseChild) |
| 10 | `PvContainer` | custom.widgets | optionalChild | onPv | 커스텀 이벤트명 |
| 11 | `CustomCard` | custom.widgets | child | onTap | child + handler 조합 |
| 12 | `CustomTile` | custom.widgets | namedSlots | onTap | leading/title/subtitle/trailing 슬롯 (ListTile 패턴 모방) |
| 13 | `CustomAppBar` | custom.widgets | namedSlots | - | title + actions(리스트 슬롯) (AppBar 패턴 모방) |

### 기능 커버리지 매트릭스

| 기능 | 커버하는 위젯 |
|------|-------------|
| child_type: none | 1, 5, 6 |
| child_type: child | 4, 11 |
| child_type: optionalChild | 2, 3, 8, 9, 10 |
| child_type: childList | 7 |
| child_type: namedSlots | 12, 13 |
| handlers (단일) | 2, 11 |
| handlers (복수) | 4 |
| handlers (커스텀 이벤트명) | 10 |
| 위젯-값 param (단일) | 3 |
| 위젯-값 param (다중) | 9 |
| namedSlots (단일 슬롯) | 12, 13 |
| namedSlots (리스트 슬롯) | 13 |
| pass-through params | 1, 5, 6, 8 |

### Example 앱 구조 변경

```
example/
  rfw_gen.yaml                    ← 13개 위젯 등록
  lib/
    custom/
      custom_widgets.dart         ← 13개 @RfwWidget 데모 함수
    main.dart                     ← 'Custom' 카테고리 추가 + LocalWidgetLibrary 등록
```

**main.dart 변경**:
- `_catalogWidgets` 맵에 `'Custom'` 카테고리 추가 (13개 위젯명)
- `initState`에서 `custom.widgets` LocalWidgetLibrary 등록 (stub 위젯)

### rfw_gen.yaml 전체

```yaml
widgets:
  CustomText:
    import: custom.widgets
  CustomBounceTapper:
    import: custom.widgets
    child_type: optionalChild
    handlers: [onTap]
  NullConditionalWidget:
    import: custom.widgets
    child_type: optionalChild
  CustomButton:
    import: custom.widgets
    child_type: child
    handlers: [onPressed, onLongPress]
  CustomBadge:
    import: custom.widgets
  CustomProgressBar:
    import: custom.widgets
  CustomColumn:
    import: custom.widgets
    child_type: childList
  SkeletonContainer:
    import: custom.widgets
    child_type: optionalChild
  CompareWidget:
    import: custom.widgets
    child_type: optionalChild
  PvContainer:
    import: custom.widgets
    child_type: optionalChild
    handlers: [onPv]
  CustomCard:
    import: custom.widgets
    child_type: child
    handlers: [onTap]
  CustomTile:
    import: custom.widgets
    child_type: namedSlots
    named_child_slots:
      leading: false
      title: false
      subtitle: false
      trailing: false
    handlers: [onTap]
  CustomAppBar:
    import: custom.widgets
    child_type: namedSlots
    named_child_slots:
      title: false
      actions: true
```

## 구현 순서

1. namedSlots 확장 (`widget_registry.dart` + 테스트)
2. `rfw_gen.yaml` 업데이트 (13개 위젯)
3. `custom_widgets.dart` 작성 (13개 @RfwWidget 데모)
4. `main.dart` 업데이트 (Custom 카테고리 + LocalWidgetLibrary)
5. build_runner 실행 → rfwtxt/rfw 생성
6. 통합 검증
