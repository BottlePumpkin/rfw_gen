import 'dart:convert';

import 'package:rfw_gen_mcp/src/tools/list_rfw_widgets.dart';
import 'package:test/test.dart';

void main() {
  group('handleListRfwWidgets', () {
    test('returns empty list when no remote widgets', () {
      final store = RfwWidgetStore();
      final result = handleListRfwWidgets(store, {});
      final data = jsonDecode(result) as Map<String, dynamic>;
      expect(data['widgets'], isEmpty);
      expect(data['count'], equals(0));
    });

    test('returns registered remote widgets', () {
      final store = RfwWidgetStore();
      store.register(
          'movieDetail',
          RfwWidgetContract(
            state: {'liked': false},
            dataRefs: ['movie.title', 'movies'],
            stateRefs: ['liked'],
            events: ['movie.select'],
          ));
      final result = handleListRfwWidgets(store, {});
      final data = jsonDecode(result) as Map<String, dynamic>;
      expect(data['count'], equals(1));
      final widgets = data['widgets'] as List;
      expect(widgets.first['name'], equals('movieDetail'));
      expect(widgets.first['hasState'], isTrue);
      expect(widgets.first['dataRefCount'], equals(2));
      expect(widgets.first['eventCount'], equals(1));
    });
  });
}
