import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw_gen_playground/widgets/link_text.dart';

void main() {
  testWidgets('LinkText renders blue text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: LinkText(text: 'Click me', page: 'home')),
      ),
    );
    expect(find.text('Click me'), findsOneWidget);
  });

  testWidgets('LinkText calls onNavigate on tap', (tester) async {
    String? navigatedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LinkText(
            text: 'Go',
            page: 'getting-started',
            onNavigate: (page) => navigatedTo = page,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Go'));
    expect(navigatedTo, 'getting-started');
  });
}
