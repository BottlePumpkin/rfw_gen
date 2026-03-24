/// RFW event handler helpers for use in @RfwWidget functions.
///
/// RFW supports two handler patterns:
/// 1. `set state.field = value` -- widget-local state mutation
/// 2. `event "name" { ... }` -- event dispatch to Flutter host
///
/// Usage:
/// ```dart
/// GestureDetector(
///   onTap: RfwHandler.setState('pressed', true),
///   onLongPress: RfwHandler.event('cart.add', {'itemId': 42}),
/// )
/// ```
class RfwHandler {
  RfwHandler._();

  /// State mutation with static value: `set state.field = value`
  static RfwSetState setState(String field, dynamic value) =>
      RfwSetState(field, value);

  /// State mutation from callback arg: `set state.field = args.argName`
  ///
  /// Used for widgets that pass values to callbacks (e.g., Slider.onChanged).
  static RfwSetStateFromArg setStateFromArg(String field,
          [String argName = 'value']) =>
      RfwSetStateFromArg(field, argName);

  /// Event dispatch: `event "name" { key: value, ... }`
  static RfwEvent event(String name,
          [Map<String, dynamic> args = const {}]) =>
      RfwEvent(name, args);
}

/// Represents `set state.field = value`.
class RfwSetState {
  /// The state field name to mutate.
  final String field;

  /// The static value to assign.
  final dynamic value;

  /// Creates a state mutation that sets [field] to [value].
  const RfwSetState(this.field, this.value);
}

/// Represents `set state.field = args.argName`.
///
/// Used for callbacks that receive a value (e.g. `Slider.onChanged`).
class RfwSetStateFromArg {
  /// The state field name to mutate.
  final String field;

  /// The callback argument name to read from (defaults to `'value'`).
  final String argName;

  /// Creates a state mutation that sets [field] from callback arg [argName].
  const RfwSetStateFromArg(this.field, [this.argName = 'value']);
}

/// Represents `event "name" { key: value, ... }`.
///
/// Dispatches a named event to the Flutter host for handling.
class RfwEvent {
  /// The event name (e.g. `'cart.add'`).
  final String name;

  /// Optional key-value arguments sent with the event.
  final Map<String, dynamic> args;

  /// Creates an event dispatch with the given [name] and optional [args].
  const RfwEvent(this.name, [this.args = const {}]);
}
