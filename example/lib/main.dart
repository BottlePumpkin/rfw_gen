import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw/rfw.dart';

import 'data/mock_data.dart';

void main() {
  runApp(const RfwGenExampleApp());
}

class RfwGenExampleApp extends StatelessWidget {
  const RfwGenExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rfw_gen Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;

  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();
  bool _isLoaded = false;
  String? _error;

  // Catalog state
  String _selectedCategory = 'Layout';
  String? _selectedWidget;

  static const _catalogLibrary = LibraryName(<String>['catalog']);
  static const _shopLibrary = LibraryName(<String>['shop']);

  static const Map<String, List<String>> _catalogWidgets = {
    'Layout': [
      'columnDemo', 'rowDemo', 'wrapDemo', 'stackDemo',
      'expandedDemo', 'sizedBoxDemo', 'alignDemo',
      'aspectRatioDemo', 'intrinsicDemo',
    ],
    'Scrolling': [
      'listViewDemo', 'gridViewDemo', 'scrollViewDemo', 'listBodyDemo',
    ],
    'Styling & Visual': [
      'containerDemo', 'paddingOpacityDemo', 'clipRRectDemo',
      'defaultTextStyleDemo', 'directionalityDemo',
      'iconDemo', 'iconThemeDemo', 'imageDemo',
      'textDemo', 'coloredBoxDemo',
    ],
    'Transform': [
      'rotationDemo', 'scaleDemo', 'fittedBoxDemo',
    ],
    'Interaction': [
      'gestureDetectorDemo', 'inkWellDemo',
    ],
    'Material': [
      'scaffoldDemo', 'materialDemo', 'cardDemo', 'buttonDemo',
      'listTileDemo', 'sliderDemo', 'drawerDemo', 'dividerDemo',
      'progressDemo', 'overflowBarDemo',
    ],
    'Other': [
      'animationDefaultsDemo', 'safeAreaDemo', 'argsPatternDemo',
    ],
  };

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
    MockData.setupCatalog(_data);
    MockData.setupShop(_data);
    _loadRfwBinaries();
  }

  Future<void> _loadRfwBinaries() async {
    try {
      final catalogBytes = await rootBundle.load('assets/catalog_widgets.rfw');
      final shopBytes = await rootBundle.load('assets/shop_widgets.rfw');
      _runtime.update(
        _catalogLibrary,
        decodeLibraryBlob(catalogBytes.buffer.asUint8List()),
      );
      _runtime.update(
        _shopLibrary,
        decodeLibraryBlob(shopBytes.buffer.asUint8List()),
      );
      setState(() => _isLoaded = true);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  void _handleCatalogEvent(String name, DynamicMap args) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Event: $name ${args.isNotEmpty ? args : ""}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleShopEvent(String name, DynamicMap args) {
    if (!mounted) return;
    switch (name) {
      case 'navigate':
        final page = args['page'] as String;
        if (page == 'shopHome') {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _ShopPage(
                runtime: _runtime,
                data: _data,
                library: _shopLibrary,
                widgetName: page,
                onEvent: _handleShopEvent,
              ),
            ),
          );
        }
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shop: $name ${args.isNotEmpty ? args : ""}'),
            duration: const Duration(seconds: 1),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    if (!_isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _tabIndex == 0 ? _buildCatalogTab() : _buildShopTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() {
          _tabIndex = i;
          _selectedWidget = null;
        }),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.widgets), label: 'Catalog'),
          NavigationDestination(icon: Icon(Icons.shopping_bag), label: 'Shop'),
        ],
      ),
    );
  }

  Widget _buildCatalogTab() {
    return Column(
      children: [
        AppBar(
          title: Text(_selectedWidget ?? 'Widget Catalog'),
          leading: _selectedWidget != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedWidget = null),
                )
              : null,
        ),
        if (_selectedWidget == null) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: _catalogWidgets.keys.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: _catalogWidgets[_selectedCategory]!.length,
              itemBuilder: (context, i) {
                final name = _catalogWidgets[_selectedCategory]![i];
                return ListTile(
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => setState(() => _selectedWidget = name),
                );
              },
            ),
          ),
        ] else
          Expanded(
            child: RemoteWidget(
              runtime: _runtime,
              data: _data,
              widget: FullyQualifiedWidgetName(_catalogLibrary, _selectedWidget!),
              onEvent: _handleCatalogEvent,
            ),
          ),
      ],
    );
  }

  Widget _buildShopTab() {
    return RemoteWidget(
      runtime: _runtime,
      data: _data,
      widget: FullyQualifiedWidgetName(_shopLibrary, 'shopHome'),
      onEvent: _handleShopEvent,
    );
  }
}

class _ShopPage extends StatelessWidget {
  const _ShopPage({
    required this.runtime,
    required this.data,
    required this.library,
    required this.widgetName,
    required this.onEvent,
  });

  final Runtime runtime;
  final DynamicContent data;
  final LibraryName library;
  final String widgetName;
  final void Function(String name, DynamicMap args) onEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widgetName)),
      body: RemoteWidget(
        runtime: runtime,
        data: data,
        widget: FullyQualifiedWidgetName(library, widgetName),
        onEvent: (name, args) {
          if (name == 'navigate') {
            final page = args['page'] as String;
            if (page == 'shopHome') {
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _ShopPage(
                    runtime: runtime,
                    data: data,
                    library: library,
                    widgetName: page,
                    onEvent: onEvent,
                  ),
                ),
              );
            }
          } else {
            onEvent(name, args);
          }
        },
      ),
    );
  }
}
