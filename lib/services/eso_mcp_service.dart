import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import '../models/content.dart';
import 'builtin_bt_server.dart';
import 'source_service.dart';

/// Local MCP-compatible JSON-RPC service inspired by eso's multi-source tools.
///
/// The eso repository itself does not contain a module named MCP. This is an
/// app-owned compatibility layer exposing the same useful operations as MCP
/// tools: source discovery, search, detail, music resolution and BT status.
class EsoMcpService {
  final SourceService sourceService;
  final BuiltInBtServer btServer;
  final List<SourceDefinition> Function() sources;
  io.HttpServer? _server;

  EsoMcpService({
    required this.sourceService,
    required this.btServer,
    required this.sources,
  });

  bool get running => _server != null;
  int? get port => _server?.port;

  Future<int> start({int preferredPort = 0}) async {
    if (_server != null) return _server!.port;
    _server = await io.HttpServer.bind(io.InternetAddress.loopbackIPv4, preferredPort);
    _server!.listen(_handleRequest);
    return _server!.port;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  Future<void> _handleRequest(io.HttpRequest request) async {
    request.response.headers.contentType = io.ContentType.json;
    if (request.method != 'POST') {
      request.response.statusCode = io.HttpStatus.methodNotAllowed;
      request.response.write(jsonEncode(_error(null, -32600, 'POST required')));
      await request.response.close();
      return;
    }

    try {
      final body = await utf8.decoder.bind(request).join();
      final rpc = jsonDecode(body);
      final response = await handleRpc(rpc is Map ? Map<String, dynamic>.from(rpc) : <String, dynamic>{});
      request.response.write(jsonEncode(response));
    } catch (error) {
      request.response.statusCode = io.HttpStatus.badRequest;
      request.response.write(jsonEncode(_error(null, -32700, '$error')));
    }
    await request.response.close();
  }

  Future<Map<String, dynamic>> handleRpc(Map<String, dynamic> request) async {
    final id = request['id'];
    final method = request['method']?.toString() ?? '';
    final params = request['params'] is Map ? Map<String, dynamic>.from(request['params']) : <String, dynamic>{};

    if (method == 'initialize') {
      return _result(id, <String, dynamic>{
        'protocolVersion': '2024-11-05',
        'serverInfo': <String, dynamic>{'name': 'hongxi-eso-mcp', 'version': '1.0.0'},
        'capabilities': <String, dynamic>{'tools': <String, dynamic>{}},
      });
    }
    if (method == 'tools/list') {
      return _result(id, <String, dynamic>{'tools': _tools()});
    }
    if (method == 'tools/call') {
      final name = params['name']?.toString() ?? '';
      final arguments = params['arguments'] is Map ? Map<String, dynamic>.from(params['arguments']) : <String, dynamic>{};
      return _result(id, await _callTool(name, arguments));
    }
    if (method == 'ping') return _result(id, <String, dynamic>{});
    return _error(id, -32601, 'Unknown method: $method');
  }

  List<Map<String, dynamic>> _tools() => <Map<String, dynamic>>[
    <String, dynamic>{'name': 'sources.list', 'description': 'List enabled media sources', 'inputSchema': _schema()},
    <String, dynamic>{'name': 'content.search', 'description': 'Search across enabled sources', 'inputSchema': _schema(<String, dynamic>{'query': <String, dynamic>{'type': 'string'}})},
    <String, dynamic>{'name': 'content.detail', 'description': 'Get content detail by source and id', 'inputSchema': _schema(<String, dynamic>{'sourceId': <String, dynamic>{'type': 'string'}, 'id': <String, dynamic>{'type': 'string'}})},
    <String, dynamic>{'name': 'music.resolve', 'description': 'Resolve a music item to a playable URL', 'inputSchema': _schema(<String, dynamic>{'sourceId': <String, dynamic>{'type': 'string'}, 'id': <String, dynamic>{'type': 'string'}})},
    <String, dynamic>{'name': 'bt.status', 'description': 'Get internal BT-server status', 'inputSchema': _schema()},
    <String, dynamic>{'name': 'bt.play', 'description': 'Play a magnet or torrent URI through internal BT service', 'inputSchema': _schema(<String, dynamic>{'uri': <String, dynamic>{'type': 'string'}})},
  ];

  Map<String, dynamic> _schema([Map<String, dynamic>? properties]) => <String, dynamic>{
    'type': 'object',
    'properties': properties ?? <String, dynamic>{},
  };

  Future<Map<String, dynamic>> _callTool(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'sources.list':
        return _toolResult(sources().where((s) => s.enabled).map((s) => s.toMap()).toList());
      case 'content.search':
        final query = args['query']?.toString() ?? '';
        final result = await Future.wait(sources().where((s) => s.enabled).map((s) => sourceService.search(s, query)));
        return _toolResult(result.expand((r) => r.items.map((i) => i.toMap())).toList());
      case 'content.detail':
        final source = sources().where((s) => s.id == args['sourceId']).firstOrNull;
        if (source == null) return _toolError('source not found');
        final item = await sourceService.detail(source, args['id']?.toString() ?? '');
        return _toolResult(item?.toMap());
      case 'music.resolve':
        final source = sources().where((s) => s.id == args['sourceId']).firstOrNull;
        if (source == null) return _toolError('source not found');
        final item = MediaItem(id: args['id']?.toString() ?? '', title: '', sourceId: source.id, type: ContentType.music);
        return _toolResult(<String, dynamic>{'url': await sourceService.resolveMusicUrl(source, item)});
      case 'bt.status':
        await btServer.start();
        return _toolResult(btServer.status());
      case 'bt.play':
        return _toolResult(await btServer.play(args['uri']?.toString() ?? ''));
      default:
        return _toolError('unknown tool');
    }
  }

  Map<String, dynamic> _toolResult(dynamic value) => <String, dynamic>{
    'content': <Map<String, dynamic>>[<String, dynamic>{'type': 'text', 'text': jsonEncode(value)}],
  };

  Map<String, dynamic> _toolError(String value) => <String, dynamic>{'isError': true, 'content': <Map<String, dynamic>>[<String, dynamic>{'type': 'text', 'text': value}]};
  Map<String, dynamic> _result(dynamic id, dynamic value) => <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'result': value};
  Map<String, dynamic> _error(dynamic id, int code, String message) => <String, dynamic>{'jsonrpc': '2.0', 'id': id, 'error': <String, dynamic>{'code': code, 'message': message}};
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
