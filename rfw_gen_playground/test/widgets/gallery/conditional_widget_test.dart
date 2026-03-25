import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/gallery/conditional_widget.dart';

void main() {
  testWidgets('shows childIfTrue when condition is true', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: ConditionalWidget(condition: true, childIfTrue: Text('YES'), childIfFalse: Text('NO')),
    )));
    expect(find.text('YES'), findsOneWidget);
    expect(find.text('NO'), findsNothing);
  });

  testWidgets('shows childIfFalse when condition is false', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: ConditionalWidget(condition: false, childIfTrue: Text('YES'), childIfFalse: Text('NO')),
    )));
    expect(find.text('NO'), findsOneWidget);
    expect(find.text('YES'), findsNothing);
  });
}
