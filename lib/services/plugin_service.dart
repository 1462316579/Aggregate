import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin.dart';

class PluginService {
  static const _key = 'source_plugins';

  static Future<List<SourcePlugin>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [_defaultPlugin];
    try {
      return (jsonDecode(raw) as List).map((e) => SourcePlugin.fromMap(Map<String, dynamic>.from(e))).toList();
    } catch (_) { return [_defaultPlugin]; }
  }

  static Future<void> save(SourcePlugin plugin) async {
    final prefs = await SharedPreferences.getInstance();
    final values = await list();
    final result = [...values.where((e) => e.id != plugin.id), plugin];
    await prefs.setString(_key, jsonEncode(result.map((e) => e.toMap()).toList()));
  }

  static Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final values = await list();
    await prefs.setString(_key, jsonEncode(values.where((e) => e.id != id).map((e) => e.toMap()).toList()));
  }

  static SourcePlugin get _defaultPlugin => SourcePlugin(
    id: 'example-json',
    name: 'JSON 视频源示例',
    description: '在插件页编辑 JS/Python/PHP/Go/Java 源代码。',
    language: PluginLanguage.javascript,
    code: '''// 宏曦聚合源插件示例
// 插件统一返回 JSON: {"list":[...]}
async function search(keyword, page) {
  return JSON.stringify({ list: [] });
}
''',
  );
}
