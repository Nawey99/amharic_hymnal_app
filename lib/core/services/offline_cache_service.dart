// lib/core/services/offline_cache_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for managing offline cache of data
///
/// Provides functionality to:
/// - Cache data locally for offline access
/// - Track cache version/timestamp
/// - Clear cache when needed
/// - Check cache validity
///
/// This service ensures the app works offline by maintaining
/// a local cache of previously loaded data.
class OfflineCacheService {
  static OfflineCacheService? _instance;
  static OfflineCacheService get instance {
    _instance ??= OfflineCacheService._();
    return _instance!;
  }

  OfflineCacheService._();

  SharedPreferences? _prefs;

  /// Initialize the cache service
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (kDebugMode) {
      debugPrint('✅ OfflineCacheService initialized');
    }
  }

  /// Cache data with a key
  ///
  /// [key] - Unique key for the cached data
  /// [data] - The data to cache (will be JSON encoded)
  /// [expiryDays] - Number of days before cache expires (default: 30)
  Future<bool> cacheData(String key, Map<String, dynamic> data, {int expiryDays = 30}) async {
    await init();
    try {
      final cacheEntry = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiryDays': expiryDays,
      };
      final jsonString = jsonEncode(cacheEntry);
      final success = await _prefs?.setString(key, jsonString) ?? false;
      if (kDebugMode) {
        debugPrint('✅ Cached data for key: $key');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to cache data for key $key: $e');
      }
      return false;
    }
  }

  /// Retrieve cached data
  ///
  /// [key] - The key to retrieve cached data for
  /// Returns the cached data if valid, null otherwise
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    await init();
    try {
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) {
        return null;
      }

      final cacheEntry = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      final expiryDays = cacheEntry['expiryDays'] as int? ?? 30;

      // Check if cache is expired
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final expiryDate = cacheDate.add(Duration(days: expiryDays));
      if (DateTime.now().isAfter(expiryDate)) {
        if (kDebugMode) {
          debugPrint('⚠️ Cache expired for key: $key');
        }
        await clearCache(key);
        return null;
      }

      final data = cacheEntry['data'] as Map<String, dynamic>;
      if (kDebugMode) {
        debugPrint('✅ Retrieved cached data for key: $key');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to retrieve cached data for key $key: $e');
      }
      return null;
    }
  }

  /// Clear cached data for a specific key
  ///
  /// [key] - The key to clear
  Future<bool> clearCache(String key) async {
    await init();
    try {
      final success = await _prefs?.remove(key) ?? false;
      if (kDebugMode) {
        debugPrint('✅ Cleared cache for key: $key');
      }
      return success;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear cache for key $key: $e');
      }
      return false;
    }
  }

  /// Clear all cached data
  Future<bool> clearAllCache() async {
    await init();
    try {
      // Get all keys and filter for cache keys
      final keys = _prefs?.getKeys() ?? {};
      int cleared = 0;
      for (final key in keys) {
        if (key.startsWith('cache_')) {
          await _prefs?.remove(key);
          cleared++;
        }
      }
      if (kDebugMode) {
        debugPrint('✅ Cleared $cleared cache entries');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to clear all cache: $e');
      }
      return false;
    }
  }

  /// Check if cache exists and is valid
  ///
  /// [key] - The key to check
  /// Returns true if valid cache exists, false otherwise
  Future<bool> hasValidCache(String key) async {
    final cached = await getCachedData(key);
    return cached != null;
  }

  /// Get cache timestamp
  ///
  /// [key] - The key to get timestamp for
  /// Returns the timestamp when cache was created, or null if not found
  Future<DateTime?> getCacheTimestamp(String key) async {
    await init();
    try {
      final jsonString = _prefs?.getString(key);
      if (jsonString == null) {
        return null;
      }

      final cacheEntry = jsonDecode(jsonString) as Map<String, dynamic>;
      final timestamp = cacheEntry['timestamp'] as int;
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get cache timestamp for key $key: $e');
      }
      return null;
    }
  }
}

