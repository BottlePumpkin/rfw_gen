// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';
import '../../widgets/gallery/mystique_box_button.dart';

@RfwWidget('root')
Widget buildWidgetDetailMystiqueBoxButton() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          child: Text(
            'Back to Gallery',
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF237AF2),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        SizedBox(height: 24.0),
        Text(
          'MystiqueBoxButton',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'A versatile button component with primary, secondary, and disabled variants.',
          style: const TextStyle(fontSize: 16.0, color: Color(0xFF49515A)),
        ),
        SizedBox(height: 32.0),
        Text(
          'Preview',
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 12.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MystiqueBoxButton(text: 'Primary', type: 'primary', size: 'm'),
            SizedBox(height: 8.0),
            MystiqueBoxButton(text: 'Secondary', type: 'secondary', size: 'm'),
            SizedBox(height: 8.0),
            MystiqueBoxButton(text: 'Disabled', type: 'disabled', size: 'm'),
          ],
        ),
        SizedBox(height: 32.0),
        Text(
          'Properties',
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Name', 'Type', 'Required'],
          rows: [
            ['text', 'String', 'Yes'],
            ['type', 'String (primary/secondary/disabled)', 'No'],
            ['size', 'String (xl/l/m/s)', 'No'],
            ['onPressed', 'handler', 'No'],
          ],
        ),
        SizedBox(height: 32.0),
        Text(
          'rfwtxt Usage',
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 12.0),
        CodeBlock(
          code:
              'MystiqueBoxButton(text: "Click", type: "primary", onPressed: event "tap" {})',
        ),
      ],
    ),
  );
}
