/// 播放器 v2 — 整合所有平台特性
/// TV遥控器 / 手势 / 键盘 / 投屏 / 跳过片头片尾
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../providers/player_provider.dart';
import '../../models/video_content.dart';
import '../../models/video_source.dart';
import '../../services/spider_service.dart';
import '../../services/cast_service.dart';
import '../../utils/tv_remote_handler.dart';
import '../../utils/keyboard_shortcuts.dart';
import '../../utils/player_gesture_detector.dart';
import '../../utils/skip_intro_outro.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  final bool isLive;
  final List<VideoEpisode>? episodes;
  final VideoEpisode? currentEpisode;
  final VideoSource? source;

  const PlayerScreen({
    super.key,
    required this.title,
    required this.url,
    this.isLive = false,
    this.episodes,
    this.currentEpisode,
    this.source,
  });

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  late final CastService _castService;
  bool _isLoading = true;
  bool _showControls = true;
  String? _error;
  VideoEpisode? _currentEpisode;
  double _speed = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  // 跳过片头片尾
  Duration? _introEnd;
  Duration? _outroStart;
  bool _introSettingEnabled = true;

  @override
  void initState() {
    super.initState();
    _player = Player();
    _controller = VideoController(_player);
    _castService = CastService();
    _currentEpisode = widget.currentEpisode;

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initPlayer();
    _listenPlayer();
  }

  void _listenPlayer() {
    _player.stream.playing.listen((p) { if (mounted) setState(() => _isPlaying = p); });
    _player.stream.position.listen((p) { if (mounted) setState(() => _position = p); });
    _player.stream.duration.listen((d) { if (mounted) setState(() => _duration = d); });
    _player.stream.completed.listen((c) {
      if (c && mounted && !widget.isLive) _playNextEpisode();
    });
  }

  Future<void> _initPlayer() async {
    try {
      final realUrl = await SpiderService.parsePlayUrl(
          widget.source ?? VideoSource(key: '', name: '', api: ''), widget.url);
      if (realUrl != null) {
        await _player.open(Media(realUrl));
        setState(() => _isLoading = false);
        // 投屏同步
        if (_castService.isCasting) _castService.startCast(realUrl);
      } else {
        setState(() { _error = '无法解析播放地址'; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = '播放出错: $e'; _isLoading = false; });
    }
  }

  void _playNextEpisode() {
    if (widget.episodes == null || _currentEpisode == null || widget.source == null) return;
    final idx = widget.episodes!.indexOf(_currentEpisode!);
    if (idx < widget.episodes!.length - 1) {
      _switchEpisode(widget.episodes![idx + 1]);
    }
  }

  Future<void> _switchEpisode(VideoEpisode episode) async {
    setState(() { _isLoading = true; _currentEpisode = episode; _error = null; });
    try {
      await _player.stop();
      final url = await SpiderService.parsePlayUrl(widget.source!, episode.url);
      if (url != null) await _player.open(Media(url));
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = '播放出错: $e'; _isLoading = false; });
    }
  }

  void _togglePlayPause() {
    _player.playOrPause();
    if (_castService.isCasting) {
      _isPlaying ? _castService.pauseCast() : _castService.resumeCast();
    }
  }

  void _seek(Duration offset) {
    final newPos = _position + offset;
    _player.seek(newPos);
    if (_castService.isCasting) _castService.seekCast(newPos);
  }

  void _seekTo(Duration pos) {
    _player.seek(pos);
    if (_castService.isCasting) _castService.seekCast(pos);
  }

  void _handleTvAction(TvAction action) {
    switch (action) {
      case TvAction.center:
      case TvAction.playPause: _togglePlayPause(); break;
      case TvAction.left: _seek(const Duration(seconds: -10)); break;
      case TvAction.right: _seek(const Duration(seconds: 10)); break;
      case TvAction.up: _seek(const Duration(seconds: -60)); break;
      case TvAction.down: _seek(const Duration(seconds: 60)); break;
      case TvAction.back: Navigator.pop(context); break;
      case TvAction.fastForward: _seek(const Duration(seconds: 30)); break;
      case TvAction.rewind: _seek(const Duration(seconds: -30)); break;
      default: break;
    }
  }

  void _handleKeyboardAction(KeyboardAction action) {
    switch (action) {
      case KeyboardAction.playPause: _togglePlayPause(); break;
      case KeyboardAction.seekForward10: _seek(const Duration(seconds: 10)); break;
      case KeyboardAction.seekBackward10: _seek(const Duration(seconds: -10)); break;
      case KeyboardAction.seekForward30: _seek(const Duration(seconds: 30)); break;
      case KeyboardAction.seekBackward30: _seek(const Duration(seconds: -30)); break;
      case KeyboardAction.nextEpisode: _playNextEpisode(); break;
      case KeyboardAction.prevEpisode:
        final idx = widget.episodes?.indexOf(_currentEpisode!) ?? 0;
        if (idx > 0) _switchEpisode(widget.episodes![idx - 1]);
        break;
      case KeyboardAction.speedUp: _changeSpeed(0.25); break;
      case KeyboardAction.speedDown: _changeSpeed(-0.25); break;
      case KeyboardAction.escape: Navigator.pop(context); break;
      default: break;
    }
  }

  void _changeSpeed(double delta) {
    _speed = (_speed + delta).clamp(0.5, 3.0);
    _player.setPlaybackRate(_speed);
  }

  @override
  void dispose() {
    _player.dispose();
    _castService.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 960;
    final isMobile = !isTV && !Platform.isWindows && !Platform.isMacOS && !Platform.isLinux;

    Widget playerBody = Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 视频画面
          Center(
            child: _error != null
                ? _buildError()
                : Video(controller: _controller, controls: NoVideoControls),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.white)),

          // 手势层 (移动端)
          if (isMobile)
            PlayerGestureDetector(
              onDoubleTapPause: _togglePlayPause,
              onLongPressSeek: (delta) => _seek(Duration(milliseconds: (delta * 1000).toInt())),
              onHorizontalDragSeek: (delta) => _seek(Duration(milliseconds: (delta * 1000).toInt())),
              onSingleTap: () => setState(() => _showControls = !_showControls),
              child: const SizedBox.expand(),
            ),

          // 控制层
          if (_showControls) ...[
            _buildTopBar(),
            const Spacer(),
            _buildCenterControls(),
            const Spacer(),
            _buildBottomBar(),
          ],

          // 选集面板 (TV)
          if (_showControls && isTV && widget.episodes != null)
            Positioned(
              right: 0, top: 60, bottom: 60, width: 200,
              child: _buildEpisodePanel(),
            ),

          // 跳过片头片尾
          SkipIntroOutro(
            introEnd: _introEnd,
            outroStart: _outroStart,
            position: _position,
            duration: _duration,
            onSkipIntro: () => _seekTo(_introEnd!),
            onSkipOutro: _playNextEpisode,
            onSeekTo: _seekTo,
          ),
        ],
      ),
    );

    // TV 遥控器层
    if (isTV) {
      playerBody = TvRemoteHandler(
        onAction: _handleTvAction,
        child: playerBody,
      );
    }

    // 桌面键盘层
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      playerBody = KeyboardShortcutHandler(
        onAction: _handleKeyboardAction,
        child: playerBody,
      );
    }

    return playerBody;
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent])),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Text(widget.title, style: const TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
            // 投屏按钮
            if (!widget.isLive)
              IconButton(
                icon: Icon(
                  _castService.isCasting ? Icons.screen_share : Icons.screen_share_outlined,
                  color: _castService.isCasting ? Colors.green : Colors.white, size: 22),
                onPressed: _showCastSheet,
                tooltip: '投屏',
              ),
            // 倍速
            PopupMenuButton<double>(
              icon: Text('${_speed}x', style: const TextStyle(color: Colors.white, fontSize: 14)),
              onSelected: (s) { _speed = s; _player.setPlaybackRate(s); },
              itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                  .map((s) => PopupMenuItem(value: s, child: Text('${s}x',
                      style: TextStyle(color: s == _speed ? Colors.blue : null))))
                  .toList()),
            // 跳过设置
            IconButton(
              icon: const Icon(Icons.skip_next, color: Colors.white, size: 22),
              onPressed: _showSkipSettings,
              tooltip: '跳过片头片尾'),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 40),
          onPressed: () => _seek(const Duration(seconds: -10))),
        const SizedBox(width: 32),
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.white, size: 64),
          onPressed: _togglePlayPause),
        const SizedBox(width: 32),
        IconButton(
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 40),
          onPressed: () => _seek(const Duration(seconds: 10))),
      ],
    );
  }

  Widget _buildBottomBar() {
    final pos = _position;
    final dur = _duration;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent])),
      child: Column(
        children: [
          // 进度条
          SliderTheme(
            data: SliderThemeData(
              thumbColor: const Color(0xFF2196F3),
              activeTrackColor: const Color(0xFF2196F3),
              inactiveTrackColor: Colors.white24,
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6)),
            child: Slider(
              value: dur.inMilliseconds > 0
                  ? pos.inMilliseconds.toDouble().clamp(0.0, dur.inMilliseconds.toDouble())
                  : 0,
              max: dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1,
              onChanged: (v) => _seekTo(Duration(milliseconds: v.toInt())),
              onChangeStart: (_) => setState(() => _showControls = true),
            ),
          ),
          // 时间
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(pos), style: const TextStyle(color: Colors.white, fontSize: 12)),
              // 跳过片头/片尾快捷按钮
              if (_introEnd != null && pos < _introEnd!)
                GestureDetector(
                  onTap: () => _seekTo(_introEnd!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4)),
                    child: const Text('跳过片头', style: TextStyle(color: Colors.white, fontSize: 10)),
                  ),
                ),
              Text(_fmt(dur), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodePanel() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text('选集', style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: widget.episodes!.length,
              itemBuilder: (ctx, i) {
                final ep = widget.episodes![i];
                final isCurrent = ep == _currentEpisode;
                return TvFocusable(
                  onSelect: () => _switchEpisode(ep),
                  child: ListTile(
                    title: Text(ep.name, style: TextStyle(
                        color: isCurrent ? Colors.blue : Colors.white, fontSize: 13)),
                    dense: true,
                    selected: isCurrent,
                    selectedTileColor: Colors.blue.withOpacity(0.2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 16),
        Text(_error ?? '播放错误', style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () {
          setState(() { _error = null; _isLoading = true; });
          _initPlayer();
        }, child: const Text('重试')),
      ]),
    );
  }

  void _showCastSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: _castService,
        child: CastDeviceSheet(castService: _castService),
      ),
    );
  }

  void _showSkipSettings() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SkipSettingsDialog(
        currentIntroEnd: _introEnd,
        currentOutroStart: _outroStart,
        duration: _duration,
      ),
    );
    if (result is Map) {
      setState(() {
        _introEnd = result['introEnd'];
        _outroStart = result['outroStart'];
      });
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) return '${h.toString().padLeft(2,'0')}:${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }
}
