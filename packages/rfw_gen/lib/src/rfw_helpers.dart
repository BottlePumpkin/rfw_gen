/// Reference to `data.path` in rfwtxt.
class DataRef {
  final String path;
  const DataRef(this.path);
}

/// Reference to `args.path` in rfwtxt.
class ArgsRef {
  final String path;
  const ArgsRef(this.path);
}

/// Reference to `state.path` in rfwtxt.
class StateRef {
  final String path;
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
  final String name;
  const LoopVar(this.name);
  LoopVar operator [](Object path) => LoopVar('$name.$path');
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
class RfwConcat {
  final List<Object> parts;
  const RfwConcat(this.parts);
}

/// Switch expression for widget positions (children, child).
class RfwSwitch {
  final Object value;
  final Map<Object, Object> cases;
  final Object? defaultCase;

  const RfwSwitch({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}

/// Switch expression for value positions (padding, color, etc.).
class RfwSwitchValue<T> {
  final Object value;
  final Map<Object, T> cases;
  final T? defaultCase;

  const RfwSwitchValue({
    required this.value,
    required this.cases,
    this.defaultCase,
  });
}

/// For loop: `...for itemName in items: builder(itemName)`.
class RfwFor {
  final Object items;
  final String itemName;
  final Object Function(LoopVar) builder;

  const RfwFor({
    required this.items,
    required this.itemName,
    required this.builder,
  });
}
