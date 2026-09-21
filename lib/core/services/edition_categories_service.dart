import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// One of an edition's own categories, as `GET /categories` lists it.
class EditionCategory {
  final String slug;
  final String name;
  final String? englishName;
  final int sortOrder;

  const EditionCategory({
    required this.slug,
    required this.name,
    required this.sortOrder,
    this.englishName,
  });

  static EditionCategory? fromJson(Object? value) {
    if (value is! Map) return null;
    final slug = value['slug'];
    final name = value['name'];
    if (slug is! String || name is! String || name.isEmpty) return null;
    final sortOrder = value['sortOrder'];
    final englishName = value['englishName'];
    return EditionCategory(
      slug: slug,
      name: name,
      sortOrder: sortOrder is int ? sortOrder : 0,
      englishName: englishName is String ? englishName : null,
    );
  }

  Map<String, Object?> toJson() => {
        'slug': slug,
        'name': name,
        'englishName': englishName,
        'sortOrder': sortOrder,
      };
}

/// A category on the category screen: its name and its hymns.
class CategoryGroup {
  final String name;
  final String? slug;
  final List<Hymn> hymns;

  const CategoryGroup({required this.name, required this.hymns, this.slug});
}

/// Each edition's categories. The 1961, 1975 and 2004 books group their
/// hymns differently, so the category screen is built from the edition being
/// read: the hymns carry their category name (from `/sync`), and
/// `/categories` supplies the book's order and each category's slug.
///
/// The list is kept per edition on the device, so the screen keeps its
/// order offline.
class EditionCategoriesService {
  EditionCategoriesService({http.Client? client, String? baseUrl})
      : _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl;

  static final EditionCategoriesService instance = EditionCategoriesService();

  static const _storageKeyPrefix = 'edition_categories_';

  final HymnalApiClient _api;
  final String? _baseUrl;
  final Map<String, List<EditionCategory>> _byCode = {};
  final Map<String, Future<List<EditionCategory>>> _loading = {};

  /// What is already known for [version], without waiting.
  List<EditionCategory> cached(String version) =>
      _byCode[HymnalVersions.apiCode(version)] ?? const [];

  /// The slug of the category called [name] in [version], if known.
  String? slugFor(String version, String name) {
    for (final category in cached(version)) {
      if (category.name == name) return category.slug;
    }
    return null;
  }

  /// Loads [version]'s categories: from the API, else the stored copy.
  /// Never throws; an unknown edition has none.
  Future<List<EditionCategory>> load(String version) {
    final code = HymnalVersions.apiCode(version);
    return _loading[code] ??= _load(code).whenComplete(() {
      _loading.remove(code);
    });
  }

  Future<List<EditionCategory>> _load(String code) async {
    try {
      final uri =
          Uri.parse('${_baseUrl ?? ContentApiConfig.baseUrl}/categories')
              .replace(queryParameters: {'language': 'am', 'version': code});
      final response = await _api.get(
        uri,
        timeout: const Duration(seconds: 8),
        conditional: true,
      );
      final data = decodeHymnalApiData(response);
      final categories = (data is List ? data : const [])
          .map(EditionCategory.fromJson)
          .whereType<EditionCategory>()
          .toList(growable: false);
      _byCode[code] = categories;
      await _store(code, categories);
      return categories;
    } catch (_) {
      final stored = await _read(code);
      if (stored != null) _byCode[code] = stored;
      return _byCode[code] ?? const [];
    }
  }

  Future<void> _store(String code, List<EditionCategory> categories) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_storageKeyPrefix$code',
        jsonEncode(categories.map((category) => category.toJson()).toList()),
      );
    } catch (_) {
      // The in-memory copy still serves this session.
    }
  }

  Future<List<EditionCategory>?> _read(String code) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString('$_storageKeyPrefix$code');
      if (value == null) return null;
      final decoded = jsonDecode(value);
      return (decoded is List ? decoded : const [])
          .map(EditionCategory.fromJson)
          .whereType<EditionCategory>()
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  /// Groups [hymns] by their category, in the book's order when
  /// [categories] gives one, else by each category's lowest hymn number.
  /// Hymns without a category are left out.
  static List<CategoryGroup> group(
    List<Hymn> hymns,
    List<EditionCategory> categories,
  ) {
    final byName = <String, List<Hymn>>{};
    for (final hymn in hymns) {
      final name = hymn.category?.trim();
      if (name == null || name.isEmpty) continue;
      byName.putIfAbsent(name, () => []).add(hymn);
    }
    for (final list in byName.values) {
      list.sort((a, b) => a.displayNumber.compareTo(b.displayNumber));
    }

    final known = {for (final category in categories) category.name: category};
    int lowest(List<Hymn> list) =>
        list.isEmpty ? 1 << 30 : list.first.displayNumber;

    final names = byName.keys.toList()
      ..sort((a, b) {
        final orderA = known[a]?.sortOrder;
        final orderB = known[b]?.sortOrder;
        if (orderA != null && orderB != null && orderA != orderB) {
          return orderA.compareTo(orderB);
        }
        // Categories the list does not name yet go after those it does.
        if (orderA != null && orderB == null) return -1;
        if (orderA == null && orderB != null) return 1;
        return lowest(byName[a]!).compareTo(lowest(byName[b]!));
      });

    return [
      for (final name in names)
        CategoryGroup(
            name: name, slug: known[name]?.slug, hymns: byName[name]!),
    ];
  }
}
