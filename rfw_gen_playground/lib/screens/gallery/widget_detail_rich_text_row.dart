// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';

@RfwWidget('root')
Widget buildWidgetDetailRichTextRow() {
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
          'RichTextRow',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'Renders inline rich text with mixed styles, bold, italic, and colored segments.',
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
            Text('Hello ', style: const TextStyle(fontSize: 16.0)),
            Text(
              'World',
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
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
            ['segments', 'List<TextSegment>', 'Yes'],
            ['segments[].text', 'String', 'Yes'],
            ['segments[].bold', 'bool', 'No'],
            ['segments[].italic', 'bool', 'No'],
            ['segments[].color', 'int', 'No'],
            ['segments[].link', 'String', 'No'],
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
              'RichTextRow(segments: [{ text: "Hello " }, { text: "World", bold: true }])',
        ),
      ],
    ),
  );
}
