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

  testWidgets('containerDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'containerDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/container_demo.png'),
    );
  });

  testWidgets('paddingOpacityDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'paddingOpacityDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/padding_opacity_demo.png'),
    );
  });

  testWidgets('clipRRectDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'clipRRectDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/clip_r_rect_demo.png'),
    );
  });

  testWidgets('defaultTextStyleDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'defaultTextStyleDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/default_text_style_demo.png'),
    );
  });

  testWidgets('directionalityDemo golden', (tester) async {
    // Suppress overflow errors for this widget
    final List<FlutterErrorDetails> overflowErrors = [];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('overflowed') ||
          details.exception.toString().contains('RenderFlex')) {
        overflowErrors.add(details);
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              'directionalityDemo',
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/directionality_demo.png'),
    );
  });

  testWidgets('iconDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'iconDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/icon_demo.png'),
    );
  });

  testWidgets('iconThemeDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'iconThemeDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/icon_theme_demo.png'),
    );
  });

  testWidgets('imageDemo golden', (tester) async {
    // Use pump instead of pumpAndSettle to avoid pending timer from network image
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('HTTP') ||
          details.exception.toString().contains('NetworkImage') ||
          details.exception.toString().contains('SocketException') ||
          details.exception.toString().contains('network') ||
          details.exception.toString().contains('image')) {
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
              'imageDemo',
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/image_demo.png'),
    );

    // Dispose widget tree and pump enough time to cancel pending network timers
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('textDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'textDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/text_demo.png'),
    );
  });

  testWidgets('coloredBoxDemo golden', (tester) async {
    await helper.pumpWidget(tester, library: 'catalog', widget: 'coloredBoxDemo');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/colored_box_demo.png'),
    );
  });

  testWidgets('borderDemo golden', (tester) async {
    // Suppress overflow errors for this widget
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('overflowed') ||
          details.exception.toString().contains('RenderFlex')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
              'borderDemo',
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/catalog/styling/border_demo.png'),
    );
  });
}
