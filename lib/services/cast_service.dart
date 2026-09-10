/// 投屏服务 - DLNA/UPnP SSDP 扫描
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/cast_device.dart';

class CastService extends ChangeNotifier {
  static const int SSDP_PORT = 1900;
  static const String SSDP_ADDR = '239.255.255.250';

  final List<CastDevice> _devices = [];
  bool _scanning = false;
  CastDevice? _activeDevice;
  bool _isCasting = false;

  List<CastDevice> get devices => _devices;
  bool get isScanning => _scanning;
  bool get isCasting => _isCasting;
  CastDevice? get activeDevice => _activeDevice;

  Future<void> scan(int timeoutSec = 5) async {
    if (_scanning) return;
    _scanning = true;
    notifyListeners();
    try {
      final socket = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, 0);
      await socket.joinMulticastGroup(
          InternetAddress(SSDP_ADDR));
      socket!.setOption(RawSocketOption.rawReuseAddress, true);
      socket.setOption(RawSocketOption.rawReuseMulticast, true);

      final mcast = await RawDatagramSocket.bind(
          InternetAddress.anyIPv4, 0);
      mcast!.setOption(RawSocketOption.rawReuseAddress, true);
      mcast.setOption(RawSocketOption.rawReuseMulticast, true);

      final message = 'NOTIFY * HTTP/1.1\r\n'
          'Host: $SSDP_ADDR:$SSDP_PORT\r\n'
          'St: upnp:rootdevice\r\n'
          'Usn: uuid:allplay\r\n\r\n';

      final data = utf8.encode(message);
      final buffer = ByteData(data.length);
      buffer.setUint8(0, data[0]);
      // 简化的单字节发送测试
      mcast.send(buffer, InternetAddress(SSDP_ADDR), SSDP_PORT);

      final completer = Completer<List<CastDevice>>();
      final controller = StreamController<void>(sync: true);
      
      final listenFuture = mcast.listen((event) {
        if (event is RawSocketEvent) {
          try {
            final data = event.data;
            if (data != null) {
              final response = String.fromCharCodes(data);
              final device = _parseSsdpResponse(response);
              if (device != null && !_devices.any((d) => d.ip == device.ip)) {
                _devices.add(device);
                notifyListeners();
              }
            }
          } catch (_) {}
        }
      });

      await Future.delayed(Duration(seconds: timeoutSec));
      await listenFuture;
      mcast.close();
      socket.close();

      if (!completer.isCompleted) completer.complete(_devices.toList());
      _scanning = false;
      notifyListeners();
    } catch (e) {
      debugPrint('CastService scan error: $e');
      _scanning = false;
      notifyListeners();
    }
  }

  CastDevice? _parseSsdpResponse(String response) {
    if (!response.contains('HTTP/1.1 200 OK')) return null;
    try {
      final lines = response.split('\r\n');
      String? location;
      String? usn;
      for (final line in lines) {
        if (line.startsWith('LOCATION:')) {
          location = line.substring('LOCATION:'.length).trim();
        } else if (line.startsWith('USN:')) {
          usn = line.substring('USN:'.length).trim();
        }
      }
      if (location != null) {
        final uri = Uri.parse(location);
        return CastDevice(
          id: usn ?? uri.host,
          name: 'DLNA Device',
          ip: uri.host,
          port: uri.port,
          type: CastDeviceType.mediaRenderer,
          baseUrl: location,
        );
      }
    } catch (e) {
      debugPrint('Parse SSDP error: $e');
    }
    return null;
  }

  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  Future<bool> startCast(CastDevice device, String url) async {
    _activeDevice = device;
    _isCasting = true;
    notifyListeners();
    return true;
  }

  Future<bool> startCastUrl(String url) async {
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

  Future<void> seekCast(Duration position) async {
    // no-op stub
  }
}

/// 投屏设备选择面板
class CastDeviceSheet extends StatelessWidget {
  final CastService castService;
  final VoidCallback? onDismiss;

  const CastDeviceSheet({
    super.key,
    required this.castService,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('投屏设备', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Consumer<CastService>(
            builder: (context, service, _) {
              if (service.devices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('未发现投屏设备\n请点击搜索按钮', textAlign: TextAlign.center),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: service.devices.length,
                itemBuilder: (ctx, i) {
                  final device = service.devices[i];
                  return ListTile(
                    leading: const Icon(Icons.tv),
                    title: Text(device.name),
                    subtitle: Text('${device.ip}:${device.port}'),
                    onTap: () {
                      Navigator.pop(context);
                      onDismiss?.call();
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDismiss ?? () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              TextButton.icon(
                onPressed: () => castService.scan(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('搜索'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}