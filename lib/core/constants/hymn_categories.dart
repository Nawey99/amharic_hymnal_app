// lib/core/constants/hymn_categories.dart
import 'package:amharic_hymnal_app/core/models/hymn_category.dart';

/// Canonical definition of all 31 hymn categories
///
/// This is the single source of truth for category definitions.
/// Each category maps to a specific hymn number range.
///
/// Categories are validated to ensure:
/// - No overlaps
/// - No gaps
/// - All hymns 1-325 are covered
class HymnCategories {
  /// All 31 categories in order
  static const List<HymnCategory> all = [
    HymnCategory(
        id: 'praise', nameAmharic: 'ምስጋና', startNumber: 1, endNumber: 24),
    HymnCategory(
        id: 'worship', nameAmharic: 'ስግደት', startNumber: 25, endNumber: 42),
    HymnCategory(
        id: 'awakening', nameAmharic: 'መነቃቃት', startNumber: 43, endNumber: 44),
    HymnCategory(
        id: 'repentance', nameAmharic: 'ንሥሐ', startNumber: 45, endNumber: 58),
    HymnCategory(
        id: 'prayer', nameAmharic: 'ጸሎት', startNumber: 59, endNumber: 84),
    HymnCategory(
        id: 'christian_life',
        nameAmharic: 'የክርስቲያን ኑሮ',
        startNumber: 85,
        endNumber: 116),
    HymnCategory(
        id: 'self_sacrifice',
        nameAmharic: 'ራስን ቀድሶ መስጠት',
        startNumber: 117,
        endNumber: 118),
    HymnCategory(
        id: 'work', nameAmharic: 'ሥራ', startNumber: 119, endNumber: 121),
    HymnCategory(
        id: 'people', nameAmharic: 'ሕዝብ', startNumber: 122, endNumber: 122),
    HymnCategory(
        id: 'faithfulness',
        nameAmharic: 'ታማኝነት',
        startNumber: 123,
        endNumber: 128),
    HymnCategory(
        id: 'hope', nameAmharic: 'ተስፋ', startNumber: 129, endNumber: 134),
    HymnCategory(
        id: 'joy', nameAmharic: 'ደስታ', startNumber: 135, endNumber: 140),
    HymnCategory(
        id: 'peace', nameAmharic: 'ሰላም', startNumber: 141, endNumber: 146),
    HymnCategory(
        id: 'love', nameAmharic: 'ፍቅር', startNumber: 147, endNumber: 159),
    HymnCategory(
        id: 'salvation', nameAmharic: 'መድህን', startNumber: 160, endNumber: 178),
    HymnCategory(
        id: 'cross', nameAmharic: 'መስቀል', startNumber: 179, endNumber: 193),
    HymnCategory(
        id: 'sabbath', nameAmharic: 'ሰንበት', startNumber: 194, endNumber: 197),
    HymnCategory(
        id: 'word_of_god',
        nameAmharic: 'የእግዚአብሔር ቃል',
        startNumber: 198,
        endNumber: 203),
    HymnCategory(
        id: 'christian_struggle',
        nameAmharic: 'የክርስቲያን ተጋድሎ',
        startNumber: 204,
        endNumber: 206),
    HymnCategory(
        id: 'judgment', nameAmharic: 'ፍርድ', startNumber: 207, endNumber: 208),
    HymnCategory(
        id: 'second_coming',
        nameAmharic: 'ዳግም ምፅአት',
        startNumber: 209,
        endNumber: 220),
    HymnCategory(
        id: 'heaven', nameAmharic: 'የሰማይ ቤት', startNumber: 221, endNumber: 241),
    HymnCategory(
        id: 'youth', nameAmharic: 'ወጣቶች', startNumber: 242, endNumber: 264),
    HymnCategory(
        id: 'nature', nameAmharic: 'ተፈጥሮ', startNumber: 265, endNumber: 266),
    HymnCategory(
        id: 'children',
        nameAmharic: 'የልጆች መዝሙር',
        startNumber: 267,
        endNumber: 275),
    HymnCategory(
        id: 'marriage', nameAmharic: 'ጋብቻ', startNumber: 276, endNumber: 277),
    HymnCategory(
        id: 'birth', nameAmharic: 'ልደት', startNumber: 278, endNumber: 292),
    HymnCategory(
        id: 'trust', nameAmharic: 'መታመን', startNumber: 293, endNumber: 310),
    HymnCategory(
        id: 'offering', nameAmharic: 'ቁርባን', startNumber: 311, endNumber: 314),
    HymnCategory(
        id: 'resurrection',
        nameAmharic: 'ትንሣኤ',
        startNumber: 315,
        endNumber: 320),
    HymnCategory(
        id: 'funeral', nameAmharic: 'መሰናበቻ', startNumber: 321, endNumber: 325),
  ];

  /// Get category by hymn number
  static HymnCategory? getCategoryByNumber(int hymnNumber) {
    for (final category in all) {
      if (category.contains(hymnNumber)) {
        return category;
      }
    }
    return null;
  }

  /// Get category by ID
  static HymnCategory? getCategoryById(String id) {
    try {
      return all.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get category by Amharic name
  static HymnCategory? getCategoryByName(String nameAmharic) {
    try {
      return all.firstWhere((cat) => cat.nameAmharic == nameAmharic);
    } catch (e) {
      return null;
    }
  }

  /// Validate all categories for overlaps and gaps
  ///
  /// Returns a list of validation errors, empty if valid
  static List<String> validate() {
    final List<String> errors = [];

    // Check for overlaps
    for (int i = 0; i < all.length; i++) {
      for (int j = i + 1; j < all.length; j++) {
        final cat1 = all[i];
        final cat2 = all[j];

        // Check if ranges overlap
        if ((cat1.startNumber <= cat2.endNumber &&
            cat1.endNumber >= cat2.startNumber)) {
          errors.add(
            'Overlap detected: ${cat1.nameAmharic} (${cat1.startNumber}-${cat1.endNumber}) '
            'and ${cat2.nameAmharic} (${cat2.startNumber}-${cat2.endNumber})',
          );
        }
      }
    }

    // Check for gaps and coverage (should cover 1-325)
    final coveredNumbers = <int>{};
    for (final category in all) {
      for (int num = category.startNumber; num <= category.endNumber; num++) {
        coveredNumbers.add(num);
      }
    }

    // Check for gaps
    for (int num = 1; num <= 325; num++) {
      if (!coveredNumbers.contains(num)) {
        errors.add('Gap detected: Hymn #$num is not covered by any category');
      }
    }

    // Check for numbers outside expected range
    for (final category in all) {
      if (category.startNumber < 1 || category.endNumber > 325) {
        errors.add(
          'Category ${category.nameAmharic} has numbers outside range 1-325: '
          '${category.startNumber}-${category.endNumber}',
        );
      }
    }

    return errors;
  }

  /// Get all hymn numbers covered by categories
  static Set<int> getAllCoveredNumbers() {
    final Set<int> numbers = {};
    for (final category in all) {
      numbers.addAll(category.hymnNumbers);
    }
    return numbers;
  }
}
