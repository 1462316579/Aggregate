/// 漫画详情页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/unified_content.dart';
import '../../models/comic_detail.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
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
    final detail = await SpiderServiceV2.getComicDetail(source, widget.content.id);
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
                        title: Text(detail.title,
                            style: const TextStyle(fontSize: 15)),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: detail.cover, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Container(color: Colors.grey[800]),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
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
                              if (detail.author.isNotEmpty) _tag(detail.author),
                              if (detail.category.isNotEmpty) _tag(detail.category),
                              if (detail.status != null) _tag(detail.status!),
                            ]),
                            const SizedBox(height: 12),
                            if (detail.description.isNotEmpty)
                              Text(detail.description,
                                  maxLines: 5, overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.5)),
                          ],
                        ),
                      ),
                    ),
                    // 章节
                    for (var volume in detail.volumes) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(volume.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        sliver: SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isTV ? 8 : 4,
                            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.5,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final ch = volume.chapters[index];
                              return InkWell(
                                onTap: () => _readComic(detail, volume.chapters, index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(ch.name, style: const TextStyle(fontSize: 12),
                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              );
                            },
                            childCount: volume.chapters.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
    );
  }

  Widget _tag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(color: Colors.orange, fontSize: 11)),
  );

  void _readComic(ComicDetail detail, List<ComicChapter> chapters, int index) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!,
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ComicReaderScreen(
        comic: detail, chapters: chapters,
        startChapterIndex: index, source: source,
      ),
    ));
  }
}
