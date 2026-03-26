import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_preview/rfw_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: implementation_imports
import 'package:rfw_preview/src/editor/snippet_storage.dart';

void main() {
  group('SnippetStorage', () {
    const storageKey = 'rfw_editor_saved_snippets';

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('load', () {
      test('returns empty list when no data stored', () async {
        final snippets = await SnippetStorage.load();
        expect(snippets, isEmpty);
      });

      test('returns empty list on corrupted JSON', () async {
        SharedPreferences.setMockInitialValues({
          storageKey: 'not valid json{{{',
        });
        final snippets = await SnippetStorage.load();
        expect(snippets, isEmpty);
      });

      test('returns empty list on non-list JSON', () async {
        SharedPreferences.setMockInitialValues({
          storageKey: '{"not": "a list"}',
        });
        final snippets = await SnippetStorage.load();
        expect(snippets, isEmpty);
      });

      test('deserializes snippet without data', () async {
        final stored = jsonEncode([
          {
            'name': 'Test',
            'rfwtxt': 'widget x = Text(text: "hi");',
            'widgetName': 'x',
          }
        ]);
        SharedPreferences.setMockInitialValues({storageKey: stored});

        final snippets = await SnippetStorage.load();
        expect(snippets, hasLength(1));
        expect(snippets.first.name, 'Test');
        expect(snippets.first.rfwtxt, 'widget x = Text(text: "hi");');
        expect(snippets.first.widgetName, 'x');
        expect(snippets.first.data, isNull);
      });

      test('deserializes snippet with data', () async {
        final stored = jsonEncode([
          {
            'name': 'WithData',
            'rfwtxt': 'widget y = Text(text: data.msg);',
            'widgetName': 'y',
            'data': {'msg': 'Hello'},
          }
        ]);
        SharedPreferences.setMockInitialValues({storageKey: stored});

        final snippets = await SnippetStorage.load();
        expect(snippets.first.data, {'msg': 'Hello'});
      });

      test('deserializes multiple snippets', () async {
        final stored = jsonEncode([
          {
            'name': 'First',
            'rfwtxt': 'widget a = Text(text: "A");',
            'widgetName': 'a',
          },
          {
            'name': 'Second',
            'rfwtxt': 'widget b = Text(text: "B");',
            'widgetName': 'b',
          },
        ]);
        SharedPreferences.setMockInitialValues({storageKey: stored});

        final snippets = await SnippetStorage.load();
        expect(snippets, hasLength(2));
        expect(snippets[0].name, 'First');
        expect(snippets[1].name, 'Second');
      });
    });

    group('save', () {
      test('persists a snippet', () async {
        const snippet = RfwSnippet(
          name: 'Saved',
          rfwtxt: 'widget s = Text(text: "Saved");',
          widgetName: 's',
        );
        await SnippetStorage.save(snippet);

        final loaded = await SnippetStorage.load();
        expect(loaded, hasLength(1));
        expect(loaded.first.name, 'Saved');
        expect(loaded.first.rfwtxt, snippet.rfwtxt);
        expect(loaded.first.widgetName, 's');
      });

      test('appends to existing snippets', () async {
        const first = RfwSnippet(
          name: 'First',
          rfwtxt: 'widget a = Text(text: "A");',
          widgetName: 'a',
        );
        const second = RfwSnippet(
          name: 'Second',
          rfwtxt: 'widget b = Text(text: "B");',
          widgetName: 'b',
        );

        await SnippetStorage.save(first);
        await SnippetStorage.save(second);

        final loaded = await SnippetStorage.load();
        expect(loaded, hasLength(2));
        expect(loaded[0].name, 'First');
        expect(loaded[1].name, 'Second');
      });

      test('persists data map when present', () async {
        const snippet = RfwSnippet(
          name: 'DataSnippet',
          rfwtxt: 'widget d = Text(text: data.val);',
          widgetName: 'd',
          data: {'val': 'test', 'count': 42},
        );
        await SnippetStorage.save(snippet);

        final loaded = await SnippetStorage.load();
        expect(loaded.first.data, isNotNull);
        expect(loaded.first.data!['val'], 'test');
        expect(loaded.first.data!['count'], 42);
      });

      test('omits data key when data is null', () async {
        const snippet = RfwSnippet(
          name: 'NoData',
          rfwtxt: 'widget n = Text(text: "No data");',
          widgetName: 'n',
        );
        await SnippetStorage.save(snippet);

        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString(storageKey)!;
        final list = jsonDecode(raw) as List;
        final map = list.first as Map<String, dynamic>;
        expect(map.containsKey('data'), isFalse);
      });
    });

    group('delete', () {
      test('removes snippet by name', () async {
        const a = RfwSnippet(
          name: 'Keep',
          rfwtxt: 'widget k = Text(text: "K");',
          widgetName: 'k',
        );
        const b = RfwSnippet(
          name: 'Remove',
          rfwtxt: 'widget r = Text(text: "R");',
          widgetName: 'r',
        );

        await SnippetStorage.save(a);
        await SnippetStorage.save(b);
        await SnippetStorage.delete('Remove');

        final loaded = await SnippetStorage.load();
        expect(loaded, hasLength(1));
        expect(loaded.first.name, 'Keep');
      });

      test('does nothing when name not found', () async {
        const snippet = RfwSnippet(
          name: 'Existing',
          rfwtxt: 'widget e = Text(text: "E");',
          widgetName: 'e',
        );
        await SnippetStorage.save(snippet);
        await SnippetStorage.delete('NonExistent');

        final loaded = await SnippetStorage.load();
        expect(loaded, hasLength(1));
        expect(loaded.first.name, 'Existing');
      });

      test('removes all snippets with same name', () async {
        const snippet = RfwSnippet(
          name: 'Dup',
          rfwtxt: 'widget d = Text(text: "D");',
          widgetName: 'd',
        );
        await SnippetStorage.save(snippet);
        await SnippetStorage.save(snippet);

        await SnippetStorage.delete('Dup');

        final loaded = await SnippetStorage.load();
        expect(loaded, isEmpty);
      });
    });

    group('round-trip', () {
      test('save then load preserves all fields', () async {
        const snippet = RfwSnippet(
          name: 'RoundTrip',
          rfwtxt: 'widget rt = Column(children: [Text(text: data.x)]);',
          widgetName: 'rt',
          data: {'x': 'value', 'nested': 'data'},
        );
        await SnippetStorage.save(snippet);

        final loaded = await SnippetStorage.load();
        expect(loaded.first.name, snippet.name);
        expect(loaded.first.rfwtxt, snippet.rfwtxt);
        expect(loaded.first.widgetName, snippet.widgetName);
        expect(loaded.first.data, snippet.data);
      });
    });
  });
}
