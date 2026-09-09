/// 亦搜风格音乐页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/source_provider.dart';
import '../../../models/unified_content.dart';
import '../../../models/music_detail.dart';
import '../../../services/spider_service_v2.dart';
import '../../../services/music_player_service.dart';
import '../../music/music_player_screen.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});
  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  List<UnifiedContent> _items = [];
  bool _isLoading = true;
  String _selectedCategory = '全部';
  final _categories = ['全部', '流行', '摇滚', '民谣', '电子', '古风', '说唱'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final provider = context.read<SourceProvider>();
    final sources = provider.musicSources;
    if (sources.isEmpty) { setState(() { _items = []; _isLoading = false; }); return; }
    List<UnifiedContent> all = [];
    for (var s in sources.take(3)) {
      try { all.addAll(await SpiderServiceV2.searchMusic(s, '热门')); } catch (_) {}
    }
    setState(() { _items = all; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final sel = _categories[i] == _selectedCategory;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = _categories[i]),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF9C27B0) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(_categories[i], style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[700], fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.music_note, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('暂无音乐源', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (ctx, i) => _buildTrackTile(_items[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildTrackTile(UnifiedContent item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: item.cover, width: 48, height: 48, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 48, height: 48, color: Colors.grey[200],
            child: const Icon(Icons.music_note, color: Colors.grey, size: 22)),
        ),
      ),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
      subtitle: Text(item.author, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: IconButton(
        icon: Icon(Icons.play_circle_outline, color: Colors.grey[400], size: 28),
        onPressed: () => _playItem(item),
      ),
      onTap: () => _playItem(item),
    );
  }

  void _playItem(UnifiedContent item) {
    final provider = context.read<SourceProvider>();
    final source = provider.sources.firstWhere(
      (s) => s.key == item.sourceKey, orElse: () => provider.activeSource!);
    final track = MusicTrack(id: item.id, name: item.title, author: item.author, cover: item.cover);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MusicPlayerScreen(track: track, source: source)));
  }
}
