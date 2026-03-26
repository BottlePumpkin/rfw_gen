import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rfw/rfw.dart';
import 'package:url_launcher/url_launcher.dart';

import 'navigation/doc_navigator.dart';
import 'remote/remote_loader.dart';
import 'remote/screen_registry.dart';
import 'ui/content_area.dart';
import 'ui/search_bar.dart';
import 'ui/sidebar.dart';
import 'widgets/doc_widget_library.dart';

class DocsApp extends StatefulWidget {
  const DocsApp({super.key});

  @override
  State<DocsApp> createState() => _DocsAppState();
}

class _DocsAppState extends State<DocsApp> {
  late final Runtime _runtime;
  late final DynamicContent _data;
  late RemoteLoader _loader;
  Manifest? _manifest;
  bool _isAppLoading = true;

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
        _isAppLoading = false;
      });
    } catch (e) {
      setState(() => _isAppLoading = false);
    }
  }

  late final _router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      if (state.uri.path == '/') return '/home';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return _DocsShell(
            manifest: _manifest,
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/:pageId',
            builder: (context, state) {
              final urlPageId = state.pathParameters['pageId'] ?? 'home';
              final pageId = DocNavigator.pathToPageId(urlPageId);
              return _PageLoader(
                key: ValueKey(pageId),
                pageId: pageId,
                manifest: _manifest,
                loader: _loader,
                runtime: _runtime,
                data: _data,
              );
            },
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'rfw_gen Docs',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF237AF2),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

class _DocsShell extends StatelessWidget {
  const _DocsShell({
    required this.manifest,
    required this.currentPath,
    required this.child,
  });

  final Manifest? manifest;
  final String currentPath;
  final Widget child;

  String get _selectedPageId => DocNavigator.pathToPageId(currentPath);

  void _selectPage(BuildContext context, String pageId) {
    context.go(DocNavigator.pageIdToPath(pageId));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return isWide
            ? _buildWideLayout(context)
            : _buildNarrowLayout(context);
      },
    );
  }

  Widget _buildWideLayout(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (manifest != null)
            Sidebar(
              manifest: manifest!,
              selectedPageId: _selectedPageId,
              onPageSelected: (id) => _selectPage(context, id),
            ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('rfw_gen'),
        actions: [
          if (manifest != null)
            SizedBox(
              width: 200,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: DocSearchBar(
                  manifest: manifest!,
                  onPageSelected: (id) => _selectPage(context, id),
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: manifest != null
          ? Drawer(
              child: Sidebar(
                manifest: manifest!,
                selectedPageId: _selectedPageId,
                onPageSelected: (id) {
                  _selectPage(context, id);
                  Navigator.of(context).pop();
                },
              ),
            )
          : null,
      body: child,
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: Row(
        children: [
          const Spacer(),
          if (manifest != null)
            SizedBox(
              width: 280,
              child: DocSearchBar(
                manifest: manifest!,
                onPageSelected: (id) => _selectPage(context, id),
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
}

class _PageLoader extends StatefulWidget {
  const _PageLoader({
    super.key,
    required this.pageId,
    required this.manifest,
    required this.loader,
    required this.runtime,
    required this.data,
  });

  final String pageId;
  final Manifest? manifest;
  final RemoteLoader loader;
  final Runtime runtime;
  final DynamicContent data;

  @override
  State<_PageLoader> createState() => _PageLoaderState();
}

class _PageLoaderState extends State<_PageLoader> {
  bool _isLoading = true;
  String? _error;
  FullyQualifiedWidgetName? _widgetName;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    final screen = widget.manifest?.screenById(widget.pageId);
    if (screen == null) {
      setState(() {
        _error = 'Page not found: ${widget.pageId}';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final library = await widget.loader.loadScreen(screen.rfwtxtPath);
      widget.runtime.update(const LibraryName(<String>['screen']), library);
      if (screen.dataPath != null) {
        final dataMap = await widget.loader.loadData(screen.dataPath!);
        for (final entry in dataMap.entries) {
          widget.data.update(entry.key, entry.value);
        }
      }
      setState(() {
        _widgetName = const FullyQualifiedWidgetName(
          LibraryName(<String>['screen']),
          'root',
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentArea(
      runtime: widget.runtime,
      data: widget.data,
      widgetName: _widgetName,
      isLoading: _isLoading,
      error: _error,
      onEvent: (name, args) => DocNavigator.handleEvent(context, name, args),
      onRetry: _loadPage,
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
