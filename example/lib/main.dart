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
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
