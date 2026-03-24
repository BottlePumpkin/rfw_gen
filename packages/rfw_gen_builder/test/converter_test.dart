import 'dart:typed_data';

import 'package:rfw_gen/rfw_gen.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:rfw_gen_builder/src/ast_visitor.dart';
import 'package:test/test.dart';

void main() {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  group('RfwConverter.convertFromSource', () {
    test('converts simple Text widget', () {
      const input = "Widget buildGreeting() { return Text('Hello'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('widget greeting = Text('));
      expect(result.rfwtxt, contains('text: "Hello"'));
    });

    test('converts Column with children', () {
      const input = '''
Widget buildMyList() {
  return Column(
    children: [
      Text('First'),
      Text('Second'),
    ],
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('widget myList = Column('));
      expect(result.rfwtxt, contains('text: "First"'));
      expect(result.rfwtxt, contains('text: "Second"'));
    });

    test('converts nested Container > Text with color and padding', () {
      const input = '''
Widget buildCard() {
  return Container(
    color: Color(0xFF42A5F5),
    padding: EdgeInsets.all(16.0),
    child: Text('Inside'),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('widget card = Container('));
      expect(result.rfwtxt, contains('color: 0xFF42A5F5'));
      expect(result.rfwtxt, contains('padding: [16.0]'));
      expect(result.rfwtxt, contains('text: "Inside"'));
    });

    test('extracts custom name from @RfwWidget annotation', () {
      const input = '''
@RfwWidget('myCustomName')
Widget buildSomething() {
  return Text('Annotated');
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget myCustomName = Text('));
      expect(result.rfwtxt, contains('text: "Annotated"'));
    });

    test('converts SizedBox with dimensions', () {
      const input = '''
Widget buildSpacer() {
  return SizedBox(width: 100.0, height: 50.0);
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget spacer = SizedBox('));
      expect(result.rfwtxt, contains('width: 100.0'));
      expect(result.rfwtxt, contains('height: 50.0'));
    });

    test('converts Row with mainAxisAlignment enum', () {
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
      expect(result.rfwtxt, contains('widget toolbar = Row('));
      expect(result.rfwtxt, contains('mainAxisAlignment: "center"'));
    });

    test('throws on unsupported widget', () {
      const input = '''
Widget buildBad() {
  return CupertinoButton(child: Text('hello'));
}
''';
      expect(
        () => converter.convertFromSource(input),
        throwsA(isA<UnsupportedWidgetError>()),
      );
    });

    test('arrow function body works', () {
      const input = "Widget buildArrow() => Text('Arrow');";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget arrow = Text('));
      expect(result.rfwtxt, contains('text: "Arrow"'));
    });

    test('function name fallback without build prefix', () {
      const input = "Widget simple() { return Text('Plain'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget simple = Text('));
      expect(result.rfwtxt, contains('text: "Plain"'));
    });

    test('throws StateError when no function declaration found', () {
      const input = 'var x = 42;';
      expect(
        () => converter.convertFromSource(input),
        throwsStateError,
      );
    });
  });

  group('ConvertResult', () {
    test(
        'convertFromSource returns ConvertResult with no issues for valid input',
        () {
      const input = "Widget buildGreeting() { return Text('Hello'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget greeting'));
      expect(result.issues, isEmpty);
    });

    test('convertFromSource collects warning for unsupported expression', () {
      const input = '''
Widget buildTest() {
  return Container(
    color: someFunction(),
  );
}
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget test'));
      expect(result.issues, hasLength(1));
      expect(result.issues.first.severity, RfwGenSeverity.warning);
      expect(result.issues.first.line, isNotNull);
    });
  });

  group('RfwConverter.toBlob', () {
    test('produces non-empty Uint8List from valid rfwtxt', () {
      const rfwtxt = '''
import core.widgets;

widget greeting = Text(
  text: "Hello"
);
''';
      final blob = converter.toBlob(rfwtxt);
      expect(blob, isA<Uint8List>());
      expect(blob.isNotEmpty, isTrue);
    });

    test('round-trip: source -> rfwtxt -> blob produces valid binary', () {
      const input = "Widget buildGreeting() { return Text('Hello'); }";
      final result = converter.convertFromSource(input);
      final blob = converter.toBlob(result.rfwtxt);
      expect(blob, isA<Uint8List>());
      expect(blob.isNotEmpty, isTrue);
    });
  });

  group('Import collection', () {
    test('core-only widget produces core.widgets import', () {
      const input = "Widget build() { return Text('Hello'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, isNot(contains('import material;')));
    });

    test('collects imports from widgets inside IrForLoop body', () {
      const source = """
@RfwWidget('test')
Widget test() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => ElevatedButton(
          child: Text('hello'),
        ),
      ),
    ],
  );
}
""";
      final converter = RfwConverter(registry: WidgetRegistry.core());
      final result = converter.convertFromSource(source);
      expect(result.rfwtxt, contains('import core.widgets;'));
      expect(result.rfwtxt, contains('import material;'));
    });
  });

  group('State declaration', () {
    test('extracts state from @RfwWidget annotation', () {
      const source = """
@RfwWidget('toggle', state: {'down': false})
Widget toggle() {
  return SizedBox();
}
""";
      final converter = RfwConverter(registry: WidgetRegistry.core());
      final result = converter.convertFromSource(source);
      expect(
          result.rfwtxt, contains('widget toggle { down: false } = SizedBox('));
    });
  });

  group('Widget name extraction', () {
    test('buildGreeting -> greeting', () {
      const input = "Widget buildGreeting() { return Text('hi'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget greeting ='));
    });

    test('buildMyCard -> myCard', () {
      const input = "Widget buildMyCard() { return Text('hi'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget myCard ='));
    });

    test('simple -> simple (no build prefix)', () {
      const input = "Widget simple() { return Text('hi'); }";
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget simple ='));
    });

    test('@RfwWidget annotation takes precedence over function name', () {
      const input = '''
@RfwWidget('override')
Widget buildSomethingElse() { return Text('hi'); }
''';
      final result = converter.convertFromSource(input);
      expect(result.rfwtxt, contains('widget override ='));
    });
  });
}
