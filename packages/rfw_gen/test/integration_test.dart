import 'package:rfw/formats.dart';
import 'package:rfw_gen/rfw_gen.dart';
import 'package:test/test.dart';

void main() {
  late RfwConverter converter;

  setUp(() {
    converter = RfwConverter(registry: WidgetRegistry.core());
  });

  group('rfwtxt → parseLibraryFile roundtrip', () {
    test('Text widget parses without error', () {
      const input = "Widget buildGreeting() { return Text('Hello World'); }";
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('Column with 3 children parses without error', () {
      const input = '''
Widget buildList() {
  return Column(
    children: [
      Text('First'),
      Text('Second'),
      Text('Third'),
    ],
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('nested Container > Column > [Text, SizedBox, Text] with color and padding parses without error', () {
      const input = '''
Widget buildNested() {
  return Container(
    color: Color(0xFF42A5F5),
    padding: EdgeInsets.all(16.0),
    child: Column(
      children: [
        Text('Top'),
        SizedBox(width: 8.0, height: 8.0),
        Text('Bottom'),
      ],
    ),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('Row with mainAxisAlignment enum parses without error', () {
      const input = '''
Widget buildToolbar() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Left'),
      Text('Right'),
    ],
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      final library = parseLibraryFile(rfwtxt);
      expect(library.widgets, isNotEmpty);
    });

    test('rfwtxt → binary blob roundtrip produces decodable library', () {
      const input = '''
Widget buildCard() {
  return Container(
    color: Color(0xFF42A5F5),
    padding: EdgeInsets.all(8.0),
    child: Text('Hello'),
  );
}
''';
      final rfwtxt = converter.convertFromSource(input);
      final blob = converter.toBlob(rfwtxt);
      final decoded = decodeLibraryBlob(blob);
      expect(decoded.widgets, isNotEmpty);
    });

    test('multiple widgets: blob size is reasonable', () {
      const input1 = "Widget buildFirst() { return Text('First'); }";
      const input2 = "Widget buildSecond() { return Text('Second'); }";

      final rfwtxt1 = converter.convertFromSource(input1);
      final rfwtxt2 = converter.convertFromSource(input2);

      final blob1 = converter.toBlob(rfwtxt1);
      final blob2 = converter.toBlob(rfwtxt2);

      // Each blob should be non-empty and reasonably small (< 1KB for simple widgets).
      expect(blob1, isNotEmpty);
      expect(blob2, isNotEmpty);
      expect(blob1.length, lessThan(1024));
      expect(blob2.length, lessThan(1024));

      // Both blobs decode correctly.
      final lib1 = decodeLibraryBlob(blob1);
      final lib2 = decodeLibraryBlob(blob2);
      expect(lib1.widgets, isNotEmpty);
      expect(lib2.widgets, isNotEmpty);
    });
  });
}
