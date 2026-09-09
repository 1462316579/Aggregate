import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/content.dart';
import 'app_config.dart';
import 'config_transfer_service.dart';
import '../providers/source_provider.dart';

/// WebDAV 备份服务 —— 兼容常见 WebDAV 服务器
/// (Nextcloud、Filebrowser、Seafile、坚果云、Alist、FastDFS 等)。
class WebDavService {
  WebDavService({this.baseUrl = '', this.username, this.password, this.rootPath = '/'});

  /// 例：https://cloud.example.com 或 http://192.168.1.100:8080
  final String baseUrl;
  final String? username;
  final String? password;
  final String rootPath;

  static WebDavService? fromConfig(AppConfig config) {
    if (AppConfig.webdavEnabled != true) return null;
    final url = AppConfig.webdavHost.trim();
    if (url.isEmpty) return null;
    var host = url;
    if (!RegExp(r'^https?://').hasMatch(host)) {
      host = 'https://$host';
    }
    return WebDavService(
      baseUrl: host,
      username: AppConfig.webdavUsername,
      password: AppConfig.webdavPassword,
      rootPath: AppConfig.webdavPath.isEmpty ? '/' : AppConfig.webdavPath,
    );
  }

  Uri _uri(String path) {
    final normalized = rootPath.endsWith('/')
        ? rootPath + path
        : '$rootPath/$path';
    return Uri.parse('$baseUrl$normalized');
  }

  String get _authHeader {
    if (username == null || username!.isEmpty) return '';
    final raw = '$username:$password';
    return 'Basic ${base64Encode(utf8.encode(raw))}';
  }

  Future<http.Response> _request(
    String method,
    String path, {
    http.Request? body,
    Map<String, String>? headers,
  }) async {
    final req = http.Request(method, _uri(path));
    if (_authHeader.isNotEmpty) {
      req.headers['Authorization'] = _authHeader;
    }
    if (headers != null) {
      req.headers.addAll(headers);
    }
    if (body != null) {
      req.bodyBytes = body.bodyBytes;
      req.headers.addAll(body.headers);
      req.body = body.body;
    }
    final client = http.Client();
    try {
      final streamed = await client.send(req);
      return await http.Response.fromStream(streamed);
    } finally {
      client.close();
    }
  }

  /// PROPFIND 用于检查文件是否存在。
  Future<bool> exists(String path) async {
    final res = await _request('PROPFIND', path);
    return res.statusCode == 200 || res.statusCode == 207;
  }

  /// MKCOL 创建目录（如果父目录不存在则逐级创建）。
  Future<bool> mkcolRecursive(String path) async {
    final parts = path.split('/').where((e) => e.isNotEmpty).toList();
    var current = '';
    for (final part in parts) {
      current += '$part/';
      final res = await _request('MKCOL', current);
      // 405 说明目录已存在，忽略
      if (res.statusCode == 201 || res.statusCode == 405) continue;
      return false;
    }
    return true;
  }

  /// PUT 上传文件；[createDirs] 为 true 时自动创建父目录。
  Future<bool> put(String path, String content, {bool createDirs = true}) async {
    if (createDirs) {
      final parent = path.contains('/')
          ? path.substring(0, path.lastIndexOf('/'))
          : '';
      if (parent.isNotEmpty && !await exists(parent)) {
        if (!await mkcolRecursive(parent)) return false;
      }
    }
    final req = http.Request('PUT', _uri(path));
    req.bodyBytes = utf8.encode(content);
    req.headers['Content-Type'] = 'application/json; charset=utf-8';
    final client = http.Client();
    try {
      final streamed = await client.send(req);
      final res = await http.Response.fromStream(streamed);
      return res.statusCode == 200 || res.statusCode == 201 || res.statusCode == 204;
    } finally {
      client.close();
    }
  }

  /// GET 下载文件内容为字符串。
  Future<String?> get(String path) async {
    final res = await _request('GET', path);
    if (res.statusCode == 200) return res.body;
    return null;
  }

  /// DELETE 删除文件。
  Future<bool> delete(String path) async {
    final res = await _request('DELETE', path);
    return res.statusCode == 200 || res.statusCode == 204;
  }

  /// 测试连接是否可用。
  Future<bool> ping() async {
    final res = await _request('PROPFIND', rootPath.isEmpty ? '/' : rootPath);
    return res.statusCode == 200 || res.statusCode == 207;
  }

  /// 列出目录内容（返回相对路径）。
  Future<List<String>> listDir(String dir) async {
    final res = await _request('PROPFIND', dir);
    if (res.statusCode != 200 && res.statusCode != 207) return <String>[];
    final result = <String>[];
    // 简单从 XML 响应里抽取 href
    final re = RegExp(r'<(?:[^:>]*:)?href>([^<]+)</(?:[^:>]*:)?href>');
    for (final match in re.allMatches(res.body)) {
      final href = Uri.decodeComponent(match.group(1)!);
      // 过滤出目录下的直接子项
      final parts = href.split('/').where((e) => e.isNotEmpty).toList();
      final dirParts = dir.split('/').where((e) => e.isNotEmpty).toList();
      if (href.endsWith('/')) continue;
      if (parts.length == dirParts.length + 1 &&
          dirParts.every((p) => parts[dirParts.indexOf(p)] == p)) {
        result.add(parts.last);
      }
    }
    result.sort();
    return result;
  }

  /// 列出根目录下的备份文件（*.json）。
  Future<List<String>> listBackups() async {
    final dir = rootPath.isEmpty ? '/' : rootPath;
    final files = await listDir(dir);
    return files.where((f) => f.endsWith('.json')).toList();
  }
}

/// 备份/恢复工具：把当前源列表 + 播放设置 + 收藏/历史打包成一个 JSON。
class BackupService {
  BackupService(this._config, this._sources);
  // ignore: unused_field
  final AppConfig _config;
  final List<SourceDefinition> _sources;

  Map<String, dynamic> buildBackup() {
    return <String, dynamic>{
      'format': 'hongxi-backup',
      'version': 1,
      'appVersion': '1.0.0',
      'createdAt': DateTime.now().toIso8601String(),
      'sources': _sources.map((e) => e.toMap()).toList(),
      'settings': <String, dynamic>{
        'language': AppConfig.language,
        'theme': AppConfig.theme,
        'tmdbKey': AppConfig.tmdbKey,
        'autoCheckUpdate': AppConfig.autoCheckUpdate,
        'nsfw': AppConfig.nsfw,
        'webdavEnabled': AppConfig.webdavEnabled,
        'webdavHost': AppConfig.webdavHost,
        'webdavUsername': AppConfig.webdavUsername,
        // 密码故意不写入云端备份，恢复后由用户重新填入
        'webdavPassword': '',
        'webdavPath': AppConfig.webdavPath,
      },
      'favorites': AppConfig.favorites,
      'history': AppConfig.history,
    };
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(buildBackup());

  Future<void> backupTo(String remotePath, WebDavService service) async {
    final json = exportJson();
    final ok = await service.put(remotePath, json, createDirs: true);
    if (!ok) throw Exception('备份上传失败');
  }

  Future<void> restoreFrom(String remotePath, WebDavService service) async {
    final raw = await service.get(remotePath);
    if (raw == null) throw Exception('备份文件不存在或无法读取');
    return applyBackup(raw);
  }

  Future<void> applyBackup(String json) async {
    final decoded = jsonDecode(json);
    if (decoded is! Map) throw Exception('备份文件格式错误');
    final root = Map<String, dynamic>.from(decoded);

    // 源列表
    final sources = root['sources'];
    if (sources is List) {
      final imported = ConfigTransferService.importSources(jsonEncode({
        'format': 'hongxi-sources',
        'sources': sources,
      }));
      await AppConfig.saveSources(imported);
    }

    // 设置项
    final settings = root['settings'];
    if (settings is Map) {
      final s = Map<String, dynamic>.from(settings);
      if (s['language'] is String) await AppConfig.setLanguage(s['language'] as String);
      if (s['theme'] is String) await AppConfig.setTheme(s['theme'] as String);
      if (s['tmdbKey'] is String) await AppConfig.setTmdbKey(s['tmdbKey'] as String);
      if (s['autoCheckUpdate'] is bool) await AppConfig.setAutoCheckUpdate(s['autoCheckUpdate'] as bool);
      if (s['nsfw'] is bool) await AppConfig.setNsfw(s['nsfw'] as bool);
      if (s['webdavEnabled'] is bool) await AppConfig.setWebdavEnabled(s['webdavEnabled'] as bool);
      if (s['webdavHost'] is String) await AppConfig.setWebdavHost(s['webdavHost'] as String);
      if (s['webdavUsername'] is String) await AppConfig.setWebdavUsername(s['webdavUsername'] as String);
      if (s['webdavPath'] is String) await AppConfig.setWebdavPath(s['webdavPath'] as String);
    }

    // 收藏与历史
    if (root['favorites'] is List) {
      await AppConfig.setFavorites(
        (root['favorites'] as List).cast<Map<String, dynamic>>(),
      );
    }
    if (root['history'] is List) {
      await AppConfig.setHistory(
        (root['history'] as List).cast<Map<String, dynamic>>(),
      );
    }
  }
}
