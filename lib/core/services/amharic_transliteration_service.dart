// lib/core/services/amharic_transliteration_service.dart
import 'package:flutter/services.dart';
import 'package:amharic_hymnal_app/core/utils/script_detector.dart';

/// Service for transliterating Latin characters to Amharic using EZ keyboard layout
class AmharicTransliterationService {
  // EZ keyboard phonetic mapping based on standard Amharic keyboard layout
  // Maps Latin character sequences to Amharic characters
  static const Map<String, String> _transliterationMap = {
    // Basic consonants with vowels
    'ha': 'ሀ', 'hu': 'ሁ', 'hi': 'ሂ', 'haa': 'ሃ', 'hee': 'ሄ', 'he': 'ህ',
    'ho': 'ሆ',
    'la': 'ለ', 'lu': 'ሉ', 'li': 'ሊ', 'laa': 'ላ', 'lee': 'ሌ', 'le': 'ል',
    'lo': 'ሎ',
    'hha': 'ሐ', 'hhu': 'ሑ', 'hhi': 'ሒ', 'hhaa': 'ሓ', 'hhee': 'ሔ', 'hhe': 'ሕ',
    'hho': 'ሖ',
    'ma': 'መ', 'mu': 'ሙ', 'mi': 'ሚ', 'maa': 'ማ', 'mee': 'ሜ', 'me': 'ም',
    'mo': 'ሞ',
    'sza': 'ሠ', 'szu': 'ሡ', 'szi': 'ሢ', 'szaa': 'ሣ', 'szee': 'ሤ', 'sze': 'ሥ',
    'szo': 'ሦ',
    'ra': 'ረ', 'ru': 'ሩ', 'ri': 'ሪ', 'raa': 'ራ', 'ree': 'ሬ', 're': 'ር',
    'ro': 'ሮ',
    'sa': 'ሰ', 'su': 'ሱ', 'si': 'ሲ', 'saa': 'ሳ', 'see': 'ሴ', 'se': 'ስ',
    'so': 'ሶ',
    'sha': 'ሸ', 'shu': 'ሹ', 'shi': 'ሺ', 'shaa': 'ሻ', 'shee': 'ሼ', 'she': 'ሽ',
    'sho': 'ሾ',
    'qa': 'ቀ', 'qu': 'ቁ', 'qi': 'ቂ', 'qaa': 'ቃ', 'qee': 'ቄ', 'qe': 'ቅ',
    'qo': 'ቆ',
    'qha': 'ቐ', 'qhu': 'ቑ', 'qhi': 'ቒ', 'qhaa': 'ቓ', 'qhee': 'ቔ', 'qhe': 'ቕ',
    'qho': 'ቖ',
    'ba': 'በ', 'bu': 'ቡ', 'bi': 'ቢ', 'baa': 'ባ', 'bee': 'ቤ', 'be': 'ብ',
    'bo': 'ቦ',
    'va': 'ቨ', 'vu': 'ቩ', 'vi': 'ቪ', 'vaa': 'ቫ', 'vee': 'ቬ', 've': 'ቭ',
    'vo': 'ቮ',
    'ta': 'ተ', 'tu': 'ቱ', 'ti': 'ቲ', 'taa': 'ታ', 'tee': 'ቴ', 'te': 'ት',
    'to': 'ቶ',
    'ca': 'ቸ', 'cu': 'ቹ', 'ci': 'ቺ', 'caa': 'ቻ', 'cee': 'ቼ', 'ce': 'ች',
    'co': 'ቾ',
    'xa': 'ኀ', 'xu': 'ኁ', 'xi': 'ኂ', 'xaa': 'ኃ', 'xee': 'ኄ', 'xe': 'ኅ',
    'xo': 'ኆ',
    'na': 'ነ', 'nu': 'ኑ', 'ni': 'ኒ', 'naa': 'ና', 'nee': 'ኔ', 'ne': 'ን',
    'no': 'ኖ',
    'nya': 'ኘ', 'nyu': 'ኙ', 'nyi': 'ኚ', 'nyaa': 'ኛ', 'nyee': 'ኜ', 'nye': 'ኝ',
    'nyo': 'ኞ',
    'a': 'አ', 'au': 'ኡ', 'ai': 'ኢ', 'aa': 'አ', 'aee': 'ኤ', 'ae': 'እ', 'ao': 'ኦ',
    'ka': 'ከ', 'ku': 'ኩ', 'ki': 'ኪ', 'kaa': 'ካ', 'kee': 'ኬ', 'ke': 'ክ',
    'ko': 'ኮ',
    'kxa': 'ኸ', 'kxu': 'ኹ', 'kxi': 'ኺ', 'kxaa': 'ኻ', 'kxee': 'ኼ', 'kxe': 'ኽ',
    'kxo': 'ኾ',
    'wa': 'ወ', 'wu': 'ዉ', 'wi': 'ዊ', 'waa': 'ዋ', 'wee': 'ዌ', 'we': 'ው',
    'wo': 'ዎ',
    'za': 'ዘ', 'zu': 'ዙ', 'zi': 'ዚ', 'zaa': 'ዛ', 'zee': 'ዜ', 'ze': 'ዝ',
    'zo': 'ዞ',
    'zha': 'ዠ', 'zhu': 'ዡ', 'zhi': 'ዢ', 'zhaa': 'ዣ', 'zhee': 'ዤ', 'zhe': 'ዥ',
    'zho': 'ዦ',
    'ya': 'የ', 'yu': 'ዩ', 'yi': 'ዪ', 'yaa': 'ያ', 'yee': 'ዬ', 'ye': 'ይ',
    'yo': 'ዮ',
    'da': 'ደ', 'du': 'ዱ', 'di': 'ዲ', 'daa': 'ዳ', 'dee': 'ዴ', 'de': 'ድ',
    'do': 'ዶ',
    'dda': 'ዸ', 'ddu': 'ዹ', 'ddi': 'ዺ', 'ddaa': 'ዻ', 'ddee': 'ዼ', 'dde': 'ዽ',
    'ddo': 'ዾ',
    'ja': 'ጀ', 'ju': 'ጁ', 'ji': 'ጂ', 'jaa': 'ጃ', 'jee': 'ጄ', 'je': 'ጅ',
    'jo': 'ጆ',
    'ga': 'ገ', 'gu': 'ጉ', 'gi': 'ጊ', 'gaa': 'ጋ', 'gee': 'ጌ', 'ge': 'ግ',
    'go': 'ጎ',
    'gga': 'ጐ', 'ggu': '጑', 'ggi': 'ጒ', 'ggaa': 'ጓ', 'ggee': 'ጔ', 'gge': 'ጕ',
    'ggo': '጖',
    'tha': 'ጠ', 'thu': 'ጡ', 'thi': 'ጢ', 'thaa': 'ጣ', 'thee': 'ጤ', 'the': 'ጥ',
    'tho': 'ጦ',
    'cha': 'ጨ', 'chu': 'ጩ', 'chi': 'ጪ', 'chaa': 'ጫ', 'chee': 'ጬ', 'che': 'ጭ',
    'cho': 'ጮ',
    'pha': 'ጰ', 'phu': 'ጱ', 'phi': 'ጲ', 'phaa': 'ጳ', 'phee': 'ጴ', 'phe': 'ጵ',
    'pho': 'ጶ',
    'tsa': 'ጸ', 'tsu': 'ጹ', 'tsi': 'ጺ', 'tsaa': 'ጻ', 'tsee': 'ጼ', 'tse': 'ጽ',
    'tso': 'ጾ',
    'tza': 'ፀ', 'tzu': 'ፁ', 'tzi': 'ፂ', 'tzaa': 'ፃ', 'tzee': 'ፄ', 'tze': 'ፅ',
    'tzo': 'ፆ',
    'fa': 'ፈ', 'fu': 'ፉ', 'fi': 'ፊ', 'faa': 'ፋ', 'fee': 'ፌ', 'fe': 'ፍ',
    'fo': 'ፎ',
    'pa': 'ፐ', 'pu': 'ፑ', 'pi': 'ፒ', 'paa': 'ፓ', 'pee': 'ፔ', 'pe': 'ፕ',
    'po': 'ፖ',

    // Special characters
    ' ': ' ', '\n': '\n',
  };

  /// Transliterate Latin text to Amharic
  static String transliterate(String latinText) {
    if (latinText.isEmpty) return '';

    String result = '';
    int i = 0;

    while (i < latinText.length) {
      bool found = false;

      // Try to match longest sequences first (up to 4 characters)
      for (int len = 4; len >= 1 && i + len <= latinText.length; len--) {
        final substring = latinText.substring(i, i + len).toLowerCase();
        if (_transliterationMap.containsKey(substring)) {
          result += _transliterationMap[substring]!;
          i += len;
          found = true;
          break;
        }
      }

      if (!found) {
        // If no match found, keep the original character
        result += latinText[i];
        i++;
      }
    }

    return result;
  }

  // Expose transliteration map for formatter
  static Map<String, String> get transliterationMap => _transliterationMap;
}

/// TextInputFormatter for real-time Amharic transliteration
/// Transliterates as user types, converting Latin phonetic input to Amharic
class AmharicTransliterationFormatter extends TextInputFormatter {
  String _pendingText = '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If text hasn't changed, return as is
    if (newValue.text == oldValue.text) {
      return newValue;
    }

    final oldText = oldValue.text;
    final newText = newValue.text;

    // Handle deletion - clear buffer and return new value
    if (newText.length < oldText.length) {
      _pendingText = '';
      return newValue;
    }

    // Get the inserted text
    final insertedText = newText.substring(oldText.length);

    // If user is typing Amharic directly, don't process - just return as-is
    if (insertedText.isNotEmpty && ScriptDetector.isAmharic(insertedText)) {
      _pendingText = '';
      return newValue;
    }

    // Handle space, punctuation, or special characters - keep as is
    if (insertedText.length == 1) {
      final char = insertedText[0];
      if (char == ' ' ||
          char == '\n' ||
          char == '.' ||
          char == ',' ||
          char == '?' ||
          char == '!' ||
          char == ':' ||
          char == ';' ||
          char == '-' ||
          char == '_' ||
          char == '(' ||
          char == ')' ||
          char == '[' ||
          char == ']') {
        _pendingText = '';
        return newValue;
      }
    }

    // Add to pending text for processing
    _pendingText += insertedText.toLowerCase();

    // Process pending text - transliterate what we can
    String result = oldText;
    int processed = 0;
    final map = AmharicTransliterationService.transliterationMap;

    // Process from the end backwards to handle multi-character sequences
    // Start from the end and work backwards to find longest matches
    int i = 0;
    while (i < _pendingText.length) {
      bool matched = false;
      // Try to match sequences from current position
      for (int len = 4; len >= 1 && i + len <= _pendingText.length; len--) {
        final substr = _pendingText.substring(i, i + len);
        if (map.containsKey(substr)) {
          result += map[substr]!;
          i += len;
          processed += len;
          matched = true;
          break;
        }
      }

      if (!matched) {
        // Check if this could be start of a sequence
        final char = _pendingText[i];
        final couldStartSequence = map.keys.any((k) => k.startsWith(char));

        if (couldStartSequence && i < _pendingText.length - 1) {
          // Might be incomplete sequence, wait for more input
          break;
        } else {
          // Not a sequence, add as-is
          result += char;
          i++;
          processed++;
        }
      }
    }

    // Update pending text
    if (processed > 0) {
      _pendingText = _pendingText.substring(processed);
    }

    // Calculate cursor position
    final cursorPos = newValue.selection.baseOffset;

    return TextEditingValue(
      text: result,
      selection:
          TextSelection.collapsed(offset: cursorPos.clamp(0, result.length)),
    );
  }
}
