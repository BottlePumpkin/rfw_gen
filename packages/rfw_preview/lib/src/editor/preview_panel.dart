import 'package:flutter/material.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import '../rfw_preview_widget.dart';
import '../rfw_source.dart';
import 'editor_theme.dart';
import 'rfw_editor_controller.dart';

/// Live preview panel that renders the current rfwtxt.
///
/// Uses [RfwPreview] from the same package. Supports device frame
/// constraints, zoom, background toggle, and keeps the last
/// successful render visible on error.
class PreviewPanel extends StatefulWidget {
  const PreviewPanel({
    super.key,
    required this.controller,
    required this.libraryName,
    this.localWidgetLibraries,
  });

  /// The editor controller.
  final RfwEditorController controller;

  /// Library name used for the rfwtxt source.
  final LibraryName libraryName;

  /// Custom widget libraries passed through to [RfwPreview].
  final Map<LibraryName, LocalWidgetLibrary>? localWidgetLibraries;

  @override
  State<PreviewPanel> createState() => _PreviewPanelState();
}

class _PreviewPanelState extends State<PreviewPanel> {
  int _renderKey = 0;
  String? _lastRenderedRfwtxt;
  String? _lastRenderedWidget;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _scheduleRender();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  String? _prevRfwtxt;
  String? _prevWidget;
  Map<String, Object>? _prevData;

  void _onControllerChanged() {
    final ctrl = widget.controller;
    if (ctrl.rfwtxt != _prevRfwtxt ||
        ctrl.selectedWidget != _prevWidget ||
        ctrl.jsonData != _prevData) {
      _prevRfwtxt = ctrl.rfwtxt;
      _prevWidget = ctrl.selectedWidget;
      _prevData = ctrl.jsonData;
      _scheduleRender();
    }
    if (mounted) setState(() {});
  }

  void _scheduleRender() {
    // Validate rfwtxt before rendering.
    try {
      parseLibraryFile(widget.controller.rfwtxt);
      widget.controller.markRenderSuccess();
      _lastRenderedRfwtxt = widget.controller.rfwtxt;
      _lastRenderedWidget = widget.controller.selectedWidget;
      _renderKey++;
    } on FormatException catch (e) {
      widget.controller.setParseError(e.message, offset: e.offset);
    } catch (e) {
      widget.controller.error = e.toString();
    }
    if (mounted) setState(() {});
  }

  void _onRefresh() {
    _scheduleRender();
  }

  void _onEvent(String name, DynamicMap args) {
    widget.controller.addEvent(name, args);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isDark = ctrl.isDarkTheme;

    return Container(
      color: isDark ? EditorColors.darkBg : EditorColors.cardBg,
      child: Column(
        children: [
          // Preview toolbar
          _buildToolbar(ctrl, isDark),
          // Preview area
          Expanded(child: _buildPreviewArea(ctrl)),
          // Preview status bar
          _buildStatusBar(ctrl, isDark),
        ],
      ),
    );
  }

  Widget _buildToolbar(RfwEditorController ctrl, bool isDark) {
    final bgColor = isDark ? EditorColors.darkSurface : EditorColors.sectionBg;
    final textColor = isDark ? EditorColors.darkText : EditorColors.szsGray70;

    return Container(
      height: 36,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          // Device frame selector
          DropdownButtonHideUnderline(
            child: DropdownButton<DeviceFrame>(
              value: ctrl.deviceFrame,
              isDense: true,
              style: TextStyle(fontSize: 12, color: textColor),
              dropdownColor:
                  isDark ? EditorColors.darkSurface : EditorColors.cardBg,
              items: DeviceFrame.values.map((frame) {
                return DropdownMenuItem(
                  value: frame,
                  child: Text(frame.label),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) ctrl.deviceFrame = v;
              },
            ),
          ),
          const SizedBox(width: 8),
          // Background toggle
          _BackgroundToggle(controller: ctrl, isDark: isDark),
          const Spacer(),
          // Zoom slider
          Icon(Icons.zoom_out, size: 16, color: textColor),
          SizedBox(
            width: 100,
            child: Slider(
              value: ctrl.zoom,
              min: 0.5,
              max: 2.0,
              divisions: 6,
              onChanged: (v) => ctrl.zoom = v,
            ),
          ),
          Text(
            '${(ctrl.zoom * 100).round()}%',
            style: TextStyle(fontSize: 12, color: textColor),
          ),
          const SizedBox(width: 4),
          Icon(Icons.zoom_in, size: 16, color: textColor),
          const SizedBox(width: 8),
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Refresh',
            onPressed: _onRefresh,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewArea(RfwEditorController ctrl) {
    final rfwtxt =
        ctrl.error != null ? ctrl.lastSuccessfulRfwtxt : _lastRenderedRfwtxt;
    final widgetName = ctrl.error != null
        ? (_lastRenderedWidget ?? ctrl.selectedWidget)
        : ctrl.selectedWidget;

    if (rfwtxt == null || rfwtxt.isEmpty) {
      return const Center(
        child: Text(
          'Enter rfwtxt to see preview',
          style: TextStyle(color: EditorColors.szsGray50),
        ),
      );
    }

    Widget preview = RfwPreview(
      key: ValueKey(_renderKey),
      source: RfwSource.text(rfwtxt, library: widget.libraryName),
      widget: widgetName,
      localWidgetLibraries: widget.localWidgetLibraries,
      data: ctrl.jsonData.isNotEmpty ? ctrl.jsonData : null,
      onEvent: _onEvent,
      errorBuilder: (_, error) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'Render Error:\n\n$error',
            style: const TextStyle(
              color: EditorColors.szsRed50,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        );
      },
    );

    // Apply device frame constraint
    if (ctrl.deviceFrame != DeviceFrame.free) {
      preview = Center(
        child: SizedBox(
          width: ctrl.deviceFrame.width,
          child: preview,
        ),
      );
    }

    // Apply zoom
    if (ctrl.zoom != 1.0) {
      preview = Transform.scale(
        scale: ctrl.zoom,
        alignment: Alignment.topCenter,
        child: preview,
      );
    }

    // Wrap in background
    return _PreviewBackground(
      background: ctrl.previewBackground,
      child: preview,
    );
  }

  Widget _buildStatusBar(RfwEditorController ctrl, bool isDark) {
    final bgColor = isDark ? EditorColors.darkSurface : EditorColors.sectionBg;
    final textColor = isDark ? EditorColors.szsGray50 : EditorColors.szsGray70;

    return Container(
      height: 24,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            '${ctrl.deviceFrame.label} / ${(ctrl.zoom * 100).round()}%',
            style: TextStyle(fontSize: 11, color: textColor),
          ),
          const Spacer(),
          if (ctrl.error != null)
            Text(
              'Showing last successful render',
              style: TextStyle(
                fontSize: 11,
                color: Colors.orange.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

/// Toggle button for preview background.
class _BackgroundToggle extends StatelessWidget {
  const _BackgroundToggle({required this.controller, required this.isDark});

  final RfwEditorController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PreviewBackground>(
      tooltip: 'Background',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.format_color_fill,
              size: 16,
              color: isDark ? EditorColors.darkText : EditorColors.szsGray70),
          const SizedBox(width: 4),
          Text(
            controller.previewBackground.label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? EditorColors.darkText : EditorColors.szsGray70,
            ),
          ),
        ],
      ),
      onSelected: (v) => controller.previewBackground = v,
      itemBuilder: (_) => PreviewBackground.values.map((bg) {
        return PopupMenuItem(value: bg, child: Text(bg.label));
      }).toList(),
    );
  }
}

/// Renders the background for the preview area.
class _PreviewBackground extends StatelessWidget {
  const _PreviewBackground({
    required this.background,
    required this.child,
  });

  final PreviewBackground background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (background) {
      case PreviewBackground.white:
        return ColoredBox(color: Colors.white, child: child);
      case PreviewBackground.gray:
        return ColoredBox(color: EditorColors.sectionBg, child: child);
      case PreviewBackground.checkerboard:
        return Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _CheckerPainter())),
            child,
          ],
        );
    }
  }
}

class _CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cellSize = 10.0;
    final light = Paint()..color = const Color(0xFFFFFFFF);
    final dark = Paint()..color = const Color(0xFFE8E8E8);

    for (var y = 0.0; y < size.height; y += cellSize) {
      for (var x = 0.0; x < size.width; x += cellSize) {
        final isEven = ((x ~/ cellSize) + (y ~/ cellSize)) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, cellSize, cellSize),
          isEven ? light : dark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
