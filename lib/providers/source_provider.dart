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
  bool _isLoading = false;
  String? _error;

  SourceProvider() : _sources = [] {
    _init();
  }

  List<VideoSource> get sources => _sources;
  VideoSource? get activeSource => _activeSource;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<VideoSource> get videoSources =>
      _sources.where((s) => s.mediaType == 'video').toList();
  List<VideoSource> get comicSources =>
      _sources.where((s) => s.mediaType == 'comic').toList();
  List<VideoSource> get novelSources =>
      _sources.where((s) => s.mediaType == 'novel').toList();
  List<VideoSource> get musicSources =>
      _sources.where((s) => s.mediaType == 'music').toList();

  Future<void> _init() async {
    _loading = true;
    notifyListeners();
    try {
      _sources = await AppConfig.getSources();
      final activeKey = await AppConfig.getActiveSourceKey();
      if (activeKey != null) {
        _activeSource = _sources.firstWhere(
          (s) => s.key == activeKey, orElse: () => _sources.first);
      } else if (_sources.isNotEmpty) {
        _activeSource = _sources.first;
      }

      // 尝试在线刷新
      try {
        final configUrl = await AppConfig.getConfigUrl();
        if (configUrl != null && configUrl.isNotEmpty) {
          final onlineSources = await SpiderServiceV2.getSources(configUrl);
          if (onlineSources.isNotEmpty) {
            _sources = onlineSources;
            if (activeKey != null) {
              _activeSource = _sources.firstWhere(
                (s) => s.key == activeKey, orElse: () => _sources.first);
            }
            AppConfig.saveSources(_sources);
          }
        }
      } catch (_) {}

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 从 URL 加载配置
  Future<void> loadFromUrl(String url) async {
    _loading = true;
    notifyListeners();
    try {
      final sources = await SpiderServiceV2.getSources(url);
      if (sources.isNotEmpty) {
        _sources = sources;
        _activeSource = _sources.first;
        AppConfig.saveSources(sources);
        AppConfig.saveConfigUrl(url);
        _error = null;
      } else {
        _error = '未找到可用源';
      }
    } catch (e) {
      _error = '加载失败: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// 选择源
  void selectSource(VideoSource source) {
    _activeSource = source;
    AppConfig.saveActiveSourceKey(source.key);
    notifyListeners();
  }

  /// 获取视频分类
  Future<List<VideoContent>> getCategory(String? typeId, {int page = 1}) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return [];
    final items = await SpiderServiceV2.getCategoryVideo(
      _activeSource!, typeId: typeId, page: page);
    return items.map((e) => e.toVideoContent()).toList();
  }

  /// 获取视频详情
  Future<VideoContent?> getDetail(String id) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return null;
    final json = await SpiderServiceV2.getVideoDetail(_activeSource!, id);
    if (json == null) return null;
    return VideoContent.fromJson(json, sourceKey: _activeSource!.key);
  }

  /// 获取直播频道
  Future<List<Map<String, String>>> getLiveChannels(String url) async {
    return SpiderServiceV2.getLiveChannels(url);
  }

  /// 聚合搜索
  Future<AggregatedSearchResult> searchAll(String query) async {
    return SpiderServiceV2.searchAll(_sources, query);
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
    AppConfig.saveActiveSourceKey(source.key);
    notifyListeners();
  }

  /// 从配置 URL 刷新
  Future<void> refreshFromConfig(String url) async {
    await loadFromUrl(url);
  }

  bool _loading = false;
}
