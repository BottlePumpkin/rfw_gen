// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildExamples() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(32.0),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8E1),
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Conversion Examples',
                  style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('Before and After: Dart to rfwtxt',
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF49515A))),
            ],
          ),
        ),
        SizedBox(height: 32.0),

        // Example 1: Simple text
        Text('Example 1: Simple Text Widget',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('A basic @RfwWidget function that returns a styled Text widget.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        Text('Dart Input:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: '@RfwWidget("root")\\nWidget buildGreeting() {\\n  return Text(\\n    "Hello, World!",\\n    style: TextStyle(fontSize: 24.0, color: Color(0xFF141618)),\\n  );\\n}',
          language: 'dart',
        ),
        SizedBox(height: 12.0),
        Text('rfwtxt Output:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: 'widget root = Text(\\n  text: "Hello, World!",\\n  style: { fontSize: 24.0, color: 0xFF141618 },\\n);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 32.0),

        // Example 2: Layout with children
        Text('Example 2: Column Layout',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('A Column with multiple children and crossAxisAlignment.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        Text('Dart Input:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: '@RfwWidget("root")\\nWidget buildProfile() {\\n  return Column(\\n    crossAxisAlignment: CrossAxisAlignment.start,\\n    children: [\\n      Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),\\n      SizedBox(height: 8.0),\\n      Text("Developer"),\\n    ],\\n  );\\n}',
          language: 'dart',
        ),
        SizedBox(height: 12.0),
        Text('rfwtxt Output:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: 'widget root = Column(\\n  crossAxisAlignment: "start",\\n  children: [\\n    Text(text: "Name", style: { fontWeight: "bold" }),\\n    SizedBox(height: 8.0),\\n    Text(text: "Developer"),\\n  ],\\n);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 32.0),

        // Example 3: Container with decoration
        Text('Example 3: Styled Container',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('A Container with color, padding, and border radius.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        Text('Dart Input:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: '@RfwWidget("root")\\nWidget buildCard() {\\n  return Container(\\n    padding: EdgeInsets.all(16.0),\\n    color: Color(0xFFF5F5F5),\\n    child: Text("Content"),\\n  );\\n}',
          language: 'dart',
        ),
        SizedBox(height: 12.0),
        Text('rfwtxt Output:',
            style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w600,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        CodeBlock(
          code: 'widget root = Container(\\n  padding: [16.0],\\n  color: 0xFFF5F5F5,\\n  child: Text(text: "Content"),\\n);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 32.0),

        // Conversion rules
        Text('Key Conversion Rules',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Dart', 'rfwtxt'],
          rows: [
            ['Color(0xFF000000)', '0xFF000000'],
            ['EdgeInsets.all(16.0)', '[16.0]'],
            ['EdgeInsets.symmetric(h: 8, v: 4)', '[8.0, 4.0]'],
            ['FontWeight.bold', '"bold"'],
            ['CrossAxisAlignment.start', '"start"'],
            ['TextStyle(fontSize: 24.0)', '{ fontSize: 24.0 }'],
            ['Text("hello")', 'Text(text: "hello")'],
          ],
        ),
        SizedBox(height: 24.0),

        // Data binding example
        Text('Example 4: Data Binding',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('rfwtxt supports data references for dynamic content from DynamicContent.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'widget root = Column(\\n  children: [\\n    Text(text: data.user.name),\\n    Text(text: ["Score: ", data.user.score]),\\n  ],\\n);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 24.0),

        // Event handler example
        Text('Example 5: Event Handlers',
            style: const TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        Text('Use event handlers to communicate back to the host Flutter app.',
            style: const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(
          code: 'widget root = ElevatedButton(\\n  onPressed: event "button.clicked" { id: "submit" },\\n  child: Text(text: "Submit"),\\n);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Back to Home', page: 'home'),
      ],
    ),
  );
}
