/// 视频源管理与数据抓取服务
/// 支持 TVBox V3 格式、XML、JSON 三种源类型
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/video_source.dart';
import '../models/video_content.dart';
import '../models/live_channel.dart';

class SpiderService {
  /// 获取源列表 (TVBox V3 格式)
  static Future<List<VideoSource>> loadSources(String configUrl) async {
    try {
      final response = await http.get(
        Uri.parse(configUrl),
        headers: {'User-Agent': 'AllPlay/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final json = jsonDecode(response.body);
      
      if (json is List) {
        return json.map((item) => VideoSource.fromJson(item)).toList();
      }
      
      if (json is Map<String, dynamic>) {
        // TVBox V3 格式
        List<VideoSource> sources = [];
        
        // 解析 sites
        if (json['sites'] != null) {
          for (var site in json['sites']) {
            if (site is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: site['key'] ?? '',
                name: site['name'] ?? '',
                api: site['api'] ?? '',
                type: _parseSourceType(site['type']),
                ext: site['ext'],
                spider: site['spider'],
              ));
            }
          }
        }
        
        // 解析 lives
        if (json['lives'] != null) {
          for (var live in json['lives']) {
            if (live is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: live['name'] ?? 'live',
                name: live['name'] ?? '直播源',
                api: live['url'] ?? '',
                type: 4, // 直播类型
              ));
            }
          }
        }
        
        // 解析 topos
        if (json['topos'] != null) {
          for (var topo in json['topos']) {
            if (topo is Map<String, dynamic>) {
              sources.add(VideoSource(
                key: topo['name'] ?? 'topo',
                name: topo['name'] ?? 'Topo源',
                api: topo['url'] ?? '',
                type: 5,
              ));
            }
          }
        }
        
        return sources;
      }
      
      return [];
    } catch (e) {
      print('loadSources error: $e');
      return [];
    }
  }

  static int _parseSourceType(String? type) {
    switch (type?.toLowerCase()) {
      case 'xml': return 1;
      case 'json': return 2;
      case 'spider': return 3;
      default: return 1;
    }
  }

  /// 搜索视频
  static Future<List<VideoContent>> search(
    VideoSource source,
    String query,
  ) async {
    try {
      final searchUrl = _buildSearchUrl(source, query);
      if (searchUrl == null) return [];

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: _buildHeaders(source),
      ).timeout(const Duration(seconds: 15));

      return _parseSearchResult(response.body, source);
    } catch (e) {
      print('search error: $e');
      return [];
    }
  }

  /// 获取分类列表
  static Future<List<VideoContent>> getCategory(
    VideoSource source,
    String? typeId,
    {int page = 1}
  ) async {
    try {
      final url = _buildCategoryUrl(source, typeId, page);
      if (url == null) return [];

      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(source),
      ).timeout(const Duration(seconds: 15));

      return _parseCategoryResult(response.body, source);
    } catch (e) {
      print('getCategory error: $e');
      return [];
    }
  }

  /// 获取视频详情
  static Future<VideoContent?> getDetail(
    VideoSource source,
    String videoId,
  ) async {
    try {
      final url = _buildDetailUrl(source, videoId);
      if (url == null) return null;

      final response = await http.get(
        Uri.parse(url),
        headers: _buildHeaders(source),
      ).timeout(const Duration(seconds: 15));

      return _parseDetailResult(response.body, source);
    } catch (e) {
      print('getDetail error: $e');
      return null;
    }
  }

  /// 解析播放地址 (获取真实 m3u8/mp4 链接)
  static Future<String?> parsePlayUrl(
    VideoSource source,
    String url,
  ) async {
    try {
      if (source.playerApi != null && source.playerApi!.isNotEmpty) {
        final parseUrl = '${source.playerApi}?url=${Uri.encodeComponent(url)}';
        final response = await http.get(
          Uri.parse(parseUrl),
          headers: _buildHeaders(source),
        ).timeout(const Duration(seconds: 15));
        
        final json = jsonDecode(response.body);
        if (json['url'] != null) return json['url'].toString();
        if (json['data'] != null) return json['data'].toString();
      }
      
      // 如果 URL 本身就是直接链接
      if (url.endsWith('.m3u8') || url.endsWith('.mp4') ||
          url.contains('.m3u8?') || url.contains('.mp4?')) {
        return url;
      }
      
      return url;
    } catch (e) {
      print('parsePlayUrl error: $e');
      return url;
    }
  }

  /// 获取直播列表
  static Future<List<LiveChannel>> getLiveChannels(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'AllPlay/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (url.endsWith('.m3u') || url.endsWith('.m3u8') ||
          response.body.contains('#EXTINF')) {
        return LiveChannel.parseM3u(response.body);
      }
      
      return LiveChannel.parseTxt(response.body);
    } catch (e) {
      print('getLiveChannels error: $e');
      return [];
    }
  }

  // ============ URL 构建 ============

  static String? _buildSearchUrl(VideoSource source, String query) {
    final api = source.api;
    if (api.isEmpty) return null;
    
    // TVBox V3 搜索格式
    if (api.contains('acList')) {
      return '$api?ac=detail&wd=${Uri.encodeComponent(query)}';
    }
    
    // 普通 CMS 搜索
    if (api.contains('api.php')) {
      return '$api?ac=detail&wd=${Uri.encodeComponent(query)}';
    }
    
    // 尝试通用搜索路径
    return '$api?wd=${Uri.encodeComponent(query)}';
  }

  static String? _buildCategoryUrl(VideoSource source, String? typeId, int page) {
    final api = source.api;
    if (api.isEmpty) return null;
    
    String url = '$api?ac=detail&pg=$page';
    if (typeId != null && typeId.isNotEmpty) {
      url += '&t=$typeId';
    }
    return url;
  }

  static String? _buildDetailUrl(VideoSource source, String videoId) {
    final api = source.api;
    if (api.isEmpty) return null;
    return '$api?ac=detail&ids=$videoId';
  }

  static Map<String, String> _buildHeaders(VideoSource source) {
    return {
      'User-Agent': 'AllPlay/1.0',
      ...Map.fromEntries(
        source.headers.map((h) {
          final parts = h.split(':');
          if (parts.length >= 2) {
            return MapEntry(parts[0].trim(), parts.sublist(1).join(':').trim());
          }
          return MapEntry('Authorization', h);
        }),
      ),
    };
  }

  // ============ 结果解析 ============

  static List<VideoContent> _parseSearchResult(String body, VideoSource source) {
    try {
      final json = jsonDecode(body);
      
      if (json is Map<String, dynamic>) {
        final list = json['list'] ?? json['data'] ?? json['results'];
        if (list is List) {
          return list
              .map((item) => VideoContent.fromJson(item, sourceKey: source.key))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      // 尝试 XML 解析
      return _parseXmlList(body, source);
    }
  }

  static List<VideoContent> _parseCategoryResult(String body, VideoSource source) {
    try {
      final json = jsonDecode(body);
      
      if (json is Map<String, dynamic>) {
        final list = json['list'] ?? json['data'];
        if (list is List) {
          return list
              .map((item) => VideoContent.fromJson(item, sourceKey: source.key))
              .toList();
        }
      }
      
      return [];
    } catch (e) {
      return _parseXmlList(body, source);
    }
  }

  static VideoContent? _parseDetailResult(String body, VideoSource source) {
    try {
      final json = jsonDecode(body);
      
      if (json is Map<String, dynamic>) {
        final list = json['list'];
        if (list is List && list.isNotEmpty) {
          return VideoContent.fromJson(list[0], sourceKey: source.key);
        }
      }
      
      return null;
    } catch (e) {
      return _parseXmlDetail(body, source);
    }
  }

  /// XML 格式解析 (简易)
  static List<VideoContent> _parseXmlList(String xml, VideoSource source) {
    List<VideoContent> results = [];
    
    final videoRegex = RegExp(r'<video[^>]*>(.*?)</video>', dotAll: true);
    final matches = videoRegex.allMatches(xml);
    
    for (var match in matches) {
      final videoXml = match.group(1) ?? '';
      final id = _extractXmlTag(videoXml, 'vod_id');
      final name = _extractXmlTag(videoXml, 'vod_name');
      final pic = _extractXmlTag(videoXml, 'vod_pic');
      
      if (name.isNotEmpty) {
        results.add(VideoContent(
          id: id,
          name: name,
          pic: pic,
          desc: _extractXmlTag(videoXml, 'vod_content'),
          category: _extractXmlTag(videoXml, 'type_name'),
          year: _extractXmlTag(videoXml, 'vod_year'),
          area: _extractXmlTag(videoXml, 'vod_area'),
          sourceKey: source.key,
        ));
      }
    }
    
    return results;
  }

  static VideoContent? _parseXmlDetail(String xml, VideoSource source) {
    final videoRegex = RegExp(r'<video[^>]*>(.*?)</video>', dotAll: true);
    final match = videoRegex.firstMatch(xml);
    
    if (match != null) {
      final videoXml = match.group(1) ?? '';
      return VideoContent(
        id: _extractXmlTag(videoXml, 'vod_id'),
        name: _extractXmlTag(videoXml, 'vod_name'),
        pic: _extractXmlTag(videoXml, 'vod_pic'),
        desc: _extractXmlTag(videoXml, 'vod_content'),
        category: _extractXmlTag(videoXml, 'type_name'),
        year: _extractXmlTag(videoXml, 'vod_year'),
        sourceKey: source.key,
      );
    }
    
    return null;
  }

  static String _extractXmlTag(String xml, String tag) {
    final regex = RegExp(r'<$tag[^>]*>(.*?)</$tag>', dotAll: true);
    final match = regex.firstMatch(xml);
    return match?.group(1)?.trim() ?? '';
  }
}
