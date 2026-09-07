import 'builtin_bt_server.dart';
import 'eso_mcp_service.dart';
import 'source_service.dart';
import '../models/content.dart';

/// Application-owned services. BT and MCP run locally and are not exposed as
/// user-configurable BT-server settings.
class AppServices {
  final BuiltInBtServer btServer;
  late final EsoMcpService mcpServer;

  AppServices({
    BuiltInBtServer? btServer,
    List<SourceDefinition> Function()? sourceReader,
  }) : btServer = btServer ?? BuiltInBtServer() {
    mcpServer = EsoMcpService(
      sourceService: const SourceService(),
      btServer: this.btServer,
      sources: sourceReader ?? () => const <SourceDefinition>[],
    );
  }

  Future<void> startBuiltInServices() async {
    // These are optional local integrations. Never let them block app startup.
    try {
      await btServer.start().timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      await mcpServer.start().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await mcpServer.stop();
    await btServer.stop();
  }
}
