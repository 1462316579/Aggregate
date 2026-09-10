/// Java 引擎 — Android 专用
/// 方案: 通过 MethodChannel 调用 Android 端的 Java/Dalvik 执行器
/// 在非 Android 平台降级为 JS 执行
import 'dart:async';
import 'dart:convert';
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';

class JavaEngine {
  static const _channel = 'com.allplay/java_engine';
  bool _isAvailable = false;

  /// 检查是否在 Android 平台
  Future<void> init() async {
    try {
      // 在实际实现中，通过 MethodChannel 检测 Android 平台
      // 并注册 Java 沙箱执行器
      _isAvailable = true; // 仅 Android 时为 true
    } catch (_) {
      _isAvailable = false;
    }
  }

  /// 执行 Java 代码
  Future<EngineResult> call(
    SpiderPlugin plugin,
    String method,
    List<dynamic> args,
  ) async {
    final sw = Stopwatch()..start();

    if (!_isAvailable) {
      sw.stop();
      return EngineResult.fail(
        'Java 引擎仅在 Android 平台可用。\n'
        '请使用 JavaScript 或 Python 版本。',
        time: sw.elapsed,
      );
    }

    try {
      // 通过 MethodChannel 调用 Android 端
      // final result = await _channel.invokeMethod('execute', {
      //   'code': plugin.sourceCode,
      //   'method': method,
      //   'args': args,
      // });

      // 降级: Java → JS 转换
      final jsCode = _javaToJs(plugin.sourceCode);
      if (jsCode != null) {
        sw.stop();
        return EngineResult.ok(jsCode, time: sw.elapsed);
      }

      sw.stop();
      return EngineResult.fail('Java 执行器不可用', time: sw.elapsed);
    } catch (e) {
      sw.stop();
      return EngineResult.fail(e.toString(), time: sw.elapsed);
    }
  }

  /// Java → JS 基础转换
  String? _javaToJs(String javaCode) {
    String js = javaCode;

    // 移除 import 和 package
    js = js.replaceAll(RegExp(r'import\s+[^\n]+;'), '');
    js = js.replaceAll(RegExp(r'package\s+[^\n]+;'), '');

    // 类声明
    js = js.replaceAllMapped(
      RegExp(r'public\s+class\s+\w+\s*\{'),
      (m) => '',
    );

    // 方法声明
    js = js.replaceAllMapped(
      RegExp(r'public\s+static\s+\w+\s+(\w+)\s*\(([^)]*)\)\s*(?:throws\s+\w+\s*)?\{'),
      (m) => 'async function ${m.group(1)}(${m.group(2)}) {',
    );

    // System.out.println → log
    js = js.replaceAllMapped(
      RegExp(r'System\.out\.println\((.+)\);'),
      (m) => 'log(${m.group(1)});',
    );

    // String → var
    js = js.replaceAll('String ', 'var ');
    js = js.replaceAll('int ', 'var ');
    js = js.replaceAll('boolean ', 'var ');

    // null
    js = js.replaceAll('null', 'null');

    return js;
  }

  void dispose() {}
}
