import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin.dart';

class PluginService {
  static const _key = 'source_plugins';

  static Future<List<SourcePlugin>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [_defaultPlugin];
    try {
      return (jsonDecode(raw) as List).map((item) => SourcePlugin.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (_) {
      return [_defaultPlugin];
    }
  }

  static Future<void> save(SourcePlugin plugin) async {
    final values = await list();
    final result = [...values.where((item) => item.id != plugin.id), plugin];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(result.map((item) => item.toMap()).toList()));
  }

  static Future<void> delete(String id) async {
    final values = await list();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(values.where((item) => item.id != id).map((item) => item.toMap()).toList()));
  }

  static Future<String> downloadCode(String url) async {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('HTTP ${response.statusCode}');
    return response.body;
  }

  static SourcePlugin get _defaultPlugin => SourcePlugin(
    id: 'example-json',
    name: 'JSON 视频源示例',
    description: 'Miru 风格本地扩展示例，返回统一 JSON。',
    language: PluginLanguage.javascript,
    code: '''// 宏曦聚合插件协议
// search(keyword, page) 返回 {"list": [{"id":"", "title":"", "cover":""}]}
async function search(keyword, page) {
  return JSON.stringify({ list: [] });
}
''',
  );
}
