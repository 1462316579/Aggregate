/// 插件商店 — 浏览 / 安装 / 管理本地和在线插件
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../plugin/spider_plugin.dart';
import '../../plugin/spider_interface.dart';
import '../plugin_editor/plugin_editor_screen.dart';

class PluginStoreScreen extends StatefulWidget {
  const PluginStoreScreen({super.key});
  @override
  State<PluginStoreScreen> createState() => _PluginStoreScreenState();
}

class _PluginStoreScreenState extends State<PluginStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _plugins = <SpiderPlugin>[];
  bool _isLoading = false;

  // 内置示例插件
  final _builtinPlugins = <SpiderPlugin>[
    SpiderPlugin(
      id: 'builtin_js_1',
      name: 'CMS JSON 采集器 (JS)',
      description: '通用 CMS JSON API 采集插件，支持 TVBox V3 格式源',
      author: 'AllPlay',
      language: PluginLanguage.javascript,
      sourceCode: SpiderPlugin.template(PluginLanguage.javascript),
      isBuiltIn: true,
      tags: ['CMS', '通用', 'JSON'],
    ),
    SpiderPlugin(
      id: 'builtin_py_1',
      name: 'CMS 采集器 (Python)',
      description: 'Python 版 CMS 采集插件，适合熟悉 Python 的用户',
      author: 'AllPlay',
      language: PluginLanguage.python,
      sourceCode: SpiderPlugin.template(PluginLanguage.python),
      isBuiltIn: true,
      tags: ['CMS', '通用', 'Python'],
    ),
    SpiderPlugin(
      id: 'builtin_php_1',
      name: 'CMS 采集器 (PHP)',
      description: 'PHP 版 CMS 采集插件，兼容 PHP 开发者习惯',
      author: 'AllPlay',
      language: PluginLanguage.php,
      sourceCode: SpiderPlugin.template(PluginLanguage.php),
      isBuiltIn: true,
      tags: ['CMS', '通用', 'PHP'],
    ),
    SpiderPlugin(
      id: 'builtin_go_1',
      name: 'CMS 采集器 (Go)',
      description: 'Go 版 CMS 采集插件，高性能实现',
      author: 'AllPlay',
      language: PluginLanguage.go,
      sourceCode: SpiderPlugin.template(PluginLanguage.go),
      isBuiltIn: true,
      tags: ['CMS', '通用', 'Go'],
    ),
    SpiderPlugin(
      id: 'builtin_java_1',
      name: 'CMS 采集器 (Java)',
      description: 'Java 版 CMS 采集插件，Android 平台专用',
      author: 'AllPlay',
      language: PluginLanguage.java,
      sourceCode: SpiderPlugin.template(PluginLanguage.java),
      isBuiltIn: true,
      tags: ['CMS', '通用', 'Java'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    setState(() => _isLoading = true);
    // 加载本地已安装插件
    // TODO: 从持久化存储加载
    setState(() {
      _plugins.addAll(_builtinPlugins);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件中心'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: '内置模板'),
            Tab(text: '我的插件'),
            Tab(text: '导入'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '新建插件',
            onPressed: () => _openEditor(null),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBuiltinList(),
          _buildMyPluginsList(),
          _buildImportTab(),
        ],
      ),
    );
  }

  Widget _buildBuiltinList() {
    final grouped = <PluginLanguage, List<SpiderPlugin>>{};
    for (var p in _builtinPlugins) {
      grouped.putIfAbsent(p.language, () => []).add(p);
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 语言环境状态
        _buildEnvironmentCard(),
        const SizedBox(height: 12),
        // 按语言分组展示
        for (var entry in grouped.entries) ...[
          _buildLanguageHeader(entry.key, entry.value.length),
          ...entry.value.map((p) => _buildPluginCard(p)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildEnvironmentCard() {
    return Card(
      color: const Color(0xFF1A2332),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text('运行环境',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _envRow(PluginLanguage.javascript, true, 'flutter_js 引擎'),
            _envRow(PluginLanguage.python, false, '需要配置 Python 运行时'),
            _envRow(PluginLanguage.php, false, '需要配置 PHP WASM'),
            _envRow(PluginLanguage.go, false, '需要 Go WASM 模块'),
            _envRow(PluginLanguage.java, false, '仅 Android (MethodChannel)'),
            const SizedBox(height: 8),
            Text('💡 JavaScript 已内置，其他语言需在「设置 → 运行环境」中配置',
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _envRow(PluginLanguage lang, bool available, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(lang.icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(lang.label, style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Icon(
            available ? Icons.check_circle : Icons.info_outline,
            color: available ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(note, style: TextStyle(
            fontSize: 10, color: available ? Colors.green : Colors.orange)),
        ],
      ),
    );
  }

  Widget _buildLanguageHeader(PluginLanguage lang, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(lang.icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(lang.label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ),
        ],
      ),
    );
  }

  Widget _buildPluginCard(SpiderPlugin plugin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openEditor(plugin),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getLangColor(plugin.language).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${plugin.language.icon} ${plugin.language.label}',
                        style: TextStyle(
                            color: _getLangColor(plugin.language), fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  if (plugin.isBuiltIn)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('内置',
                          style: TextStyle(color: Colors.green, fontSize: 10)),
                    ),
                  const Spacer(),
                  if (plugin.tags.isNotEmpty)
                    ...plugin.tags.take(2).map((t) => Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(t, style: TextStyle(fontSize: 9, color: Colors.grey[400])),
                    )),
                ],
              ),
              const SizedBox(height: 10),
              Text(plugin.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(plugin.description,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('by ${plugin.author}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  const Spacer(),
                  Text('v${plugin.version}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPluginsList() {
    final myPlugins = _plugins.where((p) => !p.isBuiltIn).toList();

    if (myPlugins.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.code, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text('暂无自定义插件',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            Text('点击右上角 + 创建新插件',
                style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('新建插件'),
              onPressed: () => _openEditor(null),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: myPlugins.length,
      itemBuilder: (context, index) => _buildPluginCard(myPlugins[index]),
    );
  }

  Widget _buildImportTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('导入插件', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // 导入方式
          _importOption(
            Icons.content_paste,
            '粘贴代码',
            '将插件代码粘贴到编辑器中',
            () => _importFromClipboard(),
          ),
          const SizedBox(height: 12),
          _importOption(
            Icons.file_open,
            '打开本地文件',
            '选择设备上的 .js / .py / .php / .go / .java 文件',
            () => _importFromFile(),
          ),
          const SizedBox(height: 12),
          _importOption(
            Icons.link,
            '从 URL 导入',
            '输入插件文件的网络地址',
            () => _importFromUrl(),
          ),
          const SizedBox(height: 12),
          _importOption(
            Icons.qr_code,
            '扫描二维码',
            '扫描插件分享二维码导入',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _importOption(IconData icon, String title, String desc, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _openEditor(SpiderPlugin? plugin) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => PluginEditorScreen(plugin: plugin)));
  }

  Future<void> _importFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final ext = _detectLanguage(data.text!);
      final plugin = SpiderPlugin(
        id: 'import_${DateTime.now().millisecondsSinceEpoch}',
        name: '导入插件',
        language: ext,
        sourceCode: data.text!,
      );
      _openEditor(plugin);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('剪贴板为空')));
    }
  }

  void _importFromFile() {
    // TODO: 使用 file_picker 打开文件
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('文件导入功能开发中')));
  }

  void _importFromUrl() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('从 URL 导入'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com/spider.js',
            labelText: '插件 URL',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: 下载并导入
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL 导入功能开发中')));
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  PluginLanguage _detectLanguage(String code) {
    if (code.contains('function ') && code.contains('async')) return PluginLanguage.javascript;
    if (code.contains('def ') && code.contains('import json')) return PluginLanguage.python;
    if (code.contains('<?php')) return PluginLanguage.php;
    if (code.contains('package main')) return PluginLanguage.go;
    if (code.contains('public class')) return PluginLanguage.java;
    return PluginLanguage.javascript;
  }

  Color _getLangColor(PluginLanguage lang) {
    switch (lang) {
      case PluginLanguage.javascript: return Colors.yellow;
      case PluginLanguage.python: return Colors.green;
      case PluginLanguage.php: return Colors.purple;
      case PluginLanguage.go: return Colors.cyan;
      case PluginLanguage.java: return Colors.orange;
    }
  }
}
