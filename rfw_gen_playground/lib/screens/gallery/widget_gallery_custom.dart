// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../../widgets/gallery/mystique_box_button.dart';
import '../../widgets/gallery/mystique_tag.dart';
import '../../widgets/gallery/mystique_badge.dart';
import '../../widgets/gallery/mystique_spinner.dart';
import '../../widgets/gallery/conditional_widget.dart';
import '../../widgets/code_block.dart';
import '../../widgets/doc_table.dart';
import '../../widgets/link_text.dart';

@RfwWidget('root')
Widget buildWidgetGalleryCustom() {
  return SingleChildScrollView(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RFW Custom Widget Gallery', style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.w800, color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Custom widgets registered via LocalWidgetLibrary for RFW.', style: const TextStyle(fontSize: 16.0, color: Color(0xFF49515A))),
        SizedBox(height: 32.0),

        // Row 1: CodeBlock + DocTable
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: CodeBlock(code: 'print("hello")'))),
                SizedBox(height: 12.0),
                Text('CodeBlock', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Dark-themed code display', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
          SizedBox(width: 12.0),
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: DocTable(headers: ['A', 'B'], rows: [['1', '2']]))),
                SizedBox(height: 12.0),
                Text('DocTable', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Table layout widget', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
        ]),
        SizedBox(height: 12.0),

        // Row 2: RichTextRow (use plain Text as preview!) + LinkText
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: Text('Hello World', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: Color(0xFF237AF2))))),
                SizedBox(height: 12.0),
                Text('RichTextRow', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Inline styled text', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
          SizedBox(width: 12.0),
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: LinkText(text: 'Click me', page: ''))),
                SizedBox(height: 12.0),
                Text('LinkText', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Tappable link text', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
        ]),
        SizedBox(height: 12.0),

        // Row 3: MystiqueBoxButton + MystiqueTag
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: MystiqueBoxButton(text: 'Button', type: 'primary', size: 'm'))),
                SizedBox(height: 12.0),
                Text('MystiqueBoxButton', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('CTA button with variants', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
          SizedBox(width: 12.0),
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [MystiqueTag(title: 'NEW', type: 'primary'), SizedBox(width: 8.0), MystiqueTag(title: 'HOT', type: 'red')]))),
                SizedBox(height: 12.0),
                Text('MystiqueTag', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Color tags', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
        ]),
        SizedBox(height: 12.0),

        // Row 4: MystiqueBadge + MystiqueSpinner
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [MystiqueBadge(type: 'dot'), SizedBox(width: 12.0), MystiqueBadge(type: 'event', title: '3', color: 0xFFFF5041), SizedBox(width: 12.0), MystiqueBadge(type: 'basic', title: 'NEW')]))),
                SizedBox(height: 12.0),
                Text('MystiqueBadge', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Dot, event, basic badges', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
          SizedBox(width: 12.0),
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: MystiqueSpinner(size: 'medium'))),
                SizedBox(height: 12.0),
                Text('MystiqueSpinner', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Loading spinner', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
        ]),
        SizedBox(height: 12.0),

        // Row 5: ConditionalWidget + empty
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GestureDetector(
            child: Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(color: const Color(0xFFFFFFFF), borderRadius: BorderRadius.circular(16.0)),
              child: Column(children: [
                SizedBox(height: 48.0, child: Center(child: ConditionalWidget(condition: true, childIfTrue: Text('Visible', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)), childIfFalse: Text('Hidden')))),
                SizedBox(height: 12.0),
                Text('ConditionalWidget', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600, color: Color(0xFF141618))),
                SizedBox(height: 4.0),
                Text('Conditional rendering', style: const TextStyle(fontSize: 12.0, color: Color(0xFF788391))),
              ]),
            ),
          )),
          SizedBox(width: 12.0),
          Expanded(child: SizedBox()),
        ]),
      ],
    ),
  );
}
