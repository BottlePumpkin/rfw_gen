/// Intermediate Representation (IR) for widget tree values.
///
/// Sits between AST parsing and rfwtxt string emission.
/// The AST visitor produces [IrWidgetNode] trees; the rfwtxt emitter consumes them.
sealed class IrValue {}

/// A string literal value.
class IrStringValue extends IrValue {
  final String value;
  IrStringValue(this.value);
}

/// A floating-point number value.
class IrNumberValue extends IrValue {
  final double value;
  IrNumberValue(this.value);
}

/// An integer value.
class IrIntValue extends IrValue {
  final int value;
  IrIntValue(this.value);
}

/// A boolean value.
class IrBoolValue extends IrValue {
  final bool value;
  IrBoolValue(this.value);
}

/// An enumeration value represented as its dot-qualified string (e.g. `TextAlign.center`).
class IrEnumValue extends IrValue {
  final String value;
  IrEnumValue(this.value);
}

/// An ordered list of [IrValue] elements.
class IrListValue extends IrValue {
  final List<IrValue> values;
  IrListValue(this.values);
}

/// A string-keyed map of [IrValue] entries.
class IrMapValue extends IrValue {
  final Map<String, IrValue> entries;
  IrMapValue(this.entries);
}

/// A widget node with a [name] and a map of [properties].
///
/// Children are typically stored under a `children` key as an [IrListValue]
/// of nested [IrWidgetNode] instances.
class IrWidgetNode extends IrValue {
  final String name;
  final Map<String, IrValue> properties;
  IrWidgetNode({required this.name, this.properties = const {}});
}

/// `set state.field = value` handler.
class IrSetStateValue extends IrValue {
  final String field;
  final IrValue value;
  IrSetStateValue(this.field, this.value);
}

/// `set state.field = args.argName` handler (callback arg reference).
class IrSetStateFromArgValue extends IrValue {
  final String field;
  final String argName;
  IrSetStateFromArgValue(this.field, [this.argName = 'value']);
}

/// `event "name" { key: value, ... }` handler.
class IrEventValue extends IrValue {
  final String name;
  final Map<String, IrValue> args;
  IrEventValue(this.name, [this.args = const {}]);
}

/// A `data.path` reference to DynamicContent.
class IrDataRef extends IrValue {
  final String path;
  IrDataRef(this.path);
}

/// An `args.path` reference to widget constructor arguments.
class IrArgsRef extends IrValue {
  final String path;
  IrArgsRef(this.path);
}

/// A `state.path` reference to widget-local state.
class IrStateRef extends IrValue {
  final String path;
  IrStateRef(this.path);
}

/// A loop variable reference (no prefix). Used inside `...for` loops.
class IrLoopVarRef extends IrValue {
  final String path;
  IrLoopVarRef(this.path);
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
class IrConcat extends IrValue {
  final List<IrValue> parts;
  IrConcat(this.parts);
}

/// A `...for item in source: body` loop.
class IrForLoop extends IrValue {
  final IrValue items;
  final String itemName;
  final IrWidgetNode body;
  IrForLoop({required this.items, required this.itemName, required this.body});
}

/// A `switch value { case1: result1, default: resultN }` expression.
class IrSwitchExpr extends IrValue {
  final IrValue value;
  final Map<IrValue, IrValue> cases;
  final IrValue? defaultCase;
  IrSwitchExpr({required this.value, required this.cases, this.defaultCase});
}
