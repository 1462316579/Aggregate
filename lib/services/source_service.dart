import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

class SourceService {
  const SourceService();

  Future<SearchResult> search(SourceDefinition source, String query) async {
    try {
      final params = source.type == ContentType.music
          ? <String, String>{'type': 'search', 'keywords': query, 'key': query, 'page': '1'}
          : <String, String>{'ac': 'detail', 'wd': query, 'pg': '1', 'page': '1'};
      final uri = _buildUri(source.search ?? source.api, params);
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return SearchResult(query: query, items: [], errors: {source.id: 'HTTP ${response.statusCode}'});
      return SearchResult(query: query, items: _parseItems(response.body, source), errors: const {});
    } catch (error) {
      return SearchResult(query: query, items: [], errors: {source.id: '$error'});
    }
  }

  Future<MediaItem?> detail(SourceDefinition source, String id) async {
    try {
      final uri = _buildUri(source.detail ?? source.api, {
        'ac': 'detail',
        'ids': id,
        'id': id,
      });
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return null;
      final items = _parseItems(response.body, source);
      return items.isEmpty ? null : items.first;
    } catch (_) {
      return null;
    }
  }

  Future<List<MediaItem>> category(SourceDefinition source, {String? categoryId, int page = 1}) async {
    try {
      final uri = _buildUri(source.api, {
        'ac': 'detail',
        'pg': '$page',
        if (categoryId != null && categoryId.isNotEmpty) 't': categoryId,
      });
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return [];
      return _parseItems(response.body, source);
    } catch (_) {
      return [];
    }
  }

  Future<List<SourceCategory>> categories(SourceDefinition source) async {
    try {
      final uri = _buildUri(source.api, {'ac': 'list'});
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return [];
      return _parseCategories(response.body);
    } catch (_) {
      return [];
    }
  }

  Future<String> chapterContent(SourceDefinition source, String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return '';
      try {
        final data = jsonDecode(response.body);
        final value = data is Map ? (data['content'] ?? data['text'] ?? data['data'] ?? '') : data;
        return '$value'.replaceAll(RegExp(r'<[^>]+>'), '\\n').trim();
      } catch (_) {
        return response.body.replaceAll(RegExp(r'<[^>]+>'), '\\n').trim();
      }
    } catch (_) {
      return '';
    }
  }

  Future<List<String>> chapterImages(SourceDefinition source, String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return [];
      final data = jsonDecode(response.body);
      final raw = data is Map ? (data['images'] ?? data['pages'] ?? data['list'] ?? []) : data;
      if (raw is List) return raw.map((item) => item is String ? item : '${item['url'] ?? item['src'] ?? ''}').where((item) => item.isNotEmpty).toList();
    } catch (_) {}
    return [];
  }

  /// Resolve a music URL. Supports direct URLs and common API response keys.
  Future<String?> resolveMusicUrl(SourceDefinition? source, MediaItem item) async {
    if (item.playUrl != null && item.playUrl!.isNotEmpty && _looksLikeUrl(item.playUrl!)) {
      return item.playUrl;
    }
    if (source == null || source.api.isEmpty) return item.playUrl;
    try {
      final uri = _buildUri(source.api, {
        'type': 'url',
        'id': item.id,
        'song_id': item.id,
      });
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return item.playUrl;
      final root = jsonDecode(response.body);
      return _findString(root, const ['url', 'playUrl', 'play_url', 'audio', 'audio_url', 'data']) ?? item.playUrl;
    } catch (_) {
      return item.playUrl;
    }
  }

  Future<String?> playUrl(SourceDefinition source, String url) async {
    if (source.ext == null || source.ext!.isEmpty) return url;
    try {
      final uri = _buildUri(source.ext!, {'url': url});
      final response = await http.get(uri, headers: source.headers).timeout(const Duration(seconds: 15));
      if (_ok(response)) {
        final data = jsonDecode(response.body);
        if (data is Map) return (data['url'] ?? data['data'] ?? url).toString();
      }
    } catch (_) {}
    return url;
  }

  Future<List<SourceDefinition>> loadRepository(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (!_ok(response)) return [];
      final root = jsonDecode(response.body);
      if (root is List) {
        return root.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e))).toList();
      }
      if (root is Map) return _parseRepository(Map<String, dynamic>.from(root));
    } catch (_) {}
    return [];
  }

  List<SourceDefinition> _parseRepository(Map<String, dynamic> root) {
    final result = <SourceDefinition>[];
    _addSourceGroup(root['sites'], result, ContentType.video);
    _addSourceGroup(root['videoSites'], result, ContentType.video);
    _addSourceGroup(root['comicSites'], result, ContentType.comic);
    _addSourceGroup(root['novelSites'], result, ContentType.novel);
    _addSourceGroup(root['musicSites'], result, ContentType.music);
    return result;
  }

  void _addSourceGroup(dynamic value, List<SourceDefinition> output, ContentType type) {
    if (value is! List) return;
    for (final entry in value.whereType<Map>()) {
      output.add(SourceDefinition.fromMap(Map<String, dynamic>.from(entry), forcedType: type));
    }
  }

  List<MediaItem> _parseItems(String body, SourceDefinition source) {
    try {
      final root = jsonDecode(body);
      final raw = _extractItems(root, source.type);
      if (raw is List) {
        return raw.whereType<Map>().map((e) => MediaItem.fromMap(
          Map<String, dynamic>.from(e), source.id, source.type,
        )).where((e) => e.title.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  dynamic _extractItems(dynamic root, ContentType type) {
    if (root is List) return root;
    if (root is! Map) return const <dynamic>[];
    final keys = type == ContentType.music
        ? const ['songs', 'song', 'tracks', 'result', 'data', 'list', 'items']
        : const ['list', 'data', 'results', 'items'];
    for (final key in keys) {
      final value = root[key];
      if (value is List) return value;
      if (value is Map) {
        final nested = _extractItems(value, type);
        if (nested is List && nested.isNotEmpty) return nested;
      }
    }
    return const <dynamic>[];
  }

  List<SourceCategory> _parseCategories(String body) {
    try {
      final root = jsonDecode(body);
      final raw = root is Map ? (root['class'] ?? root['categories'] ?? root['types']) : root;
      if (raw is List) {
        return raw.whereType<Map>().map((e) => SourceCategory(
          id: '${e['type_id'] ?? e['id'] ?? e['tid'] ?? ''}',
          name: '${e['type_name'] ?? e['name'] ?? ''}',
        )).where((e) => e.name.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
  }

  Uri _buildUri(String base, Map<String, String> params) {
    final uri = Uri.parse(base);
    final merged = Map<String, String>.from(uri.queryParameters)..addAll(params);
    return uri.replace(queryParameters: merged);
  }

  String? _findString(dynamic value, List<String> keys) {
    if (value is String && _looksLikeUrl(value)) return value;
    if (value is Map) {
      for (final key in keys) {
        final candidate = value[key];
        if (candidate is String && _looksLikeUrl(candidate)) return candidate;
      }
      for (final child in value.values) {
        final found = _findString(child, keys);
        if (found != null) return found;
      }
    }
    if (value is List) {
      for (final child in value) {
        final found = _findString(child, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  bool _looksLikeUrl(String value) {
    return value.startsWith('http://') || value.startsWith('https://');
  }

  bool _ok(http.Response response) => response.statusCode >= 200 && response.statusCode < 300;
}
