/// Describes how a widget's child relationship is represented.
enum ChildType {
  /// The widget takes no children.
  none,

  /// The widget takes a single required child.
  child,

  /// The widget takes a single optional child.
  optionalChild,

  /// The widget takes a list of children.
  childList,
}

/// Describes how a single Flutter parameter maps to an rfwtxt parameter.
class ParamMapping {
  /// The name of the parameter in the rfwtxt output.
  final String rfwName;

  /// An optional transformer key that describes how to convert the value
  /// (e.g. `'textStyle'`, `'enum'`, `'color'`, `'edgeInsets'`).
  /// `null` means the value is passed through directly.
  final String? transformer;

  const ParamMapping(this.rfwName, {this.transformer});

  /// Creates a direct pass-through mapping where [rfwName] equals the
  /// Flutter parameter name and no transformation is applied.
  const ParamMapping.direct(String name)
      : rfwName = name,
        transformer = null;
}

/// Describes how a Flutter widget maps to its rfwtxt equivalent.
class WidgetMapping {
  /// The fully-qualified rfwtxt widget name (e.g. `'core.widgets:Text'`).
  /// When import is `'core.widgets'` this typically mirrors the Flutter name.
  final String rfwName;

  /// Parameter mappings keyed by the Flutter parameter name.
  final Map<String, ParamMapping> params;

  /// When set, this Flutter parameter is rendered as the rfwtxt positional
  /// argument rather than as a named property (e.g. `'text'` for [Text]).
  final String? positionalParam;

  /// Describes the child relationship this widget uses.
  final ChildType childType;

  /// The Flutter parameter name that holds the child/children
  /// (e.g. `'child'` or `'children'`). Only meaningful when
  /// [childType] is not [ChildType.none].
  final String? childParam;

  /// The rfwtxt import library that declares this widget
  /// (default: `'core.widgets'`).
  final String import;

  const WidgetMapping({
    required this.rfwName,
    required this.params,
    required this.import,
    this.positionalParam,
    this.childType = ChildType.none,
    this.childParam,
  });
}

/// Registry that maps Flutter widget names to their [WidgetMapping]s.
///
/// Use [WidgetRegistry.core] to obtain a registry pre-populated with the
/// five built-in widget mappings (Text, Column, Row, Container, SizedBox).
/// Additional mappings can be added at any time with [register].
class WidgetRegistry {
  final Map<String, WidgetMapping> _widgets;

  /// Creates an empty registry.
  WidgetRegistry() : _widgets = {};

  /// Internal constructor used by the factory.
  WidgetRegistry._fromMap(Map<String, WidgetMapping> widgets)
      : _widgets = Map<String, WidgetMapping>.of(widgets);

  /// Returns an unmodifiable view of all registered widget mappings.
  Map<String, WidgetMapping> get supportedWidgets =>
      Map<String, WidgetMapping>.unmodifiable(_widgets);

  /// Returns `true` if [widgetName] has a registered mapping.
  bool isSupported(String widgetName) => _widgets.containsKey(widgetName);

  /// Registers or replaces the [WidgetMapping] for [name].
  void register(String name, WidgetMapping mapping) {
    _widgets[name] = mapping;
  }

  /// Returns a registry pre-populated with the five core widget mappings.
  factory WidgetRegistry.core() {
    return WidgetRegistry._fromMap({
      'Text': const WidgetMapping(
        rfwName: 'core.Text',
        import: 'core.widgets',
        positionalParam: 'text',
        childType: ChildType.none,
        params: {
          'style': ParamMapping('style', transformer: 'textStyle'),
          'textAlign': ParamMapping('textAlign', transformer: 'enum'),
          'maxLines': ParamMapping.direct('maxLines'),
          'overflow': ParamMapping('overflow', transformer: 'enum'),
          'softWrap': ParamMapping.direct('softWrap'),
        },
      ),
      'Column': const WidgetMapping(
        rfwName: 'core.Column',
        import: 'core.widgets',
        childType: ChildType.childList,
        childParam: 'children',
        params: {
          'mainAxisAlignment':
              ParamMapping('mainAxisAlignment', transformer: 'enum'),
          'mainAxisSize': ParamMapping('mainAxisSize', transformer: 'enum'),
          'crossAxisAlignment':
              ParamMapping('crossAxisAlignment', transformer: 'enum'),
          'verticalDirection':
              ParamMapping('verticalDirection', transformer: 'enum'),
        },
      ),
      'Row': const WidgetMapping(
        rfwName: 'core.Row',
        import: 'core.widgets',
        childType: ChildType.childList,
        childParam: 'children',
        params: {
          'mainAxisAlignment':
              ParamMapping('mainAxisAlignment', transformer: 'enum'),
          'mainAxisSize': ParamMapping('mainAxisSize', transformer: 'enum'),
          'crossAxisAlignment':
              ParamMapping('crossAxisAlignment', transformer: 'enum'),
          'verticalDirection':
              ParamMapping('verticalDirection', transformer: 'enum'),
        },
      ),
      'Container': const WidgetMapping(
        rfwName: 'core.Container',
        import: 'core.widgets',
        childType: ChildType.optionalChild,
        childParam: 'child',
        params: {
          'color': ParamMapping('color', transformer: 'color'),
          'padding': ParamMapping('padding', transformer: 'edgeInsets'),
          'margin': ParamMapping('margin', transformer: 'edgeInsets'),
          'width': ParamMapping.direct('width'),
          'height': ParamMapping.direct('height'),
          'alignment': ParamMapping('alignment', transformer: 'alignment'),
          'decoration':
              ParamMapping('decoration', transformer: 'boxDecoration'),
        },
      ),
      'SizedBox': const WidgetMapping(
        rfwName: 'core.SizedBox',
        import: 'core.widgets',
        childType: ChildType.optionalChild,
        childParam: 'child',
        params: {
          'width': ParamMapping.direct('width'),
          'height': ParamMapping.direct('height'),
        },
      ),
      'Center': const WidgetMapping(
        rfwName: 'core.Center',
        import: 'core.widgets',
        childType: ChildType.optionalChild,
        childParam: 'child',
        params: {
          'widthFactor': ParamMapping.direct('widthFactor'),
          'heightFactor': ParamMapping.direct('heightFactor'),
        },
      ),
    });
  }
}
