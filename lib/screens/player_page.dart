import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/content.dart';
import '../services/app_config.dart';

class PlayerPage extends StatefulWidget {
  final MediaItem item;
  final MediaEpisode episode;
  const PlayerPage({super.key, required this.item, required this.episode});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _controller;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    AppConfig.addHistory(widget.item);
    _open();
  }

  Future<void> _open() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.episode.url));
      await controller.initialize();
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = '无法播放此地址，请检查源接口或播放链接。';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.item.title),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white)))
              : controller == null
                  ? const SizedBox.shrink()
                  : Center(child: AspectRatio(
                      aspectRatio: controller.value.aspectRatio,
                      child: Stack(children: [
                        VideoPlayer(controller),
                        _controls(controller),
                      ])),
    );
  }

  Widget _controls(VideoPlayerController controller) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Column(children: [
          VideoProgressIndicator(
            controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(playedColor: Colors.blue),
          ),
          Row(children: [
            IconButton(
              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white),
              onPressed: () {
                if (controller.value.isPlaying) {
                  controller.pause();
                } else {
                  controller.play();
                }
                setState(() {});
              },
            ),
            Text(_format(controller.value.position), style: const TextStyle(color: Colors.white, fontSize: 12)),
            const Text(' / ', style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text(_format(controller.value.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${value.inHours > 0 ? '${value.inHours.toString().padLeft(2, '0')}:' : ''}$minutes:$seconds';
  }
}
