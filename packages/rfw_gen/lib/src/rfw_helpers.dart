/// Sealed base class for dynamic references in rfwtxt.
///
/// [DataRef], [StateRef], and [ArgsRef] all implement this type,
/// enabling type-safe usage in [RfwSwitch.value] and [RfwSwitchValue.value].
sealed class RfwRef {
  /// Dot-separated path into the referenced data.
  String get path;
}

/// Reference to `data.path` in rfwtxt.
///
/// Use this to bind a widget parameter to dynamic data provided at runtime.
class DataRef implements RfwRef {
  /// Dot-separated path into the data model (e.g. `'user.name'`).
  @override
  final String path;

  /// Creates a data reference to [path].
  const DataRef(this.path);
}

/// Reference to `args.path` in rfwtxt.
///
/// Use this to forward constructor arguments through to the widget tree.
class ArgsRef implements RfwRef {
  /// Dot-separated path into the widget's constructor arguments.
  @override
  final String path;

  /// Creates an args reference to [path].
  const ArgsRef(this.path);
}

/// Reference to `state.path` in rfwtxt.
///
/// Use this to read widget-local state declared via [RfwWidget.state].
class StateRef implements RfwRef {
  /// Dot-separated path into the widget's local state.
  @override
  final String path;

  /// Creates a state reference to [path].
  const StateRef(this.path);
}

/// Loop variable reference for use inside [RfwFor.builder].
///
/// Use `[]` operator to access nested paths:
/// ```dart
/// RfwFor(
///   items: DataRef('items'),
///   itemName: 'item',
///   builder: (item) => item['name'],  // → item.name
/// )
/// ```
class LoopVar {
  /// The dot-separated variable path (e.g. `'item'` or `'item.name'`).
  final String name;

  /// Creates a loop variable with the given [name].
  const LoopVar(this.name);

  /// Accesses a nested property, returning a new [LoopVar] with the extended path.
  LoopVar operator [](Object path) => LoopVar('$name.$path');
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
///
/// Each element in [parts] can be a literal string or a reference (e.g. [DataRef]).
class RfwConcat {
  /// The ordered list of string literals and references to concatenate.
  final List<Object> parts;

  /// Creates a concatenation from the given [parts].
  const RfwConcat(this.parts);
}

/// Switch expression for widget positions (children, child).
///
/// Use when the widget itself varies based on a condition.
class RfwSwitch {
  /// The expression to switch on (must be a [DataRef] or [StateRef]).
  final RfwRef value;

  /// Map of case values to widget results.
  final Map<Object, Object> cases;

  /// Fallback widget when no case matches.
  final Object? defaultCase;

  /// Creates a switch expression over [value] with the given [cases].
  const RfwSwitch({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}

/// Switch expression for value positions (padding, color, etc.).
///
/// Use when a scalar parameter varies based on a condition.
class RfwSwitchValue<T> {
  /// The expression to switch on (must be a [DataRef] or [StateRef]).
  final RfwRef value;

  /// Map of case values to typed results.
  final Map<Object, T> cases;

  /// Fallback value when no case matches.
  final T? defaultCase;

  /// Creates a switch expression over [value] with the given [cases].
  const RfwSwitchValue({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}

/// For loop: `...for itemName in items: builder(itemName)`.
///
/// Generates a list spread in rfwtxt that iterates over [items].
class RfwFor {
  /// The collection to iterate (must be a [DataRef]).
  final DataRef items;

  /// The loop variable name used in the generated rfwtxt.
  final String itemName;

  /// Builder that receives a [LoopVar] and returns the widget for each item.
  final Object Function(LoopVar) builder;

  /// Creates a for-loop spread over [items].
  const RfwFor({
    required this.items,
    required this.itemName,
    required this.builder,
  });
}
