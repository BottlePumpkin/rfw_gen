# Type Safety Improvement Design

## 문제

`@RfwWidget` 템플릿 파일에 `ignore_for_file` 주석이 6개 필요하다:

```dart
// ignore_for_file: argument_type_not_assignable, undefined_function,
//   undefined_class, undefined_named_parameter,
//   not_enough_positional_arguments, list_element_type_not_assignable
```

pub.dev 패키지 배포 시 사용자에게 이 부담을 최소화해야 한다.

## 분석 결과

실제 에러 109건을 분석한 결과:

| 에러 코드 | 건수 | 원인 | 제거 가능 여부 |
|-----------|------|------|--------------|
| `argument_type_not_assignable` | 59 | DataRef/StateRef/RfwEvent 등을 String/Color/Callback 자리에 사용 | 불가능 — rfw_gen의 본질 |
| `undefined_named_parameter` | 24 | `Icon(icon: ...)` 등 Flutter와 RFW의 API 차이 | 가능 — Icon 사용법 변경 |
| `not_enough_positional_arguments` | 16 | `Icon(icon: ...)` 사용 시 positional param 누락 | 가능 — Icon 사용법 변경 |
| `undefined_function` | 6 | SizedBoxShrink, Rotation, Scale, AnimationDefaults 등 RFW 전용 위젯 | 가능 — 빈 클래스 제공 |
| `list_element_type_not_assignable` | 4 | RfwFor를 List\<Widget\>에 사용 | 불가능 — for 루프 구조상 불가피 |
| `undefined_class` | 0 | 실제 에러 없음 | 제거 |

## 설계

### 1. RFW 전용 위젯 클래스 제공 (undefined_function 제거)

RFW가 공식 지원하지만 Flutter에 같은 이름이 없는 위젯 5개를 rfw_gen 패키지에서 제공한다.

**파일**: `packages/rfw_gen/lib/src/rfw_only_widgets.dart`

```dart
/// RFW 전용 위젯 — Flutter에 같은 이름이 없는 위젯들.
/// 빌드 타임 AST 파싱용이며 런타임에 인스턴스화되지 않는다.

/// RFW의 SizedBox.shrink 대응. 자식을 0x0으로 축소.
class SizedBoxShrink {
  final Object? child;
  const SizedBoxShrink({this.child});
}

/// RFW의 SizedBox.expand 대응. 자식을 가능한 최대로 확장.
class SizedBoxExpand {
  final Object? child;
  const SizedBoxExpand({this.child});
}

/// 회전 변환 위젯. Flutter의 RotatedBox에 해당하나 암묵적 애니메이션 지원.
class Rotation {
  final Object? turns;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Rotation({this.turns, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// 크기 변환 위젯. Flutter의 Transform.scale에 해당하나 암묵적 애니메이션 지원.
class Scale {
  final Object? scale;
  final Object? alignment;
  final Object? duration;
  final Object? curve;
  final Object? child;
  final Object? onEnd;
  const Scale({this.scale, this.alignment, this.duration, this.curve, this.child, this.onEnd});
}

/// 하위 위젯의 기본 애니메이션 duration/curve를 설정. RFW 전용.
class AnimationDefaults {
  final Object? duration;
  final Object? curve;
  final Object? child;
  const AnimationDefaults({this.duration, this.curve, this.child});
}
```

**export**: `packages/rfw_gen/lib/rfw_gen.dart`에서 export 추가.

### 2. Icon 사용법 변경 (undefined_named_parameter + not_enough_positional_arguments 제거)

Flutter의 `Icon`은 `Icon(IconData icon, {double? size, Color? color, ...})` — positional param.

**Before** (에러 발생):
```dart
Icon(icon: RfwIcon.home, size: 32.0, color: const Color(0xFF2196F3))
```

**After** (에러 없음):
```dart
Icon(RfwIcon.home, size: 32.0, color: const Color(0xFF2196F3))
```

Placeholder의 `placeholderWidth`/`placeholderHeight`도 Flutter의 실제 param 이름(`fallbackWidth`/`fallbackHeight`)으로 변경 필요. WidgetRegistry에서 두 이름 모두 지원하거나, 문서에서 Flutter 기준 이름 사용을 안내.

### 3. undefined_class 제거

실제 에러 0건이므로 ignore 목록에서 단순 제거.

## 최종 결과

**Before** (6개):
```dart
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments, list_element_type_not_assignable
```

**After** (2개):
```dart
// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
```

### 남은 2개가 제거 불가능한 이유

- **`argument_type_not_assignable`**: DataRef가 String/Color/int/double/VoidCallback 자리에 모두 들어가야 하는데, Dart 타입 시스템에서 하나의 클래스가 이 모든 타입을 만족시킬 수 없다.
- **`list_element_type_not_assignable`**: RfwFor를 Widget으로 만들면 해결 가능하나, 실행되지 않는 build() 메서드 강제, flutter 의존성 추가, "렌더링 가능한 위젯"이라는 오해 유발 등의 문제가 더 크다.

## 파일명 관례

`@RfwWidget` 함수가 포함된 파일은 `*.rfw.dart` 접미사 사용을 권장한다.

```
lib/
  widgets/
    shop_widgets.rfw.dart
    catalog_widgets.rfw.dart
```

## 변경 범위

| 변경 | 파일 |
|------|------|
| RFW 전용 위젯 클래스 추가 | `packages/rfw_gen/lib/src/rfw_only_widgets.dart` (신규) |
| export 추가 | `packages/rfw_gen/lib/rfw_gen.dart` |
| Icon 사용법 변경 | `example/lib/catalog/catalog_widgets.dart`, `example/lib/ecommerce/shop_widgets.dart` |
| Placeholder param 이름 확인 | `packages/rfw_gen/lib/src/widget_registry.dart` |
| ignore_for_file 정리 | `example/lib/catalog/catalog_widgets.dart`, `example/lib/ecommerce/shop_widgets.dart` |
| 테스트 추가 | RFW 전용 위젯 변환 테스트 |

## 검토하지 않은 대안

| 대안 | 제외 이유 |
|------|----------|
| Shadow 위젯 (56개 전체) | Object? 파라미터로 오히려 타입 안전성 후퇴, Flutter 자동완성/문서 상실 |
| Extension types | DataRef가 String/Color/int 등 모두에 필요 — 단일 타입만 implement 가능 |
| analyzer: exclude | IDE 지원(자동완성, 문서, 에러체크) 전부 비활성화 |
| 별도 DSL (YAML 등) | Flutter 개발자 친화성이라는 핵심 장점 포기 |
| RfwFor를 StatelessWidget으로 | 더미 build(), flutter 의존성, 혼란 유발 |
