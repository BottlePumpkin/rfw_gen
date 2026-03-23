import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

FunctionDeclaration parseFunction(String source) {
  final result = parseString(content: source);
  return result.unit.declarations.whereType<FunctionDeclaration>().first;
}

void main() {
  late WidgetRegistry registry;
  late ExpressionConverter expressionConverter;
  late WidgetAstVisitor visitor;

  setUp(() {
    registry = WidgetRegistry.core();
    expressionConverter = ExpressionConverter();
    visitor = WidgetAstVisitor(
      registry: registry,
      expressionConverter: expressionConverter,
    );
  });

  group('WidgetAstVisitor', () {
    test('simple Text widget', () {
      final fn = parseFunction('''
Widget build() {
  return Text('Hello');
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Text');
      expect(node.properties, hasLength(1));
      final text = node.properties['text'] as IrStringValue;
      expect(text.value, 'Hello');
    });

    test('Column with children list', () {
      final fn = parseFunction('''
Widget build() {
  return Column(
    children: [
      Text('A'),
      Text('B'),
    ],
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Column');
      final children = node.properties['children'] as IrListValue;
      expect(children.values, hasLength(2));

      final first = children.values[0] as IrWidgetNode;
      expect(first.name, 'Text');
      expect((first.properties['text'] as IrStringValue).value, 'A');

      final second = children.values[1] as IrWidgetNode;
      expect(second.name, 'Text');
      expect((second.properties['text'] as IrStringValue).value, 'B');
    });

    test('Container with child and color', () {
      final fn = parseFunction('''
Widget build() {
  return Container(
    color: Color(0xFF00FF00),
    child: Text('Inside'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Container');
      final color = node.properties['color'] as IrIntValue;
      expect(color.value, 0xFF00FF00);

      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Inside');
    });

    test('SizedBox with width and height', () {
      final fn = parseFunction('''
Widget build() {
  return SizedBox(width: 100.0, height: 50.0);
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'SizedBox');
      final width = node.properties['width'] as IrNumberValue;
      expect(width.value, 100.0);
      final height = node.properties['height'] as IrNumberValue;
      expect(height.value, 50.0);
    });

    test('Row with mainAxisAlignment enum', () {
      final fn = parseFunction('''
Widget build() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('X')],
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Row');
      final alignment = node.properties['mainAxisAlignment'] as IrEnumValue;
      expect(alignment.value, 'center');

      final children = node.properties['children'] as IrListValue;
      expect(children.values, hasLength(1));
    });

    test('arrow function body', () {
      final fn = parseFunction('''
Widget build() => Text('Hello');
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Text');
      expect((node.properties['text'] as IrStringValue).value, 'Hello');
    });

    test('nested Container > Column > [Text, SizedBox, Text]', () {
      final fn = parseFunction('''
Widget build() {
  return Container(
    child: Column(
      children: [
        Text('First'),
        SizedBox(height: 8.0),
        Text('Last'),
      ],
    ),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Container');
      final column = node.properties['child'] as IrWidgetNode;
      expect(column.name, 'Column');

      final children = column.properties['children'] as IrListValue;
      expect(children.values, hasLength(3));

      final first = children.values[0] as IrWidgetNode;
      expect(first.name, 'Text');
      expect((first.properties['text'] as IrStringValue).value, 'First');

      final sizedBox = children.values[1] as IrWidgetNode;
      expect(sizedBox.name, 'SizedBox');
      expect((sizedBox.properties['height'] as IrNumberValue).value, 8.0);

      final last = children.values[2] as IrWidgetNode;
      expect(last.name, 'Text');
      expect((last.properties['text'] as IrStringValue).value, 'Last');
    });

    test('throws on unsupported widget', () {
      final fn = parseFunction('''
Widget build() {
  return GestureDetector();
}
''');

      expect(
        () => visitor.extractWidgetTree(fn),
        throwsA(isA<UnsupportedWidgetError>()),
      );
    });

    test('throws when no return expression found', () {
      final fn = parseFunction('''
void doNothing() {
  print('hello');
}
''');

      expect(
        () => visitor.extractWidgetTree(fn),
        throwsStateError,
      );
    });

    test('positional argument for Text is mapped to text property', () {
      final fn = parseFunction('''
Widget build() {
  return Text('World');
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.properties.containsKey('text'), isTrue);
      expect((node.properties['text'] as IrStringValue).value, 'World');
    });

    test('unknown named arguments are silently skipped', () {
      final fn = parseFunction('''
Widget build() {
  return Text('Hi', key: someKey);
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Text');
      // 'key' is not in the mapping and someKey is unsupported,
      // so it should be silently skipped
      expect(node.properties, hasLength(1));
      expect(node.properties.containsKey('text'), isTrue);
    });
  });
}
