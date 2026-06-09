// lib/core/utils/category_ranges.dart

/// Exact category ranges for SDA Hymnal
/// 
/// Format: "Category Name": fromNumber - toNumber (inclusive)
/// 
/// Categories are static and defined by numeric ranges.
/// Each hymn number belongs to exactly one category.
class CategoryRanges {
  /// Category name to range mapping
  /// Key: Category name (Amharic)
  /// Value: List of two integers [fromNumber, toNumber]
  static const Map<String, List<int>> ranges = {
    'ምስጋና': [1, 24],
    'ስግደት': [25, 42],
    'መነቃቃት': [43, 44],
    'ንሥሐ': [45, 58],
    'ጸሎት': [59, 84],
    'የክርስቲያን ኑሮ': [85, 116],
    'ራስን ቀድሶ መስጠት': [117, 118],
    'ሥራ': [119, 121],
    'ሕዝብ': [122, 122],
    'ታማኝነት': [123, 128],
    'ተስፋ': [129, 134],
    'ደስታ': [135, 140],
    'ሰላም': [141, 146],
    'ፍቅር': [147, 159],
    'መድህን': [160, 178],
    'መስቀል': [179, 193],
    'ሰንበት': [194, 197],
    'የእግዚአብሔር ቃል': [198, 203],
    'የክርስቲያን ተጋድሎ': [204, 206],
    'ፍርድ': [207, 208],
    'ዳግም ምፅአት': [209, 220],
    'የሰማይ ቤት': [221, 241],
    'ወጣቶች': [242, 264],
    'ተፈጥሮ': [265, 266],
    'የልጆች መዝሙር': [267, 275],
    'ጋብቻ': [276, 277],
    'ልደት': [278, 292],
    'መታመን': [293, 310],
    'ቁርባን': [311, 314],
    'ትንሣኤ': [315, 320],
    'መሰናበቻ': [321, 325],
  };

  /// Get all category names sorted by starting hymn number (ascending)
  static List<String> get allCategories {
    final entries = ranges.entries.toList();
    // Sort by fromNumber (range[0]) in ascending order
    entries.sort((a, b) => a.value[0].compareTo(b.value[0]));
    return entries.map((e) => e.key).toList();
  }

  /// Get category range for a given category name
  /// Returns null if category doesn't exist
  static List<int>? getRange(String categoryName) {
    return ranges[categoryName];
  }

  /// Get category name for a given hymn number
  /// Returns null if hymn number doesn't belong to any category
  static String? getCategoryForHymn(int hymnNumber) {
    for (final entry in ranges.entries) {
      final range = entry.value;
      final fromNumber = range[0];
      final toNumber = range[1];
      if (hymnNumber >= fromNumber && hymnNumber <= toNumber) {
        return entry.key;
      }
    }
    return null;
  }

  /// Check if a hymn number belongs to a category
  static bool hymnBelongsToCategory(int hymnNumber, String categoryName) {
    final range = ranges[categoryName];
    if (range == null) return false;
    return hymnNumber >= range[0] && hymnNumber <= range[1];
  }

  /// Get all hymn numbers in a category
  static List<int> getHymnNumbersInCategory(String categoryName) {
    final range = ranges[categoryName];
    if (range == null) return [];
    final fromNumber = range[0];
    final toNumber = range[1];
    return List.generate(toNumber - fromNumber + 1, (index) => fromNumber + index);
  }
}

