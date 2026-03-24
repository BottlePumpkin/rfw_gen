import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:rfw_gen_mcp/src/tools/get_widget_info.dart';
import 'package:test/test.dart';

void main() {
  late WidgetRegistry registry;

  setUp(() {
    registry = WidgetRegistry.core();
  });

  group('handleGetWidgetInfo', () {
    test('Container - optionalChild with params', () {
      final result = handleGetWidgetInfo(registry, {'widget': 'Container'});
      expect(result.isError, isFalse);

      final data = jsonDecode(result.text) as Map<String, dynamic>;
      expect(data['name'], equals('Container'));
      expect(data['childType'], equals('optionalChild'));
      expect(data['params'], isNotEmpty);
    });

    test('Scaffold - namedSlots with namedChildSlots', () {
      final result = handleGetWidgetInfo(registry, {'widget': 'Scaffold'});
      expect(result.isError, isFalse);

      final data = jsonDecode(result.text) as Map<String, dynamic>;
      expect(data['name'], equals('Scaffold'));
      expect(data['childType'], equals('namedSlots'));
      expect(data['namedChildSlots'], isNotNull);
      expect((data['namedChildSlots'] as Map), isNotEmpty);
    });

    test('Text - has positionalParam "text"', () {
      final result = handleGetWidgetInfo(registry, {'widget': 'Text'});
      expect(result.isError, isFalse);

      final data = jsonDecode(result.text) as Map<String, dynamic>;
      expect(data['name'], equals('Text'));
      expect(data['positionalParam'], equals('text'));
    });

    test('unknown widget FooBar - isError true with error message', () {
      final result = handleGetWidgetInfo(registry, {'widget': 'FooBar'});
      expect(result.isError, isTrue);

      final data = jsonDecode(result.text) as Map<String, dynamic>;
      expect(data['error'], contains('FooBar'));
      expect(data['availableWidgets'], isNotEmpty);
    });
  });
}
