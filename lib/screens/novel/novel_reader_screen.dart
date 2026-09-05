/// 小说阅读器 — 护眼模式/夜间模式/字号调整/翻页动画/阅读进度
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/novel_detail.dart';
import '../../models/reader_settings.dart';
import '../../models/video_source.dart';
import '../../services/spider_service_v2.dart';
import '../../services/app_config.dart';

class NovelReaderScreen extends StatefulWidget {
  final NovelDetail novel;
  final int startChapterIndex;
  final VideoSource source;

  const NovelReaderScreen({
    super.key,
    required this.novel,
    this.startChapterIndex = 0,
    required this.source,
  });

  @override
  State<NovelReaderScreen> createState() => _NovelReaderScreenState();
}

class _NovelReaderScreenState extends State<NovelReaderScreen> {
  late PageController _pageController;
  int _currentChapter = 0;
  String _chapterContent = '';
  bool _isLoading = true;
  bool _showUI = true;
  bool _showChapters = false;
  bool _showSettings = false;
  ReaderSettings _settings = ReaderSettings();

  // 翻页模式: true=左右翻页, false=上下滚动
  bool _isPagedMode = true;
  List<String> _pages = [];

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.startChapterIndex;
    _pageController = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadChapter();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _saveProgress();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadChapter() async {
    if (_currentChapter < 0 || _currentChapter >= widget.novel.chapters.length) return;
    setState(() { _isLoading = true; _chapterContent = ''; _pages = []; });

    final chapter = widget.novel.chapters[_currentChapter];
    final content = await SpiderServiceV2.getNovelChapterContent(
      widget.source, chapter.url,
    );

    if (content != null) {
      setState(() {
        _chapterContent = content;
        _isLoading = false;
        _pages = _splitContent(content);
      });
    } else {
      setState(() {
        _chapterContent = '加载失败，请重试';
        _isLoading = false;
      });
    }
  }

  /// 将长文本按屏幕高度分页
  List<String> _splitContent(String content) {
    if (!_isPagedMode) return [content];
    // 简单分页: 按段落分割，每页约 500 字
    final paragraphs = content.split(RegExp(r'\n'));
    List<String> pages = [];
    String currentPage = '';
    for (var p in paragraphs) {
      if (currentPage.length + p.length > 500) {
        pages.add(currentPage);
        currentPage = p;
      } else {
        currentPage += '\n$p';
      }
    }
    if (currentPage.isNotEmpty) pages.add(currentPage);
    return pages.isEmpty ? [content] : pages;
  }

  Future<void> _saveProgress() async {
    // TODO: 保存阅读进度到 AppConfig
  }

  void _goToChapter(int index) {
    if (index < 0 || index >= widget.novel.chapters.length) return;
    _saveProgress();
    setState(() => _currentChapter = index);
    _loadChapter();
  }

  Color get _bgColor => _settings.isNightMode
      ? const Color(0xFF1A1A1A)
      : _settings.isNightMode ? Colors.black : Colors.white;

  Color get _textColor => _settings.isNightMode
      ? Colors.grey[400]!
      : const Color(0xFF333333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          // 主内容
          GestureDetector(
            onTap: () => setState(() => _showUI = !_showUI),
            child: _isLoading
                ? Center(child: CircularProgressIndicator(
                    color: _settings.isNightMode ? Colors.white : Colors.blue))
                : _isPagedMode ? _buildPagedView() : _buildScrollView(),
          ),

          // 顶部栏
          if (_showUI) _buildTopBar(),

          // 底部栏
          if (_showUI) _buildBottomBar(),

          // 章节列表
          if (_showChapters) _buildChapterPanel(),

          // 设置面板
          if (_showSettings) _buildSettingsPanel(),
        ],
      ),
    );
  }

  Widget _buildPagedView() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (i) => setState(() {}),
      itemCount: _pages.length + 1, // +1 for next chapter hint
      itemBuilder: (context, index) {
        if (index == _pages.length) {
          // 最后一页 — 提示下一章
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('本章已读完',
                    style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                const SizedBox(height: 16),
                if (_currentChapter < widget.novel.chapters.length - 1)
                  ElevatedButton(
                    onPressed: () => _goToChapter(_currentChapter + 1),
                    child: const Text('下一章'),
                  ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Text(_pages[index],
                style: TextStyle(
                  fontSize: _settings.fontSize,
                  color: _textColor,
                  height: _settings.lineSpacing,
                  fontFamily: _settings.fontFamily.isNotEmpty
                      ? _settings.fontFamily : null,
                )),
          ),
        );
      },
    );
  }

  Widget _buildScrollView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(_chapterContent,
              style: TextStyle(
                fontSize: _settings.fontSize,
                color: _textColor,
                height: _settings.lineSpacing,
                fontFamily: _settings.fontFamily.isNotEmpty
                    ? _settings.fontFamily : null,
              )),
          const SizedBox(height: 40),
          // 章节导航
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: _currentChapter > 0
                    ? () => _goToChapter(_currentChapter - 1) : null,
                child: const Text('上一章'),
              ),
              OutlinedButton(
                onPressed: () => setState(() => _showChapters = true),
                child: const Text('目录'),
              ),
              OutlinedButton(
                onPressed: _currentChapter < widget.novel.chapters.length - 1
                    ? () => _goToChapter(_currentChapter + 1) : null,
                child: const Text('下一章'),
              ),
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
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [_bgColor.withOpacity(0.95), _bgColor.withOpacity(0)],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back,
                    color: _settings.isNightMode ? Colors.white : Colors.black87,
                    size: 24),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.novel.title,
                        style: TextStyle(color: _textColor, fontSize: 14),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(
                      _currentChapter < widget.novel.chapters.length
                          ? widget.novel.chapters[_currentChapter].name
                          : '',
                      style: TextStyle(
                          color: Colors.grey[_settings.isNightMode ? 500 : 400],
                          fontSize: 11),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (_isPagedMode)
                Text(
                  '${_pages.isNotEmpty ? 1 : 0}/${_pages.length}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [_bgColor.withOpacity(0.95), _bgColor.withOpacity(0)],
            ),
          ),
          child: Row(
            children: [
              // 上一章
              IconButton(
                icon: Icon(Icons.skip_previous,
                    color: _currentChapter > 0
                        ? (_settings.isNightMode ? Colors.white : Colors.black87)
                        : Colors.grey,
                    size: 28),
                onPressed: _currentChapter > 0
                    ? () => _goToChapter(_currentChapter - 1) : null,
              ),
              // 进度
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    thumbColor: Colors.blue,
                    activeTrackColor: Colors.blue,
                    inactiveTrackColor: Colors.grey[400],
                    trackHeight: 2,
                  ),
                  child: Slider(
                    value: _currentChapter.toDouble(),
                    max: (widget.novel.chapters.length - 1).toDouble().clamp(1, 9999).toDouble(),
                    onChanged: (v) => _goToChapter(v.toInt()),
                  ),
                ),
              ),
              // 下一章
              IconButton(
                icon: Icon(Icons.skip_next,
                    color: _currentChapter < widget.novel.chapters.length - 1
                        ? (_settings.isNightMode ? Colors.white : Colors.black87)
                        : Colors.grey,
                    size: 28),
                onPressed: _currentChapter < widget.novel.chapters.length - 1
                    ? () => _goToChapter(_currentChapter + 1) : null,
              ),
              // 目录
              IconButton(
                icon: Icon(Icons.list,
                    color: _settings.isNightMode ? Colors.white : Colors.black87,
                    size: 24),
                onPressed: () => setState(() {
                  _showChapters = !_showChapters;
                  _showSettings = false;
                }),
              ),
              // 设置
              IconButton(
                icon: Icon(Icons.tune,
                    color: _settings.isNightMode ? Colors.white : Colors.black87,
                    size: 24),
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

  Widget _buildChapterPanel() {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      height: MediaQuery.of(context).size.height * 0.55,
      child: Container(
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text('目录',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: _textColor)),
                  const Spacer(),
                  Text('${widget.novel.chapters.length}章',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: _textColor),
                    onPressed: () => setState(() => _showChapters = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.novel.chapters.length,
                itemBuilder: (context, index) {
                  final ch = widget.novel.chapters[index];
                  final isCurrent = index == _currentChapter;
                  return ListTile(
                    title: Text(ch.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: isCurrent ? Colors.blue : _textColor,
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
      left: 0, right: 0, bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            )),
            // 阅读模式
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeChip('翻页', Icons.menu_book, !_isPagedMode),
                const SizedBox(width: 16),
                _buildModeChip('滚动', Icons.vertical_align_center, _isPagedMode),
              ],
            ),
            const SizedBox(height: 16),
            // 字号
            Row(
              children: [
                Icon(Icons.text_decrease, color: Colors.grey[500], size: 20),
                Expanded(
                  child: Slider(
                    value: _settings.fontSize,
                    min: 12, max: 28,
                    onChanged: (v) => setState(() {
                      _settings.fontSize = v;
                      _pages = _splitContent(_chapterContent);
                    }),
                  ),
                ),
                Icon(Icons.text_increase, color: Colors.grey[500], size: 20),
                Text('${_settings.fontSize.round()}',
                    style: TextStyle(color: _textColor, fontSize: 14)),
              ],
            ),
            // 夜间模式
            SwitchListTile(
              title: Text('夜间模式',
                  style: TextStyle(color: _textColor, fontSize: 14)),
              value: _settings.isNightMode,
              onChanged: (v) => setState(() => _settings.isNightMode = v),
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon, bool isActive) {
    return GestureDetector(
      onTap: () => setState(() {
        _isPagedMode = (label == '翻页');
        _pages = _splitContent(_chapterContent);
        _showSettings = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? Colors.blue : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 20),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              color: isActive ? Colors.blue : Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
