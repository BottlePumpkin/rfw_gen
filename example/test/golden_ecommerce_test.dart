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

  /// Pumps an e-commerce screen with network image support.
  /// Uses pump loops to drain timers without leaving pending state.
  Future<void> pumpEcommerceWidget(
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
          msg.contains('overflowed') ||
          msg.contains('Connection') ||
          msg.contains('Codec failed') ||
          msg.contains('image data')) {
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
            widget: FullyQualifiedWidgetName(
              const LibraryName(<String>['shop']),
              widget,
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );

    // Pump several frames to let layout settle without leaving pending timers
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shopHome golden', (tester) async {
    await pumpEcommerceWidget(tester, widget: 'shopHome');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/shop_home.png'),
    );
  });

  testWidgets('productList golden', (tester) async {
    await pumpEcommerceWidget(tester, widget: 'productList');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/product_list.png'),
    );
  });

  testWidgets('productDetail golden', (tester) async {
    // productDetail is stateful (state: {quantity: 1})
    await pumpEcommerceWidget(tester, widget: 'productDetail');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/product_detail.png'),
    );
  });

  testWidgets('cart golden', (tester) async {
    await pumpEcommerceWidget(tester, widget: 'cart');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/cart.png'),
    );
  });

  testWidgets('orderComplete golden', (tester) async {
    await pumpEcommerceWidget(tester, widget: 'orderComplete');
    await expectLater(
      find.byType(RemoteWidget),
      matchesGoldenFile('goldens/ecommerce/order_complete.png'),
    );
  });
}
