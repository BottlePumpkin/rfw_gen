import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  group('RfwWidget', () {
    test('stores name', () {
      const annotation = RfwWidget('MyWidget');
      expect(annotation.name, equals('MyWidget'));
    });

    test('is const constructible', () {
      const annotation = RfwWidget('AnotherWidget');
      expect(annotation, isA<RfwWidget>());
    });

    test('stores empty string name', () {
      const annotation = RfwWidget('');
      expect(annotation.name, equals(''));
    });
  });

  group('RfwGenIssue', () {
    test('fatal issue isFatal returns true', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Something went wrong',
      );
      expect(issue.isFatal, isTrue);
    });

    test('warning issue isFatal returns false', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.warning,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Something to note',
      );
      expect(issue.isFatal, isFalse);
    });

    test('toString includes error label for fatal', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Fatal problem',
      );
      expect(issue.toString(), contains('[rfw_gen]'));
      expect(issue.toString(), contains('Error'));
      expect(issue.toString(), contains('Fatal problem'));
    });

    test('toString includes warning label for warning', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.warning,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Minor issue',
      );
      expect(issue.toString(), contains('Warning'));
      expect(issue.toString(), contains('Minor issue'));
    });

    test('toString includes line number when provided', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Error on line',
        line: 42,
      );
      expect(issue.toString(), contains('line 42'));
    });

    test('toString includes suggestion when provided', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.warning,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Check this',
        suggestion: 'Try doing X instead',
      );
      expect(issue.toString(), contains('Suggestion: Try doing X instead'));
    });

    test('toString omits line number when not provided', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Some error message',
      );
      expect(issue.toString(), isNot(contains('(line')));
    });

    test('toString includes column when provided', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Error here',
        line: 12,
        column: 8,
      );
      expect(issue.toString(), contains('line 12, col 8'));
    });

    test('toString shows only line when column is null', () {
      const issue = RfwGenIssue(
        severity: RfwGenSeverity.fatal,
        code: RfwGenIssueCode.unsupportedExpression,
        message: 'Error here',
        line: 12,
      );
      expect(issue.toString(), contains('(line 12)'));
      expect(issue.toString(), isNot(contains('col')));
    });
  });

  group('RfwGenException', () {
    test('toString joins all issues', () {
      const issues = [
        RfwGenIssue(
            severity: RfwGenSeverity.fatal,
            code: RfwGenIssueCode.unsupportedExpression,
            message: 'Error one'),
        RfwGenIssue(
            severity: RfwGenSeverity.warning,
            code: RfwGenIssueCode.unsupportedExpression,
            message: 'Warning two'),
      ];
      const exception = RfwGenException(issues);
      final str = exception.toString();
      expect(str, contains('Error one'));
      expect(str, contains('Warning two'));
    });

    test('stores issues list', () {
      const issues = [
        RfwGenIssue(
            severity: RfwGenSeverity.fatal,
            code: RfwGenIssueCode.unsupportedExpression,
            message: 'Test'),
      ];
      const exception = RfwGenException(issues);
      expect(exception.issues, hasLength(1));
      expect(exception.issues.first.message, equals('Test'));
    });

    test('is an Exception', () {
      const exception = RfwGenException([]);
      expect(exception, isA<Exception>());
    });
  });
}
