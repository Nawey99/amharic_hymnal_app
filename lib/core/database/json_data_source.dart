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
  bool _isLoading = false;

  JsonDataSource._init();

  /// Get hymns from JSON assets (very fast, no database needed)
  /// Returns cached data if available, otherwise loads and caches
  Future<List<Map<String, dynamic>>> getHymns(
    String languageCode,
    String version,
  ) async {
    final normalizedVersion = HymnalVersions.normalizeId(version);
    final cacheKey = '${languageCode}_$normalizedVersion';

    // Return cached data if available
    if (_cache.containsKey(cacheKey)) {
      if (kDebugMode) {
        debugPrint(
            '📦 Returning cached JSON data for $languageCode/$version (${_cache[cacheKey]!.length} hymns)');
      }
      return _cache[cacheKey]!;
    }

    // Prevent concurrent loading
    if (_isLoading) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 100));
      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      }
    }

    try {
      _isLoading = true;

      // Get database config to find the JSON file path
      final dbConfig =
          DatabaseRegistry.getDatabase(languageCode, normalizedVersion);
      if (dbConfig == null) {
        if (kDebugMode) {
          debugPrint('⚠️ No database config found for $languageCode/$version');
        }
        return [];
      }

      if (kDebugMode) {
        debugPrint('⚡ Loading hymns from JSON: ${dbConfig.filePath}');
      }

      // Load JSON file
      final String jsonString = await rootBundle.loadString(dbConfig.filePath);
      final dynamic jsonData = json.decode(jsonString);

      // Parse based on version
      List<Map<String, dynamic>> hymns;
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

      // Cache the parsed data
      _cache[cacheKey] = hymns;

      if (kDebugMode) {
        debugPrint(
            '✅ Loaded ${hymns.length} hymns from JSON for $languageCode/$normalizedVersion');
      }

      return hymns;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to load JSON data for $languageCode/$version: $e');
      }
      return [];
    } finally {
      _isLoading = false;
    }
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
