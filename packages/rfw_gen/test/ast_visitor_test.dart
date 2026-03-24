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

    // -----------------------------------------------------------------
    // Widget-value param auto-detection
    // -----------------------------------------------------------------

    test('widget-value param: unknown param with registered widget is converted', () {
      // Register a custom widget with optionalChild that has a non-standard widget param
      registry.register('ConditionalWidget', const WidgetMapping(
        rfwName: 'ConditionalWidget',
        import: 'custom.widgets',
        childType: ChildType.optionalChild,
        childParam: 'child',
        params: {},
      ));
      visitor = WidgetAstVisitor(
        registry: registry,
        expressionConverter: expressionConverter,
      );

      final fn = parseFunction('''
Widget build() {
  return ConditionalWidget(
    child: Text('visible'),
    nullChild: Text('fallback'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'ConditionalWidget');
      expect(node.properties['child'], isA<IrWidgetNode>());
      expect(node.properties['nullChild'], isA<IrWidgetNode>());
      final nullChild = node.properties['nullChild'] as IrWidgetNode;
      expect(nullChild.name, 'Text');
    });

    test('widget-value param: deeply nested widget-value params are converted', () {
      registry.register('Outer', const WidgetMapping(
        rfwName: 'Outer',
        import: 'custom.widgets',
        childType: ChildType.none,
        params: {},
      ));
      registry.register('Inner', const WidgetMapping(
        rfwName: 'Inner',
        import: 'custom.widgets',
        childType: ChildType.none,
        params: {},
      ));
      visitor = WidgetAstVisitor(
        registry: registry,
        expressionConverter: expressionConverter,
      );

      final fn = parseFunction('''
Widget build() {
  return Outer(
    slot: Inner(label: 'hello'),
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      final slot = node.properties['slot'] as IrWidgetNode;
      expect(slot.name, 'Inner');
      expect((slot.properties['label'] as IrStringValue).value, 'hello');
    });

    test('widget-value param: non-widget unknown params still pass through', () {
      registry.register('MyWidget', const WidgetMapping(
        rfwName: 'MyWidget',
        import: 'custom.widgets',
        childType: ChildType.none,
        params: {},
      ));
      visitor = WidgetAstVisitor(
        registry: registry,
        expressionConverter: expressionConverter,
      );

      final fn = parseFunction('''
Widget build() {
  return MyWidget(
    title: 'hello',
    count: 42,
    active: true,
  );
}
''');

      final node = visitor.extractWidgetTree(fn);
      expect(node.name, 'MyWidget');
      expect((node.properties['title'] as IrStringValue).value, 'hello');
      expect((node.properties['count'] as IrIntValue).value, 42);
      expect((node.properties['active'] as IrBoolValue).value, true);
    });

    // -----------------------------------------------------------------
    // Dynamic feature recognition: RfwFor, RfwSwitch, DataRef
    // -----------------------------------------------------------------

    test('converts RfwFor in children list', () {
      final fn = parseFunction('''
Widget build() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Text('hello'),
      ),
    ],
  );
}
''');
      final node = visitor.extractWidgetTree(fn);
      final children = node.properties['children'] as IrListValue;
      expect(children.values.first, isA<IrForLoop>());
      final loop = children.values.first as IrForLoop;
      expect(loop.items, isA<IrDataRef>());
      expect(loop.itemName, 'item');
      expect(loop.body, isA<IrWidgetNode>());
      expect(loop.body.name, 'Text');
    });

    test('converts RfwSwitch in child position', () {
      final fn = parseFunction('''
Widget build() {
  return Container(
    child: RfwSwitch(
      value: DataRef('status'),
      cases: {
        'active': SizedBox(),
      },
      defaultCase: SizedBox(),
    ),
  );
}
''');
      final node = visitor.extractWidgetTree(fn);
      expect(node.properties['child'], isA<IrSwitchExpr>());
      final sw = node.properties['child'] as IrSwitchExpr;
      expect(sw.value, isA<IrDataRef>());
      expect(sw.cases, hasLength(1));
      expect(sw.defaultCase, isA<IrWidgetNode>());
    });

    test('converts DataRef as pass-through param', () {
      final fn = parseFunction('''
Widget build() {
  return Container(
    color: DataRef('theme.primary'),
  );
}
''');
      final node = visitor.extractWidgetTree(fn);
      expect(node.properties['color'], isA<IrDataRef>());
      expect((node.properties['color'] as IrDataRef).path, 'theme.primary');
    });

    test('nested RfwFor containing RfwSwitch', () {
      final fn = parseFunction('''
Widget build() {
  return Column(
    children: [
      RfwFor(
        items: DataRef('items'),
        itemName: 'item',
        builder: (item) => Container(
          child: RfwSwitch(
            value: DataRef('mode'),
            cases: {
              'a': Text('A'),
            },
            defaultCase: Text('default'),
          ),
        ),
      ),
    ],
  );
}
''');
      final node = visitor.extractWidgetTree(fn);
      final children = node.properties['children'] as IrListValue;
      final loop = children.values.first as IrForLoop;
      expect(loop.body.name, 'Container');
      // The child of the Container is a RfwSwitch, but _convertWidget
      // is called for the builder body, and Container's child processing
      // uses _convertWidgetOrSpecial.
      expect(loop.body.properties['child'], isA<IrSwitchExpr>());
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

    test('childList non-ListLiteral does not throw and omits children', () {
      final fn = parseFunction('''
Widget build() {
  return Column(
    children: someVariableList,
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'Column');
      // children should be missing because the expression is not a ListLiteral
      expect(node.properties.containsKey('children'), isFalse);
    });

    test('named slot list non-ListLiteral does not throw and omits slot', () {
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
    actions: someVariableList,
  );
}
''');

      final node = visitor.extractWidgetTree(fn);

      expect(node.name, 'AppBar');
      // title should still be present
      expect(node.properties['title'], isA<IrWidgetNode>());
      // actions should be missing because the expression is not a ListLiteral
      expect(node.properties.containsKey('actions'), isFalse);
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
