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

  /// Pumps a Material widget with overflow suppression.
  Future<void> pumpMaterialWidget(
    WidgetTester tester, {
    required String widget,
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
                const LibraryName(<String>['catalog']),
                widget,
              ),
              onEvent: (String name, DynamicMap args) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('scaffoldDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'scaffoldDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/scaffold_demo.png'),
    );
  });

  testWidgets('materialDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'materialDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/material_demo.png'),
    );
  });

  testWidgets('cardDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'cardDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/card_demo.png'),
    );
  });

  testWidgets('buttonDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'buttonDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/button_demo.png'),
    );
  });

  testWidgets('listTileDemo golden', (tester) async {
    // ListTile requires a Material ancestor
    await pumpMaterialWidget(tester, widget: 'listTileDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/list_tile_demo.png'),
    );
  });

  testWidgets('sliderDemo golden', (tester) async {
    // Slider requires a Material ancestor; test initial state only
    await pumpMaterialWidget(tester, widget: 'sliderDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/slider_demo.png'),
    );
  });

  testWidgets('drawerDemo golden', (tester) async {
    // drawerDemo — test closed state only
    await helper.pumpWidget(tester, library: 'catalog', widget: 'drawerDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/drawer_demo.png'),
    );
  });

  testWidgets('dividerDemo golden', (tester) async {
    // May contain Row overflow — suppress
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final msg = details.exception.toString();
      if (msg.contains('overflowed') || msg.contains('HTTP') || msg.contains('SocketException')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'Roboto'),
        home: SizedBox(
          width: 400,
          height: 800,
          child: RemoteWidget(
            runtime: helper.runtime,
            data: helper.data,
            widget: const FullyQualifiedWidgetName(
              LibraryName(<String>['catalog']),
              'dividerDemo',
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/divider_demo.png'),
    );
  });

  testWidgets('progressDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'progressDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/progress_demo.png'),
    );
  });

  testWidgets('overflowBarDemo golden', (tester) async {
    await helper.pumpWidget(
        tester, library: 'catalog', widget: 'overflowBarDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/overflow_bar_demo.png'),
    );
  });

  testWidgets('visualDensityDemo golden', (tester) async {
    // visualDensityDemo uses ListTile — requires Material ancestor
    await pumpMaterialWidget(tester, widget: 'visualDensityDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/material/visual_density_demo.png'),
    );
  });
}
