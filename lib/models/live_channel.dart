/// 直播频道
class LiveChannel {
  final String name;
  final String logo;
  final String url;
  final String group;

  LiveChannel({
    required this.name,
    this.logo = '',
    required this.url,
    this.group = '',
  });

  /// 解析 M3U 格式
  static List<LiveChannel> parseM3u(String content) {
    List<LiveChannel> channels = [];
    final lines = content.split('\n');
    String? currentGroup = '';
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        // 解析 EXTINF 行
        final groupMatch = RegExp(r'group-title="([^"]*)"').firstMatch(line);
        currentGroup = groupMatch?.group(1) ?? '';
        final logoMatch = RegExp(r'tvg-logo="([^"]*)"').firstMatch(line);
        final logo = logoMatch?.group(1) ?? '';
        final nameStart = line.lastIndexOf(',');
        final name = nameStart >= 0 ? line.substring(nameStart + 1).trim() : '';
        
        // 下一行应该是 URL
        if (i + 1 < lines.length) {
          final url = lines[i + 1].trim();
          if (!url.startsWith('#')) {
            channels.add(LiveChannel(
              name: name,
              logo: logo,
              url: url,
              group: currentGroup,
            ));
          }
        }
      }
    }
    
    return channels;
  }

  /// 解析 TXT/列表格式 (TVBox 格式)
  static List<LiveChannel> parseTxt(String content) {
    List<LiveChannel> channels = [];
    String currentGroup = '默认';
    
    for (var line in content.split('\n')) {
      line = line.trim();
      if (line.isEmpty) continue;
      
      if (line.endsWith(',') || line.endsWith('#') || line.endsWith('group')) {
        currentGroup = line.replaceAll(RegExp(r'[,#\s]+$'), '');
      } else if (line.contains(',')) {
        final parts = line.split(',');
        if (parts.length >= 2) {
          channels.add(LiveChannel(
            name: parts[0].trim(),
            url: parts[1].trim(),
            group: currentGroup,
          ));
        }
      } else if (line.startsWith('http')) {
        channels.add(LiveChannel(
          name: channels.length + 1,
          url: line,
          group: currentGroup,
        ).copyWithIndex(channels.length + 1));
      }
    }
    
    return channels;
  }
}

/// 扩展方法用于设置无名称频道的名称
extension _LiveChannelHelper on LiveChannel {
  LiveChannel copyWithIndex(int index) => LiveChannel(
    name: '频道$index',
    logo: logo,
    url: url,
    group: group,
  );
}
