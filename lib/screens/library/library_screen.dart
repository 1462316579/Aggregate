/// 书架页 — Venera/Mihon 风格: 分类 + 网格 + 排序 + 筛选
/// 收藏的漫画/小说/视频统一展示，支持分类标签和多种排序方式
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
import '../music/music_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _isLoading = true;
  bool _isGridMode = true;
  String _selectedCategory = '全部';
  SortMode _sortMode = SortMode.recent;
  MediaType? _typeFilter;

  final _categories = ['全部', '视频', '漫画', '小说', '音乐'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 书架 + 更新
    _loadLibrary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLibrary() async {
    final favorites = await AppConfig.getFavorites();
    final history = await AppConfig.getHistory();
    setState(() {
      _allItems = [...favorites, ...history];
      _allItems = _dedupeItems(_allItems);
      _filteredItems = _allItems;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _dedupeItems(List<Map<String, dynamic>> items) {
    final map = <String, Map<String, dynamic>>{};
    for (var item in items) {
      final key = '${item['id']}_${item['sourceKey'] ?? ''}';
      map[key] = item;
    }
    return map.values.toList();
  }

  void _applyFilter() {
    setState(() {
      _filteredItems = _allItems.where((item) {
        if (_typeFilter != null) {
          final type = item['mediaType'] ?? item['type'] ?? '';
          if (type != _typeFilter!.name) return false;
        }
        return true;
      }).toList();

      // 排序
      switch (_sortMode) {
        case SortMode.recent:
          _filteredItems.sort((a, b) =>
              (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
          break;
        case SortMode.name:
          _filteredItems.sort((a, b) =>
              (a['name'] ?? a['title'] ?? '').compareTo(b['name'] ?? b['title'] ?? ''));
          break;
        case SortMode.source:
          _filteredItems.sort((a, b) =>
              (a['sourceKey'] ?? '').compareTo(b['sourceKey'] ?? ''));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('书架'),
        actions: [
          // 排序
          PopupMenuButton<SortMode>(
            icon: const Icon(Icons.sort),
            onSelected: (mode) { _sortMode = mode; _applyFilter(); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: SortMode.recent, child: Text('最近更新')),
              const PopupMenuItem(value: SortMode.name, child: Text('名称排序')),
              const PopupMenuItem(value: SortMode.source, child: Text('来源排序')),
            ],
          ),
          // 布局切换
          IconButton(
            icon: Icon(_isGridMode ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridMode = !_isGridMode),
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类标签
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final sel = _categories[i] == _selectedCategory;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = _categories[i]);
                    _typeFilter = i == 0 ? null : MediaType.values[i - 1];
                    _applyFilter();
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2196F3) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                    alignment: Alignment.center,
                    child: Text(_categories[i], style: TextStyle(
                        color: sel ? Colors.white : Colors.grey[700], fontSize: 13,
                        fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              },
            ),
          ),
          // 数量
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('共 ${_filteredItems.length} 项', style: TextStyle(
                  fontSize: 12, color: Colors.grey[500])),
            ]),
          ),
          // 内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredItems.isEmpty
                    ? _buildEmpty()
                    : _isGridMode ? _buildGrid() : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('书架为空', style: TextStyle(color: Colors.grey[500], fontSize: 18)),
          const SizedBox(height: 8),
          Text('在搜索或详情页点击收藏添加', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return RefreshIndicator(
      onRefresh: _loadLibrary,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: _filteredItems.length,
        itemBuilder: (ctx, i) => _buildGridCard(_filteredItems[i]),
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadLibrary,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _filteredItems.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) => _buildListTile(_filteredItems[i]),
      ),
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _openItem(item),
      onLongPress: () => _showItemMenu(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200]),
              clipBehavior: Clip.antiAlias,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(item['pic'] ?? item['cover'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                        _getTypeIcon(item), color: Colors.grey[400])),
                // 类型标签
                Positioned(top: 0, left: 0, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeColor(item),
                    borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8))),
                  child: Text(_getTypeLabel(item),
                      style: const TextStyle(color: Colors.white, fontSize: 9)),
                )),
                // 进度标记
                if (item['episodeName'] != null)
                  Positioned(bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter, end: Alignment.topCenter,
                          colors: [Colors.black87, Colors.transparent])),
                      child: Text('看到 ${item['episodeName']}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 9)),
                    )),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Text(item['name'] ?? item['title'] ?? '', maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        ],
      ),
    );
  }

  Widget _buildListTile(Map<String, dynamic> item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(item['pic'] ?? item['cover'] ?? '',
            width: 48, height: 64, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 48, height: 64, color: Colors.grey[200],
              child: Icon(_getTypeIcon(item), color: Colors.grey, size: 20))),
      ),
      title: Text(item['name'] ?? item['title'] ?? '', maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item['episodeName'] != null)
            Text('看到 ${item['episodeName']}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          Text(_getTypeLabel(item), style: TextStyle(
              fontSize: 10, color: _getTypeColor(item))),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert, size: 18),
        onPressed: () => _showItemMenu(item),
      ),
      onTap: () => _openItem(item),
    );
  }

  void _openItem(Map<String, dynamic> item) {
    final type = item['mediaType'] ?? item['type'] ?? 'video';
    final content = UnifiedContent(
      id: item['id'] ?? '', title: item['name'] ?? item['title'] ?? '',
      cover: item['pic'] ?? item['cover'] ?? '',
      sourceKey: item['sourceKey'] ?? '',
      mediaType: MediaType.values.firstWhere((t) => t.name == type, orElse: () => MediaType.video));

    switch (type) {
      case 'comic':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ComicDetailScreen(content: content)));
      case 'novel':
        Navigator.push(context, MaterialPageRoute(builder: (_) => NovelDetailScreen(content: content)));
      case 'music':
        Navigator.push(context, MaterialPageRoute(builder: (_) => MusicDetailScreen(content: content)));
      default:
        Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(video: VideoContent.fromJson(item))));
    }
  }

  void _showItemMenu(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('从书架移除', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await AppConfig.removeFavorite(
                    item['id'] ?? '', item['sourceKey'] ?? '');
                Navigator.pop(ctx);
                _loadLibrary();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('分享'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(Map<String, dynamic> item) {
    final type = item['mediaType'] ?? item['type'] ?? 'video';
    return switch (type) {
      'comic' => Icons.auto_stories,
      'novel' => Icons.menu_book,
      'music' => Icons.music_note,
      _ => Icons.movie,
    };
  }

  Color _getTypeColor(Map<String, dynamic> item) {
    final type = item['mediaType'] ?? item['type'] ?? 'video';
    return switch (type) {
      'comic' => const Color(0xFFFF9800),
      'novel' => const Color(0xFF4CAF50),
      'music' => const Color(0xFF9C27B0),
      _ => const Color(0xFF2196F3),
    };
  }

  String _getTypeLabel(Map<String, dynamic> item) {
    final type = item['mediaType'] ?? item['type'] ?? 'video';
    return switch (type) {
      'comic' => '漫画',
      'novel' => '小说',
      'music' => '音乐',
      _ => '视频',
    };
  }
}

enum SortMode { recent, name, source }
