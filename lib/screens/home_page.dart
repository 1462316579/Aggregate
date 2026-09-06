import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import 'package:hongxi/providers/source_provider.dart';
import 'detail_page.dart';
import 'search_page.dart';

/// Miru-style discovery page: source-aware content tabs, dynamic categories,
/// recent items, and a responsive grid/list presentation.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ContentType _type = ContentType.video;
  String? _sourceId;
  String? _categoryId;
  List<MediaItem> _items = <MediaItem>[];
  List<SourceCategory> _categories = <SourceCategory>[];
  List<MediaItem> _history = <MediaItem>[];
  List<MediaItem> _favorites = <MediaItem>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocal();
    _loadRemote();
  }

  Future<void> _loadLocal() async {
    final shelf = await context.read<SourceProvider>().localShelf();
    if (!mounted) return;
    setState(() {
      _history = shelf.history;
      _favorites = shelf.favorites;
    });
  }

  Future<void> _loadRemote() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });

    final provider = context.read<SourceProvider>();
    final source = _selectedSource(provider);
    if (source == null) {
      if (!mounted) return;
      setState(() {
        _items = <MediaItem>[];
        _categories = <SourceCategory>[];
        _loading = false;
      });
      return;
    }

    try {
      final values = await provider.category(
        categoryId: _categoryId,
        type: _type,
      );
      final categories = await provider.categories(source);
      if (!mounted) return;
      setState(() {
        _items = values;
        _categories = categories;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _items = <MediaItem>[];
        _categories = <SourceCategory>[];
        _loading = false;
        _error = '$error';
      });
    }
  }

  SourceDefinition? _selectedSource(SourceProvider provider) {
    final candidates = provider.enabledSources.where((s) => s.type == _type).toList();
    if (candidates.isEmpty) return null;
    if (_sourceId != null) {
      for (final source in candidates) {
        if (source.id == _sourceId) return source;
      }
    }
    return candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    final sources = provider.enabledSources.where((s) => s.type == _type).toList();
    final source = _selectedSource(provider);
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: <Widget>[
          if (sources.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: '选择扩展源',
              icon: const Icon(Icons.source_outlined),
              onSelected: (value) {
                setState(() {
                  _sourceId = value;
                  _categoryId = null;
                });
                _loadRemote();
              },
              itemBuilder: (_) => sources.map((item) => PopupMenuItem<String>(
                value: item.id,
                child: Row(children: <Widget>[
                  Icon(item.id == source?.id ? Icons.check : Icons.circle_outlined, size: 17),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis)),
                ]),
              )).toList(),
            ),
          IconButton(
            tooltip: '刷新',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadLocal();
              _loadRemote();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadLocal();
          await _loadRemote();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            _buildSearchEntry(context),
            _buildTypeSelector(),
            if (_history.isNotEmpty) _buildMediaSection('继续观看', _history, wide),
            if (_favorites.isNotEmpty) _buildMediaSection('我的收藏', _favorites, wide),
            _buildSourceHeader(source, sources),
            if (_categories.isNotEmpty) _buildCategories(),
            _buildRemoteContent(wide),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchEntry(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push<void>(
          context,
          MaterialPageRoute<void>(builder: (_) => const SearchPage()),
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: <Widget>[
            Icon(Icons.search, color: Colors.grey[600]),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '搜索视频、漫画、小说',
              style: TextStyle(color: Colors.grey[600]),
            )),
            Icon(Icons.tune, size: 18, color: Colors.grey[600]),
          ]),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SegmentedButton<ContentType>(
        segments: const <ButtonSegment<ContentType>>[
          ButtonSegment(value: ContentType.video, icon: Icon(Icons.movie_outlined), label: Text('视频')),
          ButtonSegment(value: ContentType.comic, icon: Icon(Icons.auto_stories_outlined), label: Text('漫画')),
          ButtonSegment(value: ContentType.novel, icon: Icon(Icons.menu_book_outlined), label: Text('小说')),
        ],
        selected: <ContentType>{_type},
        onSelectionChanged: (value) {
          setState(() {
            _type = value.first;
            _sourceId = null;
            _categoryId = null;
          });
          _loadRemote();
        },
      ),
    );
  }

  Widget _buildSourceHeader(SourceDefinition? source, List<SourceDefinition> sources) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(children: <Widget>[
        const Icon(Icons.extension_outlined, size: 19),
        const SizedBox(width: 7),
        Text(_typeLabel(_type), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        if (source != null)
          Flexible(child: Text(
            source.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          )),
        const Spacer(),
        Text('${sources.length} 个源', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ]),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final isAll = index == 0;
          final category = isAll ? null : _categories[index - 1];
          final selected = _categoryId == category?.id || (isAll && _categoryId == null);
          return ChoiceChip(
            label: Text(isAll ? '全部' : category!.name),
            selected: selected,
            onSelected: (_) {
              setState(() => _categoryId = category?.id);
              _loadRemote();
            },
          );
        },
      ),
    );
  }

  Widget _buildRemoteContent(bool wide) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _empty('源请求失败', '检查源地址后点击右上角刷新');
    }
    return _items.isEmpty ? _empty('暂无内容', '当前源没有返回可展示的数据') : _grid(_items, wide);
  }

  Widget _buildMediaSection(String title, List<MediaItem> items, bool wide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(children: <Widget>[
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${items.length}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
        SizedBox(
          height: wide ? 220 : 190,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) => _card(items[index], width: wide ? 140 : 120),
          ),
        ),
      ],
    );
  }

  Widget _grid(List<MediaItem> values, bool wide) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      itemCount: values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: wide ? 6 : 3,
        childAspectRatio: .64,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (_, index) => _card(values[index]),
    );
  }

  Widget _card(MediaItem item, {double? width}) {
    return GestureDetector(
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => DetailPage(item: item)),
      ),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.cover,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[200],
                  alignment: Alignment.center,
                  child: Icon(_iconFor(item.type), color: Colors.grey[500]),
                ),
              ),
            )),
            const SizedBox(height: 6),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (item.remark != null)
              Text(item.remark!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _empty(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.all(44),
      child: Column(children: <Widget>[
        Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 15)),
        const SizedBox(height: 5),
        Text(subtitle, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }

  String _typeLabel(ContentType type) {
    switch (type) {
      case ContentType.video:
        return '视频';
      case ContentType.comic:
        return '漫画';
      case ContentType.novel:
        return '小说';
    }
  }

  IconData _iconFor(ContentType type) {
    switch (type) {
      case ContentType.video:
        return Icons.movie_outlined;
      case ContentType.comic:
        return Icons.auto_stories_outlined;
      case ContentType.novel:
        return Icons.menu_book_outlined;
    }
  }
}
