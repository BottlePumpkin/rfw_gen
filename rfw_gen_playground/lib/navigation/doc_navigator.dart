import 'package:rfw/rfw.dart';

class DocNavigator {
  DocNavigator({required this.onNavigate});

  final void Function(String pageId) onNavigate;

  bool handleEvent(String name, DynamicMap arguments) {
    if (name == 'navigate') {
      final page = arguments['page'] as String?;
      if (page != null) {
        onNavigate(page);
        return true;
      }
    }
    return false;
  }
}
