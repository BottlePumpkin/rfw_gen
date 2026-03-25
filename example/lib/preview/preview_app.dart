// Standalone RFW Preview Editor app.
//
// Run with:
//   flutter run -t lib/preview/preview_app.dart -d macos
//   flutter run -t lib/preview/preview_app.dart -d chrome

import 'package:flutter/material.dart';
import 'package:rfw_preview/rfw_preview.dart';

import '../custom/custom_widget_builders.dart';

void main() {
  runApp(RfwEditorApp(
    localWidgetLibraries: {
      customWidgetsLibraryName: LocalWidgetLibrary(customWidgetBuilders),
    },
  ));
}
