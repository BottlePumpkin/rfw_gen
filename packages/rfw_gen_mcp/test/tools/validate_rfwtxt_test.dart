import 'dart:convert';

import 'package:rfw_gen_mcp/src/tools/validate_rfwtxt.dart';
import 'package:test/test.dart';

void main() {
  group('handleValidateRfwtxt', () {
    test('valid single widget - valid true, widgetCount 1', () {
      const rfwtxt = '''
import core.widgets;

widget myWidget = Text(text: "Hello");
''';
      final json = handleValidateRfwtxt({'rfwtxt': rfwtxt});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['valid'], isTrue);
      expect(data['widgetCount'], equals(1));
    });

    test('valid multi-widget with imports - widgetCount 2, imports list', () {
      const rfwtxt = '''
import core.widgets;
import material;

widget first = Text(text: "First");
widget second = Container(child: Text(text: "Second"));
''';
      final json = handleValidateRfwtxt({'rfwtxt': rfwtxt});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['valid'], isTrue);
      expect(data['widgetCount'], equals(2));
      final imports = data['imports'] as List;
      expect(imports, contains('core.widgets'));
      expect(imports, contains('material'));
    });

    test('invalid rfwtxt - valid false with error message', () {
      const rfwtxt = '''
this is not valid rfwtxt @@##!!
''';
      final json = handleValidateRfwtxt({'rfwtxt': rfwtxt});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['valid'], isFalse);
      expect(data['error'], isA<String>());
      expect(data['error'], isNotEmpty);
    });

    test('empty string - valid false', () {
      final json = handleValidateRfwtxt({'rfwtxt': ''});
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['valid'], isFalse);
    });
  });
}
