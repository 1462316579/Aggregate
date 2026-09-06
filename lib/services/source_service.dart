import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';

class SourceService {
  const SourceService();

  Future<SearchResult> search(SourceDefinition source, String query) async {
    try {
      final uri = _buildUri(source.search ?? source.api, {
        'ac': 'detail',
        'wd': query,
        'pg': '1',
        'page': '1',
      });
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
      final raw = root is Map
          ? (root['list'] ?? root['data'] ?? root['results'] ?? root['items'])
          : root;
      if (raw is List) {
        return raw.whereType<Map>().map((e) => MediaItem.fromMap(
          Map<String, dynamic>.from(e), source.id, source.type,
        )).where((e) => e.title.isNotEmpty).toList();
      }
    } catch (_) {}
    return [];
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

  bool _ok(http.Response response) => response.statusCode >= 200 && response.statusCode < 300;
}
