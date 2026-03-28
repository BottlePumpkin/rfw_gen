# for문 index 변수 및 동적 리스트 접근 불가

## 상태
수집됨

## 증상
rfwtxt의 `...for item in data.items:` 구문에서 현재 반복 index를 변수로 접근할 수 없다. 또한 리스트 요소를 동적 index로 접근하는 것이 불가능하여 `data.list.0`, `data.list.1`처럼 하드코딩해야 한다.

예: 리스트를 순회하면서 "1번째 항목", "2번째 항목" 같이 번호를 표시하거나, 현재 index를 기반으로 다른 리스트의 대응 요소에 접근하는 패턴이 불가능하다.

## 재현 코드

### 기대하는 rfwtxt (현재 불가능)
```rfwtxt
// 1) index 변수 접근 — 현재 문법 자체가 없음
...for item in data.items:
  ListTile(
    leading: Text(text: item.index),  // ← index 변수 없음
    title: Text(text: item.name),
  ),

// 2) 동적 index로 리스트 접근 — 변수를 index로 사용 불가
...for i in data.indices:
  Text(text: data.names.{i}),  // ← 동적 접근 불가
```

### 실제 동작
- `item.index` 같은 index 변수가 존재하지 않음 — for문은 값만 바인딩하고 index를 제공하지 않음
- `data.list.{variable}` 형태의 동적 접근 불가 — Reference의 parts는 파싱 시점에 리터럴로 확정됨
- 하드코딩된 정수 index만 가능: `data.list.0`, `data.list.1`

## RFW 소스 원인 분석

### 1. Loop 파싱 — index 변수 미생성
- **파일**: `packages/rfw/lib/src/dart/text.dart:2217-2260`
- Loop 파싱 시 루프 식별자 이름과 컬렉션만 저장. 카운터/index 변수가 생성되지 않음
- `Loop` 객체는 `collection`과 `template`만 보유 (`model.dart:584-596`)

### 2. 런타임 바인딩 — 값만 바인딩
- **파일**: `packages/rfw/lib/src/flutter/runtime.dart:677-750`
- `_bindLoopVariable()` 에서 `LoopReference`를 현재 루프 값에만 바인딩 (line 733)
- index 정보가 바인딩 과정에 전혀 관여하지 않음

### 3. Reference 시스템 — 정적 경로만 지원
- **파일**: `packages/rfw/lib/src/dart/model.dart:464-477`
- Reference의 `parts`는 문자열(맵 키) 또는 정수(리스트 인덱스) 리터럴만 허용
- **파일**: `packages/rfw/lib/src/dart/text.dart:2295-2314`
- `_readParts()`가 리터럴 정수/문자열만 파싱 — 변수 표현식은 파싱 불가
- 설계 철학: 참조 경로가 파싱 시점에 정적으로 결정됨

## 제안 해결책

**Option A: for문에 index 변수 추가**
```rfwtxt
...for item, index in data.items:
  Text(text: index),  // index = 0, 1, 2, ...
```
- Dart의 `MapEntry` 패턴이나 Python의 `enumerate`와 유사
- Loop 파싱 시 두 번째 식별자를 index로 인식
- 런타임에서 `_bindLoopVariable()` 확장하여 index 바인딩 추가

**Option B: 동적 경로 접근 지원**
- Reference parts에 변수 표현식 허용
- 런타임에서 parts 평가 시 변수를 resolve하는 단계 추가
- 이건 큰 설계 변경이라 Option A가 현실적

## 관련 링크
- 발견 경로: 3o3 실무 경험 + dogfood
