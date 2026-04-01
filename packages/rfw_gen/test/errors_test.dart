import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('RfwGenIssueCode', () {
    test('enum has expected values', () {
      expect(RfwGenIssueCode.values,
          contains(RfwGenIssueCode.widgetNotRegistered));
      expect(RfwGenIssueCode.values,
          contains(RfwGenIssueCode.unsupportedExpression));
      expect(
          RfwGenIssueCode.values, contains(RfwGenIssueCode.loopVariableMisuse));
      expect(RfwGenIssueCode.values,
          contains(RfwGenIssueCode.stateFieldConversionFailed));
    });
  });

  group('RfwGenIssue with code', () {
    test('code is included in issue', () {
      final issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        message: 'Widget not found',
        code: RfwGenIssueCode.widgetNotRegistered,
      );
      expect(issue.code, equals(RfwGenIssueCode.widgetNotRegistered));
      expect(issue.isFatal, isTrue);
    });

    test('toString includes code name', () {
      final issue = RfwGenIssue(
        severity: RfwGenSeverity.warning,
        message: 'test',
        code: RfwGenIssueCode.loopVariableMisuse,
        line: 5,
        column: 12,
      );
      expect(issue.toString(), contains('loopVariableMisuse'));
      expect(issue.toString(), contains('line 5'));
    });

    test('code is required', () {
      final issue = RfwGenIssue(
        severity: RfwGenSeverity.warning,
        message: 'test',
        code: RfwGenIssueCode.unsupportedExpression,
      );
      expect(issue.code, isNotNull);
    });
  });
}
