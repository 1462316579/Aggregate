/// 源配置导入/导出服务
/// 支持: JSON文件导入导出 / 剪贴板 / 分享
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/video_source.dart';

class SourceImportExport {
  /// 导出源配置为 JSON 字符串
  static String exportToJson(List<VideoSource> sources) {
    final config = {
      'name': 'AllPlay 自定义配置',
      'version': '1.0.0',
      'sources': sources.map((s) => s.toJson()).toList(),
      'exportTime': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(config);
  }

  /// 导出到文件并返回路径
  static Future<String> exportToFile(List<VideoSource> sources, {String? filename}) async {
    final json = exportToJson(sources);
    final dir = await getApplicationDocumentsDirectory();
    final name = filename ?? 'allplay_sources_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);
    return file.path;
  }

  /// 导出到共享存储
  static Future<String> exportToShared(List<VideoSource> sources) async {
    final json = exportToJson(sources);
    final dir = Directory('/var/minis/workspace/AllPlay/config');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final file = File('${dir.path}/sources_export.json');
    await file.writeAsString(json);
    return file.path;
  }

  /// 从 JSON 字符串导入
  static ImportResult importFromJson(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr);
      List<VideoSource> sources = [];

      // 兼容多种格式
      if (json is List) {
        // 直接是源数组
        sources = json.map((item) => VideoSource.fromJson(item)).toList();
      } else if (json is Map<String, dynamic>) {
        // TVBox V3 格式
        if (json['sites'] != null) {
          for (var site in json['sites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? site['name'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                type: site['type'] ?? 2,
              ));
            }
          }
        }
        // 自定义配置格式
        if (json['sources'] != null) {
          for (var s in json['sources']) {
            if (s is Map<String, dynamic>) {
              sources.add(VideoSource.fromJson(s));
            }
          }
        }
        // 漫画源
        if (json['comicSites'] != null) {
          for (var s in json['comicSites']) {
            if (s is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: s['key'] ?? s['name'] ?? '',
                name: s['name'] ?? '', api: s['api'] ?? '',
                mediaType: 'comic',
              ));
            }
          }
        }
        // 小说源
        if (json['novelSites'] != null) {
          for (var s in json['novelSites']) {
            if (s is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: s['key'] ?? s['name'] ?? '',
                name: s['name'] ?? '', api: s['api'] ?? '',
                mediaType: 'novel',
              ));
            }
          }
        }
        // 音乐源
        if (json['musicSites'] != null) {
          for (var s in json['musicSites']) {
            if (s is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: s['key'] ?? s['name'] ?? '',
                name: s['name'] ?? '', api: s['api'] ?? '',
                mediaType: 'music',
              ));
            }
          }
        }
      }

      if (sources.isEmpty) {
        return ImportResult(false, '未找到有效源', 0);
      }

      return ImportResult(true, '导入成功', sources.length, sources: sources);
    } catch (e) {
      return ImportResult(false, '解析失败: $e', 0);
    }
  }

  /// 从文件导入
  static Future<ImportResult> importFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ImportResult(false, '文件不存在', 0);
      }
      final jsonStr = await file.readAsString();
      return importFromJson(jsonStr);
    } catch (e) {
      return ImportResult(false, '读取文件失败: $e', 0);
    }
  }

  /// 从剪贴板导入
  static Future<ImportResult> importFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.isEmpty) {
        return ImportResult(false, '剪贴板为空', 0);
      }
      return importFromJson(data.text!);
    } catch (e) {
      return ImportResult(false, '剪贴板读取失败: $e', 0);
    }
  }

  /// 复制到剪贴板
  static Future<void> copyToClipboard(List<VideoSource> sources) async {
    final json = exportToJson(sources);
    await Clipboard.setData(ClipboardData(text: json));
  }

  /// 导入对话框
  static Future<void> showImportDialog(BuildContext context, Function(List<VideoSource>) onImport) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('导入源配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _importOption(ctx, Icons.content_paste, '从剪贴板粘贴', () async {
              final result = await importFromClipboard();
              Navigator.pop(ctx);
              _showResult(context, result, onImport);
            }),
            const SizedBox(height: 8),
            _importOption(ctx, Icons.file_open, '打开本地文件', () async {
              Navigator.pop(ctx);
              // TODO: file_picker
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('文件选择器开发中')));
            }),
            const SizedBox(height: 8),
            _importOption(ctx, Icons.link, '从 URL 导入', () {
              Navigator.pop(ctx);
              _showUrlImportDialog(context, onImport);
            }),
            const SizedBox(height: 8),
            _importOption(ctx, Icons.code, '直接粘贴 JSON', () {
              Navigator.pop(ctx);
              _showJsonInputDialog(context, onImport);
            }),
          ],
        ),
      ),
    );
  }

  static Widget _importOption(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2196F3), size: 22),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  static void _showResult(BuildContext context, ImportResult result, Function(List<VideoSource>) onImport) {
    if (result.success && result.sources != null) {
      onImport(result.sources!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 ${result.count} 个源')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)));
    }
  }

  static void _showUrlImportDialog(BuildContext context, Function(List<VideoSource>) onImport) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('从 URL 导入'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(
          hintText: 'https://raw.githubusercontent.com/xxx/config.json',
          labelText: '配置 URL'),
        maxLines: 2,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
          onPressed: () async {
            Navigator.pop(ctx);
            // TODO: HTTP 下载并导入
          },
          child: const Text('导入'),
        ),
      ],
    ));
  }

  static void _showJsonInputDialog(BuildContext context, Function(List<VideoSource>) onImport) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('粘贴 JSON 配置'),
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: '粘贴 JSON 格式的源配置'),
        maxLines: 8,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2196F3), foregroundColor: Colors.white),
          onPressed: () {
            Navigator.pop(ctx);
            final result = importFromJson(ctrl.text);
            _showResult(context, result, onImport);
          },
          child: const Text('导入'),
        ),
      ],
    ));
  }
}

class ImportResult {
  final bool success;
  final String message;
  final int count;
  final List<VideoSource>? sources;

  ImportResult(this.success, this.message, this.count, {this.sources});
}
