import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Built-in BT-server facade.
///
/// Eso's public project exposes BT playback as an application feature rather
/// than a user-configured server. This service follows that model: it starts
/// an app-owned local HTTP endpoint and keeps the BT transport hidden from
/// the settings screen. A native torrent engine can be attached later without
/// changing the MCP or player-facing API.
class BuiltInBtServer {
  HttpServer? _server;
  int? _port;
  String? _currentUri;
  bool _paused = false;

  bool get running => _server != null;
  int? get port => _port;
  String? get currentUri => _currentUri;
  bool get paused => _paused;

  Future<int> start({int preferredPort = 0}) async {
    if (_server != null) return _port!;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, preferredPort);
    _port = _server!.port;
    _server!.listen(_handleRequest);
    return _port!;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _port = null;
    _currentUri = null;
    _paused = false;
  }

  /// Start internal BT playback for a magnet or torrent URI.
  /// The endpoint is intentionally internal; UI does not expose server config.
  Future<Map<String, dynamic>> play(String uri) async {
    if (!uri.startsWith('magnet:') && !uri.toLowerCase().endsWith('.torrent')) {
      return <String, dynamic>{'ok': false, 'error': 'not a magnet or torrent URI'};
    }
    await start();
    _currentUri = uri;
    _paused = false;
    return status();
  }

  Future<void> pause() async => _paused = true;
  Future<void> resume() async => _paused = false;

  Map<String, dynamic> status() => <String, dynamic>{
    'running': running,
    'port': _port,
    'uri': _currentUri,
    'paused': _paused,
    'engine': 'built-in',
  };

  Future<void> _handleRequest(HttpRequest request) async {
    request.response.headers.contentType = ContentType.json;
    final path = request.uri.path;
    if (path == '/health' || path == '/status') {
      request.response.write(jsonEncode(status()));
    } else if (path == '/pause') {
      await pause();
      request.response.write(jsonEncode(status()));
    } else if (path == '/resume') {
      await resume();
      request.response.write(jsonEncode(status()));
    } else {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(jsonEncode(<String, dynamic>{'error': 'not found'}));
    }
    await request.response.close();
  }
}
