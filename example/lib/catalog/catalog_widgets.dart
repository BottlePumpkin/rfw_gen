// ignore_for_file: argument_type_not_assignable, undefined_function, undefined_class, undefined_named_parameter
import 'package:flutter/material.dart';
import 'package:rfw_gen/rfw_gen.dart';

// ============================================================
// Layout Category
// ============================================================

@RfwWidget('columnDemo')
Widget buildColumnDemo() {
  return Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    mainAxisSize: MainAxisSize.max,
    children: [
      Container(width: 60, height: 60, color: const Color(0xFF2196F3)),
      Container(width: 60, height: 60, color: const Color(0xFF4CAF50)),
      Container(width: 60, height: 60, color: const Color(0xFFFF9800)),
    ],
  );
}

@RfwWidget('rowDemo')
Widget buildRowDemo() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: [
      Container(width: 50, height: 80, color: const Color(0xFFE91E63)),
      Container(width: 50, height: 60, color: const Color(0xFF9C27B0)),
      Container(width: 50, height: 40, color: const Color(0xFF673AB7)),
    ],
  );
}

@RfwWidget('wrapDemo')
Widget buildWrapDemo() {
  return Wrap(
    spacing: 8.0,
    runSpacing: 8.0,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF2196F3),
        child: Text('Flutter', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF4CAF50),
        child: Text('RFW', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFFFF9800),
        child: Text('Dart', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFFE91E63),
        child: Text('Widget', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        color: const Color(0xFF9C27B0),
        child: Text('Remote', style: const TextStyle(color: Color(0xFFFFFFFF))),
      ),
    ],
  );
}

@RfwWidget('stackDemo')
Widget buildStackDemo() {
  return Stack(
    alignment: const Alignment(0.0, 0.0),
    children: [
      Container(width: 200, height: 200, color: const Color(0xFF2196F3)),
      Container(width: 150, height: 150, color: const Color(0xFF4CAF50)),
      Positioned(
        top: 10.0,
        end: 10.0,
        child: Container(width: 40, height: 40, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('expandedDemo')
Widget buildExpandedDemo() {
  return Row(
    children: [
      Expanded(
        flex: 2,
        child: Container(height: 60, color: const Color(0xFF2196F3)),
      ),
      Expanded(
        flex: 1,
        child: Container(height: 60, color: const Color(0xFF4CAF50)),
      ),
      Flexible(
        flex: 1,
        fit: FlexFit.loose,
        child: Container(width: 30, height: 60, color: const Color(0xFFFF9800)),
      ),
    ],
  );
}

@RfwWidget('sizedBoxDemo')
Widget buildSizedBoxDemo() {
  return Column(
    children: [
      SizedBox(
        width: 100,
        height: 50,
        child: ColoredBox(color: const Color(0xFF2196F3)),
      ),
      const Spacer(flex: 1),
      SizedBoxExpand(
        child: ColoredBox(color: const Color(0xFFE8EAF6)),
      ),
      SizedBoxShrink(),
    ],
  );
}

@RfwWidget('alignDemo')
Widget buildAlignDemo() {
  return SizedBox(
    width: 200,
    height: 200,
    child: Stack(
      children: [
        Container(color: const Color(0xFFE8EAF6)),
        Align(
          alignment: const Alignment(-1.0, -1.0),
          child: Container(width: 40, height: 40, color: const Color(0xFFFF5722)),
        ),
        Center(
          child: Text('Center'),
        ),
        Align(
          alignment: const Alignment(1.0, 1.0),
          child: Container(width: 40, height: 40, color: const Color(0xFF4CAF50)),
        ),
      ],
    ),
  );
}

@RfwWidget('aspectRatioDemo')
Widget buildAspectRatioDemo() {
  return Column(
    children: [
      AspectRatio(
        aspectRatio: 1.78,
        child: Container(color: const Color(0xFF2196F3)),
      ),
      SizedBox(height: 8),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: Container(height: 40, color: const Color(0xFF4CAF50)),
      ),
    ],
  );
}

@RfwWidget('intrinsicDemo')
Widget buildIntrinsicDemo() {
  return Column(
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 50, color: const Color(0xFF2196F3)),
            Column(
              children: [
                Container(width: 100, height: 30, color: const Color(0xFF4CAF50)),
                Container(width: 100, height: 60, color: const Color(0xFFFF9800)),
              ],
            ),
          ],
        ),
      ),
      SizedBox(height: 8),
      IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(height: 30, width: 80, color: const Color(0xFFE91E63)),
            Container(height: 30, width: 120, color: const Color(0xFF9C27B0)),
          ],
        ),
      ),
    ],
  );
}
