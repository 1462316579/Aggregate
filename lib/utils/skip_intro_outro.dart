/// 跳过片头片尾组件 — 支持所有平台
/// 自动检测 + 手动设置 + 提示条
import 'package:flutter/material.dart';
import 'dart:async';

class SkipIntroOutro extends StatefulWidget {
  final Duration? introEnd;       // 片头结束时间
  final Duration? outroStart;     // 片尾开始时间 (null=自动检测)
  final Duration position;        // 当前播放位置
  final Duration duration;        // 总时长
  final VoidCallback? onSkipIntro;
  final VoidCallback? onSkipOutro;
  final Function(Duration)? onSeekTo;  // 跳转到指定位置
  final bool showSkipButtons;

  const SkipIntroOutro({
    super.key,
    this.introEnd,
    this.outroStart,
    required this.position,
    required this.duration,
    this.onSkipIntro,
    this.onSkipOutro,
    this.onSeekTo,
    this.showSkipButtons = true,
  });

  @override
  State<SkipIntroOutro> createState() => _SkipIntroOutroState();
}

class _SkipIntroOutroState extends State<SkipIntroOutro> {
  bool _showSkipIntro = false;
  bool _showSkipOutro = false;
  bool _introSkipped = false;
  bool _outroSkipped = false;

  @override
  void didUpdateWidget(SkipIntroOutro oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkSkipPoints();
  }

  void _checkSkipPoints() {
    if (widget.introEnd != null && !_introSkipped) {
      final inIntro = widget.position < widget.introEnd!;
      if (inIntro && !_showSkipIntro) {
        setState(() => _showSkipIntro = true);
      } else if (!inIntro && _showSkipIntro) {
        setState(() { _showSkipIntro = false; _introSkipped = true; });
      }
    }

    if (widget.outroStart != null && !_outroSkipped) {
      final inOutro = widget.position >= widget.outroStart!;
      if (inOutro && !_showSkipOutro) {
        setState(() => _showSkipOutro = true);
      } else if (!inOutro && _showSkipOutro) {
        setState(() { _showSkipOutro = false; _outroSkipped = true; });
      }
    }
  }

  void _skipIntro() {
    if (widget.introEnd != null && widget.onSeekTo != null) {
      widget.onSeekTo!(widget.introEnd!);
    }
    widget.onSkipIntro?.call();
    setState(() { _showSkipIntro = false; _introSkipped = true; });
  }

  void _skipOutro() {
    if (widget.onSkipOutro != null) {
      widget.onSkipOutro!();
    }
    // 跳到下一集
    setState(() { _showSkipOutro = false; _outroSkipped = true; });
  }

  void _resetSkips() {
    setState(() {
      _introSkipped = false;
      _outroSkipped = false;
      _showSkipIntro = false;
      _showSkipOutro = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // "跳过片头" 按钮 (右下角)
        if (_showSkipIntro && widget.showSkipButtons)
          Positioned(
            right: 16,
            bottom: 80,
            child: _buildSkipButton(
              '跳过片头',
              Icons.skip_next,
              _skipIntro,
              subtitle: _formatDuration(widget.introEnd!),
            ),
          ),

        // "跳过片尾" / "下一集" 按钮 (右下角)
        if (_showSkipOutro && widget.showSkipButtons)
          Positioned(
            right: 16,
            bottom: 80,
            child: _buildSkipButton(
              '下一集',
              Icons.fast_forward,
              _skipOutro,
            ),
          ),

        // 片头/片尾进度指示条
        if (widget.introEnd != null || widget.outroStart != null)
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _buildProgressBar(),
          ),
      ],
    );
  }

  Widget _buildSkipButton(String label, IconData icon, VoidCallback onTap, {String? subtitle}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF333333), size: 20),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(
                    color: Color(0xFF333333), fontSize: 14, fontWeight: FontWeight.bold)),
                if (subtitle != null)
                  Text(subtitle, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    if (widget.duration.inMilliseconds == 0) return const SizedBox.shrink();

    final progress = widget.position.inMilliseconds / widget.duration.inMilliseconds;

    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          // 全局进度条
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)),
          ),
          // 片头区间标记
          if (widget.introEnd != null)
            Positioned(
              left: 0,
              top: 0, bottom: 0,
              width: (widget.introEnd!.inMilliseconds / widget.duration.inMilliseconds) * 
                  MediaQuery.of(context).size.width,
              child: Container(color: Colors.red.withOpacity(0.4)),
            ),
          // 片尾区间标记
          if (widget.outroStart != null)
            Positioned(
              right: 0,
              top: 0, bottom: 0,
              width: ((widget.duration.inMilliseconds - widget.outroStart!.inMilliseconds) /
                  widget.duration.inMilliseconds) * MediaQuery.of(context).size.width,
              child: Container(color: Colors.orange.withOpacity(0.4)),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

/// 跳过片头片尾设置弹窗
class SkipSettingsDialog extends StatefulWidget {
  final Duration? currentIntroEnd;
  final Duration? currentOutroStart;
  final Duration duration;

  const SkipSettingsDialog({
    super.key,
    this.currentIntroEnd,
    this.currentOutroStart,
    required this.duration,
  });

  @override
  State<SkipSettingsDialog> createState() => _SkipSettingsDialogState();
}

class _SkipSettingsDialogState extends State<SkipSettingsDialog> {
  late double _introEndSeconds;
  late double _outroStartSeconds;
  bool _enableIntro = false;
  bool _enableOutro = false;

  @override
  void initState() {
    super.initState();
    _enableIntro = widget.currentIntroEnd != null;
    _enableOutro = widget.currentOutroStart != null;
    _introEndSeconds = (widget.currentIntroEnd ?? const Duration(seconds: 90)).inSeconds.toDouble();
    _outroStartSeconds = (widget.currentOutroStart ??
        Duration(seconds: widget.duration.inSeconds - 90)).inSeconds.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final totalSeconds = widget.duration.inSeconds.toDouble();

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('跳过片头片尾'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 片头设置
          SwitchListTile(
            title: const Text('跳过片头'),
            subtitle: Text(_enableIntro
                ? '片头到 ${_formatSec(_introEndSeconds)}'
                : '关闭'),
            value: _enableIntro,
            onChanged: (v) => setState(() => _enableIntro = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableIntro) ...[
            Slider(
              value: _introEndSeconds,
              min: 0, max: totalSeconds,
              label: _formatSec(_introEndSeconds),
              onChanged: (v) => setState(() => _introEndSeconds = v),
            ),
            Text('片头到: ${_formatSec(_introEndSeconds)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
          const Divider(),
          // 片尾设置
          SwitchListTile(
            title: const Text('跳过片尾'),
            subtitle: Text(_enableOutro
                ? '片尾从 ${_formatSec(_outroStartSeconds)}'
                : '关闭'),
            value: _enableOutro,
            onChanged: (v) => setState(() => _enableOutro = v),
            contentPadding: EdgeInsets.zero,
          ),
          if (_enableOutro) ...[
            Slider(
              value: _outroStartSeconds,
              min: 0, max: totalSeconds,
              label: _formatSec(_outroStartSeconds),
              onChanged: (v) => setState(() => _outroStartSeconds = v),
            ),
            Text('片尾从: ${_formatSec(_outroStartSeconds)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2196F3),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context, {
              'introEnd': _enableIntro
                  ? Duration(seconds: _introEndSeconds.toInt())
                  : null,
              'outroStart': _enableOutro
                  ? Duration(seconds: _outroStartSeconds.toInt())
                  : null,
            });
          },
          child: const Text('保存'),
        ),
      ],
    );
  }

  String _formatSec(double sec) {
    final s = sec.toInt();
    final m = s ~/ 60;
    final ss = s % 60;
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }
}
