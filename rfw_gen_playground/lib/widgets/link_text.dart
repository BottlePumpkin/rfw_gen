import 'package:flutter/material.dart';

class LinkText extends StatelessWidget {
  const LinkText({super.key, required this.text, required this.page, this.onNavigate});

  final String text;
  final String page;
  final ValueChanged<String>? onNavigate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onNavigate?.call(page),
      child: Text(text, style: const TextStyle(
        fontSize: 14.0,
        color: Color(0xFF237AF2),
        fontWeight: FontWeight.w500,
      )),
    );
  }
}
