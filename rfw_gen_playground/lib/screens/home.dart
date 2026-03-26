// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildHome() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(32.0),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8FF),
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('rfw_gen',
                  style: const TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('Flutter Widget to RFW Converter',
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF49515A))),
              SizedBox(height: 16.0),
              Text(
                  'Write Flutter widgets with @RfwWidget, get rfwtxt automatically.',
                  style: const TextStyle(
                      fontSize: 14.0, color: Color(0xFF49515A))),
            ],
          ),
        ),
        SizedBox(height: 32.0),

        // Packages overview
        Text('Packages',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 16.0),
        DocTable(
          headers: ['Package', 'Description'],
          rows: [
            ['rfw_gen', 'Core: @RfwWidget annotation + conversion engine'],
            ['rfw_gen_builder', 'build_runner code generator'],
            ['rfw_gen_mcp', 'MCP server for widget registry & validation'],
            ['rfw_preview', 'Dev preview widget with live editor'],
          ],
        ),
        SizedBox(height: 32.0),

        // Quick start
        Text('Quick Start',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 16.0),
        CodeBlock(
          code: 'dependencies:\\n  rfw_gen: ^0.4.0\\n\\ndev_dependencies:\\n  build_runner: ^2.4.0\\n  rfw_gen_builder: ^0.4.0',
          language: 'yaml',
        ),
        SizedBox(height: 24.0),

        // Navigation link
        LinkText(text: 'Getting Started Guide', page: 'getting-started'),
      ],
    ),
  );
}
