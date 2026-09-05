/// WebDAV 设置 + 备份管理页面
import 'package:flutter/material.dart';
import '../services/webdav_service.dart';
import '../services/source_import_export.dart';
import '../services/app_config.dart';
import '../models/video_source.dart';
import 'package:provider/provider.dart';
import '../providers/source_provider.dart';

class WebDavScreen extends StatefulWidget {
  const WebDavScreen({super.key});
  @override
  State<WebDavScreen> createState() => _WebDavScreenState();
}

class _WebDavScreenState extends State<WebDavScreen> {
  final _webdav = WebDavService();
  final _hostCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pathCtrl = TextEditingController(text: '/AllPlay/');
  bool _isLoading = false;
  List<WebDavBackupInfo> _backups = [];

  @override
  void initState() {
    super.initState();
    _webdav.init().then((_) {
      setState(() {
        _hostCtrl.text = _webdav.host;
        _isConnected = _webdav.isConnected;
      });
      if (_isConnected) _loadBackups();
    });
  }

  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 备份')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 连接状态
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isConnected
                  ? const Color(0xFF4CAF50).withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isConnected ? const Color(0xFF4CAF50) : Colors.orange,
                width: 1)),
            child: Row(
              children: [
                Icon(
                  _isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: _isConnected ? const Color(0xFF4CAF50) : Colors.orange,
                  size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isConnected ? '已连接' : '未连接',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    if (_isConnected)
                      Text(_hostCtrl.text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // WebDAV 配置
          const Text('服务器配置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildField('服务器地址', _hostCtrl, 'https://dav.example.com'),
          _buildField('用户名', _userCtrl, 'username'),
          _buildField('密码', _passCtrl, 'password', isPassword: true),
          _buildField('远程路径', _pathCtrl, '/AllPlay/'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _testConnection,
                  child: const Text('测试连接'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white),
                  onPressed: _saveConnection,
                  child: const Text('保存配置'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 备份操作
          if (_isConnected) ...[
            const Text('数据备份', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    Icons.cloud_upload, '备份数据', '上传到 WebDAV',
                    const Color(0xFF2196F3), _backup),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    Icons.cloud_download, '恢复数据', '从 WebDAV 下载',
                    const Color(0xFF4CAF50), _restore),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _actionCard(
                    Icons.file_download_outlined, '导出文件', '保存到本地',
                    Colors.orange, _exportToFile),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionCard(
                    Icons.file_upload_outlined, '导入文件', '从本地加载',
                    Colors.purple, _importFromFile),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 备份列表
            Row(
              children: [
                const Text('备份列表', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('刷新'),
                  onPressed: _loadBackups,
                ),
              ],
            ),
            if (_isLoading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator()))
            else if (_backups.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('暂无备份', style: TextStyle(color: Colors.grey[500])),
                ))
            else
              ..._backups.map((b) => ListTile(
                leading: const Icon(Icons.backup, color: Color(0xFF2196F3)),
                title: Text(b.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(b.time.toString().substring(0, 19),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteBackup(b)),
              )),
          ],
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: ctrl,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label, hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          isDense: true,
        ),
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    await _webdav.saveConfig(
      host: _hostCtrl.text, username: _userCtrl.text,
      password: _passCtrl.text, remotePath: _pathCtrl.text);
    final ok = await _webdav.testConnection();
    setState(() { _isLoading = false; _isConnected = ok; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? '连接成功' : '连接失败')));
  }

  void _saveConnection() async {
    await _webdav.saveConfig(
      host: _hostCtrl.text, username: _userCtrl.text,
      password: _passCtrl.text, remotePath: _pathCtrl.text);
    setState(() => _isConnected = true);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')));
  }

  Future<void> _backup() async {
    setState(() => _isLoading = true);
    final result = await _webdav.backup();
    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message),
            backgroundColor: result.success ? null : Colors.red));
    }
    _loadBackups();
  }

  Future<void> _restore() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('确认恢复'),
        content: const Text('恢复将覆盖当前所有数据，确定继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    final result = await _webdav.restore();
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message),
          backgroundColor: result.success ? null : Colors.red));
  }

  Future<void> _exportToFile() async {
    final provider = context.read<SourceProvider>();
    final path = await SourceImportExport.exportToFile(provider.sources);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导出: $path')));
  }

  void _importFromFile() {
    SourceImportExport.showImportDialog(context, (sources) async {
      final provider = context.read<SourceProvider>();
      await provider.addSources(sources);
    });
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    _backups = await _webdav.getBackupList();
    setState(() => _isLoading = false);
  }

  void _deleteBackup(WebDavBackupInfo backup) async {
    await _webdav.deleteBackup(backup.filename);
    _loadBackups();
  }
}
