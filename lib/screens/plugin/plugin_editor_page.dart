import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../l10n/app_localizations.dart';
import '../../services/app_config.dart';
import '../../services/plugin_service.dart';

class PluginEditorPage extends StatefulWidget {
  final Map<String, dynamic>? plugin;

  const PluginEditorPage({this.plugin, super.key});

  @override
  State<PluginEditorPage> createState() => _PluginEditorPageState();
}

class _PluginEditorPageState extends State<PluginEditorPage> {
  late final TextEditingController _codeController;
  late final TextEditingController _nameController;
  late final TextEditingController _searchInputController;
  String _currentMessage = '';
  List<Map<String, String>> _messages = [];
  bool _isAiThinking = false;

  @override
  void initState() {
    super.initState();
    final plugin = widget.plugin;
    _codeController = TextEditingController(text: plugin?['code'] ?? '');
    _nameController = TextEditingController(text: plugin?['name'] ?? '');
    _searchInputController = TextEditingController();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _searchInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(AppConfig.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(plugin == null ? appStrings.t('addPlugin') : appStrings.t('editPlugin')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePlugin,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: appStrings.t('aiChat'),
            onPressed: _openAIChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // 插件名称输入
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: appStrings.t('pluginName'),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          // 代码编辑器
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _codeController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: appStrings.t('pluginCode'),
                  border: const OutlineInputBorder(),
                  hintText: '输入 JavaScript 插件代码...',
                ),
              ),
            ),
          ),
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bug),
                    label: Text(appStrings.t('debug')),
                    onPressed: _debugCode,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.search),
                    label: Text(appStrings.t('testSearch')),
                    onPressed: _testSearch,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? get plugin => widget.plugin;

  void _savePlugin() async {
    final code = _codeController.text.trim();
    final name = _nameController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('代码不能为空');
      return;
    }

    final isUpdate = plugin != null;
    await PluginService.save({
      'id': plugin?['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'language': 'javascript',
      'code': code,
      'description': '',
      'createdAt': DateTime.now().toIso8601String(),
    });

    if (!mounted) return;
    _showSnackBar(isUpdate ? '插件已更新' : '插件已创建');
    Navigator.pop(context);
  }

  Future<void> _debugCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('代码不能为空');
      return;
    }

    setState(() => _isAiThinking = true);

    final result = await AIService.chat(
      message: '''分析以下 JavaScript 插件代码的错误：\n\n$code

请指出语法错误、逻辑问题，并提供修复后的完整代码。''',
      apiUrl: AppConfig.aiApiUrl,
      apiKey: AppConfig.aiApiKey,
      model: AppConfig.aiModel,
    );

    setState(() => _isAiThinking = false);

    if (!mounted) return;
    if (result != null) {
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('调试结果'),
          content: SingleChildScrollView(
            child: SelectableText(result),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
            FilledButton(
              onPressed: () {
                // 应用 AI 建议的修复
                _applyAIRecommendation(result);
              },
              child: const Text('应用建议'),
            ),
          ],
        ),
      );
    }
  }

  void _applyAIRecommendation(String aiResponse) {
    // 尝试从 AI 响应中提取代码
    final codeMatch = RegExp(r'\`\`\`(?:javascript)?\s*([\s\S]*?)\`\`\`').firstMatch(aiResponse);
    if (codeMatch != null) {
      final newCode = codeMatch.group(1)?.trim() ?? '';
      if (newCode.isNotEmpty) {
        setState(() {
          _codeController.text = newCode;
        });
      }
    }
  }

  Future<void> _testSearch() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      _showSnackBar('代码不能为空');
      return;
    }

    // 简单的搜索测试：检查代码中是否有 search 函数
    final hasSearch = code.contains('function search') ||
        code.contains('async function search');

    if (!hasSearch) {
      _showSnackBar('代码中未检测到 search 函数');
      return;
    }

    // 调用 AI 测试搜索逻辑
    setState(() => _isAiThinking = true);

    final result = await AIService.chat(
      message: '''请分析以下搜索函数的实现，并说明如何正确返回数据：

[code_start]
$code
[code_end]

请检查：
1. 搜索参数是否正确解析
2. 数据格式化是否符合规范
3. 网络请求是否正确处理''',
      apiUrl: AppConfig.aiApiUrl,
      apiKey: AppConfig.aiApiKey,
      model: AppConfig.aiModel,
    );

    setState(() => _isAiThinking = false);

    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('搜索测试分析'),
        content: SingleChildScrollView(
          child: SelectableText(result ?? '无响应'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _openAIChat() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const AIChatScreen(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      // 应用 AI 生成的代码
      setState(() {
        _codeController.text = result;
      });
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// AI 聊天屏幕
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isThinking = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appStrings = AppStrings.of(AppConfig.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings.t('aiChat')),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空对话',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(msg['content'] ?? ''),
                  ),
                );
              },
            ),
          ),
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 8),
                  Text('AI 思考中...'),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: appStrings.t('aiChatHint'),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.chat),
                    ),
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text(appStrings.t('send')),
                  onPressed: _isThinking ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    // 添加用户消息
    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isThinking = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // 发送到 AI
    final response = await _callAI(message);

    // 添加 AI 回复
    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isThinking = false;
    });

    _scrollToBottom();
  }

  Future<String> _callAI(String userMessage) async {
    final configName = AppConfig.aiConfigName;
    final apiUrl = AppConfig.aiApiUrl;
    final apiKey = AppConfig.aiApiKey;
    final model = AppConfig.aiModel;

    // 构建带上下文的提示
    final contextMessage = '''当前插件代码:
${_codeContext}

用户问题: $userMessage''';

    try {
      final result = await AIService.chat(
        message: contextMessage,
        apiUrl: apiUrl,
        apiKey: apiKey,
        model: model,
      );
      return result ?? '未收到响应';
    } catch (e) {
      return '错误: ${e.toString()}';
    }
  }

  String get _codeContext {
    // 从父页面获取代码上下文
    // 这里简化处理，实际应该通过回调传递
    return '[代码上下文]';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
