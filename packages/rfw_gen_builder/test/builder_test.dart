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
        },
      );
      expect(result.succeeded, isTrue);
    });
  });
}
