import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class AppConfig {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<List<SourceDefinition>> getSources() async {
    final raw = _prefs?.getString('sources');
    if (raw == null || raw.isEmpty) return defaultSources;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return defaultSources;
    }
  }

  static Future<void> saveSources(List<SourceDefinition> sources) async {
    await _prefs?.setString('sources', jsonEncode(sources.map((e) => e.toMap()).toList()));
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final raw = _prefs?.getString('history');
    if (raw == null) return [];
    try { return List<Map<String, dynamic>>.from(jsonDecode(raw)); } catch (_) { return []; }
  }

  static Future<void> addHistory(MediaItem item) async {
    final list = await getHistory();
    list.removeWhere((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    list.insert(0, item.toMap());
    if (list.length > 100) list.removeRange(100, list.length);
    await _prefs?.setString('history', jsonEncode(list));
  }

  static Future<void> clearHistory() async {
    await _prefs?.remove('history');
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final raw = _prefs?.getString('favorites');
    if (raw == null) return [];
    try { return List<Map<String, dynamic>>.from(jsonDecode(raw)); } catch (_) { return []; }
  }

  static Future<void> toggleFavorite(MediaItem item) async {
    final list = await getFavorites();
    final exists = list.any((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    if (exists) {
      list.removeWhere((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    } else {
      list.insert(0, item.toMap());
    }
    await _prefs?.setString('favorites', jsonEncode(list));
  }

  static Future<bool> isFavorite(MediaItem item) async {
    final list = await getFavorites();
    return list.any((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
  }

  static Future<List<String>> getSearchHistory() async {
    final raw = _prefs?.getString('search_history');
    if (raw == null) return [];
    try { return List<String>.from(jsonDecode(raw)); } catch (_) { return []; }
  }

  static Future<void> addSearchHistory(String query) async {
    final list = await getSearchHistory();
    list.remove(query);
    list.insert(0, query);
    if (list.length > 30) list.removeRange(30, list.length);
    await _prefs?.setString('search_history', jsonEncode(list));
  }

  static Future<void> clearSearchHistory() async {
    await _prefs?.remove('search_history');
  }

  static final defaultSources = <SourceDefinition>[
    SourceDefinition(
      id: 'demo-json', name: 'JSON 视频示例源',
      api: 'https://example.com/api.php/provide/vod/', type: ContentType.video),
  ];
}
