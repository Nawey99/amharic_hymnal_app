// lib/core/services/music_api_service.dart
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Service for fetching music metadata and audio URLs from open-source APIs
/// Currently integrates with Open Opus API for classical music metadata
/// Can be extended to support other APIs (Free Music Archive, Musopen, etc.)
class MusicApiService {
  static MusicApiService? _instance;
  static MusicApiService get instance {
    _instance ??= MusicApiService._();
    return _instance!;
  }

  MusicApiService._();

  // Cache for audio URLs to avoid repeated API calls
  final Map<String, String?> _audioUrlCache = {};

  /// Fetch audio URL for a specific hymn
  ///
  /// [hymnNumber] - The hymn number (1-615 for SDA Hymnal)
  /// [hymnTitle] - Optional hymn title for search matching
  ///
  /// Returns the audio URL if found, null otherwise
  ///
  /// Note: Currently only implemented for hymn #1 (SDA Hymnal) as per requirements
  Future<String?> getAudioUrl(int hymnNumber, {String? hymnTitle}) async {
    // Only support hymn #1 for now (SDA Hymnal)
    if (hymnNumber != 1) {
      if (kDebugMode) {
        debugPrint(
            '🎵 Music API: Only hymn #1 is supported, requested #$hymnNumber');
      }
      return null;
    }

    // Check cache first
    final cacheKey = 'hymn_$hymnNumber';
    if (_audioUrlCache.containsKey(cacheKey)) {
      return _audioUrlCache[cacheKey];
    }

    try {
      // For hymn #1, we'll use a placeholder/dummy URL for now
      // In production, this would query Open Opus or another API
      // Open Opus API: https://api.openopus.org/dyn/composer/list/ids/{ids}.json

      // Example: Search for "Nearer My God to Thee" or similar hymn
      // For now, return a placeholder URL structure

      // TODO: Integrate with actual API
      // This is a placeholder that demonstrates the structure
      // When real API is available, replace with actual API call

      final audioUrl = await _fetchFromOpenOpus(hymnNumber, hymnTitle);

      // Cache the result
      _audioUrlCache[cacheKey] = audioUrl;

      return audioUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to fetch audio URL for hymn #$hymnNumber: $e');
      }
      return null;
    }
  }

  /// Fetch audio URL from Open Opus API
  ///
  /// This is a placeholder implementation. In production, this would:
  /// 1. Search Open Opus for hymn-related classical pieces
  /// 2. Match hymn titles with composer works
  /// 3. Return streaming audio URL
  Future<String?> _fetchFromOpenOpus(int hymnNumber, String? hymnTitle) async {
    // Placeholder: Return null for now (no real API endpoint yet)
    // In production, implement actual Open Opus API integration

    if (kDebugMode) {
      debugPrint('🎵 Music API: Fetching from Open Opus for hymn #$hymnNumber');
      debugPrint('   Title: $hymnTitle');
    }

    // Return null to indicate no audio available yet
    // This allows the UI to show a placeholder player that's ready for API integration
    return null;

    /* Example implementation structure:
    try {
      // Search for composer or work
      final searchUrl = '$_openOpusBaseUrl/dyn/composer/search/search.php?q=$hymnTitle';
      final response = await http.get(Uri.parse(searchUrl)).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Parse response and extract audio URL
        // This depends on Open Opus API structure
        return audioUrl;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Open Opus API error: $e');
      }
    }
    return null;
    */
  }

  /// Clear the audio URL cache
  void clearCache() {
    _audioUrlCache.clear();
    if (kDebugMode) {
      debugPrint('🎵 Music API: Cache cleared');
    }
  }
}
