import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/code_block.dart';

void main() {
  testWidgets('CodeBlock renders code text on dark background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CodeBlock(code: 'void main() {}'),
        ),
      ),
    );
    expect(find.text('void main() {}'), findsOneWidget);
    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration?;
    final color = container.color ?? decoration?.color;
    expect(color, equals(const Color(0xFF1E1E1E)));
  });

  testWidgets('CodeBlock uses monospace font', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CodeBlock(code: 'test')),
      ),
    );
    final text = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(text.style?.fontFamily, 'monospace');
  });
}
