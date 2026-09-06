import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/content.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
import '../../services/config_transfer_service.dart';

/// Settings grouped like Miru: source management, repositories, playback,
/// network, storage and about.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _autoPlay = true;
  bool _rememberPosition = true;
  bool _hardwareDecode = true;
  bool _proxyEnabled = false;
  String _proxyHost = '';
  String _proxyPort = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: <Widget>[
          _section('源管理'),
          ...provider.sources.map((source) => _sourceTile(context, source)),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('添加源'),
            subtitle: const Text('视频、漫画或小说扩展源'),
            onTap: () => _addSource(context),
          ),
          _section('扩展仓库'),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('管理插件仓库'),
            subtitle: const Text('在插件页面添加和安装仓库'),
            onTap: () => _showMessage(context, '请到「插件」→「扩展仓库」管理'),
          ),
          _section('播放'),
          SwitchListTile(
            secondary: const Icon(Icons.play_circle_outline),
            title: const Text('自动播放下一集'),
            value: _autoPlay,
            onChanged: (value) => setState(() => _autoPlay = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.restore),
            title: const Text('记忆播放位置'),
            value: _rememberPosition,
            onChanged: (value) => setState(() => _rememberPosition = value),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.memory),
            title: const Text('硬件解码'),
            value: _hardwareDecode,
            onChanged: (value) => setState(() => _hardwareDecode = value),
          ),
          _section('网络代理'),
          SwitchListTile(
            secondary: const Icon(Icons.lan_outlined),
            title: const Text('启用代理'),
            subtitle: Text(_proxyEnabled && _proxyHost.isNotEmpty
                ? '$_proxyHost:${_proxyPort.isEmpty ? '8080' : _proxyPort}'
                : '支持 HTTP / SOCKS4 / SOCKS5 的配置入口'),
            value: _proxyEnabled,
            onChanged: (value) => setState(() => _proxyEnabled = value),
          ),
          if (_proxyEnabled)
            ListTile(
              leading: const Icon(Icons.settings_ethernet),
              title: const Text('代理地址'),
              onTap: () => _proxyDialog(context),
            ),
          _section('数据与同步'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导入源配置'),
            subtitle: const Text('支持 TVBox JSON / HongXi JSON'),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导出源配置'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.copy_all_outlined),
            title: const Text('复制配置到剪贴板'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
            title: const Text('清除观看历史', style: TextStyle(color: Colors.red)),
            onTap: () => _clearHistory(context),
          ),
          _section('外观'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            subtitle: const Text('跟随系统主题的独立开关入口'),
            value: _darkMode,
            onChanged: (value) => setState(() => _darkMode = value),
          ),
          _section('关于'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('宏曦聚合'),
            subtitle: Text('Miru 风格多媒体聚合应用 · 无需登录，本地存储'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('应用包名'),
            subtitle: Text('juhe.homes.app2026'),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(title, style: const TextStyle(
      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
  );

  Widget _sourceTile(BuildContext context, SourceDefinition source) => ListTile(
    leading: Icon(_sourceIcon(source.type)),
    title: Text(source.name),
    subtitle: Text(source.api, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Switch(
        value: source.enabled,
        onChanged: (_) => context.read<SourceProvider>().toggleSource(source),
      ),
      PopupMenuButton<String>(
        onSelected: (value) {
          if (value == 'delete') context.read<SourceProvider>().removeSource(source.id);
        },
        itemBuilder: (_) => const <PopupMenuEntry<String>>[
          PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
      ),
    ]),
  );

  IconData _sourceIcon(ContentType type) {
    switch (type) {
      case ContentType.comic:
        return Icons.auto_stories_outlined;
      case ContentType.novel:
        return Icons.menu_book_outlined;
      case ContentType.video:
        return Icons.movie_outlined;
    }
  }

  void _addSource(BuildContext context) {
    final name = TextEditingController();
    final api = TextEditingController();
    var type = ContentType.video;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('添加源'),
          content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            TextField(controller: name, decoration: const InputDecoration(labelText: '名称')),
            TextField(controller: api, decoration: const InputDecoration(labelText: 'API 地址')),
            DropdownButton<ContentType>(
              value: type,
              isExpanded: true,
              items: ContentType.values.map((item) => DropdownMenuItem(
                value: item, child: Text(item.name),
              )).toList(),
              onChanged: (value) {
                if (value != null) setDialogState(() => type = value);
              },
            ),
          ]),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || api.text.trim().isEmpty) return;
                context.read<SourceProvider>().addSource(SourceDefinition(
                  id: 'source-${DateTime.now().millisecondsSinceEpoch}',
                  name: name.text.trim(), api: api.text.trim(), type: type,
                ));
                Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入源配置'),
        content: TextField(
          controller: controller,
          maxLines: 8,
          decoration: const InputDecoration(hintText: '{"sites": [...]}'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              try {
                final values = ConfigTransferService.importSources(controller.text);
                context.read<SourceProvider>().addSources(values);
                Navigator.pop(ctx);
                _showMessage(context, '已导入 ${values.length} 个源');
              } catch (_) {
                _showMessage(context, 'JSON 格式错误');
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final value = ConfigTransferService.exportSources(context.read<SourceProvider>().sources);
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) _showMessage(context, '配置已复制到剪贴板');
  }

  Future<void> _clearHistory(BuildContext context) async {
    await AppConfig.clearHistory();
    if (context.mounted) _showMessage(context, '观看历史已清除');
  }

  void _proxyDialog(BuildContext context) {
    final host = TextEditingController(text: _proxyHost);
    final port = TextEditingController(text: _proxyPort);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('代理地址'),
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          TextField(controller: host, decoration: const InputDecoration(labelText: '主机地址')),
          TextField(controller: port, decoration: const InputDecoration(labelText: '端口')),
        ]),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              setState(() {
                _proxyHost = host.text.trim();
                _proxyPort = port.text.trim();
              });
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}
