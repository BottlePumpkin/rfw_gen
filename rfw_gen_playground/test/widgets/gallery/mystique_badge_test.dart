import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/gallery/mystique_badge.dart';

void main() {
  testWidgets('MystiqueBadge dot renders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueBadge(type: 'dot'),
    )));
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('MystiqueBadge event renders with title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueBadge(type: 'event', title: 'NEW'),
    )));
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('MystiqueBadge count renders with title', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: MystiqueBadge(type: 'count', title: '5'),
    )));
    expect(find.text('5'), findsOneWidget);
  });
}
