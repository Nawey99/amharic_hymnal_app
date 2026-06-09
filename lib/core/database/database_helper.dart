// lib/core/database/database_helper.dart
import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/core/database/app_database.dart';
import 'package:amharic_hymnal_app/core/database/database_migration.dart';

/// Singleton helper class for database operations
///
/// Provides a high-level interface to the Drift database with:
/// - Ready state management
/// - Graceful error handling (returns empty lists/null instead of throwing)
/// - Data mapping between database and application models
///
/// All methods check if the database is ready before executing queries.
/// If not ready, methods return safe defaults (empty lists, null) to prevent app crashes.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  final AppDatabase _database;
  bool _isInitialized = false;
  bool _isReady = false;
  String? _initializationError;
  final _readyStreamController = StreamController<bool>.broadcast();

  // Query result cache for static data (hymns don't change frequently)
  final Map<String, List<Map<String, dynamic>>> _hymnsCache = {};
  final Map<String, Map<String, dynamic>?> _hymnByIdCache = {};
  final Map<String, Map<String, dynamic>?> _hymnByNumberCache = {};

  /// Clear query cache (call after updates that modify hymns)
  void clearCache() {
    _hymnsCache.clear();
    _hymnByIdCache.clear();
    _hymnByNumberCache.clear();
    if (kDebugMode) {
      debugPrint('🗑️ Cleared database query cache');
    }
  }

  DatabaseHelper._init() : _database = AppDatabase();

  AppDatabase get database => _database;

  /// Mark database as initialized
  void markInitialized() {
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('✅ Database marked as initialized');
    }
  }

  /// Mark database as ready (migration completed)
  void markReady() {
    _isReady = true;
    _initializationError = null;
    if (kDebugMode) {
      debugPrint('✅ Database marked as ready');
    }
    // Emit readiness event to stream
    if (!_readyStreamController.isClosed) {
      _readyStreamController.add(true);
    }
  }

  /// Stream that emits when database becomes ready
  Stream<bool> get readyStream => _readyStreamController.stream;

  /// Mark database initialization as failed
  void markFailed(String error) {
    _initializationError = error;
    if (kDebugMode) {
      debugPrint('❌ Database initialization failed: $error');
    }
  }

  /// Check if database is ready for queries
  bool get isReady => _isInitialized && _isReady;

  /// Get initialization error if any
  String? get initializationError => _initializationError;

  /// Wait for database to be ready (with timeout and optimized exponential backoff)
  Future<bool> waitForReady(
      {Duration timeout = const Duration(seconds: 30)}) async {
    if (isReady) return true;

    if (_initializationError != null) {
      if (kDebugMode) {
        debugPrint('⚠️ Database initialization failed: $_initializationError');
      }
      return false;
    }

    final startTime = DateTime.now();
    int retryCount = 0;
    const baseDelay = Duration(milliseconds: 50);
    const maxDelay = Duration(milliseconds: 500);

    while (!isReady) {
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed > timeout) {
        if (kDebugMode) {
          debugPrint(
              '⚠️ Database ready timeout after ${timeout.inSeconds} seconds');
        }
        return false;
      }

      // Optimized polling: 50ms, 100ms, 200ms, then exponential backoff capped at 500ms
      int delayMs;
      if (retryCount < 3) {
        // More aggressive at start: 50ms, 100ms, 200ms
        delayMs = baseDelay.inMilliseconds * (1 << retryCount);
      } else {
        // Exponential backoff after initial aggressive polling
        delayMs = (baseDelay.inMilliseconds * (1 << (retryCount - 1))).clamp(
          baseDelay.inMilliseconds,
          maxDelay.inMilliseconds,
        );
      }
      await Future.delayed(Duration(milliseconds: delayMs));
      retryCount++;
    }
    return true;
  }

  /// Ensure database is ready before executing query
  /// Returns true if ready, false if not ready (non-blocking)
  /// Uses exponential backoff retry mechanism
  Future<bool> _ensureReady(
      {bool throwOnError = false, Duration? customTimeout}) async {
    if (isReady) return true;

    if (_initializationError != null && throwOnError) {
      throw Exception('Database initialization failed: $_initializationError');
    }

    // Use longer timeout with exponential backoff retry
    final timeout = customTimeout ?? const Duration(seconds: 30);
    final ready = await waitForReady(timeout: timeout);

    if (!ready && throwOnError) {
      throw Exception(
          'Database not ready. Initialization may still be in progress. '
          'Please wait and try again. ${_initializationError != null ? "Error: $_initializationError" : ""}');
    }
    return ready;
  }

  // Insert hymn
  Future<int> insertHymn(Map<String, dynamic> hymn) async {
    final companion = _mapToCompanion(hymn);
    return await _database.insertHymn(companion);
  }

  // Insert multiple hymns
  Future<void> insertHymns(List<Map<String, dynamic>> hymns) async {
    final companions = hymns.map((h) => _mapToCompanion(h)).toList();
    await _database.insertHymns(companions);
  }

  // Get all hymns for a language and version
  Future<List<Map<String, dynamic>>> getHymns(
    String languageCode,
    String version,
  ) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Database not ready, returning empty list for $languageCode/$version');
      }
      return [];
    }

    // Check cache first
    final cacheKey = '${languageCode}_$version';
    if (_hymnsCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        debugPrint(
            '📦 Returning cached hymns for $cacheKey (${_hymnsCache[cacheKey]!.length} hymns)');
      }
      return _hymnsCache[cacheKey]!;
    }

    try {
      final hymnData = await _database.getHymns(languageCode, version);
      if (kDebugMode) {
        debugPrint(
            '📖 Retrieved ${hymnData.length} hymns for $languageCode/$version');
      }
      final mapped = hymnData.map((h) => _mapToMap(h)).toList();
      // Cache the results
      _hymnsCache[cacheKey] = mapped;
      return mapped;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get hymns: $e');
      }
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Get hymn by ID
  Future<Map<String, dynamic>?> getHymnById(String id) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint('⚠️ Database not ready, cannot get hymn by ID $id');
      }
      return null;
    }
    try {
      final hymn = await _database.getHymnById(id);
      return hymn != null ? _mapToMap(hymn) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get hymn by ID $id: $e');
      }
      // Return null instead of throwing to prevent app crashes
      return null;
    }
  }

  // Get hymn by number
  Future<Map<String, dynamic>?> getHymnByNumber(
    String languageCode,
    String version,
    int number,
  ) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Database not ready, cannot get hymn #$number for $languageCode/$version');
      }
      return null;
    }

    // Check cache first
    final cacheKey = '${languageCode}_${version}_$number';
    if (_hymnByNumberCache.containsKey(cacheKey)) {
      if (kDebugMode) {
        debugPrint(
            '📦 Returning cached hymn #$number for $languageCode/$version');
      }
      return _hymnByNumberCache[cacheKey];
    }

    try {
      final hymn =
          await _database.getHymnByNumber(languageCode, version, number);
      final mapped = hymn != null ? _mapToMap(hymn) : null;
      // Cache the result
      _hymnByNumberCache[cacheKey] = mapped;
      return mapped;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
            '❌ Failed to get hymn #$number for $languageCode/$version: $e');
      }
      // Return null instead of throwing to prevent app crashes
      return null;
    }
  }

  // Search hymns using FTS5
  Future<List<Map<String, dynamic>>> searchHymns(
    String languageCode,
    String version,
    String query,
  ) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Database not ready, returning empty search results for "$query"');
      }
      return [];
    }

    try {
      final hymnData =
          await _database.searchHymns(languageCode, version, query);
      if (kDebugMode) {
        debugPrint(
            '🔍 Search "$query" returned ${hymnData.length} results for $languageCode/$version');
      }
      return hymnData.map((h) => _mapToMap(h)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Search failed for "$query": $e');
      }
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Get hymns by category
  Future<List<Map<String, dynamic>>> getHymnsByCategory(
    String languageCode,
    String version,
    String category,
  ) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint(
            '⚠️ Database not ready, returning empty list for category $category');
      }
      return [];
    }
    try {
      final hymnData =
          await _database.getHymnsByCategory(languageCode, version, category);
      return hymnData.map((h) => _mapToMap(h)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get hymns by category $category: $e');
      }
      // Return empty list instead of throwing to prevent app crashes
      return [];
    }
  }

  // Clear all hymns for a language/version
  Future<void> clearHymns(String languageCode, String version) async {
    await _database.clearHymns(languageCode, version);
  }

  // Check if database is empty
  Future<bool> isEmpty() async {
    final ready = await _ensureReady();
    if (!ready) {
      // If database isn't ready, assume it's empty
      return true;
    }
    try {
      return await _database.isEmpty();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error checking if database is empty: $e');
      }
      // On error, assume empty
      return true;
    }
  }

  /// Retry migration if database is empty
  /// Returns true if migration was successful, false otherwise
  Future<bool> retryMigration() async {
    try {
      final isEmpty = await this.isEmpty();
      if (!isEmpty) {
        // Database already has data
        markReady();
        return true;
      }

      // Database is empty, try migration again
      if (kDebugMode) {
        debugPrint('🔄 Retrying database migration...');
      }

      final migration = DatabaseMigration();
      await migration.migrate();
      markReady();

      if (kDebugMode) {
        debugPrint('✅ Migration retry successful');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Migration retry failed: $e');
      }
      markFailed('Migration retry failed: $e');
      return false;
    }
  }

  // Close database
  Future<void> close() async {
    await _readyStreamController.close();
    await _database.close();
  }

  // Helper: Convert Map to HymnsCompanion
  HymnsCompanion _mapToCompanion(Map<String, dynamic> hymn) {
    return HymnsCompanion.insert(
      hymnId: hymn['id'] as String,
      languageCode: hymn['language_code'] as String,
      version: hymn['version'] as String,
      number: Value(hymn['number'] as int?),
      title: Value(hymn['title'] as String?),
      lyrics: Value(hymn['lyrics'] as String?),
      category: Value(hymn['category'] as String?),
      audioUrl: Value(hymn['audio_url'] as String?),
      sheetMusic: Value(
        hymn['sheet_music'] is List
            ? json.encode(hymn['sheet_music'])
            : hymn['sheet_music'] as String?,
      ),
      artist: Value(hymn['artist'] as String?),
      song: Value(hymn['song'] as String?),
      newHymnalTitle: Value(hymn['new_hymnal_title'] as String?),
      oldHymnalTitle: Value(hymn['old_hymnal_title'] as String?),
      newHymnalLyrics: Value(hymn['new_hymnal_lyrics'] as String?),
      englishTitleOld: Value(hymn['english_title_old'] as String?),
      oldHymnalLyrics: Value(hymn['old_hymnal_lyrics'] as String?),
      createdAt: hymn['created_at'] as int,
      updatedAt: hymn['updated_at'] as int,
      isFavorite: Value((hymn['is_favorite'] as int?) == 1),
    );
  }

  // Helper: Convert Drift Hymn to Map (using generated class from app_database.g.dart)
  Map<String, dynamic> _mapToMap(dynamic hymn) {
    // hymn is the generated Hymn class from Drift
    return {
      'id': hymn.hymnId,
      'language_code': hymn.languageCode,
      'version': hymn.version,
      'number': hymn.number,
      'title': hymn.title,
      'lyrics': hymn.lyrics,
      'category': hymn.category,
      'audio_url': hymn.audioUrl,
      'sheet_music': hymn.sheetMusic,
      'artist': hymn.artist,
      'song': hymn.song,
      'new_hymnal_title': hymn.newHymnalTitle,
      'old_hymnal_title': hymn.oldHymnalTitle,
      'new_hymnal_lyrics': hymn.newHymnalLyrics,
      'english_title_old': hymn.englishTitleOld,
      'old_hymnal_lyrics': hymn.oldHymnalLyrics,
      'created_at': hymn.createdAt,
      'updated_at': hymn.updatedAt,
      'is_favorite': hymn.isFavorite ? 1 : 0,
    };
  }

  // Toggle favorite status for a hymn
  Future<void> toggleFavorite(
      String languageCode, String version, int hymnNumber) async {
    await _ensureReady();
    try {
      // Get current favorite status
      final hymn = await getHymnByNumber(languageCode, version, hymnNumber);
      if (hymn != null) {
        final currentStatus = (hymn['is_favorite'] as int?) == 1;
        final newStatus = !currentStatus;

        // Update in database
        // SQLite stores booleans as integers (0 or 1), so use withInt
        await _database.customStatement(
          'UPDATE hymns SET is_favorite = ? WHERE language_code = ? AND version = ? AND number = ?',
          [
            Variable.withInt(newStatus ? 1 : 0),
            Variable.withString(languageCode),
            Variable.withString(version),
            Variable.withInt(hymnNumber),
          ],
        );

        // Invalidate cache for this hymn and the hymns list
        _hymnByNumberCache.remove('${languageCode}_${version}_$hymnNumber');
        _hymnsCache.remove('${languageCode}_$version');
        if (kDebugMode) {
          debugPrint('✅ Toggled favorite for hymn #$hymnNumber to $newStatus');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to toggle favorite for hymn #$hymnNumber: $e');
      }
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  // Get favorite hymns
  Future<List<Map<String, dynamic>>> getFavoriteHymns(
      String languageCode, String version) async {
    final ready = await _ensureReady();
    if (!ready) {
      if (kDebugMode) {
        debugPrint('⚠️ Database not ready, returning empty list for favorites');
      }
      return [];
    }
    try {
      // Query database directly for favorites
      final rows = await _database.customSelect(
        'SELECT * FROM hymns WHERE language_code = ? AND version = ? AND is_favorite = 1 ORDER BY number ASC',
        variables: [
          Variable.withString(languageCode),
          Variable.withString(version),
        ],
        readsFrom: {_database.hymns},
      ).get();

      return rows.map((row) {
        final data = row.data;
        return {
          'id': data['id'] as String,
          'language_code': data['language_code'] as String,
          'version': data['version'] as String,
          'number': data['number'] as int?,
          'title': data['title'] as String?,
          'lyrics': data['lyrics'] as String?,
          'category': data['category'] as String?,
          'audio_url': data['audio_url'] as String?,
          'sheet_music': data['sheet_music'] as String?,
          'artist': data['artist'] as String?,
          'song': data['song'] as String?,
          'new_hymnal_title': data['new_hymnal_title'] as String?,
          'old_hymnal_title': data['old_hymnal_title'] as String?,
          'new_hymnal_lyrics': data['new_hymnal_lyrics'] as String?,
          'english_title_old': data['english_title_old'] as String?,
          'old_hymnal_lyrics': data['old_hymnal_lyrics'] as String?,
          'created_at': data['created_at'] as int,
          'updated_at': data['updated_at'] as int,
          'is_favorite': 1,
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to get favorite hymns: $e');
      }
      // Return empty list instead of throwing
      return [];
    }
  }
}
