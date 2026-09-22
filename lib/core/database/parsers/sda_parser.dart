// lib/core/database/parsers/sda_parser.dart
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

/// Parser for SDA Hymnal JSON format
class SdaParser {
  /// Parse SDA format: find arrays by _name and combine by index
  static List<Map<String, dynamic>> parse(
    Map<String, dynamic> jsonData, {
    String version = HymnalVersions.sdaNew,
  }) {
    final normalizedVersion = HymnalVersions.normalizeId(version);
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

    // The bundled file lists both books by position, but position i in one
    // book is not the same hymn as position i in the other (1975 #130 is
    // 2004 #132). So each hymn carries only its own book's fields; mixing them
    // put the other book's title and lyrics into search and categories.
    final isOld = normalizedVersion == HymnalVersions.sdaOld;
    String at(List<String> items, int i) => items.length > i ? items[i] : '';

    for (int i = 0; i < maxLength; i++) {
      final number = i + 1;
      final exists =
          isOld ? oldTitleArray.length > i || oldLyricsArray.length > i : true;
      if (!exists) continue;

      final title = isOld ? at(oldTitleArray, i) : at(newTitleArray, i);
      final lyrics = isOld ? at(oldLyricsArray, i) : at(newLyricsArray, i);

      hymns.add({
        'id': '$normalizedVersion-sda-$i',
        'language_code': 'am',
        'version': normalizedVersion,
        'number': number,
        'new_hymnal_number': isOld ? null : number,
        'old_hymnal_number': isOld ? number : null,
        'title': title,
        'lyrics': lyrics,
        // The number ranges describe the 2004 book only.
        'category': isOld
            ? null
            : HymnCategories.getCategoryByNumber(number)?.nameAmharic,
        'new_hymnal_title': isOld ? '' : title,
        'old_hymnal_title': isOld ? title : '',
        'new_hymnal_lyrics': isOld ? '' : lyrics,
        'old_hymnal_lyrics': isOld ? lyrics : '',
        // `new_title_en` holds the 2004 book's English titles.
        'english_title_old': isOld ? '' : at(englishTitleArray, i),
        'created_at': now,
        'updated_at': now,
      });
    }

    return hymns;
  }
}
