import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/content.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
import '../../services/config_transfer_service.dart';

/// Miru 风格设置页：使用可展开分组，而不是把所有开关平铺。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoCheckUpdate = true;
  bool _nsfw = false;
  bool _autoPlay = true;
  bool _rememberPosition = true;
  bool _hardwareDecode = true;
  bool _tracking = false;
  bool _saveLog = false;
  String _language = '简体中文';
  String _theme = '跟随系统';
  String _readerMode = '标准';
  String _externalPlayer = '内置播放器';
  String _proxyType = 'DIRECT';
  String _proxy = '';
  String _userAgent = '';
  final List<String> _logs = <String>[];
  String _tmdbKey = '';

  @override
  void initState() {
    super.initState();
    _tmdbKey = AppConfig.tmdbKey;
    _language = _languageLabel(AppConfig.language);
    _theme = _themeLabel(AppConfig.theme);
    _autoCheckUpdate = AppConfig.autoCheckUpdate;
    _nsfw = AppConfig.nsfw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: <Widget>[
          _expandGroup(
            icon: Icons.tune,
            title: '常规',
            subtitle: 'TMDB、语言、主题和启动行为',
            children: <Widget>[
              _inputTile('TMDB API Key', _maskedKey(), () => _tmdbDialog(context)),
              _radioTile('语言', _language, <String>['简体中文', '繁體中文', 'English'], (v) {
                setState(() => _language = v);
                AppConfig.setLanguage(_languageCode(v));
              }),
              _radioTile('主题', _theme, <String>['跟随系统', '浅色', '深色', '纯黑'], (v) {
                setState(() => _theme = v);
                AppConfig.setTheme(_themeCode(v));
              }),
              _switchTile('启动时检查更新', '应用启动时检查新版本', _autoCheckUpdate, (v) {
                setState(() => _autoCheckUpdate = v);
                AppConfig.setAutoCheckUpdate(v);
              }),
              _switchTile('显示成人内容', '允许扩展返回成人内容', _nsfw, (v) {
                setState(() => _nsfw = v);
                AppConfig.setNsfw(v);
              }),
            ],
          ),
          _expandGroup(
            icon: Icons.extension_outlined,
            title: '扩展',
            subtitle: '扩展仓库和本地插件',
            children: <Widget>[
              _inputTile('扩展仓库地址', '在插件页管理仓库', () => _toast('请到“插件”页的“扩展仓库”管理')),
              _itemTile(Icons.extension, '已安装插件', '打开插件中心编辑、调试和删除插件', () => _toast('请点击底部“插件”页面')),
              _itemTile(Icons.upload_file, '导入源配置', 'TVBox / HongXi JSON', _importSources),
              _itemTile(Icons.download, '导出源配置', '复制当前源配置', _exportSources),
            ],
          ),
          _expandGroup(
            icon: Icons.play_circle_outline,
            title: '视频播放器',
            subtitle: '播放引擎、外部播放器和快捷键',
            children: <Widget>[
              _itemTile(Icons.cloud_queue, 'BT 服务器', 'BT 播放服务管理', () => _toast('BT 服务器配置入口')),
              _radioTile('外部播放器', _externalPlayer, <String>['内置播放器', 'VLC', 'mpv', 'PotPlayer'], (v) => setState(() => _externalPlayer = v)),
              _switchTile('自动连播', '播放结束后播放下一集', _autoPlay, (v) => setState(() => _autoPlay = v)),
              _switchTile('记忆播放位置', '恢复上次播放进度', _rememberPosition, (v) => setState(() => _rememberPosition = v)),
              _switchTile('硬件解码', '优先使用硬件解码', _hardwareDecode, (v) => setState(() => _hardwareDecode = v)),
              _numberTile('跳过间隔', '左/右方向键跳过秒数', 10, () => _toast('跳过间隔已设置')),
            ],
          ),
          _expandGroup(
            icon: Icons.auto_stories_outlined,
            title: '漫画阅读器',
            subtitle: '阅读模式和图片显示',
            children: <Widget>[
              _radioTile('默认阅读模式', _readerMode, <String>['标准', '从右到左', 'Webtoon'], (v) => setState(() => _readerMode = v)),
              _switchTile('预加载下一页', '提前加载下一张图片', true, (_) {}),
              _radioTile('图片适应', '宽度', <String>['宽度', '高度', '原图'], (_) {}),
              _radioTile('音量键翻页', '启用', <String>['启用', '禁用'], (_) {}),
            ],
          ),
          _expandGroup(
            icon: Icons.sync,
            title: '追踪',
            subtitle: 'AniList 等第三方进度同步',
            children: <Widget>[
              _switchTile('自动追踪', '自动同步观看和阅读进度', _tracking, (v) => setState(() => _tracking = v)),
              _itemTile(Icons.account_circle_outlined, 'AniList', '账号和同步设置', () => _toast('AniList 配置入口')),
            ],
          ),
          _expandGroup(
            icon: Icons.network_check,
            title: '网络',
            subtitle: 'User-Agent 和代理协议',
            children: <Widget>[
              _inputTile('User-Agent', _userAgent.isEmpty ? '系统默认' : _userAgent, () => _textDialog('User-Agent', '输入 User-Agent', true)),
              _radioTile('代理类型', _proxyType, <String>['DIRECT', 'HTTP', 'SOCKS4', 'SOCKS5'], (v) => setState(() => _proxyType = v)),
              _inputTile('代理地址', _proxy.isEmpty ? '未设置' : _proxy, () => _textDialog('代理地址', 'http://127.0.0.1:7890', true)),
            ],
          ),
          _expandGroup(
            icon: Icons.article_outlined,
            title: '日志',
            subtitle: '调试日志和扩展日志',
            children: <Widget>[
              _switchTile('保存日志', '保存应用运行日志', _saveLog, (v) => setState(() => _saveLog = v)),
              _itemTile(Icons.ios_share, '导出日志', '${_logs.length} 条日志', () => _toast('日志导出入口')),
              _switchTile('扩展日志', '显示扩展执行日志', true, (_) {}),
              _itemTile(Icons.delete_sweep_outlined, '清除日志', '删除本地日志', () { setState(() => _logs.clear()); _toast('日志已清除'); }),
            ],
          ),
          _expandGroup(
            icon: Icons.info_outline,
            title: '关于',
            subtitle: '版本、更新和开源信息',
            initiallyExpanded: true,
            children: <Widget>[
              _itemTile(Icons.system_update, '检查更新', '当前版本 v1.0.0', () => _toast('当前已是最新版本')),
              const ListTile(title: Text('宏曦聚合'), subtitle: Text('Miru 风格多媒体聚合应用')),
              const ListTile(title: Text('包名'), subtitle: Text('juhe.homes.app2026')),
              const ListTile(title: Text('许可'), subtitle: Text('开源项目，遵循仓库许可证')),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _expandGroup({required IconData icon, required String title, required String subtitle, required List<Widget> children, bool initiallyExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle),
          children: <Widget>[Padding(padding: const EdgeInsets.only(bottom: 8), child: Column(children: children))],
        ),
      ),
    );
  }

  Widget _itemTile(IconData icon, String title, String subtitle, VoidCallback onTap) => ListTile(
    leading: Icon(icon), title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap,
  );

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
    title: Text(title), subtitle: Text(subtitle), value: value, onChanged: onChanged,
  );

  Widget _inputTile(String title, String subtitle, VoidCallback onTap) => ListTile(
    title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right), onTap: onTap,
  );

  Widget _radioTile(String title, String current, List<String> values, ValueChanged<String> onChanged) => ListTile(
    title: Text(title), subtitle: Text(current), trailing: const Icon(Icons.chevron_right), onTap: () => _radioDialog(title, current, values, onChanged),
  );

  Widget _numberTile(String title, String subtitle, int value, VoidCallback onTap) => ListTile(
    title: Text(title), subtitle: Text('$subtitle · 当前 $value 秒'), trailing: const Icon(Icons.chevron_right), onTap: onTap,
  );

  String _maskedKey() {
    if (_tmdbKey.isEmpty) return '未设置';
    return List<String>.filled(_tmdbKey.length.clamp(4, 24), '•').join();
  }

  String _languageCode(String value) {
    switch (value) {
      case '繁體中文': return 'zhHant';
      case 'English': return 'en';
      default: return 'zh';
    }
  }

  String _languageLabel(String value) {
    switch (value) {
      case 'zhHant': return '繁體中文';
      case 'en': return 'English';
      default: return '简体中文';
    }
  }

  String _themeCode(String value) {
    switch (value) {
      case '浅色': return 'light';
      case '深色': return 'dark';
      case '纯黑': return 'black';
      default: return 'system';
    }
  }

  String _themeLabel(String value) {
    switch (value) {
      case 'light': return '浅色';
      case 'dark': return '深色';
      case 'black': return '纯黑';
      default: return '跟随系统';
    }
  }

  void _tmdbDialog(BuildContext context) {
    final controller = TextEditingController(text: _tmdbKey);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('TMDB API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: '输入 TMDB API Key'),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () async {
            final value = controller.text.trim();
            await AppConfig.setTmdbKey(value);
            if (mounted) setState(() => _tmdbKey = value);
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('保存')),
        ],
      ),
    );
  }

  void _radioDialog(String title, String current, List<String> values, ValueChanged<String> onChanged) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: values.map((value) => RadioListTile<String>(
          title: Text(value), value: value, groupValue: current, onChanged: (selected) { if (selected != null) { onChanged(selected); Navigator.pop(ctx); } },
        )).toList()),
      ),
    );
  }

  void _textDialog(String title, String hint, bool saveProxy) {
    final controller = TextEditingController(text: saveProxy ? _proxy : '');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(onPressed: () { if (saveProxy) setState(() => _proxy = controller.text.trim()); Navigator.pop(ctx); }, child: const Text('保存')),
        ],
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
          FilledButton(onPressed: () { try { final values = ConfigTransferService.importSources(controller.text); context.read<SourceProvider>().addSources(values); Navigator.pop(ctx); _toast('已导入 ${values.length} 个源'); } catch (_) { _toast('JSON 格式错误'); } }, child: const Text('导入')),
        ],
      ),
    );
  }

  Future<void> _exportSources() async {
    await Clipboard.setData(ClipboardData(text: ConfigTransferService.exportSources(context.read<SourceProvider>().sources)));
    _toast('配置已复制到剪贴板');
  }

  void _sourceManager() => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _SourceManagerSheet(onChanged: () => setState(() {})));

  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
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
          Expanded(child: ListView.builder(itemCount: provider.sources.length, itemBuilder: (_, index) {
            final source = provider.sources[index];
            return ListTile(
              leading: Icon(source.type == ContentType.video ? Icons.movie_outlined : source.type == ContentType.comic ? Icons.auto_stories_outlined : source.type == ContentType.novel ? Icons.menu_book_outlined : Icons.music_note_outlined),
              title: Text(source.name), subtitle: Text('${source.type.name} · ${source.api}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Switch(value: source.enabled, onChanged: (_) { provider.toggleSource(source); onChanged(); }),
            );
          })),
        ]),
      ),
    );
  }
}
