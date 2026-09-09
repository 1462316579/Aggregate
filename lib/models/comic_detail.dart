/// 漫画详情 + 章节
class ComicDetail {
  final String id;
  final String title;
  final String cover;
  final String description;
  final String author;
  final String category;
  final String? status;
  final String? sourceKey;
  final List<ComicVolume> volumes;
  final Map<String, String> headers;

  ComicDetail({
    required this.id,
    required this.title,
    this.cover = '',
    this.description = '',
    this.author = '',
    this.category = '',
    this.status,
    this.sourceKey,
    this.volumes = const [],
    this.headers = const {},
  });

  factory ComicDetail.fromJson(Map<String, dynamic> json, {String? sourceKey}) {
    List<ComicVolume> volumes = [];
    
    if (json['chapters'] != null) {
      for (var ch in json['chapters']) {
        if (ch is Map<String, dynamic>) {
          volumes.add(ComicVolume.fromJson(ch));
        }
      }
    }
    if (json['episodeList'] != null) {
      for (var ep in json['episodeList']) {
        if (ep is Map<String, dynamic>) {
          volumes.add(ComicVolume.fromJson(ep));
        }
      }
    }
    // 如果没有分卷结构，将所有章节放在一个卷里
    if (volumes.isEmpty && json['chapterList'] != null) {
      List<ComicChapter> chapters = [];
      for (var ch in json['chapterList']) {
        if (ch is Map<String, dynamic>) {
          chapters.add(ComicChapter.fromJson(ch));
        }
      }
      if (chapters.isNotEmpty) {
        volumes.add(ComicVolume(name: '章节列表', chapters: chapters));
      }
    }

    return ComicDetail(
      id: (json['comicId'] ?? json['id'] ?? '').toString(),
      title: json['comicName'] ?? json['name'] ?? json['title'] ?? '',
      cover: json['coverUrl'] ?? json['cover'] ?? json['pic'] ?? '',
      description: json['intro'] ?? json['description'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? '',
      status: json['status'],
      sourceKey: sourceKey,
      volumes: volumes,
    );
  }
}

/// 漫画卷
class ComicVolume {
  final String name;
  final List<ComicChapter> chapters;

  ComicVolume({required this.name, this.chapters = const []});

  factory ComicVolume.fromJson(Map<String, dynamic> json) => ComicVolume(
    name: json['volumeName'] ?? json['name'] ?? '',
    chapters: (json['chapters'] ?? json['chapterList'] ?? [])
        .map<ComicChapter>((c) => ComicChapter.fromJson(c))
        .toList(),
  );
}

/// 漫画章节
class ComicChapter {
  final String id;
  final String name;
  final String url;
  final int index;

  ComicChapter({required this.id, required this.name, this.url = '', this.index = 0});

  factory ComicChapter.fromJson(Map<String, dynamic> json) => ComicChapter(
    id: (json['chapterId'] ?? json['id'] ?? '').toString(),
    name: json['chapterName'] ?? json['name'] ?? '',
    url: json['chapterUrl'] ?? json['url'] ?? '',
    index: json['index'] ?? 0,
  );
}

/// 漫画页面 (单张图片)
class ComicPage {
  final int index;
  final String imageUrl;
  final String? localPath; // 缓存后的本地路径

  ComicPage({required this.index, required this.imageUrl, this.localPath});
}
