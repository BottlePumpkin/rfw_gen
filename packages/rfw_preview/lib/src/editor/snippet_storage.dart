import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'rfw_editor_controller.dart';

/// Persists user-saved snippets using [SharedPreferences].
///
/// Snippets are stored as a JSON list under a single key.
class SnippetStorage {
  static const _key = 'rfw_editor_saved_snippets';

  /// Load all saved snippets.
  static Future<List<RfwSnippet>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];

    try {
      final list = jsonDecode(json) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return RfwSnippet(
          name: map['name'] as String,
          rfwtxt: map['rfwtxt'] as String,
          widgetName: map['widgetName'] as String,
          data: map['data'] != null
              ? Map<String, Object>.from(map['data'] as Map)
              : null,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Save a snippet. Appends to existing list.
  static Future<void> save(RfwSnippet snippet) async {
    final snippets = await load();
    snippets.add(snippet);
    await _persist(snippets);
  }

  /// Delete a snippet by name.
  static Future<void> delete(String name) async {
    final snippets = await load();
    snippets.removeWhere((s) => s.name == name);
    await _persist(snippets);
  }

  static Future<void> _persist(List<RfwSnippet> snippets) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(snippets
        .map((s) => {
              'name': s.name,
              'rfwtxt': s.rfwtxt,
              'widgetName': s.widgetName,
              if (s.data != null) 'data': s.data,
            })
        .toList());
    await prefs.setString(_key, json);
  }
}
