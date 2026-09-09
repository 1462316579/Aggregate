/// 增强版视频源模型 — 支持所有媒体类型
class VideoSource {
  final String key;
  final String name;
  final String api;
  final String? detailApi;
  final String? searchApi;
  final String? categories;
  final String? playerApi;
  final int type;       // 1=xml, 2=json, 3=spider, 4=live
  final String? ext;
  final String? spider;
  final List<String> headers;
  final bool isActive;
  final String mediaType; // video/comic/novel/music/live
  final Map<String, String>? searchHeaders;

  VideoSource({
    required this.key,
    required this.name,
    required this.api,
    this.detailApi,
    this.searchApi,
    this.categories,
    this.playerApi,
    this.type = 2,
    this.ext,
    this.spider,
    this.headers = const [],
    this.isActive = true,
    this.mediaType = 'video',
    this.searchHeaders,
  });

  Map<String, dynamic> toJson() => {
    'key': key, 'name': name, 'api': api, 'detailApi': detailApi,
    'searchApi': searchApi, 'categories': categories, 'playerApi': playerApi,
    'type': type, 'ext': ext, 'spider': spider, 'headers': headers,
    'isActive': isActive, 'mediaType': mediaType,
  };

  factory VideoSource.fromJson(Map<String, dynamic> json) => VideoSource(
    key: json['key'] ?? json['name'] ?? '',
    name: json['name'] ?? '',
    api: json['api'] ?? '',
    detailApi: json['detailApi'] ?? json['detail'],
    searchApi: json['searchApi'] ?? json['search'],
    categories: json['categories'] is String
        ? json['categories'] : json['categories']?.join(','),
    playerApi: json['playerApi'] ?? json['player_parse'],
    type: json['type'] ?? 2,
    ext: json['ext'], spider: json['spider'],
    headers: json['headers'] != null ? List<String>.from(json['headers']) : [],
    isActive: json['isActive'] ?? true,
    mediaType: json['mediaType'] ?? 'video',
  );

  VideoSource copyWith({
    String? key, String? name, String? api, String? mediaType, bool? isActive,
  }) => VideoSource(
    key: key ?? this.key, name: name ?? this.name, api: api ?? this.api,
    detailApi: detailApi, searchApi: searchApi, categories: categories,
    playerApi: playerApi, type: type, ext: ext, spider: spider,
    headers: headers, isActive: isActive ?? this.isActive,
    mediaType: mediaType ?? this.mediaType,
  );
}
