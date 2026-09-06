import 'package:flutter/material.dart';
import 'package:hongxi/models/content.dart';

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
  final _pageController = PageController();
  final _scrollController = ScrollController();

  bool get _isNovel => widget.item.type == ContentType.novel;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.item.episodes.isEmpty ? 0 : widget.item.episodes.length - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = _night ? const Color(0xff202124) : const Color(0xfffffbf2);
    final foreground = _night ? Colors.white70 : const Color(0xff333333);
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: Text(widget.item.title),
        backgroundColor: background,
        foregroundColor: foreground,
        actions: [
          IconButton(icon: Icon(_night ? Icons.light_mode : Icons.dark_mode), onPressed: () => setState(() => _night = !_night)),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'paged') setState(() => _paged = true);
              if (value == 'scroll') setState(() => _paged = false);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'paged', child: Text('翻页模式')),
              PopupMenuItem(value: 'scroll', child: Text('滚动模式')),
            ],
          ),
        ],
      ),
      body: _isNovel ? _buildNovel(background, foreground) : _buildComic(),
      bottomNavigationBar: _buildBottomBar(foreground),
    );
  }

  Widget _buildNovel(Color background, Color foreground) {
    final text = widget.item.episodes.isEmpty
        ? '该小说暂时没有章节内容。请检查源接口返回的 chapters 或 chapterList 字段。'
        : widget.item.episodes[_index].url;
    final content = text.isEmpty ? '章节内容为空。' : text;
    if (!_paged) {
      return SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
        child: Text(content, style: TextStyle(color: foreground, fontSize: _fontSize, height: 1.8)),
      );
    }
    return PageView(
      controller: _pageController,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 40),
          child: SingleChildScrollView(child: Text(content, style: TextStyle(color: foreground, fontSize: _fontSize, height: 1.8))),
        ),
      ],
    );
  }

  Widget _buildComic() {
    final image = widget.item.episodes.isEmpty ? '' : widget.item.episodes[_index].url;
    if (image.isEmpty) return const Center(child: Text('章节图片地址为空'));
    return _paged
        ? PageView.builder(
            controller: _pageController,
            itemCount: widget.item.episodes.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: .5, maxScale: 4,
              child: Center(child: Image.network(widget.item.episodes[i].url, fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60))),
            ),
          )
        : ListView.builder(
            controller: _scrollController,
            itemCount: widget.item.episodes.length,
            itemBuilder: (_, i) => Image.network(widget.item.episodes[i].url, fit: BoxFit.fitWidth,
              errorBuilder: (_, __, ___) => const SizedBox(height: 240, child: Icon(Icons.broken_image, size: 60))),
          );
  }

  Widget _buildBottomBar(Color foreground) {
    final count = widget.item.episodes.length;
    return BottomAppBar(
      color: _night ? const Color(0xff202124) : Colors.white,
      child: Row(children: [
        IconButton(icon: Icon(Icons.skip_previous, color: foreground), onPressed: _index > 0 ? () => setState(() => _index--) : null),
        Expanded(child: Slider(
          value: count == 0 ? 0 : _index.toDouble(),
          min: 0, max: count <= 1 ? 1 : (count - 1).toDouble(),
          onChanged: count == 0 ? null : (v) => setState(() => _index = v.round()),
        )),
        IconButton(icon: Icon(Icons.skip_next, color: foreground), onPressed: _index + 1 < count ? () => setState(() => _index++) : null),
        if (_isNovel) IconButton(icon: Icon(Icons.text_decrease, color: foreground), onPressed: () => setState(() => _fontSize = (_fontSize - 1).clamp(12, 30))),
        if (_isNovel) IconButton(icon: Icon(Icons.text_increase, color: foreground), onPressed: () => setState(() => _fontSize = (_fontSize + 1).clamp(12, 30))),
      ]),
    );
  }
}
