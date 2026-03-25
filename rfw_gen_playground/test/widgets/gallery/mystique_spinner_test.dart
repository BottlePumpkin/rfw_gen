import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/gallery/mystique_spinner.dart';

void main() {
  testWidgets('MystiqueSpinner renders CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueSpinner(),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MystiqueSpinner small size renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueSpinner(size: 'small'),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MystiqueSpinner large size renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueSpinner(size: 'large'),
    )));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
