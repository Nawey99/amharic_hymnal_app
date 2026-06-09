// lib/core/models/language_config.dart
class LanguageConfig {
  final String code; // e.g., 'am' for Amharic, 'en' for English
  final String name; // Display name in native language
  final String nameEn; // Display name in English
  final String flag; // Emoji flag or icon identifier

  const LanguageConfig({
    required this.code,
    required this.name,
    required this.nameEn,
    required this.flag,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageConfig &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

// Supported languages registry
class SupportedLanguages {
  static const List<LanguageConfig> languages = [
    LanguageConfig(
      code: 'am',
      name: 'አማርኛ',
      nameEn: 'Amharic',
      flag: '🇪🇹',
    ),
    LanguageConfig(
      code: 'en',
      name: 'English',
      nameEn: 'English',
      flag: '🇬🇧',
    ),
    // Add more languages as needed
    // LanguageConfig(
    //   code: 'or',
    //   name: 'Oromo',
    //   nameEn: 'Oromo',
    //   flag: '🇪🇹',
    // ),
  ];

  static LanguageConfig getDefault() => languages.first;

  static LanguageConfig? getByCode(String code) {
    try {
      return languages.firstWhere((lang) => lang.code == code);
    } catch (e) {
      return null;
    }
  }
}

