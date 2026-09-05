/// 视频源模型
class VideoSource {
  final String key;
  final String name;
  final String api;
  final String? playerApi;
  final int type;
  final bool isActive;
  final String mediaType;
  final List<String> headers;

  VideoSource({
    required this.key,
    required this.name,
    required this.api,
    this.playerApi,
    this.type = 2,
    this.isActive = true,
    this.mediaType = 'video',
    this.headers = const [],
  });

  Map<String, dynamic> toJson() => {
    'key': key, 'name': name, 'api': api, 'playerApi': playerApi,
    'type': type, 'isActive': isActive, 'mediaType': mediaType,
  };

  factory VideoSource.fromJson(Map<String, dynamic> json) => VideoSource(
    key: json['key'] ?? json['name'] ?? '',
    name: json['name'] ?? '', api: json['api'] ?? '',
    playerApi: json['playerApi'], type: json['type'] ?? 2,
    isActive: json['isActive'] ?? true,
    mediaType: json['mediaType'] ?? 'video',
  );
}
