import 'dart:convert';
import '../models/content.dart';

class ConfigTransferService {
  static String exportSources(List<SourceDefinition> sources) {
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'hongxi-sources',
      'version': 1,
      'sources': sources.map((e) => e.toMap()).toList(),
    });
  }

  static List<SourceDefinition> importSources(String value) {
    final decoded = jsonDecode(value);
    if (decoded is List) {
      return decoded.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e))).toList();
    }
    if (decoded is Map) {
      final root = Map<String, dynamic>.from(decoded);
      final result = <SourceDefinition>[];
      final values = root['sources'] ?? root['sites'] ?? root['videoSites'];
      if (values is List) {
        result.addAll(values.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e), forcedType: ContentType.video)));
      }
      final comics = root['comicSites'];
      if (comics is List) {
        result.addAll(comics.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e), forcedType: ContentType.comic)));
      }
      final novels = root['novelSites'];
      if (novels is List) {
        result.addAll(novels.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e), forcedType: ContentType.novel)));
      }
      final music = root['musicSites'];
      if (music is List) {
        result.addAll(music.whereType<Map>().map((e) => SourceDefinition.fromMap(Map<String, dynamic>.from(e), forcedType: ContentType.music)));
      }
      return result;
    }
    return [];
  }
}
