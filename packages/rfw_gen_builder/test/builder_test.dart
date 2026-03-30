import 'dart:convert';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:test/test.dart';

import 'package:rfw_gen_builder/builder.dart';

void main() {
  group('RfwWidgetBuilder', () {
    test('generates rfwtxt from @RfwWidget annotated function', () async {
      final result = await testBuilder(
        rfwWidgetBuilder(BuilderOptions.empty),
        {
          'a|lib/widgets.dart': '''
@RfwWidget('greeting')
Widget buildGreeting() {
  return Text('Hello');
}
''',
        },
        outputs: {
          'a|lib/widgets.rfwtxt': decodedMatches(
            allOf(
              contains('widget greeting'),
              contains('Text('),
              contains('text: "Hello"'),
            ),
          ),
          'a|lib/widgets.rfw': isNotEmpty,
          'a|lib/widgets.rfw_meta.json': decodedMatches(
            predicate<String>((s) {
              final meta = jsonDecode(s) as Map<String, dynamic>;
              final widgets = meta['widgets'] as Map<String, dynamic>;
              final greeting = widgets['greeting'] as Map<String, dynamic>;
              return greeting['type'] == 'remote';
            }, 'valid .rfw_meta.json with remote type'),
          ),
        },
      );
      expect(result.succeeded, isTrue);
    });

    test('skips files without @RfwWidget annotations', () async {
      final result = await testBuilder(
        rfwWidgetBuilder(BuilderOptions.empty),
        {
          'a|lib/plain.dart': '''
Widget buildSomething() {
  return Text('No annotation');
}
''',
        },
        outputs: {},
      );
      expect(result.succeeded, isTrue);
    });

    test('handles multiple @RfwWidget functions in one file', () async {
      final result = await testBuilder(
        rfwWidgetBuilder(BuilderOptions.empty),
        {
          'a|lib/multi.dart': '''
@RfwWidget('first')
Widget buildFirst() {
  return Text('One');
}

@RfwWidget('second')
Widget buildSecond() {
  return Text('Two');
}
''',
        },
        outputs: {
          'a|lib/multi.rfwtxt': decodedMatches(
            allOf(
              contains('widget first'),
              contains('widget second'),
              contains('text: "One"'),
              contains('text: "Two"'),
            ),
          ),
          'a|lib/multi.rfw': isNotEmpty,
          'a|lib/multi.rfw_meta.json': decodedMatches(
            predicate<String>((s) {
              final meta = jsonDecode(s) as Map<String, dynamic>;
              final widgets = meta['widgets'] as Map<String, dynamic>;
              return widgets.containsKey('first') &&
                  widgets.containsKey('second') &&
                  (widgets['first'] as Map)['type'] == 'remote' &&
                  (widgets['second'] as Map)['type'] == 'remote';
            }, 'valid .rfw_meta.json with both remote widgets'),
          ),
        },
      );
      expect(result.succeeded, isTrue);
    });

    // NOTE: Custom widget tests that previously used rfw_gen.yaml have been
    // removed. Custom widget discovery now uses the Dart analyzer's Resolver,
    // which requires a full analysis context not available in testBuilder.
    // Resolver-based custom widget resolution is tested via integration tests
    // in the example app (build_runner end-to-end).
  });
}
