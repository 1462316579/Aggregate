/// 视频源抓取服务
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_source.dart';
import '../models/video_content.dart';

class SpiderService {
  static Future<List<VideoContent>> search(VideoSource source, String query) async {
    try {
      final url = '${source.api}?ac=detail&wd=${Uri.encodeComponent(query)}';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body);
      final list = json['list'] ?? [];
      return (list as List).map((e) => VideoContent.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  static Future<List<VideoContent>> getCategory(VideoSource source, {String? typeId, int page = 1}) async {
    try {
      String url = '${source.api}?ac=detail&pg=$page';
      if (typeId != null && typeId.isNotEmpty) url += '&t=$typeId';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body);
      final list = json['list'] ?? [];
      return (list as List).map((e) => VideoContent.fromJson(e)).toList();
    } catch (_) { return []; }
  }

  static Future<VideoContent?> getDetail(VideoSource source, String id) async {
    try {
      final url = '${source.api}?ac=detail&ids=$id';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body);
      final list = json['list'];
      if (list is List && list.isNotEmpty) return VideoContent.fromJson(list[0]);
    } catch (_) {}
    return null;
  }

  static Future<String?> parsePlayUrl(VideoSource source, String url) async {
    if (source.playerApi != null && source.playerApi!.isNotEmpty) {
      try {
        final res = await http.get(
          Uri.parse('${source.playerApi}?url=${Uri.encodeComponent(url)}'),
        ).timeout(const Duration(seconds: 10));
        final json = jsonDecode(res.body);
        return json['url']?.toString();
      } catch (_) {}
    }
    return url;
  }
}
