// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/code_block.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildSyntaxGuide() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(32.0),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F8FF),
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('rfwtxt Syntax Guide',
                  style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('Complete reference for Remote Flutter Widgets text format.',
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF49515A))),
            ],
          ),
        ),
        SizedBox(height: 32.0),

        // Imports
        Text('Imports',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Import core and material widget libraries at the top of rfwtxt files.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'import core.widgets;'),
        SizedBox(height: 8.0),
        CodeBlock(code: 'import material;'),
        SizedBox(height: 32.0),

        // Widget Declarations
        Text('Widget Declarations',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Declare a widget with "widget name = WidgetType(...);".',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'widget myWidget = Container(color: 0xFF002211, child: Text(text: "Hello"));'),
        SizedBox(height: 32.0),

        // Stateful Widgets
        Text('Stateful Widgets',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Add local state with curly braces after the widget name.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'widget Button { down: false } = GestureDetector(onTapDown: set state.down = true, child: Text(text: "tap"));'),
        SizedBox(height: 32.0),

        // Data References
        Text('Data References',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Access external data, arguments, and local state using dot notation.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'data.path.to.value'),
        SizedBox(height: 8.0),
        CodeBlock(code: 'data.list.0'),
        SizedBox(height: 8.0),
        CodeBlock(code: 'args.paramName'),
        SizedBox(height: 8.0),
        CodeBlock(code: 'state.fieldName'),
        SizedBox(height: 32.0),

        // String Concatenation
        Text('String Concatenation',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Concatenate strings and data references using a list.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'Text(text: ["Hello, ", data.user.name, "!"])'),
        SizedBox(height: 32.0),

        // Switch Expressions
        Text('Switch Expressions',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Use switch on state or data values with true/false/default cases.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'color: switch state.active { true: 0xFF00FF00, false: 0xFFFF0000, default: 0xFF888888 }'),
        SizedBox(height: 32.0),

        // State Mutation
        Text('State Mutation',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Mutate local widget state from event handlers using "set".',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'onTap: set state.selected = true,'),
        SizedBox(height: 32.0),

        // Event Handlers
        Text('Event Handlers',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Fire named events to the host app with optional arguments.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'onTap: event "shop.purchase" { productId: args.product.id, quantity: 1 },'),
        SizedBox(height: 32.0),

        // For Loops
        Text('For Loops (List Spread)',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Iterate over data lists using ...for inside children lists.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'children: [ ...for item in data.items: ListTile(title: Text(text: item.name)), ]'),
        SizedBox(height: 32.0),

        // Literals
        Text('Literals',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Supported literal types in rfwtxt.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        CodeBlock(code: 'String: "hello"  Number: 24.0  Hex: 0xFF000000  Bool: true, false  List: [16.0, 8.0]  Map: { fontSize: 24.0 }'),
        SizedBox(height: 32.0),

        // Comments
        Text('Comments',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        CodeBlock(code: '// Line comment'),
        SizedBox(height: 8.0),
        CodeBlock(code: '/* Block comment */'),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Widget Gallery', page: 'widget-gallery'),
        SizedBox(height: 8.0),
        LinkText(text: 'API Reference', page: 'api-reference'),
      ],
    ),
  );
}
