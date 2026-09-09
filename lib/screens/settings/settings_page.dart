import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/content.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
import '../../services/webdav_service.dart';
import '../../services/config_transfer_service.dart';

/// Settings page with expandable groups and runtime language support.
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
  bool _saveLog = false;
  String _languageCode = 'zh';
  String _themeCode = 'system';
  String _readerModeCode = 'standard';
  String _proxyType = 'DIRECT';
  String _proxy = '';
  String _userAgent = '';
  String _tmdbKey = '';
  String _webdavHost = '';
  String _webdavUsername = '';
  String _webdavPassword = '';
  String _webdavPath = '/';
  bool _webdavEnabled = false;
  String _aiConfigName = '';
  String _aiApiUrl = '';
  String _aiApiKey = '';
  String _aiModel = 'gpt-3.5-turbo';
  String _pluginRepositoryUrl = '';
  final List<String> _logs = <String>[];

  @override
  void initState() {
    super.initState();
    _tmdbKey = AppConfig.tmdbKey;
    _languageCode = AppConfig.language;
    _themeCode = AppConfig.theme;
    _autoCheckUpdate = AppConfig.autoCheckUpdate;
    _nsfw = AppConfig.nsfw;
    _webdavHost = AppConfig.webdavHost;
    _webdavUsername = AppConfig.webdavUsername;
    _webdavPath = AppConfig.webdavPath;
    _webdavEnabled = AppConfig.webdavEnabled;
    _aiConfigName = AppConfig.aiConfigName;
    _aiApiUrl = AppConfig.aiApiUrl;
    _aiApiKey = AppConfig.aiApiKey;
    _aiModel = AppConfig.aiModel;
    _pluginRepositoryUrl = AppConfig.pluginRepositoryUrl;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppConfig.languageNotifier,
      builder: (context, language, _) {
        final s = AppStrings.of(language);
        return Scaffold(
          appBar: AppBar(title: Text(s.t('settings'))),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: <Widget>[
              _group(s, Icons.tune, 'general', 'generalSubtitle', <Widget>[
                _asyncInputTile(s.t('tmdbKey'), _maskedKey(s), () => _tmdbDialog(context, s)),
                _radioTile(s.t('language'), _languageLabel(s), _languageOptions().keys.toList(), (value) async {
                  setState(() => _languageCode = value);
                  await AppConfig.setLanguage(value);
                }, labels: _languageOptions()),
                _radioTile(s.t('theme'), _themeLabel(s), _themeOptions(s).keys.toList(), (value) async {
                  setState(() => _themeCode = value);
                  await AppConfig.setTheme(value);
                }, labels: _themeOptions(s)),
                _switchTile(s.t('autoCheckUpdate'), s.t('autoCheckUpdateSubtitle'), _autoCheckUpdate, (value) async {
                  setState(() => _autoCheckUpdate = value);
                  await AppConfig.setAutoCheckUpdate(value);
                }),
                _switchTile(s.t('nsfw'), s.t('nsfwSubtitle'), _nsfw, (value) async {
                  setState(() => _nsfw = value);
                  await AppConfig.setNsfw(value);
                }),
              ]),
              _group(s, Icons.play_circle_outline, 'videoPlayer', 'videoPlayerSubtitle', <Widget>[
                _radioTile(s.t('externalPlayer'), _externalPlayerLabel(s), <String>['builtin', 'vlc', 'mpv', 'potplayer'], (value) {
                  setState(() => _externalPlayerCode = value);
                }, labels: <String, String>{
                  'builtin': s.t('builtinPlayer'), 'vlc': 'VLC', 'mpv': 'mpv', 'potplayer': 'PotPlayer',
                }),
                _switchTile(s.t('autoPlay'), s.t('autoPlaySubtitle'), _autoPlay, (value) => setState(() => _autoPlay = value)),
                _switchTile(s.t('rememberPosition'), s.t('rememberPositionSubtitle'), _rememberPosition, (value) => setState(() => _rememberPosition = value)),
                _switchTile(s.t('hardwareDecode'), s.t('hardwareDecodeSubtitle'), _hardwareDecode, (value) => setState(() => _hardwareDecode = value)),
                _itemTile(Icons.skip_next, s.t('skipInterval'), '${s.t('skipIntervalSubtitle')} · 10s', () => _toast(s.t('skipInterval'))),
              ]),
              _group(s, Icons.auto_stories_outlined, 'reader', 'readerSubtitle', <Widget>[
                _radioTile(s.t('readerMode'), _readerModeLabel(s), <String>['standard', 'leftRight', 'upDown'], (value) => setState(() => _readerModeCode = value), labels: <String, String>{
                  'standard': s.t('standard'), 'leftRight': s.t('leftRight'), 'upDown': s.t('upDown'),
                }),
                _switchTile(s.t('preload'), s.t('preloadSubtitle'), true, (_) {}),
                _radioTile(s.t('imageFit'), s.t('width'), <String>['width', 'height', 'original'], (value) {}, labels: <String, String>{
                  'width': s.t('width'), 'height': s.t('height'), 'original': s.t('original'),
                }),
                _radioTile(s.t('volumeTurning'), s.t('enabled'), <String>['enabled', 'disabled'], (value) {}, labels: <String, String>{
                  'enabled': s.t('enabled'), 'disabled': s.t('disabled'),
                }),
              ]),
              _group(s, Icons.network_check, 'network', 'networkSubtitle', <Widget>[
                _asyncInputTile(s.t('userAgent'), _userAgent.isEmpty ? s.t('defaultSystem') : _userAgent, () => _textDialog(s.t('userAgent'), _userAgent, false)),
                _radioTile(s.t('proxyType'), _proxyTypeLabel(s), <String>['DIRECT', 'HTTP', 'SOCKS4', 'SOCKS5'], (value) => setState(() => _proxyType = value), labels: <String, String>{
                  'DIRECT': s.t('direct'), 'HTTP': s.t('http'), 'SOCKS4': s.t('socks4'), 'SOCKS5': s.t('socks5'),
                }),
                _asyncInputTile(s.t('proxyAddress'), _proxy.isEmpty ? s.t('notSet') : _proxy, () => _textDialog(s.t('proxyAddress'), _proxy, true)),
                _itemTile(Icons.dns_outlined, s.t('connectionTest'), s.t('connectionTestSubtitle'), _testNetwork),
              ]),
              _group(s, Icons.article_outlined, 'logs', 'logsSubtitle', <Widget>[
                _switchTile(s.t('saveLog'), s.t('saveLogSubtitle'), _saveLog, (value) => setState(() => _saveLog = value)),
                _itemTile(Icons.ios_share, s.t('exportLog'), '${_logs.length}', () => _toast(s.t('exportLog'))),
                _itemTile(Icons.delete_sweep_outlined, s.t('clearLog'), s.t('clearLog'), () { setState(() => _logs.clear()); _toast(s.t('clearLog')); }),
              ]),
              _group(s, Icons.cloud_outlined, 'webdav', 'webdavSubtitle', <Widget>[
                _switchTile(s.t('webdavEnable'), s.t('webdavEnableSubtitle'), _webdavEnabled, (value) async {
                  setState(() => _webdavEnabled = value);
                  await AppConfig.setWebdavEnabled(value);
                }),
                if (_webdavEnabled) ...<Widget>[
                  _asyncInputTile(s.t('webdavHost'), _webdavHost.isEmpty ? s.t('notSet') : _webdavHost, () => _textDialog(s.t('webdavHost'), _webdavHost, false)),
                  _asyncInputTile(s.t('webdavUsername'), _webdavUsername.isEmpty ? s.t('notSet') : _webdavUsername, () => _textDialog(s.t('webdavUsername'), _webdavUsername, false)),
                  _asyncInputTile(s.t('webdavPassword'), s.t('passwordSet'), () => _textDialog(s.t('webdavPassword'), _webdavPassword, true)),
                  _asyncInputTile(s.t('webdavPath'), _webdavPath.isEmpty ? '/' : _webdavPath, () => _textDialog(s.t('webdavPath'), _webdavPath, false)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      FilledButton.icon(
                        onPressed: () => _pingWebdav(context, s),
                        icon: const Icon(Icons.cloud_queue_outlined, size: 18),
                        label: Text(s.t('webdavPing')),
                      ),
                      FilledButton.icon(
                        onPressed: () => _backupWebdav(context, s),
                        icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                        label: Text(s.t('webdavBackup')),
                      ),
                      FilledButton.icon(
                        onPressed: () => _restoreWebdav(context, s),
                        icon: const Icon(Icons.cloud_download_outlined, size: 18),
                        label: Text(s.t('webdavRestore')),
                      ),
                    ],
                  ),
                ],
              ]),
              _group(s, Icons.psychology_outlined, 'ai', 'aiSubtitle', <Widget>[
                _asyncInputTile(s.t('aiConfigName'), _aiConfigName.isEmpty ? s.t('notSet') : _aiConfigName, () => _textDialog(s.t('aiConfigName'), _aiConfigName, false)),
                _asyncInputTile(s.t('aiApiUrl'), _aiApiUrl.isEmpty ? s.t('notSet') : _aiApiUrl, () => _textDialog(s.t('aiApiUrl'), _aiApiUrl, false)),
                _asyncInputTile(s.t('aiApiKey'), s.t('passwordSet'), () => _textDialog(s.t('aiApiKey'), _aiApiKey, true)),
                _radioTile(s.t('aiModel'), _aiModel, <String>['gpt-3.5-turbo', 'gpt-4', 'gpt-4o'], (value) => setState(() => _aiModel = value), labels: <String, String>{
                  'gpt-3.5-turbo': s.t('gpt-3.5-turbo'), 'gpt-4': s.t('gpt-4'), 'gpt-4o': s.t('gpt-4o'),
                }),
              ]),
              _group(s, Icons.extension, 'plugin', 'pluginSubtitle', <Widget>[
                _asyncInputTile(s.t('pluginRepositoryUrl'), _pluginRepositoryUrl.isEmpty ? s.t('notSet') : _pluginRepositoryUrl, () async {
                  await _textDialog(s.t('pluginRepositoryUrl'), _pluginRepositoryUrl, false);
                  if (mounted) setState(() {});
                }),
              ]),
              _group(s, Icons.info_outline, 'about', 'aboutSubtitle', <Widget>[
                _itemTile(Icons.system_update, s.t('checkUpdate'), s.t('latest'), () => _checkUpdate()),
              ], initiallyExpanded: true),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  String _externalPlayerCode = 'builtin';

  Widget _group(AppStrings s, IconData icon, String titleKey, String subtitleKey, List<Widget> children, {bool initiallyExpanded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          leading: Icon(icon),
          title: Text(s.t(titleKey), style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(s.t(subtitleKey)),
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

  Widget _asyncInputTile(String title, String subtitle, {required bool saveProxy}) => ListTile(
    title: Text(title), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () => _textDialog(title, subtitle, saveProxy),
  );

  Widget _radioTile(String title, String current, List<String> values, ValueChanged<String> onChanged, {Map<String, String>? labels}) => ListTile(
    title: Text(title), subtitle: Text(current), trailing: const Icon(Icons.chevron_right),
    onTap: () => _radioDialog(title, current, values, onChanged, labels: labels),
  );

  String _maskedKey(AppStrings s) {
    if (_tmdbKey.isEmpty) return s.t('unset');
    return List<String>.filled(_tmdbKey.length.clamp(4, 24), '•').join();
  }

  Map<String, String> _languageOptions() => <String, String>{
    'zh': '简体中文', 'zhHant': '繁體中文', 'en': 'English', 'ja': '日本語', 'ko': '한국어', 'bo': 'བོད་ཡིག', 'yue': '廣東話',
  };

  String _languageLabel(AppStrings s) => _languageOptions()[_languageCode] ?? s.t('unset');

  Map<String, String> _themeOptions(AppStrings s) => <String, String>{
    'system': s.t('themeSystem'), 'light': s.t('themeLight'), 'dark': s.t('themeDark'), 'black': s.t('themeBlack'),
  };

  String _themeLabel(AppStrings s) => _themeOptions(s)[_themeCode] ?? s.t('themeSystem');
  String _readerModeLabel(AppStrings s) => <String, String>{'standard': s.t('standard'), 'leftRight': s.t('leftRight'), 'upDown': s.t('upDown')}[_readerModeCode] ?? s.t('standard');
  String _externalPlayerLabel(AppStrings s) => <String, String>{'builtin': s.t('builtinPlayer'), 'vlc': 'VLC', 'mpv': 'mpv', 'potplayer': 'PotPlayer'}[_externalPlayerCode] ?? s.t('builtinPlayer');
  String _proxyTypeLabel(AppStrings s) => <String, String>{'DIRECT': s.t('direct'), 'HTTP': s.t('http'), 'SOCKS4': s.t('socks4'), 'SOCKS5': s.t('socks5')}[_proxyType] ?? _proxyType;

  void _radioDialog(String title, String currentValue, List<String> values, ValueChanged<String> onChanged, {Map<String, String>? labels}) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(mainAxisSize: MainAxisSize.min, children: values.map((value) => RadioListTile<String>(
          title: Text(labels?[value] ?? value), value: value, groupValue: currentValue,
          onChanged: (selected) { if (selected != null) { Navigator.pop(ctx); onChanged(selected); } },
        )).toList()),
      ),
    );
  }

  void _tmdbDialog(BuildContext context, AppStrings s) {
    final controller = TextEditingController(text: _tmdbKey);
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(s.t('tmdbKey')),
      content: TextField(controller: controller, obscureText: true, decoration: InputDecoration(hintText: s.t('tmdbHint'))),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.t('cancel'))),
        FilledButton(onPressed: () async { final value = controller.text.trim(); await AppConfig.setTmdbKey(value); if (mounted) setState(() => _tmdbKey = value); if (ctx.mounted) Navigator.pop(ctx); }, child: Text(s.t('save'))),
      ],
    ));
  }

  Future<void> _textDialog(String title, String value, bool saveProxy) async {
    final controller = TextEditingController(text: value);
    showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: Text(title), content: TextField(controller: controller),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () async {
          final text = controller.text.trim();
          setState(() {
            // 根据标题判断保存位置
            if (title == AppStrings.of(AppConfig.language).t('pluginRepositoryUrl')) {
              _pluginRepositoryUrl = text;
              AppConfig.setPluginRepositoryUrl(text); // fire-and-forget
            } else if (saveProxy) {
              _proxy = text;
            } else {
              _userAgent = text;
            }
          });
          Navigator.pop(ctx);
        }, child: const Text('保存')),
      ],
    ));
  }

  Future<void> _importSources() async {
    final controller = TextEditingController();
    await showDialog<void>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('导入源配置'),
      content: TextField(controller: controller, maxLines: 8, decoration: const InputDecoration(hintText: '{"sites": [...]}')),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        FilledButton(onPressed: () { try { final values = ConfigTransferService.importSources(controller.text); context.read<SourceProvider>().addSources(values); Navigator.pop(ctx); _toast('已导入 ${values.length} 个源'); } catch (_) { _toast('JSON 格式错误'); } }, child: const Text('导入')),
      ],
    ));
  }

  Future<void> _exportSources() async {
    await Clipboard.setData(ClipboardData(text: ConfigTransferService.exportSources(context.read<SourceProvider>().sources)));
    _toast('配置已复制到剪贴板');
  }

  Future<void> _pingWebdav(BuildContext context, AppStrings s) async {
    if (_webdavHost.isEmpty) { _toast(s.t('notSet')); return; }
    setState(() => _logs.add('${DateTime.now()}: webdav ping...'));
    final service = WebDavService(
      baseUrl: _webdavHost,
      username: _webdavUsername,
      password: _webdavPassword,
      rootPath: _webdavPath,
    );
    try {
      final ok = await service.ping();
      if (ok) _toast(s.t('webdavConnected'));
      else _toast(s.t('webdavError'));
    } catch (_) {
      _toast(s.t('webdavError'));
    } finally {
      setState(() => _logs.add('${DateTime.now()}: done'));
    }
  }

  Future<void> _backupWebdav(BuildContext context, AppStrings s) async {
    if (_webdavEnabled && _webdavHost.isEmpty) { _toast(s.t('notSet')); return; }
    final filename = 'hongxi-backup-${DateTime.now().millisecondsSinceEpoch}.json';
    _toast(s.t('webdavBackingUp'));
    final service = WebDavService(
      baseUrl: _webdavHost,
      username: _webdavUsername,
      password: _webdavPassword,
      rootPath: _webdavPath,
    );
    final backup = BackupService(AppConfig(), context.read<SourceProvider>().sources);
    try {
      await backup.backupTo(filename, service);
      _toast(s.t('webdavBackupSuccess'));
    } catch (e) {
      _toast(e.toString());
    }
  }

  Future<void> _restoreWebdav(BuildContext context, AppStrings s) async {
    if (_webdavEnabled && _webdavHost.isEmpty) { _toast(s.t('notSet')); return; }
    _dialogShowConfirmation(s.t('confirm'), s.t('webdavRestoreConfirm'), () async {
      final filename = await _pickBackupFile(context);
      if (filename == null) return;
      _toast(s.t('webdavRestoring'));
      final service = WebDavService(
        baseUrl: _webdavHost,
        username: _webdavUsername,
        password: _webdavPassword,
        rootPath: _webdavPath,
      );
      final backup = BackupService(AppConfig(), context.read<SourceProvider>().sources);
      try {
        await backup.restoreFrom(filename, service);
        _toast(s.t('webdavRestoreSuccess'));
        // 刷新设置页
        if (mounted) setState(() {});
      } catch (e) {
        _toast(e.toString());
      }
    });
  }

  Future<String?> _pickBackupFile(BuildContext context) async {
    return showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(AppConfig.language).t('webdavPickFile')),
        content: SizedBox(
          width: double.minPositive,
          child: FutureBuilder<List<String>>(
            future: _listBackups(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final files = snapshot.data ?? <String>[];
              if (files.isEmpty) {
                return Text(AppStrings.of(AppConfig.language).t('webdavNoFiles'));
              }
              return ListView(
                shrinkWrap: true,
                children: files.map((f) => ListTile(
                  title: Text(f),
                  onTap: () => Navigator.pop<String>(ctx, f),
                )).toList(),
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop<String>(ctx, null), child: const Text('取消')),
        ],
      ),
    );
  }

  Future<List<String>> _listBackups() async {
    final service = WebDavService(
      baseUrl: _webdavHost,
      username: _webdavUsername,
      password: _webdavPassword,
      rootPath: _webdavPath,
    );
    return await service.listBackups();
  }

  Future<void> _dialogShowConfirmation(String title, String message, VoidCallback onConfirm) async {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _testNetwork() async {
    setState(() => _logs.add('${DateTime.now()}: network test'));
    _toast('网络测试完成');
  }

  void _checkUpdate() => _toast(AppStrings.of(AppConfig.language).t('latest'));
  void _toast(String value) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
}
