/// 搜索页 - 支持多源聚合搜索
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  Map<String, List<VideoContent>> _results = {};
  bool _isSearching = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _query = query;
      _results = {};
    });

    final provider = context.read<SourceProvider>();
    final results = await provider.searchAll(query);

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  int get _totalResults {
    return _results.values.fold(0, (sum, list) => sum + list.length);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    final isTV = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索影片名称...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: _search,
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          TextButton(
            onPressed: () => _search(_searchController.text),
            child: const Text('搜索'),
          ),
        ],
      ),
      body: _isSearching
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('正在从 ${provider.sources.where((s) => s.type != 4).length} 个源搜索...',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            )
          : _results.isEmpty && _query.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text('未找到「$_query」相关结果',
                          style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                    ],
                  ),
                )
              : _results.isEmpty
                  ? _buildSearchHints()
                  : _buildResults(isTV),
    );
  }

  Widget _buildSearchHints() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text('搜索你感兴趣的影片',
              style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['流浪地球', '三体', '狂飙', '繁花', '庆余年']
                .map((hint) => ActionChip(
                      label: Text(hint),
                      onPressed: () {
                        _searchController.text = hint;
                        _search(hint);
                      },
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(bool isTV) {
    return CustomScrollView(
      slivers: [
        // 搜索结果统计
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('找到 $_totalResults 个结果',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${_results.length} 个源',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
        ),

        // 按源分组展示
        for (var entry in _results.entries) ...[
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(entry.key,
                        style: const TextStyle(
                            color: Colors.blue, fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  Text('${entry.value.length} 个结果',
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isTV ? 6 : 3,
                childAspectRatio: 0.65,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final video = entry.value[index];
                  return _buildVideoCard(video);
                },
                childCount: entry.value.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  Widget _buildVideoCard(VideoContent video) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailScreen(video: video)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.pic,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.grey),
                    ),
                  ),
                  if (video.remark != null && video.remark!.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(video.remark!,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(video.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
