import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  late RfwtxtEmitter emitter;

  setUp(() {
    emitter = RfwtxtEmitter();
  });

  group('RfwtxtEmitter', () {
    // Test 1: Simple Text widget
    test('simple Text widget emits import, declaration, and string value', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('Hello')},
      );

      final result = emitter.emit(
        widgetName: 'greeting',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('import core.widgets;'));
      expect(result, contains('widget greeting = Text('));
      expect(result, contains('text: "Hello"'));
      expect(result, endsWith(');\n'));
    });

    // Test 2: Column with children list
    test('Column with children list emits multi-line children', () {
      final root = IrWidgetNode(
        name: 'Column',
        properties: {
          'children': IrListValue([
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrStringValue('First')},
            ),
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrStringValue('Second')},
            ),
          ]),
        },
      );

      final result = emitter.emit(
        widgetName: 'myColumn',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('widget myColumn = Column('));
      expect(result, contains('children: ['));
      expect(result, contains('Text('));
      expect(result, contains('"First"'));
      expect(result, contains('"Second"'));
      // children list is multi-line (contains widget nodes)
      final childrenBlock = result.substring(result.indexOf('children:'));
      expect(childrenBlock, contains('\n'));
    });

    // Test 3: Integer values (colors)
    test('integer color value emits uppercase hex with 8 chars padded', () {
      final root = IrWidgetNode(
        name: 'Container',
        properties: {'color': IrIntValue(0xFF2196F3)},
      );

      final result = emitter.emit(
        widgetName: 'myContainer',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('color: 0xFF2196F3'));
    });

    test('integer zero emits 0x00000000', () {
      final root = IrWidgetNode(
        name: 'Container',
        properties: {'color': IrIntValue(0)},
      );

      final result = emitter.emit(
        widgetName: 'myContainer',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('color: 0x00000000'));
    });

    // Test 4: Number values
    test('whole number double emits with .0 suffix', () {
      final root = IrWidgetNode(
        name: 'SizedBox',
        properties: {
          'width': IrNumberValue(100.0),
          'height': IrNumberValue(50.0),
        },
      );

      final result = emitter.emit(
        widgetName: 'myBox',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('width: 100.0'));
      expect(result, contains('height: 50.0'));
    });

    test('fractional number emits correctly', () {
      final root = IrWidgetNode(
        name: 'SizedBox',
        properties: {'width': IrNumberValue(3.14)},
      );

      final result = emitter.emit(
        widgetName: 'myBox',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('width: 3.14'));
    });

    // Test 5: Enum values
    test('enum value emits as quoted string', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {
          'textAlign': IrEnumValue('center'),
        },
      );

      final result = emitter.emit(
        widgetName: 'myText',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('textAlign: "center"'));
    });

    // Test 6: Short list (EdgeInsets-like, all primitives, ≤4 items)
    test('short primitive list (≤4) emits inline', () {
      final root = IrWidgetNode(
        name: 'Padding',
        properties: {
          'padding': IrListValue([IrNumberValue(16.0)]),
        },
      );

      final result = emitter.emit(
        widgetName: 'myPadding',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('padding: [16.0]'));
    });

    test('short primitive list with multiple values emits inline', () {
      final root = IrWidgetNode(
        name: 'Padding',
        properties: {
          'padding': IrListValue([
            IrNumberValue(16.0),
            IrNumberValue(8.0),
          ]),
        },
      );

      final result = emitter.emit(
        widgetName: 'myPadding',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('padding: [16.0, 8.0]'));
    });

    test('long primitive list (>4 items) emits multi-line', () {
      final root = IrWidgetNode(
        name: 'Widget',
        properties: {
          'values': IrListValue([
            IrNumberValue(1.0),
            IrNumberValue(2.0),
            IrNumberValue(3.0),
            IrNumberValue(4.0),
            IrNumberValue(5.0),
          ]),
        },
      );

      final result = emitter.emit(
        widgetName: 'myWidget',
        root: root,
        imports: {'core.widgets'},
      );

      // Should be multi-line
      final valuesBlock = result.substring(result.indexOf('values:'));
      final closingBracket = valuesBlock.indexOf(']');
      final block = valuesBlock.substring(0, closingBracket + 1);
      expect(block, contains('\n'));
    });

    // Test 7: Map values (TextStyle)
    test('map value emits multi-line', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {
          'style': IrMapValue({
            'fontSize': IrNumberValue(24.0),
            'color': IrIntValue(0xFF000000),
          }),
        },
      );

      final result = emitter.emit(
        widgetName: 'myText',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('style: {'));
      expect(result, contains('fontSize: 24.0'));
      expect(result, contains('color: 0xFF000000'));
      expect(result, contains('}'));
    });

    // Test 8: Boolean values
    test('boolean true emits true', () {
      final root = IrWidgetNode(
        name: 'Switch',
        properties: {'value': IrBoolValue(true)},
      );

      final result = emitter.emit(
        widgetName: 'mySwitch',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('value: true'));
    });

    test('boolean false emits false', () {
      final root = IrWidgetNode(
        name: 'Switch',
        properties: {'value': IrBoolValue(false)},
      );

      final result = emitter.emit(
        widgetName: 'mySwitch',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('value: false'));
    });

    // Test 9: Nested widgets (Container with child)
    test('Container with nested child widget emits correctly', () {
      final root = IrWidgetNode(
        name: 'Container',
        properties: {
          'child': IrWidgetNode(
            name: 'Text',
            properties: {'text': IrStringValue('Nested')},
          ),
        },
      );

      final result = emitter.emit(
        widgetName: 'myContainer',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('widget myContainer = Container('));
      expect(result, contains('child: Text('));
      expect(result, contains('"Nested"'));
    });

    // Additional tests for string escaping
    test('string with backslash is escaped', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue(r'hello\world')},
      );

      final result = emitter.emit(
        widgetName: 'myText',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains(r'text: "hello\\world"'));
    });

    test('string with double quote is escaped', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('say "hi"')},
      );

      final result = emitter.emit(
        widgetName: 'myText',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains(r'text: "say \"hi\""'));
    });

    // Multiple imports
    test('multiple imports are emitted in sorted order', () {
      final root = IrWidgetNode(name: 'Text', properties: {});

      final result = emitter.emit(
        widgetName: 'myText',
        root: root,
        imports: {'core.widgets', 'core.material', 'local.components'},
      );

      final lines = result.split('\n');
      final importLines =
          lines.where((l) => l.startsWith('import ')).toList();
      expect(importLines.length, equals(3));
      // They should be sorted
      expect(importLines, equals(importLines.toList()..sort()));
    });

    // Empty properties widget
    test('widget with no properties emits empty parens on same line', () {
      final root = IrWidgetNode(name: 'Spacer', properties: {});

      final result = emitter.emit(
        widgetName: 'mySpacer',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('widget mySpacer = Spacer('));
      expect(result, endsWith(');\n'));
    });

    // Indentation check
    test('widget properties are indented with 2 spaces', () {
      final root = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('Hello')},
      );

      final result = emitter.emit(
        widgetName: 'greeting',
        root: root,
        imports: {'core.widgets'},
      );

      expect(result, contains('  text: "Hello"'));
    });
  });
}
