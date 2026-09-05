/// 首页 v3 — 仅2个底部Tab: 首页 + 我的
/// 首页包含所有内容分区 (精选/漫画/小说/音乐/直播/书架/更新)
/// 采用顶部搜索 + 横向分类标签 + 滚动内容流
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../../models/unified_content.dart';
import '../../services/spider_service_v2.dart';
import '../../services/music_player_service.dart';
import '../../services/app_config.dart';
import '../../screens/detail/detail_screen.dart';
import '../../screens/comic/comic_detail_screen.dart';
import '../../screens/novel/novel_detail_screen.dart';
import '../../screens/music/music_detail_screen.dart';
import '../../screens/music/music_player_screen.dart';
import '../../screens/search/search_screen.dart';
import '../../screens/aggregated/aggregated_search_screen.dart';
import '../../screens/sniffer/sniffer_screen.dart';
import '../../screens/library/library_screen.dart';
import '../../screens/setting/setting_screen.dart';
import 'pages/mine_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final musicService = context.watch<MusicPlayerService>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          Expanded(
            child: IndexedStack(
              index: _currentTab,
              children: [
                const _HomePage(),
                const MinePage(),
              ],
            ),
          ),
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: '我的'),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════
///  首页 Tab — 搜索 + 横向标签 + 内容流
/// ═══════════════════════════════════════
class _HomePage extends StatefulWidget {
  const _HomePage();
  @override
  State<_HomePage> createState() => __HomePageState();
}

class __HomePageState extends State<_HomePage> {
  final ScrollController _scrollController = ScrollController();
  int _currentSection = 0;

  // 分区数据
  List<VideoContent> _hotVideos = [];
  List<UnifiedContent> _hotComics = [];
  List<UnifiedContent> _hotNovels = [];
  List<UnifiedContent> _hotMusic = [];
  bool _isLoading = true;

  final _sections = const [
    {'name': '精选', 'icon': '🔥', 'color': Color(0xFF2196F3)},
    {'name': '漫画', 'icon': '📖', 'color': Color(0xFFFF9800)},
    {'name': '小说', 'icon': '📚', 'color': Color(0xFF4CAF50)},
    {'name': '音乐', 'icon': '🎵', 'color': Color(0xFF9C27B0)},
    {'name': '直播', 'icon': '📺', 'color': Color(0xFFF44336)},
    {'name': '书架', 'icon': '📂', 'color': Color(0xFF00BCD4)},
    {'name': '更新', 'icon': '📢', 'color': Color(0xFFFF5722)},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    final provider = context.read<SourceProvider>();
    
    // 并行加载所有数据
    final futures = <Future>[];
    
    // 视频
    if (provider.activeSource != null) {
      futures.add(provider.getCategory(null, page: 1).then((items) {
        _hotVideos = items;
      }).catchError((_) {}));
    }
    
    // 漫画
    for (var s in provider.comicSources.take(2)) {
      futures.add(SpiderServiceV2.searchComic(s, '').then((items) {
        _hotComics.addAll(items);
      }).catchError((_) {}));
    }
    
    // 小说
    for (var s in provider.novelSources.take(2)) {
      futures.add(SpiderServiceV2.searchNovel(s, '').then((items) {
        _hotNovels.addAll(items);
      }).catchError((_) {}));
    }
    
    // 音乐
    for (var s in provider.musicSources.take(2)) {
      futures.add(SpiderServiceV2.searchMusic(s, '热门').then((items) {
        _hotMusic.addAll(items);
      }).catchError((_) {}));
    }

    await Future.wait(futures);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 搜索栏
        _buildSearchBar(),
        // 分区标签
        _buildSectionTabs(),
        // 内容区
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  child: _buildContent(),
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
          borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[500], size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text('搜索影视、漫画、小说、音乐...',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SnifferScreen())),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue, borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _sections.length,
        itemBuilder: (ctx, i) {
          final sec = _sections[i];
          final sel = i == _currentSection;
          return GestureDetector(
            onTap: () {
              setState(() => _currentSection = i);
              if (i == 5) { // 书架
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LibraryScreen()));
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: sel ? sec['color'] as Color : Colors.grey[100],
                borderRadius: BorderRadius.circular(20)),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(sec['icon'] as String, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(sec['name'] as String, style: TextStyle(
                      fontSize: 13,
                      color: sel ? Colors.white : Colors.grey[700],
                      fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_currentSection) {
      case 0: return _buildVideoSection();
      case 1: return _buildComicSection();
      case 2: return _buildNovelSection();
      case 3: return _buildMusicSection();
      case 4: return _buildLiveSection();
      case 6: return _buildUpdateSection();
      default: return _buildVideoSection();
    }
  }

  /// ═══ 精选 ═══
  Widget _buildVideoSection() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _buildHorizontalRow('🔥 热门推荐', _hotVideos.take(10).toList(),
            (item) => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailScreen(video: item))),
            (item) => item.name, (item) => item.pic,
            remark: (item) => item.remark),
        _buildHorizontalRow('🎬 电影', _hotVideos.where((v) => v.category?.contains('电影') == true).toList().take(10).toList(),
            (item) => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailScreen(video: item))),
            (item) => item.name, (item) => item.pic,
            remark: (item) => item.remark),
        _buildHorizontalRow('📺 连续剧', _hotVideos.where((v) => v.category?.contains('剧') == true).toList().take(10).toList(),
            (item) => Navigator.push(context,
                MaterialPageRoute(builder: (_) => DetailScreen(video: item))),
            (item) => item.name, (item) => item.pic,
            remark: (item) => item.remark),
      ],
    );
  }

  /// ═══ 漫画 ═══
  Widget _buildComicSection() {
    if (_hotComics.isEmpty) return _buildEmpty('暂无漫画源', '请在「我的」→ 设置中添加');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: _hotComics.length,
      itemBuilder: (ctx, i) => _buildMediaCard(
        _hotComics[i].title, _hotComics[i].cover, _hotComics[i].author,
        _hotComics[i].status, const Color(0xFFFF9800),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => ComicDetailScreen(content: _hotComics[i])))),
    );
  }

  /// ═══ 小说 ═══
  Widget _buildNovelSection() {
    if (_hotNovels.isEmpty) return _buildEmpty('暂无小说源', '请在「我的」→ 设置中添加');
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: _hotNovels.length,
      itemBuilder: (ctx, i) => _buildMediaCard(
        _hotNovels[i].title, _hotNovels[i].cover, _hotNovels[i].author,
        _hotNovels[i].status, const Color(0xFF4CAF50),
        () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => NovelDetailScreen(content: _hotNovels[i])))),
    );
  }

  /// ═══ 音乐 ═══
  Widget _buildMusicSection() {
    if (_hotMusic.isEmpty) return _buildEmpty('暂无音乐源', '请在「我的」→ 设置中添加');
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _hotMusic.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final item = _hotMusic[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: item.cover, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 48, height: 48, color: Colors.grey[200],
                child: const Icon(Icons.music_note, size: 20, color: Colors.grey)),
            ),
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14)),
          subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          trailing: IconButton(
            icon: Icon(Icons.play_circle_outline, color: Colors.grey[400], size: 28),
            onPressed: () {
              final provider = context.read<SourceProvider>();
              final source = provider.sources.firstWhere(
                (s) => s.key == item.sourceKey,
                orElse: () => provider.activeSource!);
              final track = MusicTrack(
                  id: item.id, name: item.title, author: item.author, cover: item.cover);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MusicPlayerScreen(track: track, source: source)));
            },
          ),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MusicDetailScreen(content: item))),
        );
      },
    );
  }

  /// ═══ 直播 ═══
  Widget _buildLiveSection() {
    return _buildEmpty('📺 直播', '在「我的」→ 设置中配置直播源');
  }

  /// ═══ 更新 ═══
  Widget _buildUpdateSection() {
    return _buildEmpty('📢 更新', '收藏内容后会显示在这里');
  }

  /// ═══ 通用横向滚动卡片 ═══
  Widget _buildHorizontalRow<T>(
    String title, List<T> items,
    Function(T) onTap,
    String Function(T) nameGetter,
    String Function(T) coverGetter,
    {String Function(T)? remark},
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(children: [
            Text(title, style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
            const Spacer(),
            Text('更多 >', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(item),
                child: Container(
                  width: 110, margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            Image.network(coverGetter(item), fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.movie, color: Colors.grey))),
                            if (remark != null && remark(item) != null)
                              Positioned(top: 0, left: 0, child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2196F3),
                                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))),
                                child: Text(remark(item)!, style: const TextStyle(
                                    color: Colors.white, fontSize: 10)),
                              )),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(nameGetter(item), maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// ═══ 通用媒体卡片 ═══
  Widget _buildMediaCard(
    String title, String cover, String author, String? status,
    Color tagColor, VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
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
                CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.movie, color: Colors.grey[400])),
                if (status != null && status.isNotEmpty)
                  Positioned(top: 0, right: 0, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tagColor,
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(8))),
                    child: Text(status, style: const TextStyle(color: Colors.white, fontSize: 10)),
                  )),
              ]),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
          Text(author, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEmpty(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }
}

/// 迷你播放器
class _MiniMusicPlayer extends StatelessWidget {
  final MusicPlayerService service;
  const _MiniMusicPlayer({required this.service});
  @override
  Widget build(BuildContext context) {
    final track = service.currentTrack;
    if (track == null) return const SizedBox.shrink();
    return Container(
      height: 56, color: Colors.white,
      child: Column(children: [
        LinearProgressIndicator(
          value: service.duration.inMilliseconds > 0
              ? service.position.inMilliseconds / service.duration.inMilliseconds : 0,
          minHeight: 1.5, backgroundColor: Colors.grey[200],
          valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3))),
        Expanded(child: Row(children: [
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(track.cover, width: 40, height: 40, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 40, height: 40, color: Colors.grey[200],
                    child: const Icon(Icons.music_note, size: 20, color: Colors.grey))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              Text(track.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          )),
          IconButton(
            icon: Icon(service.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32, color: const Color(0xFF333333)),
            onPressed: service.playOrPause),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, size: 26),
            onPressed: service.next),
        ])),
      ]),
    );
  }
}
