/// 插件系统 — 统一 Spider 接口
/// 所有语言的插件都必须实现此接口
library;

/// 源插件的统一协议
/// JS/Python/PHP/Go/Java 插件通过此协议与主程序交互
abstract class SpiderInterface {
  /// 插件唯一标识
  String get id;

  /// 插件名称
  String get name;

  /// 插件版本
  String get version;

  /// 插件语言
  PluginLanguage get language;

  /// 插件描述
  String get description;

  /// 插件作者
  String get author;

  /// 插件源码
  String get sourceCode;

  /// 设置源码 (用于编辑器保存)
  set sourceCode(String code);

  // ════════════════════════════════════════
  //  必须实现的核心方法
  // ════════════════════════════════════════

  /// 搜索内容
  /// 返回 JSON: { "list": [ { "id":"", "title":"", "cover":"", "desc":"", "category":"", "tags":[] } ] }
  Future<String> search(String keyword, {int page = 1});

  /// 获取详情
  /// 返回 JSON: { "id":"", "title":"", "cover":"", "desc":"", "episodes": [ {"name":"", "url":""} ] }
  Future<String> detail(String url);

  /// 获取分类列表
  /// 返回 JSON: { "list": [ ... ], "categories": [ {"id":"", "name":""} ] }
  Future<String> category({String? categoryId, int page = 1});

  /// 获取播放/阅读地址 (解析真实地址)
  /// 返回 JSON: { "url":"", "headers":{} }
  Future<String> playerUrl(String url, {Map<String, String>? headers});

  /// 获取直播源列表
  /// 返回 JSON: { "channels": [ {"name":"", "url":"", "group":""} ] }
  Future<String> liveList(String url);

  /// 测试插件是否可用
  Future<bool> test();

  /// 销毁资源
  void dispose();
}

/// 插件支持的语言
enum PluginLanguage {
  javascript('JavaScript', 'js', 'ECMAScript 引擎执行', '⚡'),
  python('Python', 'py', 'Python 运行时', '🐍'),
  php('PHP', 'php', 'PHP 解释器', '🐘'),
  go('Go', 'go', 'Go WASM 运行时', '🔷'),
  java('Java', 'java', 'JVM / Dalvik', '☕');

  final String label;
  final String ext;
  final String desc;
  final String icon;
  const PluginLanguage(this.label, this.ext, this.desc, this.icon);

  static PluginLanguage fromExt(String ext) {
    return PluginLanguage.values.firstWhere(
      (l) => l.ext == ext.toLowerCase().replaceFirst('.', ''),
      orElse: () => PluginLanguage.javascript,
    );
  }
}

/// 插件运行状态
enum PluginStatus {
  idle('待运行'),
  running('运行中'),
  success('成功'),
  error('错误'),
  timeout('超时');

  final String label;
  const PluginStatus(this.label);
}

/// 引擎执行结果
class EngineResult {
  final bool success;
  final String? data;
  final String? error;
  final Duration executionTime;
  final List<ConsoleLog> logs;

  EngineResult({
    required this.success,
    this.data,
    this.error,
    Duration? executionTime,
    this.logs = const [],
  }) : executionTime = executionTime ?? Duration.zero;

  factory EngineResult.ok(String data, {Duration? time, List<ConsoleLog>? logs}) =>
    EngineResult(success: true, data: data, executionTime: time, logs: logs ?? []);

  factory EngineResult.fail(String error, {Duration? time, List<ConsoleLog>? logs}) =>
    EngineResult(success: false, error: error, executionTime: time, logs: logs ?? []);

  @override
  String toString() => success ? 'OK: $data' : 'ERROR: $error';
}

/// 控制台日志
class ConsoleLog {
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  ConsoleLog(this.level, this.message) : timestamp = DateTime.now();

  @override
  String toString() => '[${level.name.toUpperCase()}] $message';
}

enum LogLevel { debug, info, warn, error }
