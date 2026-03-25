# rfw_gen

[![CI](https://github.com/BottlePumpkin/rfw_gen/actions/workflows/ci.yml/badge.svg)](https://github.com/BottlePumpkin/rfw_gen/actions/workflows/ci.yml)
[![License: BSD-3](https://img.shields.io/badge/license-BSD--3-blue.svg)](LICENSE)

A code generator that converts Flutter Widget code into
[Remote Flutter Widgets (RFW)](https://pub.dev/packages/rfw) format.
Annotate functions with `@RfwWidget`, run `build_runner`, and get `.rfwtxt`
and `.rfw` files ready for server-driven UI.

## Packages

| Package | Description | pub.dev |
|---------|-------------|---------|
| [rfw_gen](packages/rfw_gen/) | Core: annotations, converter engine, widget registry | [![pub](https://img.shields.io/pub/v/rfw_gen.svg)](https://pub.dev/packages/rfw_gen) |
| [rfw_gen_builder](packages/rfw_gen_builder/) | build_runner code generator | [![pub](https://img.shields.io/pub/v/rfw_gen_builder.svg)](https://pub.dev/packages/rfw_gen_builder) |
| [rfw_gen_mcp](packages/rfw_gen_mcp/) | MCP server for widget registry, conversion, and validation | [![pub](https://img.shields.io/pub/v/rfw_gen_mcp.svg)](https://pub.dev/packages/rfw_gen_mcp) |

## Quick Start

1. Add dependencies:

```yaml
dependencies:
  rfw_gen: ^0.4.0

dev_dependencies:
  rfw_gen_builder: ^0.4.0
  build_runner: ^2.4.0
```

2. Annotate a top-level function with `@RfwWidget`:

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

3. Run the code generator:

```bash
dart run build_runner build
```

This produces `greeting.rfwtxt` (human-readable) and `greeting.rfw` (binary).

See [packages/rfw_gen/README.md](packages/rfw_gen/README.md) for the full
feature reference including data binding, state, loops, conditionals, and
event handlers.

## Architecture

```
Flutter Widget Code
        │
        ▼
  @RfwWidget annotation
        │
        ▼
  build_runner (rfw_gen_builder)
        │
        ├──▶ .rfwtxt          (human-readable RFW text)
        ├──▶ .rfw             (binary for production)
        ├──▶ .rfw_library.dart (LocalWidgetBuilder map for custom widgets)
        └──▶ .rfw_meta.json   (widget metadata for MCP/tooling)
```

Core components in `packages/rfw_gen/`:
- **RfwConverter** — traverses the Flutter widget tree and emits rfwtxt
- **WidgetRegistry** — maps Flutter widgets to their RFW equivalents (65 widgets)
- **WidgetResolver** — analyzes custom widget constructors via Dart analyzer
- **Annotations** — `@RfwWidget`, `DataRef`, `StateRef`, `ArgsRef`, `RfwHandler`, etc.

## Development

### Prerequisites

- Flutter SDK (Dart SDK ^3.6.0)
- [Melos](https://melos.invertase.dev/) for monorepo management

### Setup

```bash
melos bootstrap
```

### Commands

```bash
# Run all tests
melos exec -- dart test

# Static analysis
dart analyze

# Golden tests (example app)
cd example && flutter test --tags golden

# Non-golden tests (example app)
cd example && flutter test --exclude-tags golden
```

### Branch Rules

- No direct commits to `main` — always use a feature branch + PR
- Branch naming: `<type>/<description>` (e.g., `feat/data-binding`, `fix/offset-missing`)
- Types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`

## Pre-1.0 Notice

This project is pre-1.0. Minor version bumps may include breaking changes.
Pin to a specific version if stability is critical.

## License

[BSD-3-Clause](LICENSE)
