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

  // The shell: navigation, settings and the chrome of the tabs.
  String get navCategory => _localizedValue({
        'en': 'Categories',
        'am': 'ምድብ',
      });

  String get navIndex => _localizedValue({
        'en': 'Index',
        'am': 'ማውጫ',
      });

  String get navNumber => _localizedValue({
        'en': 'Number',
        'am': 'ቁጥር',
      });

  String get navFavorites => _localizedValue({
        'en': 'Favourites',
        'am': 'ተወዳጅ',
      });

  String get navSettings => _localizedValue({
        'en': 'Settings',
        'am': 'ቅንብሮች',
      });

  String get aboutSection => _localizedValue({
        'en': 'About the app',
        'am': 'ስለ መተግበሪያው',
      });

  String get appLanguageLabel => _localizedValue({
        'en': 'App language',
        'am': 'የመተግበሪያ ቋንቋ',
      });

  String get appLanguageDescription => _localizedValue({
        'en': 'The language the app speaks in',
        'am': 'የመተግበሪያው ጽሑፍ ቋንቋ',
      });

  String get followThePhone => _localizedValue({
        'en': 'Phone',
        'am': 'የስልኩ',
      });

  String get appearanceLabel => _localizedValue({
        'en': 'Appearance',
        'am': 'ገጽታ',
      });

  String get appearanceDescription => _localizedValue({
        'en': 'Choose the brightness and colour of the app',
        'am': 'የመተግበሪያውን ብርሃን እና ቀለም ይምረጡ',
      });

  String get themeModeLight => _localizedValue({
        'en': 'Light',
        'am': 'ብርሃን',
      });

  String get themeModeDark => _localizedValue({
        'en': 'Dark',
        'am': 'ጨለማ',
      });

  String get privacyPolicyLabel => _localizedValue({
        'en': 'Privacy policy',
        'am': 'የግላዊነት ፖሊሲ',
      });

  String get privacyPolicyDescription => _localizedValue({
        'en': 'What the app does with your information',
        'am': 'መተግበሪያው ስለ መረጃዎ ምን እንደሚያደርግ',
      });

  String get privacyPolicyOpenFailed => _localizedValue({
        'en': 'Could not open the privacy policy',
        'am': 'የግላዊነት ፖሊሲውን መክፈት አልተቻለም',
      });

  String get reportBugDescription => _localizedValue({
        'en': 'Report a problem or suggest an improvement',
        'am': 'ችግር ወይም የማሻሻያ ሐሳብ ያሳውቁ',
      });

  String get openGitHubTitle => _localizedValue({
        'en': 'Open GitHub?',
        'am': 'GitHub ይከፈት?',
      });

  String get openGitHubBody => _localizedValue({
        'en': 'The source code opens in a browser, outside the app.',
        'am': 'የመተግበሪያው ምንጭ ኮድ ከመተግበሪያው ውጭ በአሳሽ ይከፈታል።',
      });

  String get gitHubOpenFailed => _localizedValue({
        'en': 'Could not open the GitHub page',
        'am': 'የGitHub ገጽ መክፈት አልተቻለም',
      });

  String get cancel => _localizedValue({
        'en': 'Cancel',
        'am': 'ይቅር',
      });

  String get open => _localizedValue({
        'en': 'Open',
        'am': 'ክፈት',
      });

  String get ok => _localizedValue({
        'en': 'OK',
        'am': 'እሺ',
      });

  String get stop => _localizedValue({
        'en': 'Stop',
        'am': 'አቁም',
      });

  String get updateRequiredTitle => _localizedValue({
        'en': 'A newer version is needed',
        'am': 'አዲስ ስሪት ያስፈልጋል',
      });

  String get indexTitle => _localizedValue({
        'en': 'Hymn index',
        'am': 'መዝሙር ማውጫ',
      });

  String get search => _localizedValue({
        'en': 'Search',
        'am': 'ፈልግ',
      });

  String get closeSearch => _localizedValue({
        'en': 'Close search',
        'am': 'ፍለጋ ዝጋ',
      });

  String get sortOrder => _localizedValue({
        'en': 'Sort order',
        'am': 'ቅደም ተከተል',
      });

  String get sortDialogTitle => _localizedValue({
        'en': 'Order',
        'am': 'አደራደር',
      });

  String get sortByNumber => _localizedValue({
        'en': 'By number',
        'am': 'በቁጥር',
      });

  String get sortByName => _localizedValue({
        'en': 'By name',
        'am': 'በስም',
      });

  String get searchHymnsHint => _localizedValue({
        'en': 'Search hymns…',
        'am': 'መዝሙር ይፈልጉ...',
      });

  String get searchByTitleHint => _localizedValue({
        'en': 'Search hymns by title…',
        'am': 'በርዕስ መዝሙር ይፈልጉ...',
      });

  String get searchFavoritesHint => _localizedValue({
        'en': 'Search favourite hymns…',
        'am': 'ተወዳጅ መዝሙሮችን ይፈልጉ...',
      });

  String get noHymnsInNameOrder => _localizedValue({
        'en': 'No hymns found in name order',
        'am': 'በስም የተደረደረ መዝሙር አልተገኘም',
      });

  String get categoriesTitle => _localizedValue({
        'en': 'Categories',
        'am': 'ምድቦች',
      });

  String get noCategoriesFound => _localizedValue({
        'en': 'No categories found',
        'am': 'ምድቦች አልተገኙም',
      });

  String get noAuthorsFound => _localizedValue({
        'en': 'No authors found',
        'am': 'ዘማሪዎች አልተገኙም',
      });

  String get categoriesAdventistOnly => _localizedValue({
        'en': 'Categories are only available for the Adventist hymnal',
        'am': 'ምድቦች ለአድቬንቲስት መዝሙር ብቻ ይገኛሉ',
      });

  String get favoritesTitle => _localizedValue({
        'en': 'Favourites',
        'am': 'ተወዳጆች',
      });

  String get pleaseEnterHymnNumber => _localizedValue({
        'en': 'Please enter a hymn number.',
        'am': 'እባክዎ የመዝሙር ቁጥር ያስገቡ።',
      });

  String updateRequiredBody(String required) => _localizedValue({
        'en': 'Please update the app to version $required or later. '
            'Without it some newer hymns may not appear correctly.',
        'am': 'እባክዎ መተግበሪያውን ወደ ስሪት $required ወይም ከዚያ በላይ ያዘምኑ። '
            'ያለዚያ አንዳንድ አዳዲስ ይዘቶች በትክክል ላይታዩ ይችላሉ።',
      });

  String hymnNumber(int number) => _localizedValue({
        'en': 'Hymn $number',
        'am': 'መዝሙር $number',
      });

  String numberNotInCollection(int min, int max) => _localizedValue({
        'en': 'That number is not in this collection. '
            'Please enter a number between $min and $max.',
        'am': 'ይህ ቁጥር በአሁኑ የመዝሙር ስብስብ ውስጥ የለም። '
            'እባክዎ ከ$min እስከ $max ያለ ቁጥር ያስገቡ።',
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
