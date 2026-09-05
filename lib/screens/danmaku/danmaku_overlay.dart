/// 弹幕层 — Animeko/Kazumi 同款弹幕覆盖
/// 支持: 滚动弹幕 + 顶部/底部固定弹幕 + 密度控制
import 'dart:math';
import 'package:flutter/material.dart';

class DanmakuOverlay extends StatefulWidget {
  final List<DanmakuItem> items;
  final bool enabled;
  final double opacity;
  final double fontSize;
  final double speed;
  final DanmakuDensity density;

  const DanmakuOverlay({
    super.key,
    required this.items,
    this.enabled = true,
    this.opacity = 0.8,
    this.fontSize = 16,
    this.speed = 1.0,
    this.density = DanmakuDensity.medium,
  });

  @override
  State<DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends State<DanmakuOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_DanmakuTrack> _tracks = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, duration: const Duration(seconds: 1))
      ..repeat();
    _assignTracks();
  }

  @override
  void didUpdateWidget(DanmakuOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _assignTracks();
  }

  void _assignTracks() {
    _tracks.clear();
    final maxTracks = widget.density == DanmakuDensity.low ? 5
        : widget.density == DanmakuDensity.medium ? 10 : 20;
    for (int i = 0; i < maxTracks; i++) {
      _tracks.add(_DanmakuTrack());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || widget.items.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (ctx, _) {
          final now = DateTime.now();
          return Stack(
            children: [
              for (var item in widget.items)
                _buildDanmaku(item, now),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDanmaku(DanmakuItem item, DateTime now) {
    final elapsed = now.difference(item.sendTime).inMilliseconds;
    final speed = widget.speed * 80; // pixels per second
    final screenWidth = MediaQuery.of(context).size.width;

    double top;
    double? left;
    Widget content;

    switch (item.type) {
      case DanmakuType.top:
        top = _getTrackTop(item.trackIndex ?? 0);
        content = _buildText(item, isFixed: true);
      case DanmakuType.bottom:
        top = MediaQuery.of(context).size.height - 60 - _getTrackTop(item.trackIndex ?? 0);
        content = _buildText(item, isFixed: true);
      case DanmakuType.scroll:
      default:
        top = _getTrackTop(item.trackIndex ?? 0);
        left = screenWidth - (elapsed / 1000 * speed);
        if (left! < -200) return const SizedBox.shrink();
        content = _buildText(item);
    }

    return Positioned(
      top: top,
      left: left,
      child: Opacity(
        opacity: widget.opacity,
        child: content,
      ),
    );
  }

  double _getTrackTop(int index) {
    return 40.0 + index * 32.0;
  }

  Widget _buildText(DanmakuItem item, {bool isFixed = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isFixed ? Colors.black54 : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        item.text,
        style: TextStyle(
          color: item.color ?? Colors.white,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w500,
          shadows: isFixed ? null : [
            const Shadow(color: Colors.black, blurRadius: 3),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
      ),
    );
  }
}

/// 弹幕类型
enum DanmakuType { scroll, top, bottom }
enum DanmakuDensity { low, medium, high }

/// 弹幕数据
class DanmakuItem {
  final String text;
  final DanmakuType type;
  final Color? color;
  final int? trackIndex;
  final DateTime sendTime;

  DanmakuItem({
    required this.text,
    this.type = DanmakuType.scroll,
    this.color,
    this.trackIndex,
    DateTime? sendTime,
  }) : sendTime = sendTime ?? DateTime.now();
}

class _DanmakuTrack {
  double currentX = 0;
  bool isOccupied = false;
}

/// 弹幕设置弹窗
class DanmakuSettingsSheet extends StatefulWidget {
  final bool enabled;
  final double opacity;
  final double fontSize;
  final double speed;
  final DanmakuDensity density;
  final Function(bool enabled, double opacity, double fontSize, double speed, DanmakuDensity density) onChanged;

  const DanmakuSettingsSheet({
    super.key, required this.enabled,
    this.opacity = 0.8, this.fontSize = 16, this.speed = 1.0,
    this.density = DanmakuDensity.medium,
    required this.onChanged,
  });

  @override
  State<DanmakuSettingsSheet> createState() => _DanmakuSettingsSheetState();
}

class _DanmakuSettingsSheetState extends State<DanmakuSettingsSheet> {
  late bool _enabled;
  late double _opacity;
  late double _fontSize;
  late double _speed;
  late DanmakuDensity _density;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
    _opacity = widget.opacity;
    _fontSize = widget.fontSize;
    _speed = widget.speed;
    _density = widget.density;
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
          // 开关
          SwitchListTile(
            title: const Text('弹幕'),
            value: _enabled,
            onChanged: (v) {
              setState(() => _enabled = v);
              _notifyChange();
            },
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF2196F3),
          ),
          if (_enabled) ...[
            // 透明度
            _sliderRow('透明度', _opacity, 0.1, 1.0, (v) {
              _opacity = v; _notifyChange();
            }),
            // 字号
            _sliderRow('字号', _fontSize, 10, 24, (v) {
              _fontSize = v; _notifyChange();
            }, format: (v) => '${v.round()}'),
            // 速度
            _sliderRow('速度', _speed, 0.5, 2.0, (v) {
              _speed = v; _notifyChange();
            }, format: (v) => '${v.toStringAsFixed(1)}x'),
            // 密度
            Row(
              children: [
                const Text('密度', style: TextStyle(fontSize: 14)),
                const Spacer(),
                ...DanmakuDensity.values.map((d) {
                  final label = d == DanmakuDensity.low ? '稀疏'
                      : d == DanmakuDensity.medium ? '适中' : '密集';
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(label, style: const TextStyle(fontSize: 12)),
                      selected: _density == d,
                      onSelected: (_) { _density = d; _notifyChange(); },
                      selectedColor: const Color(0xFF2196F3),
                      labelStyle: TextStyle(
                          color: _density == d ? Colors.white : Colors.grey[600]),
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sliderRow(String label, double value, double min, double max,
      Function(double) onChanged, {String Function(double)? format}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Expanded(
          child: Slider(
            value: value, min: min, max: max,
            activeColor: const Color(0xFF2196F3),
            onChanged: (v) { setState(() {}); onChanged(v); },
          ),
        ),
        Text(format != null ? format(value) : '${(value * 100).round()}%',
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  void _notifyChange() {
    widget.onChanged(_enabled, _opacity, _fontSize, _speed, _density);
  }

  Widget _handleBar() {
    return Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.grey[300], borderRadius: BorderRadius.circular(2))));
  }
}
