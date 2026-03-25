// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildGettingStarted() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Getting Started',
            style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Set up rfw_gen in your Flutter project.',
            style:
                const TextStyle(fontSize: 16.0, color: Color(0xFF49515A))),
        SizedBox(height: 32.0),

        // Step 1: Install
        Text('1. Add Dependencies',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Add rfw_gen to dependencies and rfw_gen_builder to dev_dependencies.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                'flutter pub add rfw_gen && flutter pub add -d build_runner rfw_gen_builder'),
        SizedBox(height: 24.0),

        // Step 2: Annotate
        Text('2. Write an @RfwWidget Function',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Create a top-level function annotated with @RfwWidget. The argument is the widget name in rfwtxt output.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                "@RfwWidget('myWidget') Widget buildMyWidget() { return Container(color: Colors.blue); }"),
        SizedBox(height: 12.0),
        Text(
            'The function must be top-level (not inside a class), use a block body with return, and start with the build prefix.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 24.0),

        // Step 3: Build
        Text('3. Run Build Runner',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                'dart run build_runner build --delete-conflicting-outputs'),
        SizedBox(height: 12.0),
        Text(
            'This generates .rfwtxt (human-readable) and .rfw (binary) files next to your source file.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 24.0),

        // Step 4: Preview
        Text('4. Preview with rfw_preview',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Add rfw_preview to your dependencies for a live editor and preview widget during development.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'flutter pub add rfw_preview'),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Next: rfw_gen Package Guide', page: 'rfw-gen'),
      ],
    ),
  );
}
