import 'package:rfw_gen_builder/src/ir.dart';
import 'package:rfw_gen_builder/src/metadata_collector.dart';
import 'package:test/test.dart';

void main() {
  group('RfwWidgetMetadata', () {
    test('empty on primitive-only tree', () {
      final tree = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrStringValue('hello')},
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, isEmpty);
      expect(meta.stateRefs, isEmpty);
      expect(meta.events, isEmpty);
    });

    test('collects DataRef paths', () {
      final tree = IrWidgetNode(
        name: 'Text',
        properties: {'text': IrDataRef('user.name')},
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, equals({'user.name'}));
    });

    test('collects StateRef paths', () {
      final tree = IrWidgetNode(
        name: 'Container',
        properties: {'color': IrStateRef('isActive')},
      );
      final meta = collectMetadata(tree);
      expect(meta.stateRefs, equals({'isActive'}));
    });

    test('collects events from IrEventValue', () {
      final tree = IrWidgetNode(
        name: 'GestureDetector',
        properties: {
          'onTap': IrEventValue('item.select', {'id': IrDataRef('item.id')}),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.events, equals({'item.select'}));
      expect(meta.dataRefs, equals({'item.id'}));
    });

    test('collects stateRefs from IrSetStateValue', () {
      final tree = IrWidgetNode(
        name: 'GestureDetector',
        properties: {
          'onTap': IrSetStateValue('count', IrIntValue(0)),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.stateRefs, equals({'count'}));
    });

    test('collects stateRefs from IrSetStateFromArgValue', () {
      final tree = IrWidgetNode(
        name: 'Slider',
        properties: {
          'onChanged': IrSetStateFromArgValue('sliderVal', 'value'),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.stateRefs, equals({'sliderVal'}));
    });

    test('recurses into IrListValue', () {
      final tree = IrWidgetNode(
        name: 'Column',
        properties: {
          'children': IrListValue([
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrDataRef('title')},
            ),
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrDataRef('subtitle')},
            ),
          ]),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, equals({'title', 'subtitle'}));
    });

    test('recurses into IrForLoop', () {
      final tree = IrForLoop(
        items: IrDataRef('items'),
        itemName: 'item',
        body: IrWidgetNode(
          name: 'Text',
          properties: {'text': IrLoopVarRef('item.name')},
        ),
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, equals({'items'}));
    });

    test('recurses into IrSwitchExpr', () {
      final tree = IrSwitchExpr(
        value: IrStateRef('mode'),
        cases: {
          IrStringValue('a'): IrWidgetNode(
            name: 'Text',
            properties: {'text': IrDataRef('labelA')},
          ),
        },
        defaultCase: IrWidgetNode(
          name: 'Text',
          properties: {'text': IrDataRef('labelDefault')},
        ),
      );
      final meta = collectMetadata(tree);
      expect(meta.stateRefs, equals({'mode'}));
      expect(meta.dataRefs, equals({'labelA', 'labelDefault'}));
    });

    test('recurses into IrConcat', () {
      final tree = IrWidgetNode(
        name: 'Text',
        properties: {
          'text': IrConcat([
            IrStringValue('Hello '),
            IrDataRef('user.name'),
          ]),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, equals({'user.name'}));
    });

    test('deduplicates refs across tree', () {
      final tree = IrWidgetNode(
        name: 'Column',
        properties: {
          'children': IrListValue([
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrDataRef('title')},
            ),
            IrWidgetNode(
              name: 'Text',
              properties: {'text': IrDataRef('title')},
            ),
          ]),
        },
      );
      final meta = collectMetadata(tree);
      expect(meta.dataRefs, equals({'title'}));
    });
  });
}
