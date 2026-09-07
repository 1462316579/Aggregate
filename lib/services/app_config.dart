import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class AppConfig {
  static SharedPreferences? _prefs;
  static List<SourceDefinition> _sourcesCache = <SourceDefinition>[];

  static List<SourceDefinition> get cachedSources => List.unmodifiable(_sourcesCache);
  static final ValueNotifier<String> themeNotifier = ValueNotifier<String>('system');
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('zh');

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    themeNotifier.value = theme;
    languageNotifier.value = language;
  }

  static String get tmdbKey => _prefs?.getString('tmdb_key') ?? '';
  static Future<void> setTmdbKey(String value) async => _prefs?.setString('tmdb_key', value);

  static String get language => _prefs?.getString('language') ?? 'zh';
  static Future<void> setLanguage(String value) async {
    await _prefs?.setString('language', value);
    languageNotifier.value = value;
  }

  static String get theme => _prefs?.getString('theme') ?? 'system';
  static Future<void> setTheme(String value) async {
    await _prefs?.setString('theme', value);
    themeNotifier.value = value;
  }

  static bool get autoCheckUpdate => _prefs?.getBool('auto_check_update') ?? true;
  static Future<void> setAutoCheckUpdate(bool value) async => _prefs?.setBool('auto_check_update', value);

  static bool get nsfw => _prefs?.getBool('nsfw') ?? false;
  static Future<void> setNsfw(bool value) async => _prefs?.setBool('nsfw', value);

  static Future<List<SourceDefinition>> getSources() async {
    final raw = _prefs?.getString('sources');
    if (raw == null || raw.isEmpty) {
      _sourcesCache = defaultSources;
      return _sourcesCache;
    }
    try {
      final list = jsonDecode(raw) as List;
      _sourcesCache = list.map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e))).toList();
      return _sourcesCache;
    } catch (_) {
      _sourcesCache = defaultSources;
      return _sourcesCache;
    }
  }

  static Future<void> saveSources(List<SourceDefinition> sources) async {
    _sourcesCache = List<SourceDefinition>.from(sources);
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

  /// 首次安装保持空白，不预置任何来源。
  static const List<SourceDefinition> defaultSources = <SourceDefinition>[];
}
