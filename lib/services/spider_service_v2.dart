/// 聚合爬虫引擎 v2
/// 支持: 视频 / 漫画 / 小说 / 音乐 / 直播
/// 兼容: TVBox V3 / 漫画源 / 小说源 / 音乐API
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/unified_content.dart';
import '../models/video_source.dart';
import '../models/comic_detail.dart';
import '../models/novel_detail.dart';
import '../models/music_detail.dart';
import '../models/source_category.dart';

class SpiderServiceV2 {
  static const _defaultHeaders = {'User-Agent': 'AllPlay/2.0'};
  static const _timeout = Duration(seconds: 15);

  // ════════════════════════════════════════
  //  加载在线配置源列表
  // ════════════════════════════════════════

  static Future<List<VideoSource>> getSources(String configUrl) async {
    try {
      final body = await _httpGetRaw(configUrl);
      if (body == null) return [];

      final json = jsonDecode(body);
      List<VideoSource> sources = [];

      if (json is List) {
        return json.map((item) => VideoSource.fromJson(item)).toList();
      }

      if (json is Map<String, dynamic>) {
        // TVBox V3: sites
        if (json['sites'] != null) {
          for (var site in json['sites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? site['name'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                type: _parseSourceType(site['type']),
                ext: site['ext'], spider: site['spider'],
              ));
            }
          }
        }
        // TVBox V3: lives
        if (json['lives'] != null) {
          for (var live in json['lives']) {
            if (live is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: live['name'] ?? 'live',
                name: live['name'] ?? '直播源',
                api: live['url'] ?? '',
                type: 4, mediaType: 'live',
              ));
            }
          }
        }
        // 漫画源
        if (json['comicSites'] != null) {
          for (var site in json['comicSites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? site['name'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                mediaType: 'comic',
              ));
            }
          }
        }
        // 小说源
        if (json['novelSites'] != null) {
          for (var site in json['novelSites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? site['name'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                mediaType: 'novel',
              ));
            }
          }
        }
        // 音乐源
        if (json['musicSites'] != null) {
          for (var site in json['musicSites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? site['name'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                mediaType: 'music',
              ));
            }
          }
        }
      }

      return sources;
    } catch (e) {
      print('getSources error: $e');
      return [];
    }
  }

  static int _parseSourceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'xml': return 1;
      case 'json': return 2;
      case 'spider': return 3;
      default: return 2;
    }
  }

  static Future<String?> _httpGetRaw(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: _defaultHeaders)
          .timeout(_timeout);
      if (response.statusCode == 200) return response.body;
    } catch (_) {}
    return null;
  }

  // ════════════════════════════════════════
  //  统一聚合搜索 — 跨所有源 + 所有类型
  // ════════════════════════════════════════

  /// 并行搜索所有启用的源，返回按类型分组的结果
  static Future<AggregatedSearchResult> searchAll(
    List<VideoSource> sources,
    String query, {
    MediaType? filterType,
  }) async {
    final futures = <Future<_SearchTaskResult>>[];
    
    for (var source in sources.where((s) => s.isActive)) {
      futures.add(_searchSource(source, query, filterType));
    }

    final results = await Future.wait(futures, eagerError: false);
    
    final byType = <MediaType, List<UnifiedContent>>{};
    final bySource = <String, List<UnifiedContent>>{};
    int totalResults = 0;

    for (var result in results) {
      if (result.items.isEmpty) continue;
      totalResults += result.items.length;

      byType.putIfAbsent(result.mediaType, () => []).addAll(result.items);
      bySource.putIfAbsent(result.sourceKey, () => []).addAll(result.items);
    }

    return AggregatedSearchResult(
      query: query,
      totalResults: totalResults,
      byType: byType,
      bySource: bySource,
    );
  }

  static Future<_SearchTaskResult> _searchSource(
    VideoSource source, String query, MediaType? filterType,
  ) async {
    try {
      MediaType type;
      List<UnifiedContent> items;

      switch (source.mediaType) {
        case MediaType.comic:
          type = MediaType.comic;
          items = await searchComic(source, query);
          break;
        case MediaType.novel:
          type = MediaType.novel;
          items = await searchNovel(source, query);
          break;
        case MediaType.music:
          type = MediaType.music;
          items = await searchMusic(source, query);
          break;
        default:
          type = MediaType.video;
          items = await searchVideo(source, query);
      }

      if (filterType != null && type != filterType) {
        items = [];
      }

      return _SearchTaskResult(sourceKey: source.key, mediaType: type, items: items);
    } catch (e) {
      return _SearchTaskResult(sourceKey: source.key, mediaType: MediaType.video, items: []);
    }
  }

  // ════════════════════════════════════════
  //  视频源抓取
  // ════════════════════════════════════════

  static Future<List<UnifiedContent>> searchVideo(VideoSource source, String query) async {
    final url = _buildUrl(source.api, {'ac': 'detail', 'wd': query});
    final body = await _httpGet(url, source);
    if (body == null) return [];
    return _parseJsonList(body, source.key, UnifiedContent.fromVideo);
  }

  static Future<List<UnifiedContent>> getCategoryVideo(
    VideoSource source, {String? typeId, int page = 1}
  ) async {
    final params = <String, dynamic>{'ac': 'detail', 'pg': page.toString()};
    if (typeId != null && typeId.isNotEmpty) params['t'] = typeId;
    final url = _buildUrl(source.api, params);
    final body = await _httpGet(url, source);
    if (body == null) return [];
    return _parseJsonList(body, source.key, UnifiedContent.fromVideo);
  }

  static Future<List<VideoSourceCategory>> getVideoCategories(VideoSource source) async {
    final url = _buildUrl(source.api, {'ac': 'list'});
    final body = await _httpGet(url, source);
    if (body == null) return [];
    try {
      final json = jsonDecode(body);
      final classes = json['class'] ?? [];
      return (classes as List).map((c) => VideoSourceCategory(
        id: (c['type_id'] ?? '').toString(),
        name: c['type_name'] ?? '',
      )).toList();
    } catch (_) { return []; }
  }

  // ════════════════════════════════════════
  //  漫画源抓取 (兼容常见漫画CMS格式)
  // ════════════════════════════════════════

  static Future<List<UnifiedContent>> searchComic(VideoSource source, String query) async {
    // 漫画源常见格式: /search?keyword=xxx 或 /api/comic/search?q=xxx
    String url;
    if (source.api.contains('search')) {
      url = '${source.api}?keyword=${Uri.encodeComponent(query)}';
    } else {
      url = '${source.api}/search?keyword=${Uri.encodeComponent(query)}';
    }

    final body = await _httpGet(url, source);
    if (body == null) return [];

    try {
      final json = jsonDecode(body);
      final list = json['list'] ?? json['data'] ?? json['comics'] ?? json['result'] ?? [];
      if (list is List) {
        return list.map((item) => UnifiedContent.fromComic(item, source.key)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<ComicDetail?> getComicDetail(VideoSource source, String comicId) async {
    String url;
    if (source.api.contains('/comic/')) {
      url = '${source.api}/$comicId';
    } else {
      url = '${source.api}?comicId=$comicId';
    }

    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      final data = json['data'] ?? json['detail'] ?? json;
      return ComicDetail.fromJson(data, sourceKey: source.key);
    } catch (_) { return null; }
  }

  /// 获取漫画图片列表
  static Future<List<ComicPage>> getComicPages(
    VideoSource source, String chapterUrl,
  ) async {
    final body = await _httpGet(chapterUrl, source);
    if (body == null) return [];

    try {
      final json = jsonDecode(body);
      final images = json['images'] ?? json['pages'] ?? json['pageList'] ?? [];
      if (images is List) {
        return images.asMap().entries.map((e) {
          final img = e.value;
          final url = img is String ? img : (img['url'] ?? img['imgUrl'] ?? '').toString();
          return ComicPage(index: e.key, imageUrl: url);
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  // ════════════════════════════════════════
  //  小说源抓取 (兼容常见小说CMS格式)
  // ════════════════════════════════════════

  static Future<List<UnifiedContent>> searchNovel(VideoSource source, String query) async {
    String url;
    if (source.api.contains('search')) {
      url = '${source.api}?keyword=${Uri.encodeComponent(query)}';
    } else {
      url = '${source.api}/search?keyword=${Uri.encodeComponent(query)}';
    }

    final body = await _httpGet(url, source);
    if (body == null) return [];

    try {
      final json = jsonDecode(body);
      final list = json['list'] ?? json['data'] ?? json['novels'] ?? json['books'] ?? [];
      if (list is List) {
        return list.map((item) => UnifiedContent.fromNovel(item, source.key)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<NovelDetail?> getNovelDetail(VideoSource source, String novelId) async {
    String url;
    if (source.api.contains('/novel/') || source.api.contains('/book/')) {
      url = '${source.api}/$novelId';
    } else {
      url = '${source.api}?novelId=$novelId';
    }

    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      final data = json['data'] ?? json['detail'] ?? json;
      return NovelDetail.fromJson(data, sourceKey: source.key);
    } catch (_) { return null; }
  }

  /// 获取小说章节内容
  static Future<String?> getNovelChapterContent(
    VideoSource source, String chapterUrl,
  ) async {
    final body = await _httpGet(chapterUrl, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      // 多种格式兼容
      String content = json['content'] ?? json['data'] ?? json['text'] ?? '';
      // 清理 HTML 标签
      content = content.replaceAll(RegExp(r'<[^>]*>'), '\n');
      content = content.replaceAll(RegExp(r'\n{3,}'), '\n\n');
      return content.trim();
    } catch (_) {
      // 如果不是 JSON，直接返回 HTML/纯文本
      return body.replaceAll(RegExp(r'<[^>]*>'), '\n').trim();
    }
  }

  // ════════════════════════════════════════
  //  音乐源抓取 (兼容常见音乐API格式)
  // ════════════════════════════════════════

  static Future<List<UnifiedContent>> searchMusic(VideoSource source, String query) async {
    String url;
    if (source.api.contains('search')) {
      url = '${source.api}?keyword=${Uri.encodeComponent(query)}';
    } else {
      url = '${source.api}/search?keyword=${Uri.encodeComponent(query)}';
    }

    final body = await _httpGet(url, source);
    if (body == null) return [];

    try {
      final json = jsonDecode(body);
      final list = json['list'] ?? json['data'] ?? json['songs'] ?? json['result'] ?? [];
      if (list is List) {
        return list.map((item) => UnifiedContent.fromMusic(item, source.key)).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取音乐播放地址
  static Future<String?> getMusicPlayUrl(VideoSource source, String songId) async {
    String url;
    if (source.api.contains('url') || source.api.contains('play')) {
      url = '${source.api}?id=$songId';
    } else {
      url = '${source.api}/url?id=$songId';
    }

    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      return json['url']?.toString() ?? json['data']?.toString() ?? json['playUrl']?.toString();
    } catch (_) { return null; }
  }

  /// 获取歌词
  static Future<String?> getMusicLyric(VideoSource source, String songId) async {
    String url;
    if (source.api.contains('lyric')) {
      url = '${source.api}?id=$songId';
    } else {
      url = '${source.api}/lyric?id=$songId';
    }

    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      return json['lyric']?.toString() ?? json['lrc']?.toString() ?? json['data']?.toString();
    } catch (_) { return body; }
  }

  /// 获取歌单详情
  static Future<MusicDetail?> getMusicPlaylist(VideoSource source, String playlistId) async {
    String url = '${source.api}/playlist?id=$playlistId';
    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      final data = json['data'] ?? json['detail'] ?? json;
      return MusicDetail.fromJson(data, sourceKey: source.key);
    } catch (_) { return null; }
  }

  // ════════════════════════════════════════
  //  视频详情 + 播放解析 (复用 v1)
  // ════════════════════════════════════════

  static Future<Map<String, dynamic>?> getVideoDetail(VideoSource source, String videoId) async {
    final url = _buildUrl(source.api, {'ac': 'detail', 'ids': videoId});
    final body = await _httpGet(url, source);
    if (body == null) return null;

    try {
      final json = jsonDecode(body);
      final list = json['list'];
      if (list is List && list.isNotEmpty) return list[0];
    } catch (_) {}
    return null;
  }

  static Future<String?> parseVideoPlayUrl(VideoSource source, String url) async {
    if (source.playerApi != null && source.playerApi!.isNotEmpty) {
      try {
        final parseUrl = '${source.playerApi}?url=${Uri.encodeComponent(url)}';
        final body = await _httpGet(parseUrl, source);
        if (body != null) {
          final json = jsonDecode(body);
          if (json['url'] != null) return json['url'].toString();
          if (json['data'] != null) return json['data'].toString();
        }
      } catch (_) {}
    }
    if (url.endsWith('.m3u8') || url.endsWith('.mp4') || url.contains('.m3u8?') || url.contains('.mp4?')) {
      return url;
    }
    return url;
  }

  // ════════════════════════════════════════
  //  直播源
  // ════════════════════════════════════════

  static Future<List<Map<String, String>>> getLiveChannels(String url) async {
    final body = await _httpGet(url, null);
    if (body == null) return [];

    if (body.contains('#EXTINF') || url.endsWith('.m3u')) {
      return _parseM3u(body);
    }
    return _parseTxt(body);
  }

  // ════════════════════════════════════════
  //  工具方法
  // ════════════════════════════════════════

  static Future<String?> _httpGet(String url, VideoSource? source) async {
    try {
      final headers = Map<String, String>.from(_defaultHeaders);
      if (source?.headers != null) {
        for (var h in source!.headers) {
          final parts = h.split(':');
          if (parts.length >= 2) {
            headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
          }
        }
      }
      final response = await http.get(Uri.parse(url), headers: headers).timeout(_timeout);
      if (response.statusCode == 200) return response.body;
    } catch (_) {}
    return null;
  }

  static String _buildUrl(String base, Map<String, dynamic> params) {
    final uri = Uri.parse(base);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    params.forEach((k, v) => queryParams[k] = v.toString());
    return uri.replace(queryParameters: queryParams).toString();
  }

  static List<UnifiedContent> _parseJsonList(
    String body, String sourceKey,
    UnifiedContent Function(Map<String, dynamic>, String) factory,
  ) {
    try {
      final json = jsonDecode(body);
      final list = json['list'] ?? json['data'] ?? json['results'] ?? [];
      if (list is List) {
        return list.map((item) => factory(item, sourceKey)).toList();
      }
    } catch (_) {}
    return [];
  }

  static List<Map<String, String>> _parseM3u(String content) {
    List<Map<String, String>> channels = [];
    final lines = content.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().startsWith('#EXTINF:')) {
        final nameMatch = lines[i].trim().split(',').last.trim();
        if (i + 1 < lines.length && !lines[i + 1].trim().startsWith('#')) {
          channels.add({'name': nameMatch, 'url': lines[i + 1].trim()});
        }
      }
    }
    return channels;
  }

  static List<Map<String, String>> _parseTxt(String content) {
    List<Map<String, String>> channels = [];
    for (var line in content.split('\n')) {
      line = line.trim();
      if (line.contains(',') && !line.startsWith('#')) {
        final parts = line.split(',');
        if (parts.length >= 2 && parts[1].trim().startsWith('http')) {
          channels.add({'name': parts[0].trim(), 'url': parts[1].trim()});
        }
      } else if (line.startsWith('http')) {
        channels.add({'name': '频道${channels.length + 1}', 'url': line});
      }
    }
    return channels;
  }
}

/// 聚合搜索结果
class AggregatedSearchResult {
  final String query;
  final int totalResults;
  final Map<MediaType, List<UnifiedContent>> byType;
  final Map<String, List<UnifiedContent>> bySource;

  AggregatedSearchResult({
    required this.query,
    required this.totalResults,
    required this.byType,
    required this.bySource,
  });

  List<UnifiedContent> ofType(MediaType type) => byType[type] ?? [];
}

/// 内部搜索任务结果
class _SearchTaskResult {
  final String sourceKey;
  final MediaType mediaType;
  final List<UnifiedContent> items;

  _SearchTaskResult({
    required this.sourceKey,
    required this.mediaType,
    required this.items,
  });
}

/// 视频分类 (兼容旧版)
class VideoSourceCategory {
  final String id;
  final String name;
  VideoSourceCategory({required this.id, required this.name});
}
