import 'package:flutter/material.dart';
import 'package:rfw/rfw.dart';

import 'data_panel.dart';
import 'editor_panel.dart';
import 'editor_theme.dart';
import 'event_panel.dart';
import 'preview_panel.dart';
import 'rfw_editor_controller.dart';
import 'snippet_panel.dart';

/// Standalone RFW Editor app that wraps [MaterialApp] + [RfwEditor].
///
/// Use this with `runApp()` for a dedicated editor application:
/// ```dart
/// void main() {
///   runApp(RfwEditorApp(
///     localWidgetLibraries: {
///       customWidgetsLibraryName: LocalWidgetLibrary(customWidgetBuilders),
///     },
///   ));
/// }
/// ```
class RfwEditorApp extends StatelessWidget {
  const RfwEditorApp({
    super.key,
    this.localWidgetLibraries,
    this.libraryName,
    this.initialRfwtxt,
    this.initialData,
    this.snippets,
    this.onSave,
  });

  /// Custom widget libraries to inject into the preview.
  final Map<LibraryName, LocalWidgetLibrary>? localWidgetLibraries;

  /// Library name for the rfwtxt source. Defaults to `LibraryName(['preview'])`.
  final LibraryName? libraryName;

  /// Initial rfwtxt source code.
  final String? initialRfwtxt;

  /// Initial JSON data for DynamicContent.
  final Map<String, Object>? initialData;

  /// Preset snippets available in the editor.
  final List<RfwSnippet>? snippets;

  /// Called when the user saves (future use in V1b).
  final void Function(String rfwtxt)? onSave;

  @override
  Widget build(BuildContext context) {
    return _EditorThemeWrapper(
      child: RfwEditor(
        localWidgetLibraries: localWidgetLibraries,
        libraryName: libraryName,
        initialRfwtxt: initialRfwtxt,
        initialData: initialData,
        snippets: snippets,
        onSave: onSave,
      ),
    );
  }
}

/// Internal widget that provides the themed MaterialApp wrapper.
/// Listens to the [RfwEditorController] for theme changes.
class _EditorThemeWrapper extends StatefulWidget {
  const _EditorThemeWrapper({required this.child});

  final Widget child;

  @override
  State<_EditorThemeWrapper> createState() => _EditorThemeWrapperState();
}

class _EditorThemeWrapperState extends State<_EditorThemeWrapper> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return _ThemeNotifier(
      isDark: _isDark,
      onThemeChanged: (isDark) => setState(() => _isDark = isDark),
      child: MaterialApp(
        title: 'RFW Editor',
        debugShowCheckedModeBanner: false,
        theme: editorLightTheme(),
        darkTheme: editorDarkTheme(),
        themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
        home: widget.child,
      ),
    );
  }
}

/// InheritedWidget to propagate theme changes from controller to MaterialApp.
class _ThemeNotifier extends InheritedWidget {
  const _ThemeNotifier({
    required this.isDark,
    required this.onThemeChanged,
    required super.child,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  static _ThemeNotifier? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ThemeNotifier>();
  }

  @override
  bool updateShouldNotify(_ThemeNotifier oldWidget) =>
      isDark != oldWidget.isDark;
}

/// Embeddable RFW Editor widget without MaterialApp wrapper.
///
/// Use this to embed the editor inside an existing app:
/// ```dart
/// Scaffold(
///   body: RfwEditor(
///     localWidgetLibraries: { ... },
///   ),
/// )
/// ```
class RfwEditor extends StatefulWidget {
  const RfwEditor({
    super.key,
    this.localWidgetLibraries,
    this.libraryName,
    this.initialRfwtxt,
    this.initialData,
    this.snippets,
    this.onSave,
  });

  /// Custom widget libraries to inject into the preview.
  final Map<LibraryName, LocalWidgetLibrary>? localWidgetLibraries;

  /// Library name for the rfwtxt source. Defaults to `LibraryName(['preview'])`.
  final LibraryName? libraryName;

  /// Initial rfwtxt source code.
  final String? initialRfwtxt;

  /// Initial JSON data for DynamicContent.
  final Map<String, Object>? initialData;

  /// Preset snippets available in the editor.
  final List<RfwSnippet>? snippets;

  /// Called when the user saves.
  final void Function(String rfwtxt)? onSave;

  @override
  State<RfwEditor> createState() => _RfwEditorState();
}

class _RfwEditorState extends State<RfwEditor> {
  late final RfwEditorController _controller;
  late final LibraryName _libraryName;

  @override
  void initState() {
    super.initState();
    _libraryName = widget.libraryName ?? const LibraryName(<String>['preview']);
    _controller = RfwEditorController(
      initialRfwtxt: widget.initialRfwtxt,
      initialData: widget.initialData,
    );
    _controller.addListener(_onControllerChanged);
    _controller.loadSavedSnippets();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // Defer UI updates to avoid setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Propagate theme changes to MaterialApp wrapper if present.
      final notifier = _ThemeNotifier.of(context);
      if (notifier != null && notifier.isDark != _controller.isDarkTheme) {
        notifier.onThemeChanged(_controller.isDarkTheme);
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildTopNav(),
          Expanded(
            child: _buildMainArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNav() {
    final isDark = _controller.isDarkTheme;
    final bgColor = isDark ? EditorColors.darkSurface : EditorColors.cardBg;
    final textColor = isDark ? EditorColors.darkText : EditorColors.szsGray100;

    return Container(
      height: 48,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title
          Text(
            'RFW Editor',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(width: 24),
          // Widget selector dropdown
          if (_controller.availableWidgets.isNotEmpty)
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _controller.availableWidgets
                        .contains(_controller.selectedWidget)
                    ? _controller.selectedWidget
                    : _controller.availableWidgets.first,
                isDense: true,
                style: TextStyle(fontSize: 13, color: textColor),
                dropdownColor:
                    isDark ? EditorColors.darkSurface : EditorColors.cardBg,
                items: _controller.availableWidgets.map((name) {
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (v) {
                  if (v != null) _controller.selectedWidget = v;
                },
              ),
            )
          else
            Text('(no widgets)',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? EditorColors.darkTextDim
                        : EditorColors.szsGray50)),
          const Spacer(),
          // Theme toggle
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              size: 20,
            ),
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            onPressed: _controller.toggleTheme,
          ),
          // Data toggle
          _NavToggleButton(
            label: 'Data',
            isActive: _controller.isBottomPanelExpanded &&
                _controller.bottomPanelTab == BottomPanelTab.data,
            onTap: () =>
                _controller.toggleBottomPanel(tab: BottomPanelTab.data),
          ),
          // Events toggle
          _NavToggleButton(
            label: 'Events',
            isActive: _controller.isBottomPanelExpanded &&
                _controller.bottomPanelTab == BottomPanelTab.events,
            onTap: () =>
                _controller.toggleBottomPanel(tab: BottomPanelTab.events),
          ),
          // Snippet drawer toggle
          _NavToggleButton(
            label: 'Snippets',
            isActive: _controller.isSnippetDrawerOpen,
            onTap: _controller.toggleSnippetDrawer,
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea() {
    final isWide = MediaQuery.of(context).size.width > 800;
    final dividerColor = _controller.isDarkTheme
        ? EditorColors.darkBorder
        : EditorColors.sectionBg;

    Widget editorAndPreview;
    if (isWide) {
      editorAndPreview = Row(
        children: [
          Expanded(child: EditorPanel(controller: _controller)),
          VerticalDivider(width: 1, color: dividerColor),
          Expanded(
            child: PreviewPanel(
              controller: _controller,
              libraryName: _libraryName,
              localWidgetLibraries: widget.localWidgetLibraries,
            ),
          ),
        ],
      );
    } else {
      editorAndPreview = Column(
        children: [
          Expanded(child: EditorPanel(controller: _controller)),
          Divider(height: 1, color: dividerColor),
          Expanded(
            child: PreviewPanel(
              controller: _controller,
              libraryName: _libraryName,
              localWidgetLibraries: widget.localWidgetLibraries,
            ),
          ),
        ],
      );
    }

    // Add bottom panel if expanded.
    Widget mainContent;
    if (!_controller.isBottomPanelExpanded) {
      mainContent = editorAndPreview;
    } else {
      mainContent = Column(
        children: [
          Expanded(flex: 3, child: editorAndPreview),
          Divider(height: 1, color: dividerColor),
          Expanded(
            flex: 1,
            child: _controller.bottomPanelTab == BottomPanelTab.data
                ? DataPanel(controller: _controller)
                : EventPanel(controller: _controller),
          ),
        ],
      );
    }

    // Add snippet drawer if open.
    if (_controller.isSnippetDrawerOpen) {
      return Row(
        children: [
          SizedBox(
            width: 220,
            child: SnippetPanel(controller: _controller),
          ),
          VerticalDivider(width: 1, color: dividerColor),
          Expanded(child: mainContent),
        ],
      );
    }

    return mainContent;
  }
}

/// Small toggle button used in the top nav bar.
class _NavToggleButton extends StatelessWidget {
  const _NavToggleButton({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          backgroundColor:
              isActive ? EditorColors.szsBlue55.withValues(alpha: 0.15) : null,
          foregroundColor: isActive ? EditorColors.szsBlue55 : null,
          minimumSize: const Size(48, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(EditorRadius.input),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
