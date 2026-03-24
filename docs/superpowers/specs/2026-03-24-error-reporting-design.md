# Error Reporting Improvement Design Spec

## Problem

rfw_gen의 에러 보고가 불충분하여 사용자가 빌드 실패 원인을 파악하기 어렵다.

### 현재 문제점

1. **에러 미노출**: `ast_visitor.dart`에서 파라미터 변환 실패 시 `developer.log`를 사용하는데, 이는 build_runner 빌드 로그에 노출되지 않음. 사용자는 파라미터가 왜 빠졌는지 전혀 모름.
2. **에러 구조 미활용**: `RfwGenIssue`/`RfwGenException`이 정의되어 있으나 실제 변환 파이프라인에서 사용되지 않음.
3. **suggestion 미활용**: `RfwGenIssue.suggestion` 필드가 있으나 값을 채우는 곳이 없음.
4. **소스 위치 부재**: 에러 메시지에 line:column 정보가 없어 문제 코드를 찾기 어려움.
5. **검증 단계 부재**: 생성된 rfwtxt의 유효성을 명시적으로 검증하지 않음.

## Solution

### 접근법: IssueCollector + offset→line:column 변환 + rfwtxt 검증

변환 과정에서 에러를 throw 대신 `IssueCollector`에 축적하고, 빌드 완료 후 한 번에 보고한다. 소스 코드의 offset을 line:column으로 변환하여 정확한 위치를 제공하고, 생성된 rfwtxt에 대해 `parseLibraryFile()` 검증 단계를 추가한다.

### 빌드 출력 예시

```
[rfw_gen] Warning (line 12, col 8): ElevatedButton의 "onTap" 파라미터를 변환할 수 없습니다
  Suggestion: 삼항연산자는 지원되지 않습니다. RfwSwitch를 사용하세요.

[rfw_gen] Warning (line 25, col 15): Text의 "style" 파라미터를 변환할 수 없습니다
  Suggestion: TextStyle() const 생성자를 직접 사용하세요.

[rfw_gen] Error: CustomButton은 등록되지 않은 위젯입니다
  Suggestion: rfw_gen.yaml에 위젯을 등록하세요.

[rfw_gen] Generated myWidget.rfwtxt (2 warnings)
```

## Architecture

### 컴포넌트

#### 1. `IssueCollector` (신규 — `rfw_gen_builder`)

```dart
class IssueCollector {
  final String source;
  final List<RfwGenIssue> issues = [];

  IssueCollector(this.source);

  void warning(String message, {int? offset, String? suggestion});
  void fatal(String message, {int? offset, String? suggestion});

  bool get hasFatal => issues.any((i) => i.isFatal);
  bool get hasIssues => issues.isNotEmpty;

  ({int line, int column})? _offsetToLineColumn(int offset);
}
```

- `source` 문자열을 보관하여 offset → line:column 변환을 내부에서 처리
- `warning()`/`fatal()` 호출 시 `RfwGenIssue`를 생성하여 `issues`에 축적
- `RfwGenIssue`의 기존 `line` 필드 사용 + 새로운 `column` 필드 추가

#### 2. `RfwGenIssue` 수정 (`rfw_gen` 패키지)

```dart
class RfwGenIssue {
  final RfwGenSeverity severity;
  final String message;
  final String? suggestion;
  final int? line;
  final int? column;  // 신규
  // ...
}
```

`toString()` 포맷: `[rfw_gen] Error (line 12, col 8): message\n  Suggestion: ...`

#### 3. `RfwConverter` 반환값 변경

현재: `String convertFromAst(FunctionDeclaration function)`
변경: `ConvertResult convertFromAst(FunctionDeclaration function, {String? source})`

```dart
class ConvertResult {
  final String rfwtxt;
  final List<RfwGenIssue> issues;

  bool get hasErrors => issues.any((i) => i.isFatal);
  bool get hasWarnings => issues.any((i) => !i.isFatal);
}
```

`convertFromSource()`도 동일하게 `ConvertResult` 반환으로 변경. `convertFromSource`는 자체적으로 source 문자열을 가지고 있으므로 `IssueCollector`를 직접 생성하여 `convertFromAst`에 전달한다.

### source 문자열 전달 전략

`IssueCollector`의 offset→line:column 변환에는 원본 Dart 소스가 필요하다.

- **`convertFromSource()`**: 내부에서 `parseString(content: dartSource)`를 호출하므로 source를 이미 가지고 있음. `IssueCollector(dartSource)`를 생성.
- **`convertFromAst()`**: `FunctionDeclaration` AST 노드만 받으므로 source가 없음. `{String? source}` optional 파라미터를 추가.
  - source가 제공되면 offset→line:column 변환 가능
  - source가 없으면 offset만 보고 (line:column 없이)
- **`rfw_widget_builder.dart`**: `buildStep.readAsString()`으로 source를 이미 읽고 있으므로 `convertFromAst(function, source: source)`로 전달.

### 변경 흐름

```
현재:
  expression_converter: throw UnsupportedExpressionError
  ast_visitor: catch → developer.log → skip param
  converter: 모름
  builder: catch → log.severe

변경:
  expression_converter: collector.warning(message, offset, suggestion) → skip param
  ast_visitor: collector.warning(context 포함 메시지) → skip param
  converter: collector 생성 → ConvertResult(rfwtxt, issues) 반환
  builder: issues를 log.warning/log.severe로 출력 + parseLibraryFile 검증
```

### ExpressionConverter 변경 전략

현재 `ExpressionConverter`는 지원 안 되는 표현식에서 `throw UnsupportedExpressionError`한다. 이를 두 가지 방식으로 처리할 수 있다:

**선택: throw 유지 + ast_visitor에서 catch하여 collector에 수집**

이유:
- `ExpressionConverter`는 단일 표현식 변환기로, 실패 시 "이 표현식은 변환 불가"라는 의미가 명확
- 이미 `ast_visitor`에서 `on UnsupportedExpressionError catch`로 잡고 있음
- collector를 expression_converter에까지 주입하면 31곳의 throw를 모두 바꿔야 함
- catch 지점(ast_visitor)에서 위젯 이름, 파라미터 이름 등 **컨텍스트 정보를 추가**할 수 있음

변경점:
- `UnsupportedExpressionError`의 offset 누락 7곳에 offset 추가
- `ast_visitor`의 catch 블록에서 `developer.log` → `collector.warning` (컨텍스트 포함)
- suggestion은 catch 블록에서 에러 메시지 패턴 기반으로 매핑

### suggestion 매핑

#### ExpressionConverter 에러 (ast_visitor catch 지점에서 매핑)

| 에러 패턴 | suggestion |
|-----------|-----------|
| `Unsupported expression type: ConditionalExpression` | `삼항연산자 대신 RfwSwitch를 사용하세요` |
| `Unsupported expression type: FunctionExpressionInvocation` | `함수 호출 결과는 지원되지 않습니다. const 값을 직접 사용하세요` |
| `Unsupported method invocation: *` | `지원되지 않는 메서드입니다. 지원 목록: Color, EdgeInsets, TextStyle 등` |
| `Unsupported const constructor: *` | `지원되지 않는 생성자입니다` |
| `Unknown *Alignment* constant` | `지원되는 값: topLeft, topCenter, topRight, centerLeft, center, ...` |
| `Unsupported EdgeInsets constructor` | `지원되는 생성자: .all, .symmetric, .only, .fromLTRB` |
| `Unsupported BorderRadius constructor` | `지원되는 생성자: .circular, .all, .only` |

#### AST 구조 에러 (ast_visitor 자체 경고)

| 에러 패턴 | suggestion |
|-----------|-----------|
| `UnsupportedWidgetError` | `rfw_gen.yaml에 위젯을 등록하거나 지원 위젯 목록을 확인하세요` |
| children가 ListLiteral이 아닌 경우 | `children 파라미터에는 리스트 리터럴 [...]을 사용하세요` |
| named slot이 ListLiteral이 아닌 경우 | `리스트 슬롯에는 리스트 리터럴 [...]을 사용하세요` |

### offset 누락 보완 (7곳)

| 위치 | line | 현재 | 수정 |
|------|------|------|------|
| `_convertEdgeInsets()` | 384 | method name만 | 호출부에서 `expr.offset` 전달 |
| `_convertEdgeInsetsDirectional()` | 472 | method name만 | 호출부에서 `expr.offset` 전달 |
| `_convertRfwIcon()` | 541 | name만 | 호출부에서 `expr.offset` 전달 |
| `_convertAlignmentConstant()` | 569 | name만 | 호출부에서 `expr.offset` 전달 |
| `_convertAlignmentDirectionalConstant()` | 592 | name만 | 호출부에서 `expr.offset` 전달 |
| `_convertBorderRadius()` | 639 | method name만 | 호출부에서 `expr.offset` 전달 |
| `_convertDynamicRef()` inline | 1146 | refType만 | 호출부에서 `expr.offset` 전달 |

참고: `_convertTextDecorationEnum()` (line 835)과 `_convertFontEnum()` (line 818)은 이미 `offset: expr.offset`을 포함하고 있어 수정 불필요.

각 헬퍼 메서드에 `{int? offset}` 파라미터를 추가하고, 호출부에서 원본 expression의 offset을 전달한다.

### rfwtxt 검증 단계

`rfw_widget_builder.dart`에서 rfwtxt 파일 작성 전에 `parseLibraryFile()`로 검증한다. 현재 `toBlob()` 내부에서도 `parseLibraryFile()`을 호출하지만, 검증 단계를 명시적으로 분리하여 의도를 명확히 한다. 검증 통과 시 `toBlob()`에서 다시 파싱하는 중복이 있으나, 코드 생성은 빈번한 작업이 아니므로 성능 영향은 무시할 수 있다.

```dart
// 생성된 rfwtxt 검증
try {
  parseLibraryFile(combined);
} catch (e) {
  log.severe(
    'Generated rfwtxt is invalid (possible rfw_gen bug): $e\n'
    'Generated content:\n$combined'
  );
  return; // .rfwtxt와 .rfw 모두 생성하지 않음
}
```

### UnsupportedWidgetError 처리 전략

`UnsupportedWidgetError`는 현재 `ast_visitor.dart`의 `extractWidgetTree()` → `_convertWidget()`에서 throw된다. 이 에러는 **throw를 유지**한다.

이유:
- 루트 위젯이나 자식 위젯이 미등록이면 해당 위젯 트리 전체가 변환 불가
- 파라미터 skip과 다르게, 위젯 자체를 skip하면 의미 있는 rfwtxt를 생성할 수 없음
- `rfw_widget_builder.dart`의 기존 `catch (e) { log.severe(...) }` 패턴으로 처리

변경점: catch 블록에서 suggestion을 추가하여 사용자에게 대안을 제시한다.

```dart
// rfw_widget_builder.dart
try {
  final result = converter.convertFromAst(function, source: source);
  // ...
} on UnsupportedWidgetError catch (e) {
  log.severe('${function.name.lexeme}: ${e.toString()}\n'
    '  Suggestion: rfw_gen.yaml에 위젯을 등록하거나 지원 위젯 목록을 확인하세요');
} catch (e) {
  log.severe('Failed to convert ${function.name.lexeme}: $e');
}
```

### 범위 밖 에러 경로

다음 에러들은 이번 변경 범위에 포함하지 않는다:

- **`widget_registry.dart`의 `ArgumentError` (4곳)**: rfw_gen.yaml 설정 파싱 시 발생. 변환 시작 전에 발생하므로 IssueCollector 범위 밖. 기존 동작(즉시 throw → 빌드 실패) 유지.
- **`rfwtxt_emitter.dart`의 `StateError` (NaN/Infinity)**: 정상적인 Dart 소스에서는 발생하지 않음. rfw_gen 내부 버그 지표이므로 throw 유지.

### _extractStateDecl 에러 처리

`converter.dart`의 `_extractStateDecl()`에서 `exprConverter.convert()`를 try/catch 없이 호출하는 문제 수정:

```dart
try {
  entries[key] = exprConverter.convert(entry.value);
} on UnsupportedExpressionError catch (e) {
  collector.warning(
    'state 필드 "$key" 값을 변환할 수 없습니다: ${e.message}',
    offset: e.offset,
    suggestion: '상태 초기값은 리터럴(문자열, 숫자, 불리언)만 지원됩니다',
  );
}
```

## 변경 파일 요약

| 파일 | 패키지 | 변경 |
|------|--------|------|
| `errors.dart` | rfw_gen | `RfwGenIssue`에 `column` 필드 추가, `toString()` 수정 |
| `issue_collector.dart` (신규) | rfw_gen_builder | `IssueCollector` 클래스 |
| `convert_result.dart` (신규) | rfw_gen_builder | `ConvertResult` 클래스 |
| `expression_converter.dart` | rfw_gen_builder | offset 누락 7곳 보완 (메서드 시그니처 변경) |
| `ast_visitor.dart` | rfw_gen_builder | collector 주입, `developer.log` 6곳 → `collector.warning` |
| `converter.dart` | rfw_gen_builder | collector 생성/전달, `ConvertResult` 반환, `_extractStateDecl` 에러 처리 |
| `rfw_widget_builder.dart` | rfw_gen_builder | 이슈 출력 + parseLibraryFile 검증 |
| `rfw_gen_builder.dart` | rfw_gen_builder | `ConvertResult` export 추가 |

## 테스트 전략

### 단위 테스트

- `IssueCollector`: offset→line:column 변환 정확성, warning/fatal 수집
- `RfwGenIssue`: column 포함된 toString() 포맷
- `ExpressionConverter`: offset 누락 7곳이 올바른 offset을 포함하는지 확인

### 통합 테스트

- 지원 안 되는 표현식 사용 시 `ConvertResult.issues`에 warning이 수집되는지
- 미등록 위젯 사용 시 fatal issue가 수집되는지
- 여러 에러가 동시에 수집되어 한 번에 보고되는지
- suggestion이 적절한 값으로 채워지는지

### 기존 테스트 수정

- `converter_test.dart`: `convertFromAst()` 반환값이 `ConvertResult`로 변경됨에 따라 `.rfwtxt` 접근으로 수정
- `expression_converter_test.dart`: offset 관련 테스트 보강 (7곳 누락 보완 검증)
- `ast_visitor_test.dart`: collector 주입 후 warning 수집 동작 확인
- `rfw_widget_builder_test.dart` (있을 경우): 이슈 출력 + 검증 단계 동작 확인

## 공개 API 영향

- `RfwGenIssue` — `column` 필드 추가 (하위 호환, optional)
- `RfwConverter.convertFromAst()` — 반환값 `String` → `ConvertResult` (breaking change)
- `RfwConverter.convertFromSource()` — 반환값 `String` → `ConvertResult` (breaking change)
- `ConvertResult` — 신규 공개 클래스

`RfwConverter`는 `rfw_gen_builder`에서 export되며, 주로 `rfw_widget_builder`에서 내부적으로 사용된다. 외부에서 직접 `RfwConverter`를 사용하는 경우는 드물지만, breaking change이므로 CHANGELOG에 기록한다.
