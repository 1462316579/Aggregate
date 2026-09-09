import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/app_config.dart';
import '../models/content.dart';
import '../l10n/app_localizations.dart';
import 'detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
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
    _loadHistory();
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

  Future<void> _loadHistory() async {
    final list = await AppConfig.getHistory();
    setState(() {
      _items = list.map((e) => MediaItem.fromMap(Map<String, dynamic>.from(e), e['sourceId']?.toString() ?? '', ContentType.values.firstWhere((x) => x.name == (e['type']?.toString() ?? 'video'), orElse: () => ContentType.video))).toList();
      _loading = false;
    });
  }

  Future<void> _removeHistory(MediaItem item) async {
    final updated = _items.where((e) => e.id != item.id || e.sourceId != item.sourceId).toList();
    // Save remaining history
    await AppConfig.saveHistory(updated);
    setState(() => _items = updated);
  }

  Future<void> _clearHistory() async {
    await AppConfig.clearHistory();
    setState(() {
      _items = [];
      _loading = false;
    });
  }

  Future<void> _openDetail(MediaItem item) async {
    if (!mounted) return;
    await Navigator.push<void>(context, MaterialPageRoute<void>(
      builder: (_) => DetailPage(item: item),
    ));
    // Refresh history after returning
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(AppConfig.language);
    final filtered = _selectedTab == 'media'
        ? _items.where((e) => e.type == 'video').toList()
        : _items.where((e) => e.type == _selectedTab).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.t('history')),
        actions: <Widget>[
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
                await _clearHistory();
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
              ? Center(child: Text(s.t('emptyHistory')))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _historyItem(context, filtered[index]),
                ),
    );
  }

  Widget _historyItem(BuildContext context, MediaItem item) {
    return Dismissible(
      key: Key('${item.id}-${item.sourceId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _removeHistory(item),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(item.cover),
          backgroundColor: Colors.grey[200],
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(item.sourceName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () => _openDetail(item),
      ),
    );
  }
}
