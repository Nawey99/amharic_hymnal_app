// lib/core/utils/script_detector.dart

/// Utility for detecting the script type of input text
///
/// Determines whether text is written in Amharic (Ge'ez script) or English (Latin script).
/// This is essential for applying the correct search algorithm:
/// - Amharic: phonetic normalization matching
/// - English: case-insensitive string matching
enum ScriptType {
  /// Amharic text using Ge'ez script (Unicode range U+1200–U+137F)
  amharic,

  /// English text using Latin script (ASCII/Unicode Latin ranges)
  english,

  /// Mixed or unknown script
  mixed,
}

/// Detects the script type of input text
class ScriptDetector {
  /// Amharic (Ge'ez) Unicode range: U+1200 to U+137F
  /// This covers the Amharic syllabary
  static const int _amharicStart = 0x1200;
  static const int _amharicEnd = 0x137F;

  /// Extended Amharic range: U+1380 to U+139F (supplementary characters)
  static const int _amharicExtendedStart = 0x1380;
  static const int _amharicExtendedEnd = 0x139F;

  /// Latin script ranges (basic and extended)
  /// Basic Latin: U+0020-U+007F (ASCII printable)
  /// Latin-1 Supplement: U+0080-U+00FF
  /// Latin Extended-A: U+0100-U+017F
  /// Latin Extended-B: U+0180-U+024F
  static const int _latinStart = 0x0020;
  static const int _latinEnd = 0x024F;

  /// Detect the script type of the given text
  ///
  /// Returns:
  /// - [ScriptType.amharic] if text contains primarily Amharic characters
  /// - [ScriptType.english] if text contains primarily Latin characters
  /// - [ScriptType.mixed] if text contains significant amounts of both
  ///
  /// Detection is based on the first non-whitespace character found,
  /// or majority if multiple characters are present.
  static ScriptType detect(String text) {
    if (text.isEmpty) return ScriptType.english; // Default to English for empty

    // Remove whitespace and punctuation for analysis
    final cleaned = text.replaceAll(RegExp(r'[\s\p{P}]', unicode: true), '');
    if (cleaned.isEmpty) return ScriptType.english;

    int amharicCount = 0;
    int latinCount = 0;

    for (int i = 0; i < cleaned.length; i++) {
      final codeUnit = cleaned.codeUnitAt(i);

      if (_isAmharic(codeUnit)) {
        amharicCount++;
      } else if (_isLatin(codeUnit)) {
        latinCount++;
      }
    }

    // If no script characters found, default to English
    if (amharicCount == 0 && latinCount == 0) {
      return ScriptType.english;
    }

    // Determine based on majority
    if (amharicCount > latinCount) {
      return ScriptType.amharic;
    } else if (latinCount > amharicCount) {
      return ScriptType.english;
    } else {
      // Equal counts or mixed - check first character for tie-breaker
      final firstChar = cleaned.codeUnitAt(0);
      if (_isAmharic(firstChar)) {
        return ScriptType.amharic;
      } else {
        return ScriptType.english;
      }
    }
  }

  /// Check if a character code unit is in the Amharic range
  static bool _isAmharic(int codeUnit) {
    return (codeUnit >= _amharicStart && codeUnit <= _amharicEnd) ||
        (codeUnit >= _amharicExtendedStart && codeUnit <= _amharicExtendedEnd);
  }

  /// Check if a character code unit is in the Latin range
  static bool _isLatin(int codeUnit) {
    return codeUnit >= _latinStart && codeUnit <= _latinEnd;
  }

  /// Check if text is primarily Amharic
  static bool isAmharic(String text) {
    return detect(text) == ScriptType.amharic;
  }

  /// Check if text is primarily English
  static bool isEnglish(String text) {
    return detect(text) == ScriptType.english;
  }
}
