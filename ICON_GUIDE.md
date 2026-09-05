# AllPlay 图标使用指南

## 🎨 图标设计

当前 APP 图标使用 **Flutter Canvas 程序化绘制**，包含：

| 元素 | 说明 |
|------|------|
| 渐变背景 | 深蓝 → 亮蓝 (#0D47A1 → #1E88E5) |
| 播放三角 | 白色三角形 + 阴影 |
| 圆形光晕 | 半透明白色渐变圆 |
| 胶片装饰 | 顶部/底部胶片条 + 胶片孔 |
| "ALL" 文字 | 底部白色粗体文字 |
| 星星点缀 | 5 颗小星星装饰 |

## 📦 生成所有平台图标

### 方式一: 使用 flutter_launcher_icons (推荐)

```bash
# 1. 安装依赖
flutter pub add --dev flutter_launcher_icons

# 2. 配置 (已创建 flutter_launcher_icons.yaml)

# 3. 运行生成
dart run flutter_launcher_icons

# 图标自动输出到:
# Android: android/app/src/main/res/mipmap-*/
# iOS: ios/Runner/AppIcon.appiconset/
# Web: web/icons/
```

### 方式二: 使用 iconfont.cn 图标

1. 访问 https://www.iconfont.cn/
2. 搜索关键词: `播放` `电影` `视频` `film` `play` `video` `cinema`
3. 推荐图标风格:
   - 🎬 电影胶片图标
   - ▶️ 播放按钮图标
   - 🎵 媒体播放图标
   - 📺 电视图标

4. 下载步骤:
   ```
   选择图标 → 添加到项目 → 下载 SVG → 转换为 PNG
   ```

5. 转换为 APP 图标:
   ```bash
   # 使用 ImageMagick 转换 SVG 到各尺寸 PNG
   convert icon.svg -resize 1024x1024 app_icon.png
   convert icon.svg -resize 192x192  Icon-192.png
   convert icon.svg -resize 512x512  Icon-512.png
   
   # Android 各尺寸
   convert icon.svg -resize 48x48    mipmap-mdpi/ic_launcher.png
   convert icon.svg -resize 72x72    mipmap-hdpi/ic_launcher.png
   convert icon.svg -resize 96x96    mipmap-xhdpi/ic_launcher.png
   convert icon.svg -resize 144x144  mipmap-xxhdpi/ic_launcher.png
   convert icon.svg -resize 192x192  mipmap-xxxhdpi/ic_launcher.png
   ```

6. 替换图标:
   - Android: 放入 `android/app/src/main/res/mipmap-*/`
   - iOS: 放入 `ios/Runner/AppIcon.appiconset/`
   - Web: 放入 `web/icons/`

### 方式三: 预览当前图标

在浏览器中打开预览:
```
minis://workspace/AllPlay/assets/icon/preview.html
```

## 📐 各平台图标尺寸

| 平台 | 尺寸 | 路径 |
|------|------|------|
| Android mdpi | 48×48 | mipmap-mdpi/ic_launcher.png |
| Android hdpi | 72×72 | mipmap-hdpi/ic_launcher.png |
| Android xhdpi | 96×96 | mipmap-xhdpi/ic_launcher.png |
| Android xxhdpi | 144×144 | mipmap-xxhdpi/ic_launcher.png |
| Android xxxhdpi | 192×192 | mipmap-xxxhdpi/ic_launcher.png |
| Android Play Store | 512×512 | play_store_icon.png |
| iOS App Store | 1024×1024 | Icon-App-1024x1024@1x.png |
| Web PWA | 192×192 + 512×512 | icons/Icon-192.png, Icon-512.png |
| Windows | 256×256 | windows/runner/resources/app_icon.ico |
| macOS | 1024×1024 | macos/Runner/Assets.xcassets/AppIcon.appiconset/ |

## 🔧 Android Round Icon (自适应图标)

Android 8+ 使用自适应图标，需要两层:

```
adaptive_icon_foreground.png  ← 前景 (播放三角 + 胶片)
adaptive_icon_background.png  ← 背景 (纯色 #0D47A1)
```

在 `AndroidManifest.xml` 中:
```xml
<application
    android:icon="@mipmap/ic_launcher"
    android:roundIcon="@mipmap/ic_launcher_round">
```

## 🎯 图标风格建议

如果使用 iconfont.cn，推荐选择:
- **扁平化** / **线性** 风格
- **白色** 图标 + 透明背景 (用于前景层)
- **单色** 设计 (可着色)
- 主题色: `#1E88E5` (Material Blue 600)

搜索关键词组合:
```
播放 电影 影视 video play film cinema
```
