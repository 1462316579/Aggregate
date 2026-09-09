import 'package:flutter/material.dart';

/// Lightweight runtime translations used by the app. This avoids generated
/// ARB code and lets changing the language take effect immediately.
class AppStrings {
  final String code;
  const AppStrings(this.code);

  static const supportedCodes = <String>['zh', 'zhHant', 'en', 'ja', 'ko', 'bo', 'yue'];

  static AppStrings of(String value) {
    final normalized = supportedCodes.contains(value) ? value : 'zh';
    return AppStrings(normalized);
  }

  String t(String key) => _values[code]?[key] ?? _values['zh']![key] ?? key;

  static const Map<String, Map<String, String>> _values = <String, Map<String, String>>{
    'zh': <String, String>{
      'home': '首页', 'plugin': '插件', 'settings': '设置', 'search': '搜索',
      'searchHint': '搜索视频、漫画、小说、音乐', 'general': '常规',
      'generalSubtitle': 'TMDB、语言、主题和启动行为', 'tmdbKey': 'TMDB API Key',
      'unset': '未设置', 'language': '语言', 'theme': '主题', 'themeSystem': '跟随系统',
      'themeLight': '浅色', 'themeDark': '深色', 'themeBlack': '纯黑',
      'autoCheckUpdate': '自动检测更新', 'autoCheckUpdateSubtitle': '应用启动时自动检查新版本',
      'nsfw': '显示成人内容', 'nsfwSubtitle': '允许显示成人内容',
      'videoPlayer': '视频播放器', 'videoPlayerSubtitle': '播放引擎、外部播放器和快捷键',
      'externalPlayer': '外部播放器', 'builtinPlayer': '内置播放器',
      'autoPlay': '自动连播', 'autoPlaySubtitle': '播放完成后自动播放下一集',
      'rememberPosition': '记忆播放位置', 'rememberPositionSubtitle': '恢复上次播放进度',
      'hardwareDecode': '硬件解码', 'hardwareDecodeSubtitle': '优先使用设备硬件解码',
      'skipInterval': '跳过间隔', 'skipIntervalSubtitle': '左/右方向键跳过秒数',
      'reader': '阅读器', 'readerSubtitle': '小说与漫画阅读设置',
      'readerMode': '默认阅读模式', 'standard': '标准', 'leftRight': '左右', 'upDown': '上下',
      'preload': '预加载下一页', 'preloadSubtitle': '提前加载下一张图片',
      'imageFit': '图片适应', 'width': '宽度', 'height': '高度', 'original': '原图',
      'volumeTurning': '音量键翻页', 'enabled': '启用', 'disabled': '禁用',
      'network': '网络', 'networkSubtitle': 'User-Agent 和代理协议',
      'userAgent': 'User-Agent', 'defaultSystem': '系统默认', 'proxyType': '代理类型',
      'direct': '直连', 'http': 'HTTP', 'socks4': 'SOCKS4', 'socks5': 'SOCKS5',
      'proxyAddress': '代理地址', 'notSet': '未设置', 'logs': '日志', 'logsSubtitle': '调试日志',
      'saveLog': '保存日志', 'saveLogSubtitle': '保存应用运行日志', 'exportLog': '导出日志',
      'clearLog': '清除日志', 'about': '关于', 'aboutSubtitle': '版本和更新',
      'checkUpdate': '检查更新', 'latest': '当前已是最新版本', 'connectionTest': '连接测试', 'connectionTestSubtitle': '测试当前网络连接', 'sourceManager': '源管理',
      'sourceSubtitle': '管理视频、漫画、小说、音乐源', 'importSources': '导入源配置',
      'exportSources': '导出源配置', 'sourceEmpty': '暂无源', 'addSource': '添加源',
      'sourceName': '源名称', 'apiAddress': 'API 地址', 'cancel': '取消', 'save': '保存',
      'close': '关闭', 'imported': '已导入', 'sources': '个源', 'copied': '配置已复制到剪贴板',
      'tmdbHint': '输入 TMDB API Key', 'confirm': '确定', 'playback': '播放', 'favorites': '收藏', 'history': '历史', 'video': '视频', 'comic': '漫画', 'novel': '小说', 'music': '音乐',
      'webdav': 'WebDAV', 'webdavSubtitle': '云端备份与恢复', 'webdavEnable': '启用 WebDAV', 'webdavEnableSubtitle': '开启后支持云端备份与恢复', 'webdavHost': '服务器地址', 'webdavUsername': '用户名', 'webdavPassword': '密码', 'webdavPath': '远程路径', 'webdavPing': '测试连接', 'webdavBackup': '上传备份', 'webdavRestore': '下载恢复', 'webdavConnected': '连接成功', 'webdavError': '连接失败', 'webdavBackingUp': '正在上传备份...', 'webdavBackupSuccess': '备份上传成功', 'webdavRestoring': '正在恢复...', 'webdavRestoreSuccess': '恢复成功', 'webdavRestoreConfirm': '恢复将覆盖当前所有数据，确定继续？', 'webdavPickFile': '选择备份文件', 'webdavNoFiles': '暂无备份文件', 'ai': 'AI', 'aiSubtitle': 'AI 接口配置', 'aiConfigName': '配置名', 'aiApiUrl': 'API 地址', 'aiApiKey': 'API Key', 'aiModel': '模型', 'gpt-3.5-turbo': 'GPT-3.5 Turbo', 'gpt-4': 'GPT-4', 'gpt-4o': 'GPT-4o', 'plugin': '插件', 'pluginSubtitle': '插件配置', 'pluginRepositoryUrl': '扩展仓库 URL',
    },
    'zhHant': <String, String>{
      'autoPlaySubtitle': '播放完成後自動播放下一集', 'rememberPosition': '記憶播放位置',
      'rememberPositionSubtitle': '恢復上次播放進度', 'hardwareDecode': '硬體解碼',
      'hardwareDecodeSubtitle': '優先使用裝置硬體解碼', 'reader': '閱讀器',
      'readerSubtitle': '小說與漫畫閱讀設定', 'readerMode': '預設閱讀模式',
      'standard': '標準', 'leftRight': '左右', 'upDown': '上下', 'preload': '預載下一頁',
      'preloadSubtitle': '提前載入下一張圖片', 'imageFit': '圖片適應', 'width': '寬度',
      'height': '高度', 'original': '原圖', 'volumeTurning': '音量鍵翻頁', 'enabled': '啟用',
      'disabled': '停用', 'network': '網路', 'networkSubtitle': 'User-Agent 與代理協定',
      'latest': '目前已是最新版本', 'sourceManager': '來源管理', 'sourceSubtitle': '管理影片、漫畫、小說、音樂來源',
      'importSources': '匯入來源設定', 'exportSources': '匯出來源設定', 'sourceEmpty': '暫無來源',
      'addSource': '新增來源', 'sourceName': '來源名稱', 'apiAddress': 'API 位址', 'cancel': '取消',
      'save': '儲存', 'close': '關閉', 'imported': '已匯入', 'sources': '個來源', 'copied': '設定已複製到剪貼簿',
    },
    'en': <String, String>{
      'width': 'Width', 'height': 'Height', 'original': 'Original', 'volumeTurning': 'Volume key paging',
      'enabled': 'Enabled', 'disabled': 'Disabled', 'network': 'Network', 'networkSubtitle': 'User-Agent and proxy protocol',
      'http': 'HTTP', 'socks4': 'SOCKS4', 'socks5': 'SOCKS5', 'proxyAddress': 'Proxy address', 'notSet': 'Not set',
      'logs': 'Logs', 'logsSubtitle': 'Debug logs', 'saveLog': 'Save logs', 'saveLogSubtitle': 'Save application logs',
      'exportLog': 'Export logs', 'clearLog': 'Clear logs', 'about': 'About', 'aboutSubtitle': 'Version and updates',
      'imported': 'Imported', 'sources': ' sources', 'copied': 'Configuration copied to clipboard',
    },
    'ja': <String, String>{
      'tmdbKey': 'TMDB APIキー', 'unset': '未設定', 'language': '言語', 'theme': 'テーマ', 'themeSystem': 'システム',
      'autoCheckUpdateSubtitle': '起動時に新しいバージョンを確認', 'nsfw': '成人向けコンテンツを表示',
      'nsfwSubtitle': '成人向けコンテンツを許可', 'videoPlayer': '動画プレーヤー',
      'videoPlayerSubtitle': '再生エンジン、外部プレーヤー、ショートカット', 'externalPlayer': '外部プレーヤー',
      'builtinPlayer': '内蔵プレーヤー', 'autoPlay': '次の話を自動再生', 'autoPlaySubtitle': '再生終了後に次の話を再生',
      'networkSubtitle': 'User-Agent とプロキシ', 'userAgent': 'User-Agent', 'defaultSystem': 'システム既定',
      'proxyType': 'プロキシタイプ', 'direct': '直接接続', 'http': 'HTTP', 'socks4': 'SOCKS4', 'socks5': 'SOCKS5',
      'about': '情報', 'aboutSubtitle': 'バージョンと更新', 'checkUpdate': '更新を確認', 'latest': '最新版です',
      'sourceManager': 'ソース管理', 'sourceSubtitle': '動画、漫画、小説、音楽ソースを管理', 'importSources': 'ソース設定をインポート',
    },
    'ko': <String, String>{
      'general': '일반', 'generalSubtitle': 'TMDB, 언어, 테마 및 시작 동작', 'tmdbKey': 'TMDB API 키', 'unset': '설정 안 됨',
      'language': '언어', 'theme': '테마', 'themeSystem': '시스템', 'themeLight': '라이트', 'themeDark': '다크', 'themeBlack': '블랙',
    },
    'bo': <String, String>{
    },
    'yue': <String, String>{
    },
  };

  Locale get locale {
    if (code == 'zhHant') return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant');
    if (code == 'bo') return const Locale('bo');
    if (code == 'yue') return const Locale('yue');
    return Locale(code);
  }
}
