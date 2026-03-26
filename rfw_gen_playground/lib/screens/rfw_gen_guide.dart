// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildRfwGenGuide() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('rfw_gen Package',
            style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text(
            'Core package providing @RfwWidget annotation, RfwConverter, and WidgetRegistry.',
            style:
                const TextStyle(fontSize: 16.0, color: Color(0xFF49515A))),
        SizedBox(height: 32.0),

        // @RfwWidget annotation
        Text('@RfwWidget Annotation',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Mark a top-level function to generate rfwtxt. The string argument becomes the widget name in the output.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                "@RfwWidget('productCard')\\nWidget buildProductCard() {\\n  return Card(\\n    child: Text('Hello'),\\n  );\\n}"),
        SizedBox(height: 12.0),
        Text(
            'Rules: must be top-level, use block body with return, function name starts with build.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 24.0),

        // RfwConverter
        Text('RfwConverter',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'The conversion engine transforms Flutter widget trees into rfwtxt format. It handles widget mapping, argument encoding, and child resolution.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Feature', 'Description'],
          rows: [
            ['Widget mapping', 'Maps Flutter constructors to RFW widget names'],
            ['Argument encoding', 'Converts Dart types to rfwtxt literals'],
            ['Child resolution', 'Handles child, optionalChild, childList'],
            ['Data references', 'Supports data.path and args.param syntax'],
            ['State management', 'Converts state access and set state mutations'],
            ['Event handlers', 'Maps callbacks to event declarations'],
          ],
        ),
        SizedBox(height: 24.0),

        // WidgetRegistry
        Text('WidgetRegistry',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Registry of all supported RFW widgets with their parameters, child types, and handlers.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                "final registry = WidgetRegistry();\\nfinal info = registry.lookup('Container');"),
        SizedBox(height: 24.0),

        // Supported types
        Text('Supported Argument Types',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Type', 'RFW Encoding'],
          rows: [
            ['Color', '0xAARRGGBB integer'],
            ['EdgeInsets', 'List of 1-4 doubles'],
            ['TextStyle', 'Map with fontSize, fontWeight, color, etc.'],
            ['Alignment', 'Map with x and y doubles'],
            ['BoxDecoration', 'Map with type, color, borderRadius, etc.'],
            ['Duration', 'Integer in milliseconds'],
            ['Enums', 'Lowercase string values'],
          ],
        ),
        SizedBox(height: 24.0),

        // Supported widgets overview
        Text('Supported Widgets',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Category', 'Widgets'],
          rows: [
            ['Layout', 'Column, Row, Stack, Wrap, Center, Align, Expanded, SizedBox, Spacer'],
            ['Scrolling', 'ListView, GridView, SingleChildScrollView'],
            ['Styling', 'Container, Padding, Opacity, ClipRRect, ColoredBox, Text, Icon, Image'],
            ['Material', 'Scaffold, AppBar, Card, ElevatedButton, ListTile, InkWell, Divider'],
            ['Interaction', 'GestureDetector, InkWell, ElevatedButton, TextButton'],
            ['Transform', 'Positioned, Rotation, Scale'],
          ],
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(
            text: 'Next: rfw_gen_builder Guide', page: 'rfw-gen-builder'),
      ],
    ),
  );
}
