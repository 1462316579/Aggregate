/// AllPlay APP 图标生成器
/// 使用 Flutter Canvas 绘制专业图标，输出所有平台所需尺寸
/// 依赖: flutter, dart:ui, dart:io
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

// 不依赖 Flutter framework，纯 Dart Canvas 绘制
// 通过 recordingCanvas 生成 PNG

void main() async {
  print('🎬 AllPlay 图标生成器启动...');

  final outputDir = Directory('assets/icons');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  // 绘制图标
  final image = await _drawIcon(1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  if (bytes != null) {
    // 保存 1024px 原图
    final file = File('${outputDir.path}/app_icon_1024.png');
    file.writeAsBytesSync(bytes.buffer.asUint8List());
    print('✅ 原图已保存: ${file.path}');
  }

  // 生成各平台尺寸
  final sizes = {
    // Android
    'android/mipmap-mdpi/ic_launcher.png': 48,
    'android/mipmap-mdpi/ic_launcher_round.png': 48,
    'android/mipmap-hdpi/ic_launcher.png': 72,
    'android/mipmap-hdpi/ic_launcher_round.png': 72,
    'android/mipmap-xhdpi/ic_launcher.png': 96,
    'android/mipmap-xhdpi/ic_launcher_round.png': 96,
    'android/mipmap-xxhdpi/ic_launcher.png': 144,
    'android/mipmap-xxhdpi/ic_launcher_round.png': 144,
    'android/mipmap-xxxhdpi/ic_launcher.png': 192,
    'android/mipmap-xxxhdpi/ic_launcher_round.png': 192,
    'android/play_store_icon.png': 512,
    // iOS
    'ios/Runner/AppIcon.appiconset/Icon-App-20x20@1x.png': 20,
    'ios/Runner/AppIcon.appiconset/Icon-App-20x20@2x.png': 40,
    'ios/Runner/AppIcon.appiconset/Icon-App-20x20@3x.png': 60,
    'ios/Runner/AppIcon.appiconset/Icon-App-29x29@1x.png': 29,
    'ios/Runner/AppIcon.appiconset/Icon-App-29x29@2x.png': 58,
    'ios/Runner/AppIcon.appiconset/Icon-App-29x29@3x.png': 87,
    'ios/Runner/AppIcon.appiconset/Icon-App-40x40@1x.png': 40,
    'ios/Runner/AppIcon.appiconset/Icon-App-40x40@2x.png': 80,
    'ios/Runner/AppIcon.appiconset/Icon-App-40x40@3x.png': 120,
    'ios/Runner/AppIcon.appiconset/Icon-App-60x60@2x.png': 120,
    'ios/Runner/AppIcon.appiconset/Icon-App-60x60@3x.png': 180,
    'ios/Runner/AppIcon.appiconset/Icon-App-76x76@1x.png': 76,
    'ios/Runner/AppIcon.appiconset/Icon-App-76x76@2x.png': 152,
    'ios/Runner/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png': 167,
    'ios/Runner/AppIcon.appiconset/Icon-App-1024x1024@1x.png': 1024,
    // Web
    'web/icons/Icon-192.png': 192,
    'web/icons/Icon-512.png': 512,
    'web/icons/Icon-maskable-192.png': 192,
    'web/icons/Icon-maskable-512.png': 512,
  };

  for (var entry in sizes.entries) {
    final resized = await _resizeIcon(image, entry.value);
    final resizedBytes = await resized.toByteData(format: ui.ImageByteFormat.png);
    if (resizedBytes != null) {
      final file = File('${outputDir.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(resizedBytes.buffer.asUint8List());
      print('  ✅ ${entry.value}x${entry.value} → ${entry.key}');
    }
  }

  // 生成 favicon.ico (多尺寸合并)
  print('\n🎉 所有图标已生成完毕！');
  print('📁 输出目录: ${outputDir.path}/');
}

/// 绘制主图标 (1024x1024)
Future<ui.Image> _drawIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recainer, Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()));

  final s = size.toDouble();
  final center = Offset(s / 2, s / 2);
  final radius = s * 0.45;

  // ════════════════════════════════════════
  //  Layer 1: 圆角矩形背景 (深色渐变)
  // ════════════════════════════════════════
  final bgPaint = Paint()
    ..shader = ui.Gradient.linear(
      Offset(0, 0),
      Offset(s, s),
      [
        const Color(0xFF0D47A1),   // 深蓝
        const Color(0xFF1565C0),   // 中蓝
        const Color(0xFF1E88E5),   // 亮蓝
      ],
      [0.0, 0.5, 1.0],
    );

  final bgRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, s, s),
    Radius.circular(s * 0.22),
  );
  canvas.drawRRect(bgRect, bgPaint);

  // ════════════════════════════════════════
  //  Layer 2: 胶片/影片装饰线条
  // ════════════════════════════════════════
  final filmPaint = Paint()
    ..color = Colors.white.withOpacity(0.08)
    ..style = PaintingStyle.fill;

  // 顶部胶片条
  final filmTop = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.08, s * 0.06, s * 0.84, s * 0.12),
    Radius.circular(s * 0.03),
  );
  canvas.drawRRect(filmTop, filmPaint);

  // 底部胶片条
  final filmBottom = RRect.fromRectAndRadius(
    Rect.fromLTWH(s * 0.08, s * 0.82, s * 0.84, s * 0.12),
    Radius.circular(s * 0.03),
  );
  canvas.drawRRect(filmBottom, filmPaint);

  // 胶片孔 (顶部)
  final holePaint = Paint()
    ..color = Colors.white.withOpacity(0.15)
    ..style = PaintingStyle.fill;
  for (int i = 0; i < 6; i++) {
    final x = s * 0.16 + i * s * 0.13;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, s * 0.12), width: s * 0.06, height: s * 0.06),
        Radius.circular(s * 0.012),
      ),
      holePaint,
    );
  }
  // 胶片孔 (底部)
  for (int i = 0; i < 6; i++) {
    final x = s * 0.16 + i * s * 0.13;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, s * 0.88), width: s * 0.06, height: s * 0.06),
        Radius.circular(s * 0.012),
      ),
      holePaint,
    );
  }

  // ════════════════════════════════════════
  //  Layer 3: 播放按钮圆形背景
  // ════════════════════════════════════════
  final circlePaint = Paint()
    ..shader = ui.Gradient.radial(
      center,
      radius,
      [
        Colors.white.withOpacity(0.25),
        Colors.white.withOpacity(0.08),
      ],
    );

  canvas.drawCircle(center, radius * 0.75, circlePaint);

  // 外圈光晕
  final glowPaint = Paint()
    ..color = Colors.white.withOpacity(0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = s * 0.015;
  canvas.drawCircle(center, radius * 0.82, glowPaint);

  // ════════════════════════════════════════
  //  Layer 4: 播放三角形 (核心 icon)
  // ════════════════════════════════════════
  final playPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  final triangleSize = s * 0.18;
  final playPath = Path();
  playPath.moveTo(center.dx - triangleSize * 0.4, center.dy - triangleSize * 0.55);
  playPath.lineTo(center.dx + triangleSize * 0.6, center.dy);
  playPath.lineTo(center.dx - triangleSize * 0.4, center.dy + triangleSize * 0.55);
  playPath.close();

  // 阴影
  canvas.drawPath(playPath, Paint()
    ..color = Colors.black.withOpacity(0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

  canvas.drawPath(playPath, playPaint);

  // ════════════════════════════════════════
  //  Layer 5: "ALL" 文字 (底部)
  // ════════════════════════════════════════
  final textPainter = ui.TextPainter(
    text: TextSpan(
      text: 'ALL',
      style: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: s * 0.1,
        fontWeight: FontWeight.w900,
        letterSpacing: s * 0.04,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(
    canvas,
    Offset((s - textPainter.width) / 2, s * 0.62),
  );

  // ════════════════════════════════════════
  //  Layer 6: 星星装饰
  // ════════════════════════════════════════
  final starPaint = Paint()
    ..color = Colors.white.withOpacity(0.3)
    ..style = PaintingStyle.fill;

  _drawStar(canvas, Offset(s * 0.18, s * 0.35), s * 0.02, starPaint);
  _drawStar(canvas, Offset(s * 0.82, s * 0.30), s * 0.015, starPaint);
  _drawStar(canvas, Offset(s * 0.15, s * 0.68), s * 0.012, starPaint);
  _drawStar(canvas, Offset(s * 0.85, s * 0.72), s * 0.018, starPaint);
  _drawStar(canvas, Offset(s * 0.72, s * 0.20), s * 0.01, starPaint);

  final picture = recorder.endRecording();
  return picture.toImage(size, size);
}

/// 绘制星星
void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
  final path = Path();
  for (int i = 0; i < 5; i++) {
    final angle = (i * 72 - 90) * pi / 180;
    final innerAngle = ((i * 72 + 36) - 90) * pi / 180;
    final outer = Offset(
      center.dx + cos(angle) * size,
      center.dy + sin(angle) * size,
    );
    final inner = Offset(
      center.dx + cos(innerAngle) * size * 0.4,
      center.dy + sin(innerAngle) * size * 0.4,
    );
    if (i == 0) {
      path.moveTo(outer.dx, outer.dy);
    } else {
      path.lineTo(outer.dx, outer.dy);
    }
    path.lineTo(inner.dx, inner.dy);
  }
  path.close();
  canvas.drawPath(path, paint);
}

/// 缩放图标
Future<ui.Image> _resizeIcon(ui.Image source, int targetSize) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
  );
  canvas.drawImageRect(
    source,
    Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    Rect.fromLTWH(0, 0, targetSize.toDouble(), targetSize.toDouble()),
    Paint()..filterQuality = ui.FilterQuality.high,
  );
  final picture = recorder.endRecording();
  return picture.toImage(targetSize, targetSize);
}
