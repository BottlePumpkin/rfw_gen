import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rfw/formats.dart';

import 'screen_registry.dart';

class RemoteLoader {
  RemoteLoader({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<Manifest> loadManifest(String manifestUrl) async {
    final response = await _client.get(Uri.parse(manifestUrl));
    if (response.statusCode != 200) {
      throw RemoteLoadException('Failed to load manifest: ${response.statusCode}');
    }
    return Manifest.fromJsonString(response.body);
  }

  Future<WidgetLibrary> loadScreen(String rfwtxtPath) async {
    final url = baseUrl.isEmpty ? rfwtxtPath : '$baseUrl/$rfwtxtPath';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw RemoteLoadException('Failed to load screen: ${response.statusCode}');
    }
    try {
      return parseLibraryFile(response.body);
    } catch (e) {
      throw RemoteLoadException('Failed to parse rfwtxt: $e');
    }
  }

  Future<Map<String, Object>> loadData(String dataPath) async {
    final url = baseUrl.isEmpty ? dataPath : '$baseUrl/$dataPath';
    final response = await _client.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw RemoteLoadException('Failed to load data: ${response.statusCode}');
    }
    return (jsonDecode(response.body) as Map<String, dynamic>).cast<String, Object>();
  }
}

class RemoteLoadException implements Exception {
  RemoteLoadException(this.message);
  final String message;

  @override
  String toString() => 'RemoteLoadException: $message';
}
