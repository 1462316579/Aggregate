/// PHP 引擎 — 基于 WASM/HTTP 桥
/// 方案: 嵌入式 PHP 解释器 或 本地 PHP-FPM 服务
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';

class PhpEngine {
  String _runtimeUrl = 'http://127.0.0.1:8766';
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// 启动 PHP 运行时
  Future<void> startRuntime() async {
    // 实际实现: 通过 native code 启动 PHP WASM 或 php-cgi
    // Android: 捆绑 php-wasm.aar
    // iOS: 捆绑 php-wasm.framework
    // Web: 使用 php-wasm npm 包
    _isRunning = true;
  }

  /// 执行 PHP 代码
  Future<EngineResult> call(
    SpiderPlugin plugin,
    String method,
    List<dynamic> args,
  ) async {
    final sw = Stopwatch()..start();

    try {
      if (_isRunning) {
        return await _executeViaRuntime(plugin.sourceCode, method, args, sw);
      }

      // 降级: PHP → JS 转换
      return await _executeFallback(plugin.sourceCode, method, args, sw);
    } catch (e) {
      sw.stop();
      return EngineResult.fail(e.toString(), time: sw.elapsed);
    }
  }

  Future<EngineResult> _executeViaRuntime(
    String code, String method, List<dynamic> args, Stopwatch sw,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$_runtimeUrl/execute'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code, 'method': method, 'args': args}),
      ).timeout(const Duration(seconds: 30));

      sw.stop();

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['error'] != null) {
          return EngineResult.fail(result['error'], time: sw.elapsed);
        }
        return EngineResult.ok(result['data'] ?? '', time: sw.elapsed);
      }
      return EngineResult.fail('PHP 运行时返回 ${response.statusCode}', time: sw.elapsed);
    } catch (e) {
      sw.stop();
      return EngineResult.fail('PHP 运行时未启动: $e', time: sw.elapsed);
    }
  }

  /// 降级方案: PHP → JS 转换
  Future<EngineResult> _executeFallback(
    String code, String method, List<dynamic> args, Stopwatch sw,
  ) async {
    final jsCode = _phpToJs(code);
    sw.stop();
    if (jsCode != null) {
      return EngineResult.ok(jsCode, time: sw.elapsed);
    }
    return EngineResult.fail(
      'PHP 运行时未配置。请在设置中启用 PHP 运行时，\n'
      '或将插件转换为 JavaScript 版本。',
      time: sw.elapsed,
    );
  }

  /// PHP → JS 简单转换
  String? _phpToJs(String phpCode) {
    String js = phpCode;

    // 移除 PHP 标签
    js = js.replaceAll(RegExp(r'<\?php\s*'), '');
    js = js.replaceAll(RegExp(r'\?>'), '');

    // 函数声明
    js = js.replaceAllMapped(
      RegExp(r'function\s+(\w+)\s*\(([^)]*)\)'),
      (m) => 'async function ${m.group(1)}(${m.group(2)})',
    );

    // 变量
    js = js.replaceAllMapped(RegExp(r'\$(\w+)'), (m) => m.group(1)!);

    // 数组
    js = js.replaceAll('array(', '[');
    js = js.replaceAllMapped(
      RegExp(r"'([^']*)'\s*=>"),
      (m) => '"${m.group(1)}":',
    );

    // 字符串连接
    js = js.replaceAll('.\"', '+');
    js = js.replaceAll('."', '+');
    js = js.replaceAll(' . ', ' + ');

    // 空值
    js = js.replaceAll('null', 'null');
    js = js.replaceAll('true', 'true');
    js = js.replaceAll('false', 'false');

    // echo → log
    js = js.replaceAllMapped(
      RegExp(r'echo\s+(.+);'),
      (m) => 'log(${m.group(1)});',
    );

    return js;
  }

  void dispose() {
    _isRunning = false;
  }
}
