/// 亦搜风格视频详情页 — 渐变封面 + Tab选集 + 浮动播放按钮
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../providers/player_provider.dart';
import '../../models/video_content.dart';
import '../../models/video_source.dart';
import '../../services/app_config.dart';
import '../player/player_screen.dart';

class DetailScreen extends StatefulWidget {
  final VideoContent video;
  const DetailScreen({super.key, required this.video});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with SingleTickerProviderStateMixin {
  VideoContent? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDetail();
    _checkFavorite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<SourceProvider>();
    final detail = await provider.getDetail(widget.video.id);
    setState(() { _detail = detail ?? widget.video; _isLoading = false; });
  }

  Future<void> _checkFavorite() async {
    final fav = await AppConfig.isFavorite(widget.video.id, widget.video.sourceKey ?? '');
    setState(() => _isFavorite = fav);
  }

  @override
  Widget build(BuildContext context) {
    final source = context.read<SourceProvider>().activeSource;
    final video = _detail ?? widget.video;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ═══ 渐变封面区 ═══
                SliverToBoxAdapter(
                  child: Container(
                    height: screenH * 0.42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF1565C0),
                          const Color(0xFF0D47A1).withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 背景图 (模糊)
                        Image.network(video.pic, fit: BoxFit.cover,
                          opacity: const AlwaysStoppedAnimation(0.3),
                          errorBuilder: (_, __, ___) => const SizedBox()),
                        // 渐变遮罩
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xFF0D47A1)],
                            ),
                          ),
                        ),
                        // 返回按钮
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 4,
                          left: 4,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // 收藏按钮
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 4,
                          right: 4,
                          child: IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: _isFavorite ? Colors.red : Colors.white, size: 24),
                            onPressed: _toggleFavorite,
                          ),
                        ),
                        // 信息区
                        Positioned(
                          bottom: 0, left: 0, right: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // 海报
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(video.pic,
                                    width: 100, height: 140, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 100, height: 140, color: Colors.grey[300],
                                      child: const Icon(Icons.movie)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // 文字信息
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(video.name, maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white,
                                            fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      if (video.category != null && video.category!.isNotEmpty)
                                        _infoChip(video.category!),
                                      if (video.year != null && video.year!.isNotEmpty)
                                        _infoChip(video.year!),
                                      if (video.area != null && video.area!.isNotEmpty)
                                        _infoChip(video.area!),
                                      if (video.remark != null && video.remark!.isNotEmpty)
                                        _infoChip(video.remark!, color: Colors.amber),
                                      const SizedBox(height: 8),
                                      if (video.director != null && video.director!.isNotEmpty)
                                        Text('导演: ${video.director}',
                                            maxLines: 1, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[300], fontSize: 11)),
                                      if (video.actor != null && video.actor!.isNotEmpty)
                                        Text('演员: ${video.actor}',
                                            maxLines: 2, overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[300], fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══ Tab 区域 ═══
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF2196F3),
                      labelColor: const Color(0xFF2196F3),
                      unselectedLabelColor: Colors.grey,
                      tabs: [
                        Tab(text: '简介'),
                        Tab(text: '选集 (${video.episodes?.length ?? 0})'),
                      ],
                    ),
                  ),
                ),

                // ═══ Tab 内容 ═══
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // 简介
                      _buildInfoTab(video),
                      // 选集
                      _buildEpisodeTab(video, source),
                    ],
                  ),
                ),
              ],
            ),

      // ═══ 浮动播放按钮 ═══
      floatingActionButton: FloatingActionButton.extended(
        onPressed: video.episodes != null && video.episodes!.isNotEmpty
            ? () => _playEpisode(video.episodes!.first, source)
            : null,
        backgroundColor: const Color(0xFF2196F3),
        icon: const Icon(Icons.play_arrow, color: Colors.white),
        label: Text(
          video.episodes != null && video.episodes!.isNotEmpty
              ? '播放 ${video.episodes!.first.name}'
              : '暂无播放源',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _infoChip(String text, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(right: 6, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(
        color: color ?? Colors.white70, fontSize: 11)),
    );
  }

  Widget _buildInfoTab(VideoContent video) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('剧情简介', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(height: 8),
        Text(video.desc ?? '暂无简介',
          style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6)),
        const SizedBox(height: 16),
        const Divider(),
        // 详细信息
        if (video.director != null && video.director!.isNotEmpty)
          _infoRow('导演', video.director!),
        if (video.actor != null && video.actor!.isNotEmpty)
          _infoRow('演员', video.actor!),
        if (video.category != null) _infoRow('类型', video.category!),
        if (video.area != null) _infoRow('地区', video.area!),
        if (video.year != null) _infoRow('年份', video.year!),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 50, child: Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEpisodeTab(VideoContent video, VideoSource? source) {
    if (video.episodes == null || video.episodes!.isEmpty) {
      return const Center(child: Text('暂无播放源',
          style: TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: video.episodes!.length,
      itemBuilder: (context, index) {
        final ep = video.episodes![index];
        return InkWell(
          onTap: () => _playEpisode(ep, source),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[200]!),
            ),
            alignment: Alignment.center,
            child: Text(ep.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
          ),
        );
      },
    );
  }

  void _toggleFavorite() async {
    final item = {
      'id': widget.video.id, 'name': widget.video.name,
      'pic': widget.video.pic, 'sourceKey': widget.video.sourceKey,
    };
    if (_isFavorite) {
      await AppConfig.removeFavorite(widget.video.id, widget.video.sourceKey ?? '');
    } else {
      await AppConfig.addFavorite(item);
    }
    setState(() => _isFavorite = !_isFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavorite ? '已收藏' : '已取消'),
            duration: const Duration(seconds: 1)));
    }
  }

  void _playEpisode(VideoEpisode episode, VideoSource? source) {
    if (source == null) return;
    final video = _detail ?? widget.video;
    context.read<PlayerProvider>().loadAndPlay(video, episode, source);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        title: '${video.name} - ${episode.name}',
        url: episode.url,
        episodes: video.episodes,
        currentEpisode: episode,
        source: source,
      ),
    ));
  }
}
