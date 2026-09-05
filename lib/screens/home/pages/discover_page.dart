/// 精选页 - 聚合推荐
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/source_provider.dart';
import '../../../models/video_content.dart';
import '../../../services/spider_service.dart';
import '../../detail/detail_screen.dart';
import '../../search/search_screen.dart';
import '../../sniffer/sniffer_screen.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<VideoContent> _hotList = [];
  bool _isLoading = true;

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    final isTV = MediaQuery.of(context).size.width > 960;

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          title: Row(
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('AllPlay'),
              const Spacer(),
              // 源选择
              if (provider.sources.isNotEmpty)
                _buildSourceDropdown(provider),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
                },
              ),
            ],
          ),
        ),

        // 加载中
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hotList.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.movie_filter, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('暂无内容',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('请在「我的」中配置视频源',
                      style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ],
              ),
            ),
          )
        else ...[
          // 嗅探入口卡片
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SnifferScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.15),
                        Colors.deepOrange.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.radar, color: Colors.orange, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('影视嗅探',
                                style: TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text('输入网址自动检测视频资源，支持 M3U8/MP4/FLV',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('开始嗅探',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 横向滚动推荐
          SliverToBoxAdapter(
            child: _buildRecommendSection(
              '最新更新', _hotList.take(10).toList(), isTV),
          ),
          // 网格列表
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTV ? 6 : 3,
                childAspectRatio: 0.65,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final video = _hotList[index];
                  return _buildVideoCard(video);
                },
                childCount: _hotList.length,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSourceDropdown(SourceProvider provider) {
    return PopupMenuButton<String>(
      tooltip: '切换视频源',
      onSelected: (key) {
        final source = provider.sources.firstWhere((s) => s.key == key);
        provider.setActiveSource(source);
        setState(() {
          _isLoading = true;
          _hotList = [];
        });
        _loadData();
      },
      itemBuilder: (_) => provider.sources
          .where((s) => s.type != 4)
          .map((s) => PopupMenuItem(
                value: s.key,
                child: Row(
                  children: [
                    if (s.key == provider.activeSource?.key)
                      const Icon(Icons.check, color: Colors.blue, size: 16)
                    else
                      const SizedBox(width: 16),
                    const SizedBox(width: 8),
                    Text(s.name),
                  ],
                ),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(provider.activeSource?.name ?? '选择源',
                style: const TextStyle(color: Colors.blue, fontSize: 13)),
            const Icon(Icons.arrow_drop_down, color: Colors.blue, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendSection(
      String title, List<VideoContent> items, bool isTV) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: isTV ? 260 : 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final video = items[index];
              return _buildRecommendCard(video, isTV);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendCard(VideoContent video, bool isTV) {
    final width = isTV ? 180.0 : 130.0;
    return GestureDetector(
      onTap: () => _openDetail(video),
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 海报
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      video.pic,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, color: Colors.grey),
                      ),
                    ),
                    if (video.remark != null && video.remark!.isNotEmpty)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(video.remark!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            // 标题
            Text(video.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            if (video.category != null)
              Text(video.category!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(VideoContent video) {
    return GestureDetector(
      onTap: () => _openDetail(video),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.pic,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                  ),
                  if (video.remark != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(video.remark!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                  // 底部渐变
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(video.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _openDetail(VideoContent video) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailScreen(video: video)),
    );
  }
}
