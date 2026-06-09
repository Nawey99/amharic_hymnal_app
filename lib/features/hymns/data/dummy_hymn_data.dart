// lib/features/hymns/data/dummy_hymn_data.dart
// Dummy hymn data for testing audio functionality
// This can be removed after validation

import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Dummy hymn for testing audio player functionality
/// 
/// Contains:
/// - Title (Amharic and English)
/// - Lyrics
/// - Audio URL (placeholder - replace with actual test audio URL)
/// 
/// Usage: Use this hymn to validate:
/// - Player UI display
/// - Play/pause functionality
/// - Stop when another song plays
/// - Single audio instance behavior
class DummyHymnData {
  /// Get a dummy hymn for testing
  /// 
  /// Replace the audioUrl with an actual test audio URL if available
  static Hymn getDummyHymn() {
    return const Hymn(
      id: 'dummy_test_001',
      number: 9999, // Use high number to avoid conflicts
      title: 'የፈተና መዝሙር', // Amharic: Test Hymn
      lyrics: '''
ይህ የፈተና መዝሙር ነው።
This is a test hymn for audio validation.
Use this to test the audio player functionality.
''',
      category: 'Test',
      audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', // Placeholder test audio URL
      sheetMusic: null,
      artist: 'Test Artist',
      song: null,
      newHymnalTitle: 'የፈተና መዝሙር',
      oldHymnalTitle: null,
      newHymnalLyrics: '''
ይህ የፈተና መዝሙር ነው።
This is a test hymn for audio validation.
Use this to test the audio player functionality.
''',
      englishTitleOld: 'Test Hymn',
      oldHymnalLyrics: null,
      isFavorite: false,
    );
  }

  /// Check if a hymn is the dummy test hymn
  static bool isDummyHymn(Hymn hymn) {
    return hymn.number == 9999 || hymn.id == 'dummy_test_001';
  }
}





