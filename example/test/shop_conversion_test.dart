import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/formats.dart';

void main() {
  test('shop_widgets.rfwtxt is valid rfwtxt', () {
    final file = File('lib/ecommerce/shop_widgets.rfwtxt');
    expect(file.existsSync(), isTrue, reason: 'Run build_runner first');
    final content = file.readAsStringSync();
    expect(content.isNotEmpty, isTrue);
    final result = parseLibraryFile(content);
    expect(result, isNotNull);
  });
}
