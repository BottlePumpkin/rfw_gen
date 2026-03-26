// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildMcpGuide() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(32.0),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F0FF),
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('rfw_gen_mcp',
                  style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('MCP Server for Widget Registry & Validation',
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF49515A))),
            ],
          ),
        ),
        SizedBox(height: 32.0),

        // Overview
        Text('Overview',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('rfw_gen_mcp provides an MCP (Model Context Protocol) server that exposes the widget registry, rfwtxt conversion, and validation tools to AI assistants and editors.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 24.0),

        // Available Tools
        Text('Available Tools',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Tool', 'Description'],
          rows: [
            ['list_widgets', 'List all supported RFW widgets with their parameters'],
            ['get_widget_info', 'Get detailed info for a specific widget (params, children, handlers)'],
            ['convert_to_rfwtxt', 'Convert a Dart @RfwWidget function to rfwtxt format'],
            ['validate_rfwtxt', 'Validate rfwtxt syntax and report errors'],
            ['get_widget_categories', 'List widget categories (layout, styling, material, etc.)'],
          ],
        ),
        SizedBox(height: 24.0),

        // Setup
        Text('Setup',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('Add rfw_gen_mcp to your dev_dependencies and configure your MCP client to connect to the server.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'dev_dependencies:\\n  rfw_gen_mcp: ^0.4.0',
          language: 'yaml',
        ),
        SizedBox(height: 24.0),

        // Running the server
        Text('Running the Server',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('Start the MCP server with the dart run command. It communicates over stdio using the MCP protocol.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'dart run rfw_gen_mcp',
          language: 'shell',
        ),
        SizedBox(height: 24.0),

        // Usage example
        Text('Tool Usage Example',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('The list_widgets tool returns all supported widgets. Use get_widget_info to drill into a specific widget.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Request', 'Response'],
          rows: [
            ['list_widgets(category: "layout")', 'Align, AspectRatio, Center, Column, Row, ...'],
            ['get_widget_info(name: "Container")', 'params: alignment, padding, color, ...'],
            ['validate_rfwtxt(code: "widget foo = ...")', 'Valid / Error at line N: message'],
          ],
        ),
        SizedBox(height: 24.0),

        // Integration
        Text('Claude Code Integration',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('Add the server to your .mcp.json configuration file to enable AI-assisted RFW widget development.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: '{\\n  "mcpServers": {\\n    "rfw_gen": {\\n      "command": "dart",\\n      "args": ["run", "rfw_gen_mcp"]\\n    }\\n  }\\n}',
          language: 'json',
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Back to Home', page: 'home'),
      ],
    ),
  );
}
