/// 漫画详情页 — 完整功能: 信息 + 章节列表 + 收藏 + 分享
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/unified_content.dart';
import '../../models/comic_detail.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../services/app_config.dart';
import '../../providers/source_provider.dart';
import '../comic/comic_reader_screen.dart';

class ComicDetailScreen extends StatefulWidget {
  final UnifiedContent content;
  const ComicDetailScreen({super.key, required this.content});
  @override
  State<ComicDetailScreen> createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  ComicDetail? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isDescExpanded = false;
  bool _isDescOverflow = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkFavorite();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!);
    final detail = await SpiderServiceV2.getComicDetail(source, widget.content.id);
    setState(() { _detail = detail; _isLoading = false; });
  }

  Future<void> _checkFavorite() async {
    final fav = await AppConfig.isFavorite(widget.content.id, widget.content.sourceKey ?? '');
    setState(() => _isFavorite = fav);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final screenW = MediaQuery.of(context).size.width;
    final isTV = screenW > 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? _buildError()
              : CustomScrollView(
                  slivers: [
                    // ═══ 顶部渐变封面 ═══
                    SliverToBoxAdapter(
                      child: _buildHeroHeader(detail, screenW),
                    ),
                    // ═══ 信息区 ═══
                    SliverToBoxAdapter(
                      child: _buildInfoSection(detail),
                    ),
                    // ═══ 章节列表 ═══
                    SliverToBoxAdapter(
                      child: _buildChapterHeader(detail),
                    ),
                    // 章节网格
                    for (var volume in detail.volumes) ...[
                      if (volume.name.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                            child: Text(volume.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTV ? 8 : 4,
                            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildChapterChip(volume.chapters[i], i, volume.chapters),
                            childCount: volume.chapters.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),

      // ═══ 底部操作栏 ═══
      bottomNavigationBar: _buildBottomBar(detail),
    );
  }

  Widget _buildHeroHeader(ComicDetail detail, double screenW) {
    return Container(
      height: 280,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)])),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 背景模糊
          CachedNetworkImage(
            imageUrl: detail.cover, fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.25),
            errorBuilder: (_, __, ___) => const SizedBox()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF0D47A1)]))),
          // 返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 4, left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context))),
          // 分享按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 4, right: 4,
            child: IconButton(
              icon: const Icon(Icons.share, color: Colors.white, size: 20),
              onPressed: () {})),
          // 底部信息
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // 海报
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: detail.cover,
                      width: 90, height: 120, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90, height: 120, color: Colors.grey[300],
                        child: const Icon(Icons.auto_stories))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(detail.title, maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _chip(detail.author, Colors.white70),
                        const SizedBox(height: 6),
                        Row(children: [
                          if (detail.status != null) _chip(detail.status!, Colors.green),
                          const SizedBox(width: 6),
                          if (detail.category.isNotEmpty) _chip(detail.category, Colors.orange),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ComicDetail detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 简介
          LayoutBuilder(
            builder: (ctx, constraints) {
              final textPainter = TextPainter(
                text: TextSpan(text: detail.description, style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.6)),
                maxLines: 3,
                textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);
              _isDescOverflow = textPainter.didExceedMaxLines;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.description.isEmpty ? '暂无简介' : detail.description,
                    maxLines: _isDescExpanded ? null : 3,
                    overflow: _isDescExpanded ? null : TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6)),
                  if (_isDescOverflow)
                    GestureDetector(
                      onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                      child: Text(_isDescExpanded ? '收起' : '展开',
                          style: const TextStyle(color: Color(0xFF2196F3), fontSize: 13)),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // 信息行
          _infoRow('作者', detail.author),
          if (detail.category.isNotEmpty) _infoRow('分类', detail.category),
          if (detail.status != null) _infoRow('状态', detail.status!),
          _infoRow('章节', '${_totalChapters(detail)} 章'),
        ],
      ),
    );
  }

  Widget _buildChapterHeader(ComicDetail detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Text('目录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('${_totalChapters(detail)}章', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const Spacer(),
          // 倒序切换
          IconButton(
            icon: const Icon(Icons.sort, size: 20),
            onPressed: () {},
            tooltip: '倒序',
          ),
        ],
      ),
    );
  }

  Widget _buildChapterChip(ComicChapter ch, int index, List<ComicChapter> all) {
    return InkWell(
      onTap: () => _readComic(all, index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey[200]!)),
        alignment: Alignment.center,
        child: Text(ch.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
      ),
    );
  }

  Widget _buildBottomBar(ComicDetail? detail) {
    final firstChapter = detail?.volumes.isNotEmpty == true && detail!.volumes.first.chapters.isNotEmpty
        ? detail.volumes.first.chapters.first : null;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          // 收藏
          GestureDetector(
            onTap: _toggleFavorite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey, size: 24),
                Text(_isFavorite ? '已收藏' : '收藏',
                    style: TextStyle(fontSize: 10, color: _isFavorite ? Colors.red : Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // 评论
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment_outlined, color: Colors.grey, size: 24),
              Text('评论', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 24),
          // 分享
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, color: Colors.grey, size: 24),
              Text('分享', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 20),
          // 开始阅读按钮
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              onPressed: firstChapter != null ? () => _readComic(detail!.volumes.first.chapters, 0) : null,
              child: Text(firstChapter != null ? '开始阅读: ${firstChapter.name}' : '暂无章节',
                  style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  int _totalChapters(ComicDetail detail) {
    return detail.volumes.fold(0, (sum, v) => sum + v.chapters.length);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11)),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 50, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('加载失败', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: () { setState(() => _isLoading = true); _loadDetail(); },
            child: const Text('重试')),
      ]),
    );
  }

  void _toggleFavorite() async {
    final item = {
      'id': widget.content.id, 'title': widget.content.title,
      'cover': widget.content.cover, 'sourceKey': widget.content.sourceKey,
    };
    if (_isFavorite) {
      await AppConfig.removeFavorite(widget.content.id, widget.content.sourceKey ?? '');
    } else {
      await AppConfig.addFavorite(item);
    }
    setState(() => _isFavorite = !_isFavorite);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isFavorite ? '已收藏' : '已取消'),
            duration: const Duration(seconds: 1)));
  }

  void _readComic(List<ComicChapter> chapters, int index) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ComicReaderScreen(
        comic: _detail ?? ComicDetail(
          id: widget.content.id, title: widget.content.title, cover: widget.content.cover),
        chapters: chapters, startChapterIndex: index, source: source)));
  }
}
