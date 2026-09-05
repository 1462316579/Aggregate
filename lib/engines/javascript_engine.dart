/// JavaScript 引擎 — 基于 flutter_js
/// 沙箱执行 JS 插件代码，注入 HTTP/HTML/JSON 等 API
import 'dart:async';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';

class JavaScriptEngine {
  JavascriptRuntime? _runtime;
  final List<ConsoleLog> _logs = [];

  List<ConsoleLog> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    _runtime = getJavascriptRuntime();
    _injectApi();
  }

  void _injectApi() {
    if (_runtime == null) return;

    // 注入 console.log
    _runtime!.evaluate('''
      var console = {
        log: function(msg) { _log("info", msg); },
        warn: function(msg) { _log("warn", msg); },
        error: function(msg) { _log("error", msg); },
        debug: function(msg) { _log("debug", msg); }
      };
      var log = function(msg) { _log("info", msg); };
    ''');

    // 注入 HTTP API (通过回调)
    _runtime!.evaluate('''
      var http = {
        get: async function(url, headers) {
          return await _httpGet(url, JSON.stringify(headers || {}));
        },
        post: async function(url, data, headers) {
          return await _httpPost(url, typeof data === 'string' ? data : JSON.stringify(data), JSON.stringify(headers || {}));
        }
      };
    ''');

    // 注入 sleep
    _runtime!.evaluate('''
      function sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
      }
    ''');
  }

  /// 执行插件方法
  Future<EngineResult> call(
    SpiderPlugin plugin,
    String method,
    List<dynamic> args,
  ) async {
    _logs.clear();
    final sw = Stopwatch()..start();

    try {
      if (_runtime == null) await init();

      // 加载插件源码
      _runtime!.evaluate(plugin.sourceCode);

      // 构建调用代码
      final argsStr = args.map((a) {
        if (a is String) return "'${a.replaceAll("'", "\\'")}'";
        if (a is Map) return jsonEncode(a);
        return a.toString();
      }).join(', ');

      final jsCode = '''
        (async function() {
          try {
            var result = await ${method}(${argsStr});
            return result;
          } catch(e) {
            return JSON.stringify({ __error: e.message || e.toString() });
          }
        })()
      ''';

      final result = await _runtime!.evaluateAsync(jsCode);

      sw.stop();

      if (result.stringResult.startsWith('{') && result.stringResult.contains('__error')) {
        final err = jsonDecode(result.stringResult)['__error'];
        return EngineResult.fail(err, time: sw.elapsed, logs: _logs);
      }

      return EngineResult.ok(result.stringResult, time: sw.elapsed, logs: _logs);
    } catch (e) {
      sw.stop();
      return EngineResult.fail(e.toString(), time: sw.elapsed, logs: _logs);
    }
  }

  /// 执行测试
  Future<EngineResult> test(SpiderPlugin plugin) async {
    return call(plugin, 'test', []);
  }

  void dispose() {
    _runtime?.dispose();
    _runtime = null;
  }
}
