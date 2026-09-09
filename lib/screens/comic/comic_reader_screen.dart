/// 漫画阅读器 — 支持竖向滚动 / 左右翻页 / 双页模式
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comic_detail.dart';
import '../../models/video_source.dart';
import '../../models/reader_settings.dart';
import '../../services/spider_service_v2.dart';

class ComicReaderScreen extends StatefulWidget {
  final ComicDetail comic;
  final List<ComicChapter> chapters;
  final int startChapterIndex;
  final VideoSource source;

  const ComicReaderScreen({
    super.key,
    required this.comic,
    required this.chapters,
    this.startChapterIndex = 0,
    required this.source,
  });

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentChapter = 0;
  int _currentPage = 0;
  List<ComicPage> _pages = [];
  bool _isLoading = true;
  bool _showUI = true;
  bool _isVerticalMode = true; // true=竖向滚动, false=翻页
  bool _showChapters = false;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.startChapterIndex;
    _pageController = PageController();
    _scrollController = ScrollController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadChapter();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadChapter() async {
    if (_currentChapter < 0 || _currentChapter >= widget.chapters.length) return;
    setState(() { _isLoading = true; _pages = []; });

    final chapter = widget.chapters[_currentChapter];
    final pages = await SpiderServiceV2.getComicPages(
      widget.source, chapter.url,
    );

    setState(() {
      _pages = pages;
      _isLoading = false;
      _currentPage = 0;
    });
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.chapters.length) return;
    setState(() => _currentChapter = index);
    _loadChapter();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 主内容区
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _isVerticalMode
                    ? _buildVerticalScroll()
                    : _buildPageView(),
          ),

          // 顶部栏
          if (_showUI) _buildTopBar(),

          // 底部栏
          if (_showUI) _buildBottomBar(),

          // 章节列表面板
          if (_showChapters) _buildChapterPanel(),

          // 设置面板
          if (_showSettings) _buildSettingsPanel(),
        ],
      ),
    );
  }

  /// 竖向滚动模式 (类似 Webtoon)
  Widget _buildVerticalScroll() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return CachedNetworkImage(
          imageUrl: page.imageUrl,
          fit: BoxFit.fitWidth,
          placeholder: (_, __) => Container(
            height: 300,
            color: Colors.grey[900],
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (_, __, ___) => Container(
            height: 300,
            color: Colors.grey[900],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          ),
        );
      },
    );
  }

  /// 翻页模式
  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: _pages.length,
      itemBuilder: (context, index) {
        final page = _pages[index];
        return InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: page.imageUrl,
              fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image,
                  color: Colors.grey, size: 48),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.comic.title,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(widget.chapters[_currentChapter].name,
                        style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Text('${_currentPage + 1}/${_pages.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              // 上一章
              IconButton(
                icon: Icon(Icons.skip_previous,
                    color: _currentChapter > 0 ? Colors.white : Colors.grey,
                    size: 28),
                onPressed: _currentChapter > 0
                    ? () => _goToChapter(_currentChapter - 1)
                    : null,
              ),
              // 进度条
              Expanded(
                child: _isVerticalMode
                    ? _buildVerticalProgress()
                    : _buildPageProgress(),
              ),
              // 下一章
              IconButton(
                icon: Icon(Icons.skip_next,
                    color: _currentChapter < widget.chapters.length - 1
                        ? Colors.white
                        : Colors.grey,
                    size: 28),
                onPressed: _currentChapter < widget.chapters.length - 1
                    ? () => _goToChapter(_currentChapter + 1)
                    : null,
              ),
              // 章节列表
              IconButton(
                icon: const Icon(Icons.list, color: Colors.white, size: 24),
                onPressed: () => setState(() {
                  _showChapters = !_showChapters;
                  _showSettings = false;
                }),
              ),
              // 设置
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                onPressed: () => setState(() {
                  _showSettings = !_showSettings;
                  _showChapters = false;
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalProgress() {
    return SliderTheme(
      data: SliderThemeData(
        thumbColor: Colors.blue,
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.white24,
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      child: Slider(
        value: _pages.isNotEmpty ? (_currentPage + 1).toDouble() : 0,
        max: _pages.isNotEmpty ? _pages.length.toDouble() : 1,
        onChanged: (v) {
          final index = v.toInt().clamp(0, _pages.length - 1);
          // 滚动到对应位置
          if (_scrollController.hasClients) {
            final totalHeight = _scrollController.position.maxScrollExtent;
            final target = totalHeight * (index / _pages.length);
            _scrollController.animateTo(target,
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease);
          }
        },
      ),
    );
  }

  Widget _buildPageProgress() {
    return SliderTheme(
      data: SliderThemeData(
        thumbColor: Colors.blue,
        activeTrackColor: Colors.blue,
        inactiveTrackColor: Colors.white24,
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      child: Slider(
        value: _currentPage.toDouble(),
        max: _pages.isNotEmpty ? (_pages.length - 1).toDouble() : 1,
        onChanged: (v) {
          _pageController.jumpToPage(v.toInt());
        },
      ),
    );
  }

  Widget _buildChapterPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: MediaQuery.of(context).size.height * 0.5,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            HandleBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('目录',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text('${widget.chapters.length}章',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _showChapters = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.chapters.length,
                itemBuilder: (context, index) {
                  final ch = widget.chapters[index];
                  final isCurrent = index == _currentChapter;
                  return ListTile(
                    title: Text(ch.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCurrent ? Colors.blue : null,
                          fontWeight: isCurrent ? FontWeight.bold : null,
                        )),
                    trailing: isCurrent
                        ? const Icon(Icons.play_arrow, color: Colors.blue, size: 18)
                        : null,
                    dense: true,
                    onTap: () {
                      _goToChapter(index);
                      setState(() => _showChapters = false);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HandleBar(),
            const SizedBox(height: 12),
            // 阅读模式切换
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeButton('翻页', Icons.menu_book, !_isVerticalMode),
                const SizedBox(width: 24),
                _buildModeButton('滚动', Icons.vertical_align_center, _isVerticalMode),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() {
        _isVerticalMode = (label == '滚动');
        _showSettings = false;
      }),
      child: Column(
        children: [
          Icon(icon, color: selected ? Colors.blue : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: selected ? Colors.blue : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}

class HandleBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40, height: 4,
        margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.grey[600],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
