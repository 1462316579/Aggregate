/// 投屏设备模型
enum CastDeviceType {
  mediaRenderer,
  mediaServer,
}

class CastDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final CastDeviceType type;
  final String baseUrl;

  CastDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.type,
    required this.baseUrl,
  });
}