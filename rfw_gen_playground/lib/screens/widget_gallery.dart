// ignore_for_file: argument_type_not_assignable, list_element_type_not_assignable
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';
import '../widgets/doc_table.dart';
import '../widgets/link_text.dart';

@RfwWidget('root')
Widget buildWidgetGallery() {
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
              Text('Widget Gallery',
                  style: const TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF141618))),
              SizedBox(height: 8.0),
              Text('All widgets supported by RFW, organized by category.',
                  style: const TextStyle(
                      fontSize: 16.0, color: Color(0xFF49515A))),
            ],
          ),
        ),
        SizedBox(height: 32.0),

        // Layout Widgets
        Text('Layout',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Widgets for arranging children in rows, columns, and stacks.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['Column', 'mainAxisAlignment, crossAxisAlignment, mainAxisSize', 'childList(children)'],
            ['Row', 'mainAxisAlignment, crossAxisAlignment, mainAxisSize', 'childList(children)'],
            ['Wrap', 'direction, spacing, runSpacing, alignment', 'childList(children)'],
            ['Stack', 'alignment, fit, clipBehavior', 'childList(children)'],
            ['Expanded', 'flex', 'child'],
            ['Flexible', 'flex, fit', 'child'],
            ['SizedBox', 'width, height', 'optionalChild'],
            ['SizedBoxExpand', '(none)', 'optionalChild'],
            ['SizedBoxShrink', '(none)', 'optionalChild'],
            ['Spacer', 'flex', '(none)'],
            ['Align', 'alignment, widthFactor, heightFactor', 'optionalChild'],
            ['Center', 'widthFactor, heightFactor', 'optionalChild'],
            ['AspectRatio', 'aspectRatio', 'optionalChild'],
            ['FittedBox', 'fit, alignment, clipBehavior', 'optionalChild'],
            ['FractionallySizedBox', 'alignment, widthFactor, heightFactor', 'child'],
            ['IntrinsicHeight', '(none)', 'optionalChild'],
            ['IntrinsicWidth', 'width, height', 'optionalChild'],
          ],
        ),
        SizedBox(height: 32.0),

        // Material Widgets
        Text('Material',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Material Design widgets: buttons, cards, scaffolds, and more.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['Scaffold', 'backgroundColor, resizeToAvoidBottomInset', 'appBar, body, floatingActionButton, drawer'],
            ['AppBar', 'backgroundColor, elevation, centerTitle', 'leading, title, actions'],
            ['Card', 'color, elevation, shape, margin', 'optionalChild'],
            ['ElevatedButton', 'autofocus, clipBehavior', 'child (onPressed)'],
            ['TextButton', 'autofocus, clipBehavior', 'child (onPressed)'],
            ['OutlinedButton', 'autofocus, clipBehavior', 'child (onPressed)'],
            ['FloatingActionButton', 'tooltip, backgroundColor, mini', 'child (onPressed)'],
            ['ListTile', 'dense, enabled, selected', 'leading, title, subtitle, trailing'],
            ['InkWell', 'splashColor, highlightColor', 'optionalChild (onTap)'],
            ['Slider', 'min, max, value, divisions', '(none) (onChanged)'],
            ['Divider', 'height, thickness, indent, color', '(none)'],
            ['VerticalDivider', 'width, thickness, indent, color', '(none)'],
            ['Material', 'type, elevation, color', 'child'],
            ['OverflowBar', 'spacing, alignment', 'childList(children)'],
            ['Drawer', 'elevation', 'optionalChild'],
            ['CircularProgressIndicator', 'value, color, strokeWidth', '(none)'],
            ['LinearProgressIndicator', 'value, color, backgroundColor', '(none)'],
          ],
        ),
        SizedBox(height: 32.0),

        // Styling & Visual
        Text('Styling & Visual',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Decoration, text styling, images, and visual effects.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['Container', 'padding, color, decoration, width, height, margin', 'optionalChild'],
            ['Padding', 'padding, duration, curve', 'optionalChild'],
            ['Opacity', 'opacity, duration, curve', 'optionalChild'],
            ['ClipRRect', 'borderRadius, clipBehavior', 'optionalChild'],
            ['ColoredBox', 'color', 'optionalChild'],
            ['DefaultTextStyle', 'style, textAlign, softWrap, maxLines', 'child'],
            ['Directionality', 'textDirection', 'child'],
            ['Text', 'text (positional), style, textAlign, maxLines', '(none)'],
            ['Icon', 'iconData, size, color, semanticLabel', '(none)'],
            ['IconTheme', 'iconThemeData', 'child'],
            ['Image', 'imageProvider, width, height, fit', 'optionalChild'],
            ['Placeholder', 'color, strokeWidth', '(none)'],
          ],
        ),
        SizedBox(height: 32.0),

        // Scrolling
        Text('Scrolling',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Scrollable containers for lists, grids, and overflow content.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['ListView', 'scrollDirection, shrinkWrap, padding, itemExtent', 'childList(children)'],
            ['GridView', 'scrollDirection, shrinkWrap, padding, gridDelegate', 'childList(children)'],
            ['SingleChildScrollView', 'scrollDirection, padding, primary', 'optionalChild'],
            ['ListBody', 'mainAxis, reverse', 'childList(children)'],
          ],
        ),
        SizedBox(height: 32.0),

        // Transform
        Text('Transform',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Widgets for positioning, rotation, and scaling with implicit animation.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['Positioned', 'start, top, end, bottom, width, height', 'child'],
            ['Rotation', 'turns, alignment, duration, curve', 'optionalChild'],
            ['Scale', 'scale, alignment, duration, curve', 'optionalChild'],
          ],
        ),
        SizedBox(height: 32.0),

        // Interaction
        Text('Interaction',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 8.0),
        Text('Gesture detection and user input handling.',
            style:
                const TextStyle(fontSize: 14.0, color: Color(0xFF49515A))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['GestureDetector', 'behavior', 'optionalChild (onTap, onDoubleTap, onLongPress)'],
          ],
        ),
        SizedBox(height: 32.0),

        // Other
        Text('Other',
            style: const TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618))),
        SizedBox(height: 12.0),
        DocTable(
          headers: ['Widget', 'Key Params', 'Children'],
          rows: [
            ['AnimationDefaults', 'duration, curve', 'child'],
            ['SafeArea', 'left, top, right, bottom, minimum', 'child'],
          ],
        ),
        SizedBox(height: 32.0),

        // Navigation
        LinkText(text: 'Syntax Guide', page: 'syntax-guide'),
        SizedBox(height: 8.0),
        LinkText(text: 'API Reference', page: 'api-reference'),
      ],
    ),
  );
}
