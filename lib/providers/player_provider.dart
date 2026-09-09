/// 播放器状态管理
import 'package:flutter/material.dart';
import '../models/video_content.dart';
import '../models/video_source.dart';
import '../services/spider_service.dart';
import '../services/app_config.dart';

class PlayerProvider extends ChangeNotifier {
  VideoContent? _currentVideo;
  VideoEpisode? _currentEpisode;
  VideoSource? _currentSource;
  String? _playUrl;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _position = 0;
  double _duration = 0;
  String? _error;

  VideoContent? get currentVideo => _currentVideo;
  VideoEpisode? get currentEpisode => _currentEpisode;
  VideoSource? get currentSource => _currentSource;
  String? get playUrl => _playUrl;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  double get position => _position;
  double get duration => _duration;
  String? get error => _error;

  /// 加载并播放某个视频的某一集
  Future<void> loadAndPlay(
    VideoContent video,
    VideoEpisode episode,
    VideoSource source,
  ) async {
    _currentVideo = video;
    _currentEpisode = episode;
    _currentSource = source;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 解析真实播放地址
      final url = await SpiderService.parsePlayUrl(source, episode.url);
      if (url != null) {
        _playUrl = url;
        _isPlaying = true;
        
        // 保存历史记录
        await AppConfig.addHistory({
          'id': video.id,
          'name': video.name,
          'pic': video.pic,
          'sourceKey': source.key,
          'episodeName': episode.name,
          'episodeUrl': episode.url,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      } else {
        _error = '无法解析播放地址';
      }
    } catch (e) {
      _error = '播放失败: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 切集
  Future<void> switchEpisode(
    VideoEpisode episode,
    VideoSource source,
  ) async {
    if (_currentVideo != null) {
      await loadAndPlay(_currentVideo!, episode, source);
    }
  }

  void updatePosition(double position) {
    _position = position;
    notifyListeners();
  }

  void updateDuration(double duration) {
    _duration = duration;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void stop() {
    _playUrl = null;
    _isPlaying = false;
    _currentEpisode = null;
    _position = 0;
    _duration = 0;
    notifyListeners();
  }
}
