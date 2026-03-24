/// Marks a top-level function as an RFW widget definition.
///
/// Place on a top-level function that returns a widget tree.
/// The generator converts the function body into rfwtxt format.
///
/// ```dart
/// @RfwWidget('MyCard')
/// Object myCard() => Container(color: 0xFFFFFFFF);
/// ```
class RfwWidget {
  /// The widget name used in the generated rfwtxt `widget` declaration.
  final String name;

  /// Optional initial state map for stateful widgets.
  ///
  /// When provided, generates `widget Name { key: value } = ...` syntax.
  final Map<String, dynamic>? state;

  /// Creates an [RfwWidget] annotation with the given [name] and optional [state].
  const RfwWidget(this.name, {this.state});
}
