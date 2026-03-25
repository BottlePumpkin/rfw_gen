import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor_theme.dart';
import 'rfw_editor_controller.dart';

/// Side drawer that shows user-saved snippets.
///
/// Users can save their current work, browse saved snippets,
/// load them into the editor, and copy rfwtxt to clipboard.
class SnippetPanel extends StatelessWidget {
  const SnippetPanel({
    super.key,
    required this.controller,
  });

  final RfwEditorController controller;

  void _copySnippet(BuildContext context, RfwSnippet snippet) {
    Clipboard.setData(ClipboardData(text: snippet.rfwtxt));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied "${snippet.name}" to clipboard',
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: EditorColors.szsGray90,
      ),
    );
  }

  void _loadSnippet(RfwSnippet snippet) {
    controller.loadSnippet(snippet);
  }

  Future<void> _deleteSnippet(BuildContext context, RfwSnippet snippet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete snippet?'),
        content: Text('"${snippet.name}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: EditorColors.szsRed50,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteSavedSnippet(snippet.name);
    }
  }

  Future<void> _saveSnippet(BuildContext context) async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save snippet'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Snippet name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();

    if (name != null && name.trim().isNotEmpty) {
      await controller.saveCurrentAsSnippet(name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = controller.isDarkTheme;
    final bgColor = isDark ? EditorColors.darkBg : EditorColors.pageBg;
    final textColor =
        isDark ? EditorColors.darkText : EditorColors.szsGray100;
    final subTextColor =
        isDark ? EditorColors.darkTextDim : EditorColors.szsGray50;

    return Container(
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? EditorColors.darkSurface : EditorColors.cardBg,
              border: Border(
                bottom: BorderSide(
                  color:
                      isDark ? EditorColors.darkBorder : EditorColors.divider,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.bookmark_outline, size: 18, color: subTextColor),
                const SizedBox(width: 8),
                Text(
                  'My Snippets',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.add, size: 18, color: subTextColor),
                  onPressed: () => _saveSnippet(context),
                  tooltip: 'Save current',
                  splashRadius: 16,
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: subTextColor),
                  onPressed: controller.toggleSnippetDrawer,
                  tooltip: 'Close',
                  splashRadius: 16,
                ),
              ],
            ),
          ),
          // Snippet list
          Expanded(
            child: controller.savedSnippets.isEmpty
                ? _buildEmptyState(textColor, subTextColor, context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: controller.savedSnippets.length,
                    itemBuilder: (ctx, i) => _buildSnippetItem(
                      ctx,
                      controller.savedSnippets[i],
                      isDark: isDark,
                      textColor: textColor,
                      subTextColor: subTextColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color textColor,
    Color subTextColor,
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmark_border, size: 48, color: subTextColor),
            const SizedBox(height: 12),
            Text(
              'No saved snippets',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to save your current work',
              style: TextStyle(fontSize: 12, color: subTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSnippetItem(
    BuildContext context,
    RfwSnippet snippet, {
    required bool isDark,
    required Color textColor,
    required Color subTextColor,
  }) {
    return InkWell(
      onTap: () => _loadSnippet(snippet),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snippet.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    snippet.widgetName,
                    style: TextStyle(
                      fontSize: 11,
                      color: subTextColor,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.copy, size: 14, color: subTextColor),
              onPressed: () => _copySnippet(context, snippet),
              tooltip: 'Copy to clipboard',
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 14, color: subTextColor),
              onPressed: () => _deleteSnippet(context, snippet),
              tooltip: 'Delete',
              splashRadius: 14,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }
}
