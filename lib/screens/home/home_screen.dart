import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../services/app_config.dart';
import '../../services/plugin_service.dart';
import '../../services/spider_service_v2.dart';
import '../../services/video_sniffer_service.dart';
import '../../models/plugin.dart';
import '../../models/unified_content.dart';
import '../../models/video_source.dart';
import '../../l10n/app_localizations.dart';
import '../favorites_page.dart';
import '../plugin/plugin_page.dart';
import '../settings/settings_page.dart';
import '../detail_page.dart';
import '../player_page.dart';
import '../sniffer/sniffer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  int _selectedTab = 0;
  List<UnifiedContent> _searchResults = [];
  bool _searching = false;
  String _lastQuery = '';
  List<SourcePlugin> _plugins = [];

  static const _videoIcon = Icons.movie_filter;
  static const _favoritesIcon = Icons.favorite;
  static const _pluginIcon = Icons.extension;
  static const _settingsIcon = Icons.settings;

  static const _tabs = [
    '首页',
    '收藏',
    '插件',
    '设置',
  ];

  static const _icons = [
    _videoIcon,
    _favoritesIcon,
    _pluginIcon,
    _settingsIcon,
  ];

  @override
  void initState() {
    super.initState();
    _loadPlugins();
    _loadSearchHistory();
  }

  Future<void> _loadPlugins() async {
    _plugins = await PluginService.list();
  }

  Future<void> _loadSearchHistory() async {
    final history = await AppConfig.getSearchHistory();
    if (history.isNotEmpty) {
      _lastQuery = history.first;
      _searchController.text = '';
    }
  }

  Future<void> _search() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _searching = true;
      _lastQuery = query;
      _searchResults = [];
    });

    // 保存搜索历史
    await AppConfig.saveSearchHistory(query);

    // 从插件获取数据
    final sources = await AppConfig.getSources();
    if (sources.isEmpty) {
      setState(() {
        _searching = false;
      });
      return;
    }

    // 搜索所有源
    final allResults = <UnifiedContent>[];
    for (final source in sources) {
      try {
        final results = await SpiderServiceV2.searchVideo(source, query);
        allResults.addAll(results);
      } catch (_) {
        // 忽略单个源错误
      }
    }

    setState(() {
      _searchResults = allResults;
      _searching = false;
    });
  }

  Future<void> _searchFromHistory(String query) async {
    _searchController.text = query;
    await _search();
  }

  void _goToDetail(UnifiedContent item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailPage(item: item)),
    );
  }

  void _goToPlayer(UnifiedContent item) {
    // 需要从 item 中获取 episode
    // 暂时移除播放功能，因为需要 episode 参数
  }

  void _onTabChanged(int index) {
    if (!mounted) return;
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: '搜索影视、漫画、小说、音乐...',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SnifferScreen()),
            ),
            icon: const Icon(Icons.sensors, size: 22),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _searching ? null : _search,
            icon: _searching
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_searching) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('搜索中...'),
          ],
        ),
      );
    }

    if (_searchResults.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          return _buildContentCard(item);
        },
      );
    }

    // 显示搜索历史
    final history = AppConfig.getSearchHistory();
    return FutureBuilder<List<String>>(
      future: history,
      builder: (context, snapshot) {
        final historyList = snapshot.data ?? [];
        if (historyList.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.history, size: 18),
                  SizedBox(width: 8),
                  Text('搜索历史', style: TextStyle(fontWeight: FontWeight.w600)),
                  Spacer(),
                  TextButton(
                    onPressed: () async {
                      await AppConfig.clearSearchHistory();
                      setState(() {});
                    },
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.6,
                ),
                padding: const EdgeInsets.all(12),
                itemCount: historyList.length,
                itemBuilder: (context, index) {
                  final query = historyList[index];
                  return GestureDetector(
                    onTap: () => _searchFromHistory(query),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.search, size: 16, color: Colors.grey.shade600),
                          const Spacer(),
                          Text(
                            query,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContentCard(UnifiedContent item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      child: InkWell(
        onTap: () => _goToDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.cover.isNotEmpty
                    ? Image.network(
                        item.cover,
                        width: 60,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.movie),
                      )
                    : Container(
                        width: 60,
                        height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.movie),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (item.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (item.year?.isNotEmpty == true)
                      Text(item.year!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (item.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '暂无内容',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '搜索影视、漫画、小说、音乐',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildHomeTab(),
                FavoritesPage(),
                PluginPage(),
                SettingsPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedTab,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onTabChanged,
        items: [
          for (int i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(icon: Icon(_icons[i]), label: _tabs[i]),
        ],
      ),
    );
  }
}
