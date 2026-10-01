// lib/core/database/json_data_source.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:amharic_hymnal_app/core/database/parsers/hagerigna_parser.dart';
import 'package:amharic_hymnal_app/core/database/parsers/sda_parser.dart';
import 'package:amharic_hymnal_app/core/models/database_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

/// Fast JSON-based data source that loads directly from assets
/// Used for immediate data access while database migration runs in background
class JsonDataSource {
  static final JsonDataSource instance = JsonDataSource._init();

  // In-memory cache for parsed hymns
  final Map<String, List<Map<String, dynamic>>> _cache = {};

  /// Loads in progress, so callers asking at the same time share one read.
  final Map<String, Future<List<Map<String, dynamic>>>> _inFlight = {};

  JsonDataSource._init();

  /// Get hymns from JSON assets (very fast, no database needed)
  /// Returns cached data if available, otherwise loads and caches.
  ///
  /// An edition with no bundled copy returns an empty list. A bundled copy
  /// that cannot be read throws: an empty hymnal would hide the fault.
  Future<List<Map<String, dynamic>>> getHymns(
    String languageCode,
    String version,
  ) async {
    final normalizedVersion = HymnalVersions.normalizeId(version);
    final cacheKey = '${languageCode}_$normalizedVersion';

    final cached = _cache[cacheKey];
    if (cached != null) {
      if (kDebugMode) {
        debugPrint(
            '📦 Returning cached JSON data for $languageCode/$version (${cached.length} hymns)');
      }
      return cached;
    }

    final dbConfig =
        DatabaseRegistry.getDatabase(languageCode, normalizedVersion);
    if (dbConfig == null) {
      if (kDebugMode) {
        debugPrint('⚠️ No database config found for $languageCode/$version');
      }
      return [];
    }

    // A block body: returning the removed future would make whenComplete
    // wait on itself.
    return _inFlight[cacheKey] ??= _load(
      dbConfig,
      languageCode,
      normalizedVersion,
      cacheKey,
    ).whenComplete(() {
      _inFlight.remove(cacheKey);
    });
  }

  Future<List<Map<String, dynamic>>> _load(
    DatabaseConfig dbConfig,
    String languageCode,
    String normalizedVersion,
    String cacheKey,
  ) async {
    if (kDebugMode) {
      debugPrint('⚡ Loading hymns from JSON: ${dbConfig.filePath}');
    }

    final String jsonString = await rootBundle.loadString(dbConfig.filePath);
    final dynamic jsonData = json.decode(jsonString);
    if (jsonData is! Map<String, dynamic>) {
      throw FormatException('${dbConfig.filePath} is not a JSON object.');
    }

    // Parse based on version
    final List<Map<String, dynamic>> hymns;
    if (normalizedVersion == HymnalVersions.hagerigna) {
      hymns = HagerignaParser.parse(jsonData);
    } else if (HymnalVersions.isSda(normalizedVersion)) {
      hymns = SdaParser.parse(jsonData, version: normalizedVersion);
    } else {
      if (kDebugMode) {
        debugPrint('⚠️ Unknown version: $normalizedVersion');
      }
      return [];
    }

    _cache[cacheKey] = hymns;

    if (kDebugMode) {
      debugPrint(
          '✅ Loaded ${hymns.length} hymns from JSON for $languageCode/$normalizedVersion');
    }

    return hymns;
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _cache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ JSON data cache cleared');
    }
  }

  /// Check if data is cached
  bool isCached(String languageCode, String version) {
    final cacheKey = '${languageCode}_${HymnalVersions.normalizeId(version)}';
    return _cache.containsKey(cacheKey);
  }
}
