/// 统一内容类型枚举
enum MediaType {
  video('视频'),
  comic('漫画'),
  novel('小说'),
  music('音乐'),
  live('直播');

  final String label;
  const MediaType(this.label);
}

/// 统一内容基类
/// 所有媒体类型共享的基础字段
class UnifiedContent {
  final String id;
  final String title;
  final String cover;
  final String description;
  final String author;      // 作者/歌手/画家
  final String category;    // 分类
  final String sourceKey;   // 所属源
  final MediaType mediaType;
  final String? status;     // 连载中/完结/...
  final String? year;
  final String? extra;      // 扩展字段 (JSON字符串)

  UnifiedContent({
    required this.id,
    required this.title,
    this.cover = '',
    this.description = '',
    this.author = '',
    this.category = '',
    required this.sourceKey,
    required this.mediaType,
    this.status,
    this.year,
    this.extra,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'cover': cover, 'description': description,
    'author': author, 'category': category, 'sourceKey': sourceKey,
    'mediaType': mediaType.name, 'status': status, 'year': year, 'extra': extra,
  };

  factory UnifiedContent.fromVideo(Map<String, dynamic> json, String sourceKey) => UnifiedContent(
    id: (json['vod_id'] ?? json['id'] ?? '').toString(),
    title: json['vod_name'] ?? json['name'] ?? '',
    cover: (json['vod_pic'] ?? json['pic'] ?? '').toString().split('|').first.trim(),
    description: json['vod_content'] ?? json['content'] ?? '',
    author: json['vod_director'] ?? json['vod_actor'] ?? json['author'] ?? '',
    category: json['type_name'] ?? json['type'] ?? '',
    sourceKey: sourceKey,
    mediaType: MediaType.video,
    status: json['vod_remarks'] ?? json['remony'],
    year: json['vod_year'] ?? json['year'],
  );

  factory UnifiedContent.fromComic(Map<String, dynamic> json, String sourceKey) => UnifiedContent(
    id: (json['comicId'] ?? json['id'] ?? '').toString(),
    title: json['comicName'] ?? json['name'] ?? json['title'] ?? '',
    cover: json['coverUrl'] ?? json['cover'] ?? json['pic'] ?? '',
    description: json['intro'] ?? json['description'] ?? json['desc'] ?? '',
    author: json['author'] ?? json['artist'] ?? '',
    category: json['category'] ?? json['type'] ?? '',
    sourceKey: sourceKey,
    mediaType: MediaType.comic,
    status: json['status'] ?? json['state'] ?? (json['isEnd'] == true ? '完结' : '连载'),
    year: json['year'],
    extra: json['tag']?.toString(),
  );

  factory UnifiedContent.fromNovel(Map<String, dynamic> json, String sourceKey) => UnifiedContent(
    id: (json['novelId'] ?? json['bookId'] ?? json['id'] ?? '').toString(),
    title: json['novelName'] ?? json['bookName'] ?? json['name'] ?? json['title'] ?? '',
    cover: json['coverUrl'] ?? json['cover'] ?? json['pic'] ?? '',
    description: json['intro'] ?? json['description'] ?? json['desc'] ?? '',
    author: json['author'] ?? '',
    category: json['category'] ?? json['type'] ?? '',
    sourceKey: sourceKey,
    mediaType: MediaType.novel,
    status: json['status'] ?? (json['isEnd'] == true ? '完结' : '连载'),
    year: json['latestChapter'] != null ? null : json['year'],
    extra: json['latestChapter'],
  );

  factory UnifiedContent.fromMusic(Map<String, dynamic> json, String sourceKey) => UnifiedContent(
    id: (json['songId'] ?? json['id'] ?? '').toString(),
    title: json['songName'] ?? json['name'] ?? json['title'] ?? '',
    cover: json['coverUrl'] ?? json['pic'] ?? '',
    description: json['album'] ?? json['albumName'] ?? '',
    author: json['singer'] ?? json['artist'] ?? json['author'] ?? '',
    category: json['category'] ?? json['tag'] ?? '',
    sourceKey: sourceKey,
    mediaType: MediaType.music,
    year: json['duration']?.toString(),
    extra: json['lyric'],
  );

  UnifiedContent copyWith({String? id, String? title, String? cover, String? sourceKey}) =>
    UnifiedContent(
      id: id ?? this.id, title: title ?? this.title, cover: cover ?? this.cover,
      description: description, author: author, category: category,
      sourceKey: sourceKey ?? this.sourceKey, mediaType: mediaType,
      status: status, year: year, extra: extra,
    );
}
