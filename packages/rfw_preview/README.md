# rfw_preview

A dev preview widget for [rfw_gen](https://pub.dev/packages/rfw_gen). Renders
generated rfwtxt with automatic [Runtime](https://pub.dev/packages/rfw) setup
and custom widget support.

## Features

- **RfwPreview** — drop-in widget that renders rfwtxt from strings, files, or assets
- **RfwEditorApp** — standalone editor with live preview, snippet storage, and device frames
- **RfwEditor** — embeddable editor widget for integration into existing apps
- **RfwEditorController** — state management for editor instances

## Installation

```yaml
dev_dependencies:
  rfw_preview: ^0.4.0
```

## Quick Start

### RfwPreview Widget

```dart
import 'package:rfw_preview/rfw_preview.dart';

RfwPreview(
  source: RfwSource.text('''
    import core.widgets;
    widget root = Center(child: Text(text: "Hello, RFW!"));
  '''),
)
```

Load from a generated `.rfwtxt` file:

```dart
RfwPreview(
  source: RfwSource.file('path/to/widget.rfwtxt'),
  data: {'user': {'name': 'Alice'}},
  localWidgetBuilders: myCustomBuilders,
)
```

### RfwEditorApp

Launch a full-screen editor with live preview:

```dart
RfwEditorApp(
  localWidgetBuilders: myCustomBuilders,
)
```

### RfwEditor (Embeddable)

```dart
final controller = RfwEditorController();

RfwEditor(
  controller: controller,
  localWidgetBuilders: myCustomBuilders,
)
```

## Related Packages

- [rfw_gen](https://pub.dev/packages/rfw_gen) — Annotations and runtime helpers
- [rfw_gen_builder](https://pub.dev/packages/rfw_gen_builder) — build_runner code generator
- [rfw_gen_mcp](https://pub.dev/packages/rfw_gen_mcp) — MCP server for AI agents
- [rfw](https://pub.dev/packages/rfw) — Remote Flutter Widgets
