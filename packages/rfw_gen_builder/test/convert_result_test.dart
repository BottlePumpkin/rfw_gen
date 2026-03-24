import 'package:rfw_gen/rfw_gen.dart';
import 'package:rfw_gen_builder/src/convert_result.dart';
import 'package:test/test.dart';

void main() {
  group('ConvertResult', () {
    test('hasErrors is true when fatal issue present', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo = Text();',
        issues: [RfwGenIssue(severity: RfwGenSeverity.fatal, message: 'bad')],
      );
      expect(result.hasErrors, isTrue);
    });

    test('hasErrors is false when only warnings', () {
      final result = ConvertResult(
        rfwtxt: 'widget foo = Text();',
        issues: [RfwGenIssue(severity: RfwGenSeverity.warning, message: 'meh')],
      );
      expect(result.hasErrors, isFalse);
    });

    test('hasWarnings is true when warning present', () {
      final result = ConvertResult(
        rfwtxt: '',
        issues: [RfwGenIssue(severity: RfwGenSeverity.warning, message: 'w')],
      );
      expect(result.hasWarnings, isTrue);
    });

    test('no issues means no errors and no warnings', () {
      final result = ConvertResult(rfwtxt: 'clean', issues: []);
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isFalse);
    });
  });
}
