import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/app_config.dart';
import '../models/video_source.dart';
import '../models/video_content.dart';
import '../models/unified_content.dart';
import '../services/spider_service_v2.dart';

/// 源数据提供程序
class SourceProvider extends ChangeNotifier {
  late List<VideoSource> _sources;
  VideoSource? _activeSource;
  bool _loading = false;
  String? _error;

  List<VideoSource> get sources => _sources;
  VideoSource? get activeSource => _activeSource;
  bool get isLoading => _loading;
  String? get error => _error;

  /// 漫画源
  List<VideoSource> get comicSources =>
      _sources.where((s) => s.mediaType == 'comic').toList();
  /// 小说源
  List<VideoSource> get novelSources =>
      _sources.where((s) => s.mediaType == 'novel').toList();
  /// 音乐源
  List<VideoSource> get musicSources =>
      _sources.where((s) => s.mediaType == 'music').toList();
  /// 视频源
  List<VideoSource> get videoSources =>
      _sources.where((s) => s.mediaType == 'video').toList();

  SourceProvider() {
    _init();
  }

  /// 公开初始化方法（供 main.dart 调用）
  Future<void> init() => _init();

  Future<void> _init() async {
    _loading = true;
    _error = null;
    notifyListeners();

    _sources = await AppConfig.getSources();
    final activeKey = await AppConfig.getActiveSourceKey();
    if (activeKey != null) {
      _activeSource = _sources.firstWhere(
        (s) => s.key == activeKey,
        orElse: () => _sources.first,
      );
    } else if (_sources.isNotEmpty) {
      _activeSource = _sources.first;
    }

    // 尝试在线刷新
    try {
      final configUrl = await AppConfig.getConfigUrl();
      if (configUrl != null && configUrl.isNotEmpty) {
        await loadFromUrl(configUrl);
      }
    } catch (e) {
      debugPrint('SourceProvider init error: $e');
    }

    _loading = false;
    notifyListeners();
  }

  /// 从 URL 加载源
  Future<void> loadFromUrl(String url) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final remote = await SpiderServiceV2.getSources(url);
      if (remote != null && remote.isNotEmpty) {
        await addSources(remote);
      }
    } catch (e) {
      _error = '加载配置失败: $e';
      debugPrint('SourceProvider loadFromUrl error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 获取视频分类
  Future<List<VideoContent>> getCategory(String? typeId, {int page = 1}) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return [];
    final items = await SpiderServiceV2.getCategoryVideo(
      _activeSource!, typeId: typeId, page: page);
    return items.map((e) => e.toVideoContent()).toList();
  }

  /// 获取直播频道
  Future<List<Map<String, String>>> getLiveChannels(String url) async {
    return SpiderServiceV2.getLiveChannels(url);
  }

  /// 获取视频详情
  Future<VideoContent?> getDetail(String id) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return null;
    final detail = await SpiderServiceV2.getVideoDetail(_activeSource!, id);
    if (detail == null) return null;
    // Convert Map to VideoContent
    return VideoContent.fromJson(detail, sourceKey: _activeSource!.key);
  }

  /// 获取播放链接
  Future<String?> getPlayUrl(String id, {String? from, String? server}) async {
    if (_activeSource == null) return null;
    return SpiderServiceV2.parseVideoPlayUrl(_activeSource!, id);
  }

  /// 搜索
  Future<AggregatedSearchResult> searchAll(String keyword, {int page = 1}) async {
    return SpiderServiceV2.searchAll(_sources, keyword, page: page);
  }

  /// 刷新
  Future<void> refresh() => _init();

  // ── 源管理方法 ──

  /// 批量添加源
  Future<void> addSources(List<VideoSource> sources) async {
    _sources.addAll(sources);
    await AppConfig.saveSources(_sources);
    if (_activeSource == null && _sources.isNotEmpty) {
      _activeSource = _sources.first;
    }
    notifyListeners();
  }

  /// 添加单个源
  Future<void> addSource(VideoSource source) async {
    await addSources([source]);
  }

  /// 移除源
  Future<void> removeSource(String key) async {
    _sources.removeWhere((s) => s.key == key);
    if (_activeSource?.key == key) {
      _activeSource = _sources.isNotEmpty ? _sources.first : null;
    }
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  /// 设置活动源
  void setActiveSource(VideoSource source) {
    _activeSource = source;
    AppConfig.setActiveSource(source.key);
    notifyListeners();
  }

  /// 从配置 URL 刷新
  Future<void> refreshFromConfig(String url) async {
    await loadFromUrl(url);
  }
}