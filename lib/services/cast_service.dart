/// 投屏服务 - DLNA/UPnP SSDP 扫描（简化版）
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cast_device.dart';

class CastService extends ChangeNotifier {
  final List<CastDevice> _devices = [];
  bool _scanning = false;
  CastDevice? _activeDevice;
  bool _isCasting = false;

  List<CastDevice> get devices => _devices;
  bool get isScanning => _scanning;
  bool get isCasting => _isCasting;
  CastDevice? get activeDevice => _activeDevice;

  /// 扫描投屏设备（简化实现）
  Future<void> scan(int timeoutSec) async {
    if (_scanning) return;
    _scanning = true;
    notifyListeners();
    
    // 简化：暂时清空设备列表，等待真实实现
    // 由于 RawSocket/DatagramSocket API 在 Android sandbox 中受限
    await Future.delayed(Duration(seconds: timeoutSec));
    
    _scanning = false;
    notifyListeners();
  }

  void clearDevices() {
    _devices.clear();
    notifyListeners();
  }

  /// 开始投屏
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

  /// 暂停投屏
  Future<void> pauseCast() async {
    if (!_isCasting) return;
    _isCasting = false;
    notifyListeners();
  }

  /// 恢复投屏
  Future<void> resumeCast() async {
    if (_activeDevice == null) return;
    _isCasting = true;
    notifyListeners();
  }

  /// 投屏时定位
  Future<void> seekCast(Duration position) async {
    // stub
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