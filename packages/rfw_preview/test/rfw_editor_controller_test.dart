import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_preview/rfw_preview.dart';

void main() {
  group('RfwEditorController', () {
    late RfwEditorController controller;

    setUp(() {
      controller = RfwEditorController();
    });

    tearDown(() {
      controller.dispose();
    });

    group('initial state', () {
      test('has default rfwtxt with preview widget', () {
        expect(controller.rfwtxt, contains('widget preview'));
        expect(controller.rfwtxt, contains('Hello, RFW!'));
      });

      test('selectedWidget defaults to preview', () {
        expect(controller.selectedWidget, 'preview');
      });

      test('availableWidgets contains preview', () {
        expect(controller.availableWidgets, contains('preview'));
      });

      test('jsonData defaults to empty map', () {
        expect(controller.jsonData, isEmpty);
      });

      test('jsonText defaults to empty object string', () {
        expect(controller.jsonText, '{}');
      });

      test('jsonError is null initially', () {
        expect(controller.jsonError, isNull);
      });

      test('error is null initially', () {
        expect(controller.error, isNull);
        expect(controller.errorLine, isNull);
      });

      test('isDarkTheme defaults to true', () {
        expect(controller.isDarkTheme, isTrue);
      });

      test('isBottomPanelExpanded defaults to false', () {
        expect(controller.isBottomPanelExpanded, isFalse);
      });

      test('bottomPanelTab defaults to data', () {
        expect(controller.bottomPanelTab, BottomPanelTab.data);
      });

      test('deviceFrame defaults to iphone375', () {
        expect(controller.deviceFrame, DeviceFrame.iphone375);
      });

      test('zoom defaults to 1.0', () {
        expect(controller.zoom, 1.0);
      });

      test('previewBackground defaults to white', () {
        expect(controller.previewBackground, PreviewBackground.white);
      });

      test('events is empty initially', () {
        expect(controller.events, isEmpty);
      });

      test('lastSuccessfulRfwtxt is null initially', () {
        expect(controller.lastSuccessfulRfwtxt, isNull);
      });

      test('isSnippetDrawerOpen defaults to false', () {
        expect(controller.isSnippetDrawerOpen, isFalse);
      });

      test('savedSnippets is empty initially', () {
        expect(controller.savedSnippets, isEmpty);
      });
    });

    group('custom initial state', () {
      test('accepts initial rfwtxt', () {
        final c = RfwEditorController(
          initialRfwtxt: 'widget custom = Text(text: "Custom");',
        );
        expect(c.rfwtxt, contains('widget custom'));
        // Note: constructor does not call _parseWidgetNames(), so
        // availableWidgets remains at default until rfwtxt setter is used.
        expect(c.availableWidgets, ['preview']);
        c.dispose();
      });

      test('accepts initial data', () {
        final c = RfwEditorController(
          initialData: {'name': 'Alice'},
        );
        expect(c.jsonData, {'name': 'Alice'});
        expect(c.jsonText, contains('"name"'));
        expect(c.jsonText, contains('"Alice"'));
        c.dispose();
      });
    });

    group('rfwtxt setter', () {
      test('updates rfwtxt and notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);

        controller.rfwtxt =
            'widget newWidget = Text(text: "Updated");';
        expect(controller.rfwtxt, contains('newWidget'));
        expect(notified, isTrue);
      });

      test('does not notify when value is unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        final original = controller.rfwtxt;
        controller.rfwtxt = original;
        expect(notifyCount, 0);
      });

      test('parses widget names from new rfwtxt', () {
        controller.rfwtxt = '''
widget alpha = Text(text: "A");
widget beta = Text(text: "B");
''';
        expect(controller.availableWidgets, ['alpha', 'beta']);
      });

      test('updates selectedWidget when current selection not in new names',
          () {
        controller.rfwtxt = 'widget other = Text(text: "X");';
        expect(controller.selectedWidget, 'other');
      });

      test('preserves selectedWidget when it exists in new names', () {
        controller.rfwtxt = '''
widget preview = Text(text: "A");
widget extra = Text(text: "B");
''';
        expect(controller.selectedWidget, 'preview');
      });
    });

    group('updateJsonText', () {
      test('parses valid JSON object', () {
        controller.updateJsonText('{"name": "Bob", "age": 30}');
        expect(controller.jsonData, {'name': 'Bob', 'age': 30});
        expect(controller.jsonError, isNull);
      });

      test('sets error for invalid JSON', () {
        controller.updateJsonText('{invalid}');
        expect(controller.jsonError, isNotNull);
      });

      test('sets error for non-object JSON (array)', () {
        controller.updateJsonText('[1, 2, 3]');
        expect(controller.jsonError, 'Root must be a JSON object');
      });

      test('sets error for non-object JSON (string)', () {
        controller.updateJsonText('"hello"');
        expect(controller.jsonError, 'Root must be a JSON object');
      });

      test('handles empty object', () {
        controller.updateJsonText('{}');
        expect(controller.jsonData, isEmpty);
        expect(controller.jsonError, isNull);
      });

      test('handles null values in JSON by converting to empty string', () {
        controller.updateJsonText('{"key": null}');
        expect(controller.jsonData['key'], '');
        expect(controller.jsonError, isNull);
      });

      test('notifies listeners', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.updateJsonText('{}');
        expect(notified, isTrue);
      });

      test('updates jsonText field', () {
        controller.updateJsonText('{"x": 1}');
        expect(controller.jsonText, '{"x": 1}');
      });
    });

    group('setParseError', () {
      test('sets error message without offset', () {
        controller.setParseError('Something went wrong');
        expect(controller.error, 'Something went wrong');
        expect(controller.errorLine, isNull);
      });

      test('calculates line number from offset', () {
        controller.rfwtxt = 'line1\nline2\nline3';
        // offset 6 is first char of line2 (after 'line1\n')
        controller.setParseError('error', offset: 6);
        expect(controller.errorLine, 2);
      });

      test('offset 0 maps to line 1', () {
        controller.rfwtxt = 'hello\nworld';
        controller.setParseError('error', offset: 0);
        expect(controller.errorLine, 1);
      });

      test('offset beyond content is clamped', () {
        controller.rfwtxt = 'short';
        controller.setParseError('error', offset: 1000);
        // Should not crash; line is calculated from clamped offset
        expect(controller.errorLine, isNotNull);
        expect(controller.errorLine, 1); // 'short' has no newlines
      });

      test('negative offset is clamped to 0', () {
        controller.rfwtxt = 'hello';
        controller.setParseError('error', offset: -5);
        expect(controller.errorLine, 1);
      });

      test('counts newlines correctly for multi-line content', () {
        controller.rfwtxt = 'a\nb\nc\nd\ne';
        // offset 8 is 'e' (a\nb\nc\nd\ne → positions: a=0, \n=1, b=2, \n=3, c=4, \n=5, d=6, \n=7, e=8)
        controller.setParseError('error', offset: 8);
        expect(controller.errorLine, 5);
      });
    });

    group('markRenderSuccess', () {
      test('stores current rfwtxt as last successful', () {
        controller.rfwtxt = 'widget ok = Text(text: "OK");';
        controller.markRenderSuccess();
        expect(controller.lastSuccessfulRfwtxt,
            'widget ok = Text(text: "OK");');
      });

      test('clears error and errorLine', () {
        controller.setParseError('bad', offset: 0);
        controller.markRenderSuccess();
        expect(controller.error, isNull);
        expect(controller.errorLine, isNull);
      });
    });

    group('zoom', () {
      test('clamps to minimum 0.5', () {
        controller.zoom = 0.1;
        expect(controller.zoom, 0.5);
      });

      test('clamps to maximum 2.0', () {
        controller.zoom = 5.0;
        expect(controller.zoom, 2.0);
      });

      test('accepts value within range', () {
        controller.zoom = 1.5;
        expect(controller.zoom, 1.5);
      });

      test('accepts boundary values', () {
        controller.zoom = 0.5;
        expect(controller.zoom, 0.5);
        controller.zoom = 2.0;
        expect(controller.zoom, 2.0);
      });

      test('does not notify when clamped value is same', () {
        controller.zoom = 0.5;
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.zoom = 0.3; // clamps to 0.5, same as current
        expect(notifyCount, 0);
      });
    });

    group('toggleTheme', () {
      test('toggles from dark to light', () {
        expect(controller.isDarkTheme, isTrue);
        controller.toggleTheme();
        expect(controller.isDarkTheme, isFalse);
      });

      test('toggles from light back to dark', () {
        controller.toggleTheme();
        controller.toggleTheme();
        expect(controller.isDarkTheme, isTrue);
      });
    });

    group('toggleBottomPanel', () {
      test('opens panel when closed', () {
        controller.toggleBottomPanel();
        expect(controller.isBottomPanelExpanded, isTrue);
      });

      test('opens panel with specific tab', () {
        controller.toggleBottomPanel(tab: BottomPanelTab.events);
        expect(controller.isBottomPanelExpanded, isTrue);
        expect(controller.bottomPanelTab, BottomPanelTab.events);
      });

      test('collapses when same tab tapped while open', () {
        controller.toggleBottomPanel(tab: BottomPanelTab.data);
        expect(controller.isBottomPanelExpanded, isTrue);

        controller.toggleBottomPanel(tab: BottomPanelTab.data);
        expect(controller.isBottomPanelExpanded, isFalse);
      });

      test('switches tab when different tab tapped while open', () {
        controller.toggleBottomPanel(tab: BottomPanelTab.data);
        controller.toggleBottomPanel(tab: BottomPanelTab.events);
        expect(controller.isBottomPanelExpanded, isTrue);
        expect(controller.bottomPanelTab, BottomPanelTab.events);
      });

      test('opens without changing tab when no tab specified', () {
        controller.bottomPanelTab = BottomPanelTab.events;
        controller.toggleBottomPanel();
        expect(controller.isBottomPanelExpanded, isTrue);
        expect(controller.bottomPanelTab, BottomPanelTab.events);
      });
    });

    group('toggleSnippetDrawer', () {
      test('opens when closed', () {
        controller.toggleSnippetDrawer();
        expect(controller.isSnippetDrawerOpen, isTrue);
      });

      test('closes when open', () {
        controller.toggleSnippetDrawer();
        controller.toggleSnippetDrawer();
        expect(controller.isSnippetDrawerOpen, isFalse);
      });
    });

    group('events', () {
      test('addEvent inserts at the beginning', () {
        controller.addEvent('first', const <String, Object>{});
        controller.addEvent('second', const <String, Object>{});
        expect(controller.events.first.name, 'second');
        expect(controller.events.last.name, 'first');
      });

      test('addEvent stores name and args', () {
        controller.addEvent('tap', <String, Object>{'x': 10});
        expect(controller.events.first.name, 'tap');
        expect(controller.events.first.args, {'x': 10});
      });

      test('addEvent records timestamp', () {
        final before = DateTime.now();
        controller.addEvent('tap', const <String, Object>{});
        final after = DateTime.now();

        final timestamp = controller.events.first.timestamp;
        expect(timestamp.isAfter(before) || timestamp.isAtSameMomentAs(before),
            isTrue);
        expect(timestamp.isBefore(after) || timestamp.isAtSameMomentAs(after),
            isTrue);
      });

      test('clearEvents removes all events', () {
        controller.addEvent('a', const <String, Object>{});
        controller.addEvent('b', const <String, Object>{});
        controller.clearEvents();
        expect(controller.events, isEmpty);
      });

      test('events list is unmodifiable', () {
        controller.addEvent('test', const <String, Object>{});
        expect(
          () => controller.events.add(
            RfwEvent(
              name: 'hack',
              args: const <String, Object>{},
              timestamp: DateTime.now(),
            ),
          ),
          throwsUnsupportedError,
        );
      });
    });

    group('loadSnippet', () {
      test('loads rfwtxt and widgetName', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget loaded = Text(text: "Loaded");',
          widgetName: 'loaded',
        );
        controller.loadSnippet(snippet);
        expect(controller.rfwtxt, snippet.rfwtxt);
        expect(controller.selectedWidget, 'loaded');
      });

      test('loads data when provided', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget w = Text(text: data.msg);',
          widgetName: 'w',
          data: {'msg': 'Hello'},
        );
        controller.loadSnippet(snippet);
        expect(controller.jsonData, {'msg': 'Hello'});
        expect(controller.jsonText, contains('"msg"'));
        expect(controller.jsonError, isNull);
      });

      test('clears error state', () {
        controller.setParseError('previous error', offset: 0);
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: 'widget w = Text(text: "OK");',
          widgetName: 'w',
        );
        controller.loadSnippet(snippet);
        expect(controller.error, isNull);
        expect(controller.errorLine, isNull);
      });

      test('parses widget names from loaded snippet', () {
        const snippet = RfwSnippet(
          name: 'test',
          rfwtxt: '''
widget alpha = Text(text: "A");
widget beta = Text(text: "B");
''',
          widgetName: 'alpha',
        );
        controller.loadSnippet(snippet);
        expect(controller.availableWidgets, ['alpha', 'beta']);
      });
    });

    group('selectedWidget setter', () {
      test('updates and notifies', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.selectedWidget = 'other';
        expect(controller.selectedWidget, 'other');
        expect(notified, isTrue);
      });

      test('does not notify when value is unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.selectedWidget = controller.selectedWidget;
        expect(notifyCount, 0);
      });
    });

    group('error setter', () {
      test('clears errorLine when error set to null', () {
        controller.setParseError('err', offset: 5);
        controller.error = null;
        expect(controller.error, isNull);
        expect(controller.errorLine, isNull);
      });

      test('sets error without affecting errorLine when non-null', () {
        controller.error = 'new error';
        expect(controller.error, 'new error');
        expect(controller.errorLine, isNull);
      });
    });

    group('deviceFrame setter', () {
      test('updates and notifies', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.deviceFrame = DeviceFrame.android360;
        expect(controller.deviceFrame, DeviceFrame.android360);
        expect(notified, isTrue);
      });

      test('does not notify when value is unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.deviceFrame = controller.deviceFrame;
        expect(notifyCount, 0);
      });
    });

    group('previewBackground setter', () {
      test('updates and notifies', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.previewBackground = PreviewBackground.checkerboard;
        expect(controller.previewBackground, PreviewBackground.checkerboard);
        expect(notified, isTrue);
      });

      test('does not notify when value is unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.previewBackground = controller.previewBackground;
        expect(notifyCount, 0);
      });
    });

    group('isBottomPanelExpanded setter', () {
      test('updates and notifies', () {
        var notified = false;
        controller.addListener(() => notified = true);
        controller.isBottomPanelExpanded = true;
        expect(controller.isBottomPanelExpanded, isTrue);
        expect(notified, isTrue);
      });

      test('does not notify when value is unchanged', () {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);
        controller.isBottomPanelExpanded = false; // already false
        expect(notifyCount, 0);
      });
    });
  });

  group('DeviceFrame', () {
    test('iphone375 has correct values', () {
      expect(DeviceFrame.iphone375.label, 'iPhone 375pt');
      expect(DeviceFrame.iphone375.width, 375);
    });

    test('android360 has correct values', () {
      expect(DeviceFrame.android360.label, 'Android 360pt');
      expect(DeviceFrame.android360.width, 360);
    });

    test('free has width 0', () {
      expect(DeviceFrame.free.label, 'Free');
      expect(DeviceFrame.free.width, 0);
    });
  });

  group('PreviewBackground', () {
    test('has correct labels', () {
      expect(PreviewBackground.white.label, 'White');
      expect(PreviewBackground.gray.label, 'Gray');
      expect(PreviewBackground.checkerboard.label, 'Checkerboard');
    });
  });
}
