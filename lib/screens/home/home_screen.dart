/// 首页 — 搜索 + 横向标签 + 内容流
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/source_provider.dart';
import '../../models/video_content.dart';
import '../search/search_screen.dart';
import '../detail/detail_screen.dart';
import '../setting/setting_screen.dart';
import '../player/player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _currentTab == 0 ? _HomePage() : _MinePage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab, onTap: (i) => setState(() => _currentTab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: '我的'),
        ],
      ),
    );
  }
}

/// 首页 Tab
class _HomePage extends StatefulWidget { @override State<_HomePage> createState() => _HomePageState(); }
class _HomePageState extends State<_HomePage> {
  List<VideoContent> _items = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  final _tabs = ['全部', '电影', '连续剧', '综艺', '动漫'];

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final provider = context.read<SourceProvider>();
    final items = await provider.getCategory(page: 1);
    setState(() { _items = items; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 搜索栏
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SearchScreen())),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 48, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(24)),
          child: Row(children: [
            Icon(Icons.search, color: Colors.grey[500], size: 22),
            const SizedBox(width: 8),
            Text('搜索影视、漫画、小说...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ]),
        ),
      ),
      // 分类标签
      SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          itemCount: _tabs.length,
          itemBuilder: (ctx, i) {
            final sel = i == _selectedTab;
            return GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF2196F3) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20)),
                alignment: Alignment.center,
                child: Text(_tabs[i], style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[700], fontSize: 13,
                    fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
              ),
            );
          },
        ),
      ),
      // 内容
      Expanded(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, childAspectRatio: 0.6, mainAxisSpacing: 10, crossAxisSpacing: 10),
                  itemCount: _items.length,
                  itemBuilder: (ctx, i) => _buildCard(_items[i]),
                ),
              ),
      ),
    ]);
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

class _MinePage extends StatelessWidget {
  _MinePage();
  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const SizedBox(height: 48),
      Container(
        padding: const EdgeInsets.all(16), color: Colors.white,
        child: Row(children: [
          CircleAvatar(radius: 32, backgroundColor: const Color(0xFF2196F3),
            child: const Icon(Icons.person, color: Colors.white, size: 36)),
          const SizedBox(width: 14),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('宏曦聚合', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('包名: juhe.homes.app2026', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      Container(color: Colors.white, child: Column(children: [
        ListTile(leading: const Icon(Icons.settings), title: const Text('设置'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingScreen()))),
        ListTile(leading: const Icon(Icons.history), title: const Text('观看历史'),
          trailing: const Icon(Icons.chevron_right), onTap: () {}),
        ListTile(leading: const Icon(Icons.favorite), title: const Text('我的收藏'),
          trailing: const Icon(Icons.chevron_right), onTap: () {}),
      ])),
      const SizedBox(height: 20),
      Center(child: Text('v1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
    ]);
  }
}
