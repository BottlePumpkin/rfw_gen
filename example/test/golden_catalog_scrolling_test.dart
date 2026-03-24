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

  testWidgets('listViewDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'listViewDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/scrolling/list_view_demo.png'),
    );
  });

  testWidgets('gridViewDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'gridViewDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/scrolling/grid_view_demo.png'),
    );
  });

  testWidgets('scrollViewDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'scrollViewDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/scrolling/scroll_view_demo.png'),
    );
  });

  testWidgets('listBodyDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'listBodyDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/scrolling/list_body_demo.png'),
    );
  });
}
