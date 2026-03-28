# null 값 미지원

## 상태
수집됨

## 증상
rfwtxt에서 `null` 값을 사용하면 파서 에러가 발생한다. 맵 내부에서만 `null`이 허용되지만, 이 경우에도 해당 키가 완전히 생략되는 것과 동일하게 처리된다. 리스트, 인자, 위젯 선언 등에서는 null을 사용할 수 없다.

조건부로 값을 비워야 하는 패턴(예: 특정 조건에서 child를 null로 설정)이 불가능하다.

## 재현 코드

### 기대하는 rfwtxt (현재 에러 발생)
```rfwtxt
// 리스트에서 null
children: [Text(text: "hello"), null]

// 인자에서 null
Container(
  color: null,
  child: Text(text: "hello"),
)

// 조건부 null
widget myWidget = Container(
  child: switch state.showChild {
    true: Text(text: "visible"),
    false: null,
  },
);
```

### 실제 동작
- 리스트에서 `null` → "Expected symbol '(' at..." 파서 에러
- 인자에서 `null` → "Expected symbol '(' at..." 파서 에러
- switch의 값으로 `null` → "Expected symbol '(' at..." 파서 에러
- 맵에서 `{ key: null }` → 에러는 아니지만 키 자체가 생략됨 (`{}` 와 동일)

## RFW 소스 원인 분석
- **파일**: `packages/rfw/lib/src/dart/text.dart:2352-2354`
- `null` 키워드는 `nullOk: true`일 때만 인식됨:
  ```dart
  if (identifier == 'null' && nullOk) {
    _advance();
    return missing;  // missing 상수로 변환
  }
  ```

- **파일**: `packages/rfw/lib/src/dart/text.dart:2198-2203`
- `nullOk: true`는 맵 바디 파싱에서만 전달됨:
  ```dart
  final Object value = _readValue(
    extended: extended,
    nullOk: true,  // 맵에서만 true
    widgetBuilderScope: widgetBuilderScope,
  );
  if (value != missing) {
    results[key] = value;  // missing이면 키 자체를 생략
  }
  ```

- **파일**: `packages/rfw/lib/src/dart/text.dart:2318`
- 다른 모든 컨텍스트에서 `nullOk`의 기본값은 `false`
- `null`이 키워드로 인식되지 않으면 생성자 이름으로 취급 → `null(...)` 을 기대하며 `(` 토큰 부재로 에러

- **파일**: `packages/rfw/lib/src/dart/text.dart:32-66` (문서화)
- 명시적으로 기술: "null is not a valid value except as a value in maps, where it is equivalent to omitting the corresponding key entirely"

## 제안 해결책

**Option A: null 리터럴 전면 지원**
- `_readValue()`에서 `nullOk`를 항상 `true`로 변경
- `missing` 대신 실제 null 값을 표현하는 모델 타입 추가
- 런타임에서 null 값을 Flutter의 null로 매핑

**Option B: 최소 지원 — switch에서만 null 허용**
- switch 분기에서 "아무것도 렌더링하지 않음"을 표현하기 위해 null 허용
- `SizedBoxShrink()`를 workaround로 사용하는 현재 방식의 공식 대안 제공

## 관련 링크
- 발견 경로: 3o3 실무 경험
