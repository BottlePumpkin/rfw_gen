import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/doc_table.dart';

void main() {
  testWidgets('DocTable renders headers and rows', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocTable(
            headers: ['Name', 'Type'],
            rows: [
              ['color', 'int'],
              ['padding', 'EdgeInsets'],
            ],
          ),
        ),
      ),
    );
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Type'), findsOneWidget);
    expect(find.text('color'), findsOneWidget);
    expect(find.text('EdgeInsets'), findsOneWidget);
  });
}
