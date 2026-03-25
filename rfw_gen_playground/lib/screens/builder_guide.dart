// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildBuilderGuide() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('rfw_gen_builder Package',
            style: const TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.w800,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text(
            'build_runner integration for automatic rfwtxt code generation.',
            style:
                const TextStyle(fontSize: 16.0, color: Color(0xFF49515A))),
        SizedBox(height: 32.0),

        // How it works
        Text('How It Works',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'rfw_gen_builder scans Dart files for @RfwWidget annotations, converts the widget tree using RfwConverter, and writes output files alongside your source.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                'dart run build_runner build --delete-conflicting-outputs'),
        SizedBox(height: 12.0),
        Text(
            'Use watch mode for automatic rebuilds during development.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                'dart run build_runner watch --delete-conflicting-outputs'),
        SizedBox(height: 24.0),

        // Output files
        Text('Generated Output Files',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'For each source file with @RfwWidget, four output files are generated.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['File', 'Purpose'],
          rows: [
            ['.rfwtxt', 'Human-readable rfwtxt source for inspection and debugging'],
            ['.rfw', 'Binary format parsed by RFW runtime for production use'],
            ['.rfw_library.dart', 'Dart library with LocalWidgetLibrary builder registration'],
            ['.rfw_meta.json', 'Metadata about generated widgets for tooling integration'],
          ],
        ),
        SizedBox(height: 24.0),

        // build.yaml config
        Text('build.yaml Configuration',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'Customize generation behavior by adding a build.yaml file to your project root.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Option', 'Default', 'Description'],
          rows: [
            ['generate_rfwtxt', 'true', 'Generate human-readable .rfwtxt file'],
            ['generate_rfw', 'true', 'Generate binary .rfw file'],
            ['generate_library', 'true', 'Generate .rfw_library.dart file'],
            ['generate_meta', 'true', 'Generate .rfw_meta.json metadata'],
          ],
        ),
        SizedBox(height: 24.0),

        // Example workflow
        Text('Example Workflow',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'A typical development workflow with rfw_gen_builder.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Step', 'Action'],
          rows: [
            ['1', 'Write a Dart file with @RfwWidget functions'],
            ['2', 'Run build_runner build or watch'],
            ['3', 'Check generated .rfwtxt for correctness'],
            ['4', 'Load .rfw binary in your RFW runtime'],
            ['5', 'Use rfw_preview to test interactively'],
          ],
        ),
        SizedBox(height: 24.0),

        // Error handling
        Text('Error Handling',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text(
            'The builder reports errors at build time for unsupported patterns. Common errors include using unsupported widgets, invalid argument types, or non-top-level functions.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
            code:
                'Unsupported widget: CustomWidget is not in WidgetRegistry. Use a supported RFW widget.'),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Back to Home', page: 'home'),
      ],
    ),
  );
}
