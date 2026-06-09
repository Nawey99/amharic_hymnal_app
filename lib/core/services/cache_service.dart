// lib/core/services/cache_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amharic_hymnal_app/core/database/database_helper.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

/// Service to manage and monitor offline data caching
class CacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Check if hymns are cached for a language/version
  static Future<bool> isCached(String languageCode, String version) async {
    try {
      final hymns =
          await DatabaseHelper.instance.getHymns(languageCode, version);
      return hymns.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get cache status for all languages/versions
  static Future<Map<String, bool>> getCacheStatus() async {
    final status = <String, bool>{};
    try {
      // Check for common language/version combinations
      final amHagerigna = await isCached('am', 'hagerigna');
      if (amHagerigna) status['am_hagerigna'] = true;

      final amHymnal = await isCached('am', 'hymnal');
      if (amHymnal) status['am_hymnal'] = true;
    } catch (e) {
      // Return empty map on error
    }
    return status;
  }

  /// Get total number of cached hymns
  static Future<int> getCachedHymnCount() async {
    try {
      final db = DatabaseHelper.instance.database;
      final result = await db.customSelect(
        'SELECT COUNT(*) as count FROM hymns',
        readsFrom: {db.hymns},
      ).getSingle();
      return result.read<int>('count');
    } catch (e) {
      return 0;
    }
  }

  /// Get cache size estimate (approximate)
  static Future<int> getCacheSizeBytes() async {
    try {
      // SQLite doesn't have a direct way to get database size
      // We'll estimate based on row count and average size
      final count = await getCachedHymnCount();
      // Rough estimate: ~2KB per hymn (title, lyrics, metadata)
      return count * 2048;
    } catch (e) {
      return 0;
    }
  }

  /// Get formatted cache size string
  static Future<String> getCacheSizeFormatted() async {
    final bytes = await getCacheSizeBytes();
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Check if cache is healthy (has data and is accessible)
  static Future<bool> isCacheHealthy() async {
    try {
      final count = await getCachedHymnCount();
      return count > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get last cache update time
  static Future<DateTime?> getLastCacheUpdate(
      String languageCode, String version) async {
    try {
      final hymns =
          await DatabaseHelper.instance.getHymns(languageCode, version);
      if (hymns.isNotEmpty) {
        // Get the most recent updated_at timestamp
        int? maxTimestamp;
        for (final hymn in hymns) {
          final timestamp = hymn['updated_at'] as int?;
          if (timestamp != null) {
            if (maxTimestamp == null || timestamp > maxTimestamp) {
              maxTimestamp = timestamp;
            }
          }
        }
        if (maxTimestamp != null) {
          return DateTime.fromMillisecondsSinceEpoch(maxTimestamp);
        }
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }

  /// Mark cache as updated
  static Future<void> markCacheUpdated(
      String languageCode, String version) async {
    await _prefs?.setInt(
      '${AppConstants.keyCacheUpdated}_${languageCode}_$version',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Clear cache for a specific language/version
  static Future<void> clearCache(String languageCode, String version) async {
    try {
      await DatabaseHelper.instance.clearHymns(languageCode, version);
      await _prefs
          ?.remove('${AppConstants.keyCacheUpdated}_${languageCode}_$version');
    } catch (e) {
      // Ignore errors
    }
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    try {
      // Clear all known language/version combinations
      await clearCache('am', 'hagerigna');
      await clearCache('am', 'hymnal');
      // Clear all cache update timestamps
      final keys = _prefs?.getKeys() ?? {};
      for (final key in keys) {
        if (key.startsWith('${AppConstants.keyCacheUpdated}_')) {
          await _prefs?.remove(key);
        }
      }
    } catch (e) {
      // Ignore errors
    }
  }

  /// Verify cache integrity
  static Future<CacheIntegrityResult> verifyCacheIntegrity() async {
    try {
      final db = DatabaseHelper.instance.database;

      // Check for hymns with missing required fields
      final invalidHymns = await db.customSelect(
        '''
        SELECT COUNT(*) as count 
        FROM hymns 
        WHERE id IS NULL OR language_code IS NULL OR version IS NULL
        ''',
        readsFrom: {db.hymns},
      ).getSingle();

      final invalidCount = invalidHymns.read<int>('count');

      // Check for duplicate IDs
      final duplicates = await db.customSelect(
        '''
        SELECT id, COUNT(*) as count 
        FROM hymns 
        GROUP BY id 
        HAVING COUNT(*) > 1
        ''',
        readsFrom: {db.hymns},
      ).get();

      final duplicateCount = duplicates.length;

      return CacheIntegrityResult(
        isValid: invalidCount == 0 && duplicateCount == 0,
        invalidRecordCount: invalidCount,
        duplicateCount: duplicateCount,
      );
    } catch (e) {
      return CacheIntegrityResult(
        isValid: false,
        invalidRecordCount: -1,
        duplicateCount: -1,
        error: e.toString(),
      );
    }
  }
}

class CacheIntegrityResult {
  final bool isValid;
  final int invalidRecordCount;
  final int duplicateCount;
  final String? error;

  CacheIntegrityResult({
    required this.isValid,
    required this.invalidRecordCount,
    required this.duplicateCount,
    this.error,
  });
}
