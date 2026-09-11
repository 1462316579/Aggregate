import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/app_config.dart';
import '../models/video_source.dart';
import '../models/video_content.dart';
import '../models/unified_content.dart';
import '../services/spider_service_v2.dart';

class SourceProvider extends ChangeNotifier {
  late List<VideoSource> _sources;
  VideoSource? _activeSource;
  bool _loading = false;
  String? _error;

  List<VideoSource> get sources => _sources;
  VideoSource? get activeSource => _activeSource;
  bool get isLoading => _loading;
  String? get error => _error;

  List<VideoSource> get comicSources => _sources.where((s) => s.mediaType == 'comic').toList();
  List<VideoSource> get novelSources => _sources.where((s) => s.mediaType == 'novel').toList();
  List<VideoSource> get musicSources => _sources.where((s) => s.mediaType == 'music').toList();
  List<VideoSource> get videoSources => _sources.where((s) => s.mediaType == 'video').toList();

  SourceProvider() { _init(); }

  Future<void> init() => _init();

  Future<void> _init() async {
    _loading = true;
    _error = null;
    notifyListeners();
    _sources = await AppConfig.getSources();
    final activeKey = await AppConfig.getActiveSourceKey();
    if (activeKey != null) {
      _activeSource = _sources.firstWhere((s) => s.key == activeKey, orElse: () => _sources.first);
    } else if (_sources.isNotEmpty) {
      _activeSource = _sources.first;
    }
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

  Future<List<VideoContent>> getCategory(String? typeId, {int page = 1}) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return [];
    final items = await SpiderServiceV2.getCategoryVideo(_activeSource!, typeId: typeId, page: page);
    return items.map((e) => e.toVideoContent()).toList();
  }

  Future<List<Map<String, String>>> getLiveChannels(String url) async {
    return SpiderServiceV2.getLiveChannels(url);
  }

  Future<VideoContent?> getDetail(String id) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return null;
    final detail = await SpiderServiceV2.getVideoDetail(_activeSource!, id);
    if (detail == null) return null;
    return VideoContent.fromJson(detail, sourceKey: _activeSource!.key);
  }

  Future<String?> getPlayUrl(String id, {String? from, String? server}) async {
    if (_activeSource == null) return null;
    return SpiderServiceV2.parseVideoPlayUrl(_activeSource!, id);
  }

  Future<AggregatedSearchResult> searchAll(String keyword) async {
    return SpiderServiceV2.searchAll(_sources, keyword);
  }

  Future<void> refresh() => _init();

  Future<void> addSources(List<VideoSource> sources) async {
    _sources.addAll(sources);
    await AppConfig.saveSources(_sources);
    if (_activeSource == null && _sources.isNotEmpty) {
      _activeSource = _sources.first;
    }
    notifyListeners();
  }

  Future<void> addSource(VideoSource source) async {
    await addSources([source]);
  }

  Future<void> removeSource(String key) async {
    _sources.removeWhere((s) => s.key == key);
    if (_activeSource?.key == key) {
      _activeSource = _sources.isNotEmpty ? _sources.first : null;
    }
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  void setActiveSource(VideoSource source) {
    _activeSource = source;
    AppConfig.setActiveSource(source.key);
    notifyListeners();
  }

  Future<void> refreshFromConfig(String url) async {
    await loadFromUrl(url);
  }

  /// 获取指定源
  VideoSource? sourceFor(String? key) {
    if (key == null) return null;
    try {
      return _sources.firstWhere((s) => s.key == key);
    } catch (_) {
      return null;
    }
  }

  /// 获取小说章节内容
  Future<String> chapterContent(String sourceId, String url) async {
    final source = sourceFor(sourceId);
    if (source == null) return '';
    return await SpiderServiceV2.getNovelChapterContent(source, url) ?? '';
  }

  /// 获取漫画章节图片
  Future<List<String>> chapterImages(String sourceId, String url) async {
    final source = sourceFor(sourceId);
    if (source == null) return [];
    return await SpiderServiceV2.getComicChapterImages(source, url);
  }
}
