// lib/core/services/amharic_phonetic_service.dart

/// Service for phonetic normalization of Amharic text
/// 
/// Handles phonetic-equivalent matching for Amharic characters that sound the same
/// but are written differently. This enables search to find results even when users
/// type a different but phonetically identical character.
/// 
/// Example: Searching for "ሀ" will also match "ሐ" and "ኀ" (all pronounced "ha")
class AmharicPhoneticService {
  /// Phonetic equivalence groups - characters that sound the same
  /// Each group contains characters that should be treated as equivalent in search
  static const List<List<String>> _phoneticGroups = [
    // "ha" sound - three different characters, same pronunciation
    ['ሀ', 'ሁ', 'ሂ', 'ሃ', 'ሄ', 'ህ', 'ሆ', 'ሐ', 'ሑ', 'ሒ', 'ሓ', 'ሔ', 'ሕ', 'ሖ', 'ኀ', 'ኁ', 'ኂ', 'ኃ', 'ኄ', 'ኅ', 'ኆ'],
    // "sa" sound - two different characters
    ['ሰ', 'ሱ', 'ሲ', 'ሳ', 'ሴ', 'ስ', 'ሶ', 'ሠ', 'ሡ', 'ሢ', 'ሣ', 'ሤ', 'ሥ', 'ሦ'],
    // "tsa" sound - two different characters
    ['ጸ', 'ጹ', 'ጺ', 'ጻ', 'ጼ', 'ጽ', 'ጾ', 'ፀ', 'ፁ', 'ፂ', 'ፃ', 'ፄ', 'ፅ', 'ፆ'],
    // "a" sound - two different characters (vowel)
    ['አ', 'ኡ', 'ኢ', 'ኣ', 'ኤ', 'እ', 'ኦ', 'ዐ', 'ዑ', 'ዒ', 'ዓ', 'ዔ', 'ዕ', 'ዖ'],
  ];

  /// Map from character to its normalized (canonical) form
  /// The canonical form is the first character in the phonetic group
  static final Map<String, String> _normalizationMap = _buildNormalizationMap();

  /// Build the normalization map from phonetic groups
  /// Each character maps to the first character in its group (canonical form)
  static Map<String, String> _buildNormalizationMap() {
    final Map<String, String> map = {};
    
    for (final group in _phoneticGroups) {
      if (group.isEmpty) continue;
      final canonical = group.first;
      // Map all characters in the group to the canonical form
      for (final char in group) {
        map[char] = canonical;
      }
    }
    
    return map;
  }

  /// Normalize Amharic text by replacing phonetically equivalent characters
  /// with their canonical forms
  /// 
  /// This enables search to match regardless of which phonetic variant is used.
  /// For example, "ሐልሎ" and "ሀልሎ" will both normalize to "ሀልሎ".
  /// 
  /// Characters not in phonetic groups are returned unchanged.
  /// 
  /// Why: Amharic has multiple characters that sound identical but are written differently.
  /// Users may type any variant, so we normalize to a canonical form for consistent matching.
  static String normalizeAmharic(String text) {
    if (text.isEmpty) return text;
    
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      // Replace with canonical form if it exists in the map, otherwise keep original
      // This ensures all phonetic variants map to the same canonical character
      buffer.write(_normalizationMap[char] ?? char);
    }
    
    return buffer.toString();
  }

  /// Check if two Amharic characters are phonetically equivalent
  /// 
  /// Returns true if both characters belong to the same phonetic group
  static bool arePhoneticallyEquivalent(String char1, String char2) {
    if (char1.isEmpty || char2.isEmpty) return false;
    if (char1 == char2) return true;
    
    final normalized1 = _normalizationMap[char1] ?? char1;
    final normalized2 = _normalizationMap[char2] ?? char2;
    
    return normalized1 == normalized2 && normalized1 != char1;
  }

  /// Get all characters that are phonetically equivalent to the given character
  /// 
  /// Returns a list containing the character and all its phonetic equivalents
  static List<String> getPhoneticEquivalents(String char) {
    if (char.isEmpty) return [];
    
    final canonical = _normalizationMap[char] ?? char;
    
    // Find the group containing the canonical character
    for (final group in _phoneticGroups) {
      if (group.isNotEmpty && group.first == canonical) {
        return List.from(group);
      }
    }
    
    // If not in any group, return just the character itself
    return [char];
  }
}

