/// 更新页 — Animeko/Kazumi 风格: 显示有更新的内容
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/source_provider.dart';
import '../../models/unified_content.dart';
import '../../models/video_content.dart';
import '../../services/app_config.dart';
import '../../services/spider_service_v2.dart';
import '../detail/detail_screen.dart';
import '../comic/comic_detail_screen.dart';
import '../novel/novel_detail_screen.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});
  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  List<UpdateItem> _updates = [];
  bool _isLoading = true;
  String _filter = '全部';

  @override
  void initState() {
    super.initState();
    _loadUpdates();
  }

  Future<void> _loadUpdates() async {
    setState(() => _isLoading = true);

    // 从收藏的源获取最新更新
    final favorites = await AppConfig.getFavorites();
    final provider = context.read<SourceProvider>();
    List<UpdateItem> updates = [];

    for (var fav in favorites.take(10)) {
      try {
        final source = provider.sources.firstWhere(
          (s) => s.key == fav['sourceKey'],
          orElse: () => provider.activeSource!);
        final items = await SpiderServiceV2.getCategoryVideo(source, page: 1);
        for (var item in items.take(5)) {
          updates.add(UpdateItem(
            id: item.id, title: item.title, cover: item.cover,
            newChapter: item.remark ?? '更新', sourceKey: source.key,
            timestamp: DateTime.now(),
            type: source.mediaType,
          ));
        }
      } catch (_) {}
    }

    setState(() { _updates = updates; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == '全部'
        ? _updates
        : _updates.where((u) => u.type == _filter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('更新'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (f) => setState(() => _filter = f),
            itemBuilder: (_) => ['全部', 'video', 'comic', 'novel']
                .map((f) => PopupMenuItem(value: f, child: Text(
                    f == 'video' ? '视频' : f == 'comic' ? '漫画' : f == 'novel' ? '小说' : f)))
                .toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.update, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('暂无更新', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('收藏内容后会显示在这里',
                          style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                    ],
                  ))
              : RefreshIndicator(
                  onRefresh: _loadUpdates,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildUpdateCard(filtered[i]),
                  ),
                ),
    );
  }

  Widget _buildUpdateCard(UpdateItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _openItem(item),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: item.cover, width: 50, height: 66, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50, height: 66, color: Colors.grey[200],
                    child: const Icon(Icons.movie, color: Colors.grey, size: 20)),
                ),
              ),
              const SizedBox(width: 12),
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(item.type).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4)),
                        child: Text(_getTypeLabel(item.type), style: TextStyle(
                            fontSize: 10, color: _getTypeColor(item.type))),
                      ),
                      const SizedBox(width: 8),
                      Text(item.newChapter, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ]),
                    const SizedBox(height: 4),
                    Text(_formatTime(item.timestamp),
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _openItem(UpdateItem item) {
    final content = UnifiedContent(
      id: item.id, title: item.title, cover: item.cover,
      sourceKey: item.sourceKey, mediaType: MediaType.video);

    switch (item.type) {
      case 'comic':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailScreen(content: content)));
      case 'novel':
        Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailScreen(content: content)));
      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(
            video: VideoContent.fromJson({'vod_id': item.id, 'vod_name': item.title, 'vod_pic': item.cover}))));
    }
  }

  Color _getTypeColor(String type) => switch (type) {
    'comic' => const Color(0xFFFF9800),
    'novel' => const Color(0xFF4CAF50),
    _ => const Color(0xFF2196F3),
  };

  String _getTypeLabel(String type) => switch (type) {
    'comic' => '漫画',
    'novel' => '小说',
    _ => '视频',
  };

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }
}

class UpdateItem {
  final String id;
  final String title;
  final String cover;
  final String newChapter;
  final String sourceKey;
  final DateTime timestamp;
  final String type;

  UpdateItem({
    required this.id, required this.title, required this.cover,
    this.newChapter = '', required this.sourceKey,
    required this.timestamp, this.type = 'video',
  });
}
