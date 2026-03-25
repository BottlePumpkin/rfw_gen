import 'package:flutter/material.dart';

class MystiqueTag extends StatelessWidget {
  const MystiqueTag({super.key, required this.title, this.type = 'primary', this.size = 'medium'});
  final String title;
  final String type;
  final String size;

  double get _height => switch (size) { 'small' => 24.0, 'medium' => 28.0, 'large' => 32.0, _ => 28.0 };

  @override
  Widget build(BuildContext context) {
    final bgColor = switch (type) { 'primary' => const Color(0xFFF1F8FF), 'gray' => const Color(0xFFF5F6F8), 'red' => const Color(0xFFFFEBEE), 'outline' => Colors.transparent, _ => const Color(0xFFF1F8FF) };
    final txtColor = switch (type) { 'primary' => const Color(0xFF237AF2), 'gray' => const Color(0xFF49515A), 'red' => const Color(0xFFFF5041), 'outline' => const Color(0xFF237AF2), _ => const Color(0xFF237AF2) };
    return Container(
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(100.0), border: type == 'outline' ? Border.all(color: const Color(0xFF237AF2)) : null),
      child: Center(widthFactor: 1.0, child: Text(title, style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700, color: txtColor))),
    );
  }
}
