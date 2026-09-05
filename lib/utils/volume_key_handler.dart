/// 音量键翻页服务 — 漫画/小说阅读器使用
/// Android: 通过 MethodChannel 监听音量键
/// iOS: 通过耳机线控 / 键盘事件
/// 所有平台: 键盘 +/- 键作为备选
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;

/// 音量键事件类型
enum VolumeKeyAction {
  pageUp,      // 翻上一页
  pageDown,    // 翻下一页
  none,        // 不响应
}

/// 音量键配置
class VolumeKeyConfig {
  final bool enabled;
  final VolumeKeyAction volumeUpAction;
  final VolumeKeyAction volumeDownAction;
  final bool autoCommit;     // 翻页后自动提交阅读进度

  const VolumeKeyConfig({
    this.enabled = true,
    this.volumeUpAction = VolumeKeyAction.pageUp,
    this.volumeDownAction = VolumeKeyAction.pageDown,
    this.autoCommit = true,
  });

  VolumeKeyConfig copyWith({
    bool? enabled,
    VolumeKeyAction? volumeUpAction,
    VolumeKeyAction? volumeDownAction,
    bool? autoCommit,
  }) => VolumeKeyConfig(
    enabled: enabled ?? this.enabled,
    volumeUpAction: volumeUpAction ?? this.volumeUpAction,
    volumeDownAction: volumeDownAction ?? this.volumeDownAction,
    autoCommit: autoCommit ?? this.autoCommit,
  );
}

class VolumeKeyHandler {
  static const _channel = MethodChannel('com.allplay/volume_keys');
  static VolumeKeyHandler? _instance;
  
  final StreamController<VolumeKeyAction> _controller = StreamController.broadcast();
  Stream<VolumeKeyAction> get onKeyEvent => _controller.stream;
  
  VolumeKeyConfig _config = const VolumeKeyConfig();
  bool _isListening = false;

  VolumeKeyHandler._();
  
  static VolumeKeyHandler get instance {
    _instance ??= VolumeKeyHandler._();
    return _instance!;
  }

  /// 开始监听音量键
  Future<void> startListening({VolumeKeyConfig? config}) async {
    if (_isListening) return;
    _config = config ?? _config;
    
    try {
      // Android: 注册音量键监听
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'volumeUp') {
          _controller.add(_config.volumeUpAction);
        } else if (call.method == 'volumeDown') {
          _controller.add(_config.volumeDownAction);
        }
      });
      
      await _channel.invokeMethod('startListening');
      _isListening = true;
    } catch (_) {
      // 非 Android 平台，使用键盘事件作为备选
      _isListening = true;
    }
  }

  /// 停止监听
  Future<void> stopListening() async {
    try {
      await _channel.invokeMethod('stopListening');
    } catch (_) {}
    _isListening = false;
  }

  /// 更新配置
  void updateConfig(VolumeKeyConfig config) {
    _config = config;
  }

  void dispose() {
    _controller.close();
    _instance = null;
  }
}

/// 音量键阅读器包装器
/// 包裹阅读页面，自动处理音量键翻页
class VolumeKeyReaderWrapper extends StatefulWidget {
  final Widget child;
  final VolumeKeyConfig config;
  final VoidCallback? onPageUp;
  final VoidCallback? onPageDown;
  final Function(VolumeKeyAction)? onAction;

  const VolumeKeyReaderWrapper({
    super.key,
    required this.child,
    this.config = const VolumeKeyConfig(),
    this.onPageUp,
    this.onPageDown,
    this.onAction,
  });

  @override
  State<VolumeKeyReaderWrapper> createState() => _VolumeKeyReaderWrapperState();
}

class _VolumeKeyReaderWrapperState extends State<VolumeKeyReaderWrapper> {
  final _volumeHandler = VolumeKeyHandler.instance;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void didUpdateWidget(VolumeKeyReaderWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config != widget.config) {
      _volumeHandler.updateConfig(widget.config);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _volumeHandler.stopListening();
    super.dispose();
  }

  void _startListening() {
    _volumeHandler.startListening(config: widget.config);
    _subscription = _volumeHandler.onKeyEvent.listen((action) {
      if (!mounted) return;
      switch (action) {
        case VolumeKeyAction.pageUp:
          widget.onPageUp?.call();
          widget.onAction?.call(action);
          break;
        case VolumeKeyAction.pageDown:
          widget.onPageDown?.call();
          widget.onAction?.call(action);
          break;
        case VolumeKeyAction.none:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 同时监听键盘 +/- 键作为 PC 端备选
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        
        if (event.logicalKey == LogicalKeyboardKey.equal ||
            event.logicalKey == LogicalKeyboardKey.numpadAdd) {
          widget.onPageDown?.call();
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.minus ||
            event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
          widget.onPageUp?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}

/// 音量键设置弹窗
class VolumeKeySettingsSheet extends StatefulWidget {
  final VolumeKeyConfig config;
  final Function(VolumeKeyConfig) onChanged;

  const VolumeKeySettingsSheet({
    super.key, required this.config, required this.onChanged});

  @override
  State<VolumeKeySettingsSheet> createState() => _VolumeKeySettingsSheetState();
}

class _VolumeKeySettingsSheetState extends State<VolumeKeySettingsSheet> {
  late VolumeKeyConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handleBar(),
          const SizedBox(height: 12),
          const Text('音量键翻页设置', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // 启用开关
          SwitchListTile(
            title: const Text('启用音量键翻页'),
            subtitle: Text(_config.enabled ? '已启用' : '已关闭',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            value: _config.enabled,
            onChanged: (v) => _update(_config.copyWith(enabled: v)),
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF2196F3),
          ),
          if (_config.enabled) ...[
            // 音量+ 动作
            ListTile(
              title: const Text('音量+ 键'),
              subtitle: Text(_actionLabel(_config.volumeUpAction)),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showActionPicker(true),
            ),
            // 音量- 动作
            ListTile(
              title: const Text('音量- 键'),
              subtitle: Text(_actionLabel(_config.volumeDownAction)),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showActionPicker(false),
            ),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _update(VolumeKeyConfig config) {
    setState(() => _config = config);
    widget.onChanged(config);
  }

  void _showActionPicker(bool isVolumeUp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(isVolumeUp ? '音量+ 键动作' : '音量- 键动作'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: VolumeKeyAction.values.map((action) => RadioListTile<VolumeKeyAction>(
            title: Text(_actionLabel(action)),
            value: action,
            groupValue: isVolumeUp ? _config.volumeUpAction : _config.volumeDownAction,
            onChanged: (v) {
              Navigator.pop(ctx);
              if (v != null) {
                _update(isVolumeUp
                    ? _config.copyWith(volumeUpAction: v)
                    : _config.copyWith(volumeDownAction: v));
              }
            },
          )).toList(),
        ),
      ),
    );
  }

  String _actionLabel(VolumeKeyAction action) => switch (action) {
    VolumeKeyAction.pageUp => '⬆️ 上一页',
    VolumeKeyAction.pageDown => '⬇️ 下一页',
    VolumeKeyAction.none => '禁用',
  };

  Widget _handleBar() => Center(
    child: Container(
      width: 40, height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));
}
