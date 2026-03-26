import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_preview/rfw_preview.dart';

void main() {
  group('RfwFileSource', () {
    late File tempFile;

    setUp(() {
      tempFile = File('${Directory.systemTemp.path}/test_widget.rfwtxt');
      tempFile.writeAsStringSync('''
import core.widgets;
widget testWidget = Center(child: Text(text: "Hello from file"));
''');
    });

    tearDown(() {
      if (tempFile.existsSync()) tempFile.deleteSync();
    });

    test('stores path and library', () {
      final source = RfwSource.file(
        tempFile.path,
        library: const LibraryName(['test']),
      );
      expect(source, isA<RfwFileSource>());
      final fileSource = source as RfwFileSource;
      expect(fileSource.path, tempFile.path);
      expect(fileSource.library, const LibraryName(['test']));
    });

    test('readAsString returns file content', () {
      final source = RfwFileSource(
        tempFile.path,
        library: const LibraryName(['test']),
      );
      final content = source.readAsString();
      expect(content, contains('testWidget'));
      expect(content, contains('Hello from file'));
    });

    test('readAsString throws on missing file', () {
      final source = RfwFileSource(
        '/nonexistent/path.rfwtxt',
        library: const LibraryName(['test']),
      );
      expect(() => source.readAsString(), throwsA(isA<FileSystemException>()));
    });
  });
}
