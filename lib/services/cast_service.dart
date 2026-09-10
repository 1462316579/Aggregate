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

  StreamSubscription? _ssdpSubscription;

  /// 扫描 DLNA/UPnP 设备
  Future<List<CastDevice>> scanDevices() async {
    _devices.clear();
    notifyListeners();

    // SSDP M-SEARCH 请求
    const mx = Duration(seconds: 3);
    const msearch = """
M-SEARCH * HTTP/1.1
HOST: 239.255.255.250:1900
MAN: "ssdp:discover"
MX: $mx
ST: urn:schemas-upnp-org:device:MediaRenderer:1
""";

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.setBroadcastAllowed(true);
      
      // 发送 SSDP 搜索请求
      socket.send(utf8.encode(msearch), 
          InternetAddress('239.255.255.250'), 1900);

      // 收集响应
      final devices = <CastDevice>[];
      final completer = Completer<void>();
      
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
      }, done: () {
        if (!completer.isCompleted) completer.complete();
      });

      // 超时
      await Future.delayed(Duration(seconds: 4));
      socket.close();
      
      if (!completer.isCompleted) completer.complete();
      await completer.future;
      
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
      final ip = uri.host;
      
      return CastDevice(
        id: const Uuid().v4(),
        name: usn?.split(':')[2] ?? 'DLNA Device',
        ip: ip,
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
}
