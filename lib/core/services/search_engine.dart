// lib/core/services/search_engine.dart
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/core/services/amharic_phonetic_service.dart';
import 'package:amharic_hymnal_app/core/utils/script_detector.dart';

/// Search result with ranking information
class SearchResult {
  final Hymn hymn;
  final int rank; // Lower is better (1 = highest priority)
  final MatchType matchType;
  final int score;
  final int occurrenceCount;

  const SearchResult({
    required this.hymn,
    required this.rank,
    required this.matchType,
    this.score = 0,
    this.occurrenceCount = 0,
  });
}

/// Type of match found
enum MatchType {
  exactTitle, // Exact title match (Amharic or English)
  number, // Hymn number match
  partialTitle, // Partial title match
  lyrics, // Lyrics match
  none, // No match (shouldn't appear in results)
}

/// Pure, testable search logic
///
/// Features:
/// - Language-aware normalization (Amharic phonetic + English case-insensitive)
/// - Ranking algorithm: exact title > number > partial title > lyrics
/// - Searches title and body fields separately so lyric hits do not outrank titles
/// - Returns ranked results (no filtering in widgets)
///
/// Architecture: This is the core search logic layer. It's pure and testable,
/// with no UI dependencies or side effects.
class SearchEngine {
  // Validation logs (disabled by default, can be enabled for debugging)
  bool _enableValidationLogs = false;

  /// Search hymns with ranking
  ///
  /// [hymns] - List of hymns to search (immutable)
  /// [query] - Search query (raw, will be normalized)
  /// [normalizedIndex] - Legacy compatibility parameter; no longer required
  ///
  /// Returns: List of SearchResult sorted by rank (best matches first)
  List<SearchResult> search({
    required List<Hymn> hymns,
    required String query,
    Map<String, String>? normalizedIndex,
  }) {
    final rawQuery = query.trim();
    if (rawQuery.isEmpty) {
      return [];
    }

    final startTime = DateTime.now();

    // Detect script type to determine search strategy
    final scriptType = ScriptDetector.detect(rawQuery);
    final isAmharicQuery = scriptType == ScriptType.amharic;

    // Normalize query based on script type
    final normalizedQuery = isAmharicQuery
        ? _normalizeAmharic(rawQuery)
        : _normalizeEnglish(rawQuery);

    if (_enableValidationLogs && kDebugMode) {
      debugPrint(
          '🔍 [SearchEngine] Query: "$query" -> Normalized: "$normalizedQuery" (${isAmharicQuery ? "Amharic" : "English"})');
    }

    // Tokenize English queries for better matching
    final queryTokens = isAmharicQuery
        ? [normalizedQuery]
        : normalizedQuery
            .split(RegExp(r'\s+'))
            .where((t) => t.isNotEmpty)
            .toList();

    if (_enableValidationLogs && kDebugMode) {
      debugPrint('🔍 [SearchEngine] Query tokens: $queryTokens');
    }

    var results = <SearchResult>[];

    for (final hymn in hymns) {
      final match = _matchHymn(
        hymn: hymn,
        query: normalizedQuery,
        queryTokens: queryTokens,
        isAmharicQuery: isAmharicQuery,
      );

      if (match.matchType != MatchType.none) {
        results.add(match);
      }
    }

    // Sort by rank, lyric occurrences, hymn number, then title for stability.
    results.sort((a, b) {
      final rankComparison = a.rank.compareTo(b.rank);
      if (rankComparison != 0) return rankComparison;
      if (a.matchType == MatchType.lyrics && b.matchType == MatchType.lyrics) {
        final occurrenceComparison =
            b.occurrenceCount.compareTo(a.occurrenceCount);
        if (occurrenceComparison != 0) return occurrenceComparison;
      }
      final numberComparison =
          a.hymn.displayNumber.compareTo(b.hymn.displayNumber);
      if (numberComparison != 0) return numberComparison;
      return a.hymn.displayTitle.compareTo(b.hymn.displayTitle);
    });

    // Limit lyrics-only matches to avoid too many unrelated results
    // Keep all exact title, number, and partial title matches
    // But limit lyrics matches to top 20 if there are many results
    final lyricsOnlyResults =
        results.where((r) => r.matchType == MatchType.lyrics).toList();
    if (lyricsOnlyResults.length > 20) {
      // Remove excess lyrics-only results, keeping only top 20
      final otherResults =
          results.where((r) => r.matchType != MatchType.lyrics).toList();
      final topLyricsResults = lyricsOnlyResults.take(20).toList();
      results = [...otherResults, ...topLyricsResults];
      // Re-sort after limiting (with secondary sort by hymn number)
      results.sort((a, b) {
        final rankComparison = a.rank.compareTo(b.rank);
        if (rankComparison != 0) return rankComparison;
        if (a.matchType == MatchType.lyrics &&
            b.matchType == MatchType.lyrics) {
          final occurrenceComparison =
              b.occurrenceCount.compareTo(a.occurrenceCount);
          if (occurrenceComparison != 0) return occurrenceComparison;
        }
        final numberComparison =
            a.hymn.displayNumber.compareTo(b.hymn.displayNumber);
        if (numberComparison != 0) return numberComparison;
        return a.hymn.displayTitle.compareTo(b.hymn.displayTitle);
      });
    }

    final duration = DateTime.now().difference(startTime);
    if (_enableValidationLogs && kDebugMode) {
      debugPrint(
          '🔍 [SearchEngine] Found ${results.length} results in ${duration.inMilliseconds}ms');
    }

    return results;
  }

  /// Match a single hymn against the query
  ///
  /// Returns SearchResult with match type and rank
  /// Ranking priority, checked in this order so each hymn takes its best
  /// match:
  /// 0. Hymn number
  /// 1. Exact Amharic title
  /// 2. Amharic title starts with the query
  /// 3. Amharic title contains the query
  /// 4. Exact English title
  /// 5. English title starts with the query
  /// 6. English title contains the query
  /// 8. Lyrics
  SearchResult _matchHymn({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
  }) {
    SearchResult result(int rank, int score, MatchType type) =>
        SearchResult(hymn: hymn, rank: rank, score: score, matchType: type);

    if (_matchNumber(hymn: hymn, query: query)) {
      return result(0, 1100, MatchType.number);
    }

    if (_matchExactAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
    )) {
      return result(1, 1000, MatchType.exactTitle);
    }

    if (_matchPartialAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
      startsWith: true,
    )) {
      return result(2, 900, MatchType.partialTitle);
    }

    if (_matchPartialAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
      startsWith: false,
    )) {
      return result(3, 800, MatchType.partialTitle);
    }

    if (_matchExactEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
    )) {
      return result(4, 700, MatchType.exactTitle);
    }

    if (_matchPartialEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
      startsWith: true,
    )) {
      return result(5, 650, MatchType.partialTitle);
    }

    if (_matchPartialEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
      startsWith: false,
    )) {
      return result(6, 600, MatchType.partialTitle);
    }

    // Priority 8: Lyrics match
    final lyricsOccurrenceCount = _lyricsOccurrenceCount(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
    );
    if (lyricsOccurrenceCount > 0) {
      return SearchResult(
        hymn: hymn,
        rank: 8,
        score: 500,
        occurrenceCount: lyricsOccurrenceCount,
        matchType: MatchType.lyrics,
      );
    }

    // No match
    return SearchResult(
      hymn: hymn,
      rank: 999,
      score: 0,
      matchType: MatchType.none,
    );
  }

  bool _matchNumber({
    required Hymn hymn,
    required String query,
  }) {
    final numberQuery = int.tryParse(query.trim());
    if (numberQuery == null) return false;
    return hymn.displayNumber == numberQuery ||
        hymn.newHymnalNumber == numberQuery ||
        hymn.oldHymnalNumber == numberQuery;
  }

  /// Check for exact Amharic title match
  bool _matchExactAmharicTitle({
    required Hymn hymn,
    required String query,
    required bool isAmharicQuery,
  }) {
    if (!isAmharicQuery) return false;

    return _amharicTitles(hymn).any((title) => title == query);
  }

  /// Check for exact English title match
  bool _matchExactEnglishTitle({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
  }) {
    if (isAmharicQuery) return false;

    return _englishTitles(hymn).any((titleLower) {
      if (titleLower == query) return true;

      final titleTokens = titleLower
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      return titleTokens.length == queryTokens.length &&
          titleTokens.join(' ') == queryTokens.join(' ');
    });
  }

  /// Check for partial Amharic title match
  bool _matchPartialAmharicTitle({
    required Hymn hymn,
    required String query,
    required bool isAmharicQuery,
    required bool startsWith,
  }) {
    if (!isAmharicQuery) return false;

    return _amharicTitles(hymn).any((normalizedText) {
      if (startsWith) {
        return normalizedText.startsWith(query);
      }
      return normalizedText.contains(query);
    });
  }

  /// Check for partial English title match
  bool _matchPartialEnglishTitle({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
    required bool startsWith,
  }) {
    if (isAmharicQuery) return false;

    return _englishTitles(hymn).any((titleLower) {
      final significantTokens =
          queryTokens.where((token) => token.length >= 3).toList();
      if (startsWith) {
        if (titleLower.startsWith(query)) return true;
        return significantTokens.isNotEmpty &&
            titleLower.startsWith(significantTokens.first);
      }

      if (titleLower.contains(query)) return true;
      if (significantTokens.isEmpty) {
        return false;
      }
      if (significantTokens.length == 1) {
        return titleLower.contains(significantTokens.single);
      }
      return significantTokens.every(titleLower.contains);
    });
  }

  /// Count lyric/content occurrences.
  /// Only matches if query is long enough (at least 3 characters for Amharic,
  /// 4 for English) to avoid too many unrelated results.
  int _lyricsOccurrenceCount({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
  }) {
    if (_bodyFields(hymn).isEmpty) {
      return 0;
    }

    // Minimum query length for lyrics matching to avoid too many unrelated results
    final minQueryLength = isAmharicQuery ? 3 : 4;
    if (query.trim().length < minQueryLength) {
      return 0;
    }

    if (isAmharicQuery) {
      return _amharicBodies(hymn).fold<int>(0, (count, field) {
        return count + _countOccurrences(field, query);
      });
    }

    var count = 0;
    final significantTokens =
        queryTokens.where((token) => token.length >= 4).toSet();
    for (final fieldLower in _englishBodies(hymn)) {
      count += _countOccurrences(fieldLower, query) * 2;
      for (final token in significantTokens) {
        count += _countOccurrences(fieldLower, token);
      }
    }

    return count;
  }

  // Normalised fields per hymn, kept for as long as the hymn object lives.
  // The repository hands back the same objects for an edition, so each
  // title and lyric is normalised once rather than on every keystroke.
  static final Expando<List<String>> _amharicTitleCache = Expando();
  static final Expando<List<String>> _englishTitleCache = Expando();
  static final Expando<List<String>> _amharicBodyCache = Expando();
  static final Expando<List<String>> _englishBodyCache = Expando();

  List<String> _amharicTitles(Hymn hymn) => _amharicTitleCache[hymn] ??=
      _titleFields(hymn).map(_normalizeAmharic).toList(growable: false);

  List<String> _englishTitles(Hymn hymn) => _englishTitleCache[hymn] ??=
      _titleFields(hymn).map(_normalizeEnglish).toList(growable: false);

  List<String> _amharicBodies(Hymn hymn) => _amharicBodyCache[hymn] ??=
      _bodyFields(hymn).map(_normalizeAmharic).toList(growable: false);

  List<String> _englishBodies(Hymn hymn) => _englishBodyCache[hymn] ??=
      _bodyFields(hymn).map(_normalizeEnglish).toList(growable: false);

  List<String> _titleFields(Hymn hymn) {
    return [
      hymn.displayTitle,
      hymn.title ?? '',
      hymn.newHymnalTitle ?? '',
      hymn.oldHymnalTitle ?? '',
      hymn.englishTitleOld ?? '',
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
  }

  List<String> _bodyFields(Hymn hymn) {
    return [
      hymn.displayLyrics,
      hymn.lyrics ?? '',
      hymn.song ?? '',
      hymn.newHymnalLyrics ?? '',
      hymn.oldHymnalLyrics ?? '',
      hymn.artist ?? '',
    ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();
  }

  String _normalizeAmharic(String value) {
    return AmharicPhoneticService.normalizeAmharic(value.trim().toLowerCase());
  }

  String _normalizeEnglish(String value) {
    return value.trim().toLowerCase();
  }

  int _countOccurrences(String text, String query) {
    if (text.isEmpty || query.isEmpty) return 0;

    var count = 0;
    var start = 0;
    while (start < text.length) {
      final index = text.indexOf(query, start);
      if (index == -1) break;
      count++;
      start = index + query.length;
    }
    return count;
  }

  /// Disable validation logs (call after testing)
  void disableValidationLogs() {
    _enableValidationLogs = false;
  }
}
