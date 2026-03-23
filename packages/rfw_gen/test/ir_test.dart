import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('IrStringValue', () {
    test('stores string value', () {
      final v = IrStringValue('hello');
      expect(v.value, equals('hello'));
    });

    test('stores empty string', () {
      final v = IrStringValue('');
      expect(v.value, equals(''));
    });
  });

  group('IrNumberValue', () {
    test('stores double value', () {
      final v = IrNumberValue(3.14);
      expect(v.value, equals(3.14));
    });

    test('stores zero', () {
      final v = IrNumberValue(0.0);
      expect(v.value, equals(0.0));
    });

    test('stores negative value', () {
      final v = IrNumberValue(-1.5);
      expect(v.value, equals(-1.5));
    });
  });

  group('IrIntValue', () {
    test('stores int value', () {
      final v = IrIntValue(42);
      expect(v.value, equals(42));
    });

    test('stores zero', () {
      final v = IrIntValue(0);
      expect(v.value, equals(0));
    });

    test('stores negative int', () {
      final v = IrIntValue(-7);
      expect(v.value, equals(-7));
    });
  });

  group('IrBoolValue', () {
    test('stores true', () {
      final v = IrBoolValue(true);
      expect(v.value, isTrue);
    });

    test('stores false', () {
      final v = IrBoolValue(false);
      expect(v.value, isFalse);
    });
  });

  group('IrEnumValue', () {
    test('stores enum string', () {
      final v = IrEnumValue('TextAlign.center');
      expect(v.value, equals('TextAlign.center'));
    });
  });

  group('IrListValue', () {
    test('stores empty list', () {
      final v = IrListValue([]);
      expect(v.values, isEmpty);
    });

    test('stores list of strings', () {
      final v = IrListValue([IrStringValue('a'), IrStringValue('b')]);
      expect(v.values, hasLength(2));
      expect((v.values[0] as IrStringValue).value, equals('a'));
      expect((v.values[1] as IrStringValue).value, equals('b'));
    });

    test('stores mixed types', () {
      final v = IrListValue([
        IrStringValue('text'),
        IrIntValue(1),
        IrBoolValue(true),
      ]);
      expect(v.values, hasLength(3));
      expect(v.values[0], isA<IrStringValue>());
      expect(v.values[1], isA<IrIntValue>());
      expect(v.values[2], isA<IrBoolValue>());
    });
  });

  group('IrMapValue', () {
    test('stores empty map', () {
      final v = IrMapValue({});
      expect(v.entries, isEmpty);
    });

    test('stores string entries', () {
      final v = IrMapValue({'key': IrStringValue('val')});
      expect(v.entries['key'], isA<IrStringValue>());
      expect((v.entries['key']! as IrStringValue).value, equals('val'));
    });

    test('stores mixed type entries', () {
      final v = IrMapValue({
        'name': IrStringValue('Alice'),
        'age': IrIntValue(30),
        'active': IrBoolValue(true),
      });
      expect(v.entries, hasLength(3));
      expect(v.entries['name'], isA<IrStringValue>());
      expect(v.entries['age'], isA<IrIntValue>());
      expect(v.entries['active'], isA<IrBoolValue>());
    });
  });

  group('IrWidgetNode', () {
    test('stores widget name', () {
      final node = IrWidgetNode(name: 'Text');
      expect(node.name, equals('Text'));
    });

    test('defaults to empty properties', () {
      final node = IrWidgetNode(name: 'Container');
      expect(node.properties, isEmpty);
    });

    test('stores simple properties', () {
      final node = IrWidgetNode(
        name: 'Text',
        properties: {
          'text': IrStringValue('Hello'),
          'maxLines': IrIntValue(2),
        },
      );
      expect(node.properties['text'], isA<IrStringValue>());
      expect((node.properties['text']! as IrStringValue).value, equals('Hello'));
      expect(node.properties['maxLines'], isA<IrIntValue>());
    });

    test('stores nested children — Column with two Text widgets', () {
      final textA = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('First')},
      );
      final textB = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('Second')},
      );
      final column = IrWidgetNode(
        name: 'Column',
        properties: {
          'children': IrListValue([textA, textB]),
        },
      );

      expect(column.name, equals('Column'));
      final children = column.properties['children']! as IrListValue;
      expect(children.values, hasLength(2));

      final first = children.values[0] as IrWidgetNode;
      expect(first.name, equals('Text'));
      expect((first.properties['text']! as IrStringValue).value, equals('First'));

      final second = children.values[1] as IrWidgetNode;
      expect(second.name, equals('Text'));
      expect((second.properties['text']! as IrStringValue).value, equals('Second'));
    });

    test('is an IrValue', () {
      final node = IrWidgetNode(name: 'Foo');
      expect(node, isA<IrValue>());
    });
  });

  group('IrSetStateValue', () {
    test('stores field and value', () {
      final v = IrSetStateValue('pressed', IrBoolValue(true));
      expect(v.field, equals('pressed'));
      expect(v.value, isA<IrBoolValue>());
    });
  });

  group('IrSetStateFromArgValue', () {
    test('stores field and argName', () {
      final v = IrSetStateFromArgValue('sliderValue', 'value');
      expect(v.field, equals('sliderValue'));
      expect(v.argName, equals('value'));
    });

    test('defaults argName to value', () {
      final v = IrSetStateFromArgValue('amount');
      expect(v.argName, equals('value'));
    });
  });

  group('IrEventValue', () {
    test('stores name and empty args', () {
      final v = IrEventValue('button.click');
      expect(v.name, equals('button.click'));
      expect(v.args, isEmpty);
    });

    test('stores name and args', () {
      final v = IrEventValue('cart.add', {'itemId': IrIntValue(42)});
      expect(v.name, equals('cart.add'));
      expect(v.args, hasLength(1));
    });
  });

  group('IrValue sealed hierarchy', () {
    test('each subtype is an IrValue', () {
      final values = <IrValue>[
        IrStringValue('s'),
        IrNumberValue(1.0),
        IrIntValue(1),
        IrBoolValue(false),
        IrEnumValue('E.v'),
        IrListValue([]),
        IrMapValue({}),
        IrWidgetNode(name: 'W'),
        IrSetStateValue('f', IrBoolValue(true)),
        IrSetStateFromArgValue('f'),
        IrEventValue('e'),
      ];
      for (final v in values) {
        expect(v, isA<IrValue>());
      }
    });
  });
}
