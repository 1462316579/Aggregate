import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/content.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
import '../../services/config_transfer_service.dart';

/// Miru 风格设置分组：常规、视频播放器、阅读器、网络、日志、检查更新。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoPlay = true;
  bool _rememberPosition = true;
  bool _hardwareDecode = true;
  bool _autoSkip = false;
  bool _volumePageTurning = true;
  bool _showDanmaku = true;
  bool _proxyEnabled = false;
  String _proxy = '';
  final List<String> _logs = <String>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: <Widget>[
          _section('常规'),
          _item(Icons.source_outlined, '源管理', '管理视频、漫画、小说、音乐源', _sourceManager),
          _item(Icons.upload_file, '导入源配置', '支持 TVBox JSON / HongXi JSON', _importSources),
          _item(Icons.download, '导出源配置', '复制当前源配置到剪贴板', _exportSources),
          _switch(Icons.notifications_none, '显示更新提醒', '启动时检查订阅内容更新', true, (_) {}),

          _section('视频播放器'),
          _switch(Icons.play_circle_outline, '自动连播', '播放完成后自动播放下一集', _autoPlay,
              (value) => setState(() => _autoPlay = value)),
          _switch(Icons.restore, '记忆播放位置', '重新播放时恢复上次进度', _rememberPosition,
              (value) => setState(() => _rememberPosition = value)),
          _switch(Icons.memory, '硬件解码', '优先使用设备硬件解码', _hardwareDecode,
              (value) => setState(() => _hardwareDecode = value)),
          _switch(Icons.skip_next, '自动跳过片头片尾', '使用源提供的时间标记', _autoSkip,
              (value) => setState(() => _autoSkip = value)),
          _item(Icons.subtitles_outlined, '字幕设置', '自动搜索字幕、字幕样式和语言', () => _showSubtitleSettings(context)),
          _item(Icons.tune, '播放器快捷键', '查看桌面键盘和遥控器操作', () => _showKeyboardHelp(context)),

          _section('阅读器'),
          _switch(Icons.volume_up_outlined, '音量键翻页', '音量上/下键切换漫画或小说页面', _volumePageTurning,
              (value) => setState(() => _volumePageTurning = value)),
          _item(Icons.menu_book_outlined, '默认阅读模式', '翻页或滚动阅读', () => _showReaderMode(context)),
          _item(Icons.text_fields, '阅读外观', '字体、字号、行距、夜间模式', () => _showReaderAppearance(context)),
          _item(Icons.auto_stories_outlined, '漫画阅读', '图片适应、预加载、阅读方向', () => _showComicSettings(context)),

          _section('网络'),
          _switch(Icons.lan_outlined, '启用代理', '支持 HTTP / SOCKS4 / SOCKS5', _proxyEnabled,
              (value) => setState(() => _proxyEnabled = value)),
          if (_proxyEnabled) _item(Icons.settings_ethernet, '代理地址', _proxy.isEmpty ? '未配置' : _proxy, () => _proxyDialog(context)),
          _item(Icons.dns_outlined, '连接测试', '测试当前源和网络连接', _testNetwork),

          _section('日志'),
          _item(Icons.article_outlined, '运行日志', '${_logs.length} 条日志', () => _showLogs(context)),
          _item(Icons.delete_sweep_outlined, '清除日志', '删除本地运行日志', () {
            setState(() => _logs.clear());
            _toast('日志已清除');
          }),

          _section('检查更新'),
          _item(Icons.system_update_outlined, '检查应用更新', '当前版本 v1.0.0', _checkUpdate),
          _item(Icons.info_outline, '关于宏曦聚合', 'Miru 风格开源多媒体聚合应用', () => _showAbout(context)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
    child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
  );

  Widget _item(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: onTap,
  );

  Widget _switch(IconData icon, String title, String subtitle, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    secondary: Icon(icon), title: Text(title), subtitle: Text(subtitle), value: value, onChanged: onChanged,
  );

  void _sourceManager() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SourceManagerSheet(onChanged: () => setState(() {})),
    );
  }

  void _addSource() {
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
              items: ContentType.values.map((item) => DropdownMenuItem(value: item, child: Text(_typeName(item)))).toList(),
              onChanged: (value) { if (value != null) setDialogState(() => type = value); },
            ),
          ]),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || api.text.trim().isEmpty) return;
                context.read<SourceProvider>().addSource(SourceDefinition(
                  id: 'source-${DateTime.now().millisecondsSinceEpoch}', name: name.text.trim(), api: api.text.trim(), type: type));
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importSources() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入源配置'),
        content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: '{"sites": [...]}')),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              try {
                final values = ConfigTransferService.importSources(controller.text);
                context.read<SourceProvider>().addSources(values);
                Navigator.pop(ctx);
                _toast('已导入 ${values.length} 个源');
              } catch (_) {
                _toast('JSON 格式错误');
              }
            },
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSources() async {
    final value = ConfigTransferService.exportSources(context.read<SourceProvider>().sources);
    await Clipboard.setData(ClipboardData(text: value));
    _toast('配置已复制到剪贴板');
  }

  void _showSubtitleSettings(BuildContext context) => _simpleDialog(context, '字幕设置', <Widget>[
    const ListTile(title: Text('字幕语言'), trailing: Text('自动')),
    SwitchListTile(title: const Text('自动搜索字幕'), value: true, onChanged: (_) {}),
    const ListTile(title: Text('字幕大小'), trailing: Text('16')),
  ]);

  void _showKeyboardHelp(BuildContext context) => _simpleDialog(context, '播放器快捷键', <Widget>[
    const ListTile(title: Text('空格'), subtitle: Text('播放 / 暂停')),
    const ListTile(title: Text('← / →'), subtitle: Text('后退 / 前进 10 秒')),
    const ListTile(title: Text('N / P'), subtitle: Text('下一集 / 上一集')),
    const ListTile(title: Text('F / Esc'), subtitle: Text('全屏 / 退出全屏')),
  ]);

  void _showReaderMode(BuildContext context) => _simpleDialog(context, '默认阅读模式', <Widget>[
    RadioListTile(title: const Text('翻页模式'), value: 'paged', groupValue: 'paged', onChanged: (_) {}),
    RadioListTile(title: const Text('滚动模式'), value: 'scroll', groupValue: 'paged', onChanged: (_) {}),
  ]);

  void _showReaderAppearance(BuildContext context) => _simpleDialog(context, '阅读外观', <Widget>[
    const ListTile(title: Text('字体'), trailing: Text('系统默认')),
    const ListTile(title: Text('字号'), trailing: Text('18')),
    const ListTile(title: Text('行距'), trailing: Text('1.8')),
    SwitchListTile(title: const Text('夜间模式'), value: false, onChanged: (_) {}),
  ]);

  void _showComicSettings(BuildContext context) => _simpleDialog(context, '漫画阅读', <Widget>[
    SwitchListTile(title: const Text('预加载下一页'), value: true, onChanged: (_) {}),
    const ListTile(title: Text('图片适应'), trailing: Text('宽度')),
    const ListTile(title: Text('阅读方向'), trailing: Text('从左到右')),
  ]);

  void _proxyDialog(BuildContext context) {
    final controller = TextEditingController(text: _proxy);
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('代理地址'),
      content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'http://127.0.0.1:7890')),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { setState(() => _proxy = controller.text.trim()); Navigator.pop(ctx); }, child: const Text('保存')),
      ],
    ));
  }

  Future<void> _testNetwork() async {
    setState(() => _logs.add('${DateTime.now()}: 开始网络测试'));
    _toast('网络测试完成');
  }

  void _showLogs(BuildContext context) => showDialog<void>(context: context, builder: (_) => AlertDialog(
    title: const Text('运行日志'),
    content: SizedBox(width: 500, height: 300, child: _logs.isEmpty ? const Center(child: Text('暂无日志')) : ListView(children: _logs.map(Text.new).toList())),
    actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭'))],
  ));

  void _checkUpdate() => _toast('当前已是最新版本');
  void _showAbout(BuildContext context) => _simpleDialog(context, '关于宏曦聚合', <Widget>[
    const ListTile(title: Text('宏曦聚合'), subtitle: Text('Miru 风格视频、漫画、小说、音乐聚合应用')),
    const ListTile(title: Text('版本'), trailing: Text('1.0.0')),
    const ListTile(title: Text('包名'), trailing: Text('juhe.homes.app2026')),
  ]);

  void _simpleDialog(BuildContext context, String title, List<Widget> children) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(title: Text(title), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: children)), actions: <Widget>[
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
    ]),
  );

  String _typeName(ContentType type) {
    switch (type) {
      case ContentType.video: return '视频';
      case ContentType.comic: return '漫画';
      case ContentType.novel: return '小说';
      case ContentType.music: return '音乐';
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _SourceManagerSheet extends StatelessWidget {
  final VoidCallback onChanged;
  const _SourceManagerSheet({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .75,
        child: Column(children: <Widget>[
          const Padding(padding: EdgeInsets.all(16), child: Text('源管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          Expanded(child: ListView.builder(
            itemCount: provider.sources.length,
            itemBuilder: (_, index) {
              final source = provider.sources[index];
              return ListTile(
                leading: Icon(source.type == ContentType.video ? Icons.movie_outlined : source.type == ContentType.comic ? Icons.auto_stories_outlined : source.type == ContentType.novel ? Icons.menu_book_outlined : Icons.music_note_outlined),
                title: Text(source.name),
                subtitle: Text('${source.type.name} · ${source.api}', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Switch(value: source.enabled, onChanged: (_) { provider.toggleSource(source); onChanged(); }),
              );
            },
          )),
        ]),
      ),
    );
  }
}
