// lib/core/database/parsers/hagerigna_parser.dart
/// Parser for Hagerigna JSON format
class HagerignaParser {
  /// Parse Hagerigna format: find arrays by _name and combine by index
  static List<Map<String, dynamic>> parse(Map<String, dynamic> jsonData) {
    final List<dynamic> arrays = jsonData['resources']?['array'] ?? [];

    // Find arrays by _name
    List<String> artistArray = [];
    List<String> songArray = [];
    List<String> titleArray = [];

    for (var array in arrays) {
      if (array is Map<String, dynamic>) {
        final name = array['_name'] as String?;
        final items = array['item'] as List<dynamic>?;

        if (name == 'song_author_text' && items != null) {
          artistArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'song_text' && items != null) {
          songArray = items.map((e) => e?.toString() ?? '').toList();
        } else if (name == 'song_title_text' && items != null) {
          titleArray = items.map((e) => e?.toString() ?? '').toList();
        }
      }
    }

    // Calculate max length
    final maxLength = [
      artistArray.length,
      songArray.length,
      titleArray.length,
    ].reduce((a, b) => a > b ? a : b);

    // Combine by index
    final List<Map<String, dynamic>> hymns = [];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (int i = 0; i < maxLength; i++) {
      hymns.add({
        'id': 'hagerigna-$i',
        'language_code': 'am',
        'version': 'hagerigna',
        'number': i + 1, // Start from 1
        'title': titleArray.length > i
            ? (titleArray[i].isEmpty ? '' : titleArray[i])
            : '',
        'lyrics': songArray.length > i
            ? (songArray[i].isEmpty ? '' : songArray[i])
            : '',
        'artist': artistArray.length > i
            ? (artistArray[i].isEmpty ? '' : artistArray[i])
            : '',
        'song': songArray.length > i
            ? (songArray[i].isEmpty ? '' : songArray[i])
            : '',
        'created_at': now,
        'updated_at': now,
      });
    }

    return hymns;
  }
}
