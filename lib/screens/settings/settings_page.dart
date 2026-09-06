import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/content.dart';
import '../../providers/source_provider.dart';
import '../../services/config_transfer_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _header('源管理'),
          ...provider.sources.map((source) => _sourceTile(context, source)),
          ListTile(leading: const Icon(Icons.add), title: const Text('添加源'), onTap: () => _addSource(context)),
          const Divider(height: 24),
          _header('配置'),
          ListTile(leading: const Icon(Icons.upload_file), title: const Text('导入源配置'), subtitle: const Text('支持 TVBox JSON / HongXi JSON'), onTap: () => _import(context)),
          ListTile(leading: const Icon(Icons.download), title: const Text('导出源配置'), onTap: () => _export(context)),
          const Divider(height: 24),
          _header('关于'),
          const ListTile(leading: Icon(Icons.info_outline), title: Text('宏曦聚合'), subtitle: Text('不需要登录，数据保存在本机')),
        ],
      ),
    );
  }

  Widget _header(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
  );

  Widget _sourceTile(BuildContext context, SourceDefinition source) => ListTile(
    leading: Icon(source.type == ContentType.comic ? Icons.auto_stories : source.type == ContentType.novel ? Icons.menu_book : Icons.movie),
    title: Text(source.name),
    subtitle: Text(source.api, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Switch(value: source.enabled, onChanged: (_) => context.read<SourceProvider>().toggleSource(source)),
      PopupMenuButton<String>(
        onSelected: (value) { if (value == 'delete') context.read<SourceProvider>().removeSource(source.id); },
        itemBuilder: (_) => const [PopupMenuItem(value: 'delete', child: Text('删除'))],
      ),
    ]),
  );

  void _addSource(BuildContext context) {
    final name = TextEditingController();
    final api = TextEditingController();
    var type = ContentType.video;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setState) => AlertDialog(
      title: const Text('添加源'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: '名称')),
        TextField(controller: api, decoration: const InputDecoration(labelText: 'API 地址')),
        DropdownButton<ContentType>(value: type, isExpanded: true, items: ContentType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) { if (v != null) setState(() => type = v); }),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { if (name.text.isNotEmpty && api.text.isNotEmpty) context.read<SourceProvider>().addSource(SourceDefinition(id: 'source-${DateTime.now().millisecondsSinceEpoch}', name: name.text, api: api.text, type: type)); Navigator.pop(ctx); }, child: const Text('添加')),
      ],
    )));
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text('粘贴源配置'),
      content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: '{"sites": [...]}')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { try { final values = ConfigTransferService.importSources(controller.text); context.read<SourceProvider>().addSources(values); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入 ${values.length} 个源'))); } catch (_) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JSON 格式错误'))); } }, child: const Text('导入')),
      ],
    ));
  }

  Future<void> _export(BuildContext context) async {
    final value = ConfigTransferService.exportSources(context.read<SourceProvider>().sources);
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('配置已复制到剪贴板')));
  }
}
