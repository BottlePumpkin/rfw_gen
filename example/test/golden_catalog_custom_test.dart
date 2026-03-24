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

  /// Pumps a custom widget with overflow suppression, without pumpAndSettle.
  Future<void> pumpCustomWidget(
    WidgetTester tester, {
    required String widget,
    bool useSettle = true,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exception.toString();
      if (msg.contains('HTTP') ||
          msg.contains('NetworkImage') ||
          msg.contains('SocketException') ||
          msg.contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

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
              widget: FullyQualifiedWidgetName(
                const LibraryName(<String>['customdemo']),
                widget,
              ),
              onEvent: (String name, DynamicMap args) {},
            ),
          ),
        ),
      ),
    );

    if (useSettle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('customTextDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customTextDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_text_demo.png'),
    );
  });

  testWidgets('customBounceTapperDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customBounceTapperDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile(
          'goldens/catalog/custom/custom_bounce_tapper_demo.png'),
    );
  });

  testWidgets('nullConditionalDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'nullConditionalDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/null_conditional_demo.png'),
    );
  });

  testWidgets('customButtonDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customButtonDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_button_demo.png'),
    );
  });

  testWidgets('customBadgeDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customBadgeDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_badge_demo.png'),
    );
  });

  testWidgets('customProgressBarDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customProgressBarDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_progress_bar_demo.png'),
    );
  });

  testWidgets('customColumnDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customColumnDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_column_demo.png'),
    );
  });

  testWidgets('skeletonContainerDemo golden', (tester) async {
    // SkeletonContainer has CircularProgressIndicator (animated) — use pump instead of pumpAndSettle
    await pumpCustomWidget(tester, widget: 'skeletonContainerDemo',
        useSettle: false);
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/skeleton_container_demo.png'),
    );
  });

  testWidgets('compareWidgetDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'compareWidgetDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/compare_widget_demo.png'),
    );
  });

  testWidgets('pvContainerDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'pvContainerDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/pv_container_demo.png'),
    );
  });

  testWidgets('customCardDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customCardDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_card_demo.png'),
    );
  });

  testWidgets('customTileDemo golden', (tester) async {
    // CustomTile uses ListTile which requires a Material ancestor
    await pumpCustomWidget(tester, widget: 'customTileDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_tile_demo.png'),
    );
  });

  testWidgets('customAppBarDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'customdemo', widget: 'customAppBarDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/custom/custom_app_bar_demo.png'),
    );
  });
}
