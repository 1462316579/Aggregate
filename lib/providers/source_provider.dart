import 'package:flutter/foundation.dart';
import '../models/content.dart';
import '../services/app_config.dart';
import '../services/source_service.dart';

class SourceProvider extends ChangeNotifier {
  final SourceService service;
  List<SourceDefinition> _sources = [];
  bool _loading = true;

  SourceProvider({SourceService? service}) : service = service ?? const SourceService();

  List<SourceDefinition> get sources => List.unmodifiable(_sources);
  bool get loading => _loading;
  List<SourceDefinition> get enabledSources => _sources.where((e) => e.enabled).toList();

  Future<void> init() async {
    _loading = true;
    notifyListeners();
    _sources = await AppConfig.getSources();
    _loading = false;
    notifyListeners();
  }

  Future<SearchResult> search(String query, {ContentType? type, SourceDefinition? only}) async {
    final targets = only != null
        ? [only]
        : enabledSources.where((s) => type == null || s.type == type).toList();
    final results = await Future.wait(targets.map((source) => service.search(source, query)));
    final items = <MediaItem>[];
    final errors = <String, String>{};
    for (final result in results) {
      items.addAll(result.items);
      errors.addAll(result.errors);
    }
    return SearchResult(query: query, items: items, errors: errors);
  }

  Future<List<MediaItem>> category({String? categoryId, int page = 1, ContentType type = ContentType.video}) async {
    final source = enabledSources.where((s) => s.type == type).firstOrNull;
    if (source == null) return [];
    return service.category(source, categoryId: categoryId, page: page);
  }

  Future<List<SourceCategory>> categories(SourceDefinition source) {
    return service.categories(source);
  }

  Future<String> chapterContent(String sourceId, String url) async {
    final source = sourceFor(sourceId);
    return source == null ? '' : service.chapterContent(source, url);
  }

  Future<List<String>> chapterImages(String sourceId, String url) async {
    final source = sourceFor(sourceId);
    return source == null ? [] : service.chapterImages(source, url);
  }

  SourceDefinition? sourceFor(String id) {
    return _sources.where((source) => source.id == id).firstOrNull;
  }

  Future<MediaItem?> detail(MediaItem item) async {
    final source = sourceFor(item.sourceId);
    return source == null ? null : service.detail(source, item.id);
  }

  Future<LocalShelf> localShelf() async {
    final history = await AppConfig.getHistory();
    final favorites = await AppConfig.getFavorites();
    return LocalShelf(
      history: history.map(_storedItem).toList(),
      favorites: favorites.map(_storedItem).toList(),
    );
  }

  MediaItem _storedItem(Map<String, dynamic> value) {
    final typeName = value['type']?.toString() ?? 'video';
    final type = ContentType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => ContentType.video,
    );
    return MediaItem.fromMap(value, value['sourceId']?.toString() ?? '', type);
  }

  Future<void> addSource(SourceDefinition source) async {
    _sources = [..._sources.where((e) => e.id != source.id), source];
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  Future<void> addSources(List<SourceDefinition> values) async {
    for (final value in values) {
      _sources = [..._sources.where((e) => e.id != value.id), value];
    }
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  Future<void> removeSource(String id) async {
    _sources = _sources.where((e) => e.id != id).toList();
    await AppConfig.saveSources(_sources);
    notifyListeners();
  }

  Future<void> toggleSource(SourceDefinition source) async {
    await addSource(source.copyWith(enabled: !source.enabled));
  }

  Future<List<String>> searchHistory() => AppConfig.getSearchHistory();
  Future<void> addSearchHistory(String value) => AppConfig.addSearchHistory(value);
}

class LocalShelf {
  final List<MediaItem> history;
  final List<MediaItem> favorites;
  const LocalShelf({required this.history, required this.favorites});
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
