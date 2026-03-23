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

    test('loads custom widgets from rfw_gen.yaml', () async {
      final result = await testBuilder(
        rfwWidgetBuilder(BuilderOptions.empty),
        {
          'a|rfw_gen.yaml': '''
widgets:
  MystiqueText:
    import: mystique.widgets
''',
          'a|lib/widgets.dart': '''
@RfwWidget('card')
Widget buildCard() {
  return MystiqueText(text: 'hello', fontType: 'heading24Bold');
}
''',
        },
        outputs: {
          'a|lib/widgets.rfwtxt': decodedMatches(
            allOf(
              contains('import mystique.widgets;'),
              contains('widget card'),
              contains('MystiqueText('),
              contains('text: "hello"'),
              contains('fontType: "heading24Bold"'),
            ),
          ),
          'a|lib/widgets.rfw': isNotEmpty,
        },
      );
      expect(result.succeeded, isTrue);
    });

    test('custom widget with widget-value param in rfw_gen.yaml', () async {
      final result = await testBuilder(
        rfwWidgetBuilder(BuilderOptions.empty),
        {
          'a|rfw_gen.yaml': '''
widgets:
  NullConditional:
    import: custom.widgets
    child_type: optionalChild
  MyText:
    import: mystique.widgets
''',
          'a|lib/widgets.dart': '''
@RfwWidget('card')
Widget buildCard() {
  return NullConditional(
    child: MyText(text: 'visible'),
    nullChild: MyText(text: 'fallback'),
  );
}
''',
        },
        outputs: {
          'a|lib/widgets.rfwtxt': decodedMatches(
            allOf(
              contains('import custom.widgets;'),
              contains('import mystique.widgets;'),
              contains('nullChild: MyText('),
            ),
          ),
          'a|lib/widgets.rfw': isNotEmpty,
        },
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
