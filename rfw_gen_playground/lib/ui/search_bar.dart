import 'package:flutter/material.dart';

import '../remote/screen_registry.dart';

class DocSearchBar extends StatefulWidget {
  const DocSearchBar({
    super.key,
    required this.manifest,
    required this.onPageSelected,
  });

  final Manifest manifest;
  final ValueChanged<String> onPageSelected;

  @override
  State<DocSearchBar> createState() => _DocSearchBarState();
}

class _DocSearchBarState extends State<DocSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<ScreenEntry> _results = [];
  bool _showResults = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    setState(() {
      _results = widget.manifest.search(query);
      _showResults = _results.isNotEmpty;
    });
  }

  void _selectResult(ScreenEntry entry) {
    widget.onPageSelected(entry.id);
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _results = [];
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Search docs...',
              hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF788391)),
              prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF788391)),
              filled: true,
              fillColor: const Color(0xFFF5F6F8),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        if (_showResults)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final entry = _results[index];
                return ListTile(
                  title: Text(entry.title, style: const TextStyle(fontSize: 14)),
                  subtitle: Text(
                    entry.category,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF788391)),
                  ),
                  dense: true,
                  onTap: () => _selectResult(entry),
                );
              },
            ),
          ),
      ],
    );
  }
}
