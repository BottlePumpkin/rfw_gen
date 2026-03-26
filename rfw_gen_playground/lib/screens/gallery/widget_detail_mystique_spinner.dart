// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';
import '../../widgets/gallery/mystique_spinner.dart';

@RfwWidget('root')
Widget buildWidgetDetailMystiqueSpinner() {
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
          'MystiqueSpinner',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'A loading spinner with configurable size for indicating async operations.',
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
        Row(
          children: [
            MystiqueSpinner(size: 'small'),
            SizedBox(width: 16.0),
            MystiqueSpinner(size: 'medium'),
            SizedBox(width: 16.0),
            MystiqueSpinner(size: 'large'),
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
            ['size', 'String (small/medium/large)', 'No'],
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
        CodeBlock(code: 'MystiqueSpinner(size: "large")'),
      ],
    ),
  );
}
