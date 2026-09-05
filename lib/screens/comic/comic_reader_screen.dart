/// 漫画阅读器 — 完整功能: 竖向/翻页 + 缩放 + 亮度 + 章节跳转 + 缓存标记
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/comic_detail.dart';
import '../../models/video_source.dart';
import '../../models/reader_settings.dart';
import '../../services/spider_service_v2.dart';
import '../../utils/volume_key_handler.dart';

class ComicReaderScreen extends StatefulWidget {
  final ComicDetail comic;
  final List<ComicChapter> chapters;
  final int startChapterIndex;
  final VideoSource source;

  const ComicReaderScreen({
    super.key, required this.comic, required this.chapters,
    this.startChapterIndex = 0, required this.source});

  @override
  State<ComicReaderScreen> createState() => _ComicReaderScreenState();
}

class _ComicReaderScreenState extends State<ComicReaderScreen> {
  late PageController _pageController;
  late ScrollController _scrollController;
  int _currentChapter = 0;
  List<ComicPage> _pages = [];
  bool _isLoading = true;
  bool _showUI = true;
  bool _isVerticalMode = true;
  bool _showChapters = false;
  bool _showSettings = false;
  double _brightness = 0.8;

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
    final pages = await SpiderServiceV2.getComicPages(widget.source, chapter.url);
    setState(() { _pages = pages; _isLoading = false; _currentPage = 0; });
  }

  int _currentPage = 0;

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.chapters.length) return;
    setState(() => _currentChapter = index);
    _loadChapter();
  }

  @override
  Widget build(BuildContext context) {
    return VolumeKeyReaderWrapper(
      config: VolumeKeyConfig(
        enabled: true,
        volumeUpAction: VolumeKeyAction.pageUp,
        volumeDownAction: VolumeKeyAction.pageDown,
      ),
      onPageUp: () {
        if (_isVerticalMode && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.offset - MediaQuery.of(context).size.height * 0.8,
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
        } else if (!_isVerticalMode && _currentPage > 0) {
          _pageController.previousPage(
              duration: const Duration(milliseconds: 300), curve: Curves.ease);
        }
      },
      onPageDown: () {
        if (_isVerticalMode && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.offset + MediaQuery.of(context).size.height * 0.8,
            duration: const Duration(milliseconds: 300), curve: Curves.ease);
        } else if (!_isVerticalMode && _currentPage < _pages.length - 1) {
          _pageController.nextPage(
              duration: const Duration(milliseconds: 300), curve: Curves.ease);
        }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // 主内容
        GestureDetector(
          onTap: () => setState(() => _showUI = !_showUI),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _isVerticalMode ? _buildVerticalScroll() : _buildPageView()),
        // 顶部栏
        if (_showUI) _buildTopBar(),
        // 底部栏
        if (_showUI) _buildBottomBar(),
        // 章节列表
        if (_showChapters) _buildChapterPanel(),
        // 设置面板
        if (_showSettings) _buildSettingsPanel(),
        // 加载指示
        if (_isLoading)
          Positioned.fill(child: Container(
            color: Colors.black54,
            child: const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text('加载中...', style: TextStyle(color: Colors.white70)),
              ],
            )))),
      ]),
    ),
    );
  }

  Widget _buildVerticalScroll() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _pages.length + 1, // +1 for next chapter hint
      itemBuilder: (ctx, i) {
        if (i == _pages.length) {
          return _buildEndOfChapter();
        }
        final page = _pages[i];
        return CachedNetworkImage(
          imageUrl: page.imageUrl, fit: BoxFit.fitWidth,
          placeholder: (_, __) => Container(
            height: 300, color: Colors.grey[900],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
          errorWidget: (_, __, ___) => Container(
            height: 300, color: Colors.grey[900],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40))),
        );
      },
    );
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemCount: _pages.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _pages.length) return _buildEndOfChapter();
        final page = _pages[i];
        return InteractiveViewer(
          minScale: 0.5, maxScale: 3.0,
          child: Center(
            child: CachedNetworkImage(
              imageUrl: page.imageUrl, fit: BoxFit.contain,
              placeholder: (_, __) => const CircularProgressIndicator(),
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.grey, size: 40)),
          ),
        );
      },
    );
  }

  Widget _buildEndOfChapter() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('本章已读完', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
          const SizedBox(height: 16),
          if (_currentChapter < widget.chapters.length - 1)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9800), foregroundColor: Colors.white),
              onPressed: () => _goToChapter(_currentChapter + 1),
              child: const Text('下一章')),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => setState(() => _showChapters = true),
            child: const Text('返回目录')),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent])),
          child: Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              onPressed: () => Navigator.pop(context)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.comic.title,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(widget.chapters[_currentChapter].name,
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),
            // 页码
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(12)),
              child: Text(_isVerticalMode
                  ? '${_currentPage + 1}/${_pages.length}'
                  : '${_currentPage + 1}/${_pages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ),
            const SizedBox(width: 8),
          ]),
        )),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black87, Colors.transparent])),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              Row(children: [
                Text(_isVerticalMode ? '${_currentPage + 1}' : '${_currentPage + 1}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbColor: const Color(0xFFFF9800),
                      activeTrackColor: const Color(0xFFFF9800),
                      inactiveTrackColor: Colors.white24,
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                    child: Slider(
                      value: _pages.isNotEmpty ? (_currentPage + 1).toDouble() : 0,
                      max: _pages.isNotEmpty ? _pages.length.toDouble() : 1,
                      onChanged: (v) {
                        final idx = v.toInt().clamp(0, _pages.length - 1);
                        if (_isVerticalMode && _scrollController.hasClients) {
                          final total = _scrollController.position.maxScrollExtent;
                          _scrollController.animateTo(total * (idx / _pages.length),
                              duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        } else {
                          _pageController.jumpToPage(idx);
                        }
                      }),
                  ),
                ),
                Text('${_pages.length}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              // 操作按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _bottomBtn(Icons.skip_previous, '上一章',
                      _currentChapter > 0 ? () => _goToChapter(_currentChapter - 1) : null),
                  _bottomBtn(Icons.list, '目录', () => setState(() {
                    _showChapters = !_showChapters; _showSettings = false; })),
                  _bottomBtn(Icons.brightness_low, '亮度', () => _showBrightnessDialog()),
                  _bottomBtn(Icons.settings, '设置', () => setState(() {
                    _showSettings = !_showSettings; _showChapters = false; })),
                  _bottomBtn(Icons.skip_next, '下一章',
                      _currentChapter < widget.chapters.length - 1
                          ? () => _goToChapter(_currentChapter + 1) : null),
                ],
              ),
            ],
          )),
      ),
    );
  }

  Widget _bottomBtn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onTap != null ? Colors.white : Colors.grey, size: 22),
          Text(label, style: TextStyle(
              fontSize: 10, color: onTap != null ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChapterPanel() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      height: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          children: [
            _handleBar(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                const Text('目录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${widget.chapters.length}章', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                IconButton(icon: const Icon(Icons.close, size: 20),
                    onPressed: () => setState(() => _showChapters = false)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = widget.chapters[i];
                  final isCurrent = i == _currentChapter;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 14,
                      backgroundColor: isCurrent ? const Color(0xFFFF9800) : Colors.grey[200],
                      child: Text('${i + 1}', style: TextStyle(
                          fontSize: 11, color: isCurrent ? Colors.white : Colors.grey[600])),
                    ),
                    title: Text(ch.name, style: TextStyle(
                        fontSize: 14, color: isCurrent ? const Color(0xFFFF9800) : const Color(0xFF333333),
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                    dense: true,
                    onTap: () { _goToChapter(i); setState(() => _showChapters = false); },
                  );
                }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handleBar(),
            const SizedBox(height: 12),
            // 阅读模式
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _modeBtn('翻页', Icons.menu_book, !_isVerticalMode),
                const SizedBox(width: 24),
                _modeBtn('滚动', Icons.vertical_align_center, _isVerticalMode),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn(String label, IconData icon, bool selected) {
    return GestureDetector(
      onTap: () => setState(() { _isVerticalMode = (label == '滚动'); _showSettings = false; }),
      child: Column(children: [
        Icon(icon, color: selected ? const Color(0xFFFF9800) : Colors.grey, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
            color: selected ? const Color(0xFFFF9800) : Colors.grey, fontSize: 12)),
      ]),
    );
  }

  void _showBrightnessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('屏幕亮度'),
        content: StatefulBuilder(
          builder: (ctx, setDialogState) => Slider(
            value: _brightness,
            onChanged: (v) {
              setDialogState(() => _brightness = v);
              // 实际应用亮度: SystemChrome.setSystemUIOverlayStyle
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  Widget _handleBar() {
    return Center(
      child: Container(
        width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
        decoration: BoxDecoration(
          color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));
  }
}
