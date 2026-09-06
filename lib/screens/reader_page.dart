import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hongxi/models/content.dart';
import 'package:hongxi/providers/source_provider.dart';

class ReaderPage extends StatefulWidget {
  final MediaItem item;
  final int initialIndex;
  const ReaderPage({super.key, required this.item, this.initialIndex = 0});

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late int _index;
  bool _night = false;
  bool _paged = true;
  double _fontSize = 18;
  bool _loading = false;
  String _chapterText = '';
  List<String> _images = [];
  final _pageController = PageController();
  final _scrollController = ScrollController();

  bool get _isNovel => widget.item.type == ContentType.novel;
  bool get _hasChapters => widget.item.episodes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    final last = widget.item.episodes.length - 1;
    _index = widget.item.episodes.isEmpty ? 0 : widget.initialIndex.clamp(0, last).toInt();
    _loadChapter();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChapter() async {
    if (!_hasChapters) return;
    setState(() {
      _loading = true;
      _chapterText = '';
      _images = [];
    });
    final episode = widget.item.episodes[_index];
    final provider = context.read<SourceProvider>();
    if (_isNovel) {
      final text = await provider.chapterContent(widget.item.sourceId, episode.url);
      if (mounted) setState(() {
        _chapterText = text.isEmpty ? '章节内容为空，请检查源接口。' : text;
        _loading = false;
      });
    } else {
      var images = await provider.chapterImages(widget.item.sourceId, episode.url);
      if (images.isEmpty && episode.url.isNotEmpty) images = [episode.url];
      if (mounted) setState(() {
        _images = images;
        _loading = false;
      });
    }
  }

  void _changeChapter(int value) {
    if (!_hasChapters || value < 0 || value >= widget.item.episodes.length) return;
    setState(() => _index = value);
    _pageController.jumpToPage(0);
    _scrollController.jumpTo(0);
    _loadChapter();
  }

  @override
  Widget build(BuildContext context) {
    final background = _night ? const Color(0xff202124) : const Color(0xfffffbf2);
    final foreground = _night ? Colors.white70 : const Color(0xff333333);
    final chapterTitle = _hasChapters ? widget.item.episodes[_index].title : '正文';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(chapterTitle, style: TextStyle(fontSize: 11, color: foreground.withOpacity(.65))),
          ],
        ),
        backgroundColor: background,
        foregroundColor: foreground,
        actions: [
          IconButton(
            icon: Icon(_night ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => _night = !_night),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => _paged = value == 'paged'),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'paged', child: Text('翻页模式')),
              PopupMenuItem(value: 'scroll', child: Text('滚动模式')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isNovel ? _buildNovel(foreground) : _buildComic(),
      bottomNavigationBar: _buildBottomBar(foreground),
    );
  }

  Widget _buildNovel(Color foreground) {
    final content = _chapterText.isEmpty ? '该小说没有可显示的章节内容。' : _chapterText;
    final text = Text(content, style: TextStyle(color: foreground, fontSize: _fontSize, height: 1.8));
    if (!_paged) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        child: text,
      );
    }
    return PageView(
      controller: _pageController,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
          child: SingleChildScrollView(child: text),
        ),
      ],
    );
  }

  Widget _buildComic() {
    if (_images.isEmpty) return const Center(child: Text('章节图片地址为空'));
    if (!_paged) {
      return ListView.builder(
        controller: _scrollController,
        itemCount: _images.length,
        itemBuilder: (_, i) => Image.network(
          _images[i],
          fit: BoxFit.fitWidth,
          errorBuilder: (_, __, ___) => const SizedBox(height: 240, child: Icon(Icons.broken_image, size: 60)),
        ),
      );
    }
    return PageView.builder(
      controller: _pageController,
      itemCount: _images.length,
      itemBuilder: (_, i) => InteractiveViewer(
        minScale: .5,
        maxScale: 4,
        child: Center(child: Image.network(
          _images[i],
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60),
        )),
      ),
    );
  }

  Widget _buildBottomBar(Color foreground) {
    final count = widget.item.episodes.length;
    return BottomAppBar(
      color: _night ? const Color(0xff202124) : Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, color: foreground),
            onPressed: _index > 0 ? () => _changeChapter(_index - 1) : null,
          ),
          Expanded(
            child: Slider(
              value: count == 0 ? 0 : _index.toDouble(),
              min: 0,
              max: count <= 1 ? 1 : (count - 1).toDouble(),
              onChanged: count == 0 ? null : (value) => _changeChapter(value.round()),
            ),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: foreground),
            onPressed: _index + 1 < count ? () => _changeChapter(_index + 1) : null,
          ),
          if (_isNovel) ...[
            IconButton(
              icon: Icon(Icons.text_decrease, color: foreground),
              onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12, 30).toDouble()),
            ),
            IconButton(
              icon: Icon(Icons.text_increase, color: foreground),
              onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12, 30).toDouble()),
            ),
          ],
        ],
      ),
    );
  }
}
