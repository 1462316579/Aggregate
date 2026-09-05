/// 搜索页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../../services/app_config.dart';
import '../detail/detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<VideoContent> _results = [];
  List<String> _history = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _focusNode.requestFocus();
  }

  Future<void> _loadHistory() async {
    _history = await AppConfig.getSearchHistory();
    setState(() {});
  }

  Future<void> _doSearch(String query) async {
    if (query.trim().isEmpty) return;
    await AppConfig.saveSearchHistory(query);
    _history.insert(0, query);
    setState(() { _isSearching = true; });
    final provider = context.read<SourceProvider>();
    final results = await provider.search(query);
    setState(() { _results = results; _isSearching = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: TextField(
          controller: _controller, focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: '搜索影视...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, size: 20),
          ),
          onSubmitted: _doSearch,
        ),
        actions: [
          TextButton(onPressed: () => _doSearch(_controller.text), child: const Text('搜索')),
        ],
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? _buildHistory()
              : _buildResults(),
    );
  }

  Widget _buildHistory() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_history.isNotEmpty) ...[
          const Text('搜索历史', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _history.map((h) => GestureDetector(
              onTap: () { _controller.text = h; _doSearch(h); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[200], borderRadius: BorderRadius.circular(16)),
                child: Text(h, style: const TextStyle(fontSize: 13)),
              ),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildResults() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
      itemCount: _results.length,
      itemBuilder: (ctx, i) => _buildCard(_results[i]),
    );
  }

  Widget _buildCard(VideoContent v) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(video: v))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
          clipBehavior: Clip.antiAlias,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(v.pic, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.movie, color: Colors.grey)),
            if (v.remark != null) Positioned(top: 0, left: 0, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: Color(0xFF2196F3),
                  borderRadius: BorderRadius.only(bottomRight: Radius.circular(8))),
              child: Text(v.remark!, style: const TextStyle(color: Colors.white, fontSize: 10)),
            )),
          ]),
        )),
        const SizedBox(height: 4),
        Text(v.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
      ]),
    );
  }
}
