# rfw_gen_mcp

An [MCP (Model Context Protocol)](https://modelcontextprotocol.io/) server that
exposes [rfw_gen](https://pub.dev/packages/rfw_gen)'s widget registry, code
conversion, and rfwtxt validation as tools for AI agents and IDE integrations.

## Tools

| Tool | Description |
|------|-------------|
| `list_widgets` | List supported RFW widgets with optional category filter |
| `get_widget_info` | Get detailed widget info (params, children, handlers) |
| `convert_to_rfwtxt` | Convert Dart source with `@RfwWidget` to rfwtxt |
| `validate_rfwtxt` | Validate rfwtxt syntax |

## Usage

### Claude Code

Add to your `settings.json`:

```json
{
  "mcpServers": {
    "rfw_gen": {
      "command": "dart",
      "args": ["run", "rfw_gen_mcp"]
    }
  }
}
```

### Cursor

Add to `.cursor/mcp.json`:

```json
{
  "mcpServers": {
    "rfw_gen": {
      "command": "dart",
      "args": ["run", "rfw_gen_mcp"]
    }
  }
}
```

### Standalone

```bash
dart run rfw_gen_mcp
```

The server communicates over stdio using the MCP JSON-RPC protocol.

## Related Packages

- [rfw_gen](https://pub.dev/packages/rfw_gen) - Annotations and runtime helpers
- [rfw_gen_builder](https://pub.dev/packages/rfw_gen_builder) - build_runner code generator
- [rfw](https://pub.dev/packages/rfw) - Remote Flutter Widgets
