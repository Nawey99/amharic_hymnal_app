import 'package:characters/characters.dart';

const List<String> amharicFidelIndexOrder = [
  'ሀ',
  'ለ',
  'ሐ',
  'መ',
  'ሠ',
  'ረ',
  'ሰ',
  'ሸ',
  'ቀ',
  'በ',
  'ቨ',
  'ተ',
  'ቸ',
  'ኀ',
  'ነ',
  'ኘ',
  'አ',
  'ከ',
  'ኸ',
  'ወ',
  'ዐ',
  'ዘ',
  'ዠ',
  'የ',
  'ደ',
  'ጀ',
  'ገ',
  'ጠ',
  'ጨ',
  'ጰ',
  'ጸ',
  'ፀ',
  'ፈ',
  'ፐ',
];

const List<String> numericIndexOrder = [
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
];

final Map<String, String> _fidelToBase = {
  for (final entry in const {
    'ሀ': 'ሀ ሁ ሂ ሃ ሄ ህ ሆ',
    'ለ': 'ለ ሉ ሊ ላ ሌ ል ሎ ሏ',
    'ሐ': 'ሐ ሑ ሒ ሓ ሔ ሕ ሖ ሗ',
    'መ': 'መ ሙ ሚ ማ ሜ ም ሞ ሟ',
    'ሠ': 'ሠ ሡ ሢ ሣ ሤ ሥ ሦ ሧ',
    'ረ': 'ረ ሩ ሪ ራ ሬ ር ሮ ሯ',
    'ሰ': 'ሰ ሱ ሲ ሳ ሴ ስ ሶ ሷ',
    'ሸ': 'ሸ ሹ ሺ ሻ ሼ ሽ ሾ ሿ',
    'ቀ': 'ቀ ቁ ቂ ቃ ቄ ቅ ቆ ቋ',
    'በ': 'በ ቡ ቢ ባ ቤ ብ ቦ ቧ',
    'ቨ': 'ቨ ቩ ቪ ቫ ቬ ቭ ቮ ቯ',
    'ተ': 'ተ ቱ ቲ ታ ቴ ት ቶ ቷ',
    'ቸ': 'ቸ ቹ ቺ ቻ ቼ ች ቾ ቿ',
    'ኀ': 'ኀ ኁ ኂ ኃ ኄ ኅ ኆ ኋ',
    'ነ': 'ነ ኑ ኒ ና ኔ ን ኖ ኗ',
    'ኘ': 'ኘ ኙ ኚ ኛ ኜ ኝ ኞ ኟ',
    'አ': 'አ ኡ ኢ ኣ ኤ እ ኦ',
    'ከ': 'ከ ኩ ኪ ካ ኬ ክ ኮ ኳ',
    'ኸ': 'ኸ ኹ ኺ ኻ ኼ ኽ ኾ ዃ',
    'ወ': 'ወ ዉ ዊ ዋ ዌ ው ዎ',
    'ዐ': 'ዐ ዑ ዒ ዓ ዔ ዕ ዖ',
    'ዘ': 'ዘ ዙ ዚ ዛ ዜ ዝ ዞ ዟ',
    'ዠ': 'ዠ ዡ ዢ ዣ ዤ ዥ ዦ ዧ',
    'የ': 'የ ዩ ዪ ያ ዬ ይ ዮ',
    'ደ': 'ደ ዱ ዲ ዳ ዴ ድ ዶ ዷ',
    'ጀ': 'ጀ ጁ ጂ ጃ ጄ ጅ ጆ ጇ',
    'ገ': 'ገ ጉ ጊ ጋ ጌ ግ ጎ ጓ',
    'ጠ': 'ጠ ጡ ጢ ጣ ጤ ጥ ጦ ጧ',
    'ጨ': 'ጨ ጩ ጪ ጫ ጬ ጭ ጮ ጯ',
    'ጰ': 'ጰ ጱ ጲ ጳ ጴ ጵ ጶ ጷ',
    'ጸ': 'ጸ ጹ ጺ ጻ ጼ ጽ ጾ ጿ',
    'ፀ': 'ፀ ፁ ፂ ፃ ፄ ፅ ፆ',
    'ፈ': 'ፈ ፉ ፊ ፋ ፌ ፍ ፎ ፏ',
    'ፐ': 'ፐ ፑ ፒ ፓ ፔ ፕ ፖ ፗ',
  }.entries)
    for (final letter in entry.value.split(' ')) letter: entry.key,
};

String amharicSectionForText(String text) {
  final first = _firstMeaningfulCharacter(text);
  if (first == null) return '#';
  return _fidelToBase[first] ?? '#';
}

String numericSectionForText(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return '#';
  for (final char in trimmed.characters) {
    if (RegExp(r'\s|[()+\-.]').hasMatch(char)) continue;
    if (RegExp(r'\d').hasMatch(char)) return char;
    return '#';
  }
  return '#';
}

int? nearestSectionIndex(
  String label,
  List<String> order,
  Map<String, int> available,
) {
  if (available.isEmpty) return null;
  final exact = available[label];
  if (exact != null) return exact;

  final requested = order.indexOf(label);
  if (requested == -1) return available.values.first;

  for (var i = requested + 1; i < order.length; i++) {
    final next = available[order[i]];
    if (next != null) return next;
  }
  for (var i = requested - 1; i >= 0; i--) {
    final previous = available[order[i]];
    if (previous != null) return previous;
  }
  return null;
}

Map<String, int> buildSectionIndex<T>(
  List<T> items,
  String Function(T item) textForItem,
  String Function(String text) sectionForText,
) {
  final index = <String, int>{};
  for (var i = 0; i < items.length; i++) {
    final section = sectionForText(textForItem(items[i]));
    if (section == '#') continue;
    index.putIfAbsent(section, () => i);
  }
  return index;
}

String? _firstMeaningfulCharacter(String text) {
  for (final char in text.trim().characters) {
    if (RegExp(r'[\s\p{P}]', unicode: true).hasMatch(char)) continue;
    return char;
  }
  return null;
}
