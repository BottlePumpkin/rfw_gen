# rfw_gen_mcp — MCP Server Design Spec

**Date**: 2026-03-24
**Status**: Approved

## Problem

rfw_gen의 위젯 레지스트리, 코드 변환, rfwtxt 검증 기능에 접근하려면 Dart 코드를 직접 작성하거나 build_runner를 실행해야 한다. AI 에이전트와 개발자 모두 이 기능을 IDE/CLI에서 즉시 활용할 수 없다.

## Goal

MCP(Model Context Protocol) 서버를 구축하여 rfw_gen의 핵심 기능 4가지를 도구(tool)로 노출한다. Claude Code, Cursor 등 MCP 클라이언트에서 위젯 조회, 코드 변환, rfwtxt 검증을 즉시 수행할 수 있게 한다.

## Target Users

- **AI 에이전트** — rfw_gen 프로젝트 작업 시 위젯 정보 조회, 변환 검증
- **개발자** — IDE에서 MCP 클라이언트를 통해 실시간 위젯 조회 및 변환

## Architecture

### Package Location

모노레포 내 `packages/rfw_gen_mcp/`에 위치. 기존 패키지에 영향 없음.

```
rfw_gen/
├── packages/
│   ├── rfw_gen/           # 런타임 어노테이션, 헬퍼 (unchanged)
│   ├── rfw_gen_builder/   # 변환 엔진, 레지스트리 (unchanged)
│   └── rfw_gen_mcp/       # MCP 서버 (new)
├── example/
└── melos.yaml
```

### Dependencies

```
rfw_gen_mcp
├── rfw_gen_builder  (WidgetRegistry, RfwConverter, ConvertResult)
├── rfw_gen          (RfwGenIssue, RfwGenException — error types)
├── rfw              (parseLibraryFile for validation)
└── mcp_dart         (MCP protocol handling)
```

`rfw_gen`에도 직접 의존한다. `ConvertResult.issues`가 `List<RfwGenIssue>`를 반환하는데, `RfwGenIssue`는 `rfw_gen` 패키지에 정의되어 있다. `rfw_gen_builder`는 `rfw_gen`을 re-export하지 않으므로 별도 의존성이 필요.

### pubspec.yaml

```yaml
name: rfw_gen_mcp
description: MCP server exposing rfw_gen widget registry, code conversion, and rfwtxt validation.
version: 0.1.0
publish_to: none

environment:
  sdk: ^3.6.0

dependencies:
  mcp_dart: ^1.3.0
  rfw: ^1.0.0
  rfw_gen:
    path: ../rfw_gen
  rfw_gen_builder:
    path: ../rfw_gen_builder

dev_dependencies:
  test: ^1.25.0
```

### Technology Choice: mcp_dart

Dart 네이티브 MCP 패키지를 선택한 이유:

1. **네이티브 통합** — rfw_gen_builder의 `WidgetRegistry`, `RfwConverter`를 직접 import. subprocess 호출 불필요
2. **성숙도** — pub.dev 160/160점, 2026-03 최신 업데이트, 전체 MCP 스펙 지원
3. **성능** — in-process 호출로 즉시 응답. Dart VM 부트업 외 추가 지연 없음
4. **프로토콜 위임** — JSON-RPC, capability negotiation, transport를 패키지가 처리

대안으로 고려했으나 선택하지 않은 것:
- **직접 구현** — MCP 프로토콜이 아직 진화 중(2024-10 → 2025-11)이라 유지보수 부담
- **TypeScript SDK** — 공식이지만 rfw_gen이 Dart라 subprocess 호출 필요, 지연 + 복잡도 증가
- **dart_mcp** — 0.5.0 실험 단계, mcp_dart 대비 성숙도 낮음

## File Structure

```
packages/rfw_gen_mcp/
├── bin/
│   └── rfw_gen_mcp.dart              # 진입점 (stdio 서버 시작)
├── lib/
│   ├── rfw_gen_mcp.dart              # 공개 API (runRfwGenMcpServer export)
│   └── src/
│       ├── server.dart               # MCP 서버 설정 + 도구 등록
│       └── tools/
│           ├── list_widgets.dart     # 위젯 목록 조회
│           ├── get_widget_info.dart  # 위젯 상세 정보
│           ├── convert_to_rfwtxt.dart # Dart → rfwtxt 변환
│           └── validate_rfwtxt.dart  # rfwtxt 파싱 검증
├── test/
│   ├── tools/
│   │   ├── list_widgets_test.dart
│   │   ├── get_widget_info_test.dart
│   │   ├── convert_to_rfwtxt_test.dart
│   │   └── validate_rfwtxt_test.dart
│   └── server_test.dart              # MCP 프로토콜 통합 테스트
└── pubspec.yaml
```

## Server Initialization

```dart
// bin/rfw_gen_mcp.dart
import 'package:rfw_gen_mcp/rfw_gen_mcp.dart';

void main() => runRfwGenMcpServer();
```

```dart
// lib/src/server.dart
import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

Future<void> runRfwGenMcpServer() async {
  final registry = WidgetRegistry.core();
  final converter = RfwConverter(registry: registry);

  final server = McpServer(
    Implementation(name: 'rfw_gen', version: '0.1.0'),
  );

  registerListWidgetsTool(server, registry);
  registerGetWidgetInfoTool(server, registry);
  registerConvertToRfwtxtTool(server, converter);
  registerValidateRfwtxtTool(server);

  final transport = StdioServerTransport();
  await server.connect(transport);
}
```

`mcp_dart` API:
- `McpServer(Implementation(...))` — Implementation 객체로 서버 생성
- `server.registerTool(name, callback:, inputSchema:)` — 도구 등록 (addTool 아님)
- `StdioServerTransport()` — stdio transport (StdioTransport 아님)
- `server.connect(transport)` — 서버 시작 (start 아님)

각 도구 파일은 `void registerXxxTool(McpServer server, ...)` 함수를 export.

`WidgetRegistry.core()`와 `RfwConverter`는 서버 시작 시 한 번 생성, 모든 도구 호출에서 재사용.

## Tool Specifications

### Tool 1: `list_widgets`

위젯 목록 조회. 선택적 카테고리 필터링.

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "category": {
      "type": "string",
      "description": "Filter by import category (e.g., 'core.widgets', 'material'). Omit for all.",
      "enum": ["core.widgets", "material"]
    }
  }
}
```

**Output (success):**
```json
{
  "widgets": [
    {
      "name": "Container",
      "rfwName": "Container",
      "import": "core.widgets",
      "childType": "optionalChild"
    },
    {
      "name": "AppBar",
      "rfwName": "AppBar",
      "import": "material",
      "childType": "namedSlots"
    }
  ],
  "count": 50
}
```

**Implementation:** `registry.supportedWidgets` (Map<String, WidgetMapping>)를 순회, category가 지정되면 `mapping.import`로 필터링.

### Tool 2: `get_widget_info`

특정 위젯의 상세 정보.

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "widget": {
      "type": "string",
      "description": "Widget name (e.g., 'Scaffold', 'Container')"
    }
  },
  "required": ["widget"]
}
```

**Output (success):**
```json
{
  "name": "Scaffold",
  "rfwName": "Scaffold",
  "import": "material",
  "childType": "namedSlots",
  "params": {
    "backgroundColor": { "transformer": "color" },
    "resizeToAvoidBottomInset": { "transformer": null }
  },
  "handlerParams": [],
  "namedChildSlots": {
    "appBar": false,
    "body": false,
    "floatingActionButton": false,
    "drawer": false,
    "bottomNavigationBar": false
  }
}
```

**Output (not found):**
```json
{
  "error": "Widget 'FooBar' not found in registry",
  "availableWidgets": ["Container", "Column", "Row", "..."]
}
```

MCP `isError: true`로 반환.

**Implementation:** `registry.supportedWidgets[name]` 조회, null이면 에러 응답. `registry.isSupported(name)`으로 존재 확인도 가능.

### Tool 3: `convert_to_rfwtxt`

Flutter Dart 소스 코드를 rfwtxt로 변환.

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "source": {
      "type": "string",
      "description": "Dart source code with @RfwWidget annotation"
    }
  },
  "required": ["source"]
}
```

**Output (success):**
```json
{
  "success": true,
  "rfwtxt": "widget myWidget = Container(\n  color: 0xFFFF0000,\n);",
  "warnings": []
}
```

**Output (failure):**
```json
{
  "success": false,
  "errors": [
    {
      "message": "Unsupported widget: CustomPainter",
      "line": 3,
      "suggestion": "Use a supported widget from the registry. Run list_widgets to see available widgets."
    }
  ]
}
```

비즈니스 로직 실패이므로 MCP `isError: false`, 응답 내 `success: false`로 구분.

**Implementation:** `converter.convertFromSource(source)` 호출. 반환값은 `ConvertResult` 객체.
- `result.hasErrors`가 true이면 `success: false`, `result.issues`에서 fatal 이슈를 errors로 매핑
- `result.hasWarnings`이면 non-fatal 이슈를 warnings로 매핑 (`result.issues.where((i) => !i.isFatal)`)
- 각 `RfwGenIssue`는 `message`, `line` (nullable), `suggestion` (nullable) 필드를 가짐
- `StateError`를 catch하여 "no @RfwWidget function found" 에러 처리
- `RfwGenException`은 thrown되지 않음 — 이슈는 `ConvertResult.issues`에 수집됨

### Tool 4: `validate_rfwtxt`

rfwtxt 문자열의 문법 유효성 검사.

**Input Schema:**
```json
{
  "type": "object",
  "properties": {
    "rfwtxt": {
      "type": "string",
      "description": "rfwtxt source to validate"
    }
  },
  "required": ["rfwtxt"]
}
```

**Output (valid):**
```json
{
  "valid": true,
  "widgetCount": 3,
  "imports": ["core.widgets", "material"]
}
```

**Output (invalid):**
```json
{
  "valid": false,
  "error": "Expected ';' at line 2, column 15"
}
```

MCP `isError: false`, 응답 내 `valid: false`로 구분.

**Implementation:** `parseLibraryFile(rfwtxt)` 호출 (`package:rfw/formats.dart`). 반환값은 `RemoteWidgetLibrary` 객체.
- `library.widgets`의 length로 widgetCount 계산
- `library.imports`에서 import 목록 추출 (각 `LibraryName`을 dot-joined 문자열로 변환)
- `FormatException`을 catch하여 파싱 에러 메시지 반환
- 빈 문자열 입력 시 별도 에러 처리

## Error Handling Model

| 상황 | MCP isError | 응답 내 표시 |
|------|------------|-------------|
| 잘못된 인자 (widget 이름 누락 등) | `true` | MCP 표준 에러 |
| 위젯 못 찾음 | `true` | `error` + `availableWidgets` |
| 변환 실패 (지원 안 되는 패턴) | `false` | `success: false` + `errors[]` |
| rfwtxt 파싱 에러 | `false` | `valid: false` + `error` |
| 서버 내부 에러 | `true` | MCP 표준 에러 |

**원칙**: MCP `isError: true`는 도구 자체의 오류(잘못된 인자, 내부 에러). 비즈니스 로직 결과(변환 불가, 파싱 실패)는 정상 응답으로 `success/valid: false` 반환.

## Client Configuration

### Claude Code (`settings.json`)

```json
{
  "mcpServers": {
    "rfw_gen": {
      "command": "dart",
      "args": ["run", "packages/rfw_gen_mcp/bin/rfw_gen_mcp.dart"],
      "cwd": "/path/to/rfw_gen"
    }
  }
}
```

### Cursor (`.cursor/mcp.json`)

```json
{
  "mcpServers": {
    "rfw_gen": {
      "command": "dart",
      "args": ["run", "packages/rfw_gen_mcp/bin/rfw_gen_mcp.dart"],
      "cwd": "/path/to/rfw_gen"
    }
  }
}
```

## Testing Strategy

### Unit Tests (도구별)

각 도구 함수를 직접 호출하여 입출력 검증:

- **list_widgets_test.dart**: 전체 목록 반환, 카테고리 필터링 (core.widgets, material), 빈 카테고리
- **get_widget_info_test.dart**: 존재하는 위젯 (Container, Scaffold 등 각 childType), 미존재 위젯 에러, namedSlots 위젯 상세
- **convert_to_rfwtxt_test.dart**: 단순 위젯 변환 성공, 중첩 위젯 변환, 지원 안 되는 패턴 에러 + suggestion, 어노테이션 없는 소스 에러
- **validate_rfwtxt_test.dart**: 유효한 rfwtxt, 문법 에러, 빈 문자열, 다중 위젯 + import 카운트

### Integration Test (JSON-RPC)

`server_test.dart`에서 stdio를 모킹하여 실제 MCP 프로토콜 메시지 교환 검증:

1. `initialize` → 서버 capabilities 응답 확인
2. `tools/list` → 4개 도구 목록 확인
3. `tools/call` → 각 도구 호출 + 응답 검증

## Version & Scope

### v1 (이번 구현)

- 4개 도구: list_widgets, get_widget_info, convert_to_rfwtxt, validate_rfwtxt
- `WidgetRegistry.core()` 기본 위젯만 지원
- stdio transport
- melos 모노레포 통합

### v2 (향후)

- `rfw_gen.yaml` 커스텀 위젯 지원 (파일 경로를 인자로 받아 registry에 추가)
- 아이콘 조회 도구 (`lookup_icon`)
- 골든 테스트 관리 도구
- MCP resources로 위젯 카탈로그 노출

## Implementation Order

1. 패키지 scaffolding (`pubspec.yaml`, 디렉토리 구조)
2. `server.dart` — MCP 서버 초기화
3. `list_widgets.dart` + 테스트
4. `get_widget_info.dart` + 테스트
5. `convert_to_rfwtxt.dart` + 테스트
6. `validate_rfwtxt.dart` + 테스트
7. `server_test.dart` — 통합 테스트
8. `bin/rfw_gen_mcp.dart` 진입점 + 수동 검증
9. melos.yaml 업데이트 — 현재 `packages: - packages/*` 글로브 사용 중이므로 자동 인식됨. `melos bootstrap` 후 path dependency 해결 확인
10. CI 업데이트 (ci.yml에 rfw_gen_mcp job 추가)
