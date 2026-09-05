/// 视频内容
class VideoContent {
  final String id;
  final String name;
  final String pic;
  final String? desc;
  final String? category;
  final String? year;
  final String? area;
  final String? director;
  final String? actor;
  final String? remark;
  final List<VideoEpisode>? episodes;
  final String? sourceKey;

  VideoContent({
    required this.id, required this.name, required this.pic,
    this.desc, this.category, this.year, this.area,
    this.director, this.actor, this.remark,
    this.episodes, this.sourceKey,
  });

  factory VideoContent.fromJson(Map<String, dynamic> json) => VideoContent(
    id: (json['vod_id'] ?? json['id'] ?? '').toString(),
    name: json['vod_name'] ?? json['name'] ?? '',
    pic: (json['vod_pic'] ?? json['pic'] ?? '').toString().split('|').first,
    desc: json['vod_content'] ?? json['content'],
    category: json['type_name'] ?? json['type'],
    year: json['vod_year'] ?? json['year'],
    area: json['vod_area'] ?? json['area'],
    director: json['vod_director'] ?? json['director'],
    actor: json['vod_actor'] ?? json['actor'],
    remark: json['vod_remarks'] ?? json['remark'],
    sourceKey: json['sourceKey'],
  );
}

class VideoEpisode {
  final String name;
  final String url;
  VideoEpisode({required this.name, required this.url});
}
