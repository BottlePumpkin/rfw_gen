import 'dart:convert';

class ScreenEntry {
  const ScreenEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.rfwtxtPath,
    this.dataPath,
    this.keywords = const [],
  });

  final String id;
  final String title;
  final String category;
  final String rfwtxtPath;
  final String? dataPath;
  final List<String> keywords;

  factory ScreenEntry.fromJson(Map<String, dynamic> json) {
    return ScreenEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? '',
      rfwtxtPath: json['rfwtxt'] as String,
      dataPath: json['data'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  }
}

class Category {
  const Category({required this.id, required this.title});
  final String id;
  final String title;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] as String, title: json['title'] as String);
  }
}

class Manifest {
  const Manifest({
    required this.version,
    required this.baseUrl,
    required this.categories,
    required this.screens,
  });

  final int version;
  final String baseUrl;
  final List<Category> categories;
  final List<ScreenEntry> screens;

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      version: json['version'] as int? ?? 0,
      baseUrl: json['baseUrl'] as String? ?? '',
      categories: (json['categories'] as List<dynamic>)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList(),
      screens: (json['screens'] as List<dynamic>)
          .map((s) => ScreenEntry.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Manifest.fromJsonString(String jsonString) {
    return Manifest.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  List<ScreenEntry> screensForCategory(String categoryId) {
    return screens.where((s) => s.category == categoryId).toList();
  }

  ScreenEntry? screenById(String id) {
    return screens.where((s) => s.id == id).firstOrNull;
  }

  List<ScreenEntry> search(String query) {
    final q = query.toLowerCase();
    return screens.where((s) {
      return s.title.toLowerCase().contains(q) ||
          s.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();
  }
}
