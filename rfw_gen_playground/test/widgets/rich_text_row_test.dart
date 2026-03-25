import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/rich_text_row.dart';

void main() {
  testWidgets('RichTextRow renders multiple segments', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RichTextRow(
            segments: [
              TextSegment(text: 'Hello '),
              TextSegment(text: 'World', bold: true),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(RichText), findsOneWidget);
  });

  testWidgets('RichTextRow applies bold style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RichTextRow(
            segments: [
              TextSegment(text: 'normal '),
              TextSegment(text: 'bold', bold: true),
            ],
          ),
        ),
      ),
    );
    final richText = tester.widget<RichText>(find.byType(RichText));
    final textSpan = richText.text as TextSpan;
    final boldSpan = textSpan.children![1] as TextSpan;
    expect(boldSpan.style?.fontWeight, FontWeight.bold);
  });
}
