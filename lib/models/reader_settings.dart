/// 阅读器设置 - 漫画/小说共用
class ReaderSettings {
  double fontSize;
  String fontFamily;
  double lineSpacing;
  bool isVerticalMode;      // 漫画: 竖向滚动 vs 翻页
  bool isNightMode;         // 小说: 夜间模式
  int brightness;           // 屏幕亮度 (0-100)
  String backgroundColor;
  String textColor;

  ReaderSettings({
    this.fontSize = 18.0,
    this.fontFamily = '',
    this.lineSpacing = 1.5,
    this.isVerticalMode = true,
    this.isNightMode = false,
    this.brightness = 80,
    this.backgroundColor = '#FFFFFF',
    this.textColor = '#333333',
  });

  Map<String, dynamic> toJson() => {
    'fontSize': fontSize, 'fontFamily': fontFamily, 'lineSpacing': lineSpacing,
    'isVerticalMode': isVerticalMode, 'isNightMode': isNightMode,
    'brightness': brightness, 'backgroundColor': backgroundColor, 'textColor': textColor,
  };

  factory ReaderSettings.fromJson(Map<String, dynamic> json) => ReaderSettings(
    fontSize: (json['fontSize'] ?? 18).toDouble(),
    fontFamily: json['fontFamily'] ?? '',
    lineSpacing: (json['lineSpacing'] ?? 1.5).toDouble(),
    isVerticalMode: json['isVerticalMode'] ?? true,
    isNightMode: json['isNightMode'] ?? false,
    brightness: json['brightness'] ?? 80,
    backgroundColor: json['backgroundColor'] ?? '#FFFFFF',
    textColor: json['textColor'] ?? '#333333',
  );
}
