/// 视频播放器 — 支持手势操作
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/spider_service.dart';
import '../../models/video_source.dart';

class PlayerScreen extends StatefulWidget {
  final String title;
  final String url;
  const PlayerScreen({super.key, required this.title, required this.url});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isPlaying = false;
  bool _showControls = true;
  String _status = '加载中...';
  Duration _position = Duration.zero;
  Duration _duration = const Duration(minutes: 45);
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _parseUrl();
  }

  Future<void> _parseUrl() async {
    final source = VideoSource(key: '', name: '', api: '');
    final url = await SpiderService.parsePlayUrl(source, widget.url);
    setState(() { _status = url != null ? '准备播放' : '解析失败'; _isPlaying = url != null; });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(children: [
          const Center(child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 80)),
          if (_showControls) ...[_buildTopBar(), const Spacer(), _buildCenterControls(), const Spacer(), _buildBottomBar()],
          if (!_showControls)
            Center(child: Text(_status, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ]),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent])),
        child: Row(children: [
          IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          Expanded(child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)),
          PopupMenuButton<double>(
            icon: Text('${_speed}x', style: const TextStyle(color: Colors.white, fontSize: 14)),
            onSelected: (s) => setState(() => _speed = s),
            itemBuilder: (_) => [0.5, 1.0, 1.5, 2.0].map((s) =>
              PopupMenuItem(value: s, child: Text('${s}x'))).toList()),
        ]),
      )),
    );
  }

  Widget _buildCenterControls() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(icon: const Icon(Icons.replay_10, color: Colors.white, size: 40), onPressed: () {}),
      const SizedBox(width: 32),
      IconButton(
        icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 64),
        onPressed: () => setState(() => _isPlaying = !_isPlaying)),
      const SizedBox(width: 32),
      IconButton(icon: const Icon(Icons.forward_10, color: Colors.white, size: 40), onPressed: () {}),
    ]);
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: const BoxDecoration(gradient: LinearGradient(
          begin: Alignment.bottomCenter, end: Alignment.topCenter,
          colors: [Colors.black54, Colors.transparent])),
        child: Column(children: [
          SliderTheme(
            data: SliderThemeData(thumbColor: const Color(0xFF2196F3), activeTrackColor: const Color(0xFF2196F3),
                inactiveTrackColor: Colors.white24, trackHeight: 2),
            child: Slider(value: 0, max: 1, onChanged: (_) {})),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('00:00', style: TextStyle(color: Colors.white, fontSize: 12)),
            Text('45:00', style: TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }
}
