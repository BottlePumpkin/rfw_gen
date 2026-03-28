# Builder와 for문 조합 시 템플릿 에러

## 상태
수집됨

## 증상
WidgetBuilder 패턴 내부에서 for문(`...for`)을 사용하면 파서가 "Expecting a switch or constructor call" 에러를 발생시킨다. Builder의 템플릿으로 리스트(for문 포함)를 반환하는 것이 불가능하다.

## 재현 코드

### 기대하는 rfwtxt (현재 에러 발생)
```rfwtxt
widget myList = ListView(
  children: [
    ...for item in data.items:
      Builder(
        builder: (context) => ListTile(
          title: Text(text: item.name),
        ),
      ),
  ],
);
```

### 실제 동작
파서 에러: `Expecting a switch or constructor call got <Loop/DynamicList>`

Builder의 template 위치에 for문이 포함된 리스트가 오면 파서가 거부한다.

## RFW 소스 원인 분석
- **파일**: `packages/rfw/lib/src/dart/text.dart:2431-2432`
- WidgetBuilderDeclaration의 template 파싱 시 결과 타입을 검증:
  ```dart
  if (widget is! ConstructorCall && widget is! Switch) {
    throw ParserException._fromToken('Expecting a switch or constructor call got $widget', valueToken);
  }
  ```
- Builder의 template으로 `ConstructorCall` 또는 `Switch`만 허용
- for문이 포함된 리스트는 `DynamicList`/`Loop` 타입으로 파싱되어 이 검증에서 거부됨

- **파일**: `packages/rfw/lib/src/dart/model.dart:443-462`
- WidgetBuilderDeclaration 클래스의 `widget` 필드 주석:
  > "This is usually a ConstructorCall, but may be a Switch"
- `Loop`이나 `DynamicList` 타입은 설계에서 고려되지 않음

## 제안 해결책

Builder template에서 `Loop`/`DynamicList` 타입도 허용하도록 타입 검증 확장. 런타임(`runtime.dart`)에서 builder template이 리스트를 반환할 때 이를 children으로 처리하는 로직 추가.

다만 builder의 template이 "단일 위젯을 반환"하는 설계 의도와 충돌할 수 있어서, for문은 builder 바깥의 children에서만 사용하도록 가이드하는 것이 현실적일 수도 있다.

## 관련 링크
- 발견 경로: 3o3 실무 경험
