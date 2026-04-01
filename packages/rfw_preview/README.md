# rfw_preview

A dev preview widget for [rfw_gen](https://pub.dev/packages/rfw_gen). Renders
generated rfwtxt with automatic [Runtime](https://pub.dev/packages/rfw) setup
and custom widget support.

## Features

- **RfwPreview** — drop-in widget that renders rfwtxt from strings, binary assets, or raw bytes
- **RfwEditorApp** — standalone editor with live preview, snippet storage, and device frames
- **RfwEditor** — embeddable editor widget for integration into existing apps
- **RfwEditorController** — state management for editor instances

## Installation

```yaml
dev_dependencies:
  rfw_preview: ^0.5.2
```

## Quick Start

### RfwPreview Widget

```dart
import 'package:rfw_preview/rfw_preview.dart';

RfwPreview(
  source: RfwSource.text(
    '''
    import core.widgets;
    widget root = Center(child: Text(text: "Hello, RFW!"));
    ''',
    library: LibraryName(['main']),
  ),
  widget: 'root',
)
```

Load from a `.rfw` binary asset:

```dart
RfwPreview(
  source: RfwSource.asset(
    'assets/greeting.rfw',
    library: LibraryName(['main']),
  ),
  widget: 'greeting',
  data: {'user': {'name': 'Alice'}},
  localWidgetLibraries: myCustomWidgetLibraries,
)
```

### RfwEditorApp

Launch a full-screen editor with live preview:

```dart
RfwEditorApp(
  localWidgetLibraries: myCustomWidgetLibraries,
)
```

### RfwEditor (Embeddable)

```dart
RfwEditor(
  localWidgetLibraries: myCustomWidgetLibraries,
)
```

## Related Packages

- [rfw_gen](https://pub.dev/packages/rfw_gen) — Annotations and runtime helpers
- [rfw_gen_builder](https://pub.dev/packages/rfw_gen_builder) — build_runner code generator
- [rfw_gen_mcp](https://pub.dev/packages/rfw_gen_mcp) — MCP server for AI agents
- [rfw](https://pub.dev/packages/rfw) — Remote Flutter Widgets
