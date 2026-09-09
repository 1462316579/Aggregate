/// 应用配置管理
/// 管理源列表、用户偏好、主题设置等
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_source.dart';

class AppConfig {
  static const String _keySources = 'video_sources';
  static const String _keyActiveSource = 'active_source';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyConfigUrl = 'config_url';
  static const String _keyHistory = 'watch_history';
  static const String _keyFavorites = 'favorites';
  static const String _keySearchHistory = 'search_history';

  static const String defaultConfigUrl =
      'https://raw.githubusercontent.com/liu673cn/box/main/m.json';

  /// 默认内置源
  static final List<VideoSource> builtInSources = [
    // ===== 视频源 =====
    VideoSource(key: 'heimuer', name: '黑木耳',
        api: 'https://json.heimuer.xyz/api.php/provide/vod/', type: 2, mediaType: 'video'),
    VideoSource(key: 'ikun', name: 'ikun资源',
        api: 'https://ikunzyapi.com/api.php/provide/vod/', type: 2, mediaType: 'video'),
    VideoSource(key: 'ffzy', name: '非凡资源',
        api: 'https://cj.ffzyapi.com/api.php/provide/vod/', type: 2, mediaType: 'video'),
    VideoSource(key: 'hongniu', name: '红牛资源',
        api: 'https://www.hongniuzy2.com/api.php/provide/vod/', type: 2, mediaType: 'video'),
    VideoSource(key: 'bfzy', name: '暴风资源',
        api: 'https://bfzyapi.com/api.php/provide/vod/', type: 2, mediaType: 'video'),
    // ===== 漫画源 (示例) =====
    VideoSource(key: 'copymanga', name: '拷贝漫画',
        api: 'https://api.copymanga.site/api/v3', type: 2, mediaType: 'comic'),
    // ===== 小说源 (示例) =====
    VideoSource(key: 'bqg', name: '笔趣阁',
        api: 'https://www.xbiquge.la', type: 2, mediaType: 'novel'),
    // ===== 音乐源 (示例) =====
    VideoSource(key: 'netease', name: '网易云音乐',
        api: 'https://netease-cloud-music-api.vercel.app', type: 2, mediaType: 'music'),
  ];

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ============ 源管理 ============

  static Future<List<VideoSource>> getSources() async {
    final stored = _prefs?.getString(_keySources);
    if (stored != null) {
      final list = jsonDecode(stored) as List;
      return list.map((item) => VideoSource.fromJson(item)).toList();
    }
    // 首次启动返回内置源
    await saveSources(builtInSources);
    return builtInSources;
  }

  static Future<void> saveSources(List<VideoSource> sources) async {
    final json = sources.map((s) => s.toJson()).toList();
    await _prefs?.setString(_keySources, jsonEncode(json));
  }

  static Future<void> addSource(VideoSource source) async {
    final sources = await getSources();
    sources.add(source);
    await saveSources(sources);
  }

  static Future<void> removeSource(String key) async {
    final sources = await getSources();
    sources.removeWhere((s) => s.key == key);
    await saveSources(sources);
  }

  static Future<String?> getActiveSourceKey() async {
    return _prefs?.getString(_keyActiveSource);
  }

  static Future<void> setActiveSource(String key) async {
    await _prefs?.setString(_keyActiveSource, key);
  }

  // ============ 在线配置 ============

  static Future<String> getConfigUrl() async {
    return _prefs?.getString(_keyConfigUrl) ?? defaultConfigUrl;
  }

  static Future<void> setConfigUrl(String url) async {
    await _prefs?.setString(_keyConfigUrl, url);
  }

  // ============ 主题 ============

  static Future<int> getThemeMode() async {
    return _prefs?.getInt(_keyThemeMode) ?? 0; // 0=跟随系统, 1=亮色, 2=暗色
  }

  static Future<void> setThemeMode(int mode) async {
    await _prefs?.setInt(_keyThemeMode, mode);
  }

  // ============ 历史记录 ============

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final stored = _prefs?.getString(_keyHistory);
    if (stored != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(stored));
    }
    return [];
  }

  static Future<void> addHistory(Map<String, dynamic> item) async {
    final history = await getHistory();
    // 去重 (按 id 和 sourceKey)
    history.removeWhere((h) =>
        h['id'] == item['id'] && h['sourceKey'] == item['sourceKey']);
    history.insert(0, item);
    // 最多保留 200 条
    if (history.length > 200) history.removeRange(200, history.length);
    await _prefs?.setString(_keyHistory, jsonEncode(history));
  }

  static Future<void> removeHistory(String id, String sourceKey) async {
    final history = await getHistory();
    history.removeWhere((h) =>
        h['id'] == id && h['sourceKey'] == sourceKey);
    await _prefs?.setString(_keyHistory, jsonEncode(history));
  }

  static Future<void> clearHistory() async {
    await _prefs?.remove(_keyHistory);
  }

  // ============ 收藏 ============

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final stored = _prefs?.getString(_keyFavorites);
    if (stored != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(stored));
    }
    return [];
  }

  static Future<void> addFavorite(Map<String, dynamic> item) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) =>
        f['id'] == item['id'] && f['sourceKey'] == item['sourceKey']);
    favorites.insert(0, item);
    await _prefs?.setString(_keyFavorites, jsonEncode(favorites));
  }

  static Future<void> removeFavorite(String id, String sourceKey) async {
    final favorites = await getFavorites();
    favorites.removeWhere((f) =>
        f['id'] == id && f['sourceKey'] == sourceKey);
    await _prefs?.setString(_keyFavorites, jsonEncode(favorites));
  }

  static Future<bool> isFavorite(String id, String sourceKey) async {
    final favorites = await getFavorites();
    return favorites.any((f) =>
        f['id'] == id && f['sourceKey'] == sourceKey);
  }

  // ============ 搜索历史 ============

  static Future<List<String>> getSearchHistory() async {
    final stored = _prefs?.getString(_keySearchHistory);
    if (stored != null) return List<String>.from(jsonDecode(stored));
    return [];
  }

  static Future<void> saveSearchHistory(String query) async {
    final history = await getSearchHistory();
    history.remove(query);
    history.insert(0, query);
    if (history.length > 30) history.removeRange(30, history.length);
    await _prefs?.setString(_keySearchHistory, jsonEncode(history));
  }

  static Future<void> clearSearchHistory() async {
    await _prefs?.remove(_keySearchHistory);
  }

  // ============ 备份/恢复辅助 ============

  static Future<void> saveHistory(List<Map<String, dynamic>> history) async {
    await _prefs?.setString(_keyHistory, jsonEncode(history));
  }

  static Future<void> saveFavorites(List<Map<String, dynamic>> favorites) async {
    await _prefs?.setString(_keyFavorites, jsonEncode(favorites));
  }
}
