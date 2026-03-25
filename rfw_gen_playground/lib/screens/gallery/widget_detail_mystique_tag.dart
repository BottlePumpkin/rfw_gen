// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';
import '../../widgets/gallery/mystique_tag.dart';

@RfwWidget('root')
Widget buildWidgetDetailMystiqueTag() {
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
          'MystiqueTag',
          style: const TextStyle(
            fontSize: 28.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFF141618),
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'A tag component for labeling content with color-coded categories.',
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
            MystiqueTag(title: 'Primary', type: 'primary'),
            SizedBox(width: 8.0),
            MystiqueTag(title: 'Gray', type: 'gray'),
            SizedBox(width: 8.0),
            MystiqueTag(title: 'Red', type: 'red'),
            SizedBox(width: 8.0),
            MystiqueTag(title: 'Outline', type: 'outline'),
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
            ['title', 'String', 'Yes'],
            ['type', 'String (primary/gray/red/outline)', 'No'],
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
        CodeBlock(
          code: 'MystiqueTag(title: "NEW", type: "primary", size: "medium")',
        ),
      ],
    ),
  );
}
