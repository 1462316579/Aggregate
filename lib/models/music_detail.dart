/// 音乐内容 + 歌单
class MusicDetail {
  final String id;
  final String title;
  final String cover;
  final String author;
  final String? album;
  final String? sourceKey;
  final String? playUrl;
  final String? lyric;
  final List<MusicTrack> tracks;

  MusicDetail({
    required this.id,
    required this.title,
    this.cover = '',
    this.author = '',
    this.album,
    this.sourceKey,
    this.playUrl,
    this.lyric,
    this.tracks = const [],
  });

  factory MusicDetail.fromJson(Map<String, dynamic> json, {String? sourceKey}) {
    List<MusicTrack> tracks = [];
    if (json['tracks'] != null) {
      for (var t in json['tracks']) {
        if (t is Map<String, dynamic>) tracks.add(MusicTrack.fromJson(t));
      }
    }

    return MusicDetail(
      id: (json['songId'] ?? json['id'] ?? '').toString(),
      title: json['songName'] ?? json['name'] ?? '',
      cover: json['coverUrl'] ?? json['pic'] ?? '',
      author: json['singer'] ?? json['artist'] ?? json['author'] ?? '',
      album: json['album'] ?? json['albumName'],
      sourceKey: sourceKey,
      playUrl: json['playUrl'] ?? json['url'],
      lyric: json['lyric'],
      tracks: tracks,
    );
  }
}

/// 音乐曲目
class MusicTrack {
  final String id;
  final String name;
  final String author;
  final String cover;
  final String? album;
  final String? playUrl;
  final int duration; // 秒
  final String? lyric;

  MusicTrack({
    required this.id,
    required this.name,
    this.author = '',
    this.cover = '',
    this.album,
    this.playUrl,
    this.duration = 0,
    this.lyric,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) => MusicTrack(
    id: (json['songId'] ?? json['id'] ?? '').toString(),
    name: json['songName'] ?? json['name'] ?? '',
    author: json['singer'] ?? json['artist'] ?? json['author'] ?? '',
    cover: json['coverUrl'] ?? json['pic'] ?? '',
    album: json['album'] ?? json['albumName'],
    playUrl: json['playUrl'] ?? json['url'] ?? json['play_url'],
    duration: json['duration'] ?? 0,
    lyric: json['lyric'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'author': author, 'cover': cover,
    'album': album, 'playUrl': playUrl, 'duration': duration,
  };
}

/// 歌词行
class LyricLine {
  final Duration time;
  final String text;

  LyricLine({required this.time, required this.text});

  /// 解析 LRC 格式歌词
  static List<LyricLine> parse(String lrc) {
    List<LyricLine> lines = [];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.?(\d{0,3})\](.*)');

    for (var line in lrc.split('\n')) {
      final match = regex.firstMatch(line.trim());
      if (match != null) {
        final min = int.parse(match.group(1)!);
        final sec = int.parse(match.group(2)!);
        final msStr = match.group(3) ?? '0';
        final ms = int.parse(msStr.padRight(3, '0'));
        final text = match.group(4)?.trim() ?? '';
        if (text.isNotEmpty) {
          lines.add(LyricLine(
            time: Duration(minutes: min, seconds: sec, milliseconds: ms),
            text: text,
          ));
        }
      }
    }

    lines.sort((a, b) => a.time.compareTo(b.time));
    return lines;
  }
}
