/// 视频嗅探服务
/// 核心能力:
///   1. WebView 网络拦截 — 监听所有 HTTP/HTTPS 请求，自动识别视频 URL
///   2. 已知视频源 API 解析 — 解析 JSONP/JSON 中的播放地址
///   3. 剪贴板智能检测 — 检测剪贴板中的视频链接
///   4. HTML 源码分析 — 从 JS/HTML 中提取嵌入的视频地址
///   5. DNS 预解析 — 快速验证资源可用性
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class VideoSnifferService {
  // ════════════════════════════════════════
  //  视频 URL 正则模式库
  // ════════════════════════════════════════

  /// 视频文件扩展名匹配
  static final _videoUrlPatterns = RegExp(
    r'https?://[^\s"\'<>]+\.(m3u8|mp4|flv|ts|mkv|avi|wmv|mov|webm|rmvb|m3u)'
    r'(\?[^\s"\'<>]*)?',
    caseSensitive: false,
  );

  /// HLS manifest 匹配
  static final _hlsPatterns = RegExp(
    r'https?://[^\s"\'<>]+/[^"\'<>\s]*\.m3u8[^\s"\'<>]*',
    caseSensitive: false,
  );

  /// 常见视频 CDN 域名
  static const _videoCdnDomains = [
    'aliyuncs.com',
    'myqcloud.com',
    'clouddn.com',
    'volccdn.com',
    'bytecdn.cn',
    'bjhmt.com',
    'hdslb.com',
    'bilibili.com',
    'acgvideo.com',
    'ixigua.com',
    'douyinvod.com',
    'cdn86.cn',
    'qncdn.com',
    'xmly.com',
    'qiying.com',
    'hwcdn.net',
    'fastly.net',
    'cloudfront.net',
    'akamaized.net',
    'jwpltx.com',
  ];

  /// 常见视频 API 接口模式
  static final _videoApiPatterns = [
    RegExp(r'play(?:er)?_?url\s*[=:]\s*["\']?(https?://[^\s"\'<>]+)', caseSensitive: false),
    RegExp(r'video_?url\s*[=:]\s*["\']?(https?://[^\s"\'<>]+)', caseSensitive: false),
    RegExp(r'src\s*[=:]\s*["\']?(https?://[^\s"\'<>]+\.(m3u8|mp4|flv)[^\s"\'<>]*)', caseSensitive: false),
    RegExp(r'url\s*[=:]\s*["\']?(https?://[^\s"\'<>]+\.(m3u8|mp4|flv)[^\s"\'<>]*)', caseSensitive: false),
    RegExp(r'file\s*[=:]\s*["\']?(https?://[^\s"\'<>]+\.(m3u8|mp4|flv)[^\s"\'<>]*)', caseSensitive: false),
    RegExp(r'["\']https?://[^\s"\'<>]+\.m3u8[^\s"\'<>]*["\']'),
    RegExp(r'["\']https?://[^\s"\'<>]+\.mp4[^\s"\'<>]*["\']'),
  ];

  // ════════════════════════════════════════
  //  WebView 拦截回调处理
  // ════════════════════════════════════════

  /// 从 WebView 拦截到的请求中筛选视频 URL
  /// 由 WebView 的 shouldOverrideUrlLoading / onLoadResource 调用
  static List<SniffCandidate> processWebViewRequest({
    required String url,
    String? contentType,
    String? referer,
    int? contentLength,
    Map<String, String>? responseHeaders,
  }) {
    List<SniffCandidate> candidates = [];

    // 1. 直接检查 URL 本身
    if (_isVideoUrl(url)) {
      candidates.add(SniffCandidate(
        url: url,
        mimeType: contentType,
        contentLength: contentLength,
        referer: referer,
        confidence: SniffConfidence.high,
        reason: 'URL 匹配视频扩展名',
      ));
    }

    // 2. 检查 MIME 类型
    if (contentType != null && _isVideoMime(contentType)) {
      candidates.add(SniffCandidate(
        url: url,
        mimeType: contentType,
        contentLength: contentLength,
        referer: referer,
        confidence: SniffConfidence.high,
        reason: 'MIME 类型: $contentType',
      ));
    }

    // 3. 检查 CDN 域名
    if (_isVideoCdn(url)) {
      candidates.add(SniffCandidate(
        url: url,
        mimeType: contentType,
        contentLength: contentLength,
        referer: referer,
        confidence: SniffConfidence.medium,
        reason: '视频 CDN 域名',
      ));
    }

    return candidates;
  }

  // ════════════════════════════════════════
  //  HTML/JS 源码分析
  // ════════════════════════════════════════

  /// 从网页 HTML 源码中提取视频地址
  static List<SniffCandidate> analyzeHtml(String html, {String? pageUrl}) {
    List<SniffCandidate> candidates = [];
    final Set<String> seen = {};

    // 1. 正则匹配所有视频 URL
    for (var match in _videoUrlPatterns.allMatches(html)) {
      final url = _cleanUrl(match.group(0)!);
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        candidates.add(SniffCandidate(
          url: url,
          referer: pageUrl,
          confidence: SniffConfidence.high,
          reason: 'HTML 正则匹配',
        ));
      }
    }

    // 2. 匹配常见视频 API 模式
    for (var pattern in _videoApiPatterns) {
      for (var match in pattern.allMatches(html)) {
        final url = _extractUrl(match);
        if (url != null && !seen.contains(url)) {
          seen.add(url);
          candidates.add(SniffCandidate(
            url: url,
            referer: pageUrl,
            confidence: SniffConfidence.medium,
            reason: 'JS 变量提取',
          ));
        }
      }
    }

    // 3. 提取 <source> / <video> 标签中的 src
    final sourceTagPattern = RegExp(
      r'<(?:source|video)[^>]+src\s*=\s*["\']([^"\']+)["\']',
      caseSensitive: false,
    );
    for (var match in sourceTagPattern.allMatches(html)) {
      final url = _cleanUrl(match.group(1)!);
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        candidates.add(SniffCandidate(
          url: url,
          referer: pageUrl,
          confidence: SniffConfidence.high,
          reason: 'HTML 标签提取',
        ));
      }
    }

    // 4. 提取 iframe 嵌入的视频地址
    final iframePattern = RegExp(
      r'<iframe[^>]+src\s*=\s*["\']([^"\']*(?:player|video|embed|play)[^"\']*)["\']',
      caseSensitive: false,
    );
    for (var match in iframePattern.allMatches(html)) {
      final url = _cleanUrl(match.group(1)!);
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        candidates.add(SniffCandidate(
          url: url,
          referer: pageUrl,
          confidence: SniffConfidence.low,
          reason: 'iframe 嵌入',
        ));
      }
    }

    // 5. 匹配 JSONP 回调中的视频数据
    final jsonpPattern = RegExp(
      r'(?:callback|jsonp)\s*\(\s*(\{[^)]+\})\s*\)',
      dotAll: true,
    );
    for (var match in jsonpPattern.allMatches(html)) {
      try {
        final json = jsonDecode(match.group(1)!);
        _extractUrlsFromJson(json, candidates, seen, pageUrl);
      } catch (_) {}
    }

    return candidates;
  }

  /// 递归从 JSON 中提取视频 URL
  static void _extractUrlsFromJson(
    dynamic json, List<SniffCandidate> candidates,
    Set<String> seen, String? pageUrl,
  ) {
    if (json is Map<String, dynamic>) {
      for (var entry in json.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        if (value is String && value.startsWith('http')) {
          // 可能是视频 URL 的字段名
          if (_isVideoUrl(value) ||
              key.contains('url') || key.contains('video') ||
              key.contains('play') || key.contains('src') ||
              key.contains('m3u8') || key.contains('stream')) {
            if (!seen.contains(value)) {
              seen.add(value);
              candidates.add(SniffCandidate(
                url: value,
                referer: pageUrl,
                confidence: key.contains('url') || key.contains('src')
                    ? SniffConfidence.medium
                    : SniffConfidence.low,
                reason: 'JSON 字段: ${entry.key}',
              ));
            }
          }
        } else if (value is Map || value is List) {
          _extractUrlsFromJson(value, candidates, seen, pageUrl);
        }
      }
    } else if (json is List) {
      for (var item in json) {
        _extractUrlsFromJson(item, candidates, seen, pageUrl);
      }
    }
  }

  // ════════════════════════════════════════
  //  视频源 API 解析
  // ════════════════════════════════════════

  /// 通用视频 API 解析 — 尝试从 API 响应中提取播放地址
  static Future<List<SniffCandidate>> sniffFromApi(String apiUrl, {
    String? referer,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          if (referer != null) 'Referer': referer,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = response.body;
      List<SniffCandidate> candidates = [];

      // 尝试 JSON 解析
      try {
        final json = jsonDecode(body);
        _extractUrlsFromJson(json, candidates, {}, referer);
      } catch (_) {
        // 不是 JSON，当 HTML 处理
        candidates.addAll(analyzeHtml(body, pageUrl: apiUrl));
      }

      return candidates;
    } catch (_) {
      return [];
    }
  }

  /// 解析 M3U8 播放列表，提取子流地址
  static Future<List<SniffCandidate>> sniffM3u8(String m3u8Url, {
    String? referer,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(m3u8Url),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          if (referer != null) 'Referer': referer,
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final body = response.body;
      List<SniffCandidate> candidates = [];
      final baseUri = Uri.parse(m3u8Url);

      final lines = body.split('\n');
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty || line.startsWith('#')) continue;

        // 解析相对路径
        String resolvedUrl;
        if (line.startsWith('http')) {
          resolvedUrl = line;
        } else {
          resolvedUrl = baseUri.resolve(line).toString();
        }

        final isPlaylist = resolvedUrl.endsWith('.m3u8');
        candidates.add(SniffCandidate(
          url: resolvedUrl,
          referer: referer,
          confidence: isPlaylist ? SniffConfidence.medium : SniffConfidence.high,
          reason: isPlaylist ? 'HLS 子播放列表' : 'HLS 视频分片',
        ));
      }

      return candidates;
    } catch (_) {
      return [];
    }
  }

  // ════════════════════════════════════════
  //  剪贴板检测
  // ════════════════════════════════════════

  /// 从剪贴板文本中检测视频链接
  static List<SniffCandidate> detectFromText(String text) {
    List<SniffCandidate> candidates = [];
    final Set<String> seen = {};

    // 匹配所有可能的视频 URL
    for (var match in _videoUrlPatterns.allMatches(text)) {
      final url = _cleanUrl(match.group(0)!);
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        candidates.add(SniffCandidate(
          url: url,
          confidence: SniffConfidence.high,
          reason: '文本检测',
        ));
      }
    }

    // 匹配 M3U8 相关 URL (可能不含 .m3u8 后缀)
    for (var match in _hlsPatterns.allMatches(text)) {
      final url = _cleanUrl(match.group(0)!);
      if (url.isNotEmpty && !seen.contains(url)) {
        seen.add(url);
        candidates.add(SniffCandidate(
          url: url,
          confidence: SniffConfidence.high,
          reason: 'HLS 地址检测',
        ));
      }
    }

    return candidates;
  }

  // ════════════════════════════════════════
  //  工具方法
  // ════════════════════════════════════════

  static bool _isVideoUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') ||
        lower.contains('.mp4') ||
        lower.contains('.flv') ||
        (lower.contains('.ts') && !lower.contains('.tsx') && !lower.contains('test') && !lower.contains('typescript')) ||
        lower.contains('.mkv') ||
        lower.contains('.avi') ||
        lower.contains('.wmv') ||
        lower.contains('.mov') ||
        lower.contains('.webm') ||
        lower.contains('.rmvb') ||
        lower.contains('.rm') ||
        lower.contains('mpegurl');
  }

  static bool _isVideoMime(String mime) {
    final m = mime.toLowerCase();
    return m.contains('video/') ||
        m.contains('mpegurl') ||
        m.contains('x-mpegurl') ||
        m.includes('m3u8');
  }

  static bool _isVideoCdn(String url) {
    final lower = url.toLowerCase();
    return _videoCdnDomains.any((d) => lower.contains(d));
  }

  static String _cleanUrl(String url) {
    url = url.trim();
    // 去除首尾引号
    if ((url.startsWith('"') && url.endsWith('"')) ||
        (url.startsWith("'") && url.endsWith("'"))) {
      url = url.substring(1, url.length - 1);
    }
    // 去除转义
    url = url.replaceAll('\\/', '/').replaceAll('\\u0026', '&');
    return url;
  }

  static String? _extractUrl(Match match) {
    // 尝试所有分组，找到 URL
    for (int i = 1; i <= match.groupCount; i++) {
      final group = match.group(i);
      if (group != null && group.startsWith('http')) {
        return _cleanUrl(group);
      }
    }
    return null;
  }

  /// 验证 URL 是否可访问 (HEAD 请求)
  static Future<SniffVerification> verifyUrl(String url, {
    String? referer,
  }) async {
    try {
      final response = await http.head(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0',
          if (referer != null) 'Referer': referer,
        },
      ).timeout(const Duration(seconds: 5));

      final contentType = response.headers['content-type'];
      final contentLength = response.headers['content-length'];

      return SniffVerification(
        accessible: response.statusCode == 200 || response.statusCode == 206,
        statusCode: response.statusCode,
        contentType: contentType,
        contentLength: contentLength != null ? int.tryParse(contentLength) : null,
      );
    } catch (e) {
      return SniffVerification(
        accessible: false,
        error: e.toString(),
      );
    }
  }

  /// 批量去重 + 排序
  static List<SniffCandidate> dedupeAndSort(List<SniffCandidate> candidates) {
    final map = <String, SniffCandidate>{};
    for (var c in candidates) {
      final key = c.url.split('?').first;
      if (!map.containsKey(key) || c.confidence.index > map[key]!.confidence.index) {
        map[key] = c;
      }
    }
    final list = map.values.toList();
    list.sort((a, b) => b.confidence.index.compareTo(a.confidence.index));
    return list;
  }
}

// ════════════════════════════════════════
//  辅助类型
// ════════════════════════════════════════

enum SniffConfidence { low, medium, high }

class SniffCandidate {
  final String url;
  final String? mimeType;
  final int? contentLength;
  final String? referer;
  final SniffConfidence confidence;
  final String reason;

  SniffCandidate({
    required this.url,
    this.mimeType,
    this.contentLength,
    this.referer,
    this.confidence = SniffConfidence.low,
    this.reason = '',
  });

  /// 转换为 SniffResult
  SniffResult toResult({String? pageTitle}) {
    return SniffResult.fromUrl(
      url: url,
      mimeType: mimeType,
      referer: referer,
      pageTitle: pageTitle,
    );
  }
}

class SniffVerification {
  final bool accessible;
  final int? statusCode;
  final String? contentType;
  final int? contentLength;
  final String? error;

  SniffVerification({
    required this.accessible,
    this.statusCode,
    this.contentType,
    this.contentLength,
    this.error,
  });
}
