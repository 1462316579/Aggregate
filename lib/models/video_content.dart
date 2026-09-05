/// 视频内容信息
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
    required this.id,
    required this.name,
    required this.pic,
    this.desc,
    this.category,
    this.year,
    this.area,
    this.director,
    this.actor,
    this.remark,
    this.episodes,
    this.sourceKey,
  });

  Map<String, dynamic> toJson() => {
    'vod_id': id,
    'vod_name': name,
    'vod_pic': pic,
    'vod_content': desc,
    'type_name': category,
    'vod_year': year,
    'vod_area': area,
    'vod_director': director,
    'vod_actor': actor,
    'vod_remarks': remark,
  };

  factory VideoContent.fromJson(Map<String, dynamic> json, {String? sourceKey}) {
    // 支持 V3 格式和普通格式
    final pic = json['vod_pic'] ?? json['pic'] ?? json['img'] ?? '';
    // 处理可能的多图格式 (||分隔)
    final firstPic = pic.split('|').first.trim();

    return VideoContent(
      id: (json['vod_id'] ?? json['id'] ?? '').toString(),
      name: json['vod_name'] ?? json['name'] ?? '',
      pic: firstPic,
      desc: json['vod_content'] ?? json['content'] ?? json['desc'] ?? '',
      category: json['type_name'] ?? json['category'] ?? json['type'] ?? '',
      year: json['vod_year'] ?? json['year'] ?? '',
      area: json['vod_area'] ?? json['area'] ?? '',
      director: json['vod_director'] ?? json['director'] ?? '',
      actor: json['vod_actor'] ?? json['actor'] ?? '',
      remark: json['vod_remarks'] ?? json['remony'] ?? json['remark'] ?? '',
      episodes: _parseEpisodes(json),
      sourceKey: sourceKey,
    );
  }

  static List<VideoEpisode>? _parseEpisodes(Map<String, dynamic> json) {
    final episodeList = json['vod_play_url'] ?? json['episodes'];
    if (episodeList == null) return null;

    List<VideoEpisode> episodes = [];

    if (episodeList is List) {
      for (var ep in episodeList) {
        if (ep is Map<String, dynamic>) {
          episodes.add(VideoEpisode.fromJson(ep));
        }
      }
    } else if (episodeList is String && episodeList.isNotEmpty) {
      // TVBox V3 格式: 详情里有多条播放链接
      final groups = episodeList.split('\$\$\$');
      for (var group in groups) {
        if (group.contains('#')) {
          final parts = group.split('#');
          for (var part in parts) {
            if (part.contains('\$')) {
              final epParts = part.split('\$');
              episodes.add(VideoEpisode(
                name: epParts[0].trim(),
                url: epParts.length > 1 ? epParts[1].trim() : '',
              ));
            }
          }
        } else if (group.contains('\$')) {
          final epParts = group.split('\$');
          episodes.add(VideoEpisode(
            name: epParts[0].trim(),
            url: epParts.length > 1 ? epParts[1].trim() : '',
          ));
        }
      }
    }

    return episodes.isEmpty ? null : episodes;
  }

  VideoContent copyWith({
    String? id,
    String? name,
    String? pic,
    String? desc,
    String? category,
    String? year,
    String? area,
    String? director,
    String? actor,
    String? remark,
    List<VideoEpisode>? episodes,
    String? sourceKey,
  }) => VideoContent(
    id: id ?? this.id,
    name: name ?? this.name,
    pic: pic ?? this.pic,
    desc: desc ?? this.desc,
    category: category ?? this.category,
    year: year ?? this.year,
    area: area ?? this.area,
    director: director ?? this.director,
    actor: actor ?? this.actor,
    remark: remark ?? this.remark,
    episodes: episodes ?? this.episodes,
    sourceKey: sourceKey ?? this.sourceKey,
  );
}

/// 单集信息
class VideoEpisode {
  final String name;
  final String url;
  final String? extra;

  VideoEpisode({
    required this.name,
    required this.url,
    this.extra,
  });

  factory VideoEpisode.fromJson(Map<String, dynamic> json) => VideoEpisode(
    name: json['name'] ?? json['ep_name'] ?? '',
    url: json['url'] ?? json['ep_url'] ?? '',
    extra: json['extra'],
  );
}
