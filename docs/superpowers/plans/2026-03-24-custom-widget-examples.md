# namedSlots 확장 + Custom Widget 예제 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `rfw_gen.yaml`에서 `namedSlots` child_type 지원을 확장하고, 13개 복잡한 custom widget 예제를 example 앱에 추가한다.

**Architecture:** `registerFromConfig()`에 `named_child_slots` 맵 파싱을 추가하여 namedSlots를 지원한다. 파이프라인(ast_visitor, emitter)은 이미 namedSlots를 처리하므로 변경 불필요. example 앱에 `custom/custom_widgets.dart`를 추가하고 main.dart에 Custom 카테고리와 LocalWidgetLibrary를 등록한다.

**Tech Stack:** Dart, Flutter, rfw, rfw_gen, build_runner

**Spec:** `docs/superpowers/specs/2026-03-24-custom-widget-examples-design.md`

---

## File Structure

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `packages/rfw_gen/lib/src/widget_registry.dart` | namedSlots 파싱 확장 |
| Modify | `packages/rfw_gen/test/widget_registry_test.dart` | namedSlots 테스트 추가/수정 |
| Modify | `packages/rfw_gen/test/integration_test.dart` | namedSlots 통합 테스트 |
| Modify | `example/rfw_gen.yaml` | 13개 custom widget 등록 |
| Create | `example/lib/custom/custom_widgets.dart` | 13개 @RfwWidget 데모 함수 |
| Modify | `example/lib/main.dart` | Custom 카테고리 + LocalWidgetLibrary |

---

### Task 1: namedSlots 파싱 — 테스트 작성

**Files:**
- Modify: `packages/rfw_gen/test/widget_registry_test.dart:891-903`

- [ ] **Step 1: 기존 throw 테스트를 성공 케이스로 교체 + 에러 케이스 추가**

`widget_registry_test.dart`의 `registerFromConfig` 그룹 안, 기존 `'throws when namedSlots is used'` 테스트(line 891-903)를 삭제하고 아래로 교체:

```dart
    test('registers namedSlots widget with named_child_slots', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'MyTile': {
          'import': 'custom.widgets',
          'child_type': 'namedSlots',
          'named_child_slots': {'title': false, 'actions': true},
        },
      });
      final mapping = registry.supportedWidgets['MyTile']!;
      expect(mapping.childType, ChildType.namedSlots);
      expect(mapping.childParam, isNull);
      expect(mapping.namedChildSlots, {'title': false, 'actions': true});
    });

    test('namedSlots with handlers', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'MyTile': {
          'import': 'custom.widgets',
          'child_type': 'namedSlots',
          'named_child_slots': {'leading': false, 'title': false},
          'handlers': ['onTap'],
        },
      });
      final mapping = registry.supportedWidgets['MyTile']!;
      expect(mapping.childType, ChildType.namedSlots);
      expect(mapping.namedChildSlots, {'leading': false, 'title': false});
      expect(mapping.handlerParams, {'onTap'});
    });

    test('throws when namedSlots without named_child_slots', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {'import': 'x', 'child_type': 'namedSlots'},
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('requires "named_child_slots"'),
        )),
      );
    });

    test('throws when namedSlots with empty named_child_slots', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'namedSlots',
            'named_child_slots': <String, dynamic>{},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('requires "named_child_slots"'),
        )),
      );
    });

    test('throws when named_child_slots provided with non-namedSlots child_type', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'child',
            'named_child_slots': {'title': false},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('only valid when child_type is "namedSlots"'),
        )),
      );
    });

    test('throws when named_child_slots has non-bool value', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'namedSlots',
            'named_child_slots': {'title': 'yes'},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('must be a bool'),
        )),
      );
    });
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart --name "namedSlots"`
Expected: 6개 중 4개 FAIL (성공 케이스 2개 + non-namedSlots/non-bool 에러 케이스 — 아직 구현 안 됨)

---

### Task 2: namedSlots 파싱 — 구현

**Files:**
- Modify: `packages/rfw_gen/lib/src/widget_registry.dart:120-170`

- [ ] **Step 3: `_parseChildType` 수정 — throw 제거**

`widget_registry.dart` line 166-168에서:

```dart
// Before:
'namedSlots' => throw ArgumentError(
    'namedSlots is not supported for custom widgets in rfw_gen.yaml',
  ),

// After:
'namedSlots' => ChildType.namedSlots,
```

- [ ] **Step 4: `registerFromConfig` 수정 — named_child_slots 파싱 추가**

`widget_registry.dart`의 `registerFromConfig` 메서드에서 `final handlers = ...` 줄 다음, `final childParam = ...` 줄 앞에 추가:

```dart
      // Validate named_child_slots
      final rawSlots = config['named_child_slots'] as Map?;
      if (childType == ChildType.namedSlots &&
          (rawSlots == null || rawSlots.isEmpty)) {
        throw ArgumentError(
          'Widget "$name" with child_type "namedSlots" '
          'requires "named_child_slots" with at least one entry',
        );
      }
      if (childType != ChildType.namedSlots && rawSlots != null) {
        throw ArgumentError(
          'Widget "$name" has "named_child_slots" which is '
          'only valid when child_type is "namedSlots"',
        );
      }
      final namedChildSlots = <String, bool>{};
      if (rawSlots != null) {
        for (final e in rawSlots.entries) {
          if (e.value is! bool) {
            throw ArgumentError(
              'Widget "$name" named_child_slots["${e.key}"] '
              'must be a bool (true=list slot, false=single slot), '
              'got ${e.value.runtimeType}',
            );
          }
          namedChildSlots[e.key as String] = e.value as bool;
        }
      }
```

그리고 `register()` 호출에 `namedChildSlots` 추가:

```dart
      register(
        name,
        WidgetMapping(
          rfwName: name,
          import: importLib,
          childType: childType,
          childParam: childParam,
          params: const {},
          handlerParams: handlers,
          namedChildSlots: namedChildSlots,
        ),
      );
```

- [ ] **Step 5: 테스트 실행 — 전체 통과 확인**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/widget_registry_test.dart --name "namedSlots"`
Expected: 6개 모두 PASS

- [ ] **Step 6: 전체 테스트 실행**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/`
Expected: 전부 PASS (기존 테스트 깨지지 않음)

- [ ] **Step 7: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/lib/src/widget_registry.dart packages/rfw_gen/test/widget_registry_test.dart
git commit -m "feat: support namedSlots child_type in rfw_gen.yaml registerFromConfig"
```

---

### Task 3: namedSlots 통합 테스트

**Files:**
- Modify: `packages/rfw_gen/test/integration_test.dart:458-549`

- [ ] **Step 8: 통합 테스트 추가**

`integration_test.dart`의 `'custom widget support'` 그룹 setUp에 namedSlots 위젯 등록 추가:

```dart
      // setUp의 registerFromConfig에 추가:
      'CustomTile': {
        'import': 'custom.widgets',
        'child_type': 'namedSlots',
        'named_child_slots': {
          'leading': false,
          'title': false,
          'subtitle': false,
        },
        'handlers': ['onTap'],
      },
```

같은 그룹 마지막에 테스트 케이스 추가:

```dart
    test('custom namedSlots widget with slots and handler', () {
      const input = '''
Widget build() {
  return CustomTile(
    leading: Icon(icon: RfwIcon.star),
    title: MystiqueText(text: 'Title'),
    subtitle: Text('Subtitle'),
    onTap: RfwHandler.event('tile.tap', {}),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('CustomTile('));
      expect(rfwtxt, contains('leading: Icon('));
      expect(rfwtxt, contains('title: MystiqueText('));
      expect(rfwtxt, contains('subtitle: Text('));
      expect(rfwtxt, contains('onTap: event "tile.tap"'));
      expect(rfwtxt, contains('import custom.widgets;'));
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(rfwtxt);
    });
```

- [ ] **Step 9: 테스트 실행**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/integration_test.dart --name "namedSlots"`
Expected: PASS

- [ ] **Step 10: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add packages/rfw_gen/test/integration_test.dart
git commit -m "test: add namedSlots integration test for custom widgets"
```

---

### Task 4: rfw_gen.yaml 업데이트

**Files:**
- Modify: `example/rfw_gen.yaml`

- [ ] **Step 11: 13개 위젯 등록**

`example/rfw_gen.yaml`을 전체 교체:

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

- [ ] **Step 12: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/rfw_gen.yaml
git commit -m "feat: register 13 custom widgets in rfw_gen.yaml"
```

---

### Task 5: custom_widgets.dart 작성

**Files:**
- Create: `example/lib/custom/custom_widgets.dart`

- [ ] **Step 13: 13개 @RfwWidget 데모 함수 작성**

```dart
// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter, not_enough_positional_arguments
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// 1. CustomText — child_type: none, pass-through params
// ============================================================

@RfwWidget('customTextDemo')
Widget buildCustomTextDemo() {
  return Column(
    children: [
      CustomText(text: 'Heading Style', fontType: 'heading', color: 0xFF1565C0),
      SizedBox(height: 8.0),
      CustomText(text: 'Body Style', fontType: 'body', color: 0xFF424242),
      SizedBox(height: 8.0),
      CustomText(text: 'Caption with maxLines', fontType: 'caption', color: 0xFF757575, maxLines: 1),
    ],
  );
}

// ============================================================
// 2. CustomBounceTapper — child_type: optionalChild, handler: onTap
// ============================================================

@RfwWidget('customBounceTapperDemo')
Widget buildCustomBounceTapperDemo() {
  return CustomBounceTapper(
    onTap: RfwHandler.event('bounce.tap', {'source': 'demo'}),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFF2196F3),
      child: Text('Tap me (bounce)', style: const TextStyle(color: Color(0xFFFFFFFF))),
    ),
  );
}

// ============================================================
// 3. NullConditionalWidget — optionalChild + widget-value param (nullChild)
// ============================================================

@RfwWidget('nullConditionalDemo')
Widget buildNullConditionalDemo() {
  return Column(
    children: [
      NullConditionalWidget(
        child: CustomText(text: 'Visible content', fontType: 'heading', color: 0xFF4CAF50),
        nullChild: CustomText(text: 'Fallback content', fontType: 'body', color: 0xFFFF5722),
      ),
      SizedBox(height: 16.0),
      NullConditionalWidget(
        nullChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFFFF3E0),
          child: Text('This is the fallback'),
        ),
      ),
    ],
  );
}

// ============================================================
// 4. CustomButton — child_type: child, handlers: onPressed + onLongPress
// ============================================================

@RfwWidget('customButtonDemo')
Widget buildCustomButtonDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CustomButton(
        onPressed: RfwHandler.event('button.press', {'id': 'primary'}),
        onLongPress: RfwHandler.event('button.longPress', {'id': 'primary'}),
        child: Text('Primary Button'),
      ),
      SizedBox(height: 12.0),
      CustomButton(
        onPressed: RfwHandler.event('button.press', {'id': 'secondary'}),
        child: Text('Secondary Button'),
      ),
    ],
  );
}

// ============================================================
// 5. CustomBadge — child_type: none, Color + number + string params
// ============================================================

@RfwWidget('customBadgeDemo')
Widget buildCustomBadgeDemo() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      CustomBadge(label: 'NEW', count: 5, backgroundColor: 0xFFE91E63),
      CustomBadge(label: 'HOT', count: 12, backgroundColor: 0xFFFF9800),
      CustomBadge(label: 'SALE', count: 0, backgroundColor: 0xFF4CAF50),
    ],
  );
}

// ============================================================
// 6. CustomProgressBar — child_type: none, value + color + enum params
// ============================================================

@RfwWidget('customProgressBarDemo')
Widget buildCustomProgressBarDemo() {
  return Column(
    children: [
      CustomProgressBar(value: 0.3, color: 0xFF2196F3, shape: 'rounded'),
      SizedBox(height: 12.0),
      CustomProgressBar(value: 0.7, color: 0xFF4CAF50, shape: 'square'),
      SizedBox(height: 12.0),
      CustomProgressBar(value: 1.0, color: 0xFFFF9800, shape: 'rounded', height: 8.0),
    ],
  );
}

// ============================================================
// 7. CustomColumn — child_type: childList
// ============================================================

@RfwWidget('customColumnDemo')
Widget buildCustomColumnDemo() {
  return CustomColumn(
    spacing: 8.0,
    dividerColor: 0xFFE0E0E0,
    children: [
      Container(height: 40.0, color: const Color(0xFF2196F3)),
      Container(height: 40.0, color: const Color(0xFF4CAF50)),
      Container(height: 40.0, color: const Color(0xFFFF9800)),
    ],
  );
}

// ============================================================
// 8. SkeletonContainer — child_type: optionalChild, boolean param
// ============================================================

@RfwWidget('skeletonContainerDemo')
Widget buildSkeletonContainerDemo() {
  return Column(
    children: [
      SkeletonContainer(
        isLoading: true,
        child: Text('This content is loading...'),
      ),
      SizedBox(height: 16.0),
      SkeletonContainer(
        isLoading: false,
        child: Text('This content is loaded!'),
      ),
    ],
  );
}

// ============================================================
// 9. CompareWidget — optionalChild + multiple widget-value params
// ============================================================

@RfwWidget('compareWidgetDemo')
Widget buildCompareWidgetDemo() {
  return Column(
    children: [
      CompareWidget(
        child: CustomText(text: 'Checking condition...', fontType: 'body', color: 0xFF757575),
        trueChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFE8F5E9),
          child: Text('Condition is TRUE', style: const TextStyle(color: Color(0xFF4CAF50))),
        ),
        falseChild: Container(
          padding: const EdgeInsets.all(12.0),
          color: const Color(0xFFFFEBEE),
          child: Text('Condition is FALSE', style: const TextStyle(color: Color(0xFFFF5722))),
        ),
      ),
    ],
  );
}

// ============================================================
// 10. PvContainer — optionalChild + custom event name handler (onPv)
// ============================================================

@RfwWidget('pvContainerDemo')
Widget buildPvContainerDemo() {
  return PvContainer(
    onPv: RfwHandler.event('pv.track', {'screen': 'demo', 'section': 'custom'}),
    child: Container(
      padding: const EdgeInsets.all(16.0),
      color: const Color(0xFFE3F2FD),
      child: Column(
        children: [
          Text('PV Tracking Container', style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.0),
          Text('onPv event fires on view', style: const TextStyle(fontSize: 12.0, color: Color(0xFF757575))),
        ],
      ),
    ),
  );
}

// ============================================================
// 11. CustomCard — child_type: child + handler: onTap
// ============================================================

@RfwWidget('customCardDemo')
Widget buildCustomCardDemo() {
  return Column(
    children: [
      CustomCard(
        onTap: RfwHandler.event('card.tap', {'id': 'card1'}),
        elevation: 4.0,
        borderRadius: 12.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Custom Card 1', style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold)),
              SizedBox(height: 4.0),
              Text('Tappable card with elevation', style: const TextStyle(color: Color(0xFF757575))),
            ],
          ),
        ),
      ),
      SizedBox(height: 12.0),
      CustomCard(
        onTap: RfwHandler.event('card.tap', {'id': 'card2'}),
        elevation: 2.0,
        borderRadius: 8.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Custom Card 2'),
        ),
      ),
    ],
  );
}

// ============================================================
// 12. CustomTile — namedSlots (leading/title/subtitle/trailing) + handler
// ============================================================

@RfwWidget('customTileDemo')
Widget buildCustomTileDemo() {
  return Column(
    children: [
      CustomTile(
        leading: Icon(icon: RfwIcon.email, size: 40.0, color: const Color(0xFF2196F3)),
        title: CustomText(text: 'Custom Tile Title', fontType: 'heading', color: 0xFF212121),
        subtitle: Text('Subtitle with named slots'),
        trailing: Icon(icon: RfwIcon.chevronRight),
        onTap: RfwHandler.event('tile.tap', {'id': 'tile1'}),
      ),
      Divider(),
      CustomTile(
        leading: Icon(icon: RfwIcon.settings, size: 40.0, color: const Color(0xFF757575)),
        title: Text('Minimal Tile'),
        onTap: RfwHandler.event('tile.tap', {'id': 'tile2'}),
      ),
    ],
  );
}

// ============================================================
// 13. CustomAppBar — namedSlots (title + actions list slot)
// ============================================================

@RfwWidget('customAppBarDemo')
Widget buildCustomAppBarDemo() {
  return Column(
    children: [
      CustomAppBar(
        title: Text('Custom App Bar', style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
        actions: [
          GestureDetector(
            onTap: RfwHandler.event('appbar.search', {}),
            child: Icon(icon: RfwIcon.search, color: const Color(0xFFFFFFFF)),
          ),
          GestureDetector(
            onTap: RfwHandler.event('appbar.more', {}),
            child: Icon(icon: RfwIcon.moreVert, color: const Color(0xFFFFFFFF)),
          ),
        ],
      ),
      SizedBox(height: 16.0),
      CustomAppBar(
        title: CustomText(text: 'Styled Title', fontType: 'heading', color: 0xFFFFFFFF),
      ),
    ],
  );
}
```

- [ ] **Step 14: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/lib/custom/custom_widgets.dart
git commit -m "feat: add 13 custom widget demo functions"
```

---

### Task 6: main.dart 업데이트

**Files:**
- Modify: `example/lib/main.dart`

- [ ] **Step 15: Custom 카테고리를 `_catalogWidgets` 맵에 추가**

`main.dart`의 `_catalogWidgets` 맵 (line 54-83 부근), `'Other'` 카테고리 뒤에 추가:

```dart
    'Custom': [
      'customTextDemo', 'customBounceTapperDemo', 'nullConditionalDemo',
      'customButtonDemo', 'customBadgeDemo', 'customProgressBarDemo',
      'customColumnDemo', 'skeletonContainerDemo', 'compareWidgetDemo',
      'pvContainerDemo', 'customCardDemo', 'customTileDemo', 'customAppBarDemo',
    ],
```

- [ ] **Step 16: initState에 custom.widgets LocalWidgetLibrary 등록**

`main.dart`의 `initState` 메서드에서 `MockData.setupShop(_data)` 줄 바로 위에 추가:

```dart
    _runtime.update(
      const LibraryName(<String>['custom', 'widgets']),
      LocalWidgetLibrary(<String, LocalWidgetBuilder>{
        'CustomText': (BuildContext context, DataSource source) {
          final text = source.v<String>(['text']) ?? '';
          final fontType = source.v<String>(['fontType']) ?? 'body';
          final color = Color(source.v<int>(['color']) ?? 0xFF000000);
          final maxLines = source.v<int>(['maxLines']);
          final style = switch (fontType) {
            'heading' => TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            'button' => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            'caption' => TextStyle(fontSize: 12, color: color),
            _ => TextStyle(fontSize: 14, color: color),
          };
          return Text(text, style: style, maxLines: maxLines);
        },
        'CustomBounceTapper': (BuildContext context, DataSource source) {
          return GestureDetector(
            onTap: source.voidHandler(['onTap']),
            child: source.optionalChild(['child']),
          );
        },
        'NullConditionalWidget': (BuildContext context, DataSource source) {
          final child = source.optionalChild(['child']);
          final nullChild = source.optionalChild(['nullChild']);
          return child ?? nullChild ?? const SizedBox.shrink();
        },
        'CustomButton': (BuildContext context, DataSource source) {
          return ElevatedButton(
            onPressed: source.voidHandler(['onPressed']),
            onLongPress: source.voidHandler(['onLongPress']),
            child: source.child(['child']),
          );
        },
        'CustomBadge': (BuildContext context, DataSource source) {
          final label = source.v<String>(['label']) ?? '';
          final count = source.v<int>(['count']) ?? 0;
          final bg = Color(source.v<int>(['backgroundColor']) ?? 0xFF9E9E9E);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Text('$label${count > 0 ? ' ($count)' : ''}',
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          );
        },
        'CustomProgressBar': (BuildContext context, DataSource source) {
          final value = source.v<double>(['value']) ?? 0.0;
          final color = Color(source.v<int>(['color']) ?? 0xFF2196F3);
          final shape = source.v<String>(['shape']) ?? 'rounded';
          final height = source.v<double>(['height']) ?? 4.0;
          return ClipRRect(
            borderRadius: BorderRadius.circular(shape == 'rounded' ? height / 2 : 0),
            child: LinearProgressIndicator(value: value, color: color, minHeight: height),
          );
        },
        'CustomColumn': (BuildContext context, DataSource source) {
          final spacing = source.v<double>(['spacing']) ?? 0.0;
          final dividerColor = Color(source.v<int>(['dividerColor']) ?? 0x00000000);
          final children = <Widget>[];
          for (var i = 0; i < source.length(['children']); i++) {
            if (i > 0) {
              if (spacing > 0) children.add(SizedBox(height: spacing));
              if (dividerColor.alpha > 0) children.add(Divider(color: dividerColor, height: 1));
            }
            children.add(source.child(['children', i]));
          }
          return Column(children: children);
        },
        'SkeletonContainer': (BuildContext context, DataSource source) {
          final isLoading = source.v<bool>(['isLoading']) ?? false;
          final child = source.optionalChild(['child']);
          if (isLoading) {
            return Container(
              height: 48, color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          return child ?? const SizedBox.shrink();
        },
        'CompareWidget': (BuildContext context, DataSource source) {
          final child = source.optionalChild(['child']);
          final trueChild = source.optionalChild(['trueChild']);
          final falseChild = source.optionalChild(['falseChild']);
          // Demo: show all three stacked
          return Column(children: [
            if (child != null) child,
            if (trueChild != null) trueChild,
            if (falseChild != null) falseChild,
          ]);
        },
        'PvContainer': (BuildContext context, DataSource source) {
          // Fire onPv handler on build (simulating page view tracking)
          final onPv = source.voidHandler(['onPv']);
          WidgetsBinding.instance.addPostFrameCallback((_) => onPv?.call());
          return source.optionalChild(['child']) ?? const SizedBox.shrink();
        },
        'CustomCard': (BuildContext context, DataSource source) {
          final elevation = source.v<double>(['elevation']) ?? 1.0;
          final borderRadius = source.v<double>(['borderRadius']) ?? 8.0;
          return GestureDetector(
            onTap: source.voidHandler(['onTap']),
            child: Card(
              elevation: elevation,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: source.child(['child']),
            ),
          );
        },
        'CustomTile': (BuildContext context, DataSource source) {
          return ListTile(
            leading: source.optionalChild(['leading']),
            title: source.optionalChild(['title']),
            subtitle: source.optionalChild(['subtitle']),
            trailing: source.optionalChild(['trailing']),
            onTap: source.voidHandler(['onTap']),
          );
        },
        'CustomAppBar': (BuildContext context, DataSource source) {
          final actions = <Widget>[];
          for (var i = 0; i < source.length(['actions']); i++) {
            actions.add(source.child(['actions', i]));
          }
          return AppBar(
            title: source.optionalChild(['title']),
            actions: actions.isEmpty ? null : actions,
            backgroundColor: const Color(0xFF2196F3),
          );
        },
      }),
    );
```

- [ ] **Step 17: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/lib/main.dart
git commit -m "feat: add Custom category with 13 widgets to example app"
```

---

### Task 7: build_runner 실행 + 통합 검증

**Files:**
- Generated: `example/lib/custom/custom_widgets.rfwtxt`
- Generated: `example/lib/custom/custom_widgets.rfw`
- Modify: `example/pubspec.yaml`
- Modify: `example/lib/main.dart`

**아키텍처 결정**: custom_widgets는 catalog/shop과 마찬가지로 **별도 rfw 라이브러리로 로드**. `_buildCatalogTab`에서 Custom 카테고리의 위젯을 선택했을 때 `_customLibrary`를 사용하도록 분기한다. 기존 catalog/shop 패턴과 동일한 접근.

- [ ] **Step 18: build_runner 실행**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen/example && dart run build_runner build --delete-conflicting-outputs`
Expected: 성공. `custom_widgets.rfwtxt`와 `custom_widgets.rfw` 생성됨

- [ ] **Step 19: rfwtxt 검증 — import 확인**

Run: `head -5 example/lib/custom/custom_widgets.rfwtxt`
Expected: `import core.widgets;`와 `import custom.widgets;` 모두 포함

- [ ] **Step 20: rfwtxt 검증 — namedSlots 위젯 출력 확인**

Run: `grep -A 5 'CustomTile' example/lib/custom/custom_widgets.rfwtxt`
Expected: `leading:`, `title:`, `subtitle:`, `trailing:`, `onTap:` 가 named params로 출력

Run: `grep -A 5 'CustomAppBar' example/lib/custom/custom_widgets.rfwtxt`
Expected: `title:`, `actions:` 출력 (actions는 리스트)

- [ ] **Step 21: rfw 바이너리를 assets로 복사**

Run: `cp example/lib/custom/custom_widgets.rfw example/assets/custom_widgets.rfw`

- [ ] **Step 22: pubspec.yaml에 asset 추가**

`example/pubspec.yaml`의 `assets:` 섹션에 추가:

```yaml
    - assets/custom_widgets.rfw
```

- [ ] **Step 23: main.dart에 `_customLibrary` 상수 및 rfw 로드 추가**

`main.dart`의 클래스 멤버 영역에 `_shopLibrary` 선언(line 52) 바로 뒤에 추가:

```dart
  static const _customLibrary = LibraryName(<String>['customdemo']);
```

`_catalogWidgets` 맵에 Custom 카테고리의 위젯 이름 리스트를 추가하되, 이 위젯들이 어떤 라이브러리에 속하는지 `_buildCatalogTab`에서 구분해야 한다.

`_HomePageState`에 헬퍼 Set 추가 (line 54 부근):

```dart
  static const _customWidgetNames = <String>{
    'customTextDemo', 'customBounceTapperDemo', 'nullConditionalDemo',
    'customButtonDemo', 'customBadgeDemo', 'customProgressBarDemo',
    'customColumnDemo', 'skeletonContainerDemo', 'compareWidgetDemo',
    'pvContainerDemo', 'customCardDemo', 'customTileDemo', 'customAppBarDemo',
  };
```

`_loadRfwBinaries`에서 shop 로드 뒤에 추가:

```dart
      final customBytes = await rootBundle.load('assets/custom_widgets.rfw');
      _runtime.update(
        _customLibrary,
        decodeLibraryBlob(customBytes.buffer.asUint8List()),
      );
```

- [ ] **Step 24: `_buildCatalogTab`에서 라이브러리 분기**

`_buildCatalogTab`의 `RemoteWidget` 위젯(line 229-234 부근)에서 `FullyQualifiedWidgetName`의 라이브러리를 분기:

```dart
// Before:
widget: FullyQualifiedWidgetName(_catalogLibrary, _selectedWidget!),

// After:
widget: FullyQualifiedWidgetName(
  _customWidgetNames.contains(_selectedWidget!)
      ? _customLibrary
      : _catalogLibrary,
  _selectedWidget!,
),
```

- [ ] **Step 25: 전체 테스트 실행**

Run: `cd /Users/byeonghopark-jobis/dev/rfw_gen && dart test packages/rfw_gen/test/`
Expected: 전부 PASS

- [ ] **Step 26: 커밋**

```bash
cd /Users/byeonghopark-jobis/dev/rfw_gen
git add example/
git commit -m "feat: generate rfwtxt/rfw for 13 custom widgets, wire up in example app"
```
