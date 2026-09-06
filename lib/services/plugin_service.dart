import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plugin.dart';

class PluginService {
  static const _key = 'source_plugins';
  static const _repoKey = 'plugin_repositories';

  static Future<List<String>> repositories() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_repoKey) ?? <String>[];
  }

  static Future<void> saveRepositories(List<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_repoKey, values);
  }

  static Future<void> addRepository(String url) async {
    final values = await repositories();
    if (!values.contains(url)) values.add(url);
    await saveRepositories(values);
  }

  static Future<void> removeRepository(String url) async {
    final values = await repositories();
    values.remove(url);
    await saveRepositories(values);
  }

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

  /// 仓库可返回插件数组，或 {plugins:[...] }。
  static Future<List<SourcePlugin>> loadRepository(String url) async {
    final body = await downloadCode(url);
    final decoded = jsonDecode(body);
    final raw = decoded is List ? decoded : (decoded is Map ? decoded['plugins'] : null);
    if (raw is! List) return <SourcePlugin>[];
    return raw.whereType<Map>().map((e) => SourcePlugin.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> installFromRepository(String url) async {
    final plugins = await loadRepository(url);
    for (final plugin in plugins) {
      await save(plugin);
    }
  }

  static Future<String> runTest(SourcePlugin plugin) async {
    if (plugin.code.trim().isEmpty) return '代码为空';
    if (plugin.language != PluginLanguage.javascript) {
      return '${plugin.language.name} 插件已保存；当前内置调试器支持 JavaScript，其他语言需对应运行时。';
    }
    if (!plugin.code.contains('function search')) return '未找到 search 函数';
    return '插件结构检查通过';
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
