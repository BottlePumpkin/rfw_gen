import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('ChildType', () {
    test('has five values', () {
      expect(ChildType.values, hasLength(5));
    });

    test('contains none, child, optionalChild, childList, namedSlots', () {
      expect(ChildType.values, containsAll([
        ChildType.none,
        ChildType.child,
        ChildType.optionalChild,
        ChildType.childList,
        ChildType.namedSlots,
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

    test('contains exactly 38 widgets', () {
      expect(registry.supportedWidgets, hasLength(38));
    });

    test('supports Text, Column, Row, Container, SizedBox, Center', () {
      expect(registry.isSupported('Text'), isTrue);
      expect(registry.isSupported('Column'), isTrue);
      expect(registry.isSupported('Row'), isTrue);
      expect(registry.isSupported('Container'), isTrue);
      expect(registry.isSupported('SizedBox'), isTrue);
      expect(registry.isSupported('Center'), isTrue);
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

    group('Layout widgets', () {
      test('supports all layout widgets', () {
        for (final name in [
          'Align', 'AspectRatio', 'Expanded', 'Flexible', 'FittedBox',
          'FractionallySizedBox', 'IntrinsicHeight', 'IntrinsicWidth',
          'SizedBoxExpand', 'SizedBoxShrink', 'Spacer', 'Stack', 'Wrap',
        ]) {
          expect(registry.isSupported(name), isTrue, reason: '$name not found');
        }
      });

      test('Expanded has child type and flex param', () {
        final w = registry.supportedWidgets['Expanded']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.childParam, equals('child'));
        expect(w.params.containsKey('flex'), isTrue);
      });

      test('Flexible has child type, flex and fit params', () {
        final w = registry.supportedWidgets['Flexible']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('flex'), isTrue);
        expect(w.params.containsKey('fit'), isTrue);
        expect(w.params['fit']!.transformer, equals('enum'));
      });

      test('Stack has childList and alignment params', () {
        final w = registry.supportedWidgets['Stack']!;
        expect(w.childType, equals(ChildType.childList));
        expect(w.childParam, equals('children'));
        expect(w.params.containsKey('alignment'), isTrue);
        expect(w.params['alignment']!.transformer, equals('alignment'));
        expect(w.params.containsKey('fit'), isTrue);
        expect(w.params.containsKey('clipBehavior'), isTrue);
      });

      test('Wrap has childList and spacing params', () {
        final w = registry.supportedWidgets['Wrap']!;
        expect(w.childType, equals(ChildType.childList));
        expect(w.childParam, equals('children'));
        expect(w.params.containsKey('spacing'), isTrue);
        expect(w.params.containsKey('runSpacing'), isTrue);
        expect(w.params.containsKey('direction'), isTrue);
        expect(w.params['direction']!.transformer, equals('enum'));
      });

      test('Align has duration and curve params', () {
        final w = registry.supportedWidgets['Align']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('duration'), isTrue);
        expect(w.params.containsKey('curve'), isTrue);
      });

      test('Spacer has none childType', () {
        final w = registry.supportedWidgets['Spacer']!;
        expect(w.childType, equals(ChildType.none));
        expect(w.params.containsKey('flex'), isTrue);
      });

      test('SizedBoxExpand has no params', () {
        final w = registry.supportedWidgets['SizedBoxExpand']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params, isEmpty);
      });

      test('SizedBoxShrink has no params', () {
        final w = registry.supportedWidgets['SizedBoxShrink']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params, isEmpty);
      });

      test('IntrinsicHeight has no params', () {
        final w = registry.supportedWidgets['IntrinsicHeight']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params, isEmpty);
      });

      test('AspectRatio has aspectRatio param', () {
        final w = registry.supportedWidgets['AspectRatio']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('aspectRatio'), isTrue);
      });

      test('FittedBox has fit and alignment params', () {
        final w = registry.supportedWidgets['FittedBox']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('fit'), isTrue);
        expect(w.params['fit']!.transformer, equals('enum'));
        expect(w.params.containsKey('alignment'), isTrue);
        expect(w.params.containsKey('clipBehavior'), isTrue);
      });

      test('FractionallySizedBox has alignment and factors', () {
        final w = registry.supportedWidgets['FractionallySizedBox']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('alignment'), isTrue);
        expect(w.params.containsKey('widthFactor'), isTrue);
        expect(w.params.containsKey('heightFactor'), isTrue);
      });

      test('IntrinsicWidth has width and height params', () {
        final w = registry.supportedWidgets['IntrinsicWidth']!;
        expect(w.params.containsKey('width'), isTrue);
        expect(w.params.containsKey('height'), isTrue);
      });
    });

    group('Scrolling widgets', () {
      test('supports all scrolling widgets', () {
        for (final name in ['ListView', 'GridView', 'SingleChildScrollView', 'ListBody']) {
          expect(registry.isSupported(name), isTrue, reason: '$name not found');
        }
      });

      test('ListView has childList and scroll params', () {
        final w = registry.supportedWidgets['ListView']!;
        expect(w.childType, equals(ChildType.childList));
        expect(w.childParam, equals('children'));
        expect(w.params['scrollDirection']!.transformer, equals('enum'));
        expect(w.params.containsKey('reverse'), isTrue);
        expect(w.params.containsKey('shrinkWrap'), isTrue);
        expect(w.params['padding']!.transformer, equals('edgeInsets'));
      });

      test('GridView has gridDelegate param', () {
        final w = registry.supportedWidgets['GridView']!;
        expect(w.childType, equals(ChildType.childList));
        expect(w.params.containsKey('gridDelegate'), isTrue);
      });

      test('SingleChildScrollView has optionalChild', () {
        final w = registry.supportedWidgets['SingleChildScrollView']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params['scrollDirection']!.transformer, equals('enum'));
      });

      test('ListBody has childList', () {
        final w = registry.supportedWidgets['ListBody']!;
        expect(w.childType, equals(ChildType.childList));
        expect(w.params.containsKey('mainAxis'), isTrue);
        expect(w.params.containsKey('reverse'), isTrue);
      });
    });

    group('Styling widgets', () {
      test('supports all styling widgets', () {
        for (final name in [
          'Padding', 'ClipRRect', 'ColoredBox', 'DefaultTextStyle',
          'Directionality', 'Icon', 'IconTheme', 'Image', 'Opacity', 'Placeholder',
        ]) {
          expect(registry.isSupported(name), isTrue, reason: '$name not found');
        }
      });

      test('Padding has edgeInsets padding and animation params', () {
        final w = registry.supportedWidgets['Padding']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params['padding']!.transformer, equals('edgeInsets'));
        expect(w.params.containsKey('duration'), isTrue);
        expect(w.params.containsKey('curve'), isTrue);
      });

      test('ClipRRect has borderRadius and clipBehavior', () {
        final w = registry.supportedWidgets['ClipRRect']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params['borderRadius']!.transformer, equals('borderRadius'));
        expect(w.params['clipBehavior']!.transformer, equals('enum'));
      });

      test('ColoredBox has color param', () {
        final w = registry.supportedWidgets['ColoredBox']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params['color']!.transformer, equals('color'));
      });

      test('DefaultTextStyle has style and animation params', () {
        final w = registry.supportedWidgets['DefaultTextStyle']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params['style']!.transformer, equals('textStyle'));
        expect(w.params.containsKey('textAlign'), isTrue);
        expect(w.params.containsKey('duration'), isTrue);
      });

      test('Icon has iconData, size, color, semanticLabel', () {
        final w = registry.supportedWidgets['Icon']!;
        expect(w.childType, equals(ChildType.none));
        expect(w.params['icon']!.rfwName, equals('iconData'));
        expect(w.params.containsKey('size'), isTrue);
        expect(w.params['color']!.transformer, equals('color'));
        expect(w.params.containsKey('semanticLabel'), isTrue);
      });

      test('IconTheme has child and iconThemeData', () {
        final w = registry.supportedWidgets['IconTheme']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('iconThemeData'), isTrue);
      });

      test('Image has optionalChild and imageProvider params', () {
        final w = registry.supportedWidgets['Image']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('imageProvider'), isTrue);
        expect(w.params['fit']!.transformer, equals('enum'));
        expect(w.params['color']!.transformer, equals('color'));
      });

      test('Opacity has opacity and animation params', () {
        final w = registry.supportedWidgets['Opacity']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('opacity'), isTrue);
        expect(w.params.containsKey('duration'), isTrue);
        expect(w.params.containsKey('curve'), isTrue);
      });

      test('Placeholder has color and dimension params', () {
        final w = registry.supportedWidgets['Placeholder']!;
        expect(w.childType, equals(ChildType.none));
        expect(w.params['color']!.transformer, equals('color'));
        expect(w.params.containsKey('strokeWidth'), isTrue);
      });

      test('Directionality has textDirection enum', () {
        final w = registry.supportedWidgets['Directionality']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params['textDirection']!.transformer, equals('enum'));
      });
    });

    group('Transform widgets', () {
      test('supports all transform widgets', () {
        for (final name in ['Positioned', 'Rotation', 'Scale']) {
          expect(registry.isSupported(name), isTrue, reason: '$name not found');
        }
      });

      test('Positioned has child and position params', () {
        final w = registry.supportedWidgets['Positioned']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('start'), isTrue);
        expect(w.params.containsKey('top'), isTrue);
        expect(w.params.containsKey('end'), isTrue);
        expect(w.params.containsKey('bottom'), isTrue);
        expect(w.params.containsKey('duration'), isTrue);
      });

      test('Rotation has turns and alignment', () {
        final w = registry.supportedWidgets['Rotation']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('turns'), isTrue);
        expect(w.params['alignment']!.transformer, equals('alignment'));
        expect(w.params.containsKey('duration'), isTrue);
      });

      test('Scale has scale and alignment', () {
        final w = registry.supportedWidgets['Scale']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.params.containsKey('scale'), isTrue);
        expect(w.params['alignment']!.transformer, equals('alignment'));
        expect(w.params.containsKey('duration'), isTrue);
      });
    });

    group('Other widgets', () {
      test('supports AnimationDefaults and SafeArea', () {
        expect(registry.isSupported('AnimationDefaults'), isTrue);
        expect(registry.isSupported('SafeArea'), isTrue);
      });

      test('AnimationDefaults has duration and curve', () {
        final w = registry.supportedWidgets['AnimationDefaults']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('duration'), isTrue);
        expect(w.params.containsKey('curve'), isTrue);
      });

      test('SafeArea has boolean params and minimum', () {
        final w = registry.supportedWidgets['SafeArea']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.params.containsKey('left'), isTrue);
        expect(w.params.containsKey('top'), isTrue);
        expect(w.params.containsKey('right'), isTrue);
        expect(w.params.containsKey('bottom'), isTrue);
        expect(w.params['minimum']!.transformer, equals('edgeInsets'));
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
