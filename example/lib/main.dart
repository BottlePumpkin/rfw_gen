import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:rfw/rfw.dart';

import 'data/mock_data.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  }
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
  static const _customLibrary = LibraryName(<String>['customdemo']);

  static const _customWidgetNames = <String>{
    'customTextDemo', 'customBounceTapperDemo', 'nullConditionalDemo',
    'customButtonDemo', 'customBadgeDemo', 'customProgressBarDemo',
    'customColumnDemo', 'skeletonContainerDemo', 'compareWidgetDemo',
    'pvContainerDemo', 'customCardDemo', 'customTileDemo', 'customAppBarDemo',
  };

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
      'textDemo', 'coloredBoxDemo', 'borderDemo',
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
      'progressDemo', 'overflowBarDemo', 'visualDensityDemo',
    ],
    'Other': [
      'animationDefaultsDemo', 'safeAreaDemo', 'argsPatternDemo',
    ],
    'Custom': [
      'customTextDemo', 'customBounceTapperDemo', 'nullConditionalDemo',
      'customButtonDemo', 'customBadgeDemo', 'customProgressBarDemo',
      'customColumnDemo', 'skeletonContainerDemo', 'compareWidgetDemo',
      'pvContainerDemo', 'customCardDemo', 'customTileDemo', 'customAppBarDemo',
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
    _runtime.update(
      const LibraryName(<String>['custom', 'widgets']),
      LocalWidgetLibrary(<String, LocalWidgetBuilder>{
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
              if (dividerColor.alpha > 0) children.add(Divider(color: dividerColor, height: 1));
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
      }),
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
      final customBytes = await rootBundle.load('assets/custom_widgets.rfw');
      _runtime.update(
        _customLibrary,
        decodeLibraryBlob(customBytes.buffer.asUint8List()),
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
              widget: FullyQualifiedWidgetName(
                _customWidgetNames.contains(_selectedWidget!)
                    ? _customLibrary
                    : _catalogLibrary,
                _selectedWidget!,
              ),
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
