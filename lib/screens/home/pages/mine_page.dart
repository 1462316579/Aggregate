/// 亦搜风格「我的」页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/source_provider.dart';
import '../../../services/app_config.dart';
import '../../detail/detail_screen.dart';
import '../../setting/setting_screen.dart';
import '../../sniffer/sniffer_screen.dart';
import '../../plugin_store/plugin_store_screen.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});
  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final h = await AppConfig.getHistory();
    final f = await AppConfig.getFavorites();
    setState(() { _history = h; _favorites = f; });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();

    return ListView(
      children: [
        // 用户头部
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          color: Colors.white,
          child: Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF2196F3), size: 36),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AllPlay 用户', style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Text('当前源: ${provider.activeSource?.name ?? "未选择"}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 功能列表
        _buildSection('功能', [
          _menuItem(Icons.radar, '影视嗅探', '嗅探网页中的视频资源', Colors.orange, () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SnifferScreen()))),
          _menuItem(Icons.extension, '插件中心', 'JS/Python/PHP/Go/Java 插件', Colors.purple, () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PluginStoreScreen()))),
          _menuItem(Icons.settings, '设置', '源管理、主题、播放设置', Colors.grey, () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingScreen()))),
        ]),

        _buildSection('数据', [
          _menuItem(Icons.history, '观看历史', '${_history.length} 条记录', Colors.blue, () {}),
          _menuItem(Icons.favorite, '我的收藏', '${_favorites.length} 个内容', Colors.red, () {}),
        ]),

        // 历史记录预览
        if (_history.isNotEmpty)
          _buildSection('最近观看', _history.take(5).map((item) =>
            ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(item['pic'] ?? '', width: 48, height: 36, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 48, height: 36, color: Colors.grey[200],
                    child: const Icon(Icons.movie, size: 16, color: Colors.grey))),
              ),
              title: Text(item['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(item['episodeName'] ?? '', maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              trailing: const Icon(Icons.play_circle_outline, size: 20, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ).toList()),

        const SizedBox(height: 20),
        // 版本信息
        Center(
          child: Text('AllPlay v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
    );
  }
}
