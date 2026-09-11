import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_source.dart';

class AppConfig {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyTmdbKey = 'tmdb_key';
  static const String _keyAutoCheckUpdate = 'auto_check_update';
  static const String _keyNsfw = 'nsfw';
  static const String _keyWebdavEnabled = 'webdav_enabled';
  static const String _keyWebdavHost = 'webdav_host';
  static const String _keyWebdavUsername = 'webdav_username';
  static const String _keyWebdavPassword = 'webdav_password';
  static const String _keyWebdavPath = 'webdav_path';
  static const String _keyAiConfigName = 'ai_config_name';
  static const String _keyAiApiUrl = 'ai_api_url';
  static const String _keyAiApiKey = 'ai_api_key';
  static const String _keyAiModel = 'ai_model';
  static const String _keyPluginRepositoryUrl = 'plugin_repository_url';
  static const String _keyFavorites = 'favorites';
  static const String _keySearchHistory = 'search_history';
  static const String _keyHistory = 'history';
  static const String _keyConfigUrl = 'config_url';

  // 缓存
  static int? _cachedThemeMode;
  static String? _cachedLanguage;
  static String? _cachedTmdbKey;
  static bool? _cachedAutoCheckUpdate;
  static bool? _cachedNsfw;
  static bool? _cachedWebdavEnabled;
  static String? _cachedWebdavHost;
  static String? _cachedWebdavUsername;
  static String? _cachedWebdavPassword;
  static String? _cachedWebdavPath;
  static String? _cachedAiConfigName;
  static String? _cachedAiApiUrl;
  static String? _cachedAiApiKey;
  static String? _cachedAiModel;
  static String? _cachedPluginRepositoryUrl;
  static String? _cachedConfigUrl;

  // Notifiers for reactive UI
  static final ValueNotifier<int> themeNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('zh');

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedThemeMode = prefs.getInt(_keyThemeMode) ?? 0;
    _cachedLanguage = prefs.getString(_keyLanguage) ?? 'zh';
    _cachedTmdbKey = prefs.getString(_keyTmdbKey);
    _cachedAutoCheckUpdate = prefs.getBool(_keyAutoCheckUpdate) ?? true;
    _cachedNsfw = prefs.getBool(_keyNsfw) ?? false;
    _cachedWebdavEnabled = prefs.getBool(_keyWebdavEnabled) ?? false;
    _cachedWebdavHost = prefs.getString(_keyWebdavHost) ?? '';
    _cachedWebdavUsername = prefs.getString(_keyWebdavUsername) ?? '';
    _cachedWebdavPassword = prefs.getString(_keyWebdavPassword) ?? '';
    _cachedWebdavPath = prefs.getString(_keyWebdavPath) ?? '/';
    _cachedAiConfigName = prefs.getString(_keyAiConfigName) ?? '';
    _cachedAiApiUrl = prefs.getString(_keyAiApiUrl) ?? '';
    _cachedAiApiKey = prefs.getString(_keyAiApiKey) ?? '';
    _cachedAiModel = prefs.getString(_keyAiModel) ?? 'gpt-3.5-turbo';
    _cachedPluginRepositoryUrl = prefs.getString(_keyPluginRepositoryUrl) ?? '';
    _cachedConfigUrl = prefs.getString(_keyConfigUrl);

    // 初始化 notifiers
    themeNotifier.value = _cachedThemeMode!;
    languageNotifier.value = _cachedLanguage!;
  }

  // 同步 getter（供 UI 直接使用）
  static int get theme => _cachedThemeMode ?? 0;
  static String get language => _cachedLanguage ?? 'zh';
  static String? get tmdbKey => _cachedTmdbKey;
  static bool get autoCheckUpdate => _cachedAutoCheckUpdate ?? true;
  static bool get nsfw => _cachedNsfw ?? false;
  static bool get webdavEnabled => _cachedWebdavEnabled ?? false;
  static String get webdavHost => _cachedWebdavHost ?? '';
  static String get webdavUsername => _cachedWebdavUsername ?? '';
  static String get webdavPassword => _cachedWebdavPassword ?? '';
  static String get webdavPath => _cachedWebdavPath ?? '/';
  static String get aiConfigName => _cachedAiConfigName ?? '';
  static String get aiApiUrl => _cachedAiApiUrl ?? '';
  static String get aiApiKey => _cachedAiApiKey ?? '';
  static String get aiModel => _cachedAiModel ?? 'gpt-3.5-turbo';
  static String get pluginRepositoryUrl => _cachedPluginRepositoryUrl ?? '';

  // 异步 setter（更新缓存 + 持久化 + 通知 notifiers）
  static Future<void> setTheme(int mode) async {
    _cachedThemeMode = mode;
    themeNotifier.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode);
  }

  static Future<void> setLanguage(String code) async {
    _cachedLanguage = code;
    languageNotifier.value = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, code);
  }

  static Future<void> setTmdbKey(String? key) async {
    _cachedTmdbKey = (key != null && key.isNotEmpty) ? key : null;
    final prefs = await SharedPreferences.getInstance();
    if (_cachedTmdbKey != null) {
      await prefs.setString(_keyTmdbKey, _cachedTmdbKey!);
    } else {
      await prefs.remove(_keyTmdbKey);
    }
  }

  static Future<void> setAutoCheckUpdate(bool value) async {
    _cachedAutoCheckUpdate = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoCheckUpdate, value);
  }

  static Future<void> setNsfw(bool value) async {
    _cachedNsfw = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNsfw, value);
  }

  static Future<void> setWebdavEnabled(bool value) async {
    _cachedWebdavEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWebdavEnabled, value);
  }

  static Future<void> setWebdavHost(String value) async {
    _cachedWebdavHost = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebdavHost, value);
  }

  static Future<void> setWebdavUsername(String value) async {
    _cachedWebdavUsername = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebdavUsername, value);
  }

  static Future<void> setWebdavPassword(String value) async {
    _cachedWebdavPassword = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebdavPassword, value);
  }

  static Future<void> setWebdavPath(String value) async {
    _cachedWebdavPath = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyWebdavPath, value);
  }

  static Future<void> setAiConfigName(String value) async {
    _cachedAiConfigName = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiConfigName, value);
  }

  static Future<void> setAiApiUrl(String value) async {
    _cachedAiApiUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiApiUrl, value);
  }

  static Future<void> setAiApiKey(String value) async {
    _cachedAiApiKey = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiApiKey, value);
  }

  static Future<void> setAiModel(String value) async {
    _cachedAiModel = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAiModel, value);
  }

  static Future<void> setPluginRepositoryUrl(String value) async {
    _cachedPluginRepositoryUrl = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPluginRepositoryUrl, value);
  }

  // 配置URL
  static Future<String?> getConfigUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConfigUrl);
  }

  static Future<void> setConfigUrl(String? url) async {
    _cachedConfigUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString(_keyConfigUrl, url);
    } else {
      await prefs.remove(_keyConfigUrl);
    }
  }

  // 收藏夹
  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyFavorites);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = json.decode(jsonString) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveFavorites(List<Map<String, dynamic>> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFavorites, json.encode(favorites));
  }

  // isFavorite 检查是否收藏
  static Future<bool> isFavorite(dynamic item) async {
    final favorites = await getFavorites();
    String? id;
    if (item is Map) {
      id = item['id']?.toString();
    } else {
      try {
        id = item.id;
      } catch (_) {
        return false;
      }
    }
    if (id == null) return false;
    return favorites.any((e) => e['id']?.toString() == id);
  }

  // toggleFavorite 接收 MediaItem 或 Map
  static Future<void> toggleFavorite(dynamic item) async {
    final favorites = await getFavorites();
    String? id;
    Map<String, dynamic> itemMap;
    
    if (item is Map) {
      itemMap = Map<String, dynamic>.from(item);
      id = itemMap['id']?.toString();
    } else {
      // 假设是 MediaItem
      try {
        id = item.id;
        itemMap = {
          'id': item.id,
          'title': item.title,
          'cover': item.cover,
          'type': item.type?.name ?? 'video',
          'sourceId': item.sourceId,
          'sourceName': item.sourceName,
        };
      } catch (_) {
        return;
      }
    }
    
    if (id == null) return;
    final index = favorites.indexWhere((e) => e['id']?.toString() == id);
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.insert(0, itemMap);
    }
    await saveFavorites(favorites);
  }

  static Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFavorites);
  }

  // 播放历史
  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyHistory);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = json.decode(jsonString) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyHistory, json.encode(history));
  }

  static Future<void> addHistory(Map<String, dynamic> item) async {
    final history = await getHistory();
    String? id = item['id']?.toString();
    if (id != null) {
      history.removeWhere((e) => e['id']?.toString() == id);
    }
    history.insert(0, item);
    if (history.length > 100) history = history.sublist(0, 100);
    await saveHistory(history);
  }

  // 搜索历史
  static Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keySearchHistory);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = json.decode(jsonString) as List;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    var history = await getSearchHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > 50) history = history.sublist(0, 50);
    await prefs.setString(_keySearchHistory, json.encode(history));
  }

  static Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  static Future<void> clearHistory() async {
    await clearSearchHistory();
  }

  // 视频源
  static Future<List<VideoSource>> getSources() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('sources');
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = json.decode(jsonString) as List;
      return list.map((e) => VideoSource.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSources(List<VideoSource> sources) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sources', json.encode(sources.map((e) => e.toJson()).toList()));
  }

  static Future<String?> getActiveSourceKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_source_key');
  }

  static Future<void> saveActiveSourceKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_source_key', key);
  }

  // setActiveSource 设置活动源
  static Future<void> setActiveSource(String key) async {
    await saveActiveSourceKey(key);
  }
}
