import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('ChildType', () {
    test('has five values', () {
      expect(ChildType.values, hasLength(5));
    });

    test('contains none, child, optionalChild, childList, namedSlots', () {
      expect(
          ChildType.values,
          containsAll([
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

    test('contains exactly 56 widgets', () {
      expect(registry.supportedWidgets, hasLength(63));
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
      expect(registry.isSupported('CupertinoButton'), isFalse);
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
        expect(
            column.params['crossAxisAlignment']!.transformer, equals('enum'));
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
        expect(container.params['decoration']!.transformer,
            equals('boxDecoration'));
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
          'Align',
          'AspectRatio',
          'Expanded',
          'Flexible',
          'FittedBox',
          'FractionallySizedBox',
          'IntrinsicHeight',
          'IntrinsicWidth',
          'SizedBoxExpand',
          'SizedBoxShrink',
          'Spacer',
          'Stack',
          'Wrap',
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
        for (final name in [
          'ListView',
          'GridView',
          'SingleChildScrollView',
          'ListBody'
        ]) {
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
          'Padding',
          'ClipRRect',
          'ColoredBox',
          'DefaultTextStyle',
          'Directionality',
          'Icon',
          'IconTheme',
          'Image',
          'Opacity',
          'Placeholder',
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

      test('Icon supports positional param for icon', () {
        final mapping = registry.supportedWidgets['Icon']!;
        expect(mapping.positionalParam, equals('icon'));
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

      test('Placeholder accepts both Flutter and RFW param names', () {
        final mapping = registry.supportedWidgets['Placeholder']!;
        expect(mapping.params.containsKey('fallbackWidth'), isTrue);
        expect(mapping.params.containsKey('fallbackHeight'), isTrue);
        expect(mapping.params['fallbackWidth']!.rfwName,
            equals('placeholderWidth'));
        expect(mapping.params['fallbackHeight']!.rfwName,
            equals('placeholderHeight'));
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

    group('Interaction widgets', () {
      test('GestureDetector is registered', () {
        expect(registry.isSupported('GestureDetector'), isTrue);
      });

      test('GestureDetector has handler params', () {
        final w = registry.supportedWidgets['GestureDetector']!;
        expect(w.handlerParams, contains('onTap'));
        expect(w.handlerParams, contains('onLongPress'));
        expect(w.handlerParams, contains('onDoubleTap'));
        expect(w.childType, equals(ChildType.optionalChild));
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

    group('Material widgets', () {
      test('supports all 17 material widgets', () {
        for (final name in [
          'Scaffold',
          'AppBar',
          'ListTile',
          'Card',
          'Material',
          'ElevatedButton',
          'TextButton',
          'OutlinedButton',
          'FloatingActionButton',
          'InkWell',
          'Divider',
          'VerticalDivider',
          'CircularProgressIndicator',
          'LinearProgressIndicator',
          'Drawer',
          'OverflowBar',
          'Slider',
        ]) {
          expect(registry.isSupported(name), isTrue, reason: '$name not found');
        }
      });

      test('Scaffold has namedSlots', () {
        final w = registry.supportedWidgets['Scaffold']!;
        expect(w.childType, equals(ChildType.namedSlots));
        expect(w.namedChildSlots.containsKey('appBar'), isTrue);
        expect(w.namedChildSlots.containsKey('body'), isTrue);
        expect(w.import, equals('material'));
      });

      test('AppBar has namedSlots with list slot', () {
        final w = registry.supportedWidgets['AppBar']!;
        expect(w.childType, equals(ChildType.namedSlots));
        expect(w.namedChildSlots['actions'], isTrue);
        expect(w.namedChildSlots['title'], isFalse);
      });

      test('ListTile has namedSlots and handlers', () {
        final w = registry.supportedWidgets['ListTile']!;
        expect(w.childType, equals(ChildType.namedSlots));
        expect(w.handlerParams, contains('onTap'));
        expect(w.namedChildSlots.containsKey('title'), isTrue);
      });

      test('ElevatedButton has child and handler params', () {
        final w = registry.supportedWidgets['ElevatedButton']!;
        expect(w.childType, equals(ChildType.child));
        expect(w.handlerParams, contains('onPressed'));
        expect(w.handlerParams, contains('onLongPress'));
        expect(w.import, equals('material'));
      });

      test('Slider has handlers including onChanged', () {
        final w = registry.supportedWidgets['Slider']!;
        expect(w.childType, equals(ChildType.none));
        expect(w.handlerParams, contains('onChanged'));
        expect(w.params.containsKey('min'), isTrue);
        expect(w.params.containsKey('max'), isTrue);
      });

      test('InkWell has optionalChild and handlers', () {
        final w = registry.supportedWidgets['InkWell']!;
        expect(w.childType, equals(ChildType.optionalChild));
        expect(w.handlerParams, contains('onTap'));
      });

      test('Card has shape param with shapeBorder transformer', () {
        final w = registry.supportedWidgets['Card']!;
        expect(w.params.containsKey('shape'), isTrue);
        expect(w.params['shape']!.transformer, equals('shapeBorder'));
      });

      test('all material widgets use material import', () {
        for (final name in [
          'Scaffold',
          'AppBar',
          'Card',
          'ElevatedButton',
          'Divider'
        ]) {
          expect(registry.supportedWidgets[name]!.import, equals('material'));
        }
      });
    });
  });

  group('Missing params and handlers', () {
    late WidgetRegistry registry;

    setUp(() {
      registry = WidgetRegistry.core();
    });

    test('Column has textBaseline param', () {
      final mapping = registry.supportedWidgets['Column']!;
      expect(mapping.params.containsKey('textBaseline'), isTrue);
    });

    test('Row has textBaseline param', () {
      final mapping = registry.supportedWidgets['Row']!;
      expect(mapping.params.containsKey('textBaseline'), isTrue);
    });

    test('Column has textDirection param', () {
      final mapping = registry.supportedWidgets['Column']!;
      expect(mapping.params.containsKey('textDirection'), isTrue);
      expect(mapping.params['textDirection']!.transformer, equals('enum'));
    });

    test('Row has textDirection param', () {
      final mapping = registry.supportedWidgets['Row']!;
      expect(mapping.params.containsKey('textDirection'), isTrue);
      expect(mapping.params['textDirection']!.transformer, equals('enum'));
    });

    test('Container has additional params', () {
      final mapping = registry.supportedWidgets['Container']!;
      expect(mapping.params.containsKey('foregroundDecoration'), isTrue);
      expect(mapping.params.containsKey('constraints'), isTrue);
      expect(mapping.params.containsKey('transform'), isTrue);
      expect(mapping.params.containsKey('clipBehavior'), isTrue);
    });

    test('animated widgets have onEnd handler', () {
      for (final name in [
        'Container',
        'Align',
        'Opacity',
        'Padding',
        'DefaultTextStyle',
        'Positioned',
        'Rotation',
        'Scale',
      ]) {
        final mapping = registry.supportedWidgets[name]!;
        expect(
          mapping.handlerParams.contains('onEnd'),
          isTrue,
          reason: '$name should have onEnd handler',
        );
      }
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

      registry.register(
          'NewWidget',
          const WidgetMapping(
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
      expect(registry.supportedWidgets['Text']!.positionalParam,
          equals('content'));
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

  group('registerFromConfig', () {
    test('registers widget with import only', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'MystiqueText': {'import': 'mystique.widgets'},
      });

      expect(registry.isSupported('MystiqueText'), isTrue);
      final mapping = registry.supportedWidgets['MystiqueText']!;
      expect(mapping.import, 'mystique.widgets');
      expect(mapping.childType, ChildType.none);
      expect(mapping.childParam, isNull);
      expect(mapping.handlerParams, isEmpty);
      expect(mapping.params, isEmpty);
    });

    test('registers widget with child_type and auto-derived child_param', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'Wrapper': {'import': 'custom.widgets', 'child_type': 'optionalChild'},
      });
      final mapping = registry.supportedWidgets['Wrapper']!;
      expect(mapping.childType, ChildType.optionalChild);
      expect(mapping.childParam, 'child');
    });

    test('registers widget with childList and auto-derived children param', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'CustomColumn': {'import': 'custom.widgets', 'child_type': 'childList'},
      });
      final mapping = registry.supportedWidgets['CustomColumn']!;
      expect(mapping.childType, ChildType.childList);
      expect(mapping.childParam, 'children');
    });

    test('registers widget with explicit child_param override', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'Special': {
          'import': 'custom.widgets',
          'child_type': 'optionalChild',
          'child_param': 'content',
        },
      });
      final mapping = registry.supportedWidgets['Special']!;
      expect(mapping.childParam, 'content');
    });

    test('registers widget with handlers', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'Tapper': {
          'import': 'custom.widgets',
          'child_type': 'optionalChild',
          'handlers': ['onTap', 'onLongPress'],
        },
      });
      final mapping = registry.supportedWidgets['Tapper']!;
      expect(mapping.handlerParams, {'onTap', 'onLongPress'});
    });

    test('throws when import is missing', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {'child_type': 'none'}
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('missing required "import"'),
        )),
      );
    });

    test('registers namedSlots widget with named_child_slots', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'MyTile': {
          'import': 'custom.widgets',
          'child_type': 'namedSlots',
          'named_child_slots': {'title': false, 'actions': true},
        },
      });
      final mapping = registry.supportedWidgets['MyTile']!;
      expect(mapping.childType, ChildType.namedSlots);
      expect(mapping.childParam, isNull);
      expect(mapping.namedChildSlots, {'title': false, 'actions': true});
    });

    test('namedSlots with handlers', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'MyTile': {
          'import': 'custom.widgets',
          'child_type': 'namedSlots',
          'named_child_slots': {'leading': false, 'title': false},
          'handlers': ['onTap'],
        },
      });
      final mapping = registry.supportedWidgets['MyTile']!;
      expect(mapping.childType, ChildType.namedSlots);
      expect(mapping.namedChildSlots, {'leading': false, 'title': false});
      expect(mapping.handlerParams, {'onTap'});
    });

    test('throws when namedSlots without named_child_slots', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {'import': 'x', 'child_type': 'namedSlots'},
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('requires "named_child_slots"'),
        )),
      );
    });

    test('throws when namedSlots with empty named_child_slots', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'namedSlots',
            'named_child_slots': <String, dynamic>{},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('requires "named_child_slots"'),
        )),
      );
    });

    test(
        'throws when named_child_slots provided with non-namedSlots child_type',
        () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'child',
            'named_child_slots': {'title': false},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('only valid when child_type is "namedSlots"'),
        )),
      );
    });

    test('throws when named_child_slots has non-bool value', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({
          'Bad': {
            'import': 'x',
            'child_type': 'namedSlots',
            'named_child_slots': {'title': 'yes'},
          },
        }),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('must be a bool'),
        )),
      );
    });

    test('handles null config value (YAML key with no value)', () {
      final registry = WidgetRegistry();
      expect(
        () => registry.registerFromConfig({'MystiqueText': null}),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('missing required "import"'),
        )),
      );
    });

    test('registers multiple widgets at once', () {
      final registry = WidgetRegistry();
      registry.registerFromConfig({
        'A': {'import': 'lib.a'},
        'B': {'import': 'lib.b', 'child_type': 'child'},
        'C': {
          'import': 'lib.c',
          'handlers': ['onTap']
        },
      });
      expect(registry.isSupported('A'), isTrue);
      expect(registry.isSupported('B'), isTrue);
      expect(registry.isSupported('C'), isTrue);
      expect(registry.supportedWidgets['B']!.childType, ChildType.child);
      expect(registry.supportedWidgets['B']!.childParam, 'child');
      expect(registry.supportedWidgets['C']!.handlerParams, {'onTap'});
    });

    test('works with YamlMap from loadYaml (round-trip)', () {
      final registry = WidgetRegistry();
      final yamlStr = '''
MystiqueText:
  import: mystique.widgets
Tapper:
  import: custom.widgets
  child_type: optionalChild
  handlers:
    - onTap
''';
      final parsed = loadYaml(yamlStr) as Map;
      registry.registerFromConfig(Map<String, dynamic>.from(parsed));

      expect(registry.isSupported('MystiqueText'), isTrue);
      expect(registry.supportedWidgets['MystiqueText']!.import,
          'mystique.widgets');
      expect(registry.isSupported('Tapper'), isTrue);
      expect(registry.supportedWidgets['Tapper']!.handlerParams, {'onTap'});
      expect(registry.supportedWidgets['Tapper']!.childParam, 'child');
    });
  });

  group('Animated widget aliases', () {
    late WidgetRegistry registry;

    setUp(() {
      registry = WidgetRegistry.core();
    });

    test('AnimatedAlign maps to core.Align', () {
      final mapping = registry.supportedWidgets['AnimatedAlign']!;
      expect(mapping.rfwName, equals('core.Align'));
      expect(mapping.params.containsKey('duration'), isTrue);
      expect(mapping.params.containsKey('curve'), isTrue);
    });

    test('AnimatedContainer maps to core.Container', () {
      final mapping = registry.supportedWidgets['AnimatedContainer']!;
      expect(mapping.rfwName, equals('core.Container'));
      expect(mapping.params.containsKey('duration'), isTrue);
    });

    test('AnimatedPadding maps to core.Padding', () {
      final mapping = registry.supportedWidgets['AnimatedPadding']!;
      expect(mapping.rfwName, equals('core.Padding'));
      expect(mapping.params.containsKey('duration'), isTrue);
    });

    test('AnimatedDefaultTextStyle maps to core.DefaultTextStyle', () {
      final mapping = registry.supportedWidgets['AnimatedDefaultTextStyle']!;
      expect(mapping.rfwName, equals('core.DefaultTextStyle'));
      expect(mapping.params.containsKey('duration'), isTrue);
    });

    test('AnimatedOpacity maps to core.Opacity', () {
      final mapping = registry.supportedWidgets['AnimatedOpacity']!;
      expect(mapping.rfwName, equals('core.Opacity'));
      expect(mapping.params.containsKey('duration'), isTrue);
    });

    test('PositionedDirectional maps to core.Positioned', () {
      final mapping = registry.supportedWidgets['PositionedDirectional']!;
      expect(mapping.rfwName, equals('core.Positioned'));
      expect(mapping.params.containsKey('start'), isTrue);
      expect(mapping.params.containsKey('end'), isTrue);
    });

    test('AnimatedPositionedDirectional maps to core.Positioned', () {
      final mapping =
          registry.supportedWidgets['AnimatedPositionedDirectional']!;
      expect(mapping.rfwName, equals('core.Positioned'));
      expect(mapping.params.containsKey('duration'), isTrue);
      expect(mapping.params.containsKey('end'), isTrue);
    });
  });
}
