import 'package:rfw_gen/rfw_gen.dart';
import 'package:rfw_gen_builder/src/convert_result.dart';
import 'package:rfw_gen_builder/src/ir.dart';
import 'package:rfw_gen_builder/src/metadata_collector.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertResult', () {
    test('hasErrors is true when fatal issue present', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo = Text();',
        issues: [
          RfwGenIssue(
              severity: RfwGenSeverity.fatal,
              code: RfwGenIssueCode.unsupportedExpression,
              message: 'bad')
        ],
        widgetName: 'test',
        stateDecl: null,
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors is false when only warnings', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo = Text();',
        issues: [
          RfwGenIssue(
              severity: RfwGenSeverity.warning,
              code: RfwGenIssueCode.unsupportedExpression,
              message: 'meh')
        ],
        widgetName: 'test',
        stateDecl: null,
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.hasErrors, isFalse);
    });

    test('hasWarnings is true when warning present', () {
      final result = ConvertResult(
        rfwtxt: '',
        issues: [
          RfwGenIssue(
              severity: RfwGenSeverity.warning,
              code: RfwGenIssueCode.unsupportedExpression,
              message: 'w')
        ],
        widgetName: 'test',
        stateDecl: null,
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.hasWarnings, isTrue);
    });

    test('no issues means no errors and no warnings', () {
      final result = ConvertResult(
        rfwtxt: 'clean',
        issues: [],
        widgetName: 'test',
        stateDecl: null,
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isFalse);
    });

    test('widgetName is accessible', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo = Text();',
        issues: [],
        widgetName: 'foo',
        stateDecl: null,
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.widgetName, equals('foo'));
    });

    test('stateDecl is accessible', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo { x: false } = Text();',
        issues: [],
        widgetName: 'foo',
        stateDecl: {'x': IrBoolValue(false)},
        metadata:
            const RfwWidgetMetadata(dataRefs: {}, stateRefs: {}, events: {}),
      );
      expect(result.stateDecl, isNotNull);
      expect(result.stateDecl!['x'], equals(IrBoolValue(false)));
    });

    test('metadata contains collected refs', () {
      final result = ConvertResult(
        rfwtxt: '',
        issues: [],
        widgetName: 'bar',
        stateDecl: null,
        metadata: const RfwWidgetMetadata(
          dataRefs: {'user.name'},
          stateRefs: {'active'},
          events: {'tap'},
        ),
      );
      expect(result.metadata.dataRefs, equals({'user.name'}));
      expect(result.metadata.stateRefs, equals({'active'}));
      expect(result.metadata.events, equals({'tap'}));
    });
  });
}
