/// WebDAV 备份服务 — 同步配置/历史/收藏到 WebDAV 服务器
/// 兼容 ZYFun / 亦搜 / ZYPlayer 的 WebDAV 接口
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/video_source.dart';
import '../services/app_config.dart';

class WebDavService {
  String _host = '';
  String _username = '';
  String _password = '';
  String _remotePath = '/AllPlay/';
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get host => _host;

  /// 初始化 (从本地配置加载)
  Future<void> init() async {
    // 从 SharedPreferences 加载 WebDAV 配置
    _host = await _loadConfig('webdav_host') ?? '';
    _username = await _loadConfig('webdav_user') ?? '';
    _password = await _loadConfig('webdav_pass') ?? '';
    _remotePath = await _loadConfig('webdav_path') ?? '/AllPlay/';
    if (_host.isNotEmpty) _isConnected = true;
  }

  /// 保存 WebDAV 配置
  Future<void> saveConfig({
    required String host,
    required String username,
    required String password,
    String remotePath = '/AllPlay/',
  }) async {
    _host = host;
    _username = username;
    _password = password;
    _remotePath = remotePath;
    await _saveConfig('webdav_host', host);
    await _saveConfig('webdav_user', username);
    await _saveConfig('webdav_pass', password);
    await _saveConfig('webdav_path', remotePath);
    _isConnected = true;
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      final response = await _webDavRequest('PROPFIND', '/');
      return response.statusCode == 207 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// ═══ 备份数据 ═══
  Future<WebDavResult> backup() async {
    try {
      // 收集所有数据
      final backupData = {
        'version': '1.0.0',
        'appVersion': '1.0.0',
        'backupTime': DateTime.now().toIso8601String(),
        'data': {
          // 源配置
          'sources': (await AppConfig.getSources()).map((s) => s.toJson()).toList(),
          // 观看历史
          'history': await AppConfig.getHistory(),
          // 收藏
          'favorites': await AppConfig.getFavorites(),
          // 搜索历史
          'searchHistory': await AppConfig.getSearchHistory(),
        },
      };

      final json = const JsonEncoder.withIndent('  ').convert(backupData);

      // 上传到 WebDAV
      final response = await _webDavRequest(
        'PUT',
        '${_remotePath}backup_${DateTime.now().millisecondsSinceEpoch}.json',
        body: json,
        contentType: 'application/json',
      );

      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
        return WebDavResult(true, '备份成功', _formatSize(json.length));
      }
      return WebDavResult(false, '备份失败: HTTP ${response.statusCode}', '');
    } catch (e) {
      return WebDavResult(false, '备份失败: $e', '');
    }
  }

  /// ═══ 恢复数据 ═══
  Future<WebDavResult> restore() async {
    try {
      // 获取最新的备份文件
      final listResult = await _webDavRequest('PROPFIND', _remotePath, depth: 1);
      if (listResult.statusCode != 207 && listResult.statusCode != 200) {
        return WebDavResult(false, '无法获取备份列表', '');
      }

      // 解析文件列表 (简化版)
      final files = _parseWebDavResponse(listResult.body);
      final backupFiles = files.where((f) => f.endsWith('.json')).toList();
      if (backupFiles.isEmpty) {
        return WebDavResult(false, '未找到备份文件', '');
      }

      // 下载最新备份
      final latestFile = backupFiles.last;
      final downloadResult = await _webDavRequest('GET', '$_remotePath$latestFile');
      if (downloadResult.statusCode != 200) {
        return WebDavResult(false, '下载备份失败', '');
      }

      final backupData = jsonDecode(downloadResult.body);
      final data = backupData['data'];

      // 恢复源配置
      if (data['sources'] != null) {
        final sources = (data['sources'] as List)
            .map((s) => VideoSource.fromJson(s))
            .toList();
        await AppConfig.saveSources(sources);
      }

      // 恢复历史
      if (data['history'] != null) {
        await AppConfig.saveHistory(List<Map<String, dynamic>>.from(data['history']));
      }

      // 恢复收藏
      if (data['favorites'] != null) {
        await AppConfig.saveFavorites(List<Map<String, dynamic>>.from(data['favorites']));
      }

      return WebDavResult(true,
          '恢复成功\n源: ${(data['sources'] as List?)?.length ?? 0} 个\n'
          '历史: ${(data['history'] as List?)?.length ?? 0} 条\n'
          '收藏: ${(data['favorites'] as List?)?.length ?? 0} 个',
          '');
    } catch (e) {
      return WebDavResult(false, '恢复失败: $e', '');
    }
  }

  /// 获取备份列表
  Future<List<WebDavBackupInfo>> getBackupList() async {
    try {
      final result = await _webDavRequest('PROPFIND', _remotePath, depth: 1);
      if (result.statusCode != 207 && result.statusCode != 200) return [];

      final files = _parseWebDavResponse(result.body);
      return files
          .where((f) => f.endsWith('.json'))
          .map((f) => WebDavBackupInfo(
            filename: f,
            path: '$_remotePath$f',
            size: '',
            time: DateTime.now(),
          ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 删除备份
  Future<bool> deleteBackup(String filename) async {
    try {
      final response = await _webDavRequest('DELETE', '$_remotePath$filename');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ═══ WebDAV HTTP 请求 ═══

  Future<http.Response> _webDavRequest(
    String method,
    String path, {
    String? body,
    String? contentType,
    int depth = 0,
  }) async {
    final uri = Uri.parse('$_host$path');
    final headers = <String, String>{
      'Authorization': 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}',
      'User-Agent': 'AllPlay/1.0',
    };

    if (depth > 0) headers['Depth'] = depth.toString();
    if (contentType != null) headers['Content-Type'] = contentType;

    switch (method) {
      case 'PUT':
      case 'POST':
        return http.put(uri, headers: headers, body: body);
      case 'DELETE':
        return http.delete(uri, headers: headers);
      case 'PROPFIND':
        return http.request('PROPFIND', uri: uri, headers: headers, body: body);
      default:
        return http.get(uri, headers: headers);
    }
  }

  List<String> _parseWebDavResponse(String xml) {
    // 简化解析: 提取 href 标签中的文件名
    final files = <String>[];
    final regex = RegExp(r'<d:href>([^<]+)</d:href>', caseSensitive: false);
    for (var match in regex.allMatches(xml)) {
      final href = match.group(1) ?? '';
      final filename = Uri.decodeFull(href.split('/').last);
      if (filename.isNotEmpty && filename != '/') files.add(filename);
    }
    return files;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  // ═══ 本地配置读写 (简化版) ═══

  Future<String?> _loadConfig(String key) async {
    // 实际使用 SharedPreferences
    return null;
  }

  Future<void> _saveConfig(String key, String value) async {
    // 实际使用 SharedPreferences
  }
}

class WebDavResult {
  final bool success;
  final String message;
  final String size;
  WebDavResult(this.success, this.message, this.size);
}

class WebDavBackupInfo {
  final String filename;
  final String path;
  final String size;
  final DateTime time;
  WebDavBackupInfo({
    required this.filename,
    required this.path,
    required this.size,
    required this.time,
  });
}
