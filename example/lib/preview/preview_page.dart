import 'package:flutter/material.dart';
import 'package:rfw_preview/rfw_preview.dart';

import '../custom/custom_widget_builders.dart';

/// Default rfwtxt snippet for the editor.
const _defaultRfwtxt = '''import core.widgets;
import material;
import rfw_gen_example;

widget customTextDemo = Column(
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

/// Preview page using the [RfwEditor] from the rfw_preview package.
class PreviewPage extends StatelessWidget {
  const PreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RfwEditor(
      localWidgetLibraries: {
        customWidgetsLibraryName: LocalWidgetLibrary(customWidgetBuilders),
      },
      snippets: [
        const RfwSnippet(
          name: 'Custom Widgets',
          rfwtxt: _defaultRfwtxt,
          widgetName: 'customTextDemo',
        ),
      ],
    );
  }
}
