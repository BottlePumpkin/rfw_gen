import 'dart:convert';

import 'package:flutter/material.dart';

import 'editor_theme.dart';
import 'rfw_editor_controller.dart';

/// Event log panel showing captured events with timestamps.
class EventPanel extends StatelessWidget {
  const EventPanel({
    super.key,
    required this.controller,
  });

  /// The editor controller.
  final RfwEditorController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDarkTheme;
    final bgColor = isDark ? EditorColors.darkBg : EditorColors.cardBg;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 32,
            color: isDark ? EditorColors.darkSurface : EditorColors.sectionBg,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Events',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EditorColors.darkText
                        : EditorColors.szsGray100,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${controller.events.length})',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? EditorColors.szsGray50
                        : EditorColors.szsGray70,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: controller.events.isEmpty
                      ? null
                      : controller.clearEvents,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          // Event list
          Expanded(
            child: controller.events.isEmpty
                ? Center(
                    child: Text(
                      'No events yet',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? EditorColors.szsGray50
                            : EditorColors.szsGray70,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.events.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (_, i) {
                      final event = controller.events[i];
                      final timeStr =
                          '${event.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${event.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${event.timestamp.second.toString().padLeft(2, '0')}.'
                          '${event.timestamp.millisecond.toString().padLeft(3, '0')}';
                      final argsStr = event.args.isNotEmpty
                          ? const JsonEncoder().convert(event.args)
                          : '';

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: isDark
                                    ? EditorColors.szsGray50
                                    : EditorColors.szsGray70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              event.name,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? EditorColors.darkText
                                    : EditorColors.szsGray100,
                              ),
                            ),
                            if (argsStr.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  argsStr,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: isDark
                                        ? EditorColors.szsGray50
                                        : EditorColors.szsGray70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
