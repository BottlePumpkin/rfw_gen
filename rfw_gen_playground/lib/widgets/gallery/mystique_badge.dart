import 'package:flutter/material.dart';

class MystiqueBadge extends StatelessWidget {
  const MystiqueBadge({super.key, this.type = 'dot', this.title, this.color});
  final String type;
  final String? title;
  final int? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color != null ? Color(color!) : const Color(0xFFFF5041);
    if (type == 'dot') return Container(width: 8.0, height: 8.0, decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle));
    final isEvent = type == 'event';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(color: isEvent ? badgeColor : badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100.0)),
      child: Text(title ?? '', style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.w700, color: isEvent ? Colors.white : badgeColor)),
    );
  }
}
