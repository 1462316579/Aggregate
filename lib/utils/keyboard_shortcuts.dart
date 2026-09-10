/// 桌面端键盘快捷键适配
/// 支持: 空格播放/暂停, 方向键快进快退, F全屏, Esc退出等
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum KeyboardAction {
  playPause,
  seekForward10,
  seekBackward10,
  seekForward30,
  seekBackward30,
  volumeUp,
  volumeDown,
  mute,
  fullscreen,
  escape,
  nextEpisode,
  prevEpisode,
  speedUp,
  speedDown,
  screenshot,
  toggleDanmaku,
  unknown,
}

class KeyboardShortcutHandler extends StatefulWidget {
  final Widget child;
  final Function(KeyboardAction)? onAction;
  final bool enabled;

  const KeyboardShortcutHandler({
    super.key,
    required this.child,
    this.onAction,
    this.enabled = true,
  });

  @override
  State<KeyboardShortcutHandler> createState() => _KeyboardShortcutHandlerState();
}

class _KeyboardShortcutHandlerState extends State<KeyboardShortcutHandler> {
  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed ||
                 HardwareKeyboard.instance.isMetaPressed;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final alt = HardwareKeyboard.instance.isAltPressed;

    final action = _mapKey(key, ctrl, shift, alt);
    if (action != KeyboardAction.unknown) {
      widget.onAction?.call(action);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyboardAction _mapKey(LogicalKeyboardKey key, bool ctrl, bool shift, bool alt) {
    // 空格 → 播放/暂停
    if (key == LogicalKeyboardKey.space && !ctrl && !alt) {
      return KeyboardAction.playPause;
    }

    // 方向键 → 快进/快退
    if (key == LogicalKeyboardKey.arrowRight && !ctrl && !alt) {
      return shift ? KeyboardAction.seekForward30 : KeyboardAction.seekForward10;
    }
    if (key == LogicalKeyboardKey.arrowLeft && !ctrl && !alt) {
      return shift ? KeyboardAction.seekBackward30 : KeyboardAction.seekBackward10;
    }

    // 上/下 → 音量
    if (key == LogicalKeyboardKey.arrowUp && !ctrl && !alt) {
      return KeyboardAction.volumeUp;
    }
    if (key == LogicalKeyboardKey.arrowDown && !ctrl && !alt) {
      return KeyboardAction.volumeDown;
    }

    // M → 静音
    if (key == LogicalKeyboardKey.keyM && !ctrl && !alt) {
      return KeyboardAction.mute;
    }

    // F → 全屏
    if (key == LogicalKeyboardKey.keyF && !ctrl && !alt) {
      return KeyboardAction.fullscreen;
    }

    // Esc → 退出
    if (key == LogicalKeyboardKey.escape) {
      return KeyboardAction.escape;
    }

    // N → 下一集, P → 上一集
    if (key == LogicalKeyboardKey.keyN && !ctrl && !alt) {
      return KeyboardAction.nextEpisode;
    }
    if (key == LogicalKeyboardKey.keyP && !ctrl && !alt) {
      return KeyboardAction.prevEpisode;
    }

    // [ → 减速, ] → 加速
    if (key == LogicalKeyboardKey.bracketLeft && !ctrl && !alt) {
      return KeyboardAction.speedDown;
    }
    if (key == LogicalKeyboardKey.bracketRight && !ctrl && !alt) {
      return KeyboardAction.speedUp;
    }

    // S → 截图
    if (key == LogicalKeyboardKey.keyS && !ctrl && !alt) {
      return KeyboardAction.screenshot;
    }

    // D → 弹幕
    if (key == LogicalKeyboardKey.keyD && !ctrl && !alt) {
      return KeyboardAction.toggleDanmaku;
    }

    return KeyboardAction.unknown;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: widget.child,
    );
  }
}

/// 快捷键帮助面板
class KeyboardShortcutsPanel extends StatelessWidget {
  const KeyboardShortcutsPanel({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const KeyboardShortcutsPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          const Text('键盘快捷键', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _shortcutRow('空格', '播放 / 暂停'),
          _shortcutRow('←', '快退 10 秒'),
          _shortcutRow('→', '快进 10 秒'),
          _shortcutRow('Shift + ←', '快退 30 秒'),
          _shortcutRow('Shift + →', '快进 30 秒'),
          _shortcutRow('↑ / ↓', '音量 + / -'),
          _shortcutRow('M', '静音'),
          _shortcutRow('F', '全屏'),
          _shortcutRow('N', '下一集'),
          _shortcutRow('P', '上一集'),
          _shortcutRow('[ / ]', '减速 / 加速'),
          _shortcutRow('S', '截图'),
          _shortcutRow('D', '弹幕'),
          _shortcutRow('Esc', '退出全屏 / 返回'),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _shortcutRow(String key, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(key, style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 12),
          Text(desc, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
