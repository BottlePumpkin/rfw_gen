import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rfw/formats.dart';
import 'package:rfw/rfw.dart';

import 'rfw_source.dart';

/// A convenience widget that renders an RFW widget with automatic
/// [Runtime] setup.
///
/// Handles all the boilerplate of creating a [Runtime], registering
/// core and material widget libraries, loading the widget source,
/// and binding data.
///
/// ## Basic usage
///
/// ```dart
/// RfwPreview(
///   source: RfwSource.asset(
///     'assets/custom_widgets.rfw',
///     library: LibraryName(['custom']),
///   ),
///   widget: 'customTextDemo',
/// )
/// ```
///
/// ## With custom widgets and data
///
/// ```dart
/// RfwPreview(
///   source: RfwSource.asset(
///     'assets/custom_widgets.rfw',
///     library: LibraryName(['custom']),
///   ),
///   widget: 'myWidget',
///   localWidgetLibraries: {
///     LibraryName(['custom', 'widgets']): LocalWidgetLibrary({
///       'CustomText': customTextBuilder,
///     }),
///   },
///   data: {'user': {'name': 'John'}},
///   onEvent: (name, args) => debugPrint('Event: $name $args'),
/// )
/// ```
class RfwPreview extends StatefulWidget {
  const RfwPreview({
    super.key,
    required this.source,
    required this.widget,
    this.localWidgetLibraries,
    this.data,
    this.onEvent,
    this.errorBuilder,
    this.loadingBuilder,
  });

  /// The source to load the RFW widget library from.
  final RfwSource source;

  /// The name of the widget to render from the loaded library.
  final String widget;

  /// Custom widget libraries to register with the [Runtime].
  ///
  /// Core and material widget libraries are registered automatically.
  /// Use this to provide custom widget implementations.
  final Map<LibraryName, LocalWidgetLibrary>? localWidgetLibraries;

  /// Data to bind to the widget via [DynamicContent].
  final Map<String, Object>? data;

  /// Called when the RFW widget triggers an event.
  final void Function(String name, DynamicMap args)? onEvent;

  /// Builder for error states.
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  /// Builder shown while loading asset sources.
  final WidgetBuilder? loadingBuilder;

  @override
  State<RfwPreview> createState() => _RfwPreviewState();
}

class _RfwPreviewState extends State<RfwPreview> {
  late final Runtime _runtime;
  late DynamicContent _data;
  Set<String> _dataKeys = <String>{};
  bool _isLoaded = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _runtime = Runtime();
    _data = DynamicContent();
    _registerLibraries();
    _updateData();
    _loadSource();
  }

  @override
  void didUpdateWidget(RfwPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source ||
        oldWidget.widget != widget.widget) {
      _loadSource();
    }
    if (oldWidget.data != widget.data) {
      _updateData();
    }
    if (oldWidget.localWidgetLibraries != widget.localWidgetLibraries) {
      _registerCustomLibraries();
    }
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  void _registerLibraries() {
    _runtime.update(
      const LibraryName(<String>['core', 'widgets']),
      createCoreWidgets(),
    );
    _runtime.update(
      const LibraryName(<String>['material']),
      createMaterialWidgets(),
    );
    _registerCustomLibraries();
  }

  void _registerCustomLibraries() {
    final libraries = widget.localWidgetLibraries;
    if (libraries == null) return;
    for (final entry in libraries.entries) {
      _runtime.update(entry.key, entry.value);
    }
  }

  void _updateData() {
    final data = widget.data;
    final newKeys = data?.keys.toSet() ?? <String>{};
    if (newKeys.length != _dataKeys.length || !newKeys.containsAll(_dataKeys)) {
      // Keys changed — recreate DynamicContent to remove stale entries.
      _data = DynamicContent();
      if (data != null) {
        for (final entry in data.entries) {
          _data.update(entry.key, entry.value);
        }
      }
    } else if (data != null) {
      for (final entry in data.entries) {
        _data.update(entry.key, entry.value);
      }
    }
    _dataKeys = newKeys;
    setState(() {});
  }

  Future<void> _loadSource() async {
    try {
      final source = widget.source;
      switch (source) {
        case RfwAssetSource():
          final bytes = await rootBundle.load(source.path);
          _runtime.update(
            source.library,
            decodeLibraryBlob(bytes.buffer.asUint8List()),
          );
        case RfwTextSource():
          _runtime.update(
            source.library,
            parseLibraryFile(source.rfwtxt),
          );
        case RfwBinarySource():
          _runtime.update(
            source.library,
            decodeLibraryBlob(source.bytes),
          );
        case RfwFileSource():
          _runtime.update(
            source.library,
            parseLibraryFile(source.readAsString()),
          );
      }
      if (mounted) {
        setState(() => _isLoaded = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    }
  }

  void _handleEvent(String name, DynamicMap args) {
    widget.onEvent?.call(name, args);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          Center(child: Text('Error: $_error'));
    }
    if (!_isLoaded) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }
    return RemoteWidget(
      runtime: _runtime,
      widget: FullyQualifiedWidgetName(
        widget.source.library,
        widget.widget,
      ),
      data: _data,
      onEvent: _handleEvent,
    );
  }
}
