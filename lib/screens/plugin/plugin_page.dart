import 'package:flutter/material.dart';
import '../../models/plugin.dart';
import '../../services/plugin_service.dart';

class PluginPage extends StatefulWidget {
  const PluginPage({super.key});

  @override
  State<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _repositoryController = TextEditingController();
  List<SourcePlugin> _plugins = <SourcePlugin>[];
  List<String> _repositories = <String>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _repositoryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final plugins = await PluginService.list();
    final repositories = await PluginService.repositories();
    if (!mounted) return;
    setState(() {
      _plugins = plugins;
      _repositories = repositories;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件'),
        actions: <Widget>[
          IconButton(
            tooltip: '新建插件',
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const <Widget>[
            Tab(text: '已安装'),
            Tab(text: '扩展仓库'),
            Tab(text: '调试'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _installedTab(),
          _repositoryTab(),
          _debugTab(),
        ],
      ),
    );
  }

  Widget _installedTab() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_plugins.isEmpty) {
      return _emptyState(
        icon: Icons.extension_off,
        title: '暂无插件',
        message: '插件可以为视频、漫画和小说提供扩展源。',
        action: '新建插件',
        onPressed: () => _openEditor(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _infoCard(
          Icons.extension,
          '扩展源系统',
          '插件通过统一协议返回搜索、详情、分类和播放数据。JavaScript 可直接调试，其他语言可以先保存源码。',
        ),
        const SizedBox(height: 8),
        ..._plugins.map(_pluginTile),
      ],
    );
  }

  Widget _pluginTile(SourcePlugin plugin) {
    final color = _languageColor(plugin.language);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(.12),
          child: Text(
            plugin.language.name.substring(0, 1).toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(plugin.name),
        subtitle: Text(
          '${plugin.language.name} · v${plugin.version}\n${plugin.description.isEmpty ? '暂无描述' : plugin.description}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        onTap: () => _openEditor(plugin),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') _openEditor(plugin);
            if (value == 'debug') _debugPlugin(plugin);
            if (value == 'delete') _deletePlugin(plugin);
          },
          itemBuilder: (_) => const <PopupMenuEntry<String>>[
            PopupMenuItem<String>(value: 'edit', child: Text('编辑代码')),
            PopupMenuItem<String>(value: 'debug', child: Text('调试插件')),
            PopupMenuItem<String>(value: 'delete', child: Text('删除插件')),
          ],
        ),
      ),
    );
  }

  Widget _repositoryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        _infoCard(
          Icons.cloud_download,
          '扩展仓库',
          '添加公开 JSON 仓库，仓库可以返回插件数组，也可以使用 {"plugins": [...]} 格式。',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _repositoryController,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: '仓库 URL',
            hintText: 'https://example.com/plugins.json',
            prefixIcon: Icon(Icons.link),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('加载并安装'),
                onPressed: _installRepository,
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: _saveRepository,
              child: const Text('保存地址'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('已保存仓库', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_repositories.isEmpty)
          Text('暂无仓库', style: TextStyle(color: Colors.grey[600]))
        else
          ..._repositories.map((url) => Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_queue),
              title: Text(url, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () {
                _repositoryController.text = url;
                _installRepository();
              },
              trailing: IconButton(
                tooltip: '删除仓库',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  await PluginService.removeRepository(url);
                  _load();
                },
              ),
            ),
          )),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _debugTab() {
    if (_plugins.isEmpty) {
      return _emptyState(
        icon: Icons.bug_report,
        title: '没有可调试插件',
        message: '先创建或安装一个插件。',
        action: '新建插件',
        onPressed: () => _openEditor(),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: <Widget>[
        _infoCard(Icons.bug_report, '插件调试', '运行结构检查并查看统一协议提示。'),
        const SizedBox(height: 8),
        ..._plugins.map((plugin) => Card(
          child: ListTile(
            leading: Icon(Icons.code, color: _languageColor(plugin.language)),
            title: Text(plugin.name),
            subtitle: Text('${plugin.language.name} · ${plugin.code.split('\n').length} 行代码'),
            trailing: FilledButton(
              onPressed: () => _debugPlugin(plugin),
              child: const Text('运行'),
            ),
          ),
        )),
      ],
    );
  }

  Future<void> _installRepository() async {
    final url = _repositoryController.text.trim();
    if (url.isEmpty) return;
    try {
      await PluginService.installFromRepository(url);
      await PluginService.addRepository(url);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('插件安装完成')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('加载失败: $error')));
      }
    }
  }

  Future<void> _saveRepository() async {
    final url = _repositoryController.text.trim();
    if (url.isEmpty) return;
    await PluginService.addRepository(url);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('仓库地址已保存')));
    }
  }

  Future<void> _debugPlugin(SourcePlugin plugin) async {
    final result = await PluginService.runTest(plugin);
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('调试: ${plugin.name}'),
        content: SelectableText(result),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  void _openEditor([SourcePlugin? plugin]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => PluginEditorPage(plugin: plugin)),
    );
    _load();
  }

  Future<void> _deletePlugin(SourcePlugin plugin) async {
    await PluginService.delete(plugin.id);
    _load();
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String message,
    required String action,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 20),
            FilledButton.icon(icon: const Icon(Icons.add), label: Text(action), onPressed: onPressed),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String message) {
    return Card(
      color: const Color(0xffeef4ff),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Icon(Icons.info_outline, color: Color(0xff3f51b5)),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(children: <Widget>[
                  Icon(icon, color: const Color(0xff3f51b5), size: 18),
                  const SizedBox(width: 6),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4)),
              ],
            )),
          ],
        ),
      ),
    );
  }

  Color _languageColor(PluginLanguage language) {
    switch (language) {
      case PluginLanguage.javascript:
        return Colors.orange;
      case PluginLanguage.python:
        return Colors.blue;
      case PluginLanguage.php:
        return Colors.indigo;
      case PluginLanguage.go:
        return Colors.cyan;
      case PluginLanguage.java:
        return Colors.red;
    }
  }
}

class PluginEditorPage extends StatefulWidget {
  final SourcePlugin? plugin;
  const PluginEditorPage({super.key, this.plugin});

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _code;
  late PluginLanguage _language;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    final plugin = widget.plugin;
    _name = TextEditingController(text: plugin?.name ?? '新插件');
    _description = TextEditingController(text: plugin?.description ?? '');
    _language = plugin?.language ?? PluginLanguage.javascript;
    _code = TextEditingController(text: plugin?.code ?? _template(_language));
    _code.addListener(() {
      if (!_changed) setState(() => _changed = true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plugin == null ? '新建插件' : '编辑插件'),
        actions: <Widget>[
          PopupMenuButton<PluginLanguage>(
            tooltip: '选择语言',
            icon: const Icon(Icons.code),
            onSelected: _changeLanguage,
            itemBuilder: (_) => PluginLanguage.values.map((language) => PopupMenuItem<PluginLanguage>(
              value: language,
              child: Text(language.name),
            )).toList(),
          ),
          IconButton(tooltip: '调试', icon: const Icon(Icons.bug_report), onPressed: _test),
          IconButton(
            tooltip: '保存',
            icon: Icon(Icons.save, color: _changed ? Colors.blue : null),
            onPressed: _save,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(children: <Widget>[
              Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: '插件名称'))),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _description, decoration: const InputDecoration(labelText: '描述'))),
            ]),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              '语言: ${_language.name} · 方法: search / detail / category / playerUrl / test',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              decoration: BoxDecoration(color: const Color(0xff202124), borderRadius: BorderRadius.circular(8)),
              child: TextField(
                controller: _code,
                expands: true,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13, height: 1.4),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: '编写插件代码',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _changeLanguage(PluginLanguage language) {
    setState(() {
      _language = language;
      _code.text = _template(language);
      _changed = true;
    });
  }

  Future<void> _test() async {
    final result = await PluginService.runTest(_buildPlugin());
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('调试结果'),
        content: SelectableText(result),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    await PluginService.save(_buildPlugin());
    if (mounted) Navigator.pop(context);
  }

  SourcePlugin _buildPlugin() => SourcePlugin(
    id: widget.plugin?.id ?? 'plugin-${DateTime.now().millisecondsSinceEpoch}',
    name: _name.text.trim().isEmpty ? '未命名插件' : _name.text.trim(),
    description: _description.text.trim(),
    language: _language,
    code: _code.text,
  );

  String _template(PluginLanguage language) {
    switch (language) {
      case PluginLanguage.javascript:
        return '''// 宏曦聚合 / Miru 扩展协议
// 返回格式: {"list":[{"id":"1","title":"名称","cover":"图片"}]}
async function search(keyword, page) {
  return JSON.stringify({list: []});
}
async function detail(id) {
  return JSON.stringify({id: id, title: "", episodes: []});
}
async function category(categoryId, page) {
  return JSON.stringify({list: [], categories: []});
}
async function playerUrl(url) {
  return JSON.stringify({url: url});
}
async function test() {
  return true;
}
''';
      case PluginLanguage.python:
        return '''# Miru-compatible plugin
import json

def search(keyword, page=1):
    return json.dumps({"list": []})

def detail(item_id):
    return json.dumps({"id": item_id, "title": "", "episodes": []})

def category(category_id=None, page=1):
    return json.dumps({"list": [], "categories": []})

def player_url(url):
    return json.dumps({"url": url})

def test():
    return True
''';
      case PluginLanguage.php:
        return r'''<?php
function search($keyword, $page = 1) { return json_encode(["list" => []]); }
function detail($id) { return json_encode(["id" => $id, "episodes" => []]); }
function category($id = null, $page = 1) { return json_encode(["list" => []]); }
function playerUrl($url) { return json_encode(["url" => $url]); }
function test() { return true; }
?>''';
      case PluginLanguage.go:
        return '''package main
func search(keyword string, page int) string { return `{"list":[]}` }
func detail(id string) string { return `{"id":""}` }
func category(id string, page int) string { return `{"list":[]}` }
func playerUrl(url string) string { return `{"url":""}` }
func test() bool { return true }
''';
      case PluginLanguage.java:
        return '''public class Spider {
  public static String search(String keyword, int page) { return "{\\"list\\":[]}"; }
  public static String detail(String id) { return "{\\"id\\":\\"\\"}"; }
  public static String category(String id, int page) { return "{\\"list\\":[]}"; }
  public static String playerUrl(String url) { return "{\\"url\\":\\"\\"}"; }
  public static boolean test() { return true; }
}
''';
    }
  }
}
