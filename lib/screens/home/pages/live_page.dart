/// 亦搜风格直播页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/source_provider.dart';

class LivePage extends StatefulWidget {
  const LivePage({super.key});
  @override
  State<LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<LivePage> {
  final _urlController = TextEditingController();
  List<Map<String, String>> _channels = [];
  bool _isLoading = false;
  String? _currentUrl;

  @override
  void dispose() { _urlController.dispose(); super.dispose(); }

  Future<void> _loadChannels() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    setState(() { _isLoading = true; _currentUrl = url; });
    try {
      final provider = context.read<SourceProvider>();
      final channels = await provider.getLiveChannels(url);
      setState(() { _channels = channels; _isLoading = false; });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 输入栏
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    hintText: '输入直播源地址 (m3u/txt)',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                    suffixIcon: _urlController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.clear, size: 18),
                            onPressed: () { _urlController.clear(); setState(() {}); })
                        : null,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onSubmitted: (_) => _loadChannels(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle),
                child: IconButton(
                  icon: _isLoading
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh, color: Colors.white, size: 20),
                  onPressed: _isLoading ? null : _loadChannels,
                ),
              ),
            ],
          ),
        ),
        // 频道列表
        Expanded(
          child: _channels.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.live_tv, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('输入直播源地址开始观看',
                        style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                  ]),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _channels.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final ch = _channels[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                        child: Text('${i + 1}', style: const TextStyle(
                            color: Color(0xFF2196F3), fontSize: 13)),
                      ),
                      title: Text(ch['name'] ?? '', maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14)),
                      subtitle: Text(ch['url'] ?? '', maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                      trailing: const Icon(Icons.play_circle_outline,
                          color: Color(0xFF2196F3), size: 26),
                      onTap: () {
                        // TODO: 打开直播播放器
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('播放: ${ch["name"]}')));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}
