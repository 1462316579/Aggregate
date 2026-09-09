/// 音乐播放器界面 — 全屏播放 / 歌词滚动 / 播放列表
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/music_player_service.dart';
import '../../models/music_detail.dart';
import '../../models/video_source.dart';

class MusicPlayerScreen extends StatefulWidget {
  final MusicTrack track;
  final List<MusicTrack> playlist;
  final int startIndex;
  final VideoSource source;

  const MusicPlayerScreen({
    super.key,
    required this.track,
    this.playlist = const [],
    this.startIndex = 0,
    required this.source,
  });

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showPlaylist = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // 开始播放
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = context.read<MusicPlayerService>();
      if (widget.playlist.isNotEmpty) {
        service.playPlaylist(widget.source, widget.playlist,
            startIndex: widget.startIndex);
      } else {
        service.play(widget.source, widget.track);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<MusicPlayerService>();
    final track = service.currentTrack ?? widget.track;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              const Color(0xFF0F0F0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 顶部栏
              _buildTopBar(track),
              // 主内容: 封面 / 歌词 / 播放列表
              Expanded(
                child: _buildBody(service, track, size),
              ),
              // 播放控制
              _buildControls(service, track),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(MusicTrack track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 32),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(track.name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(track.author,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MusicPlayerService service, MusicTrack track, Size size) {
    return Column(
      children: [
        // Tab 切换
        TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: '封面'),
            Tab(text: '歌词'),
            Tab(text: '列表'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCoverView(track, size),
              _buildLyricView(service),
              _buildPlaylistView(service),
            ],
          ),
        ),
      ],
    );
  }

  /// 封面视图 — 旋转唱片
  Widget _buildCoverView(MusicTrack track, Size size) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size.width * 0.55,
        height: size.width * 0.55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 外圈
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.grey[800]!, Colors.grey[900]!],
                ),
              ),
            ),
            // 封面图
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: track.cover,
                width: size.width * 0.4,
                height: size.width * 0.4,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: Colors.grey[800],
                  child: const Icon(Icons.music_note, color: Colors.grey, size: 48),
                ),
              ),
            ),
            // 中心圆点
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 歌词视图 — 滚动高亮
  Widget _buildLyricView(MusicPlayerService service) {
    if (service.lyrics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lyrics, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            Text('暂无歌词', style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
      itemCount: service.lyrics.length,
      itemBuilder: (context, index) {
        final line = service.lyrics[index];
        final isCurrent = index == service.currentLyricIndex;

        return AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontSize: isCurrent ? 18 : 14,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isCurrent ? Colors.white : Colors.grey[600],
          ),
          textAlign: TextAlign.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(line.text),
          ),
        );
      },
    );
  }

  /// 播放列表
  Widget _buildPlaylistView(MusicPlayerService service) {
    final playlist = service.playlist;
    if (playlist.isEmpty) {
      return Center(
        child: Text('暂无播放列表', style: TextStyle(color: Colors.grey[500])),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: playlist.length,
      itemBuilder: (context, index) {
        final track = playlist[index];
        final isCurrent = index == service.currentIndex;
        return ListTile(
          leading: isCurrent
              ? const Icon(Icons.equalizer, color: Colors.blue, size: 20)
              : Text('${index + 1}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          title: Text(track.name,
              style: TextStyle(
                fontSize: 14,
                color: isCurrent ? Colors.blue : null,
                fontWeight: isCurrent ? FontWeight.bold : null,
              ),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(track.author,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              maxLines: 1),
          trailing: Text(
            MusicPlayerService.formatDuration(
                Duration(seconds: track.duration)),
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          dense: true,
          onTap: () => service.play(widget.source, track),
        );
      },
    );
  }

  /// 播放控制区
  Widget _buildControls(MusicPlayerService service, MusicTrack track) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      child: Column(
        children: [
          // 进度条
          Row(
            children: [
              Text(MusicPlayerService.formatDuration(service.position),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.blue,
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.white24,
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                  ),
                  child: Slider(
                    value: service.duration.inMilliseconds > 0
                        ? service.position.inMilliseconds.toDouble().clamp(
                            0, service.duration.inMilliseconds.toDouble())
                        : 0,
                    max: service.duration.inMilliseconds > 0
                        ? service.duration.inMilliseconds.toDouble()
                        : 1,
                    onChanged: (v) => service.seek(Duration(milliseconds: v.toInt())),
                  ),
                ),
              ),
              Text(MusicPlayerService.formatDuration(service.duration),
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          // 控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 随机
              IconButton(
                icon: Icon(Icons.shuffle,
                    color: service.shuffle ? Colors.blue : Colors.grey,
                    size: 24),
                onPressed: service.toggleShuffle,
              ),
              // 上一曲
              IconButton(
                icon: const Icon(Icons.skip_previous, size: 32),
                onPressed: service.hasPrev ? service.prev : null,
              ),
              // 播放/暂停
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    service.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white, size: 36,
                  ),
                  onPressed: service.playOrPause,
                ),
              ),
              // 下一曲
              IconButton(
                icon: const Icon(Icons.skip_next, size: 32),
                onPressed: service.hasNext ? service.next : null,
              ),
              // 循环
              IconButton(
                icon: Icon(
                  service.repeatMode == RepeatMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  color: service.repeatMode == RepeatMode.none
                      ? Colors.grey
                      : Colors.blue,
                  size: 24,
                ),
                onPressed: service.toggleRepeat,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
