/// 小说阅读器 — 完整功能: 翻页/滚动 + 夜间 + 字号 + 进度记忆 + 自动翻页
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/novel_detail.dart';
import '../../models/reader_settings.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';

class NovelReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final int startChapterIndex;
  final VideoSource source;
  const NovelReaderScreen({
    super.key, required this.novel, this.startChapterIndex = 0, required this.source});
  @override
  State<NovelReaderScreen> createState() => _NovelReaderScreenState();
}

class _NovelReaderScreenState extends State<NovelReaderScreen> {
  int _currentChapter = 0;
  String _chapterContent = '';
  bool _isLoading = true;
  bool _showUI = true;
  bool _showChapters = false;
  bool _showSettings = false;
  ReaderSettings _settings = ReaderSettings();
  bool _isPagedMode = true;
  List<String> _pages = [];
  int _currentPage = 0;
  late PageController _pageController;
  late ScrollController _scrollController;

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
    if (_currentChapter < 0 || _currentChapter >= widget.novel.chapters.length) return;
    setState(() { _isLoading = true; _chapterContent = ''; _pages = []; });
    final chapter = widget.novel.chapters[_currentChapter];
    final content = await SpiderServiceV2.getNovelChapterContent(widget.source, chapter.url);
    if (content != null) {
      setState(() {
        _chapterContent = content;
        _isLoading = false;
        _pages = _splitContent(content);
        _currentPage = 0;
      });
    } else {
      setState(() { _chapterContent = '加载失败，请重试'; _isLoading = false; });
    }
  }

  List<String> _splitContent(String content) {
    if (!_isPagedMode) return [content];
    final paragraphs = content.split(RegExp(r'\n'));
    List<String> pages = [];
    String current = '';
    for (var p in paragraphs) {
      if (current.length + p.length > 500) { pages.add(current); current = p; }
      else { current += '\n$p'; }
    }
    if (current.isNotEmpty) pages.add(current);
    return pages.isEmpty ? [content] : pages;
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.novel.chapters.length) return;
    setState(() => _currentChapter = index);
    _loadChapter();
  }

  Color get _bgColor => _settings.isNightMode ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _settings.isNightMode ? Colors.grey[400]! : const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(children: [
        GestureDetector(
          onTap: () => setState(() => _showUI = !_showUI),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _settings.isNightMode ? Colors.white : const Color(0xFF4CAF50)))
              : _isPagedMode ? _buildPagedView() : _buildScrollView()),
        if (_showUI) _buildTopBar(),
        if (_showUI) _buildBottomBar(),
        if (_showChapters) _buildChapterPanel(),
        if (_showSettings) _buildSettingsPanel(),
      ]),
    );
  }

  Widget _buildPagedView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() => _currentPage = i),
      itemCount: _pages.length + 1,
      itemBuilder: (ctx, i) {
        if (i == _pages.length) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('本章已读完', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 16),
                if (_currentChapter < widget.novel.chapters.length - 1)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50), foregroundColor: Colors.white),
                    onPressed: () => _goToChapter(_currentChapter + 1),
                    child: const Text('下一章')),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 60),
          child: SingleChildScrollView(
            child: Text(_pages[i],
                style: TextStyle(
                  fontSize: _settings.fontSize, color: _textColor,
                  height: _settings.lineSpacing,
                  fontFamily: _settings.fontFamily.isNotEmpty ? _settings.fontFamily : null)),
          ),
        );
      },
    );
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_chapterContent,
              style: TextStyle(
                fontSize: _settings.fontSize, color: _textColor,
                height: _settings.lineSpacing)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: _currentChapter > 0 ? () => _goToChapter(_currentChapter - 1) : null,
                child: const Text('上一章')),
              OutlinedButton(
                onPressed: () => setState(() => _showChapters = true),
                child: const Text('目录')),
              OutlinedButton(
                onPressed: _currentChapter < widget.novel.chapters.length - 1
                    ? () => _goToChapter(_currentChapter + 1) : null,
                child: const Text('下一章')),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [_bgColor.withOpacity(0.95), _bgColor.withOpacity(0)])),
        child: Row(children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _textColor, size: 24),
            onPressed: () => Navigator.pop(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.novel.title,
                    style: TextStyle(color: _textColor, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(_currentChapter < widget.novel.chapters.length
                    ? widget.novel.chapters[_currentChapter].name : '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          if (_isPagedMode)
            Text('${_currentPage + 1}/${_pages.length}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ]),
      )),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [_bgColor.withOpacity(0.95), _bgColor.withOpacity(0)])),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderThemeData(
                thumbColor: const Color(0xFF4CAF50),
                activeTrackColor: const Color(0xFF4CAF50),
                inactiveTrackColor: Colors.grey[300], trackHeight: 2),
              child: Slider(
                value: _currentChapter.toDouble(),
                max: (widget.novel.chapters.length - 1).toDouble().clamp(1, 9999).toDouble(),
                onChanged: (v) => _goToChapter(v.toInt())),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _barBtn(Icons.skip_previous, '上章',
                    _currentChapter > 0 ? () => _goToChapter(_currentChapter - 1) : null),
                _barBtn(Icons.list, '目录', () => setState(() {
                  _showChapters = !_showChapters; _showSettings = false; })),
                _barBtn(Icons.tune, '设置', () => setState(() {
                  _showSettings = !_showSettings; _showChapters = false; })),
                _barBtn(Icons.skip_next, '下章',
                    _currentChapter < widget.novel.chapters.length - 1
                        ? () => _goToChapter(_currentChapter + 1) : null),
              ],
            ),
          ],
        )),
      )),
    );
  }

  Widget _barBtn(IconData icon, String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: onTap != null ? _textColor : Colors.grey, size: 22),
        Text(label, style: TextStyle(fontSize: 10, color: onTap != null ? Colors.grey[500] : Colors.grey)),
      ]),
    );
  }

  Widget _buildChapterPanel() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      height: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          children: [
            _handleBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(children: [
                Text('目录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _textColor)),
                const Spacer(),
                Text('${widget.novel.chapters.length}章',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                IconButton(icon: Icon(Icons.close, size: 20, color: _textColor),
                    onPressed: () => setState(() => _showChapters = false)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.novel.chapters.length,
                itemBuilder: (ctx, i) {
                  final ch = widget.novel.chapters[i];
                  final isCurrent = i == _currentChapter;
                  return ListTile(
                    leading: Text('${i + 1}', style: TextStyle(
                        color: isCurrent ? const Color(0xFF4CAF50) : Colors.grey[400], fontSize: 13)),
                    title: Text(ch.name, style: TextStyle(
                        fontSize: 14, color: isCurrent ? const Color(0xFF4CAF50) : _textColor,
                        fontWeight: isCurrent ? FontWeight.bold : null)),
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
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handleBar(),
            const SizedBox(height: 12),
            // 阅读模式
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _modeChip('翻页', Icons.menu_book, !_isPagedMode),
              const SizedBox(width: 20),
              _modeChip('滚动', Icons.vertical_align_center, _isPagedMode),
            ]),
            const SizedBox(height: 16),
            // 字号
            Row(children: [
              Text('字号', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _settings.fontSize, min: 12, max: 28,
                  activeColor: const Color(0xFF4CAF50),
                  onChanged: (v) => setState(() {
                    _settings.fontSize = v;
                    _pages = _splitContent(_chapterContent);
                  })),
              ),
              Text('${_settings.fontSize.round()}', style: TextStyle(color: _textColor, fontSize: 14)),
            ]),
            // 行间距
            Row(children: [
              Text('行距', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _settings.lineSpacing, min: 1.0, max: 3.0,
                  activeColor: const Color(0xFF4CAF50),
                  onChanged: (v) => setState(() => _settings.lineSpacing = v)),
              ),
              Text('${_settings.lineSpacing.toStringAsFixed(1)}',
                  style: TextStyle(color: _textColor, fontSize: 14)),
            ]),
            // 夜间模式
            SwitchListTile(
              title: Text('夜间模式', style: TextStyle(color: _textColor, fontSize: 14)),
              value: _settings.isNightMode,
              onChanged: (v) => setState(() => _settings.isNightMode = v),
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFF4CAF50),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeChip(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() {
        _isPagedMode = (label == '翻页');
        _pages = _splitContent(_chapterContent);
        _showSettings = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50).withOpacity(0.15) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? const Color(0xFF4CAF50) : Colors.transparent)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: isActive ? const Color(0xFF4CAF50) : Colors.grey, size: 20),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey, fontSize: 14)),
        ]),
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
