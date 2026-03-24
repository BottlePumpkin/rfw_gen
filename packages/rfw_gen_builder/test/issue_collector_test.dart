import 'package:rfw_gen/rfw_gen.dart';
import 'package:rfw_gen_builder/src/issue_collector.dart';
import 'package:test/test.dart';

void main() {
  group('IssueCollector', () {
    test('warning adds a warning issue', () {
      final collector = IssueCollector('hello\nworld');
      collector.warning('test warning');
      expect(collector.issues, hasLength(1));
      expect(collector.issues.first.severity, RfwGenSeverity.warning);
      expect(collector.issues.first.message, 'test warning');
    });

    test('fatal adds a fatal issue', () {
      final collector = IssueCollector('hello');
      collector.fatal('test fatal');
      expect(collector.hasFatal, isTrue);
    });

    test('hasIssues returns false when empty', () {
      final collector = IssueCollector('');
      expect(collector.hasIssues, isFalse);
    });

    test('offset converts to correct line and column', () {
      // "ab\ncd\nef" — offset 3 = 'c' = line 2, col 1
      final collector = IssueCollector('ab\ncd\nef');
      collector.warning('at c', offset: 3);
      expect(collector.issues.first.line, 2);
      expect(collector.issues.first.column, 1);
    });

    test('offset at start of file', () {
      final collector = IssueCollector('hello');
      collector.warning('at start', offset: 0);
      expect(collector.issues.first.line, 1);
      expect(collector.issues.first.column, 1);
    });

    test('offset at end of line', () {
      final collector = IssueCollector('abc\ndef');
      collector.warning('at c', offset: 2);
      expect(collector.issues.first.line, 1);
      expect(collector.issues.first.column, 3);
    });

    test('null offset results in null line and column', () {
      final collector = IssueCollector('hello');
      collector.warning('no offset');
      expect(collector.issues.first.line, isNull);
      expect(collector.issues.first.column, isNull);
    });

    test('suggestion is stored', () {
      final collector = IssueCollector('');
      collector.warning('msg', suggestion: 'try X');
      expect(collector.issues.first.suggestion, 'try X');
    });

    test('collects multiple issues', () {
      final collector = IssueCollector('');
      collector.warning('w1');
      collector.warning('w2');
      collector.fatal('f1');
      expect(collector.issues, hasLength(3));
      expect(collector.hasFatal, isTrue);
    });
  });
}
