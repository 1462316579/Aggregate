import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/video_content.dart';
import '../../models/unified_content.dart';
import '../../models/video_source.dart';
import '../../providers/source_provider.dart';
import '../../services/spider_service_v2.dart';
import '../detail/detail_screen.dart';
import '../comic/comic_detail_screen.dart';
import '../novel/novel_detail_screen.dart';
import '../music/music_detail_screen.dart';
import '../comic/comic_detail_screen.dart';

/// 搜索页面
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  AggregatedSearchResult? _results;
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _query = query;
      _results = null;
    });

    final provider = context.read<SourceProvider>();
    final results = await provider.searchAll(query);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  int get _totalResults {
    if (_results == null) return 0;
    return _results!.byType.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    final isTV = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isTV
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
                onPressed: () => Navigator.pop(context),
              ),
              title: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索影视、漫画、小说、音乐...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Color(0xFF999999)),
                ),
                style: const TextStyle(color: Color(0xFF333333), fontSize: 16),
                onSubmitted: _search,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF999999)),
                  onPressed: () {
                    _searchController.clear();
                    _focusNode.requestFocus();
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          if (isTV)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF2196F3), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '搜索影视、漫画、小说、音乐...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 18),
                      ),
                      style: const TextStyle(color: Color(0xFF333333), fontSize: 18),
                      onSubmitted: _search,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.clear, color: Color(0xFF999999), size: 28),
                    onPressed: () {
                      _searchController.clear();
                      _focusNode.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          if (_isSearching)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF2196F3)),
              ),
            )
          else if (_results != null)
            Expanded(
              child: _buildResults(),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('输入关键词开始搜索',
                        style: TextStyle(fontSize: 16, color: Colors.grey[500])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results == null) return const SizedBox();

    final types = _results!.byType.entries
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (types.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('未找到 "$_query" 相关内容',
                style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: types.length,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              indicatorColor: const Color(0xFF2196F3),
              labelColor: const Color(0xFF2196F3),
              unselectedLabelColor: Colors.grey,
              tabs: types.map((t) => Tab(
                text: '${t.key.label} (${t.value.length})',
              )).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: types.map((t) => _buildTypeResults(t.key, t.value)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeResults(MediaType type, List<UnifiedContent> items) {
    if (items.isEmpty) {
      return Center(
        child: Text('无 ${type.label} 结果',
            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openItem(item),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      item.cover,
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('来源: ${item.sourceKey}  ·  ${item.author}',
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        if (item.category != null && item.category!.isNotEmpty)
                          Text(item.category!,
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openItem(UnifiedContent item) {
    switch (item.mediaType) {
      case MediaType.video:
        final video = VideoContent(
          id: item.id,
          name: item.title,
          pic: item.cover,
          desc: item.description,
          category: item.category,
          year: item.year,
          area: item.area,
          director: item.director,
          actor: item.actor ?? item.author,
          remark: item.status,
          sourceKey: item.sourceKey,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailScreen(video: video)));
      case MediaType.comic:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ComicDetailScreen(content: item)));
      case MediaType.novel:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NovelDetailScreen(content: item)));
      case MediaType.music:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MusicDetailScreen(content: item)));
      case MediaType.live:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => LiveDetailScreen(content: item)));
    }
  }
}

/// 直播详情页（占位）
class LiveDetailScreen extends StatelessWidget {
  final UnifiedContent content;
  const LiveDetailScreen({required this.content, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(content.title)),
      body: Center(child: Text('直播播放: ${content.title}')),
    );
  }
}