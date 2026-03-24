@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'helpers/golden_test_helper.dart';

void main() {
  late GoldenTestHelper helper;

  setUpAll(() async {
    await loadTestFonts();
    goldenFileComparator = TolerantGoldenFileComparator(
      Uri.parse('test/golden_stub'),
      tolerance: 0.005,
    );
  });

  setUp(() async {
    helper = GoldenTestHelper();
    await helper.setUp();
  });

  tearDown(() => helper.dispose());

  testWidgets('animationDefaultsDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'catalog', widget: 'animationDefaultsDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/other/animation_defaults_demo.png'),
    );
  });

  testWidgets('safeAreaDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'safeAreaDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/other/safe_area_demo.png'),
    );
  });

  testWidgets('argsPatternDemo golden', (tester) async {
    // argsPatternDemo uses args references — may render empty if no args provided
    await helper.pumpWidget(
        tester, library: 'catalog', widget: 'argsPatternDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/other/args_pattern_demo.png'),
    );
  });
}
