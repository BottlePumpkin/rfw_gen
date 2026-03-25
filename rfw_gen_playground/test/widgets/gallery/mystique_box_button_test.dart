import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/gallery/mystique_box_button.dart';

void main() {
  testWidgets('MystiqueBoxButton primary renders text', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MystiqueBoxButton(text: 'Click', type: 'primary'),
    )));
    expect(find.text('Click'), findsOneWidget);
  });

  testWidgets('MystiqueBoxButton disabled does not call onPressed', (tester) async {
    var pressed = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      body: MystiqueBoxButton(text: 'Disabled', type: 'disabled', onPressed: () => pressed = true),
    )));
    await tester.tap(find.text('Disabled'));
    expect(pressed, false);
  });
}
