import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/content.dart';
import 'source_service.dart';

/// Eso-style audio service: queue, repeat modes, seek and synchronized LRC lyrics.
class MusicPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final SourceService _sourceService = const SourceService();
  final List<MediaItem> _queue = <MediaItem>[];
  final List<LyricLine> _lyrics = <LyricLine>[];

  MediaItem? _current;
  int _index = -1;
  PlayerState _state = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  RepeatMode _repeatMode = RepeatMode.all;
  int _lyricIndex = -1;
  String? _error;

  MusicPlayerService() {
    _player.onPlayerStateChanged.listen((value) {
      _state = value;
      notifyListeners();
    });
    _player.onPositionChanged.listen((value) {
      _position = value;
      _updateLyricIndex();
      notifyListeners();
    });
    _player.onDurationChanged.listen((value) {
      _duration = value;
      notifyListeners();
    });
    _player.onPlayerComplete.listen((_) => _completeCurrent());
  }

  List<MediaItem> get queue => List.unmodifiable(_queue);
  MediaItem? get current => _current;
  int get index => _index;
  PlayerState get state => _state;
  bool get playing => _state == PlayerState.playing;
  Duration get position => _position;
  Duration get duration => _duration;
  List<LyricLine> get lyrics => List.unmodifiable(_lyrics);
  int get lyricIndex => _lyricIndex;
  RepeatMode get repeatMode => _repeatMode;
  String? get error => _error;

  Future<void> playQueue(
    List<MediaItem> items, {
    int startIndex = 0,
    SourceDefinition? source,
  }) async {
    _queue
      ..clear()
      ..addAll(items.where((item) => item.type == ContentType.music));
    if (_queue.isEmpty) return;
    _index = startIndex.clamp(0, _queue.length - 1).toInt();
    await playCurrent(source: source);
  }

  Future<void> playCurrent({SourceDefinition? source}) async {
    if (_index < 0 || _index >= _queue.length) return;
    final item = _queue[_index];
    _current = item;
    _error = null;
    _lyrics
      ..clear()
      ..addAll(LyricLine.parse(item.lyrics ?? ''));
    _lyricIndex = -1;
    notifyListeners();

    try {
      final url = await _sourceService.resolveMusicUrl(source, item);
      if (url == null || url.isEmpty) {
        throw StateError('当前歌曲没有可播放地址');
      }
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (error) {
      _error = '$error';
      _state = PlayerState.stopped;
      notifyListeners();
    }
  }

  Future<void> toggle() async {
    if (playing) {
      await _player.pause();
    } else if (_current != null) {
      await _player.resume();
    }
  }

  Future<void> next({SourceDefinition? source}) async {
    if (_queue.isEmpty) return;
    if (_index + 1 >= _queue.length) {
      if (_repeatMode == RepeatMode.none) return;
      _index = 0;
    } else {
      _index++;
    }
    await playCurrent(source: source);
  }

  Future<void> previous({SourceDefinition? source}) async {
    if (_queue.isEmpty) return;
    _index = _index <= 0 ? _queue.length - 1 : _index - 1;
    await playCurrent(source: source);
  }

  Future<void> seek(Duration value) => _player.seek(value);

  void setRepeatMode(RepeatMode value) {
    _repeatMode = value;
    notifyListeners();
  }

  void _completeCurrent() async {
    if (_repeatMode == RepeatMode.one) {
      await _player.seek(Duration.zero);
      await _player.resume();
      return;
    }
    await next();
  }

  void _updateLyricIndex() {
    if (_lyrics.isEmpty) return;
    var found = -1;
    for (var i = 0; i < _lyrics.length; i++) {
      if (_position >= _lyrics[i].start && _position <= _lyrics[i].end) {
        found = i;
        break;
      }
    }
    if (found != _lyricIndex) _lyricIndex = found;
  }

  static String format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return value.inHours > 0
        ? '${value.inHours.toString().padLeft(2, '0')}:$minutes:$seconds'
        : '$minutes:$seconds';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

enum RepeatMode { none, all, one }

class LyricLine {
  final Duration start;
  final Duration end;
  final String text;

  const LyricLine({required this.start, required this.end, required this.text});

  static List<LyricLine> parse(String value) {
    final result = <LyricLine>[];
    final pattern = RegExp(r'\[(\d{1,2}):(\d{1,2})(?:\.(\d{1,3}))?\](.*)');
    for (final line in value.split('\n')) {
      final match = pattern.firstMatch(line.trim());
      if (match == null) continue;
      final minutes = int.tryParse(match.group(1)!) ?? 0;
      final seconds = int.tryParse(match.group(2)!) ?? 0;
      final fraction = (match.group(3) ?? '0').padRight(3, '0');
      final milliseconds = int.tryParse(fraction) ?? 0;
      result.add(LyricLine(
        start: Duration(minutes: minutes, seconds: seconds, milliseconds: milliseconds),
        end: Duration.zero,
        text: (match.group(4) ?? '').trim(),
      ));
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return [
      for (var i = 0; i < result.length; i++)
        LyricLine(
          start: result[i].start,
          end: i + 1 < result.length
              ? result[i + 1].start
              : result[i].start + const Duration(seconds: 10),
          text: result[i].text,
        ),
    ];
  }
}
