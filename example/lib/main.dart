import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rfw_gen Example',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2196F3),
        useMaterial3: true,
      ),
      home: const RfwDemoPage(),
    );
  }
}

class RfwDemoPage extends StatefulWidget {
  const RfwDemoPage({super.key});

  @override
  State<RfwDemoPage> createState() => _RfwDemoPageState();
}

class _RfwDemoPageState extends State<RfwDemoPage> {
  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();
  bool _loaded = false;
  String? _error;

  // 생성된 위젯 목록
  static const _widgets = [
    'greeting',
    'profileCard',
    'statsDashboard',
    'listItem',
    'banner',
    'gridLayout',
    'emptyState',
    'scrollableList',
    'overlayLayout',
    'responsiveWrap',
    'animatedCard',
    'expandedLayout',
    'interactiveButton',
    'toggleCard',
    'scaffoldPage',
    'customWidgetDemo',
    // 동적 기능 예제
    'dynamicGreeting',
    'dynamicList',
    'conditionalStatus',
    'toggleButton',
    'userProfile',
    'productList',
    'notificationList',
    'tabSelector',
    'searchResults',
    'settingsToggle',
    'chatMessages',
    'counter',
  ];

  String _currentWidget = 'greeting';

  @override
  void initState() {
    super.initState();
    _runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['material']),
      createMaterialWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['custom', 'widgets']),
      LocalWidgetLibrary(<String, LocalWidgetBuilder>{
        'CustomText': (BuildContext context, DataSource source) {
          final text = source.v<String>(['text']) ?? '';
          final fontType = source.v<String>(['fontType']) ?? 'body';
          final color = Color(source.v<int>(['color']) ?? 0xFF000000);
          final style = switch (fontType) {
            'heading' => TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            'button' => TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color),
            'caption' => TextStyle(fontSize: 12, color: color),
            _ => TextStyle(fontSize: 14, color: color),
          };
          return Text(text, style: style);
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
          // In a real app, this would check a data binding for null.
          // For demo, always show the child.
          return child ?? nullChild ?? const SizedBox.shrink();
        },
      }),
    );
    // 동적 위젯용 샘플 데이터
    _data.update('user', <String, Object>{
      'name': 'Alice',
      'role': 'Developer',
      'bio': 'Flutter enthusiast building amazing apps.',
    });
    _data.update('items', <Object>[
      <String, Object>{'icon': 'A', 'name': 'Alpha Item', 'description': 'First item in the list'},
      <String, Object>{'icon': 'B', 'name': 'Beta Item', 'description': 'Second item in the list'},
      <String, Object>{'icon': 'C', 'name': 'Gamma Item', 'description': 'Third item in the list'},
    ]);
    _data.update('order', <String, Object>{'status': 'shipped'});
    _data.update('profile', <String, Object>{
      'initials': 'AK',
      'displayName': 'Alice Kim',
      'department': 'Engineering',
      'title': 'Senior Developer',
      'isVerified': true,
      'joinDate': '2024-01-15',
    });
    _data.update('products', <Object>[
      <String, Object>{'id': '1', 'name': 'Widget Pro', 'price': '\$29.99', 'inStock': true},
      <String, Object>{'id': '2', 'name': 'Widget Lite', 'price': '\$9.99', 'inStock': false},
      <String, Object>{'id': '3', 'name': 'Widget Max', 'price': '\$49.99', 'inStock': true},
    ]);
    _data.update('notifications', <Object>[
      <String, Object>{'id': '1', 'sender': 'System', 'message': 'Update available', 'time': '2m ago'},
      <String, Object>{'id': '2', 'sender': 'Bob', 'message': 'PR approved', 'time': '1h ago'},
    ]);
    _data.update('search', <String, Object>{
      'query': 'flutter',
      'hasResults': true,
      'results': <Object>[
        <String, Object>{'title': 'Flutter Widgets', 'snippet': 'Build beautiful native apps...'},
        <String, Object>{'title': 'RFW Guide', 'snippet': 'Remote Flutter Widgets overview...'},
      ],
    });
    _data.update('chat', <String, Object>{
      'messages': <Object>[
        <String, Object>{'isMine': false, 'sender': 'Bob', 'text': 'Hey, how is it going?'},
        <String, Object>{'isMine': true, 'sender': 'Me', 'text': 'Great! Working on RFW.'},
        <String, Object>{'isMine': false, 'sender': 'Bob', 'text': 'Cool, show me a demo!'},
      ],
    });
    _loadWidget();
  }

  Future<void> _loadWidget() async {
    try {
      final ByteData byteData = await rootBundle.load('assets/widgets.rfw');
      final blob = byteData.buffer.asUint8List();

      _runtime.update(
        const LibraryName(<String>['app']),
        decodeLibraryBlob(blob),
      );
      setState(() => _loaded = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('rfw_gen Example'),
      ),
      body: Column(
        children: [
          // 위젯 선택 바
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _widgets.length,
              itemBuilder: (context, index) {
                final name = _widgets[index];
                final isSelected = name == _currentWidget;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(name),
                    onSelected: (_) => setState(() => _currentWidget = name),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          // RFW 위젯 렌더링
          Expanded(
            child: Center(
              child: _error != null
                  ? Text('Error: $_error',
                      style: const TextStyle(color: Colors.red))
                  : !_loaded
                      ? const CircularProgressIndicator()
                      : RemoteWidget(
                          runtime: _runtime,
                          data: _data,
                          widget: FullyQualifiedWidgetName(
                            const LibraryName(<String>['app']),
                            _currentWidget,
                          ),
                          onEvent: (String name, DynamicMap args) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Event: $name $args'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
