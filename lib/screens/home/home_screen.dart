/// 亦搜风格首页 — 顶部搜索 + Tab切换 + 横向滚动分区 + 底部导航
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../../models/unified_content.dart';
import '../../services/spider_service_v2.dart';
import '../../services/music_player_service.dart';
import '../../screens/detail/detail_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/aggregated/aggregated_search_screen.dart';
import '../../screens/sniffer/sniffer_screen.dart';
import '../../screens/comic/comic_detail_screen.dart';
import '../../screens/novel/novel_detail_screen.dart';
import '../../screens/music/music_player_screen.dart';
import '../../screens/music/music_detail_screen.dart';
import 'pages/comic_page.dart';
import 'pages/novel_page.dart';
import 'pages/music_page.dart';
import 'pages/live_page.dart';
import 'pages/mine_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  final _tabs = const ['精选', '漫画', '小说', '音乐', '直播'];
  final _icons = const [
    Icons.home_rounded,
    Icons.auto_stories_rounded,
    Icons.menu_book_rounded,
    Icons.music_note_rounded,
    Icons.live_tv_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final musicService = context.watch<MusicPlayerService>();
    final isTV = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 状态栏占位
          SizedBox(height: MediaQuery.of(context).padding.top),
          // 内容区
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                _VideoTabPage(),
                const ComicPage(),
                const NovelPage(),
                const MusicPage(),
                const LivePage(),
              ],
            ),
          ),
          // 迷你播放器 (音乐)
          if (musicService.hasTrack)
            _MiniMusicPlayer(service: musicService),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (i) => setState(() => _currentTab = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF2196F3),
        unselectedItemColor: Colors.grey[500],
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 8,
        items: List.generate(_tabs.length, (i) => BottomNavigationBarItem(
          icon: Icon(_icons[i]),
          label: _tabs[i],
        )),
      ),
    );
  }
}

/// ═══════════════════════════════════════
///  精选 Tab — 亦搜风格
/// ═══════════════════════════════════════
class _VideoTabPage extends StatefulWidget {
  @override
  State<_VideoTabPage> createState() => __VideoTabPageState();
}

class __VideoTabPageState extends State<_VideoTabPage> {
  List<VideoContent> _hotList = [];
  List<VideoContent> _movies = [];
  List<VideoContent> _tvShows = [];
  List<VideoContent> _variety = [];
  bool _isLoading = true;
  int _selectedCategory = 0;

  final _categories = const ['全部', '电影', '连续剧', '综艺', '动漫', '纪录片'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = context.read<SourceProvider>();
    if (provider.activeSource == null) return;
    try {
      final items = await provider.getCategory(null, page: 1);
      setState(() {
        _hotList = items;
        _movies = items.where((v) => v.category?.contains('电影') == true).toList();
        _tvShows = items.where((v) => v.category?.contains('连续剧') == true || v.category?.contains('剧') == true).toList();
        _variety = items.where((v) => v.category?.contains('综艺') == true).toList();
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        // 分类 Tab
        _buildCategoryTabs(),
        // 内容
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      _buildSection('🔥 热门推荐', _hotList.take(10).toList()),
                      _buildSection('🎬 电影', _movies.isNotEmpty ? _movies : _hotList.where((v) => v.year != null).toList()),
                      _buildSection('📺 连续剧', _tvShows.isNotEmpty ? _tvShows : _hotList.skip(5).take(10).toList()),
                      _buildSection('🎤 综艺', _variety.isNotEmpty ? _variety : _hotList.skip(10).take(10).toList()),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const AggregatedSearchScreen())),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[500], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('搜索你感兴趣的影视、漫画、小说...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ),
            // 嗅探按钮
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SnifferScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar, color: Colors.white, size: 12),
                    SizedBox(width: 3),
                    Text('嗅探', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(String title, List<VideoContent> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题行
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(title, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
              const Spacer(),
              Text('更多 >', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
        // 横向滚动
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildHorizontalCard(items[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalCard(VideoContent video) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(video: video))),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(video.pic, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.movie, color: Colors.grey)),
                    ),
                    // 标签
                    Positioned(
                      top: 0, left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(8)),
                        ),
                        child: Text(video.remark ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(video.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
          ],
        ),
      ),
    );
  }
}

/// ═══════════════════════════════════════
///  迷你音乐播放器 (底部)
/// ═══════════════════════════════════════
class _MiniMusicPlayer extends StatelessWidget {
  final MusicPlayerService service;
  const _MiniMusicPlayer({required this.service});

  @override
  Widget build(BuildContext context) {
    final track = service.currentTrack;
    if (track == null) return const SizedBox.shrink();

    return Container(
      height: 56,
      color: Colors.white,
      child: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: service.duration.inMilliseconds > 0
                ? service.position.inMilliseconds / service.duration.inMilliseconds
                : 0,
            minHeight: 1.5,
            backgroundColor: Colors.grey[200],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
          ),
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 12),
                // 封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(track.cover, width: 40, height: 40, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 40, height: 40, color: Colors.grey[200],
                      child: const Icon(Icons.music_note, color: Colors.grey, size: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                // 歌曲信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      Text(track.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                // 控制按钮
                IconButton(
                  icon: Icon(service.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 32, color: const Color(0xFF333333)),
                  onPressed: service.playOrPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 26),
                  onPressed: service.next,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
