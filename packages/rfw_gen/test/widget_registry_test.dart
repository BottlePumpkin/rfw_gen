import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('ChildType', () {
    test('has four values', () {
      expect(ChildType.values, hasLength(4));
    });

    test('contains none, child, optionalChild, childList', () {
      expect(ChildType.values, containsAll([
        ChildType.none,
        ChildType.child,
        ChildType.optionalChild,
        ChildType.childList,
      ]));
    });
  });

  group('ParamMapping', () {
    test('stores rfwName and null transformer', () {
      const p = ParamMapping('myParam');
      expect(p.rfwName, equals('myParam'));
      expect(p.transformer, isNull);
    });

    test('stores rfwName and transformer', () {
      const p = ParamMapping('myParam', transformer: 'textStyle');
      expect(p.rfwName, equals('myParam'));
      expect(p.transformer, equals('textStyle'));
    });

    test('ParamMapping.direct sets rfwName and null transformer', () {
      const p = ParamMapping.direct('someParam');
      expect(p.rfwName, equals('someParam'));
      expect(p.transformer, isNull);
    });
  });

  group('WidgetMapping', () {
    test('stores all fields with defaults', () {
      const m = WidgetMapping(
        rfwName: 'core.Text',
        params: {},
        import: 'core.widgets',
      );
      expect(m.rfwName, equals('core.Text'));
      expect(m.params, isEmpty);
      expect(m.positionalParam, isNull);
      expect(m.childType, equals(ChildType.none));
      expect(m.childParam, isNull);
      expect(m.import, equals('core.widgets'));
    });

    test('stores positionalParam when provided', () {
      const m = WidgetMapping(
        rfwName: 'core.Text',
        params: {},
        import: 'core.widgets',
        positionalParam: 'text',
      );
      expect(m.positionalParam, equals('text'));
    });

    test('stores childType and childParam when provided', () {
      const m = WidgetMapping(
        rfwName: 'core.Column',
        params: {},
        import: 'core.widgets',
        childType: ChildType.childList,
        childParam: 'children',
      );
      expect(m.childType, equals(ChildType.childList));
      expect(m.childParam, equals('children'));
    });
  });

  group('WidgetRegistry.core()', () {
    late WidgetRegistry registry;

    setUp(() {
      registry = WidgetRegistry.core();
    });

    test('contains exactly 5 widgets', () {
      expect(registry.supportedWidgets, hasLength(5));
    });

    test('supports Text, Column, Row, Container, SizedBox', () {
      expect(registry.isSupported('Text'), isTrue);
      expect(registry.isSupported('Column'), isTrue);
      expect(registry.isSupported('Row'), isTrue);
      expect(registry.isSupported('Container'), isTrue);
      expect(registry.isSupported('SizedBox'), isTrue);
    });

    test('returns false for unknown widget', () {
      expect(registry.isSupported('UnknownWidget'), isFalse);
      expect(registry.isSupported('Scaffold'), isFalse);
      expect(registry.isSupported(''), isFalse);
    });

    group('Text mapping', () {
      late WidgetMapping text;

      setUp(() {
        text = registry.supportedWidgets['Text']!;
      });

      test('has positionalParam "text"', () {
        expect(text.positionalParam, equals('text'));
      });

      test('has childType none', () {
        expect(text.childType, equals(ChildType.none));
      });

      test('has style param with textStyle transformer', () {
        expect(text.params.containsKey('style'), isTrue);
        expect(text.params['style']!.transformer, equals('textStyle'));
      });

      test('has textAlign param with enum transformer', () {
        expect(text.params.containsKey('textAlign'), isTrue);
        expect(text.params['textAlign']!.transformer, equals('enum'));
      });

      test('has maxLines param as direct', () {
        expect(text.params.containsKey('maxLines'), isTrue);
        expect(text.params['maxLines']!.transformer, isNull);
      });

      test('has overflow param with enum transformer', () {
        expect(text.params.containsKey('overflow'), isTrue);
        expect(text.params['overflow']!.transformer, equals('enum'));
      });

      test('has softWrap param as direct', () {
        expect(text.params.containsKey('softWrap'), isTrue);
        expect(text.params['softWrap']!.transformer, isNull);
      });

      test('import is core.widgets', () {
        expect(text.import, equals('core.widgets'));
      });
    });

    group('Column mapping', () {
      late WidgetMapping column;

      setUp(() {
        column = registry.supportedWidgets['Column']!;
      });

      test('has childType childList', () {
        expect(column.childType, equals(ChildType.childList));
      });

      test('has childParam "children"', () {
        expect(column.childParam, equals('children'));
      });

      test('has no positionalParam', () {
        expect(column.positionalParam, isNull);
      });

      test('has mainAxisAlignment param with enum transformer', () {
        expect(column.params.containsKey('mainAxisAlignment'), isTrue);
        expect(column.params['mainAxisAlignment']!.transformer, equals('enum'));
      });

      test('has mainAxisSize param with enum transformer', () {
        expect(column.params.containsKey('mainAxisSize'), isTrue);
        expect(column.params['mainAxisSize']!.transformer, equals('enum'));
      });

      test('has crossAxisAlignment param with enum transformer', () {
        expect(column.params.containsKey('crossAxisAlignment'), isTrue);
        expect(column.params['crossAxisAlignment']!.transformer, equals('enum'));
      });

      test('has verticalDirection param with enum transformer', () {
        expect(column.params.containsKey('verticalDirection'), isTrue);
        expect(column.params['verticalDirection']!.transformer, equals('enum'));
      });

      test('import is core.widgets', () {
        expect(column.import, equals('core.widgets'));
      });
    });

    group('Row mapping', () {
      late WidgetMapping row;

      setUp(() {
        row = registry.supportedWidgets['Row']!;
      });

      test('has childType childList', () {
        expect(row.childType, equals(ChildType.childList));
      });

      test('has childParam "children"', () {
        expect(row.childParam, equals('children'));
      });

      test('has no positionalParam', () {
        expect(row.positionalParam, isNull);
      });

      test('has mainAxisAlignment param with enum transformer', () {
        expect(row.params.containsKey('mainAxisAlignment'), isTrue);
        expect(row.params['mainAxisAlignment']!.transformer, equals('enum'));
      });

      test('has mainAxisSize param with enum transformer', () {
        expect(row.params.containsKey('mainAxisSize'), isTrue);
        expect(row.params['mainAxisSize']!.transformer, equals('enum'));
      });

      test('has crossAxisAlignment param with enum transformer', () {
        expect(row.params.containsKey('crossAxisAlignment'), isTrue);
        expect(row.params['crossAxisAlignment']!.transformer, equals('enum'));
      });

      test('has verticalDirection param with enum transformer', () {
        expect(row.params.containsKey('verticalDirection'), isTrue);
        expect(row.params['verticalDirection']!.transformer, equals('enum'));
      });

      test('import is core.widgets', () {
        expect(row.import, equals('core.widgets'));
      });
    });

    group('Container mapping', () {
      late WidgetMapping container;

      setUp(() {
        container = registry.supportedWidgets['Container']!;
      });

      test('has childType optionalChild', () {
        expect(container.childType, equals(ChildType.optionalChild));
      });

      test('has childParam "child"', () {
        expect(container.childParam, equals('child'));
      });

      test('has no positionalParam', () {
        expect(container.positionalParam, isNull);
      });

      test('has color param with color transformer', () {
        expect(container.params.containsKey('color'), isTrue);
        expect(container.params['color']!.transformer, equals('color'));
      });

      test('has padding param with edgeInsets transformer', () {
        expect(container.params.containsKey('padding'), isTrue);
        expect(container.params['padding']!.transformer, equals('edgeInsets'));
      });

      test('has margin param with edgeInsets transformer', () {
        expect(container.params.containsKey('margin'), isTrue);
        expect(container.params['margin']!.transformer, equals('edgeInsets'));
      });

      test('has width param as direct', () {
        expect(container.params.containsKey('width'), isTrue);
        expect(container.params['width']!.transformer, isNull);
      });

      test('has height param as direct', () {
        expect(container.params.containsKey('height'), isTrue);
        expect(container.params['height']!.transformer, isNull);
      });

      test('has alignment param with alignment transformer', () {
        expect(container.params.containsKey('alignment'), isTrue);
        expect(container.params['alignment']!.transformer, equals('alignment'));
      });

      test('has decoration param with boxDecoration transformer', () {
        expect(container.params.containsKey('decoration'), isTrue);
        expect(container.params['decoration']!.transformer, equals('boxDecoration'));
      });

      test('import is core.widgets', () {
        expect(container.import, equals('core.widgets'));
      });
    });

    group('SizedBox mapping', () {
      late WidgetMapping sizedBox;

      setUp(() {
        sizedBox = registry.supportedWidgets['SizedBox']!;
      });

      test('has childType optionalChild', () {
        expect(sizedBox.childType, equals(ChildType.optionalChild));
      });

      test('has childParam "child"', () {
        expect(sizedBox.childParam, equals('child'));
      });

      test('has no positionalParam', () {
        expect(sizedBox.positionalParam, isNull);
      });

      test('has width param as direct', () {
        expect(sizedBox.params.containsKey('width'), isTrue);
        expect(sizedBox.params['width']!.transformer, isNull);
      });

      test('has height param as direct', () {
        expect(sizedBox.params.containsKey('height'), isTrue);
        expect(sizedBox.params['height']!.transformer, isNull);
      });

      test('import is core.widgets', () {
        expect(sizedBox.import, equals('core.widgets'));
      });
    });
  });

  group('WidgetRegistry.register()', () {
    test('adds a custom widget to the registry', () {
      final registry = WidgetRegistry.core();
      const customMapping = WidgetMapping(
        rfwName: 'custom.MyWidget',
        params: {},
        import: 'custom.widgets',
      );

      registry.register('MyWidget', customMapping);

      expect(registry.isSupported('MyWidget'), isTrue);
      expect(registry.supportedWidgets['MyWidget'], equals(customMapping));
    });

    test('registry grows by one after register', () {
      final registry = WidgetRegistry.core();
      final beforeCount = registry.supportedWidgets.length;

      registry.register('NewWidget', const WidgetMapping(
        rfwName: 'core.NewWidget',
        params: {},
        import: 'core.widgets',
      ));

      expect(registry.supportedWidgets.length, equals(beforeCount + 1));
    });

    test('register overwrites existing mapping', () {
      final registry = WidgetRegistry.core();
      const newTextMapping = WidgetMapping(
        rfwName: 'custom.Text',
        params: {},
        import: 'custom.widgets',
        positionalParam: 'content',
      );

      registry.register('Text', newTextMapping);

      expect(registry.supportedWidgets['Text']!.rfwName, equals('custom.Text'));
      expect(registry.supportedWidgets['Text']!.positionalParam, equals('content'));
    });
  });

  group('WidgetRegistry default constructor', () {
    test('creates empty registry', () {
      final registry = WidgetRegistry();
      expect(registry.supportedWidgets, isEmpty);
    });

    test('isSupported returns false on empty registry', () {
      final registry = WidgetRegistry();
      expect(registry.isSupported('Text'), isFalse);
    });
  });
}
