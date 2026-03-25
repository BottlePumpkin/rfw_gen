# rfw_gen

A code generation package that converts Flutter Widget code into
[Remote Flutter Widgets (RFW)](https://pub.dev/packages/rfw) format.
Annotate top-level functions with `@RfwWidget`, run `build_runner`, and get
`.rfwtxt` and `.rfw` files ready for server-driven UI.

## Installation

Add `rfw_gen` to your dependencies and `rfw_gen_builder` + `build_runner`
to your dev dependencies:

```yaml
dependencies:
  rfw_gen: ^0.4.0

dev_dependencies:
  rfw_gen_builder: ^0.4.0
  build_runner: ^2.4.0
```

## Quick Start

1. Write a widget function and annotate it with `@RfwWidget`:

```dart
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('greeting')
Widget buildGreeting() {
  return Container(
    color: Color(0xFF2196F3),
    child: Text('Hello, RFW!'),
  );
}
```

2. Run the code generator:

```bash
dart run build_runner build
```

3. The generator produces two files:
   - `greeting.rfwtxt` -- human-readable RFW text format
   - `greeting.rfw` -- binary format for production use

## Supported Widgets

65 widgets are supported across two categories.

### Core Widgets (~48)

- **Layout**: Align, AspectRatio, Center, Column, Expanded, Flexible,
  FittedBox, FractionallySizedBox, IntrinsicHeight, IntrinsicWidth, Row,
  SizedBox, SizedBoxExpand, SizedBoxShrink, Spacer, Stack, Wrap
- **Scrolling**: GridView, ListBody, ListView, SingleChildScrollView
- **Styling**: ClipRRect, ColoredBox, Container, DefaultTextStyle,
  Directionality, Icon, IconTheme, Image, Opacity, Padding, Placeholder, Text
- **Transform**: Positioned, Rotation, Scale
- **Interaction**: GestureDetector
- **Other**: AnimationDefaults, SafeArea

### Material Widgets (~17)

AppBar, Card, CircularProgressIndicator, Divider, Drawer, ElevatedButton,
FloatingActionButton, InkWell, LinearProgressIndicator, ListTile, Material,
OutlinedButton, OverflowBar, Scaffold, Slider, TextButton, VerticalDivider

See [`rules/rfw-widgets.md`](https://github.com/byeonghopark-jobis/rfw_gen/blob/main/.claude/rules/rfw-widgets.md)
for the full parameter reference.

## Dynamic Features

### Data Binding

Reference server-supplied data with `DataRef`:

```dart
Text(DataRef('user.name'))
```

Generates: `Text(text: data.user.name)`

### Args

Reference widget constructor arguments with `ArgsRef`:

```dart
Text(ArgsRef('product.id'))
```

Generates: `Text(text: args.product.id)`

### State

Declare local widget state and reference it with `StateRef`:

```dart
@RfwWidget('toggle', state: {'isActive': false})
Widget buildToggle() {
  return Container(
    color: RfwSwitchValue(
      value: StateRef('isActive'),
      cases: {true: Color(0xFF4CAF50), false: Color(0xFFE0E0E0)},
    ),
  );
}
```

### Loops

Iterate over lists with `RfwFor`:

```dart
RfwFor(
  items: DataRef('items'),
  itemName: 'item',
  builder: (item) => ListTile(
    title: Text(item['name']),
  ),
)
```

Generates: `...for item in data.items: ListTile(title: Text(text: item.name))`

### Conditionals

Use `RfwSwitch` for child widgets and `RfwSwitchValue` for values:

```dart
RfwSwitch(
  value: StateRef('status'),
  cases: {
    'loading': CircularProgressIndicator(),
    'done': Text('Complete'),
  },
)
```

### String Concatenation

Combine static text and dynamic references with `RfwConcat`:

```dart
Text(RfwConcat(['Hello, ', DataRef('name'), '!']))
```

Generates: `Text(text: ["Hello, ", data.name, "!"])`

### Event Handlers

Mutate local state:

```dart
GestureDetector(
  onTap: RfwHandler.setState('pressed', true),
)
```

Generates: `onTap: set state.pressed = true`

Dispatch events to the Flutter host:

```dart
GestureDetector(
  onTap: RfwHandler.event('cart.add', {'itemId': 42}),
)
```

Generates: `onTap: event "cart.add" { itemId: 42 }`

## Custom Widgets

Custom widgets are automatically detected and supported. When you use a
non-built-in widget inside an `@RfwWidget` function, the generator:

1. Discovers the custom widget via AST analysis
2. Resolves its constructor using the Dart analyzer (WidgetResolver)
3. Generates a `LocalWidgetBuilder` bridge (`.rfw_library.dart`)
4. Emits widget metadata (`.rfw_meta.json`) for MCP/tooling

```dart
// 1. Define your custom widget
class CustomText extends StatelessWidget {
  const CustomText({super.key, required this.text, this.fontSize = 14.0});
  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontSize: fontSize));
}

// 2. Use it in an @RfwWidget function — no config file needed
@RfwWidget('customDemo')
Widget buildCustomDemo() {
  return CustomText(text: 'Hello', fontSize: 24.0);
}
```

Running `build_runner` generates:
- `custom_demo.rfwtxt` / `.rfw` — RFW output with `CustomText` references
- `.rfw_library.dart` — `Map<String, LocalWidgetBuilder>` that wires
  RFW's `DataSource` to your widget's constructor
- `.rfw_meta.json` — machine-readable parameter/child/handler metadata

No `rfw_gen.yaml` configuration is required (removed in 0.4.0).

## Generated Output

For each `.dart` file containing `@RfwWidget` functions, the generator produces:

| File | Purpose |
|------|---------|
| `.rfwtxt` | Human-readable RFW text format |
| `.rfw` | Binary format for production use |
| `.rfw_library.dart` | `LocalWidgetBuilder` map for custom widgets |
| `.rfw_meta.json` | Widget metadata (params, child type, handlers) |

## Limitations

- `@RfwWidget` must be applied to top-level functions only.
- Only the 65 built-in widgets (core + material) are supported out of the box.
  Other widgets are auto-detected and require their source to be importable.
- `RfwSwitchValue` / `RfwSwitch` **cannot be used in handler positions**
  (e.g., `onTap`, `onPressed`). This is an RFW runtime limitation — handlers
  only support `setState`, `setStateFromArg`, and `event`. To conditionally
  switch behavior, use `RfwSwitch` to swap entire widgets:

  ```dart
  // ❌ This does NOT work:
  onPressed: RfwSwitchValue(value: StateRef('mode'), cases: {
    true: RfwHandler.event('pause', {}),
    false: RfwHandler.event('start', {}),
  })

  // ✅ Use RfwSwitch to swap widgets instead:
  RfwSwitch(
    value: StateRef('mode'),
    cases: {
      true: ElevatedButton(
        onPressed: RfwHandler.event('pause', {}),
        child: Text('Pause'),
      ),
      false: ElevatedButton(
        onPressed: RfwHandler.event('start', {}),
        child: Text('Start'),
      ),
    },
  )
  ```

## Pre-1.0 Note

This package is pre-1.0. Minor version bumps may include breaking changes.
Pin to a specific version if stability is critical for your project.
