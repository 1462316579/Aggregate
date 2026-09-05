/// 小说详情 + 章节
class NovelDetail {
  final String id;
  final String title;
  final String cover;
  final String description;
  final String author;
  final String category;
  final String? status;
  final String? sourceKey;
  final List<NovelChapter> chapters;

  NovelDetail({
    required this.id,
    required this.title,
    this.cover = '',
    this.description = '',
    this.author = '',
    this.category = '',
    this.status,
    this.sourceKey,
    this.chapters = const [],
  });

  factory NovelDetail.fromJson(Map<String, dynamic> json, {String? sourceKey}) {
    List<NovelChapter> chapters = [];
    
    if (json['chapters'] != null) {
      for (var ch in json['chapters']) {
        if (ch is Map<String, dynamic>) {
          chapters.add(NovelChapter.fromJson(ch));
        }
      }
    }
    if (json['chapterList'] != null) {
      for (var ch in json['chapterList']) {
        if (ch is Map<String, dynamic>) {
          chapters.add(NovelChapter.fromJson(ch));
        }
      }
    }
    if (json['episodeList'] != null) {
      for (var ch in json['episodeList']) {
        if (ch is Map<String, dynamic>) {
          chapters.add(NovelChapter.fromJson(ch));
        }
      }
    }

    return NovelDetail(
      id: (json['novelId'] ?? json['bookId'] ?? json['id'] ?? '').toString(),
      title: json['novelName'] ?? json['bookName'] ?? json['name'] ?? '',
      cover: json['coverUrl'] ?? json['cover'] ?? json['pic'] ?? '',
      description: json['intro'] ?? json['description'] ?? '',
      author: json['author'] ?? '',
      category: json['category'] ?? '',
      status: json['status'],
      sourceKey: sourceKey,
      chapters: chapters,
    );
  }
}

/// 小说章节
class NovelChapter {
  final String id;
  final String name;
  final String url;
  final String? content;   // 章节正文 (获取详情后填充)
  final int index;

  NovelChapter({required this.id, required this.name, this.url = '', this.content, this.index = 0});

  factory NovelChapter.fromJson(Map<String, dynamic> json) => NovelChapter(
    id: (json['chapterId'] ?? json['id'] ?? '').toString(),
    name: json['chapterName'] ?? json['name'] ?? '',
    url: json['chapterUrl'] ?? json['url'] ?? '',
    content: json['content'],
    index: json['index'] ?? 0,
  );

  NovelChapter copyWith({String? content}) => NovelChapter(
    id: id, name: name, url: url, content: content ?? this.content, index: index,
  );
}

/// 小说阅读进度
class NovelProgress {
  final String novelId;
  final String sourceKey;
  final String chapterId;
  final int chapterIndex;
  final double scrollPosition; // 阅读位置百分比
  final int timestamp;

  NovelProgress({
    required this.novelId,
    required this.sourceKey,
    required this.chapterId,
    required this.chapterIndex,
    this.scrollPosition = 0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'novelId': novelId, 'sourceKey': sourceKey, 'chapterId': chapterId,
    'chapterIndex': chapterIndex, 'scrollPosition': scrollPosition, 'timestamp': timestamp,
  };

  factory NovelProgress.fromJson(Map<String, dynamic> json) => NovelProgress(
    novelId: json['novelId'], sourceKey: json['sourceKey'],
    chapterId: json['chapterId'], chapterIndex: json['chapterIndex'],
    scrollPosition: (json['scrollPosition'] ?? 0).toDouble(), timestamp: json['timestamp'],
  );
}
