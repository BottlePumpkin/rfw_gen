import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:rfw_gen/rfw_gen.dart';
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
}
