/// 搜索页 v2 — 聚合搜索 + 单源搜索 + 类型筛选 + 历史记录
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/unified_content.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../services/app_config.dart';
import '../detail/detail_screen.dart';
import '../comic/comic_detail_screen.dart';
import '../novel/novel_detail_screen.dart';
import '../music/music_detail_screen.dart';

class AggregatedSearchScreen extends StatefulWidget {
  const AggregatedSearchScreen({super.key});
  @override
  State<AggregatedSearchScreen> createState() => _AggregatedSearchScreenState();
}

class _AggregatedSearchScreenState extends State<AggregatedSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  late TabController _tabController;

  AggregatedSearchResult? _result;
  bool _isSearching = false;
  String _query = '';

  // 搜索模式
  SearchMode _searchMode = SearchMode.aggregate;
  MediaType? _selectedType;      // 类型筛选
  VideoSource? _selectedSource;  // 指定源

  List<String> _history = [];
  List<String> _hotSearches = ['三体', '流浪地球', '鬼灭之刃', '周杰伦', '庆余年', '斗破苍穹'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadHistory();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final h = await AppConfig.getSearchHistory();
    setState(() => _history = h);
  }

  Future<void> _saveHistory(String query) async {
    await AppConfig.saveSearchHistory(query);
    _history.insert(0, query);
    if (_history.length > 20) _history.removeRange(20, _history.length);
  }

  /// 执行搜索
  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    _saveHistory(query);
    setState(() { _isSearching = true; _query = query; _result = null; });
    _focusNode.unfocus();

    final provider = context.read<SourceProvider>();

    if (_searchMode == SearchMode.single && _selectedSource != null) {
      // 单源搜索
      final result = await SpiderServiceV2.searchAll(
        [_selectedSource!], query, filterType: _selectedType);
      setState(() { _result = result; _isSearching = false; });
    } else {
      // 聚合搜索 (全部源)
      final result = await SpiderServiceV2.searchAll(
        provider.sources, query, filterType: _selectedType);
      setState(() { _result = result; _isSearching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 状态栏
          SizedBox(height: MediaQuery.of(context).padding.top),
          // 搜索栏
          _buildSearchBar(provider),
          // 搜索模式 + 类型筛选
          _buildFilterBar(provider),
          // Tab (全部/视频/漫画/小说/音乐/直播)
          if (_result != null) _buildTypeTabs(),
          // 内容
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchBar(SourceProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          // 返回
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // 搜索框
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '搜索影视、漫画、小说、音乐...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                          onPressed: () { _searchController.clear(); setState(() {}); })
                      : null,
                ),
                style: const TextStyle(fontSize: 14),
                onSubmitted: _doSearch,
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 搜索按钮
          GestureDetector(
            onTap: () => _doSearch(_searchController.text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('搜索', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(SourceProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Column(
        children: [
          // 搜索模式切换
          Row(
            children: [
              _buildModeChip('聚合搜索', SearchMode.aggregate, Icons.blur_on, const Color(0xFF2196F3)),
              const SizedBox(width: 8),
              _buildModeChip('单源搜索', SearchMode.single, Icons.filter_list, Colors.orange),
              const Spacer(),
              // 源选择 (单源模式)
              if (_searchMode == SearchMode.single)
                _buildSourceSelector(provider),
            ],
          ),
          const SizedBox(height: 8),
          // 类型筛选
          Row(
            children: [
              _buildTypeChip(null, '全部'),
              _buildTypeChip(MediaType.video, '🎬 视频'),
              _buildTypeChip(MediaType.comic, '📖 漫画'),
              _buildTypeChip(MediaType.novel, '📚 小说'),
              _buildTypeChip(MediaType.music, '🎵 音乐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, SearchMode mode, IconData icon, Color color) {
    final isActive = _searchMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _searchMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? color : Colors.grey[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isActive ? color : Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
                fontSize: 12, color: isActive ? color : Colors.grey[600],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(MediaType? type, String label) {
    final isActive = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF2196F3) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(label, style: TextStyle(
            fontSize: 12, color: isActive ? Colors.white : Colors.grey[600])),
      ),
    );
  }

  Widget _buildSourceSelector(SourceProvider provider) {
    return PopupMenuButton<VideoSource>(
      tooltip: '选择源',
      onSelected: (s) => setState(() => _selectedSource = s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns, size: 12, color: Colors.orange[700]),
            const SizedBox(width: 4),
            Text(_selectedSource?.name ?? '选源',
                style: TextStyle(fontSize: 11, color: Colors.orange[700])),
            Icon(Icons.arrow_drop_down, size: 14, color: Colors.orange[700]),
          ],
        ),
      ),
      itemBuilder: (_) => provider.sources.map((s) => PopupMenuItem(
        value: s,
        child: Row(
          children: [
            Icon(s.key == _selectedSource?.key ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16, color: s.key == _selectedSource?.key ? Colors.orange : Colors.grey),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(fontSize: 13)),
                Text(s.mediaType, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTypeTabs() {
    final types = [
      ('全部', _result!.totalResults),
      ('视频', _result!.ofType(MediaType.video).length),
      ('漫画', _result!.ofType(MediaType.comic).length),
      ('小说', _result!.ofType(MediaType.novel).length),
      ('音乐', _result!.ofType(MediaType.music).length),
      ('直播', 0),
    ];

    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: const Color(0xFF2196F3),
        labelColor: const Color(0xFF2196F3),
        unselectedLabelColor: Colors.grey,
        tabs: types.map((t) => Tab(
          text: '${t.0} (${t.1})',
        )).toList(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('正在搜索「$_query」...',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ]),
      );
    }

    if (_result == null) return _buildEmptyState();

    return TabBarView(
      controller: _tabController,
      children: [
        _buildGrid(_result!.byType.values.expand((l) => l).toList()),
        _buildGrid(_result!.ofType(MediaType.video)),
        _buildGrid(_result!.ofType(MediaType.comic)),
        _buildGrid(_result!.ofType(MediaType.novel)),
        _buildGrid(_result!.ofType(MediaType.music)),
        _buildGrid([]),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 搜索历史
        if (_history.isNotEmpty) ...[
          Row(
            children: [
              const Text('搜索历史', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton(
                onPressed: () async { await AppConfig.clearSearchHistory(); setState(() => _history.clear()); },
                child: const Text('清空', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _history.take(10).map((h) => GestureDetector(
              onTap: () { _searchController.text = h; _doSearch(h); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                child: Text(h, style: const TextStyle(fontSize: 13)),
              ),
            )).toList(),
          ),
          const SizedBox(height: 24),
        ],
        // 热搜
        const Text('热门搜索', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: _hotSearches.asMap().entries.map((e) => GestureDetector(
            onTap: () { _searchController.text = e.value; _doSearch(e.value); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: e.key < 3 ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (e.key < 3)
                    Text('${e.key + 1}', style: const TextStyle(
                        color: Color(0xFF2196F3), fontSize: 12, fontWeight: FontWeight.bold)),
                  if (e.key < 3) const SizedBox(width: 4),
                  Text(e.value, style: TextStyle(
                      fontSize: 13, color: e.key < 3 ? const Color(0xFF2196F3) : Colors.grey[700])),
                ],
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildGrid(List<UnifiedContent> items) {
    if (items.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('未找到相关结果', style: TextStyle(color: Colors.grey[400])),
        ],
      ));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(UnifiedContent item) {
    return GestureDetector(
      onTap: () => _openItem(item),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(item.cover, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(_getIcon(item.mediaType), color: Colors.grey[400])),
            // 类型标签
            Positioned(top: 0, left: 0, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getTypeColor(item.mediaType),
                borderRadius: const BorderRadius.only(bottomRight: Radius.circular(8))),
              child: Text(item.mediaType.label, style: const TextStyle(color: Colors.white, fontSize: 9)),
            )),
            // 状态标签
            if (item.status != null && item.status!.isNotEmpty)
              Positioned(top: 0, right: 0, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: const BoxDecoration(color: Colors.black54,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8))),
                child: Text(item.status!, style: const TextStyle(color: Colors.white70, fontSize: 9)),
              )),
          ]),
        )),
        const SizedBox(height: 4),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        Text('${item.author}  ·  ${item.category}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }

  void _openItem(UnifiedContent item) {
    switch (item.mediaType) {
      case MediaType.video:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DetailScreen(video: item.toVideoContent())));
      case MediaType.comic:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ComicDetailScreen(content: item)));
      case MediaType.novel:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => NovelDetailScreen(content: item)));
      case MediaType.music:
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MusicDetailScreen(content: item)));
      default: break;
    }
  }

  IconData _getIcon(MediaType type) => switch (type) {
    MediaType.video => Icons.movie,
    MediaType.comic => Icons.auto_stories,
    MediaType.novel => Icons.menu_book,
    MediaType.music => Icons.music_note,
    MediaType.live => Icons.live_tv,
  };

  Color _getTypeColor(MediaType type) => switch (type) {
    MediaType.video => const Color(0xFF2196F3),
    MediaType.comic => const Color(0xFFFF9800),
    MediaType.novel => const Color(0xFF4CAF50),
    MediaType.music => const Color(0xFF9C27B0),
    MediaType.live => const Color(0xFFF44336),
  };
}

enum SearchMode { aggregate, single }
