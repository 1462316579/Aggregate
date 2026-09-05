/// 配置管理
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_source.dart';

class AppConfig {
  static SharedPreferences? _prefs;

  static const _defaultSources = [
    VideoSource(key: 'heimuer', name: '黑木耳', api: 'https://json.heimuer.xyz/api.php/provide/vod/', type: 2),
    VideoSource(key: 'ikun', name: 'ikun资源', api: 'https://ikunzyapi.com/api.php/provide/vod/', type: 2),
    VideoSource(key: 'ffzy', name: '非凡资源', api: 'https://cj.ffzyapi.com/api.php/provide/vod/', type: 2),
    VideoSource(key: 'hongniu', name: '红牛资源', api: 'https://www.hongniuzy2.com/api.php/provide/vod/', type: 2),
  ];

  static Future<void> init() async { _prefs = await SharedPreferences.getInstance(); }

  static Future<List<VideoSource>> getSources() async {
    final s = _prefs?.getString('sources');
    if (s != null) return (jsonDecode(s) as List).map((e) => VideoSource.fromJson(e)).toList();
    await saveSources(_defaultSources);
    return _defaultSources;
  }

  static Future<void> saveSources(List<VideoSource> sources) async {
    await _prefs?.setString('sources', jsonEncode(sources.map((s) => s.toJson()).toList()));
  }

  static Future<String?> getActiveSourceKey() async => _prefs?.getString('activeSource');
  static Future<void> setActiveSource(String key) async => await _prefs?.setString('activeSource', key);

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final s = _prefs?.getString('history');
    return s != null ? List<Map<String, dynamic>>.from(jsonDecode(s)) : [];
  }

  static Future<void> addHistory(Map<String, dynamic> item) async {
    final h = await getHistory();
    h.removeWhere((e) => e['id'] == item['id']);
    h.insert(0, item);
    if (h.length > 100) h.removeRange(100, h.length);
    await _prefs?.setString('history', jsonEncode(h));
  }

  static Future<List<Map<String, dynamic>>> getFavorites() async {
    final s = _prefs?.getString('favorites');
    return s != null ? List<Map<String, dynamic>>.from(jsonDecode(s)) : [];
  }

  static Future<void> addFavorite(Map<String, dynamic> item) async {
    final f = await getFavorites();
    f.removeWhere((e) => e['id'] == item['id']);
    f.insert(0, item);
    await _prefs?.setString('favorites', jsonEncode(f));
  }

  static Future<void> removeFavorite(String id) async {
    final f = await getFavorites();
    f.removeWhere((e) => e['id'] == id);
    await _prefs?.setString('favorites', jsonEncode(f));
  }

  static Future<bool> isFavorite(String id) async {
    final f = await getFavorites();
    return f.any((e) => e['id'] == id);
  }

  static Future<List<String>> getSearchHistory() async {
    final s = _prefs?.getString('searchHistory');
    return s != null ? List<String>.from(jsonDecode(s)) : [];
  }

  static Future<void> saveSearchHistory(String query) async {
    final h = await getSearchHistory();
    h.remove(query);
    h.insert(0, query);
    if (h.length > 20) h.removeRange(20, h.length);
    await _prefs?.setString('searchHistory', jsonEncode(h));
  }
}
