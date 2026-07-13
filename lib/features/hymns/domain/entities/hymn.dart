// lib/features/hymns/domain/entities/hymn.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:amharic_hymnal_app/core/utils/title_cleaner.dart';

/// Domain entity representing a Hymn
/// This is the core business entity used throughout the domain layer
@immutable
class Hymn extends Equatable {
  // Common fields
  final String? id; // ID format: "hagerigna-0" or "sda-0"
  final int? number; // Hymn number (for backward compatibility)
  final String? title; // Title (for backward compatibility)
  final String? lyrics; // Lyrics (for backward compatibility)
  final String? category;
  final String? audioUrl; // Audio file path/URL
  final List<String>? sheetMusic; // Array of sheet music image paths

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

  const Hymn({
    this.id,
    this.number,
    this.title,
    this.lyrics,
    this.category,
    this.audioUrl,
    this.sheetMusic,
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
  });

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
      // Extract number from id like "hagerigna-0" or "sda-0"
      final parts = id!.split('-');
      if (parts.length > 1) {
        return int.tryParse(parts[1]) ?? 0;
      }
    }
    return 0;
  }

  int? get displayNewHymnalNumber => newHymnalNumber;

  int? get displayOldHymnalNumber => oldHymnalNumber;

  String get displayEnglishTitle => cleanEnglishTitle(englishTitleOld);

  /// Check if this hymn is from the hagerigna hymnal
  bool get isHagerigna {
    return id != null && id!.startsWith('hagerigna-');
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
      ];
}
