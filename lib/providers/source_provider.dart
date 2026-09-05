/// 全局状态管理 v2 — 统一管理所有媒体源
import 'package:flutter/material.dart';
import '../models/video_source.dart';
import '../models/unified_content.dart';
import '../services/spider_service_v2.dart';
import '../services/app_config.dart';

class SourceProvider extends ChangeNotifier {
  List<VideoSource> _sources = [];
  VideoSource? _activeSource;
  bool _isLoading = false;
  String? _error;

  List<VideoSource> get sources => _sources;
  VideoSource? get activeSource => _activeSource;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 按类型获取源列表
  List<VideoSource> sourcesByType(String type) =>
      _sources.where((s) => s.mediaType == type && s.isActive).toList();

  /// 视频源
  List<VideoSource> get videoSources => sourcesByType('video');
  /// 漫画源
  List<VideoSource> get comicSources => sourcesByType('comic');
  /// 小说源
  List<VideoSource> get novelSources => sourcesByType('novel');
  /// 音乐源
  List<VideoSource> get musicSources => sourcesByType('music');
  /// 直播源
  List<VideoSource> get liveSources => _sources.where((s) => s.type == 4 && s.isActive).toList();

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _sources = await AppConfig.getSources();
    final activeKey = await AppConfig.getActiveSourceKey();
    if (activeKey != null) {
      _activeSource = _sources.firstWhere(
        (s) => s.key == activeKey, orElse: () => _sources.isNotEmpty ? _sources.first : _sources);
    } else if (_sources.isNotEmpty) {
      _activeSource = _sources.first;
    }

    // 尝试在线刷新
    try {
      final configUrl = await AppConfig.getConfigUrl();
      final remoteSources = await SpiderServiceV2.getSources(configUrl);
      if (remoteSources.isNotEmpty) {
        _sources = _mergeSources(_sources, remoteSources);
        await AppConfig.saveSources(_sources);
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setActiveSource(VideoSource source) {
    _activeSource = source;
    AppConfig.setActiveSource(source.key);
    notifyListeners();
  }

  Future<void> addSource(VideoSource source) async {
    _sources.add(source);
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  Future<void> removeSource(String key) async {
    _sources.removeWhere((s) => s.key == key);
    await AppConfig.saveSources(_sources);
    if (_activeSource?.key == key && _sources.isNotEmpty) {
      _activeSource = _sources.first;
    }
    notifyListeners();
  }

  /// 批量添加源
  Future<void> addSources(List<VideoSource> newSources) async {
    _sources = _mergeSources(_sources, newSources);
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  /// 聚合搜索 (跨所有类型)
  Future<AggregatedSearchResult> searchAll(String query, {MediaType? filterType}) async {
    return SpiderServiceV2.searchAll(_sources, query, filterType: filterType);
  }

  /// 获取视频分类
  Future<List<VideoContent>> getCategory(String? typeId, {int page = 1}) async {
    if (_activeSource == null || _activeSource!.mediaType != 'video') return [];
    final items = await SpiderServiceV2.getCategoryVideo(
      _activeSource!, typeId: typeId, page: page);
    return items;
  }

  /// 获取直播频道
  Future<List<Map<String, String>>> getLiveChannels(String url) async {
    return SpiderServiceV2.getLiveChannels(url);
  }

  /// 刷新在线配置
  Future<void> refreshFromConfig(String configUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final remoteSources = await SpiderServiceV2.getSources(configUrl);
      if (remoteSources.isNotEmpty) {
        _sources = _mergeSources(_sources, remoteSources);
        await AppConfig.saveSources(_sources);
        await AppConfig.setConfigUrl(configUrl);
      } else {
        _error = '配置文件中未找到有效源';
      }
    } catch (e) { _error = '刷新失败: $e'; }
    _isLoading = false;
    notifyListeners();
  }

  List<VideoSource> _mergeSources(List<VideoSource> local, List<VideoSource> remote) {
    final map = <String, VideoSource>{};
    for (var s in local) map[s.key] = s;
    for (var s in remote) map[s.key] = s;
    return map.values.toList();
  }
}
