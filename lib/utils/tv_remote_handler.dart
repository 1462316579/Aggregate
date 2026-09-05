/// TV 遥控器适配 — D-Pad 导航 / 方向键 / 确认键 / 返回键
/// 支持 Android TV 和所有 Focusable TV 平台
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TV 遥控器事件类型
enum TvAction {
  up, down, left, right,
  center,     // 确认/OK
  back,       // 返回
  menu,       // 菜单
  playPause,  // 播放/暂停
  fastForward,// 快进
  rewind,     // 快退
  volumeUp,
  volumeDown,
  channelUp,
  channelDown,
  red, green, yellow, blue, // 彩色功能键
  unknown,
}

class TvRemoteHandler extends StatefulWidget {
  final Widget child;
  final Function(TvAction)? onAction;
  final bool enableFocusHighlight;

  const TvRemoteHandler({
    super.key,
    required this.child,
    this.onAction,
    this.enableFocusHighlight = true,
  });

  @override
  State<TvRemoteHandler> createState() => TvRemoteHandlerState();
}

class TvRemoteHandlerState extends State<TvRemoteHandler> {
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  FocusNode? _focusNode;

  FocusNode get focusNode => _focusNode ??= FocusNode();

  /// 检测是否在 TV 平台
  static bool isTV(BuildContext context) {
    return MediaQuery.of(context).size.width > 960;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    _pressedKeys.add(key);

    final action = _mapKeyToAction(key);
    if (action != TvAction.unknown) {
      widget.onAction?.call(action);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  TvAction _mapKeyToAction(LogicalKeyboardKey key) {
    // 方向键
    if (key == LogicalKeyboardKey.arrowUp) return TvAction.up;
    if (key == LogicalKeyboardKey.arrowDown) return TvAction.down;
    if (key == LogicalKeyboardKey.arrowLeft) return TvAction.left;
    if (key == LogicalKeyboardKey.arrowRight) return TvAction.right;

    // 确认键
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.gameButtonA)
      return TvAction.center;

    // 返回
    if (key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.browserBack)
      return TvAction.back;

    // 菜单
    if (key == LogicalKeyboardKey.contextMenu ||
        key == LogicalKeyboardKey.menu)
      return TvAction.menu;

    // 播放控制
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.space)
      return TvAction.playPause;
    if (key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.arrowRight)
      return TvAction.fastForward;
    if (key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.arrowLeft)
      return TvAction.rewind;

    // 音量
    if (key == LogicalKeyboardKey.audioVolumeUp) return TvAction.volumeUp;
    if (key == LogicalKeyboardKey.audioVolumeDown) return TvAction.volumeDown;

    // 频道
    if (key == LogicalKeyboardKey.channelUp) return TvAction.channelUp;
    if (key == LogicalKeyboardKey.channelDown) return TvAction.channelDown;

    // 彩色键 (常见于遥控器)
    if (key == LogicalKeyboardKey.f1 || key == LogicalKeyboardKey.red) return TvAction.red;
    if (key == LogicalKeyboardKey.f2 || key == LogicalKeyboardKey.green) return TvAction.green;
    if (key == LogicalKeyboardKey.f3 || key == LogicalKeyboardKey.yellow) return TvAction.yellow;
    if (key == LogicalKeyboardKey.f4 || key == LogicalKeyboardKey.blue) return TvAction.blue;

    return TvAction.unknown;
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

/// TV 焦点卡片 — 遥控器选中时高亮
class TvFocusable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onSelect;
  final bool autofocus;
  final BorderRadius borderRadius;
  final Color focusColor;
  final double elevation;

  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.focusColor = const Color(0xFF2196F3),
    this.elevation = 4,
  });

  @override
  State<TvFocusable> createState() => _TvFocusableState();
}

class _TvFocusableState extends State<TvFocusable> {
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: _isFocused
          ? (Matrix4.identity()..scale(1.05))
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select) {
              widget.onSelect?.call();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            border: _isFocused
                ? Border.all(color: widget.focusColor, width: 3)
                : null,
            boxShadow: _isFocused
                ? [BoxShadow(
                    color: widget.focusColor.withOpacity(0.4),
                    blurRadius: 12, spreadRadius: 2)]
                : null,
          ),
          child: Material(
            borderRadius: widget.borderRadius,
            elevation: _isFocused ? widget.elevation : 0,
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
