// lib/core/utils/amharic_utils.dart

/// Utility functions for Amharic text processing
class AmharicUtils {
  /// Complete Amharic fidel structure - all 33 groups with their children
  static const List<List<String>> fidel = [
    ["ሀ", "ሁ", "ሂ", "ሃ", "ሄ", "ህ", "ሆ"],
    ["ለ", "ሉ", "ሊ", "ላ", "ሌ", "ል", "ሎ"],
    ["ሐ", "ሑ", "ሒ", "ሓ", "ሔ", "ሕ", "ሖ"],
    ["መ", "ሙ", "ሚ", "ማ", "ሜ", "ም", "ሞ"],
    ["ሠ", "ሡ", "ሢ", "ሣ", "ሤ", "ሥ", "ሦ"],
    ["ረ", "ሩ", "ሪ", "ራ", "ሬ", "ር", "ሮ"],
    ["ሰ", "ሱ", "ሲ", "ሳ", "ሴ", "ስ", "ሶ"],
    ["ሸ", "ሹ", "ሺ", "ሻ", "ሼ", "ሽ", "ሾ"],
    ["ቀ", "ቁ", "ቂ", "ቃ", "ቄ", "ቅ", "ቆ"],
    ["በ", "ቡ", "ቢ", "ባ", "ቤ", "ብ", "ቦ"],
    ["ተ", "ቱ", "ቲ", "ታ", "ቴ", "ት", "ቶ"],
    ["ቸ", "ቹ", "ቺ", "ቻ", "ቼ", "ች", "ቾ"],
    ["ኀ", "ኁ", "ኂ", "ኃ", "ኄ", "ኅ", "ኆ"],
    ["ነ", "ኑ", "ኒ", "ና", "ኔ", "ን", "ኖ"],
    ["ኘ", "ኙ", "ኚ", "ኛ", "ኜ", "ኝ", "ኞ"],
    ["አ", "ኡ", "ኢ", "ኣ", "ኤ", "እ", "ኦ"],
    ["ከ", "ኩ", "ኪ", "ካ", "ኬ", "ክ", "ኮ"],
    ["ኸ", "ኹ", "ኺ", "ኻ", "ኼ", "ኽ", "ኾ"],
    ["ወ", "ዉ", "ዊ", "ዋ", "ዌ", "ው", "ዎ"],
    ["ዐ", "ዑ", "ዒ", "ዓ", "ዔ", "ዕ", "ዖ"],
    ["ዘ", "ዙ", "ዚ", "ዛ", "ዜ", "ዝ", "ዞ"],
    ["ዠ", "ዡ", "ዢ", "ዣ", "ዤ", "ዥ", "ዦ"],
    ["የ", "ዩ", "ዪ", "ያ", "ዬ", "ይ", "ዮ"],
    ["ደ", "ዱ", "ዲ", "ዳ", "ዴ", "ድ", "ዶ"],
    ["ዸ", "ዹ", "ዺ", "ዻ", "ዼ", "ዽ", "ዾ"],
    ["ጀ", "ጁ", "ጂ", "ጃ", "ጄ", "ጅ", "ጆ"],
    ["ገ", "ጉ", "ጊ", "ጋ", "ጌ", "ግ", "ጎ"],
    ["ጘ", "ጙ", "ጚ", "ጛ", "ጜ", "ጝ", "ጞ"],
    ["ጠ", "ጡ", "ጢ", "ጣ", "ጤ", "ጥ", "ጦ"],
    ["ጨ", "ጩ", "ጪ", "ጫ", "ጬ", "ጭ", "ጮ"],
    ["ጰ", "ጱ", "ጲ", "ጳ", "ጴ", "ጵ", "ጶ"],
    ["ጸ", "ጹ", "ጺ", "ጻ", "ጼ", "ጽ", "ጾ"],
    ["ፀ", "ፁ", "ፂ", "ፃ", "ፄ", "ፅ", "ፆ"],
    ["ፈ", "ፉ", "ፊ", "ፋ", "ፌ", "ፍ", "ፎ"],
    ["ፐ", "ፑ", "ፒ", "ፓ", "ፔ", "ፕ", "ፖ"]
  ];

  /// Primary Amharic letters (group fathers - first character of each family)
  /// The first letter of each group in the fidel structure
  static List<String> get primaryLetters {
    return fidel.map((group) => group.first).toList();
  }

  /// Get the group index for a given letter
  static int? getGroupIndex(String letter) {
    for (int i = 0; i < fidel.length; i++) {
      if (fidel[i].contains(letter)) {
        return i;
      }
    }
    return null;
  }

  /// Get primary Amharic letter (first character of the family) from text
  ///
  /// Returns the primary letter that the first character of the text belongs to.
  /// If the text doesn't start with an Amharic character, returns the uppercase
  /// version of the first character.
  static String getPrimaryLetter(String text) {
    if (text.isEmpty) return '';

    final firstChar = text[0];

    // Check which group this letter belongs to
    for (final group in fidel) {
      if (group.contains(firstChar)) {
        return group.first; // Return the primary letter (first in group)
      }
    }

    // If not an Amharic letter, return uppercase
    return firstChar.toUpperCase();
  }

  /// Get all letters in a primary letter's group
  static List<String> getGroupLetters(String primaryLetter) {
    for (final group in fidel) {
      if (group.first == primaryLetter) {
        return List.from(group);
      }
    }
    return [primaryLetter];
  }

  /// Check if a letter belongs to a primary letter family
  static bool belongsToPrimaryLetter(String letter, String primaryLetter) {
    if (letter.isEmpty || primaryLetter.isEmpty) return false;

    final group = getGroupLetters(primaryLetter);
    return group.contains(letter);
  }

  /// Group letters by their primary letter
  static Map<String, List<String>> groupLettersByPrimary(List<String> letters) {
    final Map<String, List<String>> grouped = {};

    for (final letter in letters) {
      final primary = getPrimaryLetter(letter);
      if (!grouped.containsKey(primary)) {
        grouped[primary] = [];
      }
      if (!grouped[primary]!.contains(letter)) {
        grouped[primary]!.add(letter);
      }
    }

    // Sort each group's letters according to fidel order
    for (final primary in grouped.keys) {
      final group = getGroupLetters(primary);
      grouped[primary]!.sort((a, b) {
        final indexA = group.indexOf(a);
        final indexB = group.indexOf(b);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    return grouped;
  }
}
