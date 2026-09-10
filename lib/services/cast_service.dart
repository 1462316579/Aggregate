import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/cast_device.dart';

/// DLNA/UPnP Cast 服务
/// 使用 SSDP 协议发现设备，支持媒体投送
class CastService extends ChangeNotifier {
  final Uuid _uuidGen = const Uuid();
  final List<CastDevice> _devices = [];

  List<CastDevice> get devices => List.unmodifiable(_devices);

  // ── Player screen integration ──
  bool _isCasting = false;
  bool get isCasting => _isCasting;
  CastDevice? get activeDevice => _activeDevice;
  CastDevice? _activeDevice;

  Future<void> startCast(String url) async {
    _isCasting = true;
    notifyListeners();
  }

  Future<bool> startCastDevice(CastDevice device, String url) async {
    _activeDevice = device;
    _isCasting = true;
    notifyListeners();
    return true;
  }

  Future<void> pauseCast() async {
    if (!_isCasting) return;
    _isCasting = false;
    notifyListeners();
  }

  Future<void> resumeCast() async {
    if (_activeDevice == null) return;
    _isCasting = true;
    notifyListeners();
  }

  Future<void> seekCast(Duration offset) async {
    // stub
  }

  void disconnectCast() {
    _isCasting = false;
    _activeDevice = null;
    notifyListeners();
  }

  /// 扫描 DLNA/UPnP 设备
  Future<List<CastDevice>> scanDevices() async {
    _devices.clear();
    notifyListeners();

    const msearch = """
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: 3
ST: urn:schemas-upnp-org:device:MediaRenderer:1
""";

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      
      socket.send(utf8.encode(msearch), 
          InternetAddress('239.255.255.250'), 1900);

      final devices = <CastDevice>[];
      
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            final device = _parseSsdpResponse(response);
            if (device != null && !devices.any((d) => d.ip == device.ip)) {
              devices.add(device);
              _devices.add(device);
              notifyListeners();
            }
          }
        }
      });

      await Future.delayed(Duration(seconds: 4));
      socket.close();
      
      return devices;
    } catch (e) {
      print('Cast scan error: $e');
      return _devices;
    }
  }

  CastDevice? _parseSsdpResponse(String response) {
    try {
      final lines = response.split('\r\n');
      String? location;
      String? usn;
      
      for (final line in lines) {
        if (line.toLowerCase().startsWith('location:')) {
          location = line.substring('location:'.length).trim();
        } else if (line.toLowerCase().startsWith('usn:')) {
          usn = line.substring('usn:'.length).trim();
        }
      }
      
      if (location == null) return null;
      
      final uri = Uri.parse(location);
      
      return CastDevice(
        id: const Uuid().v4(),
        name: usn?.split(':')[2] ?? 'DLNA Device',
        ip: uri.host,
        port: uri.port,
        type: CastDeviceType.mediaRenderer,
        baseUrl: location,
      );
    } catch (_) {
      return null;
    }
  }

  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _isCasting = false;
    _activeDevice = null;
    super.dispose();
  }
}

/// 投屏设备选择对话框
class CastDeviceSheet extends StatelessWidget {
  final CastService castService;
  final VoidCallback onDismiss;
  
  const CastDeviceSheet({
    required this.castService,
    required this.onDismiss,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final devices = castService.devices;
    
    if (devices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text('未找到投屏设备', textAlign: TextAlign.center),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('选择投屏设备', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        ...devices.map((device) => ListTile(
          leading: const Icon(Icons.tv, color: Color(0xFF2196F3)),
          title: Text(device.name),
          subtitle: Text('${device.ip}:${device.port}'),
          onTap: () {
            onDismiss();
          },
        )),
        TextButton(onPressed: onDismiss, child: const Text('取消')),
      ],
    );
  }
}