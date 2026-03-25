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
          code: '@RfwWidget("root")  Widget buildGreeting() {  return Text("Hello, World!",    style: TextStyle(fontSize: 24.0, color: Color(0xFF141618)));  }',
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
          code: 'widget root = Text(text: "Hello, World!", style: { fontSize: 24.0, color: 0xFF141618 });',
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
          code: '@RfwWidget("root")  Widget buildProfile() {  return Column(    crossAxisAlignment: CrossAxisAlignment.start,    children: [      Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),      SizedBox(height: 8.0),      Text("Developer"),    ],  );  }',
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
          code: 'widget root = Column(  crossAxisAlignment: "start",  children: [    Text(text: "Name", style: { fontWeight: "bold" }),    SizedBox(height: 8.0),    Text(text: "Developer"),  ],);',
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
          code: '@RfwWidget("root")  Widget buildCard() {  return Container(    padding: EdgeInsets.all(16.0),    color: Color(0xFFF5F5F5),    child: Text("Content"),  );  }',
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
          code: 'widget root = Container(  padding: [16.0],  color: 0xFFF5F5F5,  child: Text(text: "Content"),);',
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
          code: 'widget root = Column(  children: [    Text(text: data.user.name),    Text(text: ["Score: ", data.user.score]),  ],);',
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
          code: 'widget root = ElevatedButton(  onPressed: event "button.clicked" { id: "submit" },  child: Text(text: "Submit"),);',
          language: 'rfwtxt',
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Back to Home', page: 'home'),
      ],
    ),
  );
}
