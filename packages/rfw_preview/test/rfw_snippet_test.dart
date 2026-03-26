import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_preview/rfw_preview.dart';

void main() {
  group('RfwSnippet', () {
    group('widgetNames', () {
      test('parses single widget name', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget preview = Text(text: "Hello");',
          widgetName: 'preview',
        );
        expect(snippet.widgetNames, ['preview']);
      });

      test('parses multiple widget names', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: '''
import core.widgets;
widget header = Text(text: "Header");
widget footer = Text(text: "Footer");
widget main = Column(children: [header(), footer()]);
''',
          widgetName: 'main',
        );
        expect(snippet.widgetNames, ['header', 'footer', 'main']);
      });

      test('returns empty list when no widget declarations', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'import core.widgets;',
          widgetName: 'preview',
        );
        expect(snippet.widgetNames, isEmpty);
      });

      test('handles widget keyword in string literal (false positive)', () {
        // The regex is intentionally simple and will match "widget" in strings.
        // This documents the known behavior.
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget myWidget = Text(text: "widget other = ignored");',
          widgetName: 'myWidget',
        );
        // First match is the real declaration
        expect(snippet.widgetNames.first, 'myWidget');
      });

      test('parses stateful widget declaration with state block', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget myButton { down: false } = GestureDetector();',
          widgetName: 'myButton',
        );
        expect(snippet.widgetNames, ['myButton']);
      });

      test('handles extra whitespace between widget keyword and name', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget   spacedName = Text(text: "hi");',
          widgetName: 'spacedName',
        );
        expect(snippet.widgetNames, ['spacedName']);
      });

      test('handles newline between widget keyword and name', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget\n  multiLine = Text(text: "hi");',
          widgetName: 'multiLine',
        );
        // \\s+ matches newlines, so this should work
        expect(snippet.widgetNames, ['multiLine']);
      });

      test('empty rfwtxt returns empty list', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: '',
          widgetName: 'preview',
        );
        expect(snippet.widgetNames, isEmpty);
      });
    });

    group('constructor', () {
      test('stores all fields correctly', () {
        const snippet = RfwSnippet(
          name: 'My Snippet',
          rfwtxt: 'widget x = Text(text: "test");',
          widgetName: 'x',
          category: 'examples',
          data: {'key': 'value'},
        );
        expect(snippet.name, 'My Snippet');
        expect(snippet.rfwtxt, 'widget x = Text(text: "test");');
        expect(snippet.widgetName, 'x');
        expect(snippet.category, 'examples');
        expect(snippet.data, {'key': 'value'});
      });

      test('category and data are optional', () {
        const snippet = RfwSnippet(
          name: 'minimal',
          rfwtxt: 'widget x = Text(text: "");',
          widgetName: 'x',
        );
        expect(snippet.category, isNull);
        expect(snippet.data, isNull);
      });
    });
  });
}
