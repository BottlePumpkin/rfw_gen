import 'package:collection/collection.dart';

/// Intermediate Representation (IR) for widget tree values.
///
/// Sits between AST parsing and rfwtxt string emission.
/// The AST visitor produces [IrWidgetNode] trees; the rfwtxt emitter consumes them.
sealed class IrValue {}

/// A string literal value.
class IrStringValue extends IrValue {
  final String value;
  IrStringValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrStringValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A floating-point number value.
class IrNumberValue extends IrValue {
  final double value;
  IrNumberValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrNumberValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// An integer value.
class IrIntValue extends IrValue {
  final int value;
  IrIntValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrIntValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A boolean value.
class IrBoolValue extends IrValue {
  final bool value;
  IrBoolValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrBoolValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// An enumeration value represented as its dot-qualified string (e.g. `TextAlign.center`).
class IrEnumValue extends IrValue {
  final String value;
  IrEnumValue(this.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrEnumValue && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

const _listEquality = ListEquality<IrValue>();
const _mapEquality = MapEquality<String, IrValue>();

/// An ordered list of [IrValue] elements.
class IrListValue extends IrValue {
  final List<IrValue> values;
  IrListValue(this.values);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrListValue && _listEquality.equals(values, other.values);

  @override
  int get hashCode => _listEquality.hash(values);
}

/// A string-keyed map of [IrValue] entries.
class IrMapValue extends IrValue {
  final Map<String, IrValue> entries;
  IrMapValue(this.entries);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrMapValue && _mapEquality.equals(entries, other.entries);

  @override
  int get hashCode => _mapEquality.hash(entries);
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrSetStateValue && field == other.field && value == other.value;

  @override
  int get hashCode => Object.hash(field, value);
}

/// `set state.field = args.argName` handler (callback arg reference).
class IrSetStateFromArgValue extends IrValue {
  final String field;
  final String argName;
  IrSetStateFromArgValue(this.field, [this.argName = 'value']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrSetStateFromArgValue &&
          field == other.field &&
          argName == other.argName;

  @override
  int get hashCode => Object.hash(field, argName);
}

/// `event "name" { key: value, ... }` handler.
class IrEventValue extends IrValue {
  final String name;
  final Map<String, IrValue> args;
  IrEventValue(this.name, [this.args = const {}]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrEventValue &&
          name == other.name &&
          _mapEquality.equals(args, other.args);

  @override
  int get hashCode => Object.hash(name, _mapEquality.hash(args));
}

/// A `data.path` reference to DynamicContent.
class IrDataRef extends IrValue {
  final String path;
  IrDataRef(this.path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrDataRef && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// An `args.path` reference to widget constructor arguments.
class IrArgsRef extends IrValue {
  final String path;
  IrArgsRef(this.path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrArgsRef && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// A `state.path` reference to widget-local state.
class IrStateRef extends IrValue {
  final String path;
  IrStateRef(this.path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrStateRef && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// A loop variable reference (no prefix). Used inside `...for` loops.
class IrLoopVarRef extends IrValue {
  final String path;
  IrLoopVarRef(this.path);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IrLoopVarRef && path == other.path;

  @override
  int get hashCode => path.hashCode;
}

/// String concatenation: `["Hello, ", data.name, "!"]`.
class IrConcat extends IrValue {
  final List<IrValue> parts;
  IrConcat(this.parts);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IrConcat && _listEquality.equals(parts, other.parts);

  @override
  int get hashCode => _listEquality.hash(parts);
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
