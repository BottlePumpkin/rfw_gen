import 'package:flutter/material.dart';

import 'editor_theme.dart';
import 'rfw_editor_controller.dart';

/// JSON data editor panel with real-time validation and apply button.
class DataPanel extends StatefulWidget {
  const DataPanel({
    super.key,
    required this.controller,
  });

  /// The editor controller.
  final RfwEditorController controller;

  @override
  State<DataPanel> createState() => _DataPanelState();
}

class _DataPanelState extends State<DataPanel> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.controller.jsonText);
    _textController.addListener(_onTextChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    widget.controller.removeListener(_onControllerChanged);
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.controller.updateJsonText(_textController.text);
  }

  void _onControllerChanged() {
    // Sync if changed externally (e.g., snippet load).
    if (_textController.text != widget.controller.jsonText) {
      _textController.text = widget.controller.jsonText;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.controller.isDarkTheme;
    final bgColor = isDark ? EditorColors.darkBg : EditorColors.cardBg;
    final textColor = isDark ? EditorColors.darkText : EditorColors.szsGray100;

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
                  'JSON Data',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? EditorColors.darkText
                        : EditorColors.szsGray100,
                  ),
                ),
                const Spacer(),
                if (widget.controller.jsonError != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 14, color: EditorColors.szsRed50),
                      const SizedBox(width: 4),
                      Text(
                        widget.controller.jsonError!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: EditorColors.szsRed50,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => widget.controller.applyJsonData(),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 24),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Apply', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          // Editor
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
                color: textColor,
              ),
              cursorColor: EditorColors.szsBlue55,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
