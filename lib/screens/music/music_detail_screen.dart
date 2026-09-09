/// 音乐详情页 (歌单/专辑)
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/unified_content.dart';
import '../../models/music_detail.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../providers/source_provider.dart';
import '../../services/music_player_service.dart';
import '../music/music_player_screen.dart';

class MusicDetailScreen extends StatefulWidget {
  final UnifiedContent content;
  const MusicDetailScreen({super.key, required this.content});

  @override
  State<MusicDetailScreen> createState() => _MusicDetailScreenState();
}

class _MusicDetailScreenState extends State<MusicDetailScreen> {
  MusicDetail? _detail;
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

    // 如果源有歌单接口，获取歌单详情
    final detail = await SpiderServiceV2.getMusicPlaylist(source, widget.content.id);
    setState(() { _detail = detail; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
              ? _buildSingleTrackView()
              : _buildPlaylistView(detail),
    );
  }

  /// 单曲视图 (无歌单信息时)
  Widget _buildSingleTrackView() {
    final track = MusicTrack(
      id: widget.content.id,
      name: widget.content.title,
      author: widget.content.author,
      cover: widget.content.cover,
      album: widget.content.description,
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250, pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(widget.content.title, style: const TextStyle(fontSize: 15)),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: widget.content.cover, fit: BoxFit.cover,
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
                Text(widget.content.author,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('播放'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _playTrack(track),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 歌单视图
  Widget _buildPlaylistView(MusicDetail detail) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 250, pinned: true,
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
                Text(detail.author,
                    style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow),
                        label: Text('播放全部 (${detail.tracks.length}首)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: detail.tracks.isNotEmpty
                            ? () => _playTrack(detail.tracks.first)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // 歌曲列表
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final track = detail.tracks[index];
              return ListTile(
                leading: Text('${index + 1}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                title: Text(track.name, style: const TextStyle(fontSize: 14),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${track.author}${track.album != null ? ' · ${track.album}' : ''}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1),
                trailing: Text(
                  MusicPlayerService.formatDuration(Duration(seconds: track.duration)),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                onTap: () => _playTrack(track),
              );
            },
            childCount: detail.tracks.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  void _playTrack(MusicTrack track) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == widget.content.sourceKey,
      orElse: () => provider.activeSource!,
    );

    final tracks = _detail?.tracks ?? [track];
    final index = tracks.indexWhere((t) => t.id == track.id);

    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MusicPlayerScreen(
        track: track, playlist: tracks,
        startIndex: index >= 0 ? index : 0, source: source,
      ),
    ));
  }
}
