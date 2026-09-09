/// 视频源的分类信息
class SourceCategory {
  final String id;
  final String name;
  final String type;  // video/comic/novel/music/live
  final List<SubCategory>? subs;

  SourceCategory({required this.id, required this.name, this.type = 'video', this.subs});

  factory SourceCategory.fromJson(Map<String, dynamic> json) => SourceCategory(
    id: (json['id'] ?? json['tid'] ?? '').toString(),
    name: json['name'] ?? json['type_name'] ?? '',
    type: json['mediaType'] ?? 'video',
    subs: json['sub'] != null
        ? (json['sub'] as List).map((s) => SourceCategory.fromJson(s)).toList()
        : null,
  );
}
