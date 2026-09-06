import 'package:flutter/material.dart';
import 'search_page.dart';

/// Android home keeps the Miru-style discovery surface intentionally minimal:
/// one search entry at the top, with content discovery handled by SearchPage.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push<void>(
              context,
              MaterialPageRoute<void>(builder: (_) => const SearchPage()),
            ),
            child: Ink(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.search, color: Colors.grey[600]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '搜索视频、漫画、小说、音乐',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 15, color: Colors.grey[500]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
