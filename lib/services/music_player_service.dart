/// 音乐播放服务 — 简化版 (无 media_kit 依赖)
import 'package:flutter/material.dart';

class MusicPlayerService extends ChangeNotifier {
  MusicTrack? _currentTrack;
  List<MusicTrack> _playlist = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  MusicTrack? get currentTrack => _currentTrack;
  List<MusicTrack> get playlist => _playlist;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get hasTrack => _currentTrack != null;

  void playOrPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void next() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex + 1) % _playlist.length;
    _currentTrack = _playlist[_currentIndex];
    _isPlaying = true;
    notifyListeners();
  }

  void prev() {
    if (_playlist.isEmpty) return;
    _currentIndex = (_currentIndex - 1 + _playlist.length) % _playlist.length;
    _currentTrack = _playlist[_currentIndex];
    _isPlaying = true;
    notifyListeners();
  }

  void seek(Duration position) {
    _position = position;
    notifyListeners();
  }

  static String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class MusicTrack {
  final String id;
  final String name;
  final String author;
  final String cover;
  final String? album;
  final String? playUrl;
  final int duration;

  MusicTrack({
    required this.id,
    required this.name,
    this.author = '',
    this.cover = '',
    this.album,
    this.playUrl,
    this.duration = 0,
  });
}

enum RepeatMode { none, all, one }
