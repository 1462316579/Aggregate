/// Go 引擎 — 基于 WASM
/// 方案: 将 Go 代码编译为 WASM，通过 flutter_js 执行
import 'dart:async';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import '../plugin/spider_interface.dart';
import '../plugin/spider_plugin.dart';

class GoEngine {
  JavascriptRuntime? _runtime;
  bool _isInitialized = false;

  Future<void> init() async {
    _runtime = getJavascriptRuntime();
    // 注入 Go WASM 运行时胶水代码 (go_wasm_exec.js)
    // 这需要预先编译好的 Go WASM 运行时
    _isInitialized = true;
  }

  /// 执行 Go 代码 (转译为 JS 后执行)
  Future<EngineResult> call(
    SpiderPlugin plugin,
    String method,
    List<dynamic> args,
  ) async {
    final sw = Stopwatch()..start();

    try {
      // Go → JS 转译
      final jsCode = _goToJs(plugin.sourceCode);
      if (jsCode == null) {
        sw.stop();
        return EngineResult.fail(
          'Go 代码需要先编译为 WASM 模块。\n'
          '请将代码转换为 JavaScript 版本使用。',
          time: sw.elapsed,
        );
      }

      if (_runtime == null) await init();
      _runtime!.evaluate(jsCode);

      final argsStr = args.map((a) => "'${a.toString().replaceAll("'", "\\'")}'").join(', ');
      final result = await _runtime!.evaluateAsync(
        '${method}(${argsStr})',
      );

      sw.stop();
      return EngineResult.ok(result.stringResult, time: sw.elapsed);
    } catch (e) {
      sw.stop();
      return EngineResult.fail(e.toString(), time: sw.elapsed);
    }
  }

  /// Go → JS 基础转换
  String? _goToJs(String goCode) {
    // Go 语法较复杂，仅支持简单的函数式 Go 代码转换
    // 复杂 Go 代码需要真正的 WASM 编译
    String js = goCode;

    // 移除 package 声明和 import
    js = js.replaceAll(RegExp(r'package\s+\w+\s*'), '');
    js = js.replaceAll(RegExp(r'import\s*\(.*?\)', dotAll: true), '');
    js = js.replaceAll(RegExp(r'import\s+"[^"]*"'), '');

    // 函数声明: func name(args) type { → async function name(args) {
    js = js.replaceAllMapped(
      RegExp(r'func\s+(\w+)\s*\(([^)]*)\)\s*(?:\w+\s*)?\{'),
      (m) => 'async function ${m.group(1)}(${m.group(2)}) {',
    );

    // 变量声明
    js = js.replaceAllMapped(
      RegExp(r':=\s*'),
      (m) => '= ',
    );

    // fmt.Println → log
    js = js.replaceAllMapped(
      RegExp(r'fmt\.Println\((.+)\)'),
      (m) => 'log(${m.group(1)})',
    );

    // fmt.Sprintf → 模板字符串
    js = js.replaceAllMapped(
      RegExp(r'fmt\.Sprintf\("([^"]*)",\s*(.+)\)'),
      (m) => '`${m.group(1)}`',
    );

    // 空值
    js = js.replaceAll('nil', 'null');
    js = js.replaceAll('true', 'true');
    js = js.replaceAll('false', 'false');

    return js;
  }

  void dispose() {
    _runtime?.dispose();
    _runtime = null;
  }
}
