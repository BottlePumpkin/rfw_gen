import 'package:flutter/material.dart';

import '../remote/screen_registry.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.manifest,
    required this.selectedPageId,
    required this.onPageSelected,
  });

  final Manifest manifest;
  final String selectedPageId;
  final ValueChanged<String> onPageSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Text(
              'rfw_gen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF141618),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildCategoryList(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryList() {
    final widgets = <Widget>[];
    for (final category in manifest.categories) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            category.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF788391),
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      final screens = manifest.screensForCategory(category.id);
      for (final screen in screens) {
        final isSelected = screen.id == selectedPageId;
        widgets.add(
          _PageItem(
            title: screen.title,
            isSelected: isSelected,
            onTap: () => onPageSelected(screen.id),
          ),
        );
      }
    }
    return widgets;
  }
}

class _PageItem extends StatelessWidget {
  const _PageItem({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: isSelected ? const Color(0xFFF1F8FF) : null,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF237AF2) : const Color(0xFF49515A),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
