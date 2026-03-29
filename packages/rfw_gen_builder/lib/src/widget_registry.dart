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

  /// Multiple named child slots (e.g., Scaffold: appBar, body, drawer).
  namedSlots,
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

  /// Handler parameter names (e.g., 'onTap', 'onPressed').
  /// These expect RfwHandler/RfwSetState/RfwEvent expressions.
  final Set<String> handlerParams;

  /// Named child slots for namedSlots widgets.
  /// Key: Flutter param name, Value: true if list slot, false if single.
  final Map<String, bool> namedChildSlots;

  const WidgetMapping({
    required this.rfwName,
    required this.params,
    required this.import,
    this.positionalParam,
    this.childType = ChildType.none,
    this.childParam,
    this.handlerParams = const {},
    this.namedChildSlots = const {},
  });
}

/// Registry that maps Flutter widget names to their [WidgetMapping]s.
///
/// Use [WidgetRegistry.core] to obtain a registry pre-populated with the
/// core widget mappings. Additional mappings can be added at any time with
/// [register].
class WidgetRegistry {
  final Map<String, WidgetMapping> _widgets;

  /// Optional callback invoked when a warning condition is detected
  /// (e.g., overwriting an existing widget mapping).
  void Function(String message)? onWarning;

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
  ///
  /// If a mapping for [name] already exists, [onWarning] is called (if set)
  /// to notify that the existing mapping will be overwritten.
  void register(String name, WidgetMapping mapping) {
    if (_widgets.containsKey(name)) {
      onWarning?.call(
        'Overwriting existing widget mapping for "$name". '
        'This replaces the ${_widgets[name]!.rfwName} mapping.',
      );
    }
    _widgets[name] = mapping;
  }

  /// Returns a registry pre-populated with the core widget mappings.
  factory WidgetRegistry.core() {
    return WidgetRegistry._fromMap({
      ..._textWidgets(),
      ..._layoutWidgets(),
      ..._stylingWidgets(),
      ..._scrollingWidgets(),
      ..._transformWidgets(),
      ..._interactionWidgets(),
      ..._otherWidgets(),
      ..._animatedAliases(),
      ..._materialWidgets(),
    });
  }

  // ---------------------------------------------------------------------------
  // Text widgets
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _textWidgets() => const {
        'Text': WidgetMapping(
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
      };

  // ---------------------------------------------------------------------------
  // Layout widgets
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _layoutWidgets() => const {
        'Column': WidgetMapping(
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
            'textBaseline': ParamMapping('textBaseline', transformer: 'enum'),
            'textDirection': ParamMapping('textDirection', transformer: 'enum'),
          },
        ),
        'Row': WidgetMapping(
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
            'textBaseline': ParamMapping('textBaseline', transformer: 'enum'),
            'textDirection': ParamMapping('textDirection', transformer: 'enum'),
          },
        ),
        'Center': WidgetMapping(
          rfwName: 'core.Center',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'widthFactor': ParamMapping.direct('widthFactor'),
            'heightFactor': ParamMapping.direct('heightFactor'),
          },
        ),
        'Align': WidgetMapping(
          rfwName: 'core.Align',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'widthFactor': ParamMapping.direct('widthFactor'),
            'heightFactor': ParamMapping.direct('heightFactor'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'AspectRatio': WidgetMapping(
          rfwName: 'core.AspectRatio',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'aspectRatio': ParamMapping.direct('aspectRatio'),
          },
        ),
        'Expanded': WidgetMapping(
          rfwName: 'core.Expanded',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'flex': ParamMapping.direct('flex'),
          },
        ),
        'Flexible': WidgetMapping(
          rfwName: 'core.Flexible',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'flex': ParamMapping.direct('flex'),
            'fit': ParamMapping('fit', transformer: 'enum'),
          },
        ),
        'FittedBox': WidgetMapping(
          rfwName: 'core.FittedBox',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'fit': ParamMapping('fit', transformer: 'enum'),
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'FractionallySizedBox': WidgetMapping(
          rfwName: 'core.FractionallySizedBox',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'widthFactor': ParamMapping.direct('widthFactor'),
            'heightFactor': ParamMapping.direct('heightFactor'),
          },
        ),
        'IntrinsicHeight': WidgetMapping(
          rfwName: 'core.IntrinsicHeight',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {},
        ),
        'IntrinsicWidth': WidgetMapping(
          rfwName: 'core.IntrinsicWidth',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
          },
        ),
        'SizedBoxExpand': WidgetMapping(
          rfwName: 'core.SizedBoxExpand',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {},
        ),
        'SizedBoxShrink': WidgetMapping(
          rfwName: 'core.SizedBoxShrink',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {},
        ),
        'Spacer': WidgetMapping(
          rfwName: 'core.Spacer',
          import: 'core.widgets',
          childType: ChildType.none,
          params: {
            'flex': ParamMapping.direct('flex'),
          },
        ),
        'Stack': WidgetMapping(
          rfwName: 'core.Stack',
          import: 'core.widgets',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'textDirection': ParamMapping('textDirection', transformer: 'enum'),
            'fit': ParamMapping('fit', transformer: 'enum'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'Wrap': WidgetMapping(
          rfwName: 'core.Wrap',
          import: 'core.widgets',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'direction': ParamMapping('direction', transformer: 'enum'),
            'alignment': ParamMapping('alignment', transformer: 'enum'),
            'spacing': ParamMapping.direct('spacing'),
            'runAlignment': ParamMapping('runAlignment', transformer: 'enum'),
            'runSpacing': ParamMapping.direct('runSpacing'),
            'crossAxisAlignment':
                ParamMapping('crossAxisAlignment', transformer: 'enum'),
            'textDirection': ParamMapping('textDirection', transformer: 'enum'),
            'verticalDirection':
                ParamMapping('verticalDirection', transformer: 'enum'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
      };

  // ---------------------------------------------------------------------------
  // Styling widgets
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _stylingWidgets() => const {
        'Container': WidgetMapping(
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
            'foregroundDecoration': ParamMapping('foregroundDecoration',
                transformer: 'boxDecoration'),
            'constraints': ParamMapping.direct('constraints'),
            'transform': ParamMapping.direct('transform'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'SizedBox': WidgetMapping(
          rfwName: 'core.SizedBox',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
          },
        ),
        'Padding': WidgetMapping(
          rfwName: 'core.Padding',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'padding': ParamMapping('padding', transformer: 'edgeInsets'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'ClipRRect': WidgetMapping(
          rfwName: 'core.ClipRRect',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'borderRadius':
                ParamMapping('borderRadius', transformer: 'borderRadius'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'ColoredBox': WidgetMapping(
          rfwName: 'core.ColoredBox',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'color': ParamMapping('color', transformer: 'color'),
          },
        ),
        'DefaultTextStyle': WidgetMapping(
          rfwName: 'core.DefaultTextStyle',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'style': ParamMapping('style', transformer: 'textStyle'),
            'textAlign': ParamMapping('textAlign', transformer: 'enum'),
            'softWrap': ParamMapping.direct('softWrap'),
            'overflow': ParamMapping('overflow', transformer: 'enum'),
            'maxLines': ParamMapping.direct('maxLines'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'Directionality': WidgetMapping(
          rfwName: 'core.Directionality',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'textDirection': ParamMapping('textDirection', transformer: 'enum'),
          },
        ),
        'Icon': WidgetMapping(
          rfwName: 'core.Icon',
          import: 'core.widgets',
          childType: ChildType.none,
          positionalParam: 'icon',
          params: {
            'icon': ParamMapping('iconData', transformer: 'iconData'),
            'size': ParamMapping.direct('size'),
            'color': ParamMapping('color', transformer: 'color'),
            'semanticLabel': ParamMapping.direct('semanticLabel'),
          },
        ),
        'IconTheme': WidgetMapping(
          rfwName: 'core.IconTheme',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'iconThemeData': ParamMapping.direct('iconThemeData'),
          },
        ),
        'Image': WidgetMapping(
          rfwName: 'core.Image',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'image':
                ParamMapping('imageProvider', transformer: 'imageProvider'),
            'imageProvider': ParamMapping.direct('imageProvider'),
            'semanticLabel': ParamMapping.direct('semanticLabel'),
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
            'color': ParamMapping('color', transformer: 'color'),
            'fit': ParamMapping('fit', transformer: 'enum'),
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'repeat': ParamMapping('repeat', transformer: 'enum'),
          },
        ),
        'Opacity': WidgetMapping(
          rfwName: 'core.Opacity',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'opacity': ParamMapping.direct('opacity'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'Placeholder': WidgetMapping(
          rfwName: 'core.Placeholder',
          import: 'core.widgets',
          childType: ChildType.none,
          params: {
            'color': ParamMapping('color', transformer: 'color'),
            'strokeWidth': ParamMapping.direct('strokeWidth'),
            'placeholderWidth': ParamMapping.direct('placeholderWidth'),
            'placeholderHeight': ParamMapping.direct('placeholderHeight'),
            // Flutter aliases (Flutter uses fallbackWidth/fallbackHeight)
            'fallbackWidth': ParamMapping.direct('placeholderWidth'),
            'fallbackHeight': ParamMapping.direct('placeholderHeight'),
          },
        ),
      };

  // ---------------------------------------------------------------------------
  // Scrolling widgets (Task 6)
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _scrollingWidgets() => const {
        'ListView': WidgetMapping(
          rfwName: 'core.ListView',
          import: 'core.widgets',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'scrollDirection':
                ParamMapping('scrollDirection', transformer: 'enum'),
            'reverse': ParamMapping.direct('reverse'),
            'primary': ParamMapping.direct('primary'),
            'shrinkWrap': ParamMapping.direct('shrinkWrap'),
            'padding': ParamMapping('padding', transformer: 'edgeInsets'),
            'itemExtent': ParamMapping.direct('itemExtent'),
            'cacheExtent': ParamMapping.direct('cacheExtent'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'GridView': WidgetMapping(
          rfwName: 'core.GridView',
          import: 'core.widgets',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'scrollDirection':
                ParamMapping('scrollDirection', transformer: 'enum'),
            'reverse': ParamMapping.direct('reverse'),
            'primary': ParamMapping.direct('primary'),
            'shrinkWrap': ParamMapping.direct('shrinkWrap'),
            'padding': ParamMapping('padding', transformer: 'edgeInsets'),
            'gridDelegate':
                ParamMapping('gridDelegate', transformer: 'gridDelegate'),
            'cacheExtent': ParamMapping.direct('cacheExtent'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'SingleChildScrollView': WidgetMapping(
          rfwName: 'core.SingleChildScrollView',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'scrollDirection':
                ParamMapping('scrollDirection', transformer: 'enum'),
            'reverse': ParamMapping.direct('reverse'),
            'padding': ParamMapping('padding', transformer: 'edgeInsets'),
            'primary': ParamMapping.direct('primary'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
        ),
        'ListBody': WidgetMapping(
          rfwName: 'core.ListBody',
          import: 'core.widgets',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'mainAxis': ParamMapping('mainAxis', transformer: 'enum'),
            'reverse': ParamMapping.direct('reverse'),
          },
        ),
      };

  // ---------------------------------------------------------------------------
  // Transform widgets (Task 7)
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _transformWidgets() => const {
        'Positioned': WidgetMapping(
          rfwName: 'core.Positioned',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'start': ParamMapping.direct('start'),
            'top': ParamMapping.direct('top'),
            'end': ParamMapping.direct('end'),
            'bottom': ParamMapping.direct('bottom'),
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'Rotation': WidgetMapping(
          rfwName: 'core.Rotation',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'turns': ParamMapping.direct('turns'),
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'Scale': WidgetMapping(
          rfwName: 'core.Scale',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'scale': ParamMapping.direct('scale'),
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
      };

  // ---------------------------------------------------------------------------
  // Interaction widgets
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _interactionWidgets() => const {
        'GestureDetector': WidgetMapping(
          rfwName: 'core.GestureDetector',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'behavior': ParamMapping('behavior', transformer: 'enum'),
          },
          handlerParams: {
            'onTap',
            'onTapDown',
            'onTapUp',
            'onTapCancel',
            'onDoubleTap',
            'onLongPress',
          },
        ),
      };

  // ---------------------------------------------------------------------------
  // Other widgets (Task 7)
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _otherWidgets() => const {
        'AnimationDefaults': WidgetMapping(
          rfwName: 'core.AnimationDefaults',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
        ),
        'SafeArea': WidgetMapping(
          rfwName: 'core.SafeArea',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'left': ParamMapping.direct('left'),
            'top': ParamMapping.direct('top'),
            'right': ParamMapping.direct('right'),
            'bottom': ParamMapping.direct('bottom'),
            'minimum': ParamMapping('minimum', transformer: 'edgeInsets'),
          },
        ),
      };

  // ---------------------------------------------------------------------------
  // Animated widget aliases (map to same RFW widgets as non-animated)
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _animatedAliases() => const {
        'AnimatedAlign': WidgetMapping(
          rfwName: 'core.Align',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'alignment': ParamMapping('alignment', transformer: 'alignment'),
            'widthFactor': ParamMapping.direct('widthFactor'),
            'heightFactor': ParamMapping.direct('heightFactor'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'AnimatedContainer': WidgetMapping(
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
            'foregroundDecoration': ParamMapping('foregroundDecoration',
                transformer: 'boxDecoration'),
            'constraints': ParamMapping.direct('constraints'),
            'transform': ParamMapping.direct('transform'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'AnimatedPadding': WidgetMapping(
          rfwName: 'core.Padding',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'padding': ParamMapping('padding', transformer: 'edgeInsets'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'AnimatedDefaultTextStyle': WidgetMapping(
          rfwName: 'core.DefaultTextStyle',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'style': ParamMapping('style', transformer: 'textStyle'),
            'textAlign': ParamMapping('textAlign', transformer: 'enum'),
            'softWrap': ParamMapping.direct('softWrap'),
            'overflow': ParamMapping('overflow', transformer: 'enum'),
            'maxLines': ParamMapping.direct('maxLines'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'AnimatedOpacity': WidgetMapping(
          rfwName: 'core.Opacity',
          import: 'core.widgets',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'opacity': ParamMapping.direct('opacity'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
        'PositionedDirectional': WidgetMapping(
          rfwName: 'core.Positioned',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'start': ParamMapping.direct('start'),
            'top': ParamMapping.direct('top'),
            'end': ParamMapping.direct('end'),
            'bottom': ParamMapping.direct('bottom'),
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
          },
        ),
        'AnimatedPositionedDirectional': WidgetMapping(
          rfwName: 'core.Positioned',
          import: 'core.widgets',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'start': ParamMapping.direct('start'),
            'top': ParamMapping.direct('top'),
            'end': ParamMapping.direct('end'),
            'bottom': ParamMapping.direct('bottom'),
            'width': ParamMapping.direct('width'),
            'height': ParamMapping.direct('height'),
            'duration': ParamMapping('duration', transformer: 'duration'),
            'curve': ParamMapping('curve', transformer: 'curve'),
          },
          handlerParams: {'onEnd'},
        ),
      };

  // ---------------------------------------------------------------------------
  // Material widgets (Task 8)
  // ---------------------------------------------------------------------------

  static Map<String, WidgetMapping> _materialWidgets() => const {
        'Scaffold': WidgetMapping(
          rfwName: 'material.Scaffold',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'appBar': false,
            'body': false,
            'floatingActionButton': false,
            'drawer': false,
            'bottomNavigationBar': false,
          },
          params: {
            'backgroundColor':
                ParamMapping('backgroundColor', transformer: 'color'),
            'resizeToAvoidBottomInset':
                ParamMapping.direct('resizeToAvoidBottomInset'),
          },
        ),
        'AppBar': WidgetMapping(
          rfwName: 'material.AppBar',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'leading': false,
            'title': false,
            'actions': true,
          },
          params: {
            'backgroundColor':
                ParamMapping('backgroundColor', transformer: 'color'),
            'elevation': ParamMapping.direct('elevation'),
            'centerTitle': ParamMapping.direct('centerTitle'),
            'toolbarHeight': ParamMapping.direct('toolbarHeight'),
          },
        ),
        'ListTile': WidgetMapping(
          rfwName: 'material.ListTile',
          import: 'material',
          childType: ChildType.namedSlots,
          namedChildSlots: {
            'leading': false,
            'title': false,
            'subtitle': false,
            'trailing': false,
          },
          params: {
            'dense': ParamMapping.direct('dense'),
            'enabled': ParamMapping.direct('enabled'),
            'selected': ParamMapping.direct('selected'),
            'contentPadding':
                ParamMapping('contentPadding', transformer: 'edgeInsets'),
            'visualDensity':
                ParamMapping('visualDensity', transformer: 'visualDensity'),
          },
          handlerParams: {'onTap', 'onLongPress'},
        ),
        'ElevatedButton': WidgetMapping(
          rfwName: 'material.ElevatedButton',
          import: 'material',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'autofocus': ParamMapping.direct('autofocus'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
          handlerParams: {'onPressed', 'onLongPress'},
        ),
        'TextButton': WidgetMapping(
          rfwName: 'material.TextButton',
          import: 'material',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'autofocus': ParamMapping.direct('autofocus'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
          handlerParams: {'onPressed', 'onLongPress'},
        ),
        'OutlinedButton': WidgetMapping(
          rfwName: 'material.OutlinedButton',
          import: 'material',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'autofocus': ParamMapping.direct('autofocus'),
            'clipBehavior': ParamMapping('clipBehavior', transformer: 'enum'),
          },
          handlerParams: {'onPressed', 'onLongPress'},
        ),
        'FloatingActionButton': WidgetMapping(
          rfwName: 'material.FloatingActionButton',
          import: 'material',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'tooltip': ParamMapping.direct('tooltip'),
            'backgroundColor':
                ParamMapping('backgroundColor', transformer: 'color'),
            'elevation': ParamMapping.direct('elevation'),
            'mini': ParamMapping.direct('mini'),
          },
          handlerParams: {'onPressed'},
        ),
        'InkWell': WidgetMapping(
          rfwName: 'material.InkWell',
          import: 'material',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'splashColor': ParamMapping('splashColor', transformer: 'color'),
            'highlightColor':
                ParamMapping('highlightColor', transformer: 'color'),
            'borderRadius':
                ParamMapping('borderRadius', transformer: 'borderRadius'),
          },
          handlerParams: {'onTap', 'onDoubleTap', 'onLongPress'},
        ),
        'Card': WidgetMapping(
          rfwName: 'material.Card',
          import: 'material',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'color': ParamMapping('color', transformer: 'color'),
            'elevation': ParamMapping.direct('elevation'),
            'margin': ParamMapping('margin', transformer: 'edgeInsets'),
            'shape': ParamMapping('shape', transformer: 'shapeBorder'),
          },
        ),
        'Material': WidgetMapping(
          rfwName: 'material.Material',
          import: 'material',
          childType: ChildType.child,
          childParam: 'child',
          params: {
            'type': ParamMapping('type', transformer: 'enum'),
            'elevation': ParamMapping.direct('elevation'),
            'color': ParamMapping('color', transformer: 'color'),
            'shadowColor': ParamMapping('shadowColor', transformer: 'color'),
          },
        ),
        'Divider': WidgetMapping(
          rfwName: 'material.Divider',
          import: 'material',
          childType: ChildType.none,
          params: {
            'height': ParamMapping.direct('height'),
            'thickness': ParamMapping.direct('thickness'),
            'indent': ParamMapping.direct('indent'),
            'endIndent': ParamMapping.direct('endIndent'),
            'color': ParamMapping('color', transformer: 'color'),
          },
        ),
        'VerticalDivider': WidgetMapping(
          rfwName: 'material.VerticalDivider',
          import: 'material',
          childType: ChildType.none,
          params: {
            'width': ParamMapping.direct('width'),
            'thickness': ParamMapping.direct('thickness'),
            'indent': ParamMapping.direct('indent'),
            'endIndent': ParamMapping.direct('endIndent'),
            'color': ParamMapping('color', transformer: 'color'),
          },
        ),
        'CircularProgressIndicator': WidgetMapping(
          rfwName: 'material.CircularProgressIndicator',
          import: 'material',
          childType: ChildType.none,
          params: {
            'value': ParamMapping.direct('value'),
            'color': ParamMapping('color', transformer: 'color'),
            'strokeWidth': ParamMapping.direct('strokeWidth'),
          },
        ),
        'LinearProgressIndicator': WidgetMapping(
          rfwName: 'material.LinearProgressIndicator',
          import: 'material',
          childType: ChildType.none,
          params: {
            'value': ParamMapping.direct('value'),
            'color': ParamMapping('color', transformer: 'color'),
            'backgroundColor':
                ParamMapping('backgroundColor', transformer: 'color'),
          },
        ),
        'Drawer': WidgetMapping(
          rfwName: 'material.Drawer',
          import: 'material',
          childType: ChildType.optionalChild,
          childParam: 'child',
          params: {
            'elevation': ParamMapping.direct('elevation'),
          },
        ),
        'OverflowBar': WidgetMapping(
          rfwName: 'material.OverflowBar',
          import: 'material',
          childType: ChildType.childList,
          childParam: 'children',
          params: {
            'spacing': ParamMapping.direct('spacing'),
            'alignment': ParamMapping('alignment', transformer: 'enum'),
            'overflowSpacing': ParamMapping.direct('overflowSpacing'),
          },
        ),
        'Slider': WidgetMapping(
          rfwName: 'material.Slider',
          import: 'material',
          childType: ChildType.none,
          params: {
            'min': ParamMapping.direct('min'),
            'max': ParamMapping.direct('max'),
            'value': ParamMapping.direct('value'),
            'divisions': ParamMapping.direct('divisions'),
            'activeColor': ParamMapping('activeColor', transformer: 'color'),
          },
          handlerParams: {'onChanged', 'onChangeStart', 'onChangeEnd'},
        ),
      };
}
