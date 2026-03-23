import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';
import 'package:rfw_gen/rfw_gen.dart';

void main() {
  late Runtime runtime;
  late DynamicContent data;

  // RFW uses 'core.widgets' as import statement, which maps to ['core', 'widgets'].
  const coreLibraryName = LibraryName(<String>['core', 'widgets']);
  const testLibraryName = LibraryName(<String>['test']);

  setUp(() {
    runtime = Runtime();
    runtime.update(coreLibraryName, createCoreWidgets());
    data = DynamicContent();
  });

  tearDown(() {
    runtime.dispose();
  });

  testWidgets('Text widget renders correctly', (tester) async {
    final converter = RfwConverter(registry: WidgetRegistry.core());
    final rfwtxt = converter.convertFromSource('''
Widget buildGreeting() {
  return Text('Hello, RFW!');
}
''');
    final blob = converter.toBlob(rfwtxt);
    runtime.update(testLibraryName, decodeLibraryBlob(blob));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RemoteWidget(
              runtime: runtime,
              data: data,
              widget: const FullyQualifiedWidgetName(
                testLibraryName,
                'greeting',
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/text_greeting.png'),
    );
  });

  testWidgets('Column with multiple children renders correctly', (tester) async {
    final converter = RfwConverter(registry: WidgetRegistry.core());
    final rfwtxt = converter.convertFromSource('''
Widget buildColumnLayout() {
  return Column(
    children: [
      Text('First'),
      SizedBox(height: 8.0),
      Text('Second'),
    ],
  );
}
''');
    final blob = converter.toBlob(rfwtxt);
    runtime.update(testLibraryName, decodeLibraryBlob(blob));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RemoteWidget(
              runtime: runtime,
              data: data,
              widget: const FullyQualifiedWidgetName(
                testLibraryName,
                'columnLayout',
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/column_with_children.png'),
    );
  });

  testWidgets('Container with color, padding, and child Text renders correctly',
      (tester) async {
    final converter = RfwConverter(registry: WidgetRegistry.core());
    final rfwtxt = converter.convertFromSource('''
Widget buildStyledBox() {
  return Container(
    color: Color(0xFF2196F3),
    padding: EdgeInsets.all(16.0),
    child: Text('Styled'),
  );
}
''');
    final blob = converter.toBlob(rfwtxt);
    runtime.update(testLibraryName, decodeLibraryBlob(blob));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RemoteWidget(
              runtime: runtime,
              data: data,
              widget: const FullyQualifiedWidgetName(
                testLibraryName,
                'styledBox',
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/container_styled.png'),
    );
  });
}
