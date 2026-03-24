import 'dart:io';
import 'package:rfw/formats.dart';

void main() {
  final pairs = [
    ['lib/catalog/catalog_widgets.rfwtxt', 'assets/catalog_widgets.rfw'],
    ['lib/ecommerce/shop_widgets.rfwtxt', 'assets/shop_widgets.rfw'],
  ];

  for (final pair in pairs) {
    final source = File(pair[0]);
    final target = File(pair[1]);
    final also = File(pair[0].replaceAll('.rfwtxt', '.rfw'));

    print('Compiling ${pair[0]} ...');
    final content = source.readAsStringSync();
    final library = parseLibraryFile(content);
    final blob = encodeLibraryBlob(library);

    target.writeAsBytesSync(blob);
    also.writeAsBytesSync(blob);
    print('  -> ${pair[1]} (${blob.length} bytes)');
  }
  print('Done.');
}
