import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw/formats.dart';
import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:rfw_gen_builder/src/expression_converter.dart';
import 'package:test/test.dart';

Expression parseExpression(String code) {
  final result = parseString(content: 'final x = $code;');
  final unit = result.unit;
  final decl = unit.declarations.first as TopLevelVariableDeclaration;
  return decl.variables.variables.first.initializer!;
}

/// Maps each transformer key to a representative Flutter expression.
/// If a new transformer key is added to WidgetRegistry without an entry here,
/// the test will fail — forcing the developer to also add converter support.
const _sampleExpressions = <String?, String>{
  'color': 'Color(0xFF000000)',
  'edgeInsets': 'EdgeInsets.all(8.0)',
  'enum': '"start"',
  'alignment': 'Alignment.center',
  'borderRadius': 'BorderRadius.circular(8.0)',
  'textStyle': 'TextStyle(fontSize: 14.0)',
  'boxDecoration': 'BoxDecoration(color: Color(0xFF000000))',
  'shapeBorder': 'RoundedRectangleBorder()',
  'duration': 'Duration(milliseconds: 300)',
  'curve': 'Curves.easeInOut',
  'iconData': 'RfwIcon.home',
  'imageProvider': 'NetworkImage("https://example.com/img.png")',
  'visualDensity': 'VisualDensity.compact',
  'gridDelegate':
      'SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2)',
  null: '16.0', // direct pass-through (ParamMapping.direct)
};

void main() {
  late WidgetRegistry registry;
  late ExpressionConverter converter;

  setUp(() {
    registry = WidgetRegistry.core();
    converter = ExpressionConverter();
  });

  group('Spec sync: Registry ↔ Converter consistency', () {
    test('every transformer key has a sample expression', () {
      final allTransformers = <String?>{};
      for (final widget in registry.supportedWidgets.values) {
        for (final param in widget.params.values) {
          allTransformers.add(param.transformer);
        }
      }

      for (final key in allTransformers) {
        expect(
          _sampleExpressions.containsKey(key),
          isTrue,
          reason: 'Transformer "$key" has no sample expression in '
              '_sampleExpressions. Add one to ensure converter coverage.',
        );
      }
    });

    test('every sample expression converts without error', () {
      for (final entry in _sampleExpressions.entries) {
        final key = entry.key;
        final code = entry.value;
        final expr = parseExpression(code);
        expect(
          () => converter.convert(expr),
          returnsNormally,
          reason: 'Converter failed for transformer "$key" '
              'with expression: $code',
        );
      }
    });

    test('every widget param can be converted via its transformer', () {
      for (final entry in registry.supportedWidgets.entries) {
        final widgetName = entry.key;
        final widget = entry.value;
        for (final paramEntry in widget.params.entries) {
          final paramName = paramEntry.key;
          final transformer = paramEntry.value.transformer;
          final code = _sampleExpressions[transformer];
          if (code == null) continue; // covered by first test

          final expr = parseExpression(code);
          expect(
            () => converter.convert(expr),
            returnsNormally,
            reason: '$widgetName.$paramName (transformer: $transformer) '
                'failed with expression: $code',
          );
        }
      }
    });
  });

  group('Spec sync: Regression guard', () {
    test('widget count does not regress', () {
      expect(
        registry.supportedWidgets.length,
        greaterThanOrEqualTo(56),
        reason: 'Widget count decreased. Did you accidentally remove a widget?',
      );
    });

    test('total param + handler count does not regress', () {
      var totalParams = 0;
      var totalHandlers = 0;
      for (final widget in registry.supportedWidgets.values) {
        totalParams += widget.params.length;
        totalHandlers += widget.handlerParams.length;
      }
      // Print for visibility when updating the baseline
      // ignore: avoid_print
      print('Current counts: params=$totalParams, handlers=$totalHandlers, '
          'total=${totalParams + totalHandlers}');
      expect(
        totalParams + totalHandlers,
        greaterThanOrEqualTo(233),
        reason: 'Total param+handler count decreased. '
            'Did you accidentally remove params?',
      );
    });
  });

  group('Spec sync: End-to-end rfwtxt parsing', () {
    late RfwConverter rfwConverter;

    setUp(() {
      rfwConverter = RfwConverter(registry: WidgetRegistry.core());
    });

    test('Container with all params produces parseable rfwtxt', () {
      const input = '''
Widget build() {
  return Container(
    alignment: Alignment.center,
    padding: EdgeInsets.all(8.0),
    color: Color(0xFF000000),
    width: 100.0,
    height: 50.0,
    clipBehavior: Clip.hardEdge,
    margin: EdgeInsets.symmetric(horizontal: 4.0),
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: Text('hello'),
  );
}
''';
      final result = rfwConverter.convertFromSource(input);
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('Card with shape produces parseable rfwtxt', () {
      const input = '''
Widget build() {
  return Card(
    color: Color(0xFFFFFFFF),
    elevation: 4.0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
      side: BorderSide(color: Color(0xFF000000), width: 1.0),
    ),
    margin: EdgeInsets.all(8.0),
    child: Text('card'),
  );
}
''';
      final result = rfwConverter.convertFromSource(input);
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });

    test('Row with textDirection produces parseable rfwtxt', () {
      const input = '''
Widget build() {
  return Row(
    textDirection: TextDirection.rtl,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [Text('a'), Text('b')],
  );
}
''';
      final result = rfwConverter.convertFromSource(input);
      expect(() => parseLibraryFile(result.rfwtxt!), returnsNormally);
    });
  });
}
