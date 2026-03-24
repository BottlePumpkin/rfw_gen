import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'test_data.dart';

// ============================================================
// Network Image Mock
// ============================================================

/// 모든 HTTP 요청에 1x1 투명 PNG를 반환하는 HttpOverrides.
class TestHttpOverrides extends HttpOverrides {}

// ============================================================
// Tolerant Golden File Comparator
// ============================================================

/// 0.5% 픽셀 차이를 허용하는 GoldenFileComparator.
class TolerantGoldenFileComparator extends LocalFileComparator {
  final double tolerance;

  TolerantGoldenFileComparator(
    super.testFile, {
    this.tolerance = 0.005,
  });

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenFile = _resolveGoldenFile(golden);
    if (!goldenFile.existsSync()) {
      return super.compare(imageBytes, golden);
    }

    final goldenBytes = goldenFile.readAsBytesSync();

    if (_bytesEqual(imageBytes, goldenBytes)) return true;

    final testImage = await decodeImageFromList(imageBytes);
    final goldenImage = await decodeImageFromList(goldenBytes);

    if (testImage.width != goldenImage.width ||
        testImage.height != goldenImage.height) {
      return super.compare(imageBytes, golden);
    }

    final testByteData = await testImage.toByteData();
    final goldenByteData = await goldenImage.toByteData();

    if (testByteData == null || goldenByteData == null) {
      return super.compare(imageBytes, golden);
    }

    final totalBytes = testByteData.lengthInBytes;
    if (totalBytes == 0) return super.compare(imageBytes, golden);

    int diffBytes = 0;
    for (int i = 0; i < totalBytes; i++) {
      if (testByteData.getUint8(i) != goldenByteData.getUint8(i)) {
        diffBytes++;
      }
    }

    final diffPercent = diffBytes / totalBytes;
    if (diffPercent <= tolerance) return true;

    return super.compare(imageBytes, golden);
  }

  File _resolveGoldenFile(Uri golden) {
    return File.fromUri(basedir.resolveUri(golden));
  }

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ============================================================
// Font Loading
// ============================================================

/// 테스트 환경 초기화: 폰트 로드 + HttpOverrides 등록.
Future<void> loadTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TestHttpOverrides();

  final regular = File('test/fonts/Roboto-Regular.ttf')
      .readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final bold = File('test/fonts/Roboto-Bold.ttf')
      .readAsBytes()
      .then((bytes) => ByteData.view(bytes.buffer));
  final loader = FontLoader('Roboto')
    ..addFont(regular)
    ..addFont(bold);
  await loader.load();
}

// ============================================================
// Golden Test Helper
// ============================================================

class GoldenTestHelper {
  late Runtime runtime;
  late DynamicContent data;

  Future<void> setUp() async {
    runtime = Runtime();

    runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    runtime.update(
      const LibraryName(<String>['material']),
      createMaterialWidgets(),
    );

    // Custom local widget library 등록 (main.dart와 동일)
    runtime.update(
      const LibraryName(<String>['custom', 'widgets']),
      LocalWidgetLibrary(_buildCustomWidgets()),
    );

    // .rfw 바이너리 로드
    final catalogBlob = File('assets/catalog_widgets.rfw').readAsBytesSync();
    final shopBlob = File('assets/shop_widgets.rfw').readAsBytesSync();
    final customBlob = File('assets/custom_widgets.rfw').readAsBytesSync();
    runtime.update(
      const LibraryName(<String>['catalog']),
      decodeLibraryBlob(catalogBlob),
    );
    runtime.update(
      const LibraryName(<String>['shop']),
      decodeLibraryBlob(shopBlob),
    );
    runtime.update(
      const LibraryName(<String>['customdemo']),
      decodeLibraryBlob(customBlob),
    );

    data = DynamicContent();
    setupTestData(data);
  }

  Future<void> pumpWidget(
    WidgetTester tester, {
    required String library,
    required String widget,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception.toString().contains('HTTP') ||
          details.exception.toString().contains('NetworkImage') ||
          details.exception.toString().contains('SocketException')) {
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
            runtime: runtime,
            data: data,
            widget: FullyQualifiedWidgetName(
              LibraryName(<String>[library]),
              widget,
            ),
            onEvent: (String name, DynamicMap args) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void dispose() {
    runtime.dispose();
    data = DynamicContent();
  }

  /// Custom local widget builders (main.dart와 동일)
  static Map<String, LocalWidgetBuilder> _buildCustomWidgets() {
    return <String, LocalWidgetBuilder>{
      'CustomText': (BuildContext context, DataSource source) {
        final text = source.v<String>(['text']) ?? '';
        final fontType = source.v<String>(['fontType']) ?? 'body';
        final color = Color(source.v<int>(['color']) ?? 0xFF000000);
        final maxLines = source.v<int>(['maxLines']);
        final style = switch (fontType) {
          'heading' => TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          'button' => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
          'caption' => TextStyle(fontSize: 12, color: color),
          _ => TextStyle(fontSize: 14, color: color),
        };
        return Text(text, style: style, maxLines: maxLines);
      },
      'CustomBounceTapper': (BuildContext context, DataSource source) {
        return GestureDetector(
          onTap: source.voidHandler(['onTap']),
          child: source.optionalChild(['child']),
        );
      },
      'NullConditionalWidget': (BuildContext context, DataSource source) {
        final child = source.optionalChild(['child']);
        final nullChild = source.optionalChild(['nullChild']);
        return child ?? nullChild ?? const SizedBox.shrink();
      },
      'CustomButton': (BuildContext context, DataSource source) {
        return ElevatedButton(
          onPressed: source.voidHandler(['onPressed']),
          onLongPress: source.voidHandler(['onLongPress']),
          child: source.child(['child']),
        );
      },
      'CustomBadge': (BuildContext context, DataSource source) {
        final label = source.v<String>(['label']) ?? '';
        final count = source.v<int>(['count']) ?? 0;
        final bg = Color(source.v<int>(['backgroundColor']) ?? 0xFF9E9E9E);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text('$label${count > 0 ? ' ($count)' : ''}',
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        );
      },
      'CustomProgressBar': (BuildContext context, DataSource source) {
        final value = source.v<double>(['value']) ?? 0.0;
        final color = Color(source.v<int>(['color']) ?? 0xFF2196F3);
        final shape = source.v<String>(['shape']) ?? 'rounded';
        final height = source.v<double>(['height']) ?? 4.0;
        return ClipRRect(
          borderRadius: BorderRadius.circular(shape == 'rounded' ? height / 2 : 0),
          child: LinearProgressIndicator(value: value, color: color, minHeight: height),
        );
      },
      'CustomColumn': (BuildContext context, DataSource source) {
        final spacing = source.v<double>(['spacing']) ?? 0.0;
        final dividerColor = Color(source.v<int>(['dividerColor']) ?? 0x00000000);
        final children = <Widget>[];
        for (var i = 0; i < source.length(['children']); i++) {
          if (i > 0) {
            if (spacing > 0) children.add(SizedBox(height: spacing));
            if (dividerColor.a > 0) children.add(Divider(color: dividerColor, height: 1));
          }
          children.add(source.child(['children', i]));
        }
        return Column(children: children);
      },
      'SkeletonContainer': (BuildContext context, DataSource source) {
        final isLoading = source.v<bool>(['isLoading']) ?? false;
        final child = source.optionalChild(['child']);
        if (isLoading) {
          return Container(
            height: 48, color: Colors.grey[300],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return child ?? const SizedBox.shrink();
      },
      'CompareWidget': (BuildContext context, DataSource source) {
        final child = source.optionalChild(['child']);
        final trueChild = source.optionalChild(['trueChild']);
        final falseChild = source.optionalChild(['falseChild']);
        return Column(children: [
          if (child != null) child,
          if (trueChild != null) trueChild,
          if (falseChild != null) falseChild,
        ]);
      },
      'PvContainer': (BuildContext context, DataSource source) {
        final onPv = source.voidHandler(['onPv']);
        WidgetsBinding.instance.addPostFrameCallback((_) => onPv?.call());
        return source.optionalChild(['child']) ?? const SizedBox.shrink();
      },
      'CustomCard': (BuildContext context, DataSource source) {
        final elevation = source.v<double>(['elevation']) ?? 1.0;
        final borderRadius = source.v<double>(['borderRadius']) ?? 8.0;
        return GestureDetector(
          onTap: source.voidHandler(['onTap']),
          child: Card(
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: source.child(['child']),
          ),
        );
      },
      'CustomTile': (BuildContext context, DataSource source) {
        return ListTile(
          leading: source.optionalChild(['leading']),
          title: source.optionalChild(['title']),
          subtitle: source.optionalChild(['subtitle']),
          trailing: source.optionalChild(['trailing']),
          onTap: source.voidHandler(['onTap']),
        );
      },
      'CustomAppBar': (BuildContext context, DataSource source) {
        final actions = <Widget>[];
        for (var i = 0; i < source.length(['actions']); i++) {
          actions.add(source.child(['actions', i]));
        }
        return AppBar(
          title: source.optionalChild(['title']),
          actions: actions.isEmpty ? null : actions,
          backgroundColor: const Color(0xFF2196F3),
        );
      },
    };
  }
}
