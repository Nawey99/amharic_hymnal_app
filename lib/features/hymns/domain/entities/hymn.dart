// lib/features/hymns/domain/entities/hymn.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/utils/title_cleaner.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';

/// Domain entity representing a Hymn
/// This is the core business entity used throughout the domain layer
@immutable
class Hymn extends Equatable {
  // Common fields
  /// The song's ID in the hymnal API, e.g. `am-sda-2004-0132`. Bundled
  /// hymns carry the same IDs, so favourites and history kept under them
  /// survive a hymn being renumbered and match online and offline alike.
  final String? id;
  final int? number; // Hymn number (for backward compatibility)
  final String? title; // Title (for backward compatibility)
  final String? lyrics; // Lyrics (for backward compatibility)
  final String? category;
  final String? audioUrl; // Audio file path/URL
  final List<String>? sheetMusic; // Array of sheet music image paths

  // File details from the hymnal API for [audioUrl] and [sheetMusic]; null
  // for bundled content, which has none.
  final HymnAudioInfo? audioInfo;
  final List<HymnSheetPage>? sheetPages;

  // Hagerigna-specific fields
  final String? artist; // Song author
  final String? song; // Song text/lyrics

  // SDA-specific fields
  final String? newHymnalTitle;
  final String? oldHymnalTitle;
  final String? newHymnalLyrics;
  final String? englishTitleOld;
  final String? oldHymnalLyrics;
  final int? newHymnalNumber;
  final int? oldHymnalNumber;
  final bool isFavorite;

  /// From the copy bundled with the app rather than synced from the API:
  /// same IDs and words, but no audio or sheet music.
  final bool isBundled;

  const Hymn({
    this.id,
    this.number,
    this.title,
    this.lyrics,
    this.category,
    this.audioUrl,
    this.sheetMusic,
    this.audioInfo,
    this.sheetPages,
    // Hagerigna fields
    this.artist,
    this.song,
    // SDA fields
    this.newHymnalTitle,
    this.oldHymnalTitle,
    this.newHymnalLyrics,
    this.englishTitleOld,
    this.oldHymnalLyrics,
    this.newHymnalNumber,
    this.oldHymnalNumber,
    this.isFavorite = false,
    this.isBundled = false,
  });

  /// The key favourites and history are kept under. Every hymn has an [id];
  /// [version] and the number only rebuild it for one that somehow has none.
  String songIdIn(String version) =>
      id ?? HymnalVersions.songId(version, displayNumber);

  /// Get display title with proper fallback logic
  ///
  /// Priority order:
  /// 1. title (version-specific display title from mapping/API)
  /// 2. newHymnalTitle
  /// 3. oldHymnalTitle
  /// 4. Empty string (UI will show fallback "መዝሙር {number}")
  ///
  /// This ensures titles are always available for sorting and display,
  /// especially important for SDA hymnal sort-by-name functionality.
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    if (newHymnalTitle != null && newHymnalTitle!.isNotEmpty) {
      return newHymnalTitle!;
    }
    if (oldHymnalTitle != null && oldHymnalTitle!.isNotEmpty) {
      return oldHymnalTitle!;
    }
    // Fallback: return empty string (will be handled by UI with hymn number)
    return '';
  }

  String get displayLyrics {
    String? lyricsText;
    if (lyrics != null && lyrics!.isNotEmpty) {
      lyricsText = lyrics!;
    } else if (song != null && song!.isNotEmpty) {
      lyricsText = song!;
    } else if (newHymnalLyrics != null && newHymnalLyrics!.isNotEmpty) {
      lyricsText = newHymnalLyrics!;
    } else if (oldHymnalLyrics != null && oldHymnalLyrics!.isNotEmpty) {
      lyricsText = oldHymnalLyrics!;
    }

    if (lyricsText == null || lyricsText.isEmpty) {
      return '';
    }

    // Convert literal \n strings to actual newlines
    return lyricsText.replaceAll('\\n', '\n');
  }

  int get displayNumber {
    if (number != null) return number!;
    if (id != null) {
      // The number ends the ID: `am-sda-2004-0132`.
      return int.tryParse(id!.split('-').last) ?? 0;
    }
    return 0;
  }

  int? get displayNewHymnalNumber => newHymnalNumber;

  int? get displayOldHymnalNumber => oldHymnalNumber;

  String get displayEnglishTitle => cleanEnglishTitle(englishTitleOld);

  /// Check if this hymn is from the hagerigna hymnal
  bool get isHagerigna {
    // Bundled data uses `hagerigna-N`; the hymnal API uses `am-hagerigna-NNNN`.
    return id != null &&
        (id!.startsWith('hagerigna-') || id!.startsWith('am-hagerigna-'));
  }

  @override
  List<Object?> get props => [
        id,
        number,
        title,
        lyrics,
        category,
        audioUrl,
        sheetMusic,
        audioInfo,
        sheetPages,
        artist,
        song,
        newHymnalTitle,
        oldHymnalTitle,
        newHymnalLyrics,
        englishTitleOld,
        oldHymnalLyrics,
        newHymnalNumber,
        oldHymnalNumber,
        isFavorite,
        isBundled,
      ];
}
