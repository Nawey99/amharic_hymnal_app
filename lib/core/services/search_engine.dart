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

  const SearchResult({
    required this.hymn,
    required this.rank,
    required this.matchType,
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
/// - Uses prebuilt normalized index
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
  /// [normalizedIndex] - Prebuilt normalized search index (optional, for Amharic)
  ///
  /// Returns: List of SearchResult sorted by rank (best matches first)
  List<SearchResult> search({
    required List<Hymn> hymns,
    required String query,
    Map<String, String>? normalizedIndex,
  }) {
    if (query.isEmpty) {
      return [];
    }

    final startTime = DateTime.now();

    // Detect script type to determine search strategy
    final scriptType = ScriptDetector.detect(query);
    final isAmharicQuery = scriptType == ScriptType.amharic;

    // Normalize query based on script type
    final normalizedQuery = isAmharicQuery
        ? AmharicPhoneticService.normalizeAmharic(query)
        : query.toLowerCase().trim();

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
        normalizedIndex: normalizedIndex,
      );

      if (match.matchType != MatchType.none) {
        results.add(match);
      }
    }

    // Sort by rank (lower is better), then by hymn number for stable ordering
    results.sort((a, b) {
      final rankComparison = a.rank.compareTo(b.rank);
      if (rankComparison != 0) return rankComparison;
      // Secondary sort: hymn number for deterministic ordering
      return a.hymn.displayNumber.compareTo(b.hymn.displayNumber);
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
        return a.hymn.displayNumber.compareTo(b.hymn.displayNumber);
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
  /// Ranking priority:
  /// 1. Exact Amharic title match
  /// 2. Exact English title match
  /// 3. Partial Amharic title match (starts with)
  /// 4. Partial Amharic title match (contains)
  /// 5. Partial English title match (starts with)
  /// 6. Partial English title match (contains)
  /// 7. Lyrics match
  SearchResult _matchHymn({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
    Map<String, String>? normalizedIndex,
  }) {
    // Priority 1: Exact Amharic title match
    final exactAmharicMatch = _matchExactAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
      normalizedIndex: normalizedIndex,
    );
    if (exactAmharicMatch) {
      return SearchResult(
        hymn: hymn,
        rank: 1,
        matchType: MatchType.exactTitle,
      );
    }

    // Priority 2: Exact English title match
    final exactEnglishMatch = _matchExactEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
    );
    if (exactEnglishMatch) {
      return SearchResult(
        hymn: hymn,
        rank: 2,
        matchType: MatchType.exactTitle,
      );
    }

    // Priority 3: Partial Amharic title match (starts with)
    final partialAmharicStartsWith = _matchPartialAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
      normalizedIndex: normalizedIndex,
      startsWith: true,
    );
    if (partialAmharicStartsWith) {
      return SearchResult(
        hymn: hymn,
        rank: 3,
        matchType: MatchType.partialTitle,
      );
    }

    // Priority 4: Partial Amharic title match (contains)
    final partialAmharicContains = _matchPartialAmharicTitle(
      hymn: hymn,
      query: query,
      isAmharicQuery: isAmharicQuery,
      normalizedIndex: normalizedIndex,
      startsWith: false,
    );
    if (partialAmharicContains) {
      return SearchResult(
        hymn: hymn,
        rank: 4,
        matchType: MatchType.partialTitle,
      );
    }

    // Priority 5: Partial English title match (starts with)
    final partialEnglishStartsWith = _matchPartialEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
      startsWith: true,
    );
    if (partialEnglishStartsWith) {
      return SearchResult(
        hymn: hymn,
        rank: 5,
        matchType: MatchType.partialTitle,
      );
    }

    // Priority 6: Partial English title match (contains)
    final partialEnglishContains = _matchPartialEnglishTitle(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
      startsWith: false,
    );
    if (partialEnglishContains) {
      return SearchResult(
        hymn: hymn,
        rank: 6,
        matchType: MatchType.partialTitle,
      );
    }

    // Priority 7: Lyrics match
    final lyricsMatch = _matchLyrics(
      hymn: hymn,
      query: query,
      queryTokens: queryTokens,
      isAmharicQuery: isAmharicQuery,
      normalizedIndex: normalizedIndex,
    );
    if (lyricsMatch) {
      return SearchResult(
        hymn: hymn,
        rank: 7,
        matchType: MatchType.lyrics,
      );
    }

    // No match
    return SearchResult(
      hymn: hymn,
      rank: 999,
      matchType: MatchType.none,
    );
  }

  /// Check for exact Amharic title match
  bool _matchExactAmharicTitle({
    required Hymn hymn,
    required String query,
    required bool isAmharicQuery,
    Map<String, String>? normalizedIndex,
  }) {
    if (!isAmharicQuery) return false;

    final amharicTitle = hymn.displayTitle;
    if (amharicTitle.isEmpty) return false;

    if (normalizedIndex != null) {
      final hymnId = hymn.id ?? '${hymn.displayNumber}';
      final normalizedTitle = normalizedIndex[hymnId]?.split(' ').first ?? '';
      return normalizedTitle == query;
    }

    return false;
  }

  /// Check for exact English title match
  bool _matchExactEnglishTitle({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
  }) {
    if (isAmharicQuery) return false;

    final englishTitle = hymn.englishTitleOld ?? '';
    if (englishTitle.isEmpty) return false;

    final titleLower = englishTitle.toLowerCase();
    if (titleLower == query) {
      return true;
    }

    // Also check token-based exact match
    final titleTokens = titleLower.split(RegExp(r'\s+'));
    if (titleTokens.length == queryTokens.length &&
        titleTokens.join(' ') == queryTokens.join(' ')) {
      return true;
    }

    return false;
  }

  /// Check for partial Amharic title match
  bool _matchPartialAmharicTitle({
    required Hymn hymn,
    required String query,
    required bool isAmharicQuery,
    Map<String, String>? normalizedIndex,
    required bool startsWith,
  }) {
    if (!isAmharicQuery) return false;

    final amharicTitle = hymn.displayTitle;
    if (amharicTitle.isEmpty) return false;

    if (normalizedIndex != null) {
      final hymnId = hymn.id ?? '${hymn.displayNumber}';
      final normalizedText = normalizedIndex[hymnId] ?? '';
      if (startsWith) {
        return normalizedText.startsWith(query);
      } else {
        return normalizedText.contains(query);
      }
    }

    return false;
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

    final englishTitle = hymn.englishTitleOld ?? '';
    if (englishTitle.isEmpty) return false;

    final titleLower = englishTitle.toLowerCase();
    if (startsWith) {
      if (titleLower.startsWith(query)) {
        return true;
      }
      // Token-based startsWith matching (first token)
      if (queryTokens.isNotEmpty && titleLower.startsWith(queryTokens.first)) {
        return true;
      }
    } else {
      if (titleLower.contains(query)) {
        return true;
      }
      // Token-based matching
      for (final token in queryTokens) {
        if (titleLower.contains(token)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Check for lyrics match
  /// Only matches if query is long enough (at least 3 characters for Amharic, 4 for English)
  /// to avoid too many unrelated results
  bool _matchLyrics({
    required Hymn hymn,
    required String query,
    required List<String> queryTokens,
    required bool isAmharicQuery,
    Map<String, String>? normalizedIndex,
  }) {
    final lyrics = hymn.displayLyrics;
    if (lyrics.isEmpty) {
      return false;
    }

    // Minimum query length for lyrics matching to avoid too many unrelated results
    final minQueryLength = isAmharicQuery ? 3 : 4;
    if (query.trim().length < minQueryLength) {
      return false;
    }

    if (isAmharicQuery && normalizedIndex != null) {
      final hymnId = hymn.id ?? '${hymn.displayNumber}';
      final normalizedText = normalizedIndex[hymnId] ?? '';
      if (normalizedText.contains(query)) {
        return true;
      }
    } else if (!isAmharicQuery) {
      final lyricsLower = lyrics.toLowerCase();
      // Require at least 4 characters for English lyrics matching
      if (query.length >= 4 && lyricsLower.contains(query)) {
        return true;
      }
      // Token-based matching - only for tokens of at least 4 characters
      for (final token in queryTokens) {
        if (token.length >= 4 && lyricsLower.contains(token)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Disable validation logs (call after testing)
  void disableValidationLogs() {
    _enableValidationLogs = false;
  }
}
