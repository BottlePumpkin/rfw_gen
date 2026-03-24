import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rfw/rfw.dart';

import 'test_data.dart';

// ============================================================
// Network Image Mock
// ============================================================

// 1x1 투명 PNG (valid, base64: iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==)
final _kTransparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// 모든 HTTP 요청에 1x1 투명 PNG를 반환하는 HttpOverrides.
/// 실제 네트워크 연결을 하지 않고 즉시 응답을 반환합니다.
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return _MockHttpClient();
  }
}

class _MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) async {
    return _MockHttpClientRequest(
        Uri(scheme: 'http', host: host, port: port, path: path));
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _MockHttpClientRequest(url);
  }

  @override
  Future<HttpClientRequest> open(
          String method, String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> postUrl(Uri url) async =>
      _MockHttpClientRequest(url);
  @override
  Future<HttpClientRequest> post(String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> putUrl(Uri url) async =>
      _MockHttpClientRequest(url);
  @override
  Future<HttpClientRequest> put(String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> deleteUrl(Uri url) async =>
      _MockHttpClientRequest(url);
  @override
  Future<HttpClientRequest> delete(
          String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> headUrl(Uri url) async =>
      _MockHttpClientRequest(url);
  @override
  Future<HttpClientRequest> head(String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));
  @override
  Future<HttpClientRequest> patchUrl(Uri url) async =>
      _MockHttpClientRequest(url);
  @override
  Future<HttpClientRequest> patch(String host, int port, String path) async =>
      _MockHttpClientRequest(
          Uri(scheme: 'http', host: host, port: port, path: path));

  @override
  bool autoUncompress = true;
  @override
  Duration? connectionTimeout;
  @override
  Duration idleTimeout = const Duration(seconds: 15);
  @override
  int? maxConnectionsPerHost;
  @override
  String? userAgent;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {}
  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}
  @override
  set authenticate(
      Future<bool> Function(Uri url, String scheme, String? realm)? f) {}
  @override
  set authenticateProxy(
      Future<bool> Function(
              String host, int port, String scheme, String? realm)?
          f) {}
  @override
  set badCertificateCallback(
      bool Function(X509Certificate cert, String host, int port)? callback) {}
  @override
  set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) {}
  @override
  set findProxy(String Function(Uri url)? f) {}
  @override
  set keyLog(Function(String line)? callback) {}

  @override
  void close({bool force = false}) {}
}

class _MockHttpClientRequest implements HttpClientRequest {
  final Uri _uri;
  _MockHttpClientRequest(this._uri);

  @override
  Future<HttpClientResponse> close() async {
    return _MockHttpClientResponse();
  }

  @override
  HttpHeaders get headers => _MockHeaders();
  @override
  Encoding get encoding => utf8;
  @override
  set encoding(Encoding value) {}
  @override
  bool get bufferOutput => true;
  @override
  set bufferOutput(bool value) {}
  @override
  int get contentLength => -1;
  @override
  set contentLength(int value) {}
  @override
  bool get persistentConnection => true;
  @override
  set persistentConnection(bool value) {}
  @override
  bool get followRedirects => true;
  @override
  set followRedirects(bool value) {}
  @override
  int get maxRedirects => 5;
  @override
  set maxRedirects(int value) {}
  @override
  Uri get uri => _uri;
  @override
  String get method => 'GET';
  @override
  HttpConnectionInfo? get connectionInfo => null;
  @override
  List<Cookie> get cookies => [];

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}
  @override
  void add(List<int> data) {}
  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future addStream(Stream<List<int>> stream) async {}
  @override
  Future flush() async {}
  @override
  void write(Object? obj) {}
  @override
  void writeAll(Iterable objects, [String separator = '']) {}
  @override
  void writeCharCode(int charCode) {}
  @override
  void writeln([Object? obj = '']) {}
  @override
  Future<HttpClientResponse> get done async => _MockHttpClientResponse();
}

class _MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final int statusCode = 200;
  @override
  final String reasonPhrase = 'OK';
  @override
  final HttpHeaders headers = _MockHeaders();
  @override
  final int contentLength = -1;
  @override
  final bool persistentConnection = false;
  @override
  final bool isRedirect = false;
  @override
  final List<RedirectInfo> redirects = const [];
  @override
  final List<Cookie> cookies = const [];
  @override
  final HttpConnectionInfo? connectionInfo = null;
  @override
  final X509Certificate? certificate = null;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.fromIterable([_kTransparentPng]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  Future<Socket> detachSocket() =>
      throw UnsupportedError('detachSocket not supported in mock');

  @override
  Future<HttpClientResponse> redirect(
      [String? method, Uri? url, bool? followLoops]) async => this;
}

class _MockHeaders implements HttpHeaders {
  final Map<String, List<String>> _headers = {
    'content-type': ['image/png'],
  };

  @override
  List<String>? operator [](String name) => _headers[name.toLowerCase()];

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers.putIfAbsent(name.toLowerCase(), () => []).add(value.toString());
  }

  @override
  String? value(String name) {
    final vals = _headers[name.toLowerCase()];
    return vals?.isEmpty == true ? null : vals?.first;
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _headers[name.toLowerCase()] = [value.toString()];
  }

  @override
  void remove(String name, Object value) {
    _headers[name.toLowerCase()]?.remove(value.toString());
  }

  @override
  void removeAll(String name) => _headers.remove(name.toLowerCase());

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _headers.forEach(action);
  }

  @override
  void noFolding(String name) {}

  @override
  void clear() => _headers.clear();

  @override
  bool get chunkedTransferEncoding => false;
  @override
  set chunkedTransferEncoding(bool value) {}
  @override
  int get contentLength => -1;
  @override
  set contentLength(int value) {}
  @override
  ContentType? get contentType => ContentType.parse('image/png');
  @override
  set contentType(ContentType? value) {}
  @override
  DateTime? get date => null;
  @override
  set date(DateTime? value) {}
  @override
  DateTime? get expires => null;
  @override
  set expires(DateTime? value) {}
  @override
  String? get host => null;
  @override
  set host(String? value) {}
  @override
  DateTime? get ifModifiedSince => null;
  @override
  set ifModifiedSince(DateTime? value) {}
  @override
  bool get persistentConnection => false;
  @override
  set persistentConnection(bool value) {}
  @override
  int? get port => null;
  @override
  set port(int? value) {}
  @override
  List<String> get transferEncoding => [];
}

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
