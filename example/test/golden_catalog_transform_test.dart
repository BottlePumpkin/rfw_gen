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

  testWidgets('rotationDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'rotationDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/transform/rotation_demo.png'),
    );
  });

  testWidgets('scaleDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'scaleDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/transform/scale_demo.png'),
    );
  });

  testWidgets('fittedBoxDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'fittedBoxDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/transform/fitted_box_demo.png'),
    );
  });
}
