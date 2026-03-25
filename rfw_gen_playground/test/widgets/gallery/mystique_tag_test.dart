import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/gallery/mystique_tag.dart';

void main() {
  testWidgets('MystiqueTag renders title text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueTag(title: 'Hello'),
    )));
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('MystiqueTag primary type renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueTag(title: 'Primary', type: 'primary'),
    )));
    expect(find.text('Primary'), findsOneWidget);
  });

  testWidgets('MystiqueTag outline type renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueTag(title: 'Outline', type: 'outline'),
    )));
    expect(find.text('Outline'), findsOneWidget);
  });
}
