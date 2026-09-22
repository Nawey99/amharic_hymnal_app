// lib/features/hymns/data/datasources/local_data_source.dart
import 'dart:convert';

import 'package:amharic_hymnal_app/core/database/json_data_source.dart';
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/models/database_config.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_remote_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Loads an edition from the hymnal API (which keeps its own stored copy),
/// falling back to the hymns bundled with the app.
class LocalDataSource implements HymnLocalDataSource {
  LocalDataSource({
    HymnRemoteDataSource? remoteDataSource,
    JsonDataSource? jsonDataSource,
  })  : _remoteDataSource = remoteDataSource ?? HymnRemoteDataSource(),
        _jsonDataSource = jsonDataSource ?? JsonDataSource.instance;

  final HymnRemoteDataSource _remoteDataSource;
  final JsonDataSource _jsonDataSource;

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    final normalizedVersion = HymnalVersions.normalizeId(version);

    try {
      // A successful empty response is authoritative. This lets newly created
      // editions remain empty until their first real song is added.
      return await _remoteDataSource.getHymns(
        languageCode,
        normalizedVersion,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Content API unavailable, using local data: $e');
      }
    }

    // Dynamically published hymnals are API-only until a matching offline
    // database is bundled. Never substitute a different hymnal as fallback.
    final dbConfig =
        DatabaseRegistry.getDatabase(languageCode, normalizedVersion);
    if (dbConfig == null) {
      throw DatabaseNotFoundException(
          'No offline database for $languageCode/$normalizedVersion');
    }

    final jsonResults =
        await _jsonDataSource.getHymns(languageCode, normalizedVersion);
    return jsonResults
        .map((row) => _mapJsonToHymnModel(row, normalizedVersion))
        .toList();
  }

  /// Convert JSON data to HymnModel (for fast JSON loading)
  ///
  /// Handles title mapping with proper fallback logic:
  /// - For SDA hymnal: new_hymnal_title > old_hymnal_title
  /// - For Hagerigna: title field
  /// - Ensures title field always has a value for displayTitle getter
  /// The 2004 book's number ranges; other editions have no fallback.
  static String? _rangeCategory(String version, int? number) =>
      version == HymnalVersions.sdaNew
          ? HymnCategories.getCategoryByNumber(number ?? 0)?.nameAmharic
          : null;

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
          _rangeCategory(version, hymnNumber),
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

  int? _readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
