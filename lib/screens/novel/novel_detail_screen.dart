/// 小说详情页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/unified_content.dart';
import '../../models/novel_detail.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
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

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!,
    );
    final detail = await SpiderServiceV2.getNovelDetail(source, widget.content.id);
    setState(() { _detail = detail; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final isTV = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? const Center(child: Text('加载失败'))
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: isTV ? 350 : 250,
                      pinned: true,
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(detail.title, style: const TextStyle(fontSize: 15)),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: detail.cover, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0xFF0F0F0F)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(spacing: 8, children: [
                              _tag(detail.author, Colors.green),
                              if (detail.category.isNotEmpty) _tag(detail.category, Colors.blue),
                              if (detail.status != null) _tag(detail.status!, Colors.orange),
                            ]),
                            const SizedBox(height: 12),
                            if (detail.description.isNotEmpty)
                              Text(detail.description,
                                  maxLines: 5, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5)),
                            const SizedBox(height: 16),
                            // 开始阅读按钮
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.menu_book),
                                label: Text(detail.chapters.isNotEmpty
                                    ? '开始阅读: ${detail.chapters.first.name}' : '暂无章节'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: detail.chapters.isNotEmpty
                                    ? () => _readNovel(detail, 0) : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 章节列表
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text('目录 (${detail.chapters.length}章)',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final ch = detail.chapters[index];
                          return ListTile(
                            title: Text(ch.name, style: const TextStyle(fontSize: 14)),
                            trailing: Text('${index + 1}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            dense: true,
                            onTap: () => _readNovel(detail, index),
                          );
                        },
                        childCount: detail.chapters.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color, fontSize: 11)),
  );

  void _readNovel(NovelDetail detail, int startChapter) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!,
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => NovelReaderScreen(
        novel: detail, startChapterIndex: startChapter, source: source,
      ),
    ));
  }
}
