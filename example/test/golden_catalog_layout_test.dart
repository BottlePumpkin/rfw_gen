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

  testWidgets('columnDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'columnDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/column_demo.png'),
    );
  });

  testWidgets('rowDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'rowDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/row_demo.png'),
    );
  });

  testWidgets('wrapDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'wrapDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/wrap_demo.png'),
    );
  });

  testWidgets('stackDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'stackDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/stack_demo.png'),
    );
  });

  testWidgets('expandedDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'expandedDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/expanded_demo.png'),
    );
  });

  testWidgets('sizedBoxDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'sizedBoxDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/sized_box_demo.png'),
    );
  });

  testWidgets('alignDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'alignDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/align_demo.png'),
    );
  });

  testWidgets('aspectRatioDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'aspectRatioDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/aspect_ratio_demo.png'),
    );
  });

  testWidgets('intrinsicDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'intrinsicDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/layout/intrinsic_demo.png'),
    );
  });
}
