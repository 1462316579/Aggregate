/// 视频详情页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../../services/app_config.dart';
import '../player/player_screen.dart';

class DetailScreen extends StatefulWidget {
  final VideoContent video;
  const DetailScreen({super.key, required this.video});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  VideoContent? _detail;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadDetail();
    _checkFavorite();
  }

  Future<void> _loadDetail() async {
    final provider = context.read<SourceProvider>();
    final detail = await provider.getDetail(widget.video.id);
    setState(() { _detail = detail ?? widget.video; _isLoading = false; });
  }

  Future<void> _checkFavorite() async {
    final fav = await AppConfig.isFavorite(widget.video.id);
    setState(() => _isFavorite = fav);
  }

  @override
  Widget build(BuildContext context) {
    final video = _detail ?? widget.video;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(slivers: [
              SliverAppBar(expandedHeight: 250, pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(video.name, style: const TextStyle(fontSize: 15)),
                  background: Stack(fit: StackFit.expand, children: [
                    Image.network(video.pic, fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.3),
                      errorBuilder: (_, __, ___) => const SizedBox()),
                    const DecoratedBox(decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xFF0F0F0F)]))),
                  ]),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : null),
                    onPressed: _toggleFavorite),
                ],
              ),
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, children: [
                    if (video.category != null) _chip(video.category!),
                    if (video.year != null) _chip(video.year!),
                    if (video.area != null) _chip(video.area!),
                    if (video.remark != null) _chip(video.remark!, color: Colors.blue),
                  ]),
                  const SizedBox(height: 12),
                  if (video.desc != null) Text(video.desc!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.6)),
                  const SizedBox(height: 16),
                  if (video.episodes != null && video.episodes!.isNotEmpty)
                    const Text('选集', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
              )),
              if (video.episodes != null)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2.2),
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) {
                        final ep = video.episodes![i];
                        return InkWell(
                          onTap: () => _playEpisode(ep),
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.grey[200]!)),
                            alignment: Alignment.center,
                            child: Text(ep.name, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        );
                      },
                      childCount: video.episodes!.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ]),
      floatingActionButton: video.episodes != null && video.episodes!.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _playEpisode(video.episodes!.first),
              backgroundColor: const Color(0xFF2196F3),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text('播放 ${video.episodes!.first.name}', style: const TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  Widget _chip(String text, {Color? color}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: (color ?? Colors.grey)!.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: TextStyle(color: color ?? Colors.grey, fontSize: 11)));

  void _toggleFavorite() async {
    if (_isFavorite) {
      await AppConfig.removeFavorite(widget.video.id);
    } else {
      await AppConfig.addFavorite({'id': widget.video.id, 'name': widget.video.name, 'pic': widget.video.pic});
    }
    setState(() => _isFavorite = !_isFavorite);
  }

  void _playEpisode(VideoEpisode ep) {
    final provider = context.read<SourceProvider>();
    if (provider.activeSource == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(title: '${widget.video.name} - ${ep.name}', url: ep.url)));
  }
}
