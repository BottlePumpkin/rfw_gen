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
