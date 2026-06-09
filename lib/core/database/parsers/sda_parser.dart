// lib/core/database/parsers/sda_parser.dart
/// Parser for SDA Hymnal JSON format
class SdaParser {
  /// Parse SDA format: find arrays by _name and combine by index
  static List<Map<String, dynamic>> parse(Map<String, dynamic> jsonData) {
    final List<dynamic> arrays = jsonData['resources']?['array'] ?? [];

    // Find arrays by _name
    List<String> newTitleArray = [];
    List<String> oldTitleArray = [];
    List<String> newLyricsArray = [];
    List<String> englishTitleArray = [];
    List<String> oldLyricsArray = [];

    for (var array in arrays) {
      if (array is Map<String, dynamic>) {
        final name = array['_name'] as String?;
        final items = array['item'] as List<dynamic>?;

        if (name == 'new_title_forbookmark' && items != null) {
          newTitleArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'old_title_forbookmark' && items != null) {
          oldTitleArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'new_song' && items != null) {
          newLyricsArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'new_title_en' && items != null) {
          englishTitleArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'old_song' && items != null) {
          oldLyricsArray = items.map((e) => e?.toString() ?? '').toList();
        }
      }
    }

    // Calculate max length
    final maxLength = [
      newTitleArray.length,
      oldTitleArray.length,
      newLyricsArray.length,
      englishTitleArray.length,
      oldLyricsArray.length,
    ].reduce((a, b) => a > b ? a : b);

    // Combine by index
    final List<Map<String, dynamic>> hymns = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < maxLength; i++) {
      hymns.add({
        'id': 'sda-$i',
        'language_code': 'am',
        'version': 'hymnal',
        'number': i + 1, // Start from 1
        'new_hymnal_title': newTitleArray.length > i
            ? (newTitleArray[i].isEmpty ? '' : newTitleArray[i])
            : '',
        'old_hymnal_title': oldTitleArray.length > i
            ? (oldTitleArray[i].isEmpty ? '' : oldTitleArray[i])
            : '',
        'new_hymnal_lyrics': newLyricsArray.length > i
            ? (newLyricsArray[i].isEmpty ? '' : newLyricsArray[i])
            : '',
        'english_title_old': englishTitleArray.length > i
            ? (englishTitleArray[i].isEmpty ? '' : englishTitleArray[i])
            : '',
        'old_hymnal_lyrics': oldLyricsArray.length > i
            ? (oldLyricsArray[i].isEmpty ? '' : oldLyricsArray[i])
            : '',
        'created_at': now,
        'updated_at': now,
      });
    }

    return hymns;
  }
}

