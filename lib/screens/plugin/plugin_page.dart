import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/content.dart';
import '../../models/plugin.dart';
import '../../providers/source_provider.dart';
import '../../services/plugin_service.dart';
import '../../services/source_service.dart';

class PluginPage extends StatefulWidget {
  const PluginPage({super.key});
  @override
  State<PluginPage> createState() => _PluginPageState();
}

class _PluginPageState extends State<PluginPage> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<SourcePlugin> _plugins = [];
  final _repoController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final values = await PluginService.list();
    if (mounted) setState(() { _plugins = values; _loading = false; });
  }

  @override
  void dispose() { _tabs.dispose(); _repoController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('插件'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _edit()),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
        bottom: TabBar(controller: _tabs, tabs: const [Tab(text: '已安装'), Tab(text: '源仓库')]),
      ),
      body: TabBarView(controller: _tabs, children: [_installed(), _repository()]),
    );
  }

  Widget _installed() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_plugins.isEmpty) return const Center(child: Text('暂无插件'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plugins.length,
      itemBuilder: (_, i) {
        final p = _plugins[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(p.language.name.substring(0, 1).toUpperCase())),
            title: Text(p.name),
            subtitle: Text('${p.language.name} · v${p.version}\n${p.description}'),
            isThreeLine: true,
            trailing: PopupMenuButton<String>(
              onSelected: (action) {
                if (action == 'edit') _edit(p);
                if (action == 'delete') _delete(p);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('编辑代码')),
                PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _repository() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('扩展仓库', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('添加一个公开 JSON 仓库地址，导入视频、漫画或小说源。', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 16),
        TextField(controller: _repoController, decoration: const InputDecoration(labelText: '仓库 URL', border: OutlineInputBorder())),
        const SizedBox(height: 12),
        FilledButton.icon(icon: const Icon(Icons.download), label: const Text('加载仓库'), onPressed: _loadRepository),
        const SizedBox(height: 24),
        const Text('仓库格式示例', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText('{"sites":[{"key":"demo","name":"示例","api":"https://example.com/api.php/provide/vod/","type":2}]}', style: TextStyle(color: Colors.grey[700], fontFamily: 'monospace')),
      ],
    );
  }

  Future<void> _loadRepository() async {
    final url = _repoController.text.trim();
    if (url.isEmpty) return;
    final sources = await const SourceService().loadRepository(url);
    if (!mounted) return;
    await context.read<SourceProvider>().addSources(sources);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入 ${sources.length} 个源')));
  }

  void _edit([SourcePlugin? plugin]) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => PluginEditorPage(plugin: plugin)));
    _load();
  }

  Future<void> _delete(SourcePlugin plugin) async {
    await PluginService.delete(plugin.id);
    _load();
  }
}

class PluginEditorPage extends StatefulWidget {
  final SourcePlugin? plugin;
  const PluginEditorPage({super.key, this.plugin});
  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  late TextEditingController _name;
  late TextEditingController _code;
  late PluginLanguage _language;

  @override
  void initState() {
    super.initState();
    final p = widget.plugin;
    _name = TextEditingController(text: p?.name ?? '新插件');
    _code = TextEditingController(text: p?.code ?? '// 在这里编写源插件代码\n// 统一返回 {"list": []}\n');
    _language = p?.language ?? PluginLanguage.javascript;
  }

  @override
  void dispose() { _name.dispose(); _code.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plugin == null ? '新建插件' : '编辑插件'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _save)],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: TextField(controller: _name, decoration: const InputDecoration(labelText: '名称'))),
            const SizedBox(width: 12),
            DropdownButton<PluginLanguage>(value: _language, items: PluginLanguage.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (e) { if (e != null) setState(() => _language = e); }),
          ]),
        ),
        Expanded(child: Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xff202124), borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: _code,
            expands: true,
            maxLines: null,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
            decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(16), hintText: '插件代码', hintStyle: TextStyle(color: Colors.white54)),
          ),
        )),
      ]),
    );
  }

  Future<void> _save() async {
    final plugin = SourcePlugin(
      id: widget.plugin?.id ?? 'plugin-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim().isEmpty ? '未命名插件' : _name.text.trim(),
      language: _language,
      code: _code.text,
    );
    await PluginService.save(plugin);
    if (mounted) Navigator.pop(context);
  }
}
