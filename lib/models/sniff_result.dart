/// 嗅探结果模型
enum SniffProtocol {
  m3u8('M3U8', 'HLS 流媒体'),
  mp4('MP4', 'MP4 视频'),
  flv('FLV', 'FLV 流'),
  ts('TS', 'MPEG-TS 流'),
  mkv('MKV', 'MKV 视频'),
  avi('AVI', 'AVI 视频'),
  wmv('WMV', 'WMV 视频'),
  mov('MOV', 'QuickTime'),
  webm('WebM', 'WebM 视频'),
  rmvb('RMVB', 'RealMedia'),
  m3u('M3U', '播放列表'),
  api('API', '视频接口'),
  unknown('未知', '未知格式');

  final String label;
  final String desc;
  const SniffProtocol(this.label, this.desc);
}

class SniffResult {
  final String url;
  final String? title;           // 页面标题
  final String? referer;         // 来源页面
  final String? pageTitle;       // 视频所在页面标题
  final SniffProtocol protocol;  // 协议类型
  final String? mimeType;        // MIME 类型
  final int? contentLength;      // 文件大小 (bytes)
  final String? resolution;      // 分辨率 (如 1920x1080)
  final DateTime timestamp;
  final bool isPlaying;          // 当前是否正在播放
  final Map<String, String> headers; // 请求头
  final String? quality;         // 画质标签

  SniffResult({
    required this.url,
    this.title,
    this.referer,
    this.pageTitle,
    required this.protocol,
    this.mimeType,
    this.contentLength,
    this.resolution,
    DateTime? timestamp,
    this.isPlaying = false,
    this.headers = const {},
    this.quality,
  }) : timestamp = timestamp ?? DateTime.now();

  /// 从 URL 和 MIME 自动推断协议类型
  factory SniffResult.fromUrl({
    required String url,
    String? mimeType,
    String? referer,
    String? pageTitle,
    Map<String, String> headers = const {},
  }) {
    final lower = url.toLowerCase();
    final protocol = _detectProtocol(lower, mimeType);

    return SniffResult(
      url: url,
      referer: referer,
      pageTitle: pageTitle,
      protocol: protocol,
      mimeType: mimeType,
      headers: headers,
      quality: _detectQuality(lower),
    );
  }

  static SniffProtocol _detectProtocol(String lower, String? mime) {
    // 优先根据 MIME 类型判断
    if (mime != null) {
      final m = mime.toLowerCase();
      if (m.contains('mpegurl') || m.contains('x-mpegurl') || m.includes('m3u8'))
        return SniffProtocol.m3u8;
      if (m.contains('video/mp4')) return SniffProtocol.mp4;
      if (m.contains('video/x-flv') || m.contains('flv')) return SniffProtocol.flv;
      if (m.contains('video/mp2t')) return SniffProtocol.ts;
      if (m.contains('video/webm')) return SniffProtocol.webm;
      if (m.contains('mkv') || m.contains('matroska')) return SniffProtocol.mkv;
    }

    // 根据 URL 扩展名判断
    if (lower.contains('.m3u8') || lower.contains('mpegurl'))
      return SniffProtocol.m3u8;
    if (lower.contains('.mp4') || lower.contains('video/mp4'))
      return SniffProtocol.mp4;
    if (lower.contains('.flv')) return SniffProtocol.flv;
    if (lower.contains('.ts') && !lower.contains('.tsx') && !lower.contains('test'))
      return SniffProtocol.ts;
    if (lower.contains('.mkv')) return SniffProtocol.mkv;
    if (lower.contains('.avi')) return SniffProtocol.avi;
    if (lower.contains('.wmv')) return SniffProtocol.wmv;
    if (lower.contains('.mov')) return SniffProtocol.mov;
    if (lower.contains('.webm')) return SniffProtocol.webm;
    if (lower.contains('.rmvb') || lower.contains('.rm')) return SniffProtocol.rmvb;
    if (lower.contains('.m3u') && !lower.contains('.m3u8'))
      return SniffProtocol.m3u;

    // 根据 URL 路径关键词判断
    if (lower.contains('/play/') || lower.includes('playurl') ||
        lower.contains('videoplay') || lower.contains('get_video'))
      return SniffProtocol.api;

    return SniffProtocol.unknown;
  }

  static String? _detectQuality(String lower) {
    if (lower.contains('1080p') || lower.contains('1080') || lower.contains('fhd'))
      return '1080P';
    if (lower.contains('720p') || lower.contains('720') || lower.contains('hd'))
      return '720P';
    if (lower.contains('480p') || lower.contains('480') || lower.contains('sd'))
      return '480P';
    if (lower.contains('4k') || lower.contains('2160p'))
      return '4K';
    if (lower.contains('2k') || lower.contains('1440p'))
      return '2K';
    return null;
  }

  /// 是否为可直接播放的视频流
  bool get isPlayable =>
      protocol == SniffProtocol.m3u8 ||
      protocol == SniffProtocol.mp4 ||
      protocol == SniffProtocol.flv ||
      protocol == SniffProtocol.ts ||
      protocol == SniffProtocol.webm ||
      protocol == SniffProtocol.mkv;

  /// 格式化文件大小
  String get fileSize {
    if (contentLength == null) return '未知';
    if (contentLength! < 1024) return '$contentLength B';
    if (contentLength! < 1024 * 1024) return '${(contentLength! / 1024).toStringAsFixed(1)} KB';
    if (contentLength! < 1024 * 1024 * 1024)
      return '${(contentLength! / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(contentLength! / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  /// 去重 key
  String get dedupeKey => url.split('?').first;

  @override
  bool operator ==(Object other) =>
      other is SniffResult && other.dedupeKey == dedupeKey;

  @override
  int get hashCode => dedupeKey.hashCode;
}
