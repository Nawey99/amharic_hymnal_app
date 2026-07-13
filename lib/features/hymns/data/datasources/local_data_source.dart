// lib/features/hymns/data/datasources/local_data_source.dart
import 'dart:convert';

import 'package:amharic_hymnal_app/core/database/database_helper.dart';
import 'package:amharic_hymnal_app/core/database/json_data_source.dart';
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/models/database_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

class LocalDataSource implements HymnLocalDataSource {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final JsonDataSource _jsonDataSource = JsonDataSource.instance;
  final HymnRemoteDataSource _remoteDataSource = HymnRemoteDataSource();

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    // Verify database config exists
    final normalizedVersion = HymnalVersions.normalizeId(version);
    final dbConfig =
        DatabaseRegistry.getDatabase(languageCode, normalizedVersion);
    if (dbConfig == null) {
      throw DatabaseNotFoundException(
          'Database not found for language: $languageCode, version: $version');
    }

    try {
      final remoteHymns =
          await _remoteDataSource.getHymns(languageCode, normalizedVersion);
      if (remoteHymns.isNotEmpty) {
        return remoteHymns;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Content API unavailable, using local data: $e');
      }
    }

    // Fast path: If database is not ready, load from JSON assets (very fast, no migration needed)
    if (!_dbHelper.isReady) {
      if (kDebugMode) {
        debugPrint(
            '⚡ Database not ready, loading from JSON assets for immediate access');
      }
      try {
        final jsonResults =
            await _jsonDataSource.getHymns(languageCode, version);
        return jsonResults
            .map((row) => _mapJsonToHymnModel(row, normalizedVersion))
            .toList();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Failed to load from JSON, will try database: $e');
        }
        // Fall through to try database anyway
      }
    }

    // Normal path: Get hymns from SQLite database (when ready)
    try {
      final results = await _dbHelper.getHymns(languageCode, normalizedVersion);
      if (results.isNotEmpty) {
        return results
            .map((row) => _mapRowToHymnModel(row, normalizedVersion))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Database query failed: $e');
      }
    }

    // Fallback: If database query returned empty or failed, try JSON
    if (kDebugMode) {
      debugPrint('⚡ Falling back to JSON data source');
    }
    final jsonResults =
        await _jsonDataSource.getHymns(languageCode, normalizedVersion);
    final hymns = jsonResults
        .map((row) => _mapJsonToHymnModel(row, normalizedVersion))
        .toList();

    // Debug: Log title mapping for first few hymns from JSON
    if (kDebugMode && hymns.isNotEmpty) {
      final sampleSize = hymns.length > 5 ? 5 : hymns.length;
      debugPrint('📊 Sample hymn titles from JSON (first $sampleSize):');
      for (int i = 0; i < sampleSize; i++) {
        final hymn = hymns[i];
        debugPrint(
            '   Hymn #${hymn.number}: title="${hymn.title}", newHymnalTitle="${hymn.newHymnalTitle}", oldHymnalTitle="${hymn.oldHymnalTitle}"');
      }
    }

    return hymns;
  }

  /// Convert JSON data to HymnModel (for fast JSON loading)
  ///
  /// Handles title mapping with proper fallback logic:
  /// - For SDA hymnal: new_hymnal_title > old_hymnal_title
  /// - For Hagerigna: title field
  /// - Ensures title field always has a value for displayTitle getter
  HymnModel _mapJsonToHymnModel(Map<String, dynamic> jsonData, String version) {
    // Parse sheet_music if it's a JSON string
    List<String>? sheetMusic;
    if (jsonData['sheet_music'] != null) {
      try {
        if (jsonData['sheet_music'] is String) {
          final decoded = jsonDecode(jsonData['sheet_music'] as String);
          if (decoded is List) {
            sheetMusic = decoded.map((e) => e.toString()).toList();
          }
        } else if (jsonData['sheet_music'] is List) {
          sheetMusic = (jsonData['sheet_music'] as List)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        // If parsing fails, leave as null
        sheetMusic = null;
      }
    }

    final newHymnalNumber = _readInt(jsonData['new_hymnal_number']);
    final oldHymnalNumber = _readInt(jsonData['old_hymnal_number']);
    final isOld = version == HymnalVersions.sdaOld;

    // Extract title fields
    final newHymnalTitle = jsonData['new_hymnal_title'] as String?;
    final oldHymnalTitle = jsonData['old_hymnal_title'] as String?;
    final titleField = jsonData['title'] as String?;

    // Determine best title with fallback logic
    // Priority: title field > new_hymnal_title > old_hymnal_title
    // This ensures title field always has a value for displayTitle getter
    final String? title = titleField?.isNotEmpty == true
        ? titleField
        : (isOld
            ? (oldHymnalTitle?.isNotEmpty == true
                ? oldHymnalTitle
                : newHymnalTitle)
            : (newHymnalTitle?.isNotEmpty == true
                ? newHymnalTitle
                : oldHymnalTitle));

    // Extract lyrics with fallback
    final newHymnalLyrics = jsonData['new_hymnal_lyrics'] as String?;
    final oldHymnalLyrics = jsonData['old_hymnal_lyrics'] as String?;
    final lyricsField = jsonData['lyrics'] as String?;

    final String? lyrics = lyricsField?.isNotEmpty == true
        ? lyricsField
        : (isOld
            ? (oldHymnalLyrics?.isNotEmpty == true
                ? oldHymnalLyrics
                : newHymnalLyrics)
            : (newHymnalLyrics?.isNotEmpty == true
                ? newHymnalLyrics
                : oldHymnalLyrics));

    // Sheet music is now loaded remotely on demand
    // No need to discover during mapping - will be fetched when needed
    final hymnNumber = _readInt(jsonData['number']);
    List<String>? finalSheetMusic = sheetMusic;
    // Keep existing sheetMusic from JSON if present (may contain URLs)

    return HymnModel(
      id: jsonData['id'] as String?,
      number: hymnNumber,
      title: title,
      lyrics: lyrics,
      category: (jsonData['category'] as String?) ??
          HymnCategories.getCategoryByNumber(hymnNumber ?? 0)?.nameAmharic,
      audioUrl: jsonData['audio_url'] as String?,
      sheetMusic: finalSheetMusic,
      // Hagerigna fields
      artist: jsonData['artist'] as String?,
      song: jsonData['song'] as String?,
      // SDA fields - preserve original values for displayTitle getter priority
      newHymnalTitle: newHymnalTitle,
      oldHymnalTitle: oldHymnalTitle,
      newHymnalLyrics: newHymnalLyrics,
      englishTitleOld: jsonData['english_title_old'] as String?,
      oldHymnalLyrics: oldHymnalLyrics,
      newHymnalNumber: newHymnalNumber,
      oldHymnalNumber: oldHymnalNumber,
      isFavorite: (jsonData['is_favorite'] as int?) == 1 ||
          (jsonData['is_favorite'] as bool?) == true,
    );
  }

  /// Convert database row to HymnModel
  ///
  /// Handles title mapping with proper fallback logic (same as JSON mapping)
  /// Ensures title field always has a value for displayTitle getter
  HymnModel _mapRowToHymnModel(Map<String, dynamic> row, String version) {
    // Parse sheet_music if it's a JSON string
    List<String>? sheetMusic;
    if (row['sheet_music'] != null) {
      try {
        if (row['sheet_music'] is String) {
          final decoded = json.decode(row['sheet_music'] as String);
          if (decoded is List) {
            sheetMusic = decoded.map((e) => e.toString()).toList();
          }
        } else if (row['sheet_music'] is List) {
          sheetMusic =
              (row['sheet_music'] as List).map((e) => e.toString()).toList();
        }
      } catch (e) {
        // If parsing fails, leave as null
        sheetMusic = null;
      }
    }

    final newHymnalNumber = _readInt(row['new_hymnal_number']);
    final oldHymnalNumber = _readInt(row['old_hymnal_number']);
    final isOld = version == HymnalVersions.sdaOld;

    // Extract title fields
    final newHymnalTitle = row['new_hymnal_title'] as String?;
    final oldHymnalTitle = row['old_hymnal_title'] as String?;
    final titleField = row['title'] as String?;

    // Determine best title with fallback logic
    // Priority: title field > new_hymnal_title > old_hymnal_title
    final String? title = titleField?.isNotEmpty == true
        ? titleField
        : (isOld
            ? (oldHymnalTitle?.isNotEmpty == true
                ? oldHymnalTitle
                : newHymnalTitle)
            : (newHymnalTitle?.isNotEmpty == true
                ? newHymnalTitle
                : oldHymnalTitle));

    // Extract lyrics with fallback
    final newHymnalLyrics = row['new_hymnal_lyrics'] as String?;
    final oldHymnalLyrics = row['old_hymnal_lyrics'] as String?;
    final lyricsField = row['lyrics'] as String?;

    final String? lyrics = lyricsField?.isNotEmpty == true
        ? lyricsField
        : (isOld
            ? (oldHymnalLyrics?.isNotEmpty == true
                ? oldHymnalLyrics
                : newHymnalLyrics)
            : (newHymnalLyrics?.isNotEmpty == true
                ? newHymnalLyrics
                : oldHymnalLyrics));

    // Sheet music is now loaded remotely on demand
    // No need to discover during mapping - will be fetched when needed
    final hymnNumber = _readInt(row['number']);
    List<String>? finalSheetMusic = sheetMusic;
    // Keep existing sheetMusic from database if present (may contain URLs)

    return HymnModel(
      id: row['id'] as String?,
      number: hymnNumber,
      title: title,
      lyrics: lyrics,
      category: (row['category'] as String?) ??
          HymnCategories.getCategoryByNumber(hymnNumber ?? 0)?.nameAmharic,
      audioUrl: row['audio_url'] as String?,
      sheetMusic: finalSheetMusic,
      // Hagerigna fields
      artist: row['artist'] as String?,
      song: row['song'] as String?,
      // SDA fields - preserve original values for displayTitle getter priority
      newHymnalTitle: newHymnalTitle,
      oldHymnalTitle: oldHymnalTitle,
      newHymnalLyrics: newHymnalLyrics,
      englishTitleOld: row['english_title_old'] as String?,
      oldHymnalLyrics: oldHymnalLyrics,
      newHymnalNumber: newHymnalNumber,
      oldHymnalNumber: oldHymnalNumber,
      isFavorite: (row['is_favorite'] as int?) == 1,
    );
  }

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
