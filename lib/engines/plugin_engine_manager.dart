/// 引擎管理器 — 统一调度各语言引擎
import 'dart:async';
import 'dart:convert';
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';
import 'javascript_engine.dart';
import 'python_engine.dart';
import 'php_engine.dart';
import 'go_engine.dart';
import 'java_engine.dart';

class PluginEngineManager {
  JavaScriptEngine? _jsEngine;
  PythonEngine? _pyEngine;
  PhpEngine? _phpEngine;
  GoEngine? _goEngine;
  JavaEngine? _javaEngine;

  bool _initialized = false;

  /// 初始化所有引擎
  Future<void> init() async {
    if (_initialized) return;

    _jsEngine = JavaScriptEngine();
    await _jsEngine!.init();

    _pyEngine = PythonEngine();
    _phpEngine = PhpEngine();
    _goEngine = GoEngine();
    _javaEngine = JavaEngine();
    await _javaEngine!.init();

    _initialized = true;
  }

  /// 执行插件方法 (自动选择引擎)
  Future<EngineResult> call(
    SpiderPlugin plugin,
    String method,
    List<dynamic> args,
  ) async {
    if (!_initialized) await init();

    switch (plugin.language) {
      case PluginLanguage.javascript:
        return _jsEngine!.call(plugin, method, args);
      case PluginLanguage.python:
        return _pyEngine!.call(plugin, method, args);
      case PluginLanguage.php:
        return _phpEngine!.call(plugin, method, args);
      case PluginLanguage.go:
        return _goEngine!.call(plugin, method, args);
      case PluginLanguage.java:
        return _javaEngine!.call(plugin, method, args);
    }
  }

  /// 快捷方法: 搜索
  Future<EngineResult> search(SpiderPlugin plugin, String keyword, {int page = 1}) {
    return call(plugin, 'search', [keyword, page]);
  }

  /// 快捷方法: 详情
  Future<EngineResult> detail(SpiderPlugin plugin, String url) {
    return call(plugin, 'detail', [url]);
  }

  /// 快捷方法: 分类
  Future<EngineResult> category(SpiderPlugin plugin, {String? categoryId, int page = 1}) {
    return call(plugin, 'category', [categoryId, page]);
  }

  /// 快捷方法: 播放解析
  Future<EngineResult> playerUrl(SpiderPlugin plugin, String url) {
    return call(plugin, 'playerUrl', [url]);
  }

  /// 快捷方法: 直播
  Future<EngineResult> liveList(SpiderPlugin plugin, String url) {
    return call(plugin, 'liveList', [url]);
  }

  /// 快捷方法: 测试
  Future<EngineResult> test(SpiderPlugin plugin) {
    return call(plugin, 'test', []);
  }

  /// 在 WebView 中执行 PHP (通过 php-wasm)
  Future<String?> executePhpInWebView(String code, String method) async {
    // 这个方法会在 WebView 中执行 PHP WASM
    // 返回执行结果
    return null;
  }

  /// 保存插件到本地存储
  Future<void> savePlugin(SpiderPlugin plugin) async {
    final plugins = await getPlugins();
    plugins.removeWhere((p) => p.id == plugin.id);
    plugins.add(plugin);
    await _savePlugins(plugins);
  }

  /// 获取所有插件
  Future<List<SpiderPlugin>> getPlugins() async {
    // 从 SharedPreferences 或文件系统读取
    return [];
  }

  /// 删除插件
  Future<void> deletePlugin(String id) async {
    final plugins = await getPlugins();
    plugins.removeWhere((p) => p.id == id);
    await _savePlugins(plugins);
  }

  Future<void> _savePlugins(List<SpiderPlugin> plugins) async {
    // 保存到 SharedPreferences 或文件系统
  }

  /// 获取引擎状态
  Map<String, bool> getEngineStatus() {
    return {
      'JavaScript': _jsEngine != null,
      'Python': _pyEngine?.isRunning ?? false,
      'PHP': _phpEngine?.isRunning ?? false,
      'Go': _goEngine != null,
      'Java': _javaEngine != null,
    };
  }

  void dispose() {
    _jsEngine?.dispose();
    _pyEngine?.dispose();
    _phpEngine?.dispose();
    _goEngine?.dispose();
    _javaEngine?.dispose();
  }
}
