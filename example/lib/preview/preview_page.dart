import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rfw_preview/rfw_preview.dart';

import '../custom/custom_widget_builders.dart';

/// Split-pane editor + live preview for rfwtxt.
///
/// Left side: code editor for rfwtxt
/// Right side: rendered RFW widget preview
class PreviewPage extends StatefulWidget {
  const PreviewPage({super.key});

  @override
  State<PreviewPage> createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  final _controller = TextEditingController();
  final _widgetNameController = TextEditingController(text: 'preview');
  String? _error;
  String _rfwtxt = '';
  int _renderKey = 0;

  static const _previewLibrary = LibraryName(<String>['preview']);

  static const _defaultRfwtxt = '''import core.widgets;
import material;
import custom.widgets;

widget preview = Column(
  children: [
    CustomText(
      text: "Hello, RFW Preview!",
      fontType: "heading",
      color: 0xFF1565C0,
    ),
    SizedBox(height: 16.0),
    CustomButton(
      onPressed: event "button.tap" {},
      child: Text(text: "Tap me"),
    ),
    SizedBox(height: 16.0),
    CustomBadge(
      label: "NEW",
      count: 3,
      backgroundColor: 0xFF4CAF50,
    ),
  ],
);''';

  @override
  void initState() {
    super.initState();
    _controller.text = _defaultRfwtxt;
    _rfwtxt = _defaultRfwtxt;
  }

  @override
  void dispose() {
    _controller.dispose();
    _widgetNameController.dispose();
    super.dispose();
  }

  void _onRender() {
    setState(() {
      _rfwtxt = _controller.text;
      _error = null;
      _renderKey++;
    });
  }

  Future<void> _loadSnippet(String assetPath, String widgetName) async {
    try {
      final text = await rootBundle.loadString(assetPath);
      setState(() {
        _controller.text = text;
        _widgetNameController.text = widgetName;
        _rfwtxt = text;
        _error = null;
        _renderKey++;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RFW Preview Editor'),
        actions: [
          PopupMenuButton<(String, String)>(
            icon: const Icon(Icons.snippet_folder),
            tooltip: 'Load snippet',
            onSelected: (item) => _loadSnippet(item.$1, item.$2),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: (
                  'lib/custom/custom_widgets.rfwtxt',
                  'customTextDemo',
                ),
                child: Text('Custom Widgets'),
              ),
              const PopupMenuItem(
                value: (
                  'lib/catalog/catalog_widgets.rfwtxt',
                  'columnDemo',
                ),
                child: Text('Catalog Widgets'),
              ),
              const PopupMenuItem(
                value: (
                  'lib/ecommerce/shop_widgets.rfwtxt',
                  'shopHome',
                ),
                child: Text('Shop Widgets'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      return Row(
        children: [
          Expanded(child: _buildEditor()),
          const VerticalDivider(width: 1),
          Expanded(child: _buildPreview()),
        ],
      );
    }

    // Narrow: top editor, bottom preview
    return Column(
      children: [
        Expanded(child: _buildEditor()),
        const Divider(height: 1),
        Expanded(child: _buildPreview()),
      ],
    );
  }

  Widget _buildEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Row(
            children: [
              const Text('rfwtxt',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 160,
                height: 36,
                child: TextField(
                  controller: _widgetNameController,
                  decoration: const InputDecoration(
                    labelText: 'widget name',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _onRender,
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Render'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                height: 1.5,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text('Preview',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: _error != null
                ? _buildError()
                : _rfwtxt.isEmpty
                    ? const Center(
                        child: Text('Enter rfwtxt and press Render'))
                    : _buildRfwPreview(),
          ),
        ),
      ],
    );
  }

  Widget _buildRfwPreview() {
    return RfwPreview(
      key: ValueKey(_renderKey),
      source: RfwSource.text(
        _rfwtxt,
        library: _previewLibrary,
      ),
      widget: _widgetNameController.text,
      localWidgetLibraries: {
        customWidgetsLibraryName: LocalWidgetLibrary(customWidgetBuilders),
      },
      onEvent: (name, args) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event: $name ${args.isNotEmpty ? args : ""}'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      errorBuilder: (context, error) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            'Parse Error:\n\n$error',
            style: TextStyle(
              color: Colors.red.shade700,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
          ),
        );
      },
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SelectableText(
        'Error:\n\n$_error',
        style: TextStyle(
          color: Colors.red.shade700,
          fontFamily: 'monospace',
          fontSize: 13,
        ),
      ),
    );
  }
}
