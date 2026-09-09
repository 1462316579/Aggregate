/// 插件代码编辑器 — 内置多语言代码编辑 + 语法高亮 + 运行/调试
/// 支持: JS / Python / PHP / Go / Java
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../plugin/spider_plugin.dart';
import '../../plugin/spider_interface.dart';
import '../../engines/plugin_engine_manager.dart';
import '../plugin_store/plugin_store_screen.dart';

class PluginEditorScreen extends StatefulWidget {
  final SpiderPlugin? plugin; // null = 新建
  const PluginEditorScreen({super.key, this.plugin});

  @override
  State<PluginEditorScreen> createState() => _PluginEditorScreenState();
}

class _PluginEditorScreenState extends State<PluginEditorScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _codeController;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TabController _tabController;

  SpiderPlugin? _currentPlugin;
  PluginLanguage _selectedLanguage = PluginLanguage.javascript;
  bool _isModified = false;
  bool _isRunning = false;
  List<ConsoleLog> _consoleLogs = [];
  String? _testResult;
  int _selectedTab = 0; // 0=编辑器, 1=控制台, 2=设置

  final _engineManager = PluginEngineManager();

  // 语法高亮颜色
  static const _syntaxColors = {
    'keyword': Color(0xFFC792EA),
    'string': Color(0xFFC3E88D),
    'comment': Color(0xFF546E7A),
    'number': Color(0xFFF78C6C),
    'function': Color(0xFF82AAFF),
    'variable': Color(0xFFEEFFFF),
    'operator': Color(0xFF89DDFF),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (widget.plugin != null) {
      _currentPlugin = widget.plugin!;
      _codeController = TextEditingController(text: widget.plugin!.sourceCode);
      _nameController = TextEditingController(text: widget.plugin!.name);
      _descController = TextEditingController(text: widget.plugin!.description);
      _selectedLanguage = widget.plugin!.language;
    } else {
      _currentPlugin = null;
      _codeController = TextEditingController(text: SpiderPlugin.template(PluginLanguage.javascript));
      _nameController = TextEditingController();
      _descController = TextEditingController();
    }

    _codeController.addListener(() {
      if (!_isModified) setState(() => _isModified = true);
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _tabController.dispose();
    _engineManager.dispose();
    super.dispose();
  }

  /// 切换语言时加载模板
  void _switchLanguage(PluginLanguage lang) {
    if (_isModified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('切换语言'),
          content: const Text('当前代码未保存，切换语言将丢失修改。'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _selectedLanguage = lang;
                  _codeController.text = SpiderPlugin.template(lang);
                  _isModified = false;
                });
              },
              child: const Text('切换'),
            ),
          ],
        ),
      );
    } else {
      setState(() {
        _selectedLanguage = lang;
        _codeController.text = SpiderPlugin.template(lang);
      });
    }
  }

  /// 运行测试
  Future<void> _runTest() async {
    setState(() { _isRunning = true; _consoleLogs = []; _testResult = null; });

    final plugin = _buildPlugin();
    final result = await _engineManager.test(plugin);

    setState(() {
      _isRunning = false;
      _consoleLogs = result.logs;
      _testResult = result.success
          ? '✅ 测试通过 (${result.executionTime.inMilliseconds}ms)'
          : '❌ 测试失败: ${result.error}';
      _selectedTab = 1; // 切到控制台
    });
  }

  /// 保存插件
  void _savePlugin() {
    final plugin = _buildPlugin();
    _engineManager.savePlugin(plugin);
    setState(() => _isModified = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('插件「${plugin.name}」已保存')),
    );
  }

  SpiderPlugin _buildPlugin() {
    return SpiderPlugin(
      id: _currentPlugin?.id ?? 'plugin_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.isNotEmpty ? _nameController.text : '未命名插件',
      description: _descController.text,
      language: _selectedLanguage,
      sourceCode: _codeController.text,
      isBuiltIn: _currentPlugin?.isBuiltIn ?? false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPlugin != null ? '编辑插件' : '新建插件'),
        actions: [
          // 语言选择
          PopupMenuButton<PluginLanguage>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_selectedLanguage.icon, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 2),
                Text(_selectedLanguage.label,
                    style: const TextStyle(fontSize: 13)),
                const Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
            onSelected: _switchLanguage,
            itemBuilder: (_) => PluginLanguage.values.map((l) => PopupMenuItem(
              value: l,
              child: Row(
                children: [
                  Text(l.icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(l.desc, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ],
              ),
            )).toList(),
          ),
          // 运行测试
          IconButton(
            icon: _isRunning
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green))
                : const Icon(Icons.play_arrow, color: Colors.green),
            tooltip: '运行测试',
            onPressed: _isRunning ? null : _runTest,
          ),
          // 保存
          IconButton(
            icon: Icon(Icons.save,
                color: _isModified ? Colors.blue : Colors.grey),
            tooltip: '保存',
            onPressed: _isModified ? _savePlugin : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // 顶部: 名称和描述
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1A1A1A),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '插件名称',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _descController,
                    decoration: InputDecoration(
                      hintText: '插件描述',
                      hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          // Tab 切换: 编辑器 / 控制台 / 设置
          Container(
            color: const Color(0xFF1A1A1A),
            child: TabBar(
              controller: _tabController,
              onTap: (i) => setState(() => _selectedTab = i),
              indicatorColor: Colors.blue,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: '编辑器 (${_selectedLanguage.label})'),
                Tab(text: _consoleLogs.isNotEmpty
                    ? '控制台 (${_consoleLogs.length})'
                    : '控制台'),
                const Tab(text: '设置'),
              ],
            ),
          ),
          // 内容区域
          Expanded(
            child: _selectedTab == 0
                ? _buildCodeEditor()
                : _selectedTab == 1
                    ? _buildConsole()
                    : _buildSettings(),
          ),
        ],
      ),
    );
  }

  /// 代码编辑器
  Widget _buildCodeEditor() {
    return Container(
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          // 行号
          Container(
            width: 50,
            color: const Color(0xFF151515),
            child: ListenableBuilder(
              listenable: _codeController,
              builder: (_, __) {
                final lines = _codeController.text.split('\n').length;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 12),
                  itemCount: lines,
                  itemBuilder: (_, i) => Container(
                    height: 20,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace')),
                  ),
                );
              },
            ),
          ),
          // 代码输入区
          Expanded(
            child: TextField(
              controller: _codeController,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: Color(0xFFEEFFFF),
                height: 1.5,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 控制台输出
  Widget _buildConsole() {
    return Container(
      color: const Color(0xFF0D0D0D),
      child: Column(
        children: [
          // 测试结果
          if (_testResult != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: _testResult!.startsWith('✅')
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              child: Text(_testResult!,
                  style: TextStyle(
                    fontSize: 13,
                    color: _testResult!.startsWith('✅') ? Colors.green : Colors.red,
                  )),
            ),
          // 日志列表
          Expanded(
            child: _consoleLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.terminal, size: 48, color: Colors.grey[700]),
                        const SizedBox(height: 12),
                        Text('暂无输出', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        Text('点击 ▶ 运行测试查看结果',
                            style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _consoleLogs.length,
                    itemBuilder: (context, index) {
                      final log = _consoleLogs[index];
                      final color = {
                        LogLevel.debug: Colors.grey,
                        LogLevel.info: Colors.blue,
                        LogLevel.warn: Colors.orange,
                        LogLevel.error: Colors.red,
                      }[log.level];

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('[${log.level.name.toUpperCase()}]',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontFamily: 'monospace')),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(log.message,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontFamily: 'monospace')),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 设置面板
  Widget _buildSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('运行环境', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // 引擎状态
        ..._buildEngineStatus(),
        const Divider(height: 32),
        const Text('插件信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _infoRow('语言', _selectedLanguage.label),
        _infoRow('入口函数', _currentPlugin?.entryFunction ?? 'search'),
        _infoRow('创建时间', _currentPlugin?.createdAt.toString().substring(0, 19) ?? '新建'),
        _infoRow('修改时间', _currentPlugin?.updatedAt.toString().substring(0, 19) ?? '-'),
        const Divider(height: 32),
        const Text('代码操作', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          ActionChip(
            avatar: const Icon(Icons.copy, size: 16),
            label: const Text('复制代码'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _codeController.text));
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('代码已复制')));
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.delete, size: 16),
            label: const Text('清空代码'),
            onPressed: () => setState(() => _codeController.clear()),
          ),
          ActionChip(
            avatar: const Icon(Icons.format_color_text, size: 16),
            label: const Text('加载模板'),
            onPressed: () => setState(() {
              _codeController.text = SpiderPlugin.template(_selectedLanguage);
            }),
          ),
          ActionChip(
            avatar: const Icon(Icons.file_upload, size: 16),
            label: const Text('导入文件'),
            onPressed: () {
              // TODO: 文件导入
            },
          ),
          ActionChip(
            avatar: const Icon(Icons.file_download, size: 16),
            label: const Text('导出文件'),
            onPressed: () {
              // TODO: 文件导出
            },
          ),
        ]),
      ],
    );
  }

  List<Widget> _buildEngineStatus() {
    final engines = {
      'JavaScript (flutter_js)': true,
      'Python (HTTP 桥)': false,
      'PHP (WASM)': false,
      'Go (WASM)': false,
      'Java (Android)': false,
    };

    return engines.entries.map((e) => ListTile(
      dense: true,
      leading: Icon(
        e.value ? Icons.check_circle : Icons.cancel,
        color: e.value ? Colors.green : Colors.grey,
        size: 20,
      ),
      title: Text(e.key, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        e.value ? '可用' : '未启用 (设置 → 运行环境)',
        style: TextStyle(
            fontSize: 11, color: e.value ? Colors.green : Colors.orange),
      ),
      trailing: !e.value
          ? TextButton(
              onPressed: () {
                // TODO: 跳转运行环境设置
              },
              child: const Text('配置'),
            )
          : null,
    )).toList();
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
