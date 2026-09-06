import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import 'package:hongxi/providers/source_provider.dart';
import 'package:hongxi/services/app_config.dart';
import 'player_page.dart';
import 'reader_page.dart';

class DetailPage extends StatefulWidget {
  final MediaItem item;
  const DetailPage({super.key, required this.item});
  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late MediaItem _item;
  bool _loading = true;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _item = widget.item;
    _load();
  }

  Future<void> _load() async {
    final updated = await context.read<SourceProvider>().detail(widget.item);
    final favorite = await AppConfig.isFavorite(widget.item);
    if (mounted) setState(() {
      _item = updated ?? widget.item;
      _favorite = favorite;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff7f7f7),
      body: _loading ? const Center(child: CircularProgressIndicator()) : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            actions: [
              IconButton(icon: Icon(_favorite ? Icons.favorite : Icons.favorite_border), onPressed: _toggleFavorite),
              IconButton(icon: const Icon(Icons.open_in_browser), onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              background: Stack(fit: StackFit.expand, children: [
                Image.network(_item.cover, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.blueGrey)),
                const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xff101010)]))),
                Align(alignment: Alignment.bottomLeft, child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 52),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(_item.cover, width: 88, height: 124, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 88, height: 124, color: Colors.grey[300]))),
                    const SizedBox(width: 14),
                    Expanded(child: Text(_item.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  ]),
                )),
              ]),
            ),
          ),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 8, children: [
                if (_item.category != null) _tag(_item.category!),
                if (_item.year != null) _tag(_item.year!),
                if (_item.remark != null) _tag(_item.remark!, color: Colors.indigo),
              ]),
              const SizedBox(height: 14),
              Text(_item.description.isEmpty ? '暂无简介' : _item.description, style: TextStyle(color: Colors.grey[600], height: 1.6)),
              if (_item.author != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text('作者/演员：${_item.author}', style: TextStyle(color: Colors.grey[600], fontSize: 13))),
              const SizedBox(height: 22),
              Text(_item.type == ContentType.video ? '剧集 (${_item.episodes.length})' : '章节 (${_item.episodes.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
            ]),
          )),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2.2, crossAxisSpacing: 8, mainAxisSpacing: 8),
              delegate: SliverChildBuilderDelegate((context, index) {
                final ep = _item.episodes[index];
                return OutlinedButton(
                  onPressed: () => _openEpisode(index),
                  child: Text(ep.title.isEmpty ? '第 ${index + 1} 集' : ep.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                );
              }, childCount: _item.episodes.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: _item.episodes.isEmpty ? null : FloatingActionButton.extended(onPressed: () => _openEpisode(0), icon: Icon(_item.type == ContentType.video ? Icons.play_arrow : Icons.menu_book), label: Text(_item.type == ContentType.video ? '立即播放' : '开始阅读')),
    );
  }

  Widget _tag(String value, {Color color = Colors.grey}) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(5)), child: Text(value, style: TextStyle(color: color, fontSize: 11)));

  Future<void> _toggleFavorite() async { await AppConfig.toggleFavorite(_item); setState(() => _favorite = !_favorite); }

  void _openEpisode(int index) {
    if (_item.type == ContentType.video) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(item: _item, episode: _item.episodes[index])));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderPage(item: _item, initialIndex: index)));
    }
  }
}
