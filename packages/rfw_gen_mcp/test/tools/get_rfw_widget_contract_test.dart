import 'dart:convert';

import 'package:rfw_gen_mcp/src/tools/get_rfw_widget_contract.dart';
import 'package:rfw_gen_mcp/src/tools/list_rfw_widgets.dart';
import 'package:test/test.dart';

void main() {
  late RfwWidgetStore store;

  setUp(() {
    store = RfwWidgetStore();
    store.register(
        'movieDetail',
        RfwWidgetContract(
          state: {'liked': false},
          dataRefs: ['movie.title', 'movie.posterUrl', 'movies'],
          stateRefs: ['liked'],
          events: ['movie.book', 'movie.select'],
        ));
  });

  group('handleGetRfwWidgetContract', () {
    test('returns contract for existing widget', () {
      final result =
          handleGetRfwWidgetContract(store, {'widget': 'movieDetail'});
      expect(result.isError, isFalse);
      final data = jsonDecode(result.text) as Map<String, dynamic>;
      expect(data['name'], equals('movieDetail'));
      expect(data['state'], equals({'liked': false}));
      expect(data['dataRefs'],
          equals(['movie.title', 'movie.posterUrl', 'movies']));
      expect(data['stateRefs'], equals(['liked']));
      expect(data['events'], equals(['movie.book', 'movie.select']));
    });

    test('returns error for missing widget', () {
      final result =
          handleGetRfwWidgetContract(store, {'widget': 'nonExistent'});
      expect(result.isError, isTrue);
    });

    test('returns error for missing argument', () {
      final result = handleGetRfwWidgetContract(store, {});
      expect(result.isError, isTrue);
    });
  });
}
