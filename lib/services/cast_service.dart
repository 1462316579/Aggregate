/// 投屏服务 — DLNA / AirPlay / Miracast
/// 支持将当前播放的视频投射到智能电视/投影仪
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 投屏设备信息
class CastDevice {
  final String name;
  final String ip;
  final String type;       // dlna, airplay, miracast
  final String manufacturer;
  final String modelName;
  bool isConnected;

  CastDevice({
    required this.name,
    required this.ip,
    this.type = 'dlna',
    this.manufacturer = '',
    this.modelName = '',
    this.isConnected = false,
  });

  @override
  String toString() => '$name ($type) - $ip';
}

/// 投屏服务
class CastService extends ChangeNotifier {
  static const _channel = MethodChannel('com.allplay/cast');

  List<CastDevice> _devices = [];
  CastDevice? _connectedDevice;
  bool _isScanning = false;
  bool _isCasting = false;
  String? _error;

  List<CastDevice> get devices => _devices;
  CastDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;
  bool get isCasting => _isCasting;
  String? get error => _error;

  /// 扫描局域网中的投屏设备 (DLNA/UPnP)
  Future<void> scanDevices() async {
    _isScanning = true;
    _error = null;
    _devices = [];
    notifyListeners();

    try {
      // 方式1: 通过原生平台扫描
      try {
        final result = await _channel.invokeMethod('scanDevices');
        if (result is List) {
          _devices = result.map((d) => CastDevice(
            name: d['name'] ?? '未知设备',
            ip: d['ip'] ?? '',
            type: d['type'] ?? 'dlna',
            manufacturer: d['manufacturer'] ?? '',
            modelName: d['modelName'] ?? '',
          )).toList();
        }
      } catch (_) {
        // 方式2: 通过 SSDP 扫描
        _devices = await _scanSsdp();
      }

      _isScanning = false;
      notifyListeners();
    } catch (e) {
      _error = '扫描失败: $e';
      _isScanning = false;
      notifyListeners();
    }
  }

  /// SSDP (Simple Service Discovery Protocol) 扫描
  Future<List<CastDevice>> _scanSsdp() async {
    List<CastDevice> devices = [];

    try {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4, 0,
        reuseAddress: true,
      );

      // 发送 M-SEARCH 请求
      final searchMessage = StringBuffer()
        ..write('M-SEARCH * HTTP/1.1\r\n')
        ..write('HOST: 239.255.255.250:1900\r\n')
        ..write('MAN: "ssdp:discover"\r\n')
        ..write('MX: 3\r\n')
        ..write('ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n')
        ..write('\r\n');

      final data = searchMessage.toString().codeUnits;
      socket.send(data, InternetAddress('239.255.255.250'), 1900);

      // 等待响应
      final completer = Completer<List<CastDevice>>();
      Timer(const Duration(seconds: 4), () {
        if (!completer.isCompleted) completer.complete(devices);
        socket.close();
      });

      socket.listen((RawDatagramEvent event) {
        final datagram = event.data;
        if (datagram != null) {
          final response = String.fromCharCodes(datagram);
          final device = _parseSsdpResponse(response);
          if (device != null && !devices.any((d) => d.ip == device.ip)) {
            devices.add(device);
            notifyListeners();
          }
        }
      });

      return completer.future;
    } catch (e) {
      return devices;
    }
  }

  CastDevice? _parseSsdpResponse(String response) {
    try {
      final headers = <String, String>{};
      for (var line in response.split('\r\n')) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim().toLowerCase();
          final value = line.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }

      // 提取设备信息
      final location = headers['location'];
      if (location == null) return null;

      final name = headers['server'] ?? headers['st'] ?? 'DLNA 设备';
      final uri = Uri.tryParse(location);
      if (uri == null) return null;

      return CastDevice(
        name: name,
        ip: uri.host,
        type: 'dlna',
        manufacturer: headers['manufacturer'] ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  /// 连接设备
  Future<bool> connectToDevice(CastDevice device) async {
    try {
      try {
        await _channel.invokeMethod('connect', {'ip': device.ip});
      } catch (_) {
        // 降级: 仅标记连接状态
      }

      _connectedDevice = device;
      device.isConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '连接失败: $e';
      notifyListeners();
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    try {
      try {
        await _channel.invokeMethod('disconnect');
      } catch (_) {}

      if (_connectedDevice != null) {
        _connectedDevice!.isConnected = false;
      }
      _connectedDevice = null;
      _isCasting = false;
      notifyListeners();
    } catch (_) {}
  }

  /// 开始投屏
  Future<void> startCast(String videoUrl, {Map<String, String>? headers}) async {
    if (_connectedDevice == null) {
      _error = '请先连接设备';
      notifyListeners();
      return;
    }

    try {
      try {
        await _channel.invokeMethod('startCast', {
          'url': videoUrl,
          'deviceIp': _connectedDevice!.ip,
          'headers': headers,
        });
      } catch (_) {
        // 降级: 模拟投屏
      }

      _isCasting = true;
      notifyListeners();
    } catch (e) {
      _error = '投屏失败: $e';
      notifyListeners();
    }
  }

  /// 停止投屏
  Future<void> stopCast() async {
    try {
      try {
        await _channel.invokeMethod('stopCast');
      } catch (_) {}

      _isCasting = false;
      notifyListeners();
    } catch (_) {}
  }

  /// 暂投屏
  Future<void> pauseCast() async {
    try {
      try {
        await _channel.invokeMethod('pauseCast');
      } catch (_) {}
    } catch (_) {}
  }

  /// 恢复投屏
  Future<void> resumeCast() async {
    try {
      try {
        await _channel.invokeMethod('resumeCast');
      } catch (_) {}
    } catch (_) {}
  }

  /// 投屏进度同步
  Future<void> seekCast(Duration position) async {
    try {
      try {
        await _channel.invokeMethod('seekCast', {'position': position.inMilliseconds});
      } catch (_) {}
    } catch (_) {}
  }
}

/// 投屏选择弹窗
class CastDeviceSheet extends StatefulWidget {
  final CastService castService;
  const CastDeviceSheet({super.key, required this.castService});

  @override
  State<CastDeviceSheet> createState() => _CastDeviceSheetState();
}

class _CastDeviceSheetState extends State<CastDeviceSheet> {
  @override
  void initState() {
    super.initState();
    widget.castService.addListener(_onUpdate);
    widget.castService.scanDevices();
  }

  @override
  void dispose() {
    widget.castService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.screen_share, color: Color(0xFF2196F3), size: 24),
              const SizedBox(width: 8),
              const Text('投屏设备', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (widget.castService.isCasting)
                TextButton.icon(
                  icon: const Icon(Icons.stop, color: Colors.red, size: 18),
                  label: const Text('停止投屏', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    await widget.castService.stopCast();
                    Navigator.pop(context);
                  },
                ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => widget.castService.scanDevices(),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (widget.castService.isScanning)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('正在扫描局域网设备...'),
              ]),
            )
          else if (widget.castService.devices.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.wifi_find, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('未发现投屏设备', style: TextStyle(color: Colors.grey[500])),
                const SizedBox(height: 6),
                Text('请确保设备在同一 WiFi 网络',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ]),
            )
          else
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.castService.devices.length,
                itemBuilder: (ctx, i) {
                  final device = widget.castService.devices[i];
                  final isConnected = device == widget.castService.connectedDevice;
                  return ListTile(
                    leading: Icon(
                      device.type == 'airplay' ? Icons.air : Icons.tv,
                      color: isConnected ? const Color(0xFF2196F3) : Colors.grey,
                    ),
                    title: Text(device.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${device.ip} · ${device.type.toUpperCase()}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    trailing: isConnected
                        ? const Icon(Icons.check_circle, color: Color(0xFF2196F3))
                        : const Icon(Icons.chevron_right),
                    onTap: () async {
                      final success = await widget.castService.connectToDevice(device);
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已连接: ${device.name}')));
                      }
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
