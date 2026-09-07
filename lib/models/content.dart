import 'dart:convert';

enum ContentType { video, comic, novel, music }

class MediaItem {
  final String id;
  final String title;
  final String cover;
  final String description;
  final String sourceId;
  final ContentType type;
  final String? remark;
  final String? author;
  final String? year;
  final String? category;
  final String? album;
  final String? playUrl;
  final String? lyrics;
  final List<MediaEpisode> episodes;

  const MediaItem({
    required this.id,
    required this.title,
    this.cover = '',
    this.description = '',
    required this.sourceId,
    required this.type,
    this.remark,
    this.author,
    this.year,
    this.category,
    this.album,
    this.playUrl,
    this.lyrics,
    this.episodes = const [],
  });

  factory MediaItem.fromMap(Map<String, dynamic> json, String sourceId, ContentType type) {
    final rawEpisodes = json['episodes'] ?? json['chapters'] ?? json['chapterList'] ?? json['vod_play_url'];
    return MediaItem(
      id: (json['id'] ?? json['vod_id'] ?? json['book_id'] ?? json['song_id'] ?? '').toString(),
      title: (json['title'] ?? json['name'] ?? json['vod_name'] ?? json['book_name'] ?? json['song_name'] ?? json['songName'] ?? '').toString(),
      cover: (json['cover'] ?? json['pic'] ?? json['vod_pic'] ?? json['album_pic'] ?? json['picUrl'] ?? json['coverUrl'] ?? '').toString().split('|').first,
      description: (json['description'] ?? json['desc'] ?? json['content'] ?? json['vod_content'] ?? json['album'] ?? '').toString(),
      sourceId: sourceId,
      type: type,
      remark: (json['remark'] ?? json['vod_remarks'] ?? json['status'] ?? json['quality'])?.toString(),
      author: (json['author'] ?? json['artist'] ?? json['singer'] ?? json['song_singer'] ?? json['vod_actor'])?.toString(),
      year: (json['year'] ?? json['vod_year'] ?? json['duration'])?.toString(),
      category: (json['category'] ?? json['type_name'] ?? json['genre'] ?? json['type'])?.toString(),
      album: (json['album'] ?? json['album_name'])?.toString(),
      playUrl: (json['playUrl'] ?? json['play_url'] ?? json['url'] ?? json['audio_url'])?.toString(),
      lyrics: (json['lyrics'] ?? json['lyric'] ?? json['lrc'])?.toString(),
      episodes: _episodes(rawEpisodes),
    );
  }

  static List<MediaEpisode> _episodes(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => MediaEpisode(
        id: (e['id'] ?? e['url'] ?? e['chapterId'] ?? '').toString(),
        title: (e['title'] ?? e['name'] ?? e['chapterName'] ?? '').toString(),
        url: (e['url'] ?? e['link'] ?? e['chapterUrl'] ?? e['playUrl'] ?? '').toString(),
      )).where((e) => e.url.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) {
      return value.split(RegExp(r'\$\$\$|###')).expand((group) => group.split('#')).map((part) {
        final pieces = part.split(r'$');
        return MediaEpisode(
          id: pieces.length > 1 ? pieces[1].trim() : part.trim(),
          title: pieces.first.trim(),
          url: pieces.length > 1 ? pieces[1].trim() : part.trim(),
        );
      }).where((e) => e.url.isNotEmpty).toList();
    }
    return const [];
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'cover': cover,
    'description': description,
    'sourceId': sourceId,
    'type': type.name,
    'remark': remark,
    'author': author,
    'year': year,
    'category': category,
    'album': album,
    'playUrl': playUrl,
    'lyrics': lyrics,
  };
}

class MediaEpisode {
  final String id;
  final String title;
  final String url;
  const MediaEpisode({required this.id, required this.title, required this.url});
}

class SourceCategory {
  final String id;
  final String name;
  const SourceCategory({required this.id, required this.name});
}

class SourceDefinition {
  final String id;
  final String name;
  final String api;
  final ContentType type;
  final String? detail;
  final String? search;
  final String? ext;
  final bool enabled;
  final Map<String, String> headers;

  const SourceDefinition({
    required this.id,
    required this.name,
    required this.api,
    required this.type,
    this.detail,
    this.search,
    this.ext,
    this.enabled = true,
    this.headers = const {},
  });

  factory SourceDefinition.fromMap(Map<String, dynamic> json, {ContentType? forcedType}) {
    final rawType = (json['mediaType'] ?? json['contentType'] ?? json['type_name'] ?? json['type'] ?? '').toString().toLowerCase();
    final type = forcedType ?? (rawType.contains('comic') || rawType.contains('漫画')
        ? ContentType.comic
        : rawType.contains('novel') || rawType.contains('小说')
            ? ContentType.novel
            : rawType.contains('music') || rawType.contains('音乐')
                ? ContentType.music
                : ContentType.video);
    return SourceDefinition(
      id: (json['key'] ?? json['id'] ?? json['name'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      api: (json['api'] ?? json['url'] ?? '').toString(),
      type: type,
      detail: json['detail']?.toString(),
      search: json['search']?.toString(),
      ext: json['ext']?.toString(),
      enabled: json['enabled'] ?? json['isActive'] ?? true,
      headers: json['headers'] is Map ? Map<String, String>.from(json['headers']) : const {},
    );
  }

  Map<String, dynamic> toMap() => {
    'key': id,
    'name': name,
    'api': api,
    'type': type == ContentType.video ? 2 : 3,
    'mediaType': type.name,
    'detail': detail,
    'search': search,
    'ext': ext,
    'enabled': enabled,
    'headers': headers,
  };

  SourceDefinition copyWith({bool? enabled}) => SourceDefinition(
    id: id, name: name, api: api, type: type, detail: detail, search: search,
    ext: ext, enabled: enabled ?? this.enabled, headers: headers,
  );
}

class SearchResult {
  final String query;
  final List<MediaItem> items;
  final Map<String, String> errors;
  const SearchResult({required this.query, required this.items, this.errors = const {}});

  Map<String, dynamic> toMap() => {
    'query': query,
    'items': items.map((e) => e.toMap()).toList(),
    'errors': errors,
  };
}

String encodeJson(Object value) => const JsonEncoder.withIndent('  ').convert(value);
