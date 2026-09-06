import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import 'package:hongxi/providers/source_provider.dart';
import 'detail_page.dart';
import 'search_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MediaItem> _recommendations = [];
  List<MediaItem> _history = [];
  List<MediaItem> _favorites = [];
  List<SourceCategory> _categories = [];
  String? _selectedCategory;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLocal();
  }

  Future<void> _load() async {
    final provider = context.read<SourceProvider>();
    final values = await provider.category(categoryId: _selectedCategory);
    final source = provider.enabledSources.isEmpty ? null : provider.enabledSources.first;
    final categories = source == null ? <SourceCategory>[] : await provider.categories(source);
    if (!mounted) return;
    setState(() {
      _recommendations = values;
      _categories = categories;
      _loading = false;
    });
  }

  Future<void> _loadLocal() async {
    final shelf = await context.read<SourceProvider>().localShelf();
    if (!mounted) return;
    setState(() {
      _history = shelf.history;
      _favorites = shelf.favorites;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchPage()))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: () { _load(); _loadLocal(); }),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async { await _load(); await _loadLocal(); },
        child: _loading ? const Center(child: CircularProgressIndicator()) : ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('继续观看', _history.isEmpty ? '暂无记录' : null),
            _history.isEmpty ? _empty('暂无观看记录') : _horizontalCards(_history),
            const SizedBox(height: 24),
            _sectionTitle('我的收藏', _favorites.isEmpty ? '暂无收藏' : null),
            if (_favorites.isNotEmpty) _horizontalCards(_favorites),
            const SizedBox(height: 24),
            if (_categories.isNotEmpty) ...[
              const Text('源分类', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _categories.map((category) => ChoiceChip(
                label: Text(category.name),
                selected: _selectedCategory == category.id,
                onSelected: (_) { setState(() => _selectedCategory = category.id); _load(); },
              )).toList()),
              const SizedBox(height: 24),
            ],
            _sectionTitle('推荐内容', null),
            _grid(_recommendations),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String? trailing) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const Spacer(),
      if (trailing != null) Text(trailing, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
    ]),
  );

  Widget _empty(String text) => Container(
    height: 92,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Text(text, style: TextStyle(color: Colors.grey[500])),
  );

  Widget _horizontalCards(List<MediaItem> items) => SizedBox(
    height: 190,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) => _card(items[i], width: 120),
    ),
  );

  Widget _grid(List<MediaItem> items) => items.isEmpty
      ? _empty('源接口暂无内容')
      : GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: items.length,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, childAspectRatio: .62, crossAxisSpacing: 12, mainAxisSpacing: 16),
    itemBuilder: (_, i) => _card(items[i]),
  );

  Widget _card(MediaItem item, {double? width}) => GestureDetector(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(item: item))),
    child: SizedBox(
      width: width,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(item.cover, width: double.infinity, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.movie))),
        )),
        const SizedBox(height: 6),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        if (item.remark != null) Text(item.remark!, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ]),
    ),
  );
}
