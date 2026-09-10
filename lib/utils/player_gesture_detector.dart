/// 移动端播放器手势 — 长按调节进度 + 双击暂停 + 滑动调节
/// 亦搜/YouTube 风格手势交互
import 'package:flutter/material.dart';
import 'dart:async';

class PlayerGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTapPause;
  final Function(double)? onLongPressSeek;      // 传入进度变化量 (秒)
  final Function(double)? onVerticalDragVolume;  // 音量调节
  final Function(double)? onHorizontalDragSeek;  // 进度滑动
  final VoidCallback? onSingleTap;               // 单击显示/隐藏控制栏
  final bool enabled;

  const PlayerGestureDetector({
    super.key,
    required this.child,
    this.onDoubleTapPause,
    this.onLongPressSeek,
    this.onVerticalDragVolume,
    this.onHorizontalDragSeek,
    this.onSingleTap,
    this.enabled = true,
  });

  @override
  State<PlayerGestureDetector> createState() => _PlayerGestureDetectorState();
}

class _PlayerGestureDetectorState extends State<PlayerGestureDetector>
    with SingleTickerProviderStateMixin {
  // 长按快进/快退
  bool _isLongPressing = false;
  bool _isLongPressForward = true; // true=快进, false=快退
  int _longPressSpeed = 0; // 当前倍速
  Timer? _longPressTimer;
  int _longPress累计秒数 = 0;

  // 双击检测
  DateTime? _lastTapTime;
  DateTime? _lastDoubleTapTime;

  // 滑动反馈
  double _dragStartX = 0;
  double _dragDelta = 0;
  bool _isDragging = false;
  String _dragHint = '';

  // 长按反馈 UI
  AnimationController? _feedbackAnim;

  @override
  void initState() {
    super.initState();
    _feedbackAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _feedbackAnim?.dispose();
    super.dispose();
  }

  /// 双击检测
  void _handleTapDown(TapDownDetails details) {
    final now = DateTime.now();

    if (_lastTapTime != null) {
      final diff = now.difference(_lastTapTime!);
      if (diff.inMilliseconds < 300) {
        // 双击!
        _handleDoubleTap(details.localPosition);
        _lastTapTime = null;
        return;
      }
    }
    _lastTapTime = now;

    // 延迟判断是否为单击
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_lastTapTime == now) {
        // 单击
        widget.onSingleTap?.call();
      }
    });
  }

  void _handleDoubleTap(Offset position) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLeft = position.dx < screenWidth / 2;

    // 双击暂停/播放
    widget.onDoubleTapPause?.call();

    // 双击区域快进/快退 10s
    if (widget.onLongPressSeek != null) {
      widget.onLongPressSeek!(isLeft ? -10.0 : 10.0);
    }
  }

  /// 长按快进/快退
  void _handleLongPressStart(LongPressStartDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isLongPressForward = details.localPosition.dx > screenWidth / 2;
    _isLongPressing = true;
    _longPress累计秒数 = 0;
    _longPressSpeed = 2; // 初始 2x

    // 每 100ms 累计
    _longPressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _longPress累计秒数++;
      // 每 5 秒加速一次
      if (_longPress累计秒数 % 50 == 0 && _longPressSpeed < 8) {
        _longPressSpeed += 1;
      }
      if (widget.onLongPressSeek != null) {
        final delta = (_isLongPressForward ? 0.1 : -0.1) * _longPressSpeed;
        widget.onLongPressSeek!(delta);
      }
    });

    _feedbackAnim?.forward();
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _longPressTimer?.cancel();
    _isLongPressing = false;
    _feedbackAnim?.reverse();
  }

  /// 水平滑动快进/快退
  void _handleHorizontalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dx;
    _isDragging = true;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDelta = details.globalPosition.dx - _dragStartX;
    final seekDelta = _dragDelta / 10; // 10px = 1s
    setState(() {
      _dragHint = seekDelta > 0
          ? '快进 ${seekDelta.abs().toStringAsFixed(1)}s'
          : '快退 ${seekDelta.abs().toStringAsFixed(1)}s';
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (widget.onHorizontalDragSeek != null) {
      final seekDelta = _dragDelta / 10;
      widget.onHorizontalDragSeek!(seekDelta);
    }
    setState(() { _isDragging = false; _dragDelta = 0; });
  }

  /// 垂直滑动音量/亮度
  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartX = details.globalPosition.dy;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final delta = _dragStartX - details.globalPosition.dy;
    final volumeDelta = delta / 200;
    if (widget.onVerticalDragVolume != null) {
      widget.onVerticalDragVolume!(volumeDelta);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? _handleTapDown : null,
      onLongPressStart: widget.enabled ? _handleLongPressStart : null,
      onLongPressEnd: widget.enabled ? _handleLongPressEnd : null,
      onHorizontalDragStart: widget.enabled ? _handleHorizontalDragStart : null,
      onHorizontalDragUpdate: widget.enabled ? _handleHorizontalDragUpdate : null,
      onHorizontalDragEnd: widget.enabled ? _handleHorizontalDragEnd : null,
      onVerticalDragStart: widget.enabled ? _handleVerticalDragStart : null,
      onVerticalDragUpdate: widget.enabled ? _handleVerticalDragUpdate : null,
      child: Stack(
        children: [
          widget.child,
          // 长按快进/快退反馈
          if (_isLongPressing)
            Positioned(
              top: 0, bottom: 0,
              left: _isLongPressForward ? null : 0,
              right: _isLongPressForward ? 0 : null,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: _isLongPressForward ? Alignment.centerLeft : Alignment.centerRight,
                    end: _isLongPressForward ? Alignment.centerRight : Alignment.centerLeft,
                    colors: [
                      Colors.blue.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isLongPressForward ? Icons.fast_forward : Icons.fast_rewind,
                        color: Colors.white, size: 32,
                      ),
                      const SizedBox(height: 4),
                      Text('${_longPressSpeed}x',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          // 滑动快进快退提示
          if (_isDragging && _dragHint.isNotEmpty)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Container(
                color: Colors.black45,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_dragHint,
                        style: const TextStyle(color: Colors.white, fontSize: 18)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
