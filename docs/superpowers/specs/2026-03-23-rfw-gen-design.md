# rfw_gen Design Spec

**Date**: 2026-03-23
**Status**: Draft

## Problem

RFW(Remote Flutter Widgets)는 서버에서 UI를 동적으로 내려줄 수 있는 강력한 패키지지만, 개발자 경험이 열악하다:

- rfwtxt라는 새로운 DSL을 배워야 함 (IDE 지원 없음)
- Flutter Widget 코드를 RFW로 변환하는 production-quality 도구가 없음
- raw hex 값으로 색상/아이콘을 지정해야 함
- 커뮤니티가 2021년부터 요청하고 있지만 공식 지원 없음

관련 GitHub 이슈:
- [#141948](https://github.com/flutter/flutter/issues/141948) — RFW beyond rfwtxt
- [#141666](https://github.com/flutter/flutter/issues/141666) — DX 개선 요청
- [#144841](https://github.com/flutter/flutter/issues/144841) — 역변환 도구 요청
- [#141658](https://github.com/flutter/flutter/issues/141658) — Builder 패턴 미지원

기존 시도(swap, rfw_builder, RemoteFlutterSharp)는 모두 실험적이거나 방치 상태.

## Solution

**rfw_gen** — Flutter Widget 코드를 RFW 형식으로 변환하는 코드 생성기 + MCP 서버.

### 접근 방식: Hybrid (Code Gen + MCP)

- **Code Gen (build_runner)**: `@RfwWidget` 어노테이션으로 Flutter 문법 그대로 작성 → 빌드 타임에 rfwtxt/바이너리 생성
- **MCP 서버**: AI가 범용 Flutter 코드를 RFW로 변환하는 어시스트 + Marionette 연동 프리뷰
- **코어 엔진 분리**: 변환 로직을 독립 패키지로 분리하여 build_runner, MCP 서버 모두에서 재사용

### swap 패키지와의 차이

| | swap | rfw_gen |
|---|---|---|
| 출력 | 바이너리만 | rfwtxt (사람이 읽을 수 있음) + 바이너리 |
| 데이터 바인딩 | 불가능 | `data.user.name` 지원 (v0.2+), `state` 지원 예정 (future) |
| 실행 위치 | 서버 전용 | Flutter 프로젝트 빌드 타임 |
| 위젯 추가 | 클래스 2개씩 수동 구현 | 레지스트리에 매핑 등록 |
| MCP 연동 | 어려움 | 코어 엔진 직접 호출 |

## Architecture

### 모노레포 구조

```
rfw_gen/
├── packages/
│   ├── rfw_gen/                 ← 코어: 어노테이션 + 변환 엔진
│   ├── rfw_gen_builder/         ← build_runner generator
│   └── rfw_gen_mcp/             ← MCP 서버
├── example/
│   ├── lib/                     ← 예제 앱
│   └── widgetbook/              ← 디버깅용 Widgetbook
├── .claude/
│   ├── CLAUDE.md
│   ├── rules/
│   │   ├── rfw-syntax.md        ← rfwtxt 문법 레퍼런스
│   │   ├── rfw-widgets.md       ← 지원 위젯 전체 목록 + 파라미터
│   │   └── rfw-types.md         ← 인자 타입 인코딩
│   ├── agents/
│   │   ├── widget-mapper.md     ← 위젯 매핑 추가 전용 에이전트
│   │   └── test-writer.md       ← 테스트 작성 전용 에이전트
│   └── skills/
│       └── add-widget.md        ← /add-widget 스킬
└── melos.yaml
```

(루트에는 `melos.yaml`만 위치. 각 패키지가 자체 `pubspec.yaml`을 가짐)

### rfw_gen (코어 패키지)

**어노테이션:**

```dart
class RfwWidget {
  final String name;
  const RfwWidget(this.name);
}
```

**`@RfwWidget` 어노테이션은 top-level 함수에 사용한다.** 클래스 메서드나 로컬 함수는 지원하지 않음.

**변환 엔진 — `RfwConverter`:**

```dart
class RfwConverter {
  final WidgetRegistry registry;

  /// Dart 소스 문자열 → rfwtxt 문자열 (MCP, 테스트용)
  String convertFromSource(String dartSource);

  /// 파싱된 AST 노드 → rfwtxt 문자열 (build_runner용)
  String convertFromAst(FunctionDeclaration function);

  /// rfwtxt → rfw 바이너리
  Uint8List toBlob(String rfwtxt);
}
```

`convertFromSource`는 내부적으로 `package:analyzer`로 파싱한 뒤 `convertFromAst`를 호출. MCP 서버와 테스트에서 편의 메서드로 사용.

**위젯 매핑 레지스트리 — `WidgetRegistry`:**

```dart
class WidgetRegistry {
  /// 지원 위젯 목록과 파라미터 매핑 정보
  Map<String, WidgetMapping> get supportedWidgets;

  /// 위젯 지원 여부 확인
  bool isSupported(String widgetName);

  /// 커스텀 위젯 매핑 등록 (확장용)
  void register(String name, WidgetMapping mapping);
}
```

위젯 추가 = 레지스트리에 매핑 하나 등록. MCP의 `list_supported_widgets`도 이 레지스트리를 직접 노출.

### 표현식 변환 규칙

코어 엔진이 Dart 표현식을 rfwtxt로 변환할 때, 다음 범위만 지원한다:

**지원하는 표현식:**
- 리터럴: `'hello'`, `24.0`, `true`, `0xFF000000`
- 리스트/맵 리터럴: `[1, 2, 3]`, `{'key': 'value'}`
- 알려진 타입의 생성자: `Color(0xFF000000)` → `0xFF000000`, `EdgeInsets.all(16)` → `[16.0]`
- enum 값: `MainAxisAlignment.center` → `"center"`
- const 참조: `Colors.red` → `0xFFF44336`

**지원하지 않는 표현식 (빌드 타임 에러):**
- 변수 참조, 함수 호출, 조건식, 산술 연산
- `BuildContext` 사용, `Theme.of(context)`
- Builder 패턴 (`Builder`, `LayoutBuilder`)
- 커스텀 클래스 인스턴스 (WidgetRegistry에 없는 타입)

### 데이터 바인딩 (v0.2+)

RFW의 `data.path` 참조를 Dart에서 표현하기 위해 placeholder 객체를 사용한다:

```dart
// rfw_gen이 제공하는 placeholder
final rfw = RfwData();

@RfwWidget('userCard')
Widget buildUserCard() {
  return Text(rfw.data.user.name);  // → Text(text: data.user.name)
}
```

`RfwData`는 `noSuchMethod`를 오버라이드하여 모든 프로퍼티 접근을 기록. 코어 엔진은 AST에서 `rfw.data.*` 패턴을 감지하면 RFW `DataReference`로 변환. 실제로 실행되지는 않음 (정적 분석만).

**State 관리**: `state.counter`, `set state.x = ...` 등 RFW 상태 기능은 v0.1-v0.5 범위에 포함하지 않음. 데이터 바인딩이 안정화된 이후 future 버전에서 설계 예정.

### 변환 흐름

```
@RfwWidget('greeting')
Widget buildGreeting() {
  return Column(
    children: [
      Text('Hello'),
      Text('World'),
    ],
  );
}
        │  (analyzer AST 파싱)
        ▼
import core.widgets;
widget greeting = Column(
  children: [
    Text(text: "Hello"),
    Text(text: "World"),
  ],
);
        │  (rfw parseLibraryFile)
        ▼
    바이너리 blob (Uint8List)
```

### 에러 처리

빌드 타임에 명확한 에러 + 대안 제안. 에러 분류:

**Fatal (빌드 실패):**
- 지원 안 되는 위젯 사용
- 변환 불가능한 표현식 (변수 참조, 함수 호출 등)
- Builder 패턴, BuildContext 사용

**Warning (빌드 성공, 경고 출력):**
- 지원되지만 무시되는 파라미터
- 비표준 패턴 (동작하지만 의도와 다를 수 있음)

```
[rfw_gen] Error in buildGreeting():
  Line 5: `GestureDetector` is not supported by RFW.
  Supported alternatives: InkWell (via Material widgets)

[rfw_gen] Warning in buildCard():
  Line 8: `Container.clipBehavior` is supported but rarely used in RFW.
```

### rfw_gen_builder (build_runner)

`package:build` 기반 커스텀 `Builder` 구현 (`source_gen`의 `GeneratorForAnnotation`은 AST 접근이 제한적이므로 사용하지 않음). `@RfwWidget` 어노테이션이 달린 top-level 함수를 찾아 코어 엔진의 `RfwConverter.convertFromAst`를 호출.

생성 파일:
- `*.rfwtxt` — 사람이 읽을 수 있는 텍스트
- `*.rfw` — 바이너리 blob

### rfw_gen_mcp (MCP 서버)

| MCP Tool | 역할 |
|----------|------|
| `convert_to_rfw` | Flutter 코드(문자열) → rfwtxt (`RfwConverter.convertFromSource` 사용) |
| `list_supported_widgets` | 지원 위젯 목록 조회 |
| `validate_rfwtxt` | rfwtxt 문법 검증 |
| `preview_widget` | Marionette 연동 — 렌더링 스크린샷 반환 |

**AI 워크플로우:**

```
사용자: "이 Flutter 코드를 RFW로 변환해줘"
    │
    ▼
AI → convert_to_rfw (변환)
   → validate_rfwtxt (검증)
   → preview_widget (Marionette로 렌더링 확인)
   → "변환 완료, 렌더링 결과입니다: [스크린샷]"

   문제가 있으면 → 자동 수정 → 재검증 루프
```

### Widgetbook 연동 (디버깅용)

별도 패키지가 아닌, example 앱 내 디버깅 도구로 활용:

```
example/
└── widgetbook/
    └── lib/main.dart    ← RFW 렌더링 결과를 미리보기
```

위젯 매핑 추가 → build_runner → Widgetbook에서 시각적 확인.

### Marionette MCP 연동

MCP 서버의 `preview_widget` 도구에서 활용:

1. 생성된 RFW를 example 앱에 로드
2. Marionette `hot_reload` 호출
3. `take_screenshots`로 스크린샷 캡처
4. AI에게 이미지 반환

## Testing Strategy

모든 버전에서 3단계 테스트 적용:

### 1. 유닛 테스트 — "변환이 정확한가"

```dart
const input = '''
@RfwWidget('greeting')
Widget buildGreeting() {
  return Text('Hello');
}
''';

const expected = '''
import core.widgets;

widget greeting = Text(
  text: "Hello",
);
''';

test('Text widget converts correctly', () {
  final converter = RfwConverter(registry: WidgetRegistry.core());
  final result = converter.convertFromSource(input);
  expect(result, equals(expected));
});
```

### 2. 통합 테스트 — "생성된 RFW가 파싱되는가"

```dart
test('generated rfwtxt produces valid library blob', () {
  final converter = RfwConverter(registry: WidgetRegistry.core());
  final rfwtxt = converter.convertFromSource(input);
  final library = parseLibraryFile(rfwtxt);
  final blob = encodeLibraryBlob(library);
  final decoded = decodeLibraryBlob(blob);
  expect(decoded, isNotNull);
});
```

### 3. 골든 테스트 — "의도대로 렌더링되는가"

```dart
testWidgets('rendered widget matches golden', (tester) async {
  final blob = generateAndEncode(input);
  await tester.pumpWidget(
    RemoteWidget(
      runtime: runtime,
      data: data,
      widget: FullyQualifiedWidgetName('test', 'greeting'),
    ),
  );
  await expectLater(
    find.byType(RemoteWidget),
    matchesGoldenFile('goldens/greeting.png'),
  );
});
```

### 위젯 추가 사이클

위젯 하나 추가할 때마다 동일한 패턴:

> 매핑 작성 → 유닛 테스트 → 통합 테스트 → 골든 테스트

## Claude 프로젝트 설정

### .claude/CLAUDE.md

프로젝트 규칙, 아키텍처 개요, 참조 문서 링크.

### .claude/rules/

- **rfw-syntax.md**: rfwtxt 문법 레퍼런스 (import, widget 선언, data 참조, switch, state, event handler, for loop 등)
- **rfw-widgets.md**: Core 30+개, Material 20+개 위젯의 파라미터, children 타입, 이벤트 핸들러, 제약사항
- **rfw-types.md**: Color(0xAARRGGBB), EdgeInsets([1-4 doubles]), TextStyle(map), Alignment({x,y}), BoxDecoration, Gradient, Duration, Curve 등 인코딩 규칙

### .claude/agents/

- **widget-mapper.md**: 여러 위젯을 병렬로 매핑 추가하는 에이전트
- **test-writer.md**: 테스트 작성 전용 에이전트

### .claude/skills/

- **add-widget.md**: `/add-widget [WidgetName]` — 매핑 + 유닛/통합/골든 테스트를 한 세트로 추가하는 표준화된 워크플로우

## Roadmap

| 단계 | 산출물 | 위젯 범위 | 테스트 |
|------|--------|-----------|--------|
| **v0.1** | `rfw_gen` + `rfw_gen_builder` | Text, Column, Row, Container, SizedBox | 유닛 + 통합 + 골든 |
| **v0.2** | 위젯 확장 | + Padding, Center, Expanded, Stack, Wrap, Icon | 동일 |
| **v0.3** | `rfw_gen_mcp` | MCP 서버 (convert, validate, list) | + MCP 프로토콜 테스트 |
| **v0.4** | Material 위젯 | Scaffold, AppBar, Card, ElevatedButton, ListTile 등 | 동일 |
| **v0.5** | Marionette 연동 | preview_widget 도구 | + 스크린샷 검증 |

## Dependencies

### 코어 (rfw_gen)
- `package:analyzer` — Dart 소스 → AST 파싱
- `package:rfw` — rfwtxt 파싱 + 바이너리 인코딩

### 빌더 (rfw_gen_builder)
- `package:build` — build_runner 인프라 (커스텀 Builder 구현)

### MCP (rfw_gen_mcp)
- MCP 프로토콜 직접 구현 (stdio JSON-RPC transport)
- `package:marionette_mcp` — Marionette 연동 (v0.5)

### 개발/테스트
- `package:melos` — 모노레포 관리
- `package:widgetbook` — 디버깅용 위젯 카탈로그
- `package:flutter_test` — 골든 테스트

## Decisions

1. **Code Gen (C) over DSL (B)**: Flutter 문법 그대로 쓸 수 있어 학습 곡선 최소화. build_runner 생태계가 Flutter 개발자에게 익숙함.
2. **Hybrid over single approach**: 코어 엔진 분리로 build_runner와 MCP 서버 모두에서 재사용.
3. **rfwtxt 텍스트 출력 우선**: 사람이 읽고 디버깅 가능. 바이너리는 rfw 패키지가 처리.
4. **v0.1부터 골든 테스트**: "파싱 성공"과 "의도대로 렌더링"은 다른 문제. 초기부터 시각적 검증 필요.
5. **Widgetbook은 디버깅 도구**: 별도 패키지가 아닌 example 앱 내 개발 도구로 활용.
6. **Marionette는 MCP preview용**: AI 워크플로우에서 생성→렌더링→검증 루프 구현.
