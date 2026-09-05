/// AllPlay 图标绘制器 (Flutter 原生)
/// 在 Flutter 环境中运行此文件即可生成所有尺寸图标
/// 运行: flutter run -d <device> (会自动输出到 assets/icon/)
///
/// 使用方法:
///   1. 将此文件放在 lib/tools/ 下
///   2. 临时在 main.dart 中 import 并调用 generateIcons()
///   3. 运行后图标会输出到 assets/icon/ 目录
///   4. 恢复 main.dart
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

class AllPlayIconPainter extends CustomPainter {
  final double size;

  AllPlayIconPainter(this.size);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);

    // Layer 1: 渐变背景 (圆角)
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(s, s),
        [
          const Color(0xFF0D47A1),
          const Color(0xFF1565C0),
          const Color(0xFF1E88E5),
        ],
      );

    final bgRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, s, s),
      Radius.circular(s * 0.22),
    );
    canvas.drawRRect(bgRRect, bgPaint);

    // Layer 2: 胶片装饰
    final filmPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;

    // 顶部胶片条
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.08, s * 0.06, s * 0.84, s * 0.10),
        Radius.circular(s * 0.02),
      ),
      filmPaint,
    );
    // 底部胶片条
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.08, s * 0.84, s * 0.84, s * 0.10),
        Radius.circular(s * 0.02),
      ),
      filmPaint,
    );

    // 胶片孔
    final holePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final x = s * 0.16 + i * s * 0.13;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, s * 0.11), width: s * 0.05, height: s * 0.04),
          Radius.circular(s * 0.008),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, s * 0.89), width: s * 0.05, height: s * 0.04),
          Radius.circular(s * 0.008),
        ),
        holePaint,
      );
    }

    // Layer 3: 播放按钮背景圆
    final circlePaint = Paint()
      ..shader = ui.Gradient.radial(
        center, s * 0.33,
        [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.08)],
      );
    canvas.drawCircle(center, s * 0.33, circlePaint);

    // 外圈
    canvas.drawCircle(
      center, s * 0.37,
      Paint()
        ..color = Colors.white.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.012,
    );

    // Layer 4: 播放三角形
    final ts = s * 0.16;
    final playPath = Path()
      ..moveTo(center.dx - ts * 0.45, center.dy - ts * 0.55)
      ..lineTo(center.dx + ts * 0.65, center.dy)
      ..lineTo(center.dx - ts * 0.45, center.dy + ts * 0.55)
      ..close();

    // 阴影
    canvas.drawPath(playPath, Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.015));
    canvas.drawPath(playPath, Paint()..color = Colors.white);

    // Layer 5: "ALL" 文字
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'ALL',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: s * 0.085,
          fontWeight: FontWeight.w900,
          letterSpacing: s * 0.035,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset((s - textPainter.width) / 2, s * 0.65));

    // Layer 6: 星星
    final starPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, Offset(s * 0.18, s * 0.35), s * 0.015, starPaint);
    _drawStar(canvas, Offset(s * 0.82, s * 0.30), s * 0.012, starPaint);
    _drawStar(canvas, Offset(s * 0.15, s * 0.68), s * 0.010, starPaint);
    _drawStar(canvas, Offset(s * 0.85, s * 0.72), s * 0.014, starPaint);
    _drawStar(canvas, Offset(s * 0.72, s * 0.20), s * 0.008, starPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final innerAngle = ((i * 72 + 36) - 90) * pi / 180;
      final outer = Offset(center.dx + cos(angle) * r, center.dy + sin(angle) * r);
      final inner = Offset(center.dx + cos(innerAngle) * r * 0.4, center.dy + sin(innerAngle) * r * 0.4);
      if (i == 0) path.moveTo(outer.dx, outer.dy);
      else path.lineTo(outer.dx, outer.dy);
      path.lineTo(inner.dx, inner.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 生成图标 Widget
Widget generateIconWidget(double size) {
  return CustomPaint(
    size: Size(size, size),
    painter: AllPlayIconPainter(size),
  );
}
