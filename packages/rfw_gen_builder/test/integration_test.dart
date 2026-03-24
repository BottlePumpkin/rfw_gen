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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('nested Container > Column > [Text, SizedBox, Text] with color and padding parses without error', () {
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final blob = converter.toBlob(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      final blob = converter.toBlob(rfwtxt);
      final decoded = decodeLibraryBlob(blob);
      expect(decoded.widgets, isNotEmpty);
    });

    test('multiple widgets: blob size is reasonable', () {
      const input1 = "Widget buildFirst() { return Text('First'); }";
      const input2 = "Widget buildSecond() { return Text('Second'); }";

      final rfwtxt1 = converter.convertFromSource(input1);
      final rfwtxt2 = converter.convertFromSource(input2);

      final blob1 = converter.toBlob(rfwtxt1);
      final blob2 = converter.toBlob(rfwtxt2);

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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('set state.active = true'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('event "button.click" {}'));
      expect(rfwtxt, contains('import material;'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('import material;'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('set state.sliderValue = args.value'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('import material;'));
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('Rotation('));
      expect(rfwtxt, contains('turns: 0.25'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('Scale('));
      expect(rfwtxt, contains('scale: 2.0'));
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('SizedBoxShrink widget emits SizedBoxShrink(', () {
      const input = '''
Widget build() {
  return SizedBoxShrink();
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('SizedBoxShrink('));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('AnimationDefaults('));
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('AnimatedPadding uses core.widgets import and emits padding/duration params', () {
      const input = '''
Widget build() {
  return AnimatedPadding(
    padding: EdgeInsets.all(16.0),
    duration: Duration(milliseconds: 300),
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('Padding('));
      expect(rfwtxt, contains('padding:'));
      expect(rfwtxt, contains('duration: 300'));
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('AnimatedOpacity uses core.widgets import and emits opacity/duration params', () {
      const input = '''
Widget build() {
  return AnimatedOpacity(
    opacity: 0.5,
    duration: Duration(milliseconds: 300),
    child: Container(color: Color(0xFF000000)),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('Opacity('));
      expect(rfwtxt, contains('opacity: 0.5'));
      expect(rfwtxt, contains('duration: 300'));
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('PositionedDirectional uses core.widgets import and emits top/end params', () {
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('Positioned('));
      expect(rfwtxt, contains('end: 20.0'));
      final library = parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('data.user.name'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
    });

    test('ArgsRef produces parseable rfwtxt', () {
      const source = '''
Widget buildCard() {
  return Text(ArgsRef('item.title'));
}
''';
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('args.item.title'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('...for item in data.items:'));
      expect(rfwtxt, contains('item.name'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('switch state.active'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
    });

    test('RfwConcat produces parseable rfwtxt', () {
      const source = '''
Widget buildGreeting() {
  return Text(RfwConcat(['Hello, ', DataRef('name'), '!']));
}
''';
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('"Hello, "'));
      expect(rfwtxt, contains('data.name'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('widget toggle { down: false }'));
      expect(rfwtxt, contains('set state.down = true'));
      expect(rfwtxt, contains('set state.down = false'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('event "shop.purchase"'));
      expect(rfwtxt, contains('args.product.id'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
    });

    test('complex: RfwFor + DataRef inside Column produces parseable rfwtxt', () {
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
      final rfwtxt = converter.convertFromSource(source);
      expect(rfwtxt, contains('data.header'));
      expect(rfwtxt, contains('...for entry in data.feed.items:'));
      expect(rfwtxt, contains('entry.title'));
      expect(() => parseLibraryFile(rfwtxt), returnsNormally);
    });
  });

  group('custom widget support', () {
    late RfwConverter converter;

    setUp(() {
      final registry = WidgetRegistry.core();
      registry.registerFromConfig({
        'MystiqueText': {'import': 'mystique.widgets'},
        'NullConditionalWidget': {
          'import': 'custom.widgets',
          'child_type': 'optionalChild',
        },
        'SZSBounceTapper': {
          'import': 'custom.widgets',
          'child_type': 'optionalChild',
          'handlers': ['onTap'],
        },
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
      });
      converter = RfwConverter(registry: registry);
    });

    test('simple custom widget with pass-through params', () {
      const input = '''
Widget build() {
  return MystiqueText(text: 'hello', fontType: 'heading24Bold', color: 0xFF141618);
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import mystique.widgets;'));
      expect(rfwtxt, contains('MystiqueText('));
      expect(rfwtxt, contains('text: "hello"'));
      expect(rfwtxt, contains('fontType: "heading24Bold"'));
      expect(rfwtxt, contains('color: 0xFF141618'));
      parseLibraryFile(rfwtxt);
    });

    test('custom widget nested inside core widget generates both imports', () {
      const input = '''
Widget build() {
  return Container(
    child: MystiqueText(text: 'hello'),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import core.widgets;'));
      expect(rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('nullChild: MystiqueText('));
      expect(rfwtxt, contains('import custom.widgets;'));
      expect(rfwtxt, contains('import mystique.widgets;'));
      parseLibraryFile(rfwtxt);
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
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('onTap: event "navigate"'));
      expect(rfwtxt, contains('url: "szsapp://home"'));
      parseLibraryFile(rfwtxt);
    });

    test('only used imports are generated', () {
      const input = '''
Widget build() {
  return MystiqueText(text: 'hello');
}
''';
      final rfwtxt = converter.convertFromSource(input);
      expect(rfwtxt, contains('import mystique.widgets;'));
      expect(rfwtxt, isNot(contains('import core.widgets;')));
      parseLibraryFile(rfwtxt);
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
  });
}
