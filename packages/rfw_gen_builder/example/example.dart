import 'package:rfw_gen_builder/rfw_gen_builder.dart';

void main() {
  // Create a converter with the core widget registry.
  final registry = WidgetRegistry.core();
  final converter = RfwConverter(registry: registry);

  // Convert a Dart widget function to rfwtxt format.
  const dartSource = '''
Widget buildHello() {
  return Center(
    child: Text('Hello, RFW!'),
  );
}
''';

  final result = converter.convertFromSource(dartSource);
  print(result.rfwtxt);

  // Check for any conversion issues.
  for (final issue in result.issues) {
    print(issue);
  }
}
