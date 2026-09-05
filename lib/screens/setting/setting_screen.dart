/// 设置页
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_source.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SourceProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: Text('视频源管理', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey))),
        Container(color: Colors.white, child: Column(children: [
          for (var source in provider.sources)
            ListTile(
              leading: Icon(source.key == provider.activeSource?.key
                  ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: source.key == provider.activeSource?.key ? Colors.blue : Colors.grey, size: 20),
              title: Text(source.name),
              subtitle: Text(source.api, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              onTap: () => provider.setActiveSource(source)),
        ])),
        const SizedBox(height: 20),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
            onPressed: () async {
              final ctrl = TextEditingController();
              await showDialog(context: context, builder: (ctx) => AlertDialog(
                title: const Text('添加源'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'API 地址')),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                  ElevatedButton(onPressed: () {
                    if (ctrl.text.isNotEmpty) {
                      provider.sources.add(VideoSource(
                        key: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                        name: '自定义源', api: ctrl.text));
                      provider.notifyListeners();
                    }
                    Navigator.pop(ctx);
                  }, child: const Text('添加')),
                ],
              ));
            },
            child: const Text('添加自定义源')),
        ),
      ]),
    );
  }
}
