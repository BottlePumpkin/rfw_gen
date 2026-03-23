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

    // -----------------------------------------------------------------
    // Handler params and named child slots
    // -----------------------------------------------------------------

    test('extracts handler setState from GestureDetector', () {
      registry.register(
        'GestureDetector',
        const WidgetMapping(
          rfwName: 'core.GestureDetector',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          handlerParams: {'onTap', 'onTapDown', 'onTapUp', 'onLongPress'},
          params: {},
        ),
      );

      final fn = parseFunction('''
Widget build() {
  return GestureDetector(
    onTap: RfwHandler.setState('pressed', true),
    child: Text('Tap'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'GestureDetector');
      final onTap = node.properties['onTap'] as IrSetStateValue;
      expect(onTap.field, 'pressed');
      expect((onTap.value as IrBoolValue).value, true);

      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
    });

    test('extracts handler event from GestureDetector', () {
      registry.register(
        'GestureDetector',
        const WidgetMapping(
          rfwName: 'core.GestureDetector',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          handlerParams: {'onTap', 'onTapDown', 'onTapUp', 'onLongPress'},
          params: {},
        ),
      );

      final fn = parseFunction('''
Widget build() {
  return GestureDetector(
    onLongPress: RfwHandler.event('item.delete'),
    child: Text('Hold'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'GestureDetector');
      final onLongPress = node.properties['onLongPress'] as IrEventValue;
      expect(onLongPress.name, 'item.delete');

      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
    });

    test('extracts Scaffold namedSlots', () {
      registry.register(
        'Scaffold',
        const WidgetMapping(
          rfwName: 'material.Scaffold',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'appBar': false,
            'body': false,
            'floatingActionButton': false,
            'drawer': false,
            'bottomNavigationBar': false,
          },
          params: {
            'backgroundColor':
                ParamMapping('backgroundColor', transformer: 'color'),
          },
        ),
      );
      registry.register(
        'AppBar',
        const WidgetMapping(
          rfwName: 'material.AppBar',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'leading': false,
            'title': false,
            'actions': true,
          },
          params: {},
        ),
      );

      final fn = parseFunction('''
Widget build() {
  return Scaffold(
    appBar: AppBar(title: Text('Title')),
    body: Center(child: Text('Body')),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Scaffold');
      final appBar = node.properties['appBar'] as IrWidgetNode;
      expect(appBar.name, 'AppBar');
      final body = node.properties['body'] as IrWidgetNode;
      expect(body.name, 'Center');
    });

    test('extracts AppBar with actions list slot', () {
      registry.register(
        'AppBar',
        const WidgetMapping(
          rfwName: 'material.AppBar',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'leading': false,
            'title': false,
            'actions': true,
          },
          params: {},
        ),
      );

      final fn = parseFunction('''
Widget build() {
  return AppBar(
    title: Text('Title'),
    actions: [Text('A1'), Text('A2')],
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'AppBar');
      final title = node.properties['title'] as IrWidgetNode;
      expect(title.name, 'Text');
      expect((title.properties['text'] as IrStringValue).value, 'Title');

      final actions = node.properties['actions'] as IrListValue;
      expect(actions.values, hasLength(2));
      expect((actions.values[0] as IrWidgetNode).name, 'Text');
      expect((actions.values[1] as IrWidgetNode).name, 'Text');
    });

    test('extracts ListTile with multiple slots and handler', () {
      registry.register(
        'ListTile',
        const WidgetMapping(
          rfwName: 'material.ListTile',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'leading': false,
            'title': false,
            'subtitle': false,
            'trailing': false,
          },
          handlerParams: {'onTap', 'onLongPress'},
          params: {
            'dense': ParamMapping.direct('dense'),
            'enabled': ParamMapping.direct('enabled'),
            'selected': ParamMapping.direct('selected'),
          },
        ),
      );

      final fn = parseFunction('''
Widget build() {
  return ListTile(
    title: Text('Item'),
    subtitle: Text('Desc'),
    onTap: RfwHandler.event('item.select'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'ListTile');
      final title = node.properties['title'] as IrWidgetNode;
      expect(title.name, 'Text');
      expect((title.properties['text'] as IrStringValue).value, 'Item');

      final subtitle = node.properties['subtitle'] as IrWidgetNode;
      expect(subtitle.name, 'Text');
      expect((subtitle.properties['text'] as IrStringValue).value, 'Desc');

      final onTap = node.properties['onTap'] as IrEventValue;
      expect(onTap.name, 'item.select');
    });

    test('throws on unsupported widget', () {
      final fn = parseFunction('''
Widget build() {
  return CompletelyUnknownWidget();
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

    // ChildType.child — Expanded, Flexible
    test('extracts Expanded with child', () {
      final fn = parseFunction('''
Widget build() {
  return Expanded(flex: 2, child: Text('Content'));
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Expanded');
      final flex = node.properties['flex'] as IrIntValue;
      expect(flex.value, 2);
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Content');
    });

    test('extracts Flexible with child and fit', () {
      final fn = parseFunction('''
Widget build() {
  return Flexible(fit: FlexFit.tight, child: Text('Content'));
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Flexible');
      final fit = node.properties['fit'] as IrEnumValue;
      expect(fit.value, 'tight');
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Content');
    });

    // ChildType.childList — Stack, Wrap, ListView
    test('extracts Stack with children', () {
      final fn = parseFunction('''
Widget build() {
  return Stack(children: [Text('A'), Text('B')]);
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Stack');
      final children = node.properties['children'] as IrListValue;
      expect(children.values, hasLength(2));
      final first = children.values[0] as IrWidgetNode;
      expect(first.name, 'Text');
      expect((first.properties['text'] as IrStringValue).value, 'A');
      final second = children.values[1] as IrWidgetNode;
      expect(second.name, 'Text');
      expect((second.properties['text'] as IrStringValue).value, 'B');
    });

    test('extracts Wrap with spacing', () {
      final fn = parseFunction('''
Widget build() {
  return Wrap(
    spacing: 8.0,
    runSpacing: 4.0,
    children: [Text('A'), Text('B')],
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Wrap');
      final spacing = node.properties['spacing'] as IrNumberValue;
      expect(spacing.value, 8.0);
      final runSpacing = node.properties['runSpacing'] as IrNumberValue;
      expect(runSpacing.value, 4.0);
      final children = node.properties['children'] as IrListValue;
      expect(children.values, hasLength(2));
    });

    test('extracts ListView with padding', () {
      final fn = parseFunction('''
Widget build() {
  return ListView(
    padding: EdgeInsets.all(16),
    children: [Text('Item')],
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'ListView');
      final padding = node.properties['padding'] as IrListValue;
      expect(padding.values, hasLength(1));
      expect((padding.values[0] as IrNumberValue).value, 16.0);
      final children = node.properties['children'] as IrListValue;
      expect(children.values, hasLength(1));
      final item = children.values[0] as IrWidgetNode;
      expect(item.name, 'Text');
      expect((item.properties['text'] as IrStringValue).value, 'Item');
    });

    // ChildType.optionalChild — Opacity, ClipRRect, Padding
    test('extracts Opacity with child', () {
      final fn = parseFunction('''
Widget build() {
  return Opacity(opacity: 0.5, child: Text('Faded'));
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Opacity');
      final opacity = node.properties['opacity'] as IrNumberValue;
      expect(opacity.value, 0.5);
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Faded');
    });

    test('extracts ClipRRect with borderRadius', () {
      final fn = parseFunction('''
Widget build() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Text('Clipped'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'ClipRRect');
      final borderRadius = node.properties['borderRadius'] as IrListValue;
      expect(borderRadius.values, hasLength(1));
      final radiusMap = borderRadius.values[0] as IrMapValue;
      expect((radiusMap.entries['x'] as IrNumberValue).value, 8.0);
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Clipped');
    });

    test('extracts Padding with edgeInsets', () {
      final fn = parseFunction('''
Widget build() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Text('Padded'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Padding');
      final padding = node.properties['padding'] as IrListValue;
      expect(padding.values, hasLength(1));
      expect((padding.values[0] as IrNumberValue).value, 16.0);
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Padded');
    });

    // ChildType.none — Spacer, Placeholder
    test('extracts Spacer with flex', () {
      final fn = parseFunction('''
Widget build() {
  return Spacer(flex: 2);
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Spacer');
      final flex = node.properties['flex'] as IrIntValue;
      expect(flex.value, 2);
    });

    test('extracts Placeholder with color', () {
      final fn = parseFunction('''
Widget build() {
  return Placeholder(color: Color(0xFFFF0000));
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'Placeholder');
      final color = node.properties['color'] as IrIntValue;
      expect(color.value, 0xFFFF0000);
    });

    // Other — SafeArea
    test('extracts SafeArea with boolean params', () {
      final fn = parseFunction('''
Widget build() {
  return SafeArea(left: false, child: Text('Safe'));
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'SafeArea');
      final left = node.properties['left'] as IrBoolValue;
      expect(left.value, false);
      final child = node.properties['child'] as IrWidgetNode;
      expect(child.name, 'Text');
      expect((child.properties['text'] as IrStringValue).value, 'Safe');
    });
  });
}
