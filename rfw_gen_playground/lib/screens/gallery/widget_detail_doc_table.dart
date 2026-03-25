// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';

@RfwWidget('root')
Widget buildWidgetDetailDocTable() {
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
          'DocTable',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'A table component for displaying structured data with headers and rows.',
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
        DocTable(
          headers: ['Widget', 'Type'],
          rows: [
            ['Container', 'Layout'],
            ['Text', 'Display'],
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
            ['headers', 'List<String>', 'Yes'],
            ['rows', 'List<List<String>>', 'Yes'],
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
        CodeBlock(code: 'DocTable(headers: ["Col1", "Col2"], rows: [["a", "b"]])'),
      ],
    ),
  );
}
