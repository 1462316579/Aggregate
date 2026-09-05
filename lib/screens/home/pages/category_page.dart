/// 亦搜风格分类页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/source_provider.dart';
import '../../../models/video_content.dart';
import '../../detail/detail_screen.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});
  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<VideoContent> _items = [];
  bool _isLoading = true;
  int _currentPage = 1;
  String? _selectedCategoryId;
  final ScrollController _scrollController = ScrollController();

  final _categories = const [
    {'id': '', 'name': '全部'},
    {'id': '1', 'name': '电影'},
    {'id': '2', 'name': '连续剧'},
    {'id': '3', 'name': '综艺'},
    {'id': '4', 'name': '动漫'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) _loadMore();
    });
    _loadData(refresh: true);
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) { _currentPage = 1; _items = []; }
    final provider = context.read<SourceProvider>();
    try {
      final newItems = await provider.getCategory(
        _selectedCategoryId?.isEmpty == true ? null : _selectedCategoryId,
        page: _currentPage);
      setState(() {
        _items = refresh ? newItems : [..._items, ...newItems];
        _currentPage++;
        _isLoading = false;
      });
    } catch (_) { setState(() => _isLoading = false); }
  }

  void _loadMore() => _loadData();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 分类标签
        SizedBox(
          height: 44,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final sel = cat['id'] == _selectedCategoryId;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCategoryId = cat['id']);
                  _loadData(refresh: true);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF2196F3) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(cat['name']!, style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[700], fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            },
          ),
        ),
        // 列表
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () => _loadData(refresh: true),
                  child: GridView.builder(
                    controller: _scrollController,
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

  Widget _buildCard(VideoContent video) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => DetailScreen(video: video))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(video.pic, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(Icons.movie, color: Colors.grey[400])),
            Positioned(top: 0, left: 0, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))),
              child: Text(video.remark ?? '', style: const TextStyle(color: Colors.white, fontSize: 10)),
            )),
          ]),
        )),
        const SizedBox(height: 4),
        Text(video.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
        Text(video.category ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
      ]),
    );
  }
}
