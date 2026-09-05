/// 小说详情页 — 完整功能: 信息 + 章节列表 + 收藏 + 开始阅读
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/unified_content.dart';
import '../../models/novel_detail.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../services/app_config.dart';
import '../../providers/source_provider.dart';
import '../novel/novel_reader_screen.dart';

class NovelDetailScreen extends StatefulWidget {
  final UnifiedContent content;
  const NovelDetailScreen({super.key, required this.content});
  @override
  State<NovelDetailScreen> createState() => _NovelDetailScreenState();
}

class _NovelDetailScreenState extends State<NovelDetailScreen> {
  NovelDetail? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;
  bool _isDescExpanded = false;

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
    final detail = await SpiderServiceV2.getNovelDetail(source, widget.content.id);
    setState(() { _detail = detail; _isLoading = false; });
  }

  Future<void> _checkFavorite() async {
    final fav = await AppConfig.isFavorite(widget.content.id, widget.content.sourceKey ?? '');
    setState(() => _isFavorite = fav);
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null ? _buildError() : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeroHeader(detail)),
                SliverToBoxAdapter(child: _buildInfoSection(detail)),
                SliverToBoxAdapter(child: _buildChapterHeader(detail)),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildChapterTile(detail.chapters[i], i),
                    childCount: detail.chapters.length),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
      bottomNavigationBar: _buildBottomBar(detail),
    );
  }

  Widget _buildHeroHeader(NovelDetail detail) {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)])),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: detail.cover, fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.2),
            errorBuilder: (_, __, ___) => const SizedBox()),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xFF1B5E20)]))),
          Positioned(
            top: MediaQuery.of(context).padding.top + 4, left: 4,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context))),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: detail.cover, width: 90, height: 120, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 90, height: 120, color: Colors.grey[300],
                        child: const Icon(Icons.menu_book))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(detail.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white,
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Row(children: [
                          _chip(detail.author, Colors.white70),
                          const SizedBox(width: 6),
                          if (detail.status != null) _chip(detail.status!, Colors.green),
                        ]),
                      ],
                    )),
                ],
              )),
        ],
      ),
    );
  }

  Widget _buildInfoSection(NovelDetail detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (ctx, constraints) {
              final tp = TextPainter(
                text: TextSpan(text: detail.description, style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.6)),
                maxLines: 3, textDirection: TextDirection.ltr,
              )..layout(maxWidth: constraints.maxWidth);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(detail.description.isEmpty ? '暂无简介' : detail.description,
                      maxLines: _isDescExpanded ? null : 3,
                      overflow: _isDescExpanded ? null : TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6)),
                  if (tp.didExceedMaxLines)
                    GestureDetector(
                      onTap: () => setState(() => _isDescExpanded = !_isDescExpanded),
                      child: Text(_isDescExpanded ? '收起' : '展开',
                          style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13))),
                ],
              );
            }),
          const SizedBox(height: 12),
          if (detail.author.isNotEmpty) _infoRow('作者', detail.author),
          if (detail.category.isNotEmpty) _infoRow('分类', detail.category),
          if (detail.status != null) _infoRow('状态', detail.status!),
          _infoRow('章节', '${detail.chapters.length} 章'),
        ],
      ),
    );
  }

  Widget _buildChapterHeader(NovelDetail detail) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      margin: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Text('目录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text('${detail.chapters.length}章', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const Spacer(),
          Icon(Icons.sort, size: 20, color: Colors.grey[500]),
        ],
      ),
    );
  }

  Widget _buildChapterTile(NovelChapter ch, int index) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Text('${index + 1}', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        title: Text(ch.name, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        dense: true,
        onTap: () => _readNovel(index),
      ),
    );
  }

  Widget _buildBottomBar(NovelDetail? detail) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
      child: Row(
        children: [
          // 收藏
          GestureDetector(
            onTap: _toggleFavorite,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.grey, size: 24),
              Text(_isFavorite ? '已收藏' : '收藏',
                  style: TextStyle(fontSize: 10, color: _isFavorite ? Colors.red : Colors.grey)),
            ]),
          ),
          const SizedBox(width: 32),
          // 书架
          Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.bookmark_border, color: Colors.grey, size: 24),
            Text('书架', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(width: 32),
          // 分享
          Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.share_outlined, color: Colors.grey, size: 24),
            Text('分享', style: TextStyle(fontSize: 10, color: Colors.grey)),
          ]),
          const SizedBox(width: 20),
          // 开始阅读
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
              onPressed: detail != null && detail.chapters.isNotEmpty
                  ? () => _readNovel(0) : null,
              child: Text(
                detail != null && detail.chapters.isNotEmpty
                    ? '开始阅读: ${detail.chapters.first.name}'
                    : '暂无章节',
                style: const TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11)));

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 50, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
    ]));

  Widget _buildError() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
      const SizedBox(height: 12),
      Text('加载失败', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
      const SizedBox(height: 8),
      ElevatedButton(onPressed: () { setState(() => _isLoading = true); _loadDetail(); },
          child: const Text('重试')),
    ]));

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

  void _readNovel(int chapterIndex) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NovelReaderScreen(
        novel: _detail ?? NovelDetail(
          id: widget.content.id, title: widget.content.title, cover: widget.content.cover),
        startChapterIndex: chapterIndex, source: source)));
  }
}
