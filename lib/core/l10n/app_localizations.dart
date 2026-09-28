// lib/core/l10n/app_localizations.dart
import 'package:flutter/material.dart';

/// App localization delegate for Amharic and English
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('am', ''),
  ];

  // Settings page strings
  String get settingsTitle => _localizedValue({
        'en': 'Settings',
        'am': 'ቅንብሮች',
      });

  String get languageLabel => _localizedValue({
        'en': 'Language',
        'am': 'ቋንቋ',
      });

  String get languageDescription => _localizedValue({
        'en': 'Select the language for hymns',
        'am': 'የመዝሙሮችን ቋንቋ ይምረጡ',
      });

  String get versionLabel => _localizedValue({
        'en': 'Version',
        'am': 'ስሪት',
      });

  String get versionDescription => _localizedValue({
        'en': 'Select hymnal version',
        'am': 'የመዝሙር ስሪት ይምረጡ',
      });

  String get fontSizeLabel => _localizedValue({
        'en': 'Font Size',
        'am': 'የፊደል መጠን',
      });

  String get backgroundImageLabel => _localizedValue({
        'en': 'Background Image',
        'am': 'የጀርባ ምስል',
      });

  String get backgroundImageDescription => _localizedValue({
        'en': 'Show background image in hymn view',
        'am': 'በመዝሙር ገጽ ላይ የጀርባ ምስል አሳይ',
      });

  String get keepScreenOnLabel => _localizedValue({
        'en': 'Keep Screen On',
        'am': 'ማያ እንዳይጠፋ',
      });

  String get keepScreenOnDescription => _localizedValue({
        'en': 'Prevent screen from turning off',
        'am': 'መዝሙር በሚነበብበት ጊዜ ማያ እንዳይጠፋ ያደርጋል',
      });

  String get developmentContributionLabel => _localizedValue({
        'en': 'Development & Contribution',
        'am': 'ማበልጸግ እና ተሳትፎ',
      });

  String get developmentContributionDescription => _localizedValue({
        'en': 'View source code and contribute',
        'am': 'የምንጭ ኮድ ይመልከቱ እና ይሳተፉ',
      });

  String get donateLabel => _localizedValue({
        'en': 'Donate',
        'am': 'ይለግሱ',
      });

  String get donateDescription => _localizedValue({
        'en': 'Support the development of this app',
        'am': 'የዚህን መተግበሪያ እድገት ይደግፉ',
      });

  String get contentSection => _localizedValue({
        'en': 'Content',
        'am': 'ይዘት',
      });

  String get displaySection => _localizedValue({
        'en': 'Display',
        'am': 'ማሳያ',
      });

  String get generalSection => _localizedValue({
        'en': 'General',
        'am': 'አጠቃላይ',
      });

  // Language names
  String get amharicLanguage => _localizedValue({
        'en': 'Amharic',
        'am': 'አማርኛ',
      });

  String get englishLanguage => _localizedValue({
        'en': 'English',
        'am': 'እንግሊዝኛ',
      });

  // Version names
  String get sdaHymnal => _localizedValue({
        'en': 'SDA Hymnal',
        'am': 'SDA መዝሙር',
      });

  String get hagerigna => _localizedValue({
        'en': 'Hagerigna',
        'am': 'ሀገርኛ',
      });

  // Hymn Detail Page
  String get sheetMusic => _localizedValue({
        'en': 'Sheet Music',
        'am': 'የሙዚቃ ኖታ',
      });

  String get audioPlayer => _localizedValue({
        'en': 'Audio Player',
        'am': 'የድምፅ ማጫወቻ',
      });

  String get audioPlayerComingSoon => _localizedValue({
        'en': 'Audio player feature coming soon',
        'am': 'የድምፅ ማጫወቻ አገልግሎት በቅርቡ ይቀርባል',
      });

  String get lyricsCopied => _localizedValue({
        'en': 'Lyrics copied to clipboard!',
        'am': 'የመዝሙሩ ግጥም ተቀድቷል!',
      });

  String get sheetMusicComingSoon => _localizedValue({
        'en': 'Sheet music viewer\n(Coming soon)',
        'am': 'የኖታ ማሳያ\n(በቅርቡ ይቀርባል)',
      });

  // Common messages
  String get noHymnsFound => _localizedValue({
        'en': 'No hymns found',
        'am': 'ምንም መዝሙር አልተገኘም',
      });

  String get noFavoritesYet => _localizedValue({
        'en': 'No favorites yet',
        'am': 'እስካሁን ምንም የተመረጠ ተወዳጅ መዝሙር የለም',
      });

  String get noFavoritesFound => _localizedValue({
        'en': 'No favorites found',
        'am': 'ምንም ተወዳጅ መዝሙር አልተገኘም',
      });

  String get addToFavoritesHint => _localizedValue({
        'en': 'Tap the heart icon on any hymn to add it to favorites',
        'am': 'ማንኛውንም መዝሙር ወደ ተወዳጅ መዝሙሮች ለመጨመር የልብ ምልክቱን ይንኩ',
      });

  // Number Search Page
  String get pleaseEnterValidNumber => _localizedValue({
        'en': 'Please enter a valid hymn number',
        'am': 'እባክዎ ትክክለኛ የመዝሙር ቁጥር ያስገቡ',
      });

  // Donate Page
  String get donateTitle => _localizedValue({
        'en': 'Donate',
        'am': 'ይለግሱ',
      });

  // Support Page
  String get copiedToClipboard => _localizedValue({
        'en': 'copied to clipboard',
        'am': 'ተቀድቷል',
      });

  // Feedback Page
  String get pleaseEnterFeedback => _localizedValue({
        'en': 'Please enter your feedback',
        'am': 'እባክዎ አስተያየትዎን ያስገቡ',
      });

  String get feedbackCopied => _localizedValue({
        'en': 'Feedback copied to clipboard. Thank you!',
        'am': 'አስተያየትዎ ተቀድቷል። እናመሰግናለን!',
      });

  String get history => _localizedValue({
        'en': 'History',
        'am': 'ታሪክ',
      });

  String get reportBug => _localizedValue({
        'en': 'Report Bug',
        'am': 'የስህተት ጥቆማ',
      });

  String get errorSharing => _localizedValue({
        'en': 'Error sharing',
        'am': 'በማጋራት ላይ ስህተት ተከስቷል',
      });

  String get error => _localizedValue({
        'en': 'Error',
        'am': 'ስህተት',
      });

  // Onboarding
  String get errorOccurred => _localizedValue({
        'en': 'Error:',
        'am': 'ስህተት:',
      });

  String _localizedValue(Map<String, String> values) {
    final langCode = locale.languageCode;
    return values[langCode] ?? values['en'] ?? '';
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'am'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
