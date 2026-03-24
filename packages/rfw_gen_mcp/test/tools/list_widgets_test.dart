import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:rfw_gen_mcp/src/tools/list_widgets.dart';
import 'package:test/test.dart';

void main() {
  late WidgetRegistry registry;

  setUp(() {
    registry = WidgetRegistry.core();
  });

  group('handleListWidgets', () {
    test('returns all widgets when no category filter is provided', () {
      final json = handleListWidgets(registry, {});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['count'], greaterThan(40));
      final widgets = data['widgets'] as List;
      expect(widgets, hasLength(data['count']));
    });

    test('filters to core.widgets category', () {
      final json = handleListWidgets(registry, {'category': 'core.widgets'});
      final data = jsonDecode(json) as Map<String, dynamic>;

      final widgets = data['widgets'] as List;
      expect(widgets, isNotEmpty);
      for (final w in widgets) {
        expect((w as Map)['import'], equals('core.widgets'));
      }
    });

    test('filters to material category', () {
      final json = handleListWidgets(registry, {'category': 'material'});
      final data = jsonDecode(json) as Map<String, dynamic>;

      final widgets = data['widgets'] as List;
      expect(widgets, isNotEmpty);
      for (final w in widgets) {
        expect((w as Map)['import'], equals('material'));
      }
    });

    test('returns empty list for unknown category', () {
      final json = handleListWidgets(registry, {'category': 'unknown.lib'});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['count'], equals(0));
      expect(data['widgets'], isEmpty);
    });
  });
}
