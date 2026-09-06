import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import '../providers/source_provider.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _query = TextEditingController();
  final _sourceId = ValueNotifier<String?>(null);
  SearchMode _mode = SearchMode.aggregate;
  SearchResult? _result;
  List<String> _history = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
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
    _sourceId.dispose();
    super.dispose();
  }

  Future<void> _submit(String value) async {
    final query = value.trim();
    if (query.isEmpty) return;
    final provider = context.read<SourceProvider>();
    final only = _mode == SearchMode.single && _sourceId.value != null
        ? provider.sourceFor(_sourceId.value!)
        : null;
    if (_mode == SearchMode.single && only == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择搜索源')));
      return;
    }
    setState(() => _loading = true);
    await provider.addSearchHistory(query);
    final result = await provider.search(query, type: _mode.type, only: only);
    if (mounted) setState(() {
      _result = result;
      _loading = false;
      _history = [query, ..._history.where((item) => item != query)].take(30).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: TextField(
          controller: _query,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(hintText: '搜索视频、漫画、小说', border: InputBorder.none),
          onSubmitted: _submit,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _submit(_query.text)),
          PopupMenuButton<SearchMode>(
            icon: const Icon(Icons.tune),
            onSelected: (mode) => setState(() => _mode = mode),
            itemBuilder: (_) => SearchMode.values.map((mode) => PopupMenuItem(value: mode, child: Text(mode.label))).toList(),
          ),
        ],
        bottom: _result == null ? null : TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: [
            Tab(text: '全部 (${_result!.items.length})'),
            Tab(text: '视频 (${_result!.items.where((e) => e.type == ContentType.video).length})'),
            Tab(text: '漫画 (${_result!.items.where((e) => e.type == ContentType.comic).length})'),
            Tab(text: '小说 (${_result!.items.where((e) => e.type == ContentType.novel).length})'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _result == null
              ? _empty(provider)
              : TabBarView(controller: _tabs, children: [
                  _grid(_result!.items),
                  _grid(_result!.items.where((e) => e.type == ContentType.video).toList()),
                  _grid(_result!.items.where((e) => e.type == ContentType.comic).toList()),
                  _grid(_result!.items.where((e) => e.type == ContentType.novel).toList()),
                ]),
    );
  }

  Widget _empty(SourceProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SegmentedButton<SearchMode>(
          segments: const [
            ButtonSegment(value: SearchMode.aggregate, label: Text('聚合')),
            ButtonSegment(value: SearchMode.video, label: Text('视频')),
            ButtonSegment(value: SearchMode.comic, label: Text('漫画')),
            ButtonSegment(value: SearchMode.novel, label: Text('小说')),
            ButtonSegment(value: SearchMode.single, label: Text('指定源')),
          ],
          selected: {_mode},
          onSelectionChanged: (value) => setState(() => _mode = value.first),
        ),
        if (_mode == SearchMode.single) ...[
          const SizedBox(height: 16),
          ValueListenableBuilder<String?>(
            valueListenable: _sourceId,
            builder: (_, selected, __) => DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(labelText: '选择源', border: OutlineInputBorder()),
              items: provider.sources.map((source) => DropdownMenuItem(value: source.id, child: Text(source.name))).toList(),
              onChanged: (value) => _sourceId.value = value,
            ),
          ),
        ],
        const SizedBox(height: 28),
        if (_history.isNotEmpty) ...[
          const Text('搜索历史', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _history.map((item) => ActionChip(label: Text(item), onPressed: () { _query.text = item; _submit(item); })).toList()),
        ],
        const SizedBox(height: 28),
        Text('聚合搜索会并行请求所有已启用源；指定源模式只请求你选择的源。', style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }

  Widget _grid(List<MediaItem> items) {
    if (items.isEmpty) return const Center(child: Text('暂无结果'));
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: .62, crossAxisSpacing: 12, mainAxisSpacing: 16),
      itemCount: items.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: items[i]))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(items[i].cover, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.movie))),
          )),
          const SizedBox(height: 5),
          Text(items[i].title, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(items[i].sourceId, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ]),
      ),
    );
  }
}

enum SearchMode {
  aggregate('聚合搜索', null),
  video('只搜视频', ContentType.video),
  comic('只搜漫画', ContentType.comic),
  novel('只搜小说', ContentType.novel),
  single('指定源搜索', null);

  final String label;
  final ContentType? type;
  const SearchMode(this.label, this.type);
}
