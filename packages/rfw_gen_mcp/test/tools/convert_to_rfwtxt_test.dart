import 'dart:convert';

import 'package:rfw_gen_builder/rfw_gen_builder.dart';
import 'package:rfw_gen_mcp/src/tools/convert_to_rfwtxt.dart';
import 'package:test/test.dart';

void main() {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  group('handleConvertToRfwtxt', () {
    test('simple widget conversion succeeds', () {
      const source = "Widget buildMyWidget() { return Text('Hello'); }";
      final json = handleConvertToRfwtxt(converter, {'source': source});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['success'], isTrue);
      expect(data['rfwtxt'], isA<String>());
      expect(data['rfwtxt'], isNotEmpty);
      expect(data['warnings'], isNotNull);
    });

    test('unsupported widget produces errors list', () {
      const source =
          "Widget buildMyWidget() { return UnsupportedWidget123(); }";
      final json = handleConvertToRfwtxt(converter, {'source': source});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['success'], isFalse);
      expect(data['errors'], isA<List>());
      expect(data['errors'], isNotEmpty);
    });

    test('missing function - StateError caught, returns success false', () {
      const source = '''
// No function here, just a comment
''';
      final json = handleConvertToRfwtxt(converter, {'source': source});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['success'], isFalse);
      expect(data['errors'], isNotEmpty);
    });

    test('success result always includes warnings field', () {
      const source = "Widget buildHello() { return Text('Hi'); }";
      final json = handleConvertToRfwtxt(converter, {'source': source});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data.containsKey('warnings'), isTrue);
    });
  });
}
