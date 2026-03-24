# rfw_gen_mcp — MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** rfw_gen의 위젯 레지스트리, 코드 변환, rfwtxt 검증을 MCP 도구 4개로 노출하는 Dart 네이티브 MCP 서버를 구축한다.

**Architecture:** `packages/rfw_gen_mcp/` 패키지에서 `mcp_dart`로 MCP 프로토콜을 처리하고, `rfw_gen_builder`의 `WidgetRegistry`/`RfwConverter`를 직접 import하여 in-process로 호출.

**Tech Stack:** Dart 3, mcp_dart ^1.3.0, rfw_gen_builder (path), rfw (parseLibraryFile)

**Spec:** `docs/superpowers/specs/2026-03-24-rfw-gen-mcp-design.md`

---

## File Map

**Create:**
- `packages/rfw_gen_mcp/pubspec.yaml`
- `packages/rfw_gen_mcp/lib/rfw_gen_mcp.dart` — barrel export
- `packages/rfw_gen_mcp/lib/src/server.dart` — MCP 서버 초기화 + 도구 등록
- `packages/rfw_gen_mcp/lib/src/tools/list_widgets.dart` — list_widgets 도구
- `packages/rfw_gen_mcp/lib/src/tools/get_widget_info.dart` — get_widget_info 도구
- `packages/rfw_gen_mcp/lib/src/tools/convert_to_rfwtxt.dart` — convert_to_rfwtxt 도구
- `packages/rfw_gen_mcp/lib/src/tools/validate_rfwtxt.dart` — validate_rfwtxt 도구
- `packages/rfw_gen_mcp/test/tools/list_widgets_test.dart`
- `packages/rfw_gen_mcp/test/tools/get_widget_info_test.dart`
- `packages/rfw_gen_mcp/test/tools/convert_to_rfwtxt_test.dart`
- `packages/rfw_gen_mcp/test/tools/validate_rfwtxt_test.dart`
- `packages/rfw_gen_mcp/test/server_test.dart` — 통합 테스트
- `packages/rfw_gen_mcp/bin/rfw_gen_mcp.dart` — 진입점

**Modify:**
- `.github/workflows/ci.yml` — rfw_gen_mcp job 추가

---

### Task 1: 패키지 scaffolding + mcp_dart 검증

**Files:**
- Create: `packages/rfw_gen_mcp/pubspec.yaml`
- Create: `packages/rfw_gen_mcp/lib/rfw_gen_mcp.dart`
- Create: `packages/rfw_gen_mcp/lib/src/server.dart`
- Create: `packages/rfw_gen_mcp/bin/rfw_gen_mcp.dart`

- [ ] **Step 1: pubspec.yaml 작성**

```yaml
# packages/rfw_gen_mcp/pubspec.yaml
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

- [ ] **Step 2: barrel export 작성**

```dart
// packages/rfw_gen_mcp/lib/rfw_gen_mcp.dart
export 'src/server.dart' show runRfwGenMcpServer;
```

- [ ] **Step 3: server.dart 작성 (도구 등록 없이 빈 서버)**

```dart
// packages/rfw_gen_mcp/lib/src/server.dart
import 'package:mcp_dart/mcp_dart.dart';

Future<void> runRfwGenMcpServer() async {
  final server = McpServer(
    Implementation(name: 'rfw_gen', version: '0.1.0'),
  );

  final transport = StdioServerTransport();
  await server.connect(transport);
}
```

참고: `mcp_dart` API가 스펙과 다를 수 있음. `dart pub get` 후 실제 API를 확인하고, 생성자/메서드 이름이 다르면 맞춰서 수정. `mcp_dart` 패키지의 example 디렉토리나 API docs를 참조.

- [ ] **Step 4: 진입점 작성**

```dart
// packages/rfw_gen_mcp/bin/rfw_gen_mcp.dart
import 'package:rfw_gen_mcp/rfw_gen_mcp.dart';

void main() => runRfwGenMcpServer();
```

- [ ] **Step 5: melos bootstrap + dart pub get 확인**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
melos bootstrap
```

Expected: 모든 패키지 의존성 해결 성공. `packages/rfw_gen_mcp/.dart_tool/` 생성.

- [ ] **Step 6: dart analyze 통과 확인**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp/packages/rfw_gen_mcp
dart analyze
```

Expected: No issues found. mcp_dart API가 맞지 않으면 이 단계에서 에러 발생 → 실제 API에 맞게 수정.

- [ ] **Step 7: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/
git commit -m "feat(rfw_gen_mcp): scaffold MCP server package with mcp_dart"
```

---

### Task 2: list_widgets 도구

**Files:**
- Create: `packages/rfw_gen_mcp/lib/src/tools/list_widgets.dart`
- Create: `packages/rfw_gen_mcp/test/tools/list_widgets_test.dart`
- Modify: `packages/rfw_gen_mcp/lib/src/server.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// packages/rfw_gen_mcp/test/tools/list_widgets_test.dart
import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:test/test.dart';

import 'package:rfw_gen_mcp/src/tools/list_widgets.dart';

void main() {
  late WidgetRegistry registry;

  setUp(() {
    registry = WidgetRegistry.core();
  });

  group('handleListWidgets', () {
    test('returns all widgets when no category filter', () {
      final result = handleListWidgets(registry, {});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['count'], greaterThan(40));
      expect(json['widgets'], isList);

      final first = (json['widgets'] as List).first as Map<String, dynamic>;
      expect(first, contains('name'));
      expect(first, contains('rfwName'));
      expect(first, contains('import'));
      expect(first, contains('childType'));
    });

    test('filters by core.widgets category', () {
      final result = handleListWidgets(registry, {'category': 'core.widgets'});
      final json = jsonDecode(result) as Map<String, dynamic>;

      final widgets = json['widgets'] as List;
      for (final w in widgets) {
        expect((w as Map)['import'], equals('core.widgets'));
      }
      expect(json['count'], equals(widgets.length));
    });

    test('filters by material category', () {
      final result = handleListWidgets(registry, {'category': 'material'});
      final json = jsonDecode(result) as Map<String, dynamic>;

      final widgets = json['widgets'] as List;
      for (final w in widgets) {
        expect((w as Map)['import'], equals('material'));
      }
    });

    test('returns empty list for unknown category', () {
      final result = handleListWidgets(registry, {'category': 'nonexistent'});
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['count'], equals(0));
      expect(json['widgets'], isEmpty);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp/packages/rfw_gen_mcp
dart test test/tools/list_widgets_test.dart
```

Expected: FAIL — `handleListWidgets` 함수 없음.

- [ ] **Step 3: list_widgets.dart 구현**

```dart
// packages/rfw_gen_mcp/lib/src/tools/list_widgets.dart
import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

void registerListWidgetsTool(McpServer server, WidgetRegistry registry) {
  server.registerTool(
    'list_widgets',
    description: 'List all supported RFW widgets with optional category filter.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'category': {
          'type': 'string',
          'description':
              "Filter by import category (e.g., 'core.widgets', 'material'). Omit for all.",
        },
      },
    },
    callback: (CallToolRequest request) async {
      final args = request.params.arguments ?? {};
      final result = handleListWidgets(registry, args);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

/// 테스트 가능한 순수 함수. registry에서 위젯 목록을 JSON 문자열로 반환.
String handleListWidgets(WidgetRegistry registry, Map<String, dynamic> args) {
  final category = args['category'] as String?;

  final entries = registry.supportedWidgets.entries.where((e) {
    if (category == null) return true;
    return e.value.import == category;
  });

  final widgets = entries.map((e) {
    return {
      'name': e.key,
      'rfwName': e.value.rfwName,
      'import': e.value.import,
      'childType': e.value.childType.name,
    };
  }).toList();

  return jsonEncode({'widgets': widgets, 'count': widgets.length});
}
```

참고: `mcp_dart`의 `server.registerTool` 시그니처가 다를 수 있음. 실제 패키지 API에 맞게 `callback`, `inputSchema`, `description` 파라미터 이름을 조정. `CallToolRequest`, `CallToolResult`, `TextContent` 클래스명도 확인.

- [ ] **Step 4: server.dart에 도구 등록 추가**

`server.dart`의 `runRfwGenMcpServer`에 추가:

```dart
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'tools/list_widgets.dart';

Future<void> runRfwGenMcpServer() async {
  final registry = WidgetRegistry.core();

  final server = McpServer(
    Implementation(name: 'rfw_gen', version: '0.1.0'),
  );

  registerListWidgetsTool(server, registry);

  final transport = StdioServerTransport();
  await server.connect(transport);
}
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
dart test test/tools/list_widgets_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/lib/src/tools/list_widgets.dart packages/rfw_gen_mcp/test/tools/list_widgets_test.dart packages/rfw_gen_mcp/lib/src/server.dart
git commit -m "feat(rfw_gen_mcp): add list_widgets tool with category filtering"
```

---

### Task 3: get_widget_info 도구

**Files:**
- Create: `packages/rfw_gen_mcp/lib/src/tools/get_widget_info.dart`
- Create: `packages/rfw_gen_mcp/test/tools/get_widget_info_test.dart`
- Modify: `packages/rfw_gen_mcp/lib/src/server.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// packages/rfw_gen_mcp/test/tools/get_widget_info_test.dart
import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:test/test.dart';

import 'package:rfw_gen_mcp/src/tools/get_widget_info.dart';

void main() {
  late WidgetRegistry registry;

  setUp(() {
    registry = WidgetRegistry.core();
  });

  group('handleGetWidgetInfo', () {
    test('returns Container info (optionalChild)', () {
      final result = handleGetWidgetInfo(registry, 'Container');
      expect(result.isError, isFalse);

      final json = jsonDecode(result.text) as Map<String, dynamic>;
      expect(json['name'], equals('Container'));
      expect(json['childType'], equals('optionalChild'));
      expect(json['import'], equals('core.widgets'));
      expect(json['params'], isA<Map>());
      expect(json['params'], contains('color'));
    });

    test('returns Scaffold info (namedSlots)', () {
      final result = handleGetWidgetInfo(registry, 'Scaffold');
      final json = jsonDecode(result.text) as Map<String, dynamic>;

      expect(json['childType'], equals('namedSlots'));
      expect(json['namedChildSlots'], contains('appBar'));
      expect(json['namedChildSlots'], contains('body'));
    });

    test('returns Text info (positionalParam)', () {
      final result = handleGetWidgetInfo(registry, 'Text');
      final json = jsonDecode(result.text) as Map<String, dynamic>;

      expect(json['positionalParam'], equals('text'));
    });

    test('returns error for unknown widget', () {
      final result = handleGetWidgetInfo(registry, 'FooBar');
      expect(result.isError, isTrue);

      final json = jsonDecode(result.text) as Map<String, dynamic>;
      expect(json['error'], contains('FooBar'));
      expect(json['availableWidgets'], isList);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
dart test test/tools/get_widget_info_test.dart
```

Expected: FAIL.

- [ ] **Step 3: get_widget_info.dart 구현**

```dart
// packages/rfw_gen_mcp/lib/src/tools/get_widget_info.dart
import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

void registerGetWidgetInfoTool(McpServer server, WidgetRegistry registry) {
  server.registerTool(
    'get_widget_info',
    description: 'Get detailed info for a specific RFW widget (params, children, handlers).',
    inputSchema: {
      'type': 'object',
      'properties': {
        'widget': {
          'type': 'string',
          'description': "Widget name (e.g., 'Scaffold', 'Container')",
        },
      },
      'required': ['widget'],
    },
    callback: (CallToolRequest request) async {
      final name = request.params.arguments?['widget'] as String? ?? '';
      final result = handleGetWidgetInfo(registry, name);
      return CallToolResult(
        content: [TextContent(text: result.text)],
        isError: result.isError,
      );
    },
  );
}

class ToolResult {
  final String text;
  final bool isError;
  ToolResult(this.text, {this.isError = false});
}

ToolResult handleGetWidgetInfo(WidgetRegistry registry, String name) {
  final mapping = registry.supportedWidgets[name];
  if (mapping == null) {
    final available = registry.supportedWidgets.keys.toList()..sort();
    return ToolResult(
      jsonEncode({
        'error': "Widget '$name' not found in registry",
        'availableWidgets': available,
      }),
      isError: true,
    );
  }

  final params = <String, Map<String, dynamic>>{};
  for (final entry in mapping.params.entries) {
    params[entry.key] = {
      'rfwName': entry.value.rfwName,
      'transformer': entry.value.transformer,
    };
  }

  final info = <String, dynamic>{
    'name': name,
    'rfwName': mapping.rfwName,
    'import': mapping.import,
    'childType': mapping.childType.name,
    'params': params,
    'handlerParams': mapping.handlerParams.toList(),
  };

  if (mapping.positionalParam != null) {
    info['positionalParam'] = mapping.positionalParam;
  }
  if (mapping.namedChildSlots.isNotEmpty) {
    info['namedChildSlots'] = mapping.namedChildSlots;
  }

  return ToolResult(jsonEncode(info));
}
```

- [ ] **Step 4: server.dart에 등록 추가**

```dart
import 'tools/get_widget_info.dart';
// runRfwGenMcpServer 내:
registerGetWidgetInfoTool(server, registry);
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
dart test test/tools/get_widget_info_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/lib/src/tools/get_widget_info.dart packages/rfw_gen_mcp/test/tools/get_widget_info_test.dart packages/rfw_gen_mcp/lib/src/server.dart
git commit -m "feat(rfw_gen_mcp): add get_widget_info tool with widget detail lookup"
```

---

### Task 4: convert_to_rfwtxt 도구

**Files:**
- Create: `packages/rfw_gen_mcp/lib/src/tools/convert_to_rfwtxt.dart`
- Create: `packages/rfw_gen_mcp/test/tools/convert_to_rfwtxt_test.dart`
- Modify: `packages/rfw_gen_mcp/lib/src/server.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// packages/rfw_gen_mcp/test/tools/convert_to_rfwtxt_test.dart
import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:test/test.dart';

import 'package:rfw_gen_mcp/src/tools/convert_to_rfwtxt.dart';

void main() {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  group('handleConvertToRfwtxt', () {
    test('converts simple widget successfully', () {
      const source = """
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('myWidget')
Widget myWidget() => Container(color: const Color(0xFFFF0000));
""";
      final result = handleConvertToRfwtxt(converter, source);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isTrue);
      expect(json['rfwtxt'], contains('myWidget'));
      expect(json['rfwtxt'], contains('Container'));
    });

    test('returns errors for unsupported widget', () {
      const source = """
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('bad')
Widget bad() => const CustomPaint();
""";
      final result = handleConvertToRfwtxt(converter, source);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['errors'], isList);
      expect((json['errors'] as List).first['message'], isNotEmpty);
    });

    test('returns error for missing function declaration', () {
      const source = 'class Foo {}';
      final result = handleConvertToRfwtxt(converter, source);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['success'], isFalse);
      expect(json['errors'], isList);
    });

    test('includes warnings for non-fatal issues', () {
      // 구체적 warning 케이스는 converter 구현에 따라 다름.
      // 기본적으로 warnings 필드가 항상 존재하는지 확인.
      const source = """
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('simple')
Widget simple() => const SizedBox(width: 100, height: 100);
""";
      final result = handleConvertToRfwtxt(converter, source);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json, contains('warnings'));
      expect(json['warnings'], isList);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
dart test test/tools/convert_to_rfwtxt_test.dart
```

Expected: FAIL.

- [ ] **Step 3: convert_to_rfwtxt.dart 구현**

```dart
// packages/rfw_gen_mcp/lib/src/tools/convert_to_rfwtxt.dart
import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';

void registerConvertToRfwtxtTool(McpServer server, RfwConverter converter) {
  server.registerTool(
    'convert_to_rfwtxt',
    description: 'Convert Flutter Dart source code with @RfwWidget annotation to rfwtxt format.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'source': {
          'type': 'string',
          'description': 'Dart source code with @RfwWidget annotation',
        },
      },
      'required': ['source'],
    },
    callback: (CallToolRequest request) async {
      final source = request.params.arguments?['source'] as String? ?? '';
      final result = handleConvertToRfwtxt(converter, source);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

String handleConvertToRfwtxt(RfwConverter converter, String source) {
  try {
    final result = converter.convertFromSource(source);

    if (result.hasErrors) {
      final errors = result.issues
          .where((i) => i.isFatal)
          .map((i) => {
                'message': i.message,
                'line': i.line,
                'column': i.column,
                'suggestion': i.suggestion,
              })
          .toList();
      final warnings = result.issues
          .where((i) => !i.isFatal)
          .map((i) => {
                'message': i.message,
                'line': i.line,
                'suggestion': i.suggestion,
              })
          .toList();
      return jsonEncode({
        'success': false,
        'errors': errors,
        'warnings': warnings,
      });
    }

    final warnings = result.issues
        .where((i) => !i.isFatal)
        .map((i) => {
              'message': i.message,
              'line': i.line,
              'suggestion': i.suggestion,
            })
        .toList();

    return jsonEncode({
      'success': true,
      'rfwtxt': result.rfwtxt,
      'warnings': warnings,
    });
  } on StateError catch (e) {
    return jsonEncode({
      'success': false,
      'errors': [
        {'message': e.message, 'line': null, 'suggestion': 'Ensure the source contains a top-level function with @RfwWidget annotation.'}
      ],
      'warnings': [],
    });
  } catch (e) {
    return jsonEncode({
      'success': false,
      'errors': [
        {'message': e.toString(), 'line': null, 'suggestion': null}
      ],
      'warnings': [],
    });
  }
}
```

- [ ] **Step 4: server.dart에 등록 추가**

```dart
import 'tools/convert_to_rfwtxt.dart';
// runRfwGenMcpServer 내:
final converter = RfwConverter(registry: registry);
registerConvertToRfwtxtTool(server, converter);
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
dart test test/tools/convert_to_rfwtxt_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/lib/src/tools/convert_to_rfwtxt.dart packages/rfw_gen_mcp/test/tools/convert_to_rfwtxt_test.dart packages/rfw_gen_mcp/lib/src/server.dart
git commit -m "feat(rfw_gen_mcp): add convert_to_rfwtxt tool with error/warning reporting"
```

---

### Task 5: validate_rfwtxt 도구

**Files:**
- Create: `packages/rfw_gen_mcp/lib/src/tools/validate_rfwtxt.dart`
- Create: `packages/rfw_gen_mcp/test/tools/validate_rfwtxt_test.dart`
- Modify: `packages/rfw_gen_mcp/lib/src/server.dart`

- [ ] **Step 1: 테스트 작성**

```dart
// packages/rfw_gen_mcp/test/tools/validate_rfwtxt_test.dart
import 'dart:convert';

import 'package:test/test.dart';

import 'package:rfw_gen_mcp/src/tools/validate_rfwtxt.dart';

void main() {
  group('handleValidateRfwtxt', () {
    test('validates correct rfwtxt', () {
      const rfwtxt = '''
import core.widgets;
widget foo = Container(
  color: 0xFF000000,
);
''';
      final result = handleValidateRfwtxt(rfwtxt);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['valid'], isTrue);
      expect(json['widgetCount'], equals(1));
      expect(json['imports'], contains('core.widgets'));
    });

    test('validates rfwtxt with multiple widgets', () {
      const rfwtxt = '''
import core.widgets;
import material;
widget foo = Container();
widget bar = Text(text: "hi");
''';
      final result = handleValidateRfwtxt(rfwtxt);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['valid'], isTrue);
      expect(json['widgetCount'], equals(2));
      expect(json['imports'], containsAll(['core.widgets', 'material']));
    });

    test('returns error for invalid rfwtxt', () {
      const rfwtxt = 'widget foo = Container(';
      final result = handleValidateRfwtxt(rfwtxt);
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['valid'], isFalse);
      expect(json['error'], isNotEmpty);
    });

    test('returns error for empty string', () {
      final result = handleValidateRfwtxt('');
      final json = jsonDecode(result) as Map<String, dynamic>;

      expect(json['valid'], isFalse);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

```bash
dart test test/tools/validate_rfwtxt_test.dart
```

Expected: FAIL.

- [ ] **Step 3: validate_rfwtxt.dart 구현**

```dart
// packages/rfw_gen_mcp/lib/src/tools/validate_rfwtxt.dart
import 'dart:convert';

import 'package:mcp_dart/mcp_dart.dart';
import 'package:rfw/formats.dart';

void registerValidateRfwtxtTool(McpServer server) {
  server.registerTool(
    'validate_rfwtxt',
    description: 'Validate rfwtxt syntax and report errors.',
    inputSchema: {
      'type': 'object',
      'properties': {
        'rfwtxt': {
          'type': 'string',
          'description': 'rfwtxt source to validate',
        },
      },
      'required': ['rfwtxt'],
    },
    callback: (CallToolRequest request) async {
      final rfwtxt = request.params.arguments?['rfwtxt'] as String? ?? '';
      final result = handleValidateRfwtxt(rfwtxt);
      return CallToolResult(content: [TextContent(text: result)]);
    },
  );
}

String handleValidateRfwtxt(String rfwtxt) {
  if (rfwtxt.trim().isEmpty) {
    return jsonEncode({
      'valid': false,
      'error': 'Empty rfwtxt input',
    });
  }

  try {
    final library = parseLibraryFile(rfwtxt);

    final imports = library.imports
        .map((imp) => imp.name.parts.join('.'))
        .toList();

    return jsonEncode({
      'valid': true,
      'widgetCount': library.widgets.length,
      'imports': imports,
    });
  } on FormatException catch (e) {
    return jsonEncode({
      'valid': false,
      'error': e.message,
    });
  } catch (e) {
    return jsonEncode({
      'valid': false,
      'error': e.toString(),
    });
  }
}
```

참고: `RemoteWidgetLibrary`의 `imports`는 `List<Import>`. 각 `Import`에는 `.name` (LibraryName)이 있고, `LibraryName.parts`는 `List<String>`. 즉 `imp.name.parts.join('.')`으로 접근.

- [ ] **Step 4: server.dart에 등록 추가**

```dart
import 'tools/validate_rfwtxt.dart';
// runRfwGenMcpServer 내:
registerValidateRfwtxtTool(server);
```

- [ ] **Step 5: 테스트 통과 확인**

```bash
dart test test/tools/validate_rfwtxt_test.dart
```

Expected: All tests passed.

- [ ] **Step 6: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/lib/src/tools/validate_rfwtxt.dart packages/rfw_gen_mcp/test/tools/validate_rfwtxt_test.dart packages/rfw_gen_mcp/lib/src/server.dart
git commit -m "feat(rfw_gen_mcp): add validate_rfwtxt tool with parse validation"
```

---

### Task 6: 통합 테스트 + 전체 검증

**Files:**
- Create: `packages/rfw_gen_mcp/test/server_test.dart`

- [ ] **Step 1: 전체 단위 테스트 실행**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp/packages/rfw_gen_mcp
dart test
```

Expected: 도구별 테스트 전부 통과.

- [ ] **Step 2: dart analyze 통과 확인**

```bash
dart analyze
```

Expected: No issues found.

- [ ] **Step 3: server_test.dart 작성 (선택)**

MCP 프로토콜 통합 테스트는 `mcp_dart`의 테스트 유틸리티에 따라 구현. `mcp_dart`가 in-memory transport를 제공하면 사용, 아니면 `Process.start`로 실제 서버를 실행하여 JSON-RPC 메시지 교환 테스트.

```dart
// packages/rfw_gen_mcp/test/server_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

void main() {
  group('MCP Server Integration', () {
    test('responds to initialize and tools/list', () async {
      final process = await Process.start(
        'dart',
        ['run', 'bin/rfw_gen_mcp.dart'],
        workingDirectory: '.',
      );

      // Send initialize
      final initRequest = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {
          'protocolVersion': '2024-11-05',
          'capabilities': {},
          'clientInfo': {'name': 'test', 'version': '1.0.0'},
        },
      });
      process.stdin.writeln(initRequest);

      // Read response
      final response = await process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      final json = jsonDecode(response) as Map<String, dynamic>;
      expect(json['result'], isNotNull);

      process.kill();
    });
  });
}
```

참고: MCP 프로토콜의 정확한 메시지 형식은 `mcp_dart` 패키지 문서 참조. Content-Length 헤더가 필요할 수 있음.

- [ ] **Step 4: 수동 검증 — echo 테스트**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp/packages/rfw_gen_mcp
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | dart run bin/rfw_gen_mcp.dart
```

Expected: JSON-RPC 응답 출력. 응답 형식 확인.

- [ ] **Step 5: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add packages/rfw_gen_mcp/test/server_test.dart
git commit -m "test(rfw_gen_mcp): add integration test for MCP server protocol"
```

---

### Task 7: CI 업데이트

**Files:**
- Modify: `.github/workflows/ci.yml`

- [ ] **Step 1: ci.yml에 rfw_gen_mcp job 추가**

기존 `analyze-and-test` job의 steps에 추가:

```yaml
      - name: Analyze rfw_gen_mcp
        run: dart analyze packages/rfw_gen_mcp
      - name: Format rfw_gen_mcp
        run: dart format --set-exit-if-changed packages/rfw_gen_mcp
      - name: Test rfw_gen_mcp
        working-directory: packages/rfw_gen_mcp
        run: dart test
```

- [ ] **Step 2: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen_mcp
git add .github/workflows/ci.yml
git commit -m "ci: add rfw_gen_mcp to CI pipeline"
```

---

## 실행 순서 요약

| Task | 내용 | 예상 테스트 수 |
|------|------|-------------|
| 1 | 패키지 scaffolding + mcp_dart 검증 | — |
| 2 | list_widgets 도구 + 테스트 | 4 |
| 3 | get_widget_info 도구 + 테스트 | 4 |
| 4 | convert_to_rfwtxt 도구 + 테스트 | 4 |
| 5 | validate_rfwtxt 도구 + 테스트 | 4 |
| 6 | 통합 테스트 + 전체 검증 | 1+ |
| 7 | CI 업데이트 | — |

**총 테스트**: 16+ (도구별 단위 16 + 통합 1+)
