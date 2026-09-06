import 'dart:convert';

enum PluginLanguage { javascript, python, php, go, java }

class SourcePlugin {
  final String id;
  String name;
  String version;
  String description;
  PluginLanguage language;
  String code;
  bool enabled;
  final DateTime updatedAt;

  SourcePlugin({
    required this.id,
    required this.name,
    this.version = '1.0.0',
    this.description = '',
    this.language = PluginLanguage.javascript,
    this.code = '',
    this.enabled = true,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory SourcePlugin.fromMap(Map<String, dynamic> map) => SourcePlugin(
    id: '${map['id'] ?? ''}',
    name: '${map['name'] ?? ''}',
    version: '${map['version'] ?? '1.0.0'}',
    description: '${map['description'] ?? ''}',
    language: PluginLanguage.values.firstWhere(
      (e) => e.name == map['language'],
      orElse: () => PluginLanguage.javascript,
    ),
    code: '${map['code'] ?? ''}',
    enabled: map['enabled'] ?? true,
    updatedAt: DateTime.tryParse('${map['updatedAt']}'),
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'language': language.name,
    'code': code,
    'enabled': enabled,
    'updatedAt': updatedAt.toIso8601String(),
  };

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toMap());
}
