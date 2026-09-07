import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/content.dart';
import '../services/music_player_service.dart';
import '../services/source_service.dart';

/// Eso-style music screen: blurred/solid backdrop, cover, lyrics, queue controls.
class MusicPlayerPage extends StatefulWidget {
  final MediaItem item;
  final SourceDefinition? source;
  final List<MediaItem> queue;
  final int initialIndex;

  const MusicPlayerPage({
    super.key,
    required this.item,
    this.source,
    this.queue = const <MediaItem>[],
    this.initialIndex = 0,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late final MusicPlayerService _audio;
  late final PageController _lyricController;
  bool _showLyrics = true;
  bool _showQueue = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _audio = MusicPlayerService();
    _lyricController = PageController();
    _audio.addListener(_onAudioChanged);
    _start();
  }

  Future<void> _start() async {
    final items = widget.queue.isEmpty ? <MediaItem>[widget.item] : widget.queue;
    await _audio.playQueue(items, startIndex: widget.initialIndex, source: widget.source);
    if (mounted) setState(() {
      _loading = false;
      _error = _audio.error;
    });
  }

  void _onAudioChanged() {
    if (!mounted) return;
    setState(() => _error = _audio.error);
    if (_showLyrics && _audio.lyricIndex >= 0 && _lyricController.hasClients) {
      _lyricController.animateToPage(
        _audio.lyricIndex,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _audio.removeListener(_onAudioChanged);
    _lyricController.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = _audio.current ?? widget.item;
    return Scaffold(
      backgroundColor: const Color(0xff101114),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('音乐播放器'),
        actions: <Widget>[
          IconButton(
            tooltip: '播放列表',
            icon: const Icon(Icons.queue_music),
            onPressed: () => setState(() => _showQueue = !_showQueue),
          ),
          PopupMenuButton<RepeatMode>(
            icon: Icon(_repeatIcon(_audio.repeatMode)),
            onSelected: _audio.setRepeatMode,
            itemBuilder: (_) => const <PopupMenuEntry<RepeatMode>>[
              PopupMenuItem(value: RepeatMode.none, child: Text('不循环')),
              PopupMenuItem(value: RepeatMode.all, child: Text('列表循环')),
              PopupMenuItem(value: RepeatMode.one, child: Text('单曲循环')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _showQueue
              ? _buildQueue()
              : Column(
                  children: <Widget>[
                    Expanded(child: _showLyrics ? _buildLyrics(item) : _buildCover(item)),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    _buildControls(),
                  ],
                ),
    );
  }

  Widget _buildCover(MediaItem item) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
              boxShadow: <BoxShadow>[
                BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 24),
              ],
              image: item.cover.isEmpty ? null : DecorationImage(image: NetworkImage(item.cover), fit: BoxFit.cover),
            ),
            child: item.cover.isEmpty ? const Icon(Icons.music_note, size: 100, color: Colors.white54) : null,
          ),
          const SizedBox(height: 24),
          Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(item.author ?? '未知艺术家', style: const TextStyle(color: Colors.white70)),
          if (item.album != null && item.album!.isNotEmpty)
            Text(item.album!, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLyrics(MediaItem item) {
    final lyrics = _audio.lyrics;
    if (lyrics.isEmpty) {
      return InkWell(
        onTap: () => setState(() => _showLyrics = false),
        child: _buildCover(item),
      );
    }
    return PageView.builder(
      controller: _lyricController,
      scrollDirection: Axis.vertical,
      itemCount: lyrics.length,
      itemBuilder: (_, index) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            lyrics[index].text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: index == _audio.lyricIndex ? Colors.white : Colors.white38,
              fontSize: index == _audio.lyricIndex ? 21 : 16,
              fontWeight: index == _audio.lyricIndex ? FontWeight.bold : FontWeight.normal,
              height: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueue() {
    if (_audio.queue.isEmpty) return const Center(child: Text('播放列表为空', style: TextStyle(color: Colors.white70)));
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _audio.queue.length,
      separatorBuilder: (_, __) => const Divider(color: Colors.white12),
      itemBuilder: (_, index) {
        final item = _audio.queue[index];
        final active = index == _audio.index;
        return ListTile(
          leading: Text('${index + 1}', style: TextStyle(color: active ? Colors.blue : Colors.white54)),
          title: Text(item.title, style: TextStyle(color: active ? Colors.blue : Colors.white)),
          subtitle: Text(item.author ?? '', style: const TextStyle(color: Colors.white54)),
          onTap: () async {
            await _audio.playQueue(_audio.queue, startIndex: index, source: widget.source);
            setState(() => _showQueue = false);
          },
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      child: Column(
        children: <Widget>[
          Row(children: <Widget>[
            Text(MusicPlayerService.format(_audio.position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Expanded(
              child: Slider(
                value: _audio.duration.inMilliseconds > 0
                    ? _audio.position.inMilliseconds.clamp(0, _audio.duration.inMilliseconds).toDouble()
                    : 0,
                max: _audio.duration.inMilliseconds > 0 ? _audio.duration.inMilliseconds.toDouble() : 1,
                activeColor: Colors.blue,
                onChanged: (value) => _audio.seek(Duration(milliseconds: value.round())),
              ),
            ),
            Text(MusicPlayerService.format(_audio.duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(icon: const Icon(Icons.lyrics_outlined, color: Colors.white70), onPressed: () => setState(() => _showLyrics = !_showLyrics)),
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 30), onPressed: () => _audio.previous(source: widget.source)),
              IconButton(
                icon: Icon(_audio.playing ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white, size: 62),
                onPressed: _audio.toggle,
              ),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 30), onPressed: () => _audio.next(source: widget.source)),
              IconButton(icon: const Icon(Icons.queue_music, color: Colors.white70), onPressed: () => setState(() => _showQueue = true)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _repeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.none: return Icons.repeat;
      case RepeatMode.all: return Icons.repeat;
      case RepeatMode.one: return Icons.repeat_one;
    }
  }
}
