import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/content.dart';

class AppConfig {
  static SharedPreferences? _prefs;
  static List<SourceDefinition> _sourcesCache = <SourceDefinition>[];
  static List<Map<String, dynamic>> _favoritesCache = <Map<String, dynamic>>[];
  static List<Map<String, dynamic>> _historyCache = <Map<String, dynamic>>[];

  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('zh');
  static String get language => languageNotifier.value;
  static set language(String value) { languageNotifier.value = value; }

  static final ValueNotifier<String> themeNotifier = ValueNotifier<String>('system');
  static String get theme => themeNotifier.value;

  static bool autoCheckUpdate = true;
  static bool nsfw = false;

  // WebDAV settings
  static bool webdavEnabled = false;
  static String webdavHost = '';
  static String webdavUsername = '';
  static String webdavPassword = '';
  static String webdavPath = '/';

  // AI settings
  static String aiConfigName = '';
  static String aiApiUrl = '';
  static String aiApiKey = '';
  static String aiModel = 'gpt-3.5-turbo';

  // TMDB key
  static String tmdbKey = '';

  static Future<void> init() async {
    languageNotifier.value = 'zh';
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    languageNotifier.value = prefs.getString('language') ?? 'zh';
    themeNotifier.value = prefs.getString('theme') ?? 'system';
    tmdbKey = prefs.getString('tmdbKey') ?? '';
    autoCheckUpdate = prefs.getBool('autoCheckUpdate') ?? true;
    nsfw = prefs.getBool('nsfw') ?? false;
    // WebDAV
    webdavEnabled = prefs.getBool('webdavEnabled') ?? false;
    webdavHost = prefs.getString('webdavHost') ?? '';
    webdavUsername = prefs.getString('webdavUsername') ?? '';
    webdavPassword = prefs.getString('webdavPassword') ?? '';
    webdavPath = prefs.getString('webdavPath') ?? '/';
    // AI settings
    aiConfigName = prefs.getString('aiConfigName') ?? '';
    aiApiUrl = prefs.getString('aiApiUrl') ?? '';
    aiApiKey = prefs.getString('aiApiKey') ?? '';
    aiModel = prefs.getString('aiModel') ?? 'gpt-3.5-turbo';
    _sourcesCache = _parseSources(prefs.getString('sources') ?? '[]');
    _favoritesCache = _parseJsonList(prefs.getString('favorites') ?? '[]');
    _historyCache = _parseJsonList(prefs.getString('history') ?? '[]');
  }

  static Future<void> setLanguage(String language) async {
    languageNotifier.value = language;
    await _prefs?.setString('language', language);
  }

  static Future<void> setTheme(String theme) async {
    themeNotifier.value = theme;
    await _prefs?.setString('theme', theme);
  }

  static Future<void> setTmdbKey(String key) async {
    tmdbKey = key;
    await _prefs?.setString('tmdbKey', key);
  }

  static Future<void> setAutoCheckUpdate(bool value) async {
    autoCheckUpdate = value;
    await _prefs?.setBool('autoCheckUpdate', value);
  }

  static Future<void> setNsfw(bool value) async {
    nsfw = value;
    await _prefs?.setBool('nsfw', value);
  }

  // WebDAV setters
  static Future<void> setWebdavEnabled(bool value) async {
    webdavEnabled = value;
    await _prefs?.setBool('webdavEnabled', value);
  }

  static Future<void> setWebdavHost(String value) async {
    webdavHost = value;
    await _prefs?.setString('webdavHost', value);
  }

  static Future<void> setWebdavUsername(String value) async {
    webdavUsername = value;
    await _prefs?.setString('webdavUsername', value);
  }

  static Future<void> setWebdavPassword(String value) async {
    webdavPassword = value;
    await _prefs?.setString('webdavPassword', value);
  }

  static Future<void> setWebdavPath(String value) async {
    webdavPath = value;
    await _prefs?.setString('webdavPath', value);
  }

  // AI setters
  static Future<void> setAiConfigName(String value) async {
    aiConfigName = value;
    await _prefs?.setString('aiConfigName', value);
  }

  static Future<void> setAiApiUrl(String value) async {
    aiApiUrl = value;
    await _prefs?.setString('aiApiUrl', value);
  }

  static Future<void> setAiApiKey(String value) async {
    aiApiKey = value;
    await _prefs?.setString('aiApiKey', value);
  }

  static Future<void> setAiModel(String value) async {
    aiModel = value;
    await _prefs?.setString('aiModel', value);
  }

  static List<SourceDefinition> get sources => _sourcesCache;
  static List<Map<String, dynamic>> get favorites => _favoritesCache;
  static List<Map<String, dynamic>> get history => _historyCache;

  static Future<void> saveSources(List<SourceDefinition> sources) async {
    _sourcesCache = sources;
    await _prefs?.setString('sources', jsonEncode(sources.map((e) => e.toMap()).toList()));
  }

  static Future<void> toggleFavorite(MediaItem item) async {
    final list = List<Map<String, dynamic>>.from(_favoritesCache);
    final idx = list.indexWhere((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    if (idx >= 0) {
      list.removeAt(idx);
    } else {
      list.add(<String, dynamic>{
        'id': item.id,
        'sourceId': item.sourceId,
        'type': item.type,
        'name': item.name,
        'poster': item.poster,
        'title': item.title,
        'url': item.url,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    _favoritesCache = list;
    await _prefs?.setString('favorites', jsonEncode(list));
  }

  static bool isFavorite(MediaItem item) {
    return _favoritesCache.any((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
  }

  static Future<void> clearFavorites() async {
    _favoritesCache = <Map<String, dynamic>>[];
    await _prefs?.remove('favorites');
  }

  static Future<void> addHistoryItem(MediaItem item) async {
    final list = List<Map<String, dynamic>>.from(_historyCache);
    list.removeWhere((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    list.insert(0, <String, dynamic>{
      'id': item.id,
      'sourceId': item.sourceId,
      'type': item.type,
      'name': item.name,
      'poster': item.poster,
      'title': item.title,
      'url': item.url,
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (list.length > 200) {
      list.removeRange(200, list.length);
    }
    _historyCache = list;
    await _prefs?.setString('history', jsonEncode(list));
  }

  static Future<void> removeHistoryItem(MediaItem item) async {
    final list = List<Map<String, dynamic>>.from(_historyCache);
    list.removeWhere((e) => e['id'] == item.id && e['sourceId'] == item.sourceId);
    _historyCache = list;
    await _prefs?.setString('history', jsonEncode(list));
  }

  static Future<void> clearHistory() async {
    _historyCache = <Map<String, dynamic>>[];
    await _prefs?.remove('history');
  }

  static Future<void> setFavorites(List<Map<String, dynamic>> items) async {
    _favoritesCache = items;
    await _prefs?.setString('favorites', jsonEncode(items));
  }

  static Future<void> setHistory(List<Map<String, dynamic>> items) async {
    _historyCache = items;
    await _prefs?.setString('history', jsonEncode(items));
  }

  static List<SourceDefinition> _parseSources(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List<dynamic>;
      return list.map((e) => SourceDefinition.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return <SourceDefinition>[];
    }
  }

  static List<Map<String, dynamic>> _parseJsonList(String jsonStr) {
    try {
      return (jsonDecode(jsonStr) as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }
}
