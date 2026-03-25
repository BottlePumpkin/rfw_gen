import 'package:flutter/material.dart';

class TextSegment {
  const TextSegment({
    required this.text,
    this.bold = false,
    this.italic = false,
    this.color,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final Color? color;
  final String? link;
}

class RichTextRow extends StatelessWidget {
  const RichTextRow({super.key, required this.segments});

  final List<TextSegment> segments;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(
          fontSize: 14.0,
          height: 1.6,
          color: const Color(0xFF49515A),
        ),
        children: segments.map(_buildSpan).toList(),
      ),
    );
  }

  TextSpan _buildSpan(TextSegment segment) {
    return TextSpan(
      text: segment.text,
      style: TextStyle(
        fontWeight: segment.bold ? FontWeight.bold : null,
        fontStyle: segment.italic ? FontStyle.italic : null,
        color: segment.color ??
            (segment.link != null ? const Color(0xFF237AF2) : null),
      ),
    );
  }
}
