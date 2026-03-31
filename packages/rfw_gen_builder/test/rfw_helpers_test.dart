import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('DataRef', () {
    test('stores path', () {
      const ref = DataRef('user.name');
      expect(ref.path, equals('user.name'));
    });

    test('const construction', () {
      const ref = DataRef('items.0.title');
      expect(ref.path, equals('items.0.title'));
    });
  });

  group('ArgsRef', () {
    test('stores path', () {
      const ref = ArgsRef('product.id');
      expect(ref.path, equals('product.id'));
    });
  });

  group('StateRef', () {
    test('stores path', () {
      const ref = StateRef('selected');
      expect(ref.path, equals('selected'));
    });
  });

  group('LoopVar', () {
    test('stores name', () {
      const v = LoopVar('item');
      expect(v.name, equals('item'));
    });

    test('[] operator builds dot path', () {
      const v = LoopVar('item');
      final result = v['name'];
      expect(result.name, equals('item.name'));
    });

    test('chained [] builds deep path', () {
      const v = LoopVar('item');
      final result = v['address']['city'];
      expect(result.name, equals('item.address.city'));
    });

    test('[] returns a LoopVar', () {
      const v = LoopVar('row');
      final child = v['data'];
      expect(child, isA<LoopVar>());
    });

    test('supports integer index', () {
      const item = LoopVar('item');
      final first = item[0];
      expect(first.name, equals('item.0'));
    });

    test('chained string and integer index', () {
      const item = LoopVar('item');
      final result = item['addresses'][0]['city'];
      expect(result.name, equals('item.addresses.0.city'));
    });
  });

  group('RfwConcat', () {
    test('stores parts', () {
      const ref = DataRef('user.name');
      const concat = RfwConcat(['Hello, ', ref, '!']);
      expect(concat.parts, hasLength(3));
      expect(concat.parts[0], equals('Hello, '));
      expect(concat.parts[1], same(ref));
      expect(concat.parts[2], equals('!'));
    });

    test('empty parts list', () {
      const concat = RfwConcat([]);
      expect(concat.parts, isEmpty);
    });
  });

  group('RfwSwitch', () {
    test('stores value and cases', () {
      const stateRef = StateRef('active');
      const sw = RfwSwitch(
        value: stateRef,
        cases: {true: 'green', false: 'red'},
      );
      expect(sw.value, same(stateRef));
      expect(sw.cases[true], equals('green'));
      expect(sw.cases[false], equals('red'));
    });

    test('stores defaultCase', () {
      const sw = RfwSwitch(
        value: StateRef('x'),
        cases: {1: 'one'},
        defaultCase: 'other',
      );
      expect(sw.defaultCase, equals('other'));
    });

    test('defaultCase is null by default', () {
      const sw = RfwSwitch(
        value: StateRef('x'),
        cases: {},
      );
      expect(sw.defaultCase, isNull);
    });
  });

  group('RfwSwitchValue', () {
    test('stores value, cases, and defaultCase', () {
      const ref = StateRef('down');
      final sw = RfwSwitchValue<int>(
        value: ref,
        cases: {true: 0xFFFF0000, false: 0xFF00FF00},
        defaultCase: 0xFF888888,
      );
      expect(sw.value, same(ref));
      expect(sw.cases[true], equals(0xFFFF0000));
      expect(sw.cases[false], equals(0xFF00FF00));
      expect(sw.defaultCase, equals(0xFF888888));
    });

    test('defaultCase is null by default', () {
      final sw = RfwSwitchValue<String>(
        value: StateRef('x'),
        cases: {'a': 'alpha'},
      );
      expect(sw.defaultCase, isNull);
    });
  });

  group('RfwFor', () {
    test('stores items, itemName, and builder', () {
      const items = DataRef('list');
      final called = <String>[];

      final rfwFor = RfwFor(
        items: items,
        itemName: 'entry',
        builder: (v) {
          called.add(v.name);
          return v['title'];
        },
      );

      expect(rfwFor.items, same(items));
      expect(rfwFor.itemName, equals('entry'));

      final result = rfwFor.builder(const LoopVar('entry'));
      expect(called, equals(['entry']));
      expect((result as LoopVar).name, equals('entry.title'));
    });
  });
}
