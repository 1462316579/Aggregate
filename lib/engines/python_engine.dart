/// Python 引擎 — 通过 HTTP 调用本地/远程 Python 运行时
/// 方案: 内置一个轻量 HTTP 服务作为 Python 执行桥
/// 在 Android/iOS 上通过 Process.run 或 FFI 运行 Python 解释器
/// 备选: 使用 Pyodide (WASM) 在 WebView 中运行
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';

class PythonEngine {
  String _runtimeUrl = 'http://127.0.0.1:8765';
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// 启动 Python 运行时 (HTTP 桥)
  Future<void> startRuntime() async {
    _isRunning = true;
  }

  /// 执行 Python 代码
  Future<EngineResult> execute(String code, String method, List<dynamic> args) async {
    final sw = Stopwatch()..start();

    try {
      if (_isRunning) {
        return await _executeViaRuntime(code, method, args, sw);
      }
      return await _executeFallback(code, method, args, sw);
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
        if (result['error'] != null) return EngineResult.fail(result['error'], time: sw.elapsed);
        return EngineResult.ok(result['data'] ?? '', time: sw.elapsed);
      }
      return EngineResult.fail('Python 运行时返回 ${response.statusCode}', time: sw.elapsed);
    } catch (e) {
      sw.stop();
      return EngineResult.fail('Python 运行时未启动: $e', time: sw.elapsed);
    }
  }

  Future<EngineResult> _executeFallback(
    String code, String method, List<dynamic> args, Stopwatch sw,
  ) async {
    final jsCode = _pythonToJs(code);
    sw.stop();
    if (jsCode != null) return EngineResult.ok(jsCode, time: sw.elapsed);
    return EngineResult.fail(
      'Python 运行时未配置。请在设置中启用 Python 运行时，或将插件转换为 JavaScript 版本。',
      time: sw.elapsed,
    );
  }

  String? _pythonToJs(String pythonCode) {
    String js = pythonCode;
    js = js.replaceAllMapped(RegExp(r'def\s+(\w+)\(([^)]*)\)\s*:'), (m) => 'async function ${m.group(1)}(${m.group(2)}) {');
    js = js.replaceAllMapped(RegExp(r'for\s+(\w+)\s+in\s+(\w+):'), (m) => 'for (var ${m.group(1)} of ${m.group(2)}) {');
    js = js.replaceAllMapped(RegExp(r'if\s+(.+):'), (m) => 'if (${m.group(1)}) {');
    js = js.replaceAll('None', 'null'); js = js.replaceAll('True', 'true'); js = js.replaceAll('False', 'false');
    return js;
  }

  Future<EngineResult> call(SpiderPlugin plugin, String method, List<dynamic> args) async {
    return execute(plugin.sourceCode, method, args);
  }

  void dispose() { _isRunning = false; }
}
