// lib/core/utils/category_ranges.dart
import 'package:amharic_hymnal_app/core/constants/hymn_categories.dart';

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
  static final Map<String, List<int>> ranges = {
    for (final category in HymnCategories.all)
      category.nameAmharic: [category.startNumber, category.endNumber],
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
    return List.generate(
        toNumber - fromNumber + 1, (index) => fromNumber + index);
  }
}
