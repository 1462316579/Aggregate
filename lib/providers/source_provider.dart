/// 源管理状态
import 'package:flutter/material.dart';
import '../models/video_source.dart';
import '../models/video_content.dart';
import '../services/app_config.dart';
import '../services/spider_service.dart';

class SourceProvider extends ChangeNotifier {
  List<VideoSource> _sources = [];
  VideoSource? _activeSource;
  bool _isLoading = false;

  List<VideoSource> get sources => _sources;
  VideoSource? get activeSource => _activeSource;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    _sources = await AppConfig.getSources();
    final key = await AppConfig.getActiveSourceKey();
    _activeSource = _sources.firstWhere(
      (s) => s.key == key, orElse: () => _sources.isNotEmpty ? _sources.first : _sources.first,
    );
    notifyListeners();
  }

  void setActiveSource(VideoSource source) {
    _activeSource = source;
    AppConfig.setActiveSource(source.key);
    notifyListeners();
  }

  Future<List<VideoContent>> getCategory({String? typeId, int page = 1}) async {
    if (_activeSource == null) return [];
    return await SpiderService.getCategory(_activeSource!, typeId: typeId, page: page);
  }

  Future<VideoContent?> getDetail(String id) async {
    if (_activeSource == null) return null;
    return await SpiderService.getDetail(_activeSource!, id);
  }

  Future<List<VideoContent>> search(String query) async {
    if (_activeSource == null) return [];
    return await SpiderService.search(_activeSource!, query);
  }
}
