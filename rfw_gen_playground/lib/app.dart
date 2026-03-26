import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation/doc_navigator.dart';
import 'remote/remote_loader.dart';
import 'remote/screen_registry.dart';
import 'ui/content_area.dart';
import 'ui/search_bar.dart';
import 'ui/sidebar.dart';
import 'widgets/doc_widget_library.dart';

class DocsApp extends StatelessWidget {
  const DocsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'rfw_gen Docs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF237AF2),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        useMaterial3: true,
      ),
      home: const DocsShell(),
    );
  }
}

class DocsShell extends StatefulWidget {
  const DocsShell({super.key});

  @override
  State<DocsShell> createState() => _DocsShellState();
}

class _DocsShellState extends State<DocsShell> {
  Manifest? _manifest;
  String _selectedPageId = '';
  bool _isLoading = true;
  bool _isLoadingPage = false;
  String? _error;
  FullyQualifiedWidgetName? _widgetName;

  late final Runtime _runtime;
  late final DynamicContent _data;
  late RemoteLoader _loader;
  late final DocNavigator _navigator;

  @override
  void initState() {
    super.initState();
    _runtime = Runtime();
    _runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['material']),
      createMaterialWidgets(),
    );
    _runtime.update(
      docWidgetsLibraryName,
      LocalWidgetLibrary(docWidgetBuilders),
    );
    _data = DynamicContent();
    _loader = RemoteLoader(baseUrl: '');
    _navigator = DocNavigator(onNavigate: _selectPage);
    _loadManifest();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  Future<void> _loadManifest() async {
    try {
      final manifest = await _loader.loadManifest('remote/manifest.json');
      _loader = RemoteLoader(
        baseUrl: manifest.baseUrl.isNotEmpty ? manifest.baseUrl : 'remote',
      );
      setState(() {
        _manifest = manifest;
        _isLoading = false;
      });
      if (manifest.screens.isNotEmpty) {
        _selectPage(manifest.screens.first.id);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectPage(String pageId) {
    setState(() => _selectedPageId = pageId);
    _loadPage(pageId);
  }

  Future<void> _loadPage(String pageId) async {
    final screen = _manifest?.screenById(pageId);
    if (screen == null) return;
    setState(() {
      _isLoadingPage = true;
      _error = null;
    });
    try {
      final library = await _loader.loadScreen(screen.rfwtxtPath);
      _runtime.update(const LibraryName(<String>['screen']), library);
      if (screen.dataPath != null) {
        final dataMap = await _loader.loadData(screen.dataPath!);
        _populateData(dataMap);
      }
      setState(() {
        _widgetName = const FullyQualifiedWidgetName(
          LibraryName(<String>['screen']),
          'root',
        );
        _isLoadingPage = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingPage = false;
      });
    }
  }

  void _populateData(Map<String, Object> json) {
    for (final entry in json.entries) {
      _data.update(entry.key, entry.value);
    }
  }

  void _handleEvent(String name, DynamicMap arguments) {
    _navigator.handleEvent(name, arguments);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return isWide ? _buildWideLayout() : _buildNarrowLayout();
      },
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: Row(
        children: [
          if (_manifest != null)
            Sidebar(
              manifest: _manifest!,
              selectedPageId: _selectedPageId,
              onPageSelected: _selectPage,
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('rfw_gen'),
        actions: [
          if (_manifest != null)
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DocSearchBar(
                  manifest: _manifest!,
                  onPageSelected: _selectPage,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _manifest != null
          ? Drawer(
              child: Sidebar(
                manifest: _manifest!,
                selectedPageId: _selectedPageId,
                onPageSelected: (pageId) {
                  _selectPage(pageId);
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: _buildContent(),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE8EAED)),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (_manifest != null)
            SizedBox(
              width: 280,
              child: DocSearchBar(
                manifest: _manifest!,
                onPageSelected: _selectPage,
              ),
            ),
          const SizedBox(width: 12),
          _ExternalLinkIcon(
            icon: Icons.code,
            tooltip: 'GitHub',
            url: 'https://github.com/BottlePumpkin/rfw_gen',
          ),
          const SizedBox(width: 4),
          _ExternalLinkIcon(
            icon: Icons.open_in_new,
            tooltip: 'pub.dev',
            url: 'https://pub.dev/packages/rfw_gen',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // Kept at instance level for reuse — no state needed
  Widget _buildContent() {
    return ContentArea(
      runtime: _runtime,
      data: _data,
      widgetName: _widgetName,
      isLoading: _isLoadingPage,
      error: _error,
      onEvent: _handleEvent,
      onRetry: _error != null && _selectedPageId.isNotEmpty
          ? () => _loadPage(_selectedPageId)
          : null,
    );
  }
}

class _ExternalLinkIcon extends StatelessWidget {
  const _ExternalLinkIcon({
    required this.icon,
    required this.tooltip,
    required this.url,
  });

  final IconData icon;
  final String tooltip;
  final String url;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20, color: const Color(0xFF788391)),
      tooltip: tooltip,
      onPressed: () => launchUrl(Uri.parse(url)),
      splashRadius: 18,
    );
  }
}
