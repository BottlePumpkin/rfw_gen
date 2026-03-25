import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rfw/rfw.dart';

/// Device frame presets for the preview panel.
enum DeviceFrame {
  /// iPhone SE / small phone: 375pt wide.
  iphone375('iPhone 375pt', 375),

  /// Android compact: 360pt wide.
  android360('Android 360pt', 360),

  /// No frame constraints — fills available space.
  free('Free', 0);

  const DeviceFrame(this.label, this.width);

  /// Display label for the device frame.
  final String label;

  /// Width constraint in logical pixels. 0 means unconstrained.
  final double width;
}

/// Background style for the preview panel.
enum PreviewBackground {
  /// Pure white background.
  white('White'),

  /// Light gray background (#F5F6F8).
  gray('Gray'),

  /// Checkerboard pattern (transparency indicator).
  checkerboard('Checkerboard');

  const PreviewBackground(this.label);

  /// Display label.
  final String label;
}

/// Tab selection for the bottom panel.
enum BottomPanelTab {
  /// JSON data editor.
  data,

  /// Event log.
  events,
}

/// An RFW event captured from the preview.
class RfwEvent {
  RfwEvent({
    required this.name,
    required this.args,
    required this.timestamp,
  });

  /// Event name (e.g., 'button.tap').
  final String name;

  /// Event arguments.
  final DynamicMap args;

  /// When the event was fired.
  final DateTime timestamp;
}

/// A preset rfwtxt snippet that can be loaded in the editor.
class RfwSnippet {
  const RfwSnippet({
    required this.name,
    required this.rfwtxt,
    required this.widgetName,
    this.data,
  });

  /// Display name for the snippet.
  final String name;

  /// The rfwtxt source code.
  final String rfwtxt;

  /// Default widget name to render.
  final String widgetName;

  /// Optional data to load alongside the snippet.
  final Map<String, Object>? data;
}

/// Manages all state for the RFW Editor.
///
/// Owns the rfwtxt source, selected widget, JSON data, event log,
/// theme preference, panel states, device frame, zoom, and preview
/// background. Each panel uses [ListenableBuilder] to subscribe.
class RfwEditorController extends ChangeNotifier {
  RfwEditorController({
    String? initialRfwtxt,
    Map<String, Object>? initialData,
  })  : _rfwtxt = initialRfwtxt ?? _defaultRfwtxt,
        _jsonData = initialData ?? <String, Object>{},
        _jsonText = initialData != null
            ? const JsonEncoder.withIndent('  ').convert(initialData)
            : '{}';

  static const _defaultRfwtxt = '''import core.widgets;
import material;

widget preview = Center(
  child: Text(text: "Hello, RFW!"),
);''';

  // --- Source code ---

  String _rfwtxt;

  /// Current rfwtxt source code.
  String get rfwtxt => _rfwtxt;

  set rfwtxt(String value) {
    if (_rfwtxt == value) return;
    _rfwtxt = value;
    _parseWidgetNames();
    notifyListeners();
  }

  // --- Widget selection ---

  String _selectedWidget = 'preview';

  /// Currently selected widget name for rendering.
  String get selectedWidget => _selectedWidget;

  set selectedWidget(String value) {
    if (_selectedWidget == value) return;
    _selectedWidget = value;
    notifyListeners();
  }

  List<String> _availableWidgets = const ['preview'];

  /// Widget names parsed from the current rfwtxt.
  List<String> get availableWidgets => _availableWidgets;

  // --- JSON data ---

  Map<String, Object> _jsonData;

  /// Current JSON data for DynamicContent binding.
  Map<String, Object> get jsonData => _jsonData;

  String _jsonText;

  /// Raw JSON text in the data editor.
  String get jsonText => _jsonText;

  String? _jsonError;

  /// JSON parse error, if any.
  String? get jsonError => _jsonError;

  /// Update the JSON data from a raw text string.
  void updateJsonText(String text) {
    _jsonText = text;
    try {
      final decoded = json.decode(text);
      if (decoded is Map<String, Object?>) {
        _jsonData = Map<String, Object>.from(
          decoded.map((k, v) => MapEntry(k, v ?? '')),
        );
        _jsonError = null;
      } else {
        _jsonError = 'Root must be a JSON object';
      }
    } on FormatException catch (e) {
      _jsonError = e.message;
    }
    notifyListeners();
  }

  /// Apply the current JSON text to the data (alias for explicit apply).
  void applyJsonData() {
    updateJsonText(_jsonText);
  }

  // --- Events ---

  final List<RfwEvent> _events = [];

  /// Captured event log.
  List<RfwEvent> get events => List.unmodifiable(_events);

  /// Record a new event from the preview.
  void addEvent(String name, DynamicMap args) {
    _events.insert(
      0,
      RfwEvent(name: name, args: args, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  /// Clear all events.
  void clearEvents() {
    _events.clear();
    notifyListeners();
  }

  // --- Error & last successful render ---

  String? _error;

  /// Current parse error message, if any.
  String? get error => _error;

  int? _errorLine;

  /// Line number of the parse error (1-based), if available.
  int? get errorLine => _errorLine;

  set error(String? value) {
    _error = value;
    if (value == null) _errorLine = null;
    notifyListeners();
  }

  /// Set a parse error with optional offset for line calculation.
  void setParseError(String message, {int? offset}) {
    _error = message;
    if (offset != null) {
      _errorLine = _offsetToLine(offset);
    } else {
      _errorLine = null;
    }
    notifyListeners();
  }

  String? _lastSuccessfulRfwtxt;

  /// The last rfwtxt that rendered without error.
  String? get lastSuccessfulRfwtxt => _lastSuccessfulRfwtxt;

  /// Mark the current rfwtxt as successfully rendered.
  void markRenderSuccess() {
    _lastSuccessfulRfwtxt = _rfwtxt;
    _error = null;
    _errorLine = null;
    notifyListeners();
  }

  // --- Theme ---

  bool _isDarkTheme = true;

  /// Whether the editor uses dark theme. Preview is always light.
  bool get isDarkTheme => _isDarkTheme;

  void toggleTheme() {
    _isDarkTheme = !_isDarkTheme;
    notifyListeners();
  }

  // --- Bottom panel ---

  bool _isBottomPanelExpanded = false;

  /// Whether the bottom panel is expanded.
  bool get isBottomPanelExpanded => _isBottomPanelExpanded;

  set isBottomPanelExpanded(bool value) {
    if (_isBottomPanelExpanded == value) return;
    _isBottomPanelExpanded = value;
    notifyListeners();
  }

  BottomPanelTab _bottomPanelTab = BottomPanelTab.data;

  /// Currently active tab in the bottom panel.
  BottomPanelTab get bottomPanelTab => _bottomPanelTab;

  set bottomPanelTab(BottomPanelTab value) {
    _bottomPanelTab = value;
    notifyListeners();
  }

  /// Toggle the bottom panel, optionally switching to a specific tab.
  void toggleBottomPanel({BottomPanelTab? tab}) {
    if (tab != null && _isBottomPanelExpanded && _bottomPanelTab == tab) {
      // Same tab tapped while open — collapse.
      _isBottomPanelExpanded = false;
    } else {
      if (tab != null) _bottomPanelTab = tab;
      _isBottomPanelExpanded = true;
    }
    notifyListeners();
  }

  // --- Device frame ---

  DeviceFrame _deviceFrame = DeviceFrame.iphone375;

  /// Current device frame preset.
  DeviceFrame get deviceFrame => _deviceFrame;

  set deviceFrame(DeviceFrame value) {
    if (_deviceFrame == value) return;
    _deviceFrame = value;
    notifyListeners();
  }

  // --- Zoom ---

  double _zoom = 1.0;

  /// Preview zoom level (0.5 to 2.0).
  double get zoom => _zoom;

  set zoom(double value) {
    final clamped = value.clamp(0.5, 2.0);
    if (_zoom == clamped) return;
    _zoom = clamped;
    notifyListeners();
  }

  // --- Preview background ---

  PreviewBackground _previewBackground = PreviewBackground.white;

  /// Preview background style.
  PreviewBackground get previewBackground => _previewBackground;

  set previewBackground(PreviewBackground value) {
    if (_previewBackground == value) return;
    _previewBackground = value;
    notifyListeners();
  }

  // --- Snippet loading ---

  /// Load a snippet into the editor.
  void loadSnippet(RfwSnippet snippet) {
    _rfwtxt = snippet.rfwtxt;
    _selectedWidget = snippet.widgetName;
    if (snippet.data != null) {
      _jsonData = Map<String, Object>.from(snippet.data!);
      _jsonText = const JsonEncoder.withIndent('  ').convert(snippet.data);
      _jsonError = null;
    }
    _error = null;
    _errorLine = null;
    _parseWidgetNames();
    notifyListeners();
  }

  // --- Internal helpers ---

  /// Parse widget names from rfwtxt using a simple regex.
  void _parseWidgetNames() {
    final matches = RegExp(r'widget\s+(\w+)').allMatches(_rfwtxt);
    final names = matches.map((m) => m.group(1)!).toList();
    if (names.isNotEmpty) {
      _availableWidgets = names;
      if (!names.contains(_selectedWidget)) {
        _selectedWidget = names.first;
      }
    }
  }

  /// Convert a character offset to a 1-based line number.
  int _offsetToLine(int offset) {
    final clamped = offset.clamp(0, _rfwtxt.length);
    var line = 1;
    for (var i = 0; i < clamped; i++) {
      if (_rfwtxt.codeUnitAt(i) == 0x0A) line++;
    }
    return line;
  }
}
