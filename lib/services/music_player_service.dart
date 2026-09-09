/// 音乐播放服务 — 后台播放 + 歌词 + 播放队列
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../models/music_detail.dart';
import '../services/spider_service_v2.dart';
import '../models/video_source.dart';

class MusicPlayerService extends ChangeNotifier {
  final Player _player = Player();
  MusicTrack? _currentTrack;
  List<MusicTrack> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  List<LyricLine> _lyrics = [];
  int _currentLyricIndex = -1;
  RepeatMode _repeatMode = RepeatMode.all;
  bool _shuffle = false;
  String? _error;

  Player get player => _player;
  MusicTrack? get currentTrack => _currentTrack;
  List<MusicTrack> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  List<LyricLine> get lyrics => _lyrics;
  int get currentLyricIndex => _currentLyricIndex;
  RepeatMode get repeatMode => _repeatMode;
  bool get shuffle => _shuffle;
  String? get error => _error;
  bool get hasTrack => _currentTrack != null;
  bool get hasPrev => _currentIndex > 0 || _repeatMode == RepeatMode.all;
  bool get hasNext => _currentIndex < _playlist.length - 1 || _repeatMode == RepeatMode.all;

  MusicPlayerService() {
    _player.stream.playing.listen((p) {
      _isPlaying = p;
      notifyListeners();
    });
    _player.stream.position.listen((pos) {
      _position = pos;
      _updateLyricIndex();
      notifyListeners();
    });
    _player.stream.duration.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _player.stream.completed.listen((completed) {
      if (completed) next();
    });
  }

  void _updateLyricIndex() {
    if (_lyrics.isEmpty) return;
    for (int i = _lyrics.length - 1; i >= 0; i--) {
      if (_position >= _lyrics[i].time) {
        if (_currentLyricIndex != i) {
          _currentLyricIndex = i;
          notifyListeners();
        }
        return;
      }
    }
  }

  /// 播放单曲
  Future<void> play(VideoSource source, MusicTrack track) async {
    _isLoading = true;
    _error = null;
    _currentTrack = track;
    notifyListeners();

    try {
      final url = track.playUrl ?? await SpiderServiceV2.getMusicPlayUrl(source, track.id);
      if (url == null) {
        _error = '无法获取播放地址';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _player.open(Media(url));

      // 加载歌词
      final lyricStr = track.lyric ?? await SpiderServiceV2.getMusicLyric(source, track.id);
      if (lyricStr != null) {
        _lyrics = LyricLine.parse(lyricStr);
      } else {
        _lyrics = [];
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '播放失败: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 播放歌单/列表
  Future<void> playPlaylist(
    VideoSource source, List<MusicTrack> tracks, {int startIndex = 0}
  ) async {
    _playlist = List.from(tracks);
    _currentIndex = startIndex;
    if (_playlist.isNotEmpty) {
      await play(source, _playlist[_currentIndex]);
    }
  }

  /// 播放/暂停切换
  void playOrPause() => _player.playOrPause();

  void pause() => _player.pause();
  void resume() => _player.resume();

  /// 下一曲
  Future<void> next() async {
    if (_playlist.isEmpty) return;
    if (_shuffle) {
      _currentIndex = (DateTime.now().millisecondsSinceEpoch % _playlist.length);
    } else {
      _currentIndex++;
      if (_currentIndex >= _playlist.length) {
        if (_repeatMode == RepeatMode.all) {
          _currentIndex = 0;
        } else {
          _currentIndex = _playlist.length - 1;
          return;
        }
      }
    }
    notifyListeners();
    // 需要 source 引用，这里用当前 track 的 sourceKey
    // 实际使用中由 Provider 传入
  }

  /// 上一曲
  Future<void> prev() async {
    if (_playlist.isEmpty) return;
    _currentIndex--;
    if (_currentIndex < 0) {
      _currentIndex = _repeatMode == RepeatMode.all ? _playlist.length - 1 : 0;
    }
    notifyListeners();
  }

  /// 跳到指定位置
  void seek(Duration position) => _player.seek(position);

  /// 跳到指定进度百分比
  void seekPercent(double percent) {
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * percent).toInt(),
    );
    _player.seek(target);
  }

  /// 切换循环模式
  void toggleRepeat() {
    switch (_repeatMode) {
      case RepeatMode.none:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.none;
    }
    _player.setRepeatMode(_repeatMode == RepeatMode.one
        ? RepeatMode.single
        : _repeatMode == RepeatMode.all
            ? RepeatMode.playlist
            : RepeatMode.none);
    notifyListeners();
  }

  /// 切换随机播放
  void toggleShuffle() {
    _shuffle = !_shuffle;
    notifyListeners();
  }

  /// 格式化时间
  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

enum RepeatMode { none, all, one }
