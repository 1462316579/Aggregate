import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_config.dart';
import '../models/content.dart';
import '../l10n/app_localizations.dart';
import 'detail_page.dart';
import 'plugin/plugin_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTab = 'video';
  List<MediaItem> _items = [];
  bool _loading = true;

  static const _tabs = <String, String>{
    'video': 'media',
    'comic': 'comic',
    'novel': 'novel',
    'music': 'music',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadFavorites();
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    setState(() => _selectedTab = _tabs.keys.elementAt(_tabController.index));
  }

  Future<void> _loadFavorites() async {
    final list = await AppConfig.getFavorites();
    setState(() {
      _items = list.map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e))).toList();
      _loading = false;
    });
  }

  Future<void> _removeFavorite(MediaItem item) async {
    await AppConfig.toggleFavorite(item);
    await _loadFavorites();
  }

  void _showCategoryMenu(String type) {
    final s = AppStrings.of(AppConfig.language);
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Material(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _categoryTile(Icons.videocam, s.t('video'), 'video'),
              _categoryTile(Icons.menu_book, s.t('comic'), 'comic'),
              _categoryTile(Icons.menu_book, s.t('novel'), 'novel'),
              _categoryTile(Icons.music_note, s.t('music'), 'music'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(IconData icon, String label, String category) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        final index = ['video', 'comic', 'novel', 'music'].indexOf(category);
        if (index >= 0) {
          _tabController.animateTo(index);
        }
      },
    );
  }

  Future<void> _openDetail(MediaItem item) async {
    if (!mounted) return;
    await Navigator.push<void>(context, MaterialPageRoute<void>(
      builder: (_) => DetailPage(item: item),
    ));
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(AppConfig.language);
    final filtered = _selectedTab == 'media'
        ? _items.where((e) => e.type == 'video').toList()
        : _items.where((e) => e.type == _selectedTab).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('favorites')),
        actions: <Widget>[
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) => setState(() => _selectedTab = value),
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'video', child: Text(s.t('video'))),
              PopupMenuItem<String>(value: 'comic', child: Text(s.t('comic'))),
              PopupMenuItem<String>(value: 'novel', child: Text(s.t('novel'))),
              PopupMenuItem<String>(value: 'music', child: Text(s.t('music'))),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _items.isEmpty ? null : () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(s.t('clearHistory')),
                  content: Text(s.t('clearHistoryConfirm')),
                  actions: <Widget>[
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.t('cancel'))),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.t('delete'))),
                  ],
                ),
              );
              if (confirm == true) {
                await _clearAll();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: <Tab>[
            Tab(icon: const Icon(Icons.videocam), text: s.t('video')),
            Tab(icon: const Icon(Icons.menu_book), text: s.t('comic')),
            Tab(icon: const Icon(Icons.menu_book), text: s.t('novel')),
            Tab(icon: const Icon(Icons.music_note), text: s.t('music')),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
              ? Center(child: Text(s.t('emptyFavorites')))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _gridItem(context, filtered[index]),
                ),
    );
  }

  Widget _gridItem(BuildContext context, MediaItem item) {
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Stack(
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.cover),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Text(
              item.title,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _removeFavorite(item),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: Colors.red, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAll() async {
    await AppConfig.clearFavorites();
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(AppConfig.language).t('cleared'))),
      );
    }
  }
}
