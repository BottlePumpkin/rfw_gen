import 'package:flutter/material.dart';

class MystiqueBoxButton extends StatelessWidget {
  const MystiqueBoxButton({super.key, required this.text, this.type = 'primary', this.size = 'l', this.onPressed});
  final String text;
  final String type;
  final String size;
  final VoidCallback? onPressed;

  double get _height => switch (size) { 'xl' => 56.0, 'l' => 48.0, 'm' => 40.0, 's' => 32.0, _ => 48.0 };

  @override
  Widget build(BuildContext context) {
    final isDisabled = type == 'disabled';
    final bgColor = switch (type) { 'primary' => const Color(0xFF237AF2), 'secondary' => const Color(0xFFF1F8FF), 'disabled' => const Color(0xFFF0F1F2), _ => const Color(0xFF237AF2) };
    final textColor = switch (type) { 'primary' => const Color(0xFFFFFFFF), 'secondary' => const Color(0xFF237AF2), 'disabled' => const Color(0xFF949DA8), _ => const Color(0xFFFFFFFF) };
    return SizedBox(width: double.infinity, height: _height, child: ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(backgroundColor: bgColor, foregroundColor: textColor, disabledBackgroundColor: bgColor, disabledForegroundColor: textColor, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))),
      child: Text(text, style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700)),
    ));
  }
}
