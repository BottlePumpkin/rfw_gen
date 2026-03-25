// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildPreviewGuide() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(32.0),
          decoration: const BoxDecoration(
            color: Color(0xFFF0FFF4),
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('rfw_preview',
                  style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('Live Preview Widget with Built-in Editor',
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
        Text('rfw_preview provides RfwPreview and RfwEditor widgets for live rendering and editing of rfwtxt content during development.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 24.0),

        // Core widgets
        Text('Core Widgets',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Purpose'],
          rows: [
            ['RfwPreview', 'Renders rfwtxt content as live Flutter widgets'],
            ['RfwEditor', 'Side-by-side editor and preview with live reload'],
          ],
        ),
        SizedBox(height: 24.0),

        // RfwSource
        Text('RfwSource Modes',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('RfwSource controls how rfwtxt content is loaded. Choose from three modes depending on your use case.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Mode', 'Constructor', 'Use Case'],
          rows: [
            ['Asset', 'RfwSource.asset(path)', 'Load rfwtxt from Flutter assets'],
            ['Text', 'RfwSource.text(rfwtxt)', 'Provide rfwtxt as a string directly'],
            ['Binary', 'RfwSource.binary(bytes)', 'Load pre-compiled binary data'],
          ],
        ),
        SizedBox(height: 24.0),

        // RfwPreview usage
        Text('RfwPreview Usage',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('Use RfwPreview to render a remote widget from an RfwSource. Pass data via DynamicContent and handle events with handlers.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'RfwPreview(  source: RfwSource.asset("assets/my_widget.rfwtxt"),  widgetName: "myWidget",  data: { "title": "Hello" },  onEvent: (name, args) => print("Event: \$name"),)',
          language: 'dart',
        ),
        SizedBox(height: 24.0),

        // RfwEditor usage
        Text('RfwEditor Usage',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('RfwEditor provides a split-pane view: edit rfwtxt on the left, see live preview on the right. Changes update in real-time.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'RfwEditor(  initialSource: RfwSource.text("widget hello = Text(text: \\"Hi\\");"),  widgetName: "hello",)',
          language: 'dart',
        ),
        SizedBox(height: 24.0),

        // Features
        Text('Key Features',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Feature', 'Description'],
          rows: [
            ['Live Reload', 'Preview updates instantly as you edit rfwtxt'],
            ['Error Display', 'Syntax errors shown inline with line numbers'],
            ['Custom Widgets', 'Register local widget libraries for preview'],
            ['Data Binding', 'Pass DynamicContent data to preview widgets'],
            ['Event Handling', 'Capture and debug widget events'],
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
        CodeBlock(
          code: 'dependencies:  rfw_preview: ^0.4.0',
          language: 'yaml',
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'View Examples', page: 'examples'),
      ],
    ),
  );
}
