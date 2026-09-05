/// 亦搜风格小说页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../providers/source_provider.dart';
import '../../../models/unified_content.dart';
import '../../../services/spider_service_v2.dart';
import '../../novel/novel_detail_screen.dart';

class NovelPage extends StatefulWidget {
  const NovelPage({super.key});
  @override
  State<NovelPage> createState() => _NovelPageState();
}

class _NovelPageState extends State<NovelPage> {
  List<UnifiedContent> _items = [];
  bool _isLoading = true;
  String _selectedCategory = '全部';
  final _categories = ['全部', '玄幻', '武侠', '都市', '言情', '科幻', '历史'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final provider = context.read<SourceProvider>();
    final sources = provider.novelSources;
    if (sources.isEmpty) { setState(() { _items = []; _isLoading = false; }); return; }
    List<UnifiedContent> all = [];
    for (var s in sources.take(3)) {
      try { all.addAll(await SpiderServiceV2.searchNovel(s, '')); } catch (_) {}
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
                    color: sel ? const Color(0xFF4CAF50) : Colors.grey[100],
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
                      Icon(Icons.menu_book, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text('暂无小说源', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, childAspectRatio: 0.6,
                          mainAxisSpacing: 10, crossAxisSpacing: 10),
                        itemCount: _items.length,
                        itemBuilder: (ctx, i) => _buildCard(_items[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildCard(UnifiedContent item) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => NovelDetailScreen(content: item))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            CachedNetworkImage(imageUrl: item.cover, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.menu_book, color: Colors.grey[400])),
            if (item.status != null) Positioned(top: 0, right: 0, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: Color(0xFF4CAF50),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8))),
              child: Text(item.status!, style: const TextStyle(color: Colors.white, fontSize: 10)),
            )),
          ]),
        )),
        const SizedBox(height: 4),
        Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        Text('${item.author}', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }
}
