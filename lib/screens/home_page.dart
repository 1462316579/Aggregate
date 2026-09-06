import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/providers/source_provider.dart';
import 'search_page.dart';

/// Miru 风格首页：只负责发现、搜索和状态提示。
/// 内容列表、类型筛选和具体源搜索统一放在搜索页面。
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        actions: <Widget>[
          IconButton(
            tooltip: '搜索',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: wide ? 48 : 16, vertical: 20),
        children: <Widget>[
          _buildSearchEntry(context),
          const SizedBox(height: 24),
          _buildWelcomeCard(context),
          const SizedBox(height: 16),
          _buildStatusCard(context, provider),
        ],
      ),
    );
  }

  Widget _buildSearchEntry(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => const SearchPage()),
      ),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: <Widget>[
          Icon(Icons.search, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '搜索内容',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
          ),
          Icon(Icons.tune, size: 18, color: Colors.grey[600]),
        ]),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(children: <Widget>[
              CircleAvatar(
                radius: 26,
                backgroundColor: primary.withOpacity(.12),
                child: Icon(Icons.auto_awesome, color: primary, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  '宏曦聚合',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(
              '统一管理扩展源，在搜索页面发现内容。',
              style: TextStyle(color: Colors.grey[700], height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('开始搜索'),
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(builder: (_) => const SearchPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SourceProvider provider) {
    final count = provider.enabledSources.length;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.extension_outlined),
        title: const Text('扩展源状态'),
        subtitle: Text(count == 0 ? '尚未添加扩展源，请到设置配置' : '已启用 $count 个扩展源'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}
