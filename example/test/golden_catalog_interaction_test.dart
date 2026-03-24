@Tags(['golden'])
library;

import 'package:flutter/material.dart';
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

  testWidgets('gestureDetectorDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'gestureDetectorDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/interaction/gesture_detector_demo.png'),
    );
  });

  testWidgets('inkWellDemo golden', (tester) async {
    // InkWell requires a Material ancestor
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Material(
          child: SizedBox(
            width: 400,
            height: 800,
            child: RemoteWidget(
              runtime: helper.runtime,
              data: helper.data,
              widget: const FullyQualifiedWidgetName(
                LibraryName(<String>['catalog']),
                'inkWellDemo',
              ),
              onEvent: (String name, DynamicMap args) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/interaction/ink_well_demo.png'),
    );
  });
}
