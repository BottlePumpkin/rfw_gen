# Spec-Implementation Sync: Gap Fix & Prevention

## Problem

rfw-widgets.md / rfw-types.md에 정의된 스펙과 실제 구현(WidgetRegistry, ExpressionConverter) 사이에 동기화 메커니즘이 없어서, 파라미터나 타입 변환기가 누락되어도 감지되지 않는다.

### 발견된 갭 (7개)

**파라미터 누락 (WidgetRegistry)**
| 위젯 | 빠진 파라미터 | 영향 |
|------|-------------|------|
| Column | `textDirection` (주: 기존 `textBaseline`은 c49eab8에서 추가 완료, 별개 파라미터) | RTL 레이아웃 불가 |
| Row | `textDirection` (주: 기존 `textBaseline`은 c49eab8에서 추가 완료, 별개 파라미터) | RTL 레이아웃 불가 |
| Card | `shape` | ShapeBorder 지정 불가 |

**타입 변환기 누락 (ExpressionConverter)**
| Flutter 타입 | RFW 인코딩 |
|-------------|-----------|
| RoundedRectangleBorder | `{ type: "rounded", side: borderSide, borderRadius: borderRadius }` |
| CircleBorder | `{ type: "circle", side: borderSide }` |
| StadiumBorder | `{ type: "stadium", side: borderSide }` |

**문서 누락 (rfw-widgets.md)**
| 위젯 | 상황 |
|------|------|
| ListTile | 코드에 `visualDensity` 있지만 스펙 문서에 미기재 |

### 근본 원인

1. WidgetRegistry와 ExpressionConverter가 모두 화이트리스트 방식
2. 스펙 문서 ↔ 구현 간 자동 검증 테스트 0개
3. 위젯/타입 추가 시 수동으로 여러 곳을 동시에 수정해야 하지만, 누락을 잡아주는 메커니즘 없음

## Solution: B' (단계적 접근)

### Phase 1: 갭 수정 (즉시)

#### 1-1. WidgetRegistry 파라미터 추가

```dart
// Column에 추가
'textDirection': ParamMapping('textDirection', transformer: 'enum'),

// Row에 추가
'textDirection': ParamMapping('textDirection', transformer: 'enum'),

// Card에 추가
'shape': ParamMapping('shape', transformer: 'shapeBorder'),
```

#### 1-2. ExpressionConverter ShapeBorder 변환기 추가

`_convertShapeBorder()` 디스패처 + 3개 서브 변환기:

```dart
// RoundedRectangleBorder(side: BorderSide(...), borderRadius: BorderRadius.circular(8))
→ IrMapValue { type: "rounded", side: _convertBorderSide(), borderRadius: _convertBorderRadius() }

// CircleBorder(side: BorderSide(...))
→ IrMapValue { type: "circle", side: _convertBorderSide() }

// StadiumBorder(side: BorderSide(...))
→ IrMapValue { type: "stadium", side: _convertBorderSide() }
```

기존 `_convertBorderSide()`와 `_convertBorderRadius()`를 재사용한다.

등록 위치 (두 AST 경로 모두 처리 필수):
- `_convertMethodInvocation()`: `RoundedRectangleBorder(...)` — target == null && methodName 매칭 3건 추가
- `_convertInstanceCreation()`: `const RoundedRectangleBorder(...)` — default constructor switch (line 279)에 3건 추가
- 두 경로 모두에 `RoundedRectangleBorder`, `CircleBorder`, `StadiumBorder` 등록 필요
- `_isKnownClassName()`에 추가 불필요 (named constructor 없음, default constructor만 사용)

#### 1-3. rfw-widgets.md 문서 보완

ListTile에 `visualDensity` 파라미터 추가 기재.

### Phase 2: 동기화 테스트 (B' 방안)

파일: `packages/rfw_gen/test/spec_sync_test.dart`

#### 테스트 1: Registry → Converter 정합성

WidgetRegistry의 모든 위젯의 모든 파라미터에 대해, transformer 타입에 맞는 샘플 Flutter 표현식을 ExpressionConverter로 변환하여 에러 없이 IrValue가 반환되는지 검증한다.

```dart
/// transformer 키 → 대표 Flutter 표현식
const sampleExpressions = {
  'color': 'Color(0xFF000000)',
  'edgeInsets': 'EdgeInsets.all(8.0)',
  'enum': '"start"',
  'alignment': 'Alignment.center',
  'borderRadius': 'BorderRadius.circular(8.0)',
  'textStyle': 'TextStyle(fontSize: 14.0)',
  'boxDecoration': 'BoxDecoration(color: Color(0xFF000000))',
  'shapeBorder': 'RoundedRectangleBorder()',
  'duration': 'Duration(milliseconds: 300)',
  'curve': 'Curves.easeInOut',
  'iconData': 'RfwIcon.home',
  'imageProvider': 'NetworkImage("https://example.com/img.png")',
  'visualDensity': 'VisualDensity.compact',
  'gridDelegate': 'SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)',
  null: '16.0',  // direct pass-through (iconThemeData 등 ParamMapping.direct() 포함)
};
```

검증 로직:
1. registry의 모든 위젯 순회
2. 각 위젯의 params에서 transformer 키 수집
3. transformer 키가 sampleExpressions에 있는지 확인 (없으면 실패)
4. 해당 표현식을 파싱 → ExpressionConverter.convert() 호출
5. UnsupportedExpressionError가 발생하지 않으면 통과

이 테스트가 잡는 버그: "WidgetRegistry에 파라미터를 등록했는데 ExpressionConverter에 변환기가 없음"

#### 테스트 2: 위젯/파라미터 수 regression guard

```dart
test('widget count does not regress', () {
  expect(registry.supportedWidgets.length, greaterThanOrEqualTo(56));
});

test('total param count does not regress', () {
  final totalParams = registry.supportedWidgets.values
      .map((w) => w.params.length + w.handlerParams.length)
      .reduce((a, b) => a + b);
  // 구현 시점에 registry를 순회하여 현재 총 수를 계산 후 하드코딩
  expect(totalParams, greaterThanOrEqualTo(/* 구현 시 산출 */));
});
```

이 테스트가 잡는 버그: "실수로 파라미터나 위젯을 삭제함"

#### 테스트 3: End-to-end rfwtxt 파싱 검증

각 위젯별로 모든 파라미터를 포함한 Flutter 코드 → RfwConverter로 rfwtxt 생성 → `parseLibraryFile()`로 파싱 성공 확인.

구현 참고:
- childType별로 최소 유효 위젯 트리 생성 (child → `SizedBox()`, childList → `[SizedBox()]`, namedSlots → 필수 슬롯만)
- 기존 integration_test.dart의 패턴을 참고하여 확장
- 복잡도가 높으므로, 핵심 위젯(Container, Card, Scaffold 등)부터 점진적으로 추가

이 테스트가 잡는 버그: "IR 변환은 됐는데 rfwtxt emitter 출력이 잘못됨"

### Phase 3: 문서 자동 생성 (향후 C' 발전)

WidgetRegistry에서 rfw-widgets.md를 자동 생성하는 스크립트 추가. Phase 1-2의 동기화 테스트가 CI에서 안정적으로 통과하고, 위젯 추가 워크플로우가 정립된 후 진행.

### 참고: transformer 키와 ExpressionConverter dispatch의 관계

WidgetRegistry의 `ParamMapping.transformer`는 메타데이터 역할이다. ExpressionConverter는 transformer 키로 dispatch하지 않고, AST의 클래스 이름(`RoundedRectangleBorder`, `BorderSide` 등)으로 매칭한다. 따라서 transformer 키 `'shapeBorder'`를 등록하는 것과, ExpressionConverter에서 `RoundedRectangleBorder` 등을 인식하는 것은 별개로 구현해야 한다. 테스트 1은 이 두 계층이 실제로 연결되는지를 검증하는 역할이다.

## 수정 대상 파일

### Phase 1
- `packages/rfw_gen/lib/src/widget_registry.dart` — Column, Row, Card 파라미터 추가
- `packages/rfw_gen/lib/src/expression_converter.dart` — ShapeBorder 변환기 3종 추가
- `packages/rfw_gen/test/expression_converter_test.dart` — ShapeBorder 유닛 테스트
- `packages/rfw_gen/test/widget_registry_test.dart` — 추가된 파라미터 테스트
- `.claude/rules/rfw-widgets.md` — ListTile.visualDensity 추가

### Phase 2
- `packages/rfw_gen/test/spec_sync_test.dart` — 신규 파일, 동기화 테스트 3종

## 테스트 범위별 역할 분담

| 테스트 | 잡는 버그 유형 |
|-------|-------------|
| 기존 유닛 테스트 | 개별 변환 로직 오류 (EdgeInsets.symmetric 결과가 틀림) |
| 신규 테스트 1 (정합성) | Registry에 등록했는데 Converter에 변환기 없음 |
| 신규 테스트 2 (regression) | 실수로 위젯/파라미터 삭제 |
| 신규 테스트 3 (e2e) | 변환은 됐는데 rfwtxt 파싱 실패 |

## 장기 효과

수정 필요 곳이 4곳 → 2곳으로 감소:

```
Before: rfw-widgets.md + WidgetRegistry + ExpressionConverter + 수동 테스트
After:  WidgetRegistry + ExpressionConverter → 테스트가 정합성 자동 검증
```
