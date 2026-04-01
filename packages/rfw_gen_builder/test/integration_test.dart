import 'package:rfw/formats.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:test/test.dart';

void main() {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  group('rfwtxt → parseLibraryFile roundtrip', () {
    test('Text widget parses without error', () {
      const input = "Widget buildGreeting() { return Text('Hello World'); }";
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Column with 3 children parses without error', () {
      const input = '''
Widget buildList() {
  return Column(
    children: [
      Text('First'),
      Text('Second'),
      Text('Third'),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test(
        'nested Container > Column > [Text, SizedBox, Text] with color and padding parses without error',
        () {
      const input = '''
Widget buildNested() {
  return Container(
    color: Color(0xFF42A5F5),
    padding: EdgeInsets.all(16.0),
    child: Column(
      children: [
        Text('Top'),
        SizedBox(width: 8.0, height: 8.0),
        Text('Bottom'),
      ],
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Row with mainAxisAlignment enum parses without error', () {
      const input = '''
Widget buildToolbar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Left'),
      Text('Right'),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('rfwtxt → binary blob roundtrip produces decodable library', () {
      const input = '''
Widget buildCard() {
  return Container(
    color: Color(0xFF42A5F5),
    padding: EdgeInsets.all(8.0),
    child: Text('Hello'),
  );
}
''';
      final result = converter.convertFromSource(input);
      final blob = converter.toBlob(result.rfwtxt!);
      final decoded = decodeLibraryBlob(blob);
      expect(decoded.widgets, isNotEmpty);
    });

    test('Stack > Positioned > Text parses without error', () {
      const input = '''
Widget buildOverlay() {
  return Stack(
    children: [
      Positioned(
        top: 10.0,
        start: 20.0,
        child: Text('Overlay'),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('ListView > Padding > Text parses without error', () {
      const input = '''
Widget buildList() {
  return ListView(
    padding: EdgeInsets.all(16.0),
    children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Item 1'),
      ),
      Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('Item 2'),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Wrap with spacing parses without error', () {
      const input = '''
Widget buildTags() {
  return Wrap(
    spacing: 8.0,
    runSpacing: 4.0,
    children: [
      Text('Tag 1'),
      Text('Tag 2'),
      Text('Tag 3'),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Opacity > ClipRRect > ColoredBox parses without error', () {
      const input = '''
Widget buildCard() {
  return Opacity(
    opacity: 0.8,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: Color(0xFF42A5F5),
        child: Text('Card'),
      ),
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('SafeArea > Column > Expanded parses without error', () {
      const input = '''
Widget buildPage() {
  return SafeArea(
    child: Column(
      children: [
        Expanded(
          child: Text('Content'),
        ),
      ],
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('complex nested tree produces valid blob', () {
      const input = '''
Widget buildAnimated() {
  return Opacity(
    opacity: 0.5,
    child: Scale(
      scale: 1.5,
      child: Rotation(
        turns: 0.25,
        child: Text('Animated'),
      ),
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      final blob = converter.toBlob(result.rfwtxt!);
      final decoded = decodeLibraryBlob(blob);
      expect(decoded.widgets, isNotEmpty);
    });

    test('multiple widgets: blob size is reasonable', () {
      const input1 = "Widget buildFirst() { return Text('First'); }";
      const input2 = "Widget buildSecond() { return Text('Second'); }";

      final result1 = converter.convertFromSource(input1);
      final result2 = converter.convertFromSource(input2);

      final blob1 = converter.toBlob(result1.rfwtxt!);
      final blob2 = converter.toBlob(result2.rfwtxt!);

      // Each blob should be non-empty and reasonably small (< 1KB for simple widgets).
      expect(blob1, isNotEmpty);
      expect(blob2, isNotEmpty);
      expect(blob1.length, lessThan(1024));
      expect(blob2.length, lessThan(1024));

      // Both blobs decode correctly.
      final lib1 = decodeLibraryBlob(blob1);
      final lib2 = decodeLibraryBlob(blob2);
      expect(lib1.widgets, isNotEmpty);
      expect(lib2.widgets, isNotEmpty);
    });

    test('GestureDetector with setState handler parses', () {
      const input = '''
Widget build() {
  return GestureDetector(
    onTap: RfwHandler.setState('active', true),
    child: Text('Tap me'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('set state.active = true'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('ElevatedButton with event handler parses', () {
      const input = '''
Widget build() {
  return ElevatedButton(
    onPressed: RfwHandler.event('button.click'),
    child: Text('Click'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('event "button.click" {}'));
      expect(result.rfwtxt, contains('import material;'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Scaffold with AppBar and body parses', () {
      const input = '''
Widget build() {
  return Scaffold(
    appBar: AppBar(
      title: Text('Title'),
    ),
    body: Center(
      child: Text('Body'),
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('import material;'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Slider with setStateFromArg handler parses', () {
      const input = '''
Widget build() {
  return Slider(
    min: 0.0,
    max: 100.0,
    value: 50.0,
    onChanged: RfwHandler.setStateFromArg('sliderValue'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('set state.sliderValue = args.value'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('mixed core and material produces both imports', () {
      const input = '''
Widget build() {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Text('Hello'),
    ),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('import material;'));
    });

    test('Rotation widget emits Rotation( with turns param', () {
      const input = '''
Widget build() {
  return Rotation(
    turns: 0.25,
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('Rotation('));
      expect(result.rfwtxt, contains('turns: 0.25'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('Scale widget emits Scale( with scale param', () {
      const input = '''
Widget build() {
  return Scale(
    scale: 2.0,
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('Scale('));
      expect(result.rfwtxt, contains('scale: 2.0'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('SizedBoxShrink widget emits SizedBoxShrink(', () {
      const input = '''
Widget build() {
  return SizedBoxShrink();
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('SizedBoxShrink('));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test('AnimationDefaults widget emits AnimationDefaults( with duration', () {
      const input = '''
Widget build() {
  return AnimationDefaults(
    duration: Duration(milliseconds: 600),
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('AnimationDefaults('));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test(
        'AnimatedPadding uses core.widgets import and emits padding/duration params',
        () {
      const input = '''
Widget build() {
  return AnimatedPadding(
    padding: EdgeInsets.all(16.0),
    duration: Duration(milliseconds: 300),
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('Padding('));
      expect(result.rfwtxt, contains('padding:'));
      expect(result.rfwtxt, contains('duration: 300'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test(
        'AnimatedOpacity uses core.widgets import and emits opacity/duration params',
        () {
      const input = '''
Widget build() {
  return AnimatedOpacity(
    opacity: 0.5,
    duration: Duration(milliseconds: 300),
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('Opacity('));
      expect(result.rfwtxt, contains('opacity: 0.5'));
      expect(result.rfwtxt, contains('duration: 300'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });

    test(
        'PositionedDirectional uses core.widgets import and emits top/end params',
        () {
      const input = '''
Widget build() {
  return Stack(
    children: [
      PositionedDirectional(
        top: 10.0,
        end: 20.0,
        child: Container(color: Color(0xFF000000)),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('Positioned('));
      expect(result.rfwtxt, contains('end: 20.0'));
      final library = parseLibraryFile(result.rfwtxt!);
      expect(library.widgets, isNotEmpty);
    });
  });

  group('dynamic features integration', () {
    late RfwConverter converter;

    setUp(() {
      converter = RfwConverter(registry: WidgetRegistry.core());
    });

    test('DataRef produces parseable rfwtxt', () {
      const source = '''
Widget buildTest() {
  return Text(DataRef('user.name'));
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('data.user.name'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('ArgsRef produces parseable rfwtxt', () {
      const source = '''
Widget buildCard() {
  return Text(ArgsRef('item.title'));
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('args.item.title'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('RfwFor with LoopVar produces parseable rfwtxt', () {
      const source = '''
Widget buildList() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Text(item['name']),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('...for item in data.items:'));
      expect(result.rfwtxt, contains('item.name'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('RfwSwitch with widget cases produces parseable rfwtxt', () {
      const source = '''
Widget buildToggle() {
  return Column(
    children: [
      RfwSwitch(
        value: StateRef('active'),
        cases: {
          true: Text('Active'),
          false: Text('Inactive'),
        },
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('switch state.active'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('RfwSwitch at root produces parseable rfwtxt', () {
      const source = '''
Widget buildToggle() {
  return RfwSwitch(
    value: StateRef('active'),
    cases: {
      true: Text('Active'),
      false: Text('Inactive'),
    },
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('switch state.active'));
      expect(result.rfwtxt, contains('Text('));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('RfwSwitch at root with defaultCase produces parseable rfwtxt', () {
      const source = '''
Widget buildStatus() {
  return RfwSwitch(
    value: DataRef('status'),
    cases: {
      'loading': CircularProgressIndicator(),
      'done': Text('Complete'),
    },
    defaultCase: SizedBox(),
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('switch data.status'));
      expect(result.rfwtxt, contains('default:'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    // Note: RfwFor at root emits a spread (`...for`) which is not valid as the
    // root widget expression in rfwtxt — it is only legal inside a children
    // list.  The test therefore verifies that the converter produces the
    // correct spread syntax but does NOT assert parseLibraryFile roundtrip,
    // because the RFW parser rejects a spread at the widget-declaration root.
    test('RfwFor at root emits spread syntax', () {
      const source = '''
Widget buildList() {
  return RfwFor(
    items: DataRef('items'),
    itemName: 'item',
    builder: (item) => Text(item['name']),
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('...for item in data.items'));
    });

    test('RfwConcat produces parseable rfwtxt', () {
      const source = '''
Widget buildGreeting() {
  return Text(RfwConcat(['Hello, ', DataRef('name'), '!']));
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('"Hello, "'));
      expect(result.rfwtxt, contains('data.name'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('state declaration produces parseable rfwtxt', () {
      const source = '''
@RfwWidget('toggle', state: {'down': false})
Widget buildToggle() {
  return GestureDetector(
    onTapDown: RfwHandler.setState('down', true),
    onTapUp: RfwHandler.setState('down', false),
    child: Text('Tap'),
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('widget toggle { down: false }'));
      expect(result.rfwtxt, contains('set state.down = true'));
      expect(result.rfwtxt, contains('set state.down = false'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('event with dynamic payload produces parseable rfwtxt', () {
      const source = '''
Widget buildItem() {
  return ElevatedButton(
    onPressed: RfwHandler.event('shop.purchase', {'productId': ArgsRef('product.id'), 'quantity': 1}),
    child: Text('Buy'),
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('event "shop.purchase"'));
      expect(result.rfwtxt, contains('args.product.id'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('complex: RfwFor + DataRef inside Column produces parseable rfwtxt',
        () {
      const source = '''
Widget buildFeed() {
  return Column(
    children: [
      Text(DataRef('header')),
      RfwFor(
        items: DataRef('feed.items'),
        itemName: 'entry',
        builder: (entry) => Text(entry['title']),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('data.header'));
      expect(result.rfwtxt, contains('...for entry in data.feed.items:'));
      expect(result.rfwtxt, contains('entry.title'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('spread RfwFor in children produces parseable rfwtxt', () {
      const source = '''
Widget buildList() {
  return ListView(
    children: [
      Text('Header'),
      ...RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => ListTile(title: Text(item['name'])),
      ),
    ],
  );
}
''';
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('...for item in data.items'));
      expect(result.rfwtxt, contains('Header'));
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });
  });

  group('error reporting', () {
    test('unsupported expressions produce warnings with line info', () {
      const input = '''
Widget buildTest() {
  return Container(
    color: someFunc(),
    child: Text('hello'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget test'));
      expect(result.rfwtxt, contains('Text'));
      // color should be skipped but Text child preserved
      expect(result.rfwtxt, isNot(contains('color:')));
      // should have exactly one warning
      expect(result.issues, hasLength(1));
      expect(result.issues.first.line, isNotNull);
      expect(result.issues.first.column, isNotNull);
      expect(result.issues.first.message, contains('color'));
    });

    test('suggestion is provided for ternary expressions', () {
      const input = '''
Widget buildTest() {
  return Container(
    color: true ? Color(0xFF000000) : Color(0xFFFFFFFF),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.issues, hasLength(1));
      expect(result.issues.first.suggestion, contains('RfwSwitch'));
    });

    test('multiple warnings collected in single conversion', () {
      const input = '''
Widget buildTest() {
  return Container(
    color: fn1(),
    width: fn2(),
    child: Text('ok'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.issues, hasLength(2));
      // Text child should still be in output
      expect(result.rfwtxt, contains('text: "ok"'));
    });

    test('valid widget produces no issues', () {
      const input = '''
Widget buildTest() {
  return Container(
    color: Color(0xFF000000),
    child: Text('hello'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.issues, isEmpty);
      expect(result.rfwtxt, contains('widget test'));
    });
  });

  group('custom widget support', () {
    late RfwConverter converter;

    setUp(() {
      final registry = WidgetRegistry.core();
      registry.register(
        'MystiqueText',
        const WidgetMapping(
          rfwName: 'MystiqueText',
          import: 'mystique.widgets',
          params: {},
        ),
      );
      registry.register(
        'NullConditionalWidget',
        const WidgetMapping(
          rfwName: 'NullConditionalWidget',
          import: 'custom.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {},
        ),
      );
      registry.register(
        'SZSBounceTapper',
        const WidgetMapping(
          rfwName: 'SZSBounceTapper',
          import: 'custom.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {},
          handlerParams: {'onTap'},
        ),
      );
      registry.register(
        'CustomTile',
        const WidgetMapping(
          rfwName: 'CustomTile',
          import: 'custom.widgets',
          childType: ChildType.namedSlots,
          params: {},
          handlerParams: {'onTap'},
          namedChildSlots: {
            'leading': false,
            'title': false,
            'subtitle': false,
          },
        ),
      );
      converter = RfwConverter(registry: registry);
    });

    test('simple custom widget with pass-through params', () {
      const input = '''
Widget build() {
  return MystiqueText(text: 'hello', fontType: 'heading24Bold', color: 0xFF141618);
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import mystique.widgets;'));
      expect(result.rfwtxt, contains('MystiqueText('));
      expect(result.rfwtxt, contains('text: "hello"'));
      expect(result.rfwtxt, contains('fontType: "heading24Bold"'));
      expect(result.rfwtxt, contains('color: 0xFF141618'));
      parseLibraryFile(result.rfwtxt!);
    });

    test('custom widget nested inside core widget generates both imports', () {
      const input = '''
Widget build() {
  return Container(
    child: MystiqueText(text: 'hello'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(result.rfwtxt!);
    });

    test('widget-value param (nullChild) is preserved in output', () {
      const input = '''
Widget build() {
  return NullConditionalWidget(
    child: MystiqueText(text: 'visible'),
    nullChild: MystiqueText(text: 'fallback'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('nullChild: MystiqueText('));
      expect(result.rfwtxt, contains('import custom.widgets;'));
      expect(result.rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(result.rfwtxt!);
    });

    test('custom widget with handler param', () {
      const input = '''
Widget build() {
  return SZSBounceTapper(
    onTap: RfwHandler.event('navigate', {'url': 'szsapp://home'}),
    child: MystiqueText(text: 'tap me'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('onTap: event "navigate"'));
      expect(result.rfwtxt, contains('url: "szsapp://home"'));
      parseLibraryFile(result.rfwtxt!);
    });

    test('only used imports are generated', () {
      const input = '''
Widget build() {
  return MystiqueText(text: 'hello');
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import mystique.widgets;'));
      expect(result.rfwtxt, isNot(contains('import core.widgets;')));
      parseLibraryFile(result.rfwtxt!);
    });

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
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('CustomTile('));
      expect(result.rfwtxt, contains('leading: Icon('));
      expect(result.rfwtxt, contains('title: MystiqueText('));
      expect(result.rfwtxt, contains('subtitle: Text('));
      expect(result.rfwtxt, contains('onTap: event "tile.tap"'));
      expect(result.rfwtxt, contains('import custom.widgets;'));
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(result.rfwtxt!);
    });
  });
}
