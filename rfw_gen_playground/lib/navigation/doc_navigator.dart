import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocNavigator {
  static String pageIdToPath(String pageId) {
    return '/${pageId.replaceAll('_', '-')}';
  }

  static String pathToPageId(String path) {
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    return cleaned.replaceAll('-', '_');
  }

  static bool handleEvent(
    BuildContext context,
    String name,
    Map<String, Object?> arguments,
  ) {
    if (name == 'navigate') {
      final page = arguments['page'] as String?;
      if (page != null) {
        context.go(pageIdToPath(page));
        return true;
      }
    }
    return false;
  }
}
