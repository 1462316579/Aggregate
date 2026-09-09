import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AIService {
  /// 发送请求到 AI API
  static Future<String?> chat({
    required String message,
    required String apiUrl,
    required String apiKey,
    required String model,
  }) async {
    if (apiUrl.isEmpty || apiKey.isEmpty) return '未配置 API 地址或 Key';

    final uri = Uri.parse(apiUrl);

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'messages': [
            <String, dynamic>{
              'role': 'user',
              'content': message,
            },
          ],
          'model': model,
        }),
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] is List && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? '';
        }
        return response.body;
      } else {
        return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      return '错误: ${e.toString()}';
    }
  }

  /// 发送多轮对话
  static Future<String?> chatHistory({
    required List<Map<String, String>> messages,
    required String apiUrl,
    required String apiKey,
    required String model,
  }) async {
    if (apiUrl.isEmpty || apiKey.isEmpty) return '未配置 API 地址或 Key';

    final uri = Uri.parse(apiUrl);
    final formattedMessages = messages.map((m) => <String, dynamic>{
      'role': m['role'] ?? 'user',
      'content': m['content'] ?? '',
    }).toList();

    try {
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'messages': formattedMessages,
          'model': model,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['choices'] is List && data['choices'].isNotEmpty) {
          return data['choices'][0]['message']['content'] ?? '';
        }
        return response.body;
      } else {
        return 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      }
    } catch (e) {
      return '错误: ${e.toString()}';
    }
  }

  /// 获取系统提示词（用于 AI 助手角色）
  static String getSystemPrompt(String context) {
    return '''你是一个专业的插件开发助手。用户正在开发一个 Flutter 爬虫插件，使用 JavaScript 编写。

$context

请帮助用户：
1. 分析代码问题并提供修复方案
2. 生成符合规范的插件代码
3. 调试搜索功能并返回正确的数据结构

搜索函数应返回以下格式：
{
  "code": 0,
  "msg": "",
  "data": {
    "list": [
      {
        "vod_id": "ID",
        "vod_name": "名称",
        "vod_pic": "封面图URL",
        "vod_remarks": "备注",
        "vod_year": "年份",
        "vod_area": "地区",
        "vod_actor": "演员",
        "vod_director": "导演",
        "vod_content": "简介",
        "vod_play_from": "播放源",
        "vod_play_url": "播放链接"
      }
    ]
  }
}''';
  }
}
