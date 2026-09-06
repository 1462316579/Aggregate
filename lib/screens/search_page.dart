import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import '../providers/source_provider.dart';
import 'detail_page.dart';

/// Miru 风格搜索：聚合搜索或按内容类型筛选，不提供指定源搜索。
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _query = TextEditingController();
  SearchMode _mode = SearchMode.aggregate;
  SearchResult? _result;
  List<String> _history = <String>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final values = await context.read<SourceProvider>().searchHistory();
    if (mounted) setState(() => _history = values);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    setState(() => _loading = true);
    final provider = context.read<SourceProvider>();
    await provider.addSearchHistory(query);
    final result = await provider.search(query, type: _mode.type);
    if (!mounted) return;
    setState(() {
      _result = result;
      _loading = false;
      _history = [query, ..._history.where((item) => item != query)].take(30).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: '搜索视频、漫画、小说、音乐',
            border: InputBorder.none,
          ),
          onSubmitted: _submit,
        ),
        actions: <Widget>[
          IconButton(icon: const Icon(Icons.search), onPressed: () => _submit(_query.text)),
          PopupMenuButton<SearchMode>(
            icon: const Icon(Icons.tune),
            tooltip: '搜索范围',
            onSelected: (mode) => setState(() {
              _mode = mode;
              _result = null;
            }),
            itemBuilder: (_) => SearchMode.values.map((mode) => PopupMenuItem<SearchMode>(
              value: mode,
              child: Text(mode.label),
            )).toList(),
          ),
        ],
        bottom: result == null ? null : TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: <Widget>[
            Tab(text: '全部 (${result.items.length})'),
            Tab(text: '视频 (${_count(ContentType.video)})'),
            Tab(text: '漫画 (${_count(ContentType.comic)})'),
            Tab(text: '小说 (${_count(ContentType.novel)})'),
            Tab(text: '音乐 (${_count(ContentType.music)})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : result == null
              ? _empty()
              : TabBarView(
                  controller: _tabs,
                  children: <Widget>[
                    _grid(result.items),
                    _grid(_itemsOf(ContentType.video)),
                    _grid(_itemsOf(ContentType.comic)),
                    _grid(_itemsOf(ContentType.novel)),
                    _grid(_itemsOf(ContentType.music)),
                  ],
                ),
    );
  }

  int _count(ContentType type) => _itemsOf(type).length;

  List<MediaItem> _itemsOf(ContentType type) =>
      (_result?.items ?? <MediaItem>[]).where((item) => item.type == type).toList();

  Widget _empty() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        SegmentedButton<SearchMode>(
          segments: const <ButtonSegment<SearchMode>>[
            ButtonSegment(value: SearchMode.aggregate, label: Text('聚合')),
            ButtonSegment(value: SearchMode.video, label: Text('视频')),
            ButtonSegment(value: SearchMode.comic, label: Text('漫画')),
            ButtonSegment(value: SearchMode.novel, label: Text('小说')),
            ButtonSegment(value: SearchMode.music, label: Text('音乐')),
          ],
          selected: <SearchMode>{_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.first),
        ),
        const SizedBox(height: 28),
        if (_history.isNotEmpty) ...<Widget>[
          const Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _history.map((item) => ActionChip(
              label: Text(item),
              onPressed: () {
                _query.text = item;
                _submit(item);
              },
            )).toList(),
          ),
          const SizedBox(height: 28),
        ],
        Text(
          _mode == SearchMode.aggregate ? '聚合搜索所有已启用的扩展源。' : '当前只搜索${_mode.label.replaceAll('只搜', '')}。',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _grid(List<MediaItem> items) {
    if (items.isEmpty) return const Center(child: Text('暂无结果'));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: .62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => DetailPage(item: items[i])),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              items[i].cover,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: Icon(_icon(items[i].type)),
              ),
            ),
          )),
          const SizedBox(height: 5),
          Text(items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(items[i].sourceId, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      ),
    );
  }

  IconData _icon(ContentType type) {
    switch (type) {
      case ContentType.video: return Icons.movie_outlined;
      case ContentType.comic: return Icons.auto_stories_outlined;
      case ContentType.novel: return Icons.menu_book_outlined;
      case ContentType.music: return Icons.music_note_outlined;
    }
  }
}

enum SearchMode {
  aggregate('聚合搜索', null),
  video('只搜视频', ContentType.video),
  comic('只搜漫画', ContentType.comic),
  novel('只搜小说', ContentType.novel),
  music('只搜音乐', ContentType.music);

  final String label;
  final ContentType? type;
  const SearchMode(this.label, this.type);
}
