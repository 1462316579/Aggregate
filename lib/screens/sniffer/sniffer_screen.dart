/// 影视嗅探主界面
/// 功能: URL输入 → WebView加载 → 自动嗅探视频流 → 展示结果 → 一键播放
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/sniff_result.dart';
import '../../services/video_sniffer_service.dart';
import '../../providers/player_provider.dart';
import '../../providers/source_provider.dart';
import '../../models/video_source.dart';
import '../player/player_screen.dart';

class SnifferScreen extends StatefulWidget {
  const SnifferScreen({super.key});

  @override
  State<SnifferScreen> createState() => _SnifferScreenState();
}

class _SnifferScreenState extends State<SnifferScreen> {
  final _urlController = TextEditingController();
  final _urlFocusNode = FocusNode();
  late WebViewController _webViewController;

  List<SniffResult> _results = [];
  bool _isLoading = false;
  bool _isSniffing = false;
  String _currentUrl = '';
  String _pageTitle = '';
  int _sniffCount = 0;
  bool _showWebView = false;
  SniffProtocol? _filterType;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _checkClipboard();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (url) {
          setState(() {
            _currentUrl = url;
            _isLoading = true;
          });
        },
        onPageFinished: (url) async {
          setState(() {
            _isLoading = false;
            _currentUrl = url;
          });
          // 页面加载完成后，分析 HTML 源码
          await _analyzeCurrentPage();
        },
        // 关键: 拦截所有资源加载请求
        onNavigationRequest: (request) {
          final url = request.url;
          // 对每个请求进行视频嗅探
          _sniffRequest(url, referer: _currentUrl);
          return NavigationDecision.navigate;
        },
        onWebResourceError: (error) {
          debugPrint('WebView error: ${error.description}');
        },
      ));
  }

  /// 检查剪贴板中是否有视频链接
  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.isNotEmpty) {
        final candidates = VideoSnifferService.detectFromText(data.text!);
        if (candidates.isNotEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('检测到剪贴板中 ${candidates.length} 个视频链接'),
                action: SnackBarAction(
                  label: '粘贴并嗅探',
                  onPressed: () {
                    _urlController.text = candidates.first.url;
                    _startSniff(_urlController.text);
                  },
                ),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (_) {}
  }

  /// 嗅探单个请求
  void _sniffRequest(String url, {String? referer}) {
    final candidates = VideoSnifferService.processWebViewRequest(
      url: url,
      referer: referer ?? _currentUrl,
    );

    if (candidates.isNotEmpty) {
      final results = candidates.map((c) => c.toResult(pageTitle: _pageTitle)).toList();
      _addResults(results);
    }
  }

  /// 分析当前页面 HTML
  Future<void> _analyzeCurrentPage() async {
    try {
      final html = await _webViewController.runJavaScriptReturningResult(
        'document.documentElement.outerHTML',
      );
      final pageTitle = await _webViewController.runJavaScriptReturningResult(
        'document.title',
      );

      setState(() {
        _pageTitle = pageTitle.toString().replaceAll('"', '');
      });

      if (html is String) {
        final candidates = VideoSnifferService.analyzeHtml(
          html, pageUrl: _currentUrl,
        );
        final results = candidates.map((c) =>
            c.toResult(pageTitle: _pageTitle)).toList();
        _addResults(results);
      }
    } catch (_) {}
  }

  void _addResults(List<SniffResult> newResults) {
    setState(() {
      for (var result in newResults) {
        if (!_results.contains(result)) {
          _results.add(result);
          _sniffCount++;
        }
      }
      // 按协议类型和置信度排序
      _results.sort((a, b) {
        // 可播放的排前面
        if (a.isPlayable && !b.isPlayable) return -1;
        if (!a.isPlayable && b.isPlayable) return 1;
        return b.timestamp.compareTo(a.timestamp);
      });
    });
  }

  /// 开始嗅探
  Future<void> _startSniff(String url) async {
    if (url.isEmpty) return;

    // 补全协议头
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    setState(() {
      _results = [];
      _sniffCount = 0;
      _showWebView = true;
      _currentUrl = url;
      _urlController.text = url;
    });

    _urlFocusNode.unfocus();
    await _webViewController.loadRequest(Uri.parse(url));
  }

  /// 粘贴剪贴板
  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  /// 从文本中嗅探
  void _sniffFromText() {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;

    if (text.startsWith('http')) {
      _startSniff(text);
    } else {
      // 当作文本分析
      final candidates = VideoSnifferService.detectFromText(text);
      if (candidates.isNotEmpty) {
        final results = candidates.map((c) => c.toResult()).toList();
        _addResults(results);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('从文本中嗅探到 ${results.length} 个视频链接')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未检测到视频链接')),
        );
      }
    }
  }

  /// 播放嗅探到的视频
  void _playResult(SniffResult result) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerScreen(
        title: result.pageTitle ?? _pageTitle ?? '嗅探播放',
        url: result.url,
      ),
    ));
  }

  /// 复制 URL
  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板'), duration: Duration(seconds: 1)),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTV = MediaQuery.of(context).size.width > 960;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            const Text('影视嗅探'),
            const Spacer(),
            if (_sniffCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$_sniffCount',
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          if (_results.isNotEmpty)
            PopupMenuButton<SniffProtocol?>(
              icon: const Icon(Icons.filter_list),
              tooltip: '筛选类型',
              onSelected: (type) => setState(() => _filterType = type),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('全部')),
                ...SniffProtocol.values.where((p) =>
                    _results.any((r) => r.protocol == p)
                ).map((p) => PopupMenuItem(
                    value: p, child: Text('${p.label} (${_results.where((r) => r.protocol == p).length})'))),
              ],
            ),
          if (_results.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: '清空结果',
              onPressed: () => setState(() { _results.clear(); _sniffCount = 0; }),
            ),
        ],
      ),
      body: Column(
        children: [
          // URL 输入栏
          _buildInputBar(),
          // WebView (可收起)
          if (_showWebView) _buildWebViewPanel(isTV),
          // 分割线
          if (_showWebView)
            Container(
              height: 1,
              color: Colors.grey[800],
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[700])),
                  GestureDetector(
                    onTap: () => setState(() => _showWebView = !_showWebView),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.drag_handle,
                          size: 16, color: Colors.grey[500]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[700])),
                ],
              ),
            ),
          // 嗅探结果列表
          Expanded(child: _buildResultsList()),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12, MediaQuery.of(context).padding.top + 4, 12, 4),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          // 粘贴按钮
          IconButton(
            icon: const Icon(Icons.content_paste, size: 20),
            onPressed: _pasteFromClipboard,
            tooltip: '粘贴',
          ),
          // URL 输入框
          Expanded(
            child: TextField(
              controller: _urlController,
              focusNode: _urlFocusNode,
              decoration: InputDecoration(
                hintText: '输入网址嗅探 / 粘贴视频链接 / 输入文本检测',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
                suffixIcon: _urlController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _urlController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: 13),
              onSubmitted: (_) => _sniffFromText(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          // 嗅探按钮
          Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: _isLoading ? null : _sniffFromText,
              tooltip: '开始嗅探',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebViewPanel(bool isTV) {
    return Container(
      height: isTV ? 250 : 200,
      color: Colors.black,
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          // 遮罩层 + 控制
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // 刷新
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                    onPressed: () => _webViewController.reload(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  // 当前 URL
                  Expanded(
                    child: Text(_currentUrl,
                        style: const TextStyle(color: Colors.white70, fontSize: 10),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  // 加载指示器
                  if (_isLoading)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  const SizedBox(width: 8),
                  // 收起/展开
                  IconButton(
                    icon: Icon(_showWebView
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_up,
                        color: Colors.white, size: 18),
                    onPressed: () => setState(() => _showWebView = !_showWebView),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_results.isEmpty) {
      return _buildEmptyState();
    }

    final filtered = _filterType != null
        ? _results.where((r) => r.protocol == _filterType).toList()
        : _results;

    return Column(
      children: [
        // 结果统计
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.radar, size: 16, color: Colors.blue[400]),
              const SizedBox(width: 6),
              Text('嗅探到 ${filtered.length} 个资源',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400])),
              const Spacer(),
              // 按类型统计
              ...SniffProtocol.values.where((p) =>
                  _results.any((r) => r.protocol == p)
              ).take(4).map((p) => Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('${p.label} ${_results.where((r) => r.protocol == p).length}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                  )),
            ],
          ),
        ),
        // 结果列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (context, index) => _buildResultCard(filtered[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(SniffResult result) {
    final typeColors = {
      SniffProtocol.m3u8: Colors.green,
      SniffProtocol.mp4: Colors.blue,
      SniffProtocol.flv: Colors.orange,
      SniffProtocol.ts: Colors.purple,
      SniffProtocol.mkv: Colors.teal,
      SniffProtocol.api: Colors.red,
    };
    final color = typeColors[result.protocol] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: result.isPlayable ? () => _playResult(result) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部: 类型标签 + 操作按钮
              Row(
                children: [
                  // 协议类型
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(result.protocol.label,
                        style: TextStyle(color: color, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  // 画质标签
                  if (result.quality != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(result.quality!,
                          style: const TextStyle(
                              color: Colors.amber, fontSize: 10)),
                    ),
                  const Spacer(),
                  // 可播放标记
                  if (result.isPlayable)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle, color: Colors.green, size: 12),
                          SizedBox(width: 2),
                          Text('可播放',
                              style: TextStyle(
                                  color: Colors.green, fontSize: 10)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 标题
              if (result.pageTitle != null && result.pageTitle!.isNotEmpty)
                Text(result.pageTitle!,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              // URL
              Text(result.url,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500], fontFamily: 'monospace'),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              // 底部信息行
              Row(
                children: [
                  // 来源
                  if (result.referer != null && result.referer!.isNotEmpty) ...[
                    Icon(Icons.language, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(Uri.parse(result.referer!).host,
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  // 文件大小
                  if (result.contentLength != null) ...[
                    Icon(Icons.storage, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(result.fileSize,
                        style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                  const Spacer(),
                  // 操作按钮
                  // 复制
                  _actionButton(
                    icon: Icons.copy,
                    tooltip: '复制链接',
                    onTap: () => _copyUrl(result.url),
                  ),
                  const SizedBox(width: 4),
                  // 播放
                  if (result.isPlayable)
                    _actionButton(
                      icon: Icons.play_arrow,
                      tooltip: '播放',
                      color: Colors.green,
                      onTap: () => _playResult(result),
                    ),
                  // 详情
                  _actionButton(
                    icon: Icons.info_outline,
                    tooltip: '详情',
                    onTap: () => _showResultDetail(result),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String tooltip,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color ?? Colors.grey[400]),
        ),
      ),
    );
  }

  void _showResultDetail(SniffResult result) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600], borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 16),
            Text('资源详情',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _detailRow('协议', result.protocol.label),
            _detailRow('类型', result.protocol.desc),
            if (result.quality != null) _detailRow('画质', result.quality!),
            if (result.mimeType != null) _detailRow('MIME', result.mimeType!),
            if (result.contentLength != null) _detailRow('大小', result.fileSize),
            _detailRow('来源', result.referer ?? '未知'),
            const SizedBox(height: 8),
            // URL (可复制)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(result.url,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('复制链接'),
                    onPressed: () { _copyUrl(result.url); Navigator.pop(ctx); },
                  ),
                ),
                const SizedBox(width: 12),
                if (result.isPlayable)
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('播放'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () { _playResult(result); Navigator.pop(ctx); },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 60, child: Text(label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12))),
          Expanded(child: Text(value,
              style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 雷达动画图标
          Icon(Icons.radar, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 20),
          Text('影视嗅探',
              style: TextStyle(color: Colors.grey[400], fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('输入网址，自动嗅探页面中的视频资源',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          // 功能说明
          Container(
            width: 320,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _featureItem(Icons.language, '网址嗅探', '输入视频网站地址，自动拦截视频流'),
                const SizedBox(height: 8),
                _featureItem(Icons.content_paste, '剪贴板检测', '自动检测剪贴板中的视频链接'),
                const SizedBox(height: 8),
                _featureItem(Icons.text_snippet, '文本分析', '粘贴包含视频地址的文本内容'),
                const SizedBox(height: 8),
                _featureItem(Icons.play_circle, '一键播放', '嗅探到的视频可直接播放'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String title, String desc) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[400], size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold)),
            Text(desc, style: TextStyle(
                fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }
}
