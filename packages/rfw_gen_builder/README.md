# rfw_gen_builder

build_runner code generator for [rfw_gen](https://pub.dev/packages/rfw_gen). Converts `@RfwWidget`-annotated Flutter functions to RFW (Remote Flutter Widgets) format.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  rfw_gen: ^0.4.0

dev_dependencies:
  rfw_gen_builder: ^0.4.0
  build_runner: ^2.4.0
```

## Usage

1. Annotate your widget functions with `@RfwWidget`:

```dart
import 'package:rfw_gen/rfw_gen.dart';

@RfwWidget('myWidget')
Widget buildMyWidget() {
  return Text('Hello');
}
```

2. Run the generator:

```bash
dart run build_runner build
```

This generates:
- `.rfwtxt` — human-readable RFW text
- `.rfw` — binary format for production
- `.rfw_library.dart` — `LocalWidgetBuilder` map for custom widgets
- `.rfw_meta.json` — widget metadata for MCP/tooling

## Documentation

See [rfw_gen](https://pub.dev/packages/rfw_gen) for full documentation, supported widgets, and dynamic features.
