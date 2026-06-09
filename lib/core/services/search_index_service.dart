// lib/core/services/search_index_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/core/services/amharic_phonetic_service.dart';

/// Prebuilt search index service
/// 
/// Features:
/// - Builds normalized search index on app start
/// - Caches per language-version combination
/// - Normalizes all searchable fields
/// - Immutable after build
/// - Cold start optimization (builds in background)
/// 
/// Architecture: This service pre-builds normalized search indexes to avoid
/// recomputing normalization for every keystroke. The index is built once
/// per language-version combination and cached in memory.
class SearchIndexService {
  static final SearchIndexService _instance = SearchIndexService._internal();
  factory SearchIndexService() => _instance;
  SearchIndexService._internal();

  // Cache: Key = "languageCode-version", Value = normalized index
  // Index: Key = hymn ID, Value = normalized searchable text
  final Map<String, Map<String, String>> _indexCache = {};
  
  // Track which indexes are currently being built (to avoid duplicate builds)
  final Set<String> _buildingIndexes = {};
  
  // Validation logs (disabled by default, can be enabled for debugging)
  bool _enableValidationLogs = false;

  /// Get or build normalized search index for a language-version combination
  /// 
  /// [languageCode] - Language code (e.g., "am", "en")
  /// [version] - Version (e.g., "hymnal", "hagerigna")
  /// [hymns] - List of hymns to index (immutable)
  /// 
  /// Returns: Map of hymn ID to normalized searchable text
  /// 
  /// If index is already built, returns cached version immediately.
  /// If not built, builds it synchronously (should be called in background).
  Future<Map<String, String>> getIndex({
    required String languageCode,
    required String version,
    required List<Hymn> hymns,
  }) async {
    final indexKey = '$languageCode-$version';
    
    // Return cached index if available
    if (_indexCache.containsKey(indexKey)) {
      if (_enableValidationLogs && kDebugMode) {
        debugPrint('📊 [SearchIndexService] Using cached index for $indexKey');
      }
      return _indexCache[indexKey]!;
    }

    // Check if already building (avoid duplicate builds)
    if (_buildingIndexes.contains(indexKey)) {
      // Wait a bit and retry
      await Future.delayed(const Duration(milliseconds: 100));
      if (_indexCache.containsKey(indexKey)) {
        return _indexCache[indexKey]!;
      }
    }

    // Build index
    _buildingIndexes.add(indexKey);
    try {
      final startTime = DateTime.now();
      final index = _buildIndex(hymns);
      _indexCache[indexKey] = index;
      final duration = DateTime.now().difference(startTime);
      
      if (_enableValidationLogs && kDebugMode) {
        debugPrint('📊 [SearchIndexService] Built index for $indexKey: ${index.length} hymns in ${duration.inMilliseconds}ms');
      }
      
      return index;
    } finally {
      _buildingIndexes.remove(indexKey);
    }
  }

  /// Build normalized search index from hymns
  /// 
  /// Normalizes all searchable fields:
  /// - Titles (Amharic + English)
  /// - Lyrics (Amharic + English)
  /// - Author/composer
  /// - Hymn numbers
  /// 
  /// Returns: Map of hymn ID to normalized searchable text
  Map<String, String> _buildIndex(List<Hymn> hymns) {
    final Map<String, String> index = {};
    
    for (final hymn in hymns) {
      final hymnId = hymn.id ?? '${hymn.displayNumber}';
      
      // Concatenate ALL searchable fields for comprehensive search
      final searchableText = [
        hymn.displayTitle,           // Primary Amharic title
        hymn.displayLyrics,          // Primary lyrics
        hymn.artist ?? '',           // Artist/author
        hymn.song ?? '',             // Song text (Hagerigna)
        hymn.newHymnalTitle ?? '',   // SDA new hymnal title
        hymn.oldHymnalTitle ?? '',   // SDA old hymnal title
        hymn.englishTitleOld ?? '',  // English title (important for bilingual search)
        hymn.newHymnalLyrics ?? '',  // SDA new hymnal lyrics
        hymn.oldHymnalLyrics ?? '',  // SDA old hymnal lyrics
        hymn.displayNumber.toString(), // Hymn number (as string for search)
      ].join(' ');
      
      // Normalize Amharic text for phonetic matching
      // This ensures all phonetic variants map to the same canonical form
      final normalized = AmharicPhoneticService.normalizeAmharic(searchableText);
      index[hymnId] = normalized;
    }
    
    return index;
  }

  /// Pre-build index for a language-version combination (background task)
  /// 
  /// This should be called during app initialization to warm up the cache.
  /// It runs in the background and doesn't block the UI.
  Future<void> prebuildIndex({
    required String languageCode,
    required String version,
    required List<Hymn> hymns,
  }) async {
    final indexKey = '$languageCode-$version';
    
    // Skip if already cached or building
    if (_indexCache.containsKey(indexKey) || _buildingIndexes.contains(indexKey)) {
      return;
    }

    // Build in background (fire and forget)
    getIndex(
      languageCode: languageCode,
      version: version,
      hymns: hymns,
    ).catchError((e) {
      if (kDebugMode) {
        debugPrint('⚠️ Failed to prebuild search index: $e');
      }
      // Return empty map on error (fire and forget, error is non-critical)
      return <String, String>{};
    });
  }

  /// Clear index cache for a specific language-version combination
  /// 
  /// Useful when language/version changes to free memory.
  void clearIndex(String languageCode, String version) {
    final indexKey = '$languageCode-$version';
    _indexCache.remove(indexKey);
    if (_enableValidationLogs && kDebugMode) {
      debugPrint('📊 [SearchIndexService] Cleared index for $indexKey');
    }
  }

  /// Clear all index caches
  /// 
  /// Useful for memory management or testing.
  void clearAllIndexes() {
    _indexCache.clear();
    if (_enableValidationLogs && kDebugMode) {
      debugPrint('📊 [SearchIndexService] Cleared all indexes');
    }
  }

  /// Check if index is cached for a language-version combination
  bool hasIndex(String languageCode, String version) {
    final indexKey = '$languageCode-$version';
    return _indexCache.containsKey(indexKey);
  }

  /// Get cache statistics (for debugging)
  Map<String, int> getCacheStats() {
    return {
      'cached_indexes': _indexCache.length,
      'total_hymns_indexed': _indexCache.values.fold<int>(
        0,
        (sum, index) => sum + index.length,
      ),
    };
  }

  /// Disable validation logs (call after testing)
  void disableValidationLogs() {
    _enableValidationLogs = false;
  }
}

