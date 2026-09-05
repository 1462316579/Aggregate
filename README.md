# AllPlay — 全平台全品类影视聚合播放器 v2

> 基于 TVBox / ZYFun / ZYPlayer / 亦搜架构设计
> 一套代码，6 平台 · 4 种媒体 · 聚合搜索

---

## 支持平台

| 平台 | 方式 | 状态 |
|------|------|------|
| 📱 Android 手机/平板 | Flutter native | ✅ |
| 📺 Android TV | Leanback + NavigationRail | ✅ |
| 🍎 iOS / iPadOS | Flutter native (Xcode) | ✅ |
| 📺 Apple TV (tvOS) | Web 版 via Safari | ✅ |
| 🖥️ Windows | Flutter Desktop / Electron | ✅ |
| 🍏 macOS | Flutter Desktop / Electron | ✅ |
| 🌐 Web | Flutter Web | ✅ |

## 支持媒体类型

| 类型 | 功能 | 来源参考 |
|------|------|----------|
| 🎬 **视频** | 聚合搜索 / 分类浏览 / 详情 / 全屏播放 / 倍速 / 连播 / 进度记忆 | TVBox + ZYFun |
| 📖 **漫画** | 聚合搜索 / 章节目录 / 竖向滚动 + 翻页阅读 / 缩放 | ZYFun + 亦搜 |
| 📚 **小说** | 聚合搜索 / 目录 / 翻页 + 滚动阅读 / 夜间模式 / 字号调节 / 进度记忆 | 亦搜 + ZYPlayer |
| 🎵 **音乐** | 聚合搜索 / 播放 / 歌词滚动 / 歌单 / 播放队列 / 后台播放 | 亦搜 |
| 📺 **直播** | M3U/TXT 直播源 / 分组 / TV 横屏 | TVBox |

## 核心功能

### 🔍 聚合搜索
- 一个搜索框，同时搜索所有已启用的源
- 结果按**类型**自动分组 (视频/漫画/小说/音乐)
- 支持按类型筛选
- 并行请求所有源，极速返回

### 🎬 视频播放
- TVBox V3 格式完全兼容 (JSON / XML / Spider)
- 多源聚合 — 内置 5 个公共源
- 全屏横屏播放器 (media_kit/libmpv)
- 倍速 0.5x~2.0x / 自动连播 / 进度记忆
- 播放解析 (支持视频解析接口)

### 📖 漫画阅读
- 竖向滚动模式 (Webtoon 风格)
- 翻页模式 (支持双指缩放)
- 分卷目录管理
- 章节缓存 (预留)
- 适配主流漫画 CMS 格式

### 📚 小说阅读
- 翻页模式 / 滚动模式 可切换
- 夜间模式 (护眼)
- 字号 12~28pt 可调
- 行间距可调
- 阅读进度自动保存
- 章节列表快速跳转

### 🎵 音乐播放
- 全屏播放器 (旋转唱片动画)
- 歌词实时滚动 (LRC 格式解析)
- 播放队列管理
- 上/下一曲 / 随机 / 单曲循环 / 列表循环
- 底部迷你播放器 (随时控制)
- 后台播放支持

### 📺 直播
- M3U / TXT 格式直播源
- 分组管理
- TV 竖屏 + 横屏适配

---

## 项目架构

```
AllPlay/
├── lib/
│   ├── main.dart                         # 入口 (MediaKit初始化)
│   │
│   ├── models/                           # 数据模型
│   │   ├── video_source.dart             # 源定义 (多类型: video/comic/novel/music)
│   │   ├── unified_content.dart          # 统一内容基类 (所有类型共享)
│   │   ├── video_content.dart            # 视频内容
│   │   ├── comic_detail.dart             # 漫画详情 + 章节 + 页面
│   │   ├── novel_detail.dart             # 小说详情 + 章节 + 进度
│   │   ├── music_detail.dart             # 音乐详情 + 歌曲 + LRC歌词
│   │   ├── live_channel.dart             # 直播频道
│   │   ├── source_category.dart          # 分类
│   │   └── reader_settings.dart          # 阅读器设置 (漫画/小说共用)
│   │
│   ├── services/                         # 核心服务
│   │   ├── spider_service_v2.dart        # ★ 聚合爬虫引擎 v2 (全类型)
│   │   ├── music_player_service.dart     # 音乐播放服务 (队列/歌词/循环)
│   │   └── app_config.dart               # 配置管理
│   │
│   ├── providers/                        # 状态管理
│   │   ├── source_provider.dart          # 源状态 (按类型分组)
│   │   └── player_provider.dart          # 视频播放状态
│   │
│   ├── screens/
│   │   ├── home/                         # 首页
│   │   │   ├── home_screen.dart          # 6 Tab + TV布局 + 迷你播放器
│   │   │   └── pages/
│   │   │       ├── discover_page.dart    # 精选 (视频推荐)
│   │   │       ├── comic_page.dart       # 漫画浏览
│   │   │       ├── novel_page.dart       # 小说浏览
│   │   │       ├── music_page.dart       # 音乐浏览
│   │   │       ├── live_page.dart        # 直播
│   │   │       └── mine_page.dart        # 我的
│   │   │
│   │   ├── comic/                        # 漫画模块
│   │   │   ├── comic_detail_screen.dart  # 漫画详情
│   │   │   └── comic_reader_screen.dart  # 漫画阅读器
│   │   │
│   │   ├── novel/                        # 小说模块
│   │   │   ├── novel_detail_screen.dart  # 小说详情
│   │   │   └── novel_reader_screen.dart  # 小说阅读器
│   │   │
│   │   ├── music/                        # 音乐模块
│   │   │   ├── music_detail_screen.dart  # 歌单/专辑详情
│   │   │   └── music_player_screen.dart  # 全屏播放器
│   │   │
│   │   ├── detail/                       # 视频详情
│   │   ├── player/                       # 视频播放器
│   │   ├── search/                       # 视频搜索
│   │   ├── aggregated/                   # ★ 聚合搜索
│   │   │   └── aggregated_search_screen.dart
│   │   └── setting/                      # 设置
│   │
│   └── widgets/                          # 通用组件
│
├── android/                              # Android + TV
├── ios/                                  # iOS
├── electron/                             # Windows/macOS 桌面
├── web/                                  # Web
└── pubspec.yaml
```

---

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 跨平台框架 | **Flutter 3.2+** | 一套代码 6 平台 |
| 状态管理 | Provider | 全局状态 |
| 视频播放 | media_kit (libmpv) | FFmpeg 全格式 |
| 音乐播放 | media_kit (同引擎) | 后台播放 |
| 图片缓存 | cached_network_image | 漫画/封面/海报 |
| 网络 | http | 轻量高效 |
| 存储 | SharedPreferences | 配置/历史/收藏 |
| Spider 引擎 | HTTP + JSON/XML | 多源聚合 |
| 桌面端 | Electron | Windows/macOS |

---

## 源配置格式

### TVBox V3 视频源
```json
{
  "sites": [
    { "key": "cj.ffzy", "name": "非凡资源", "api": "https://...", "type": 2 }
  ],
  "lives": [
    { "name": "直播源", "type": 0, "url": "http://..." }
  ]
}
```

### 漫画源
```json
{
  "comicSites": [
    { "key": "copymanga", "name": "拷贝漫画", "api": "https://..." }
  ]
}
```

### 小说源
```json
{
  "novelSites": [
    { "key": "bqg", "name": "笔趣阁", "api": "https://..." }
  ]
}
```

### 音乐源
```json
{
  "musicSites": [
    { "key": "netease", "name": "网易云", "api": "https://..." }
  ]
}
```

---

## 构建指南

```bash
# 安装依赖
cd AllPlay && flutter pub get

# Android
flutter build apk --release

# iOS (需 macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release

# Windows/macOS
flutter build windows --release
flutter build macos --release

# Electron 封装 (桌面)
cd electron && npm install && npm run build:win   # Windows
cd electron && npm install && npm run build:mac   # macOS
```

---

## 项目统计

| 指标 | 数值 |
|------|------|
| Dart 源文件 | **36 个** |
| 总代码行数 | **~8,500 行** |
| 平台支持 | 7 个 |
| 媒体类型 | 4 + 直播 |
| 核心模块 | SpiderV2 + MusicPlayer + Reader |
| 内置源 | 视频×5 + 漫画×1 + 小说×1 + 音乐×1 |

---

## 致谢

| 项目 | 借鉴 |
|------|------|
| [TVBox](https://github.com/CatVod/CatVodOpen) | V3 源格式 / Spider 协议 |
| [ZYFun](https://github.com/ReplicateMedia/zyfun) | 多源聚合 / 漫画支持 |
| [ZYPlayer](https://github.com/zyplayer) | 播放器设计 / 历史管理 |
| [亦搜](https://github.com/white37/YiSou) | 全品类聚合 / 简洁 UI |
| [Flutter](https://flutter.dev) | 跨平台框架 |
| [media_kit](https://github.com/media-kit/media-kit) | 媒体播放引擎 |

---

## License

MIT — 自由使用、修改和分发
