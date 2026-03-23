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

    // New type output verification tests
    test('emits IrMapValue with icon and fontFamily (iconData)', () {
      final node = IrWidgetNode(
        name: 'Icon',
        properties: {
          'iconData': IrMapValue({
            'icon': IrIntValue(0xe318),
            'fontFamily': IrStringValue('MaterialIcons'),
          }),
        },
      );
      final output = emitter.emit(
        widgetName: 'test',
        root: node,
        imports: {'core.widgets'},
      );
      expect(output, contains('icon: 0x0000E318'));
      expect(output, contains('fontFamily: "MaterialIcons"'));
    });

    test('emits Duration as integer', () {
      final node = IrWidgetNode(
        name: 'Opacity',
        properties: {
          'opacity': IrNumberValue(0.5),
          'duration': IrIntValue(300),
        },
      );
      final output = emitter.emit(
        widgetName: 'test',
        root: node,
        imports: {'core.widgets'},
      );
      expect(output, contains('duration: 0x0000012C'));
    });

    test('emits Curve as string', () {
      final node = IrWidgetNode(
        name: 'Opacity',
        properties: {
          'opacity': IrNumberValue(0.5),
          'curve': IrStringValue('easeIn'),
        },
      );
      final output = emitter.emit(
        widgetName: 'test',
        root: node,
        imports: {'core.widgets'},
      );
      expect(output, contains('curve: "easeIn"'));
    });

    test('emits BorderRadius as list of radius maps', () {
      final node = IrWidgetNode(
        name: 'ClipRRect',
        properties: {
          'borderRadius': IrListValue([
            IrMapValue({'x': IrNumberValue(8.0)}),
          ]),
        },
      );
      final output = emitter.emit(
        widgetName: 'test',
        root: node,
        imports: {'core.widgets'},
      );
      expect(output, contains('borderRadius:'));
      expect(output, contains('x: 8.0'));
    });

    test('emits ImageProvider as map with source and scale', () {
      final node = IrWidgetNode(
        name: 'Image',
        properties: {
          'imageProvider': IrMapValue({
            'source': IrStringValue('https://example.com/img.png'),
            'scale': IrNumberValue(1.0),
          }),
        },
      );
      final output = emitter.emit(
        widgetName: 'test',
        root: node,
        imports: {'core.widgets'},
      );
      expect(output, contains('source: "https://example.com/img.png"'));
      expect(output, contains('scale: 1.0'));
    });

    // Handler emission tests
    group('Handler emission', () {
      test('emits set state with bool value', () {
        final node = IrWidgetNode(name: 'GestureDetector', properties: {
          'onTap': IrSetStateValue('pressed', IrBoolValue(true)),
        });
        final output = emitter.emit(widgetName: 'test', root: node, imports: {'core.widgets'});
        expect(output, contains('onTap: set state.pressed = true'));
      });

      test('emits set state from arg', () {
        final node = IrWidgetNode(name: 'Slider', properties: {
          'onChanged': IrSetStateFromArgValue('sliderValue'),
        });
        final output = emitter.emit(widgetName: 'test', root: node, imports: {'core.widgets'});
        expect(output, contains('onChanged: set state.sliderValue = args.value'));
      });

      test('emits event without args', () {
        final node = IrWidgetNode(name: 'ElevatedButton', properties: {
          'onPressed': IrEventValue('button.click'),
        });
        final output = emitter.emit(widgetName: 'test', root: node, imports: {'core.widgets'});
        expect(output, contains('onPressed: event "button.click" {}'));
      });

      test('emits event with args', () {
        final node = IrWidgetNode(name: 'GestureDetector', properties: {
          'onTap': IrEventValue('cart.add', {
            'itemId': IrIntValue(42),
            'quantity': IrIntValue(1),
          }),
        });
        final output = emitter.emit(widgetName: 'test', root: node, imports: {'core.widgets'});
        expect(output, contains('event "cart.add"'));
        expect(output, contains('itemId:'));
        expect(output, contains('quantity:'));
      });

      test('emits set state with int value', () {
        final node = IrWidgetNode(name: 'Widget', properties: {
          'onTap': IrSetStateValue('count', IrIntValue(0)),
        });
        final output = emitter.emit(widgetName: 'test', root: node, imports: {'core.widgets'});
        expect(output, contains('set state.count ='));
      });
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

    // Dynamic IR emission tests
    group('Dynamic IR references', () {
      test('IrDataRef emits as data.path', () {
        final node = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrDataRef('user.name')},
        );
        final output = emitter.emit(
          widgetName: 'greeting',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('text: data.user.name'));
      });

      test('IrArgsRef emits as args.path', () {
        final node = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrArgsRef('item.title')},
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('text: args.item.title'));
      });

      test('IrStateRef emits as state.path', () {
        final node = IrWidgetNode(
          name: 'Container',
          properties: {'color': IrStateRef('bgColor')},
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('color: state.bgColor'));
      });

      test('IrLoopVarRef emits path without prefix', () {
        final node = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrLoopVarRef('item.name')},
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('text: item.name'));
        expect(output, isNot(contains('data.item.name')));
        expect(output, isNot(contains('args.item.name')));
        expect(output, isNot(contains('state.item.name')));
      });

      test('IrConcat emits as list literal', () {
        final node = IrWidgetNode(
          name: 'Text',
          properties: {
            'text': IrConcat([
              IrStringValue('Hello, '),
              IrDataRef('user.name'),
              IrStringValue('!'),
            ]),
          },
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('text: ["Hello, ", data.user.name, "!"]'));
      });

      test('IrForLoop emits ...for item in source: body', () {
        final node = IrWidgetNode(
          name: 'Column',
          properties: {
            'children': IrListValue([
              IrForLoop(
                items: IrDataRef('items'),
                itemName: 'item',
                body: IrWidgetNode(
                  name: 'Text',
                  properties: {'text': IrLoopVarRef('item.name')},
                ),
              ),
            ]),
          },
        );
        final output = emitter.emit(
          widgetName: 'myList',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('...for item in data.items:'));
        expect(output, contains('Text('));
        expect(output, contains('item.name'));
      });

      test('IrSwitchExpr with default emits switch block', () {
        final node = IrWidgetNode(
          name: 'Container',
          properties: {
            'color': IrSwitchExpr(
              value: IrDataRef('status'),
              cases: {
                IrStringValue('active'): IrIntValue(0xFF00FF00),
                IrStringValue('inactive'): IrIntValue(0xFFFF0000),
              },
              defaultCase: IrIntValue(0xFF888888),
            ),
          },
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('switch data.status {'));
        expect(output, contains('"active": 0xFF00FF00'));
        expect(output, contains('"inactive": 0xFFFF0000'));
        expect(output, contains('default: 0xFF888888'));
      });

      test('IrSwitchExpr with widget cases emits widget branches', () {
        final node = IrWidgetNode(
          name: 'Container',
          properties: {
            'child': IrSwitchExpr(
              value: IrStateRef('selected'),
              cases: {
                IrBoolValue(true): IrWidgetNode(
                  name: 'Text',
                  properties: {'text': IrStringValue('On')},
                ),
                IrBoolValue(false): IrWidgetNode(
                  name: 'Text',
                  properties: {'text': IrStringValue('Off')},
                ),
              },
            ),
          },
        );
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: node,
          imports: {'core.widgets'},
        );
        expect(output, contains('switch state.selected {'));
        expect(output, contains('true:'));
        expect(output, contains('false:'));
        expect(output, contains('"On"'));
        expect(output, contains('"Off"'));
      });
    });

    // stateDecl tests
    group('stateDecl parameter', () {
      test('emits widget with stateDecl block', () {
        final root = IrWidgetNode(
          name: 'GestureDetector',
          properties: {
            'onTapDown': IrSetStateValue('down', IrBoolValue(true)),
            'onTapUp': IrSetStateValue('down', IrBoolValue(false)),
          },
        );
        final output = emitter.emit(
          widgetName: 'toggle',
          root: root,
          imports: {'core.widgets'},
          stateDecl: {'down': IrBoolValue(false)},
        );
        expect(output, contains('widget toggle { down: false } = '));
      });

      test('stateDecl with multiple fields', () {
        final root = IrWidgetNode(name: 'Container', properties: {});
        final output = emitter.emit(
          widgetName: 'myWidget',
          root: root,
          imports: {'core.widgets'},
          stateDecl: {
            'count': IrIntValue(0),
            'label': IrStringValue('hello'),
          },
        );
        expect(output, contains('widget myWidget {'));
        expect(output, contains('count: 0x00000000'));
        expect(output, contains('label: "hello"'));
        expect(output, contains('} = '));
      });

      test('emit without stateDecl produces unchanged behavior (backward compat)', () {
        final root = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrStringValue('Hello')},
        );
        final output = emitter.emit(
          widgetName: 'greeting',
          root: root,
          imports: {'core.widgets'},
        );
        expect(output, contains('widget greeting = Text('));
        expect(output, isNot(contains('{')));
      });

      test('emit with null stateDecl produces no state block', () {
        final root = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrStringValue('Hello')},
        );
        final output = emitter.emit(
          widgetName: 'greeting',
          root: root,
          imports: {'core.widgets'},
          stateDecl: null,
        );
        expect(output, contains('widget greeting = Text('));
        expect(output, isNot(contains('{')));
      });

      test('emit with empty stateDecl map produces no state block', () {
        final root = IrWidgetNode(
          name: 'Text',
          properties: {'text': IrStringValue('Hello')},
        );
        final output = emitter.emit(
          widgetName: 'greeting',
          root: root,
          imports: {'core.widgets'},
          stateDecl: {},
        );
        expect(output, contains('widget greeting = Text('));
        expect(output, isNot(contains('{')));
      });
    });
  });
}
