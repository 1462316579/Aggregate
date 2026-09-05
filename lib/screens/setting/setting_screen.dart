/// 亦搜风格设置页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_source.dart';
import '../../services/app_config.dart';
import '../../services/source_import_export.dart';
import 'webdav_screen.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // 源管理
          _buildSectionTitle('视频源管理'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                for (var source in provider.sources)
                  _buildSourceTile(provider, source),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('添加源'),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _showAddSourceDialog(context, provider),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('刷新配置'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => _showRefreshDialog(context, provider),
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_upload, size: 16),
                      label: const Text('导入配置'),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () => SourceImportExport.showImportDialog(context, (sources) async {
                        await provider.addSources(sources);
                      }),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_download, size: 16),
                      label: const Text('导出配置'),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      onPressed: () async {
                        final path = await SourceImportExport.exportToFile(provider.sources);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('已导出: $path')));
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('复制配置到剪贴板'),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    onPressed: () async {
                      await SourceImportExport.copyToClipboard(provider.sources);
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('配置已复制')));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 播放设置
          _buildSectionTitle('播放设置'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('自动连播', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('播完自动播放下一集', style: TextStyle(fontSize: 12)),
                  value: true, onChanged: (v) {},
                  activeColor: const Color(0xFF2196F3),
                ),
                SwitchListTile(
                  title: const Text('记录播放进度', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('自动恢复上次播放位置', style: TextStyle(fontSize: 12)),
                  value: true, onChanged: (v) {},
                  activeColor: const Color(0xFF2196F3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 插件运行环境
          _buildSectionTitle('插件运行环境'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _envTile(Icons.javascript, 'JavaScript 引擎', 'flutter_js — 已内置', true, null),
                _envTile(Icons.code, 'Python 运行时', '通过 HTTP 桥执行', false, null),
                _envTile(Icons.code, 'PHP WASM', '通过 WebAssembly 执行', false, null),
                _envTile(Icons.code, 'Go WASM', '通过 WebAssembly 执行', false, null),
                _envTile(Icons.code, 'Java 引擎', '仅 Android 平台', false, null),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 数据管理
          _buildSectionTitle('数据管理'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud, color: Color(0xFF2196F3), size: 22),
                  title: const Text('WebDAV 备份', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('同步配置到云端 (兼容 ZYFun/亦搜)', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const WebDavScreen())),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                  title: const Text('清除历史记录', style: TextStyle(fontSize: 15)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  onTap: () async {
                    await AppConfig.clearHistory();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已清除')));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 关于
          _buildSectionTitle('关于'),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  title: const Text('AllPlay', style: TextStyle(fontSize: 15)),
                  subtitle: const Text('v1.0.0 全平台影视聚合播放器',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Text(title, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
    );
  }

  Widget _buildSourceTile(SourceProvider provider, VideoSource source) {
    final isActive = source.key == provider.activeSource?.key;
    return ListTile(
      leading: Icon(
        isActive ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isActive ? const Color(0xFF2196F3) : Colors.grey,
        size: 20,
      ),
      title: Text(source.name, style: TextStyle(
          fontSize: 15, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      subtitle: Text(source.api, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: source.type == 4 ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(source.type == 4 ? '直播' : source.mediaType,
                style: TextStyle(fontSize: 10, color: source.type == 4 ? Colors.orange : Colors.blue)),
          ),
          if (!source.isBuiltIn)
            IconButton(
              icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey[400]),
              onPressed: () => _confirmDelete(context, provider, source),
            ),
        ],
      ),
      onTap: () => provider.setActiveSource(source),
    );
  }

  Widget _envTile(IconData icon, String title, String note, bool available, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: available ? Colors.green : Colors.grey, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(note, style: TextStyle(fontSize: 12,
          color: available ? Colors.green : Colors.orange)),
      trailing: Icon(
        available ? Icons.check_circle : Icons.info_outline,
        color: available ? Colors.green : Colors.grey,
        size: 18,
      ),
      onTap: onTap,
    );
  }

  void _showAddSourceDialog(BuildContext context, SourceProvider provider) {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('添加视频源'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称', hintText: '例: 我的源')),
        const SizedBox(height: 12),
        TextField(controller: urlCtrl, decoration: const InputDecoration(labelText: 'API 地址')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
          onPressed: () async {
            if (nameCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
              await provider.addSource(VideoSource(
                key: nameCtrl.text, name: nameCtrl.text, api: urlCtrl.text));
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
          child: const Text('添加'),
        ),
      ],
    ));
  }

  void _showRefreshDialog(BuildContext context, SourceProvider provider) {
    final ctrl = TextEditingController(text: AppConfig.defaultConfigUrl);
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('刷新在线配置'),
      content: TextField(controller: ctrl, maxLines: 3,
          decoration: const InputDecoration(labelText: '配置 URL')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            await provider.refreshFromConfig(ctrl.text);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.error ?? '配置已刷新')));
          },
          child: const Text('刷新'),
        ),
      ],
    ));
  }

  void _confirmDelete(BuildContext ctx, SourceProvider provider, VideoSource source) {
    showDialog(context: ctx, builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('确认删除'),
      content: Text('确定要删除「${source.name}」吗？'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
          onPressed: () { provider.removeSource(source.key); Navigator.pop(d); },
          child: const Text('删除'),
        ),
      ],
    ));
  }
}
