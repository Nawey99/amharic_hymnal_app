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

  // App title and app-wide labels
  String get appTitle => _localizedValue({
        'en': 'Wudase',
        'am': 'ውዳሴ',
      });

  String get initializationFailed => _localizedValue({
        'en': 'Failed to start the app',
        'am': 'መተግበሪያውን ማስጀመር አልተቻለም',
      });

  String initializationFailedWith(String message) => _localizedValue({
        'en': 'Failed to start the app: $message',
        'am': 'መተግበሪያውን ማስጀመር አልተቻለም: $message',
      });

  // Onboarding
  String get onboardingSkip => _localizedValue({
        'en': 'Skip',
        'am': 'ዝለል',
      });

  String get onboardingNext => _localizedValue({
        'en': 'Next',
        'am': 'ቀጣይ',
      });

  String get onboardingStart => _localizedValue({
        'en': 'Start',
        'am': 'ጀምር',
      });

  String get onboardingStep1Title => _localizedValue({
        'en': 'About the Wudase app',
        'am': 'ስለ ውዳሴ መተግበሪያ',
      });

  String get onboardingStep1Description => _localizedValue({
        'en':
            'Wudase brings Amharic Adventist and Hagerigna hymns — their lyrics, sheet music and audio — together in one place.',
        'am':
            'ውዳሴ የአማርኛ አድቬንቲስት እና የሀገርኛ መዝሙሮችን ከነግጥማቸው፣ ከሙዚቃ ኖታና ከድምፃቸው ጋር በአንድ ቦታ ያቀርባል።',
      });

  String get onboardingStep1Access => _localizedValue({
        'en':
            'When the app opens, the Number page appears first. Use the tab bar at the bottom to move between pages.',
        'am': 'መተግበሪያው ሲከፈት መጀመሪያ የቁጥር ገጽ ይታያል። ከታች የሚገኘው የማውጫ አሞሌ በገጾች መካከል ለመዘዋወር ያገለግላል።',
      });

  String get onboardingStep1Bullet1 => _localizedValue({
        'en': 'Hymn lyrics',
        'am': 'የመዝሙር ግጥሞች',
      });

  String get onboardingStep1Bullet2 => _localizedValue({
        'en': 'Open by number',
        'am': 'በቁጥር መክፈት',
      });

  String get onboardingStep1Bullet3 => _localizedValue({
        'en': 'Save favourites',
        'am': 'ተወዳጆችን መመዝገብ',
      });

  String get onboardingStep2Title => _localizedValue({
        'en': 'Open a hymn by number',
        'am': 'በቁጥር መዝሙር ይክፈቱ',
      });

  String get onboardingStep2Description => _localizedValue({
        'en':
            'If you know the hymn number you can jump straight to the lyrics. If the number is not in the collection the app will tell you.',
        'am':
            'የመዝሙሩን ቁጥር ካወቁ በፍጥነት ወደ ግጥሙ መግባት ይችላሉ። ቁጥሩ በስብስቡ ውስጥ ካልገኘ መተግበሪያው ያሳውቃል።',
      });

  String get onboardingStep2Access => _localizedValue({
        'en': 'Tap "Number" at the bottom, enter the hymn number, then tap "Open".',
        'am': 'ከታች “ቁጥር”ን ይንኩ፤ የመዝሙሩን ቁጥር ካስገቡ በኋላ “ክፈት”ን ይጫኑ።',
      });

  String get onboardingStep2Bullet1 => _localizedValue({
        'en': 'Search by number',
        'am': 'በቁጥር መፈለግ',
      });

  String get onboardingStep2Bullet2 => _localizedValue({
        'en': 'Open directly',
        'am': 'በቀጥታ መክፈት',
      });

  String get onboardingStep2Bullet3 => _localizedValue({
        'en': 'Read the lyrics',
        'am': 'ግጥሙን ማንበብ',
      });

  String get onboardingStep3Title => _localizedValue({
        'en': 'Find with the index',
        'am': 'በማውጫ ይፈልጉ',
      });

  String get onboardingStep3Description => _localizedValue({
        'en':
            'The index shows hymns by number or by title. You can also search by title, English title or a word from the lyrics.',
        'am':
            'ማውጫ መዝሙሮችን በቁጥር ወይም በርዕስ ቅደም ተከተል ያሳያል። በተጨማሪም በፍለጋ ሳጥኑ ውስጥ በርዕስ፣ በእንግሊዝኛ ርዕስ ወይም በግጥም ቃላት መፈለግ ይችላሉ።',
      });

  String get onboardingStep3Access => _localizedValue({
        'en':
            'Tap "Index" at the bottom. Tap the search icon to search, or the sort button to reorder by number or by title.',
        'am':
            'ከታች “ማውጫ”ን ይንኩ። የፍለጋ ምልክቱን በመንካት መፈለግ፣ ወይም የአደራደር አዝራሩን በመንካት በቁጥር አሊያም በርዕስ ቅደም ተከተል ማስተካከል ይችላሉ።',
      });

  String get onboardingStep3Bullet1 => _localizedValue({
        'en': 'By title',
        'am': 'በርዕስ',
      });

  String get onboardingStep3Bullet2 => _localizedValue({
        'en': 'By lyrics',
        'am': 'በግጥም',
      });

  String get onboardingStep3Bullet3 => _localizedValue({
        'en': 'By number or letter',
        'am': 'በቁጥር ወይም በፊደል',
      });

  String get onboardingStep4Title => _localizedValue({
        'en': 'Find by category',
        'am': 'በምድብ ያግኙ',
      });

  String get onboardingStep4Description => _localizedValue({
        'en':
            'Categories group hymns by theme — such as praise, prayer, Sabbath, marriage and hope.',
        'am':
            'ምድቦች መዝሙሮችን እንደ ምስጋና፣ ጸሎት፣ ሰንበት፣ ጋብቻ እና ተስፋ በርዕሰ ጉዳይ ያደራጃሉ።',
      });

  String get onboardingStep4Access => _localizedValue({
        'en':
            'Tap "Categories" at the bottom and pick the category you want; the hymns inside it are then listed.',
        'am':
            'ከታች “ምድብ”ን ይንኩና የሚፈልጉትን ምድብ ይምረጡ፤ ከዚያም በምድቡ ሥር የተካተቱት መዝሙሮች ይዘረዘራሉ።',
      });

  String get onboardingStep5Title => _localizedValue({
        'en': 'Lyrics, audio and sheet music',
        'am': 'ግጥም፣ ድምፅ እና ኖታ',
      });

  String get onboardingStep5Description => _localizedValue({
        'en':
            'The hymn page shows its number, its Amharic and English titles, and the full lyrics. When audio is available you can play it here; when sheet music is available you can open it full-screen.',
        'am':
            'የመዝሙሩ ገጽ ቁጥሩን፣ የአማርኛና የእንግሊዝኛ ርዕሱን እንዲሁም ሙሉ ግጥሙን ያሳያል። ድምፅ ሲኖረው ከዚያው ማጫወት፣ የሙዚቃ ኖታ ሲኖረውም በሙሉ ገጽ መክፈት ይችላሉ።',
      });

  String get onboardingStep5Access => _localizedValue({
        'en':
            'From any hymn list, tap the hymn you want. Tap the heart to add it to favourites; tap the sheet-music icon to open the notation.',
        'am':
            'ከማንኛውም የመዝሙር ዝርዝር ውስጥ የሚፈልጉትን መዝሙር ይንኩ። የልብ ምልክቱን በመንካት ወደ ተወዳጅ መዝሙሮች ማከል፣ የኖታ ምልክቱን በመንካት ደግሞ ኖታውን መክፈት ይችላሉ።',
      });

  String get onboardingStep5Bullet1 => _localizedValue({
        'en': 'Read lyrics',
        'am': 'ግጥም ማንበብ',
      });

  String get onboardingStep5Bullet2 => _localizedValue({
        'en': 'Play audio',
        'am': 'ድምፅ መጫወት',
      });

  String get onboardingStep5Bullet3 => _localizedValue({
        'en': 'Open sheet music',
        'am': 'ኖታ መክፈት',
      });

  String get onboardingStep6Title => _localizedValue({
        'en': 'Adjust settings',
        'am': 'ቅንብሮችን ያስተካክሉ',
      });

  String get onboardingStep6Description => _localizedValue({
        'en':
            'The Settings page has the hymnal collection, font size, background image, keep-screen-on switch, donation link and bug report.',
        'am':
            'ከቅንብሮች ገጽ የመዝሙር ስብስብን፣ የፊደል መጠንን፣ የጀርባ ምስልን፣ ማያ እንዳይጠፋ ማድረግን፣ የልገሳ ድጋፍን እና የስህተት ጥቆማን ያገኛሉ።',
      });

  String get onboardingStep6Access => _localizedValue({
        'en':
            'Tap "Settings" at the bottom. Use the collection selector to switch between the 2004, 1975 or 1961 Wudase or the Hagerigna hymnal.',
        'am':
            'ከታች “ቅንብሮች”ን ይንኩ። የ2004፣ የ1975 ወይም የ1961 ውዳሴ መዝሙርን አሊያም የሀገርኛ መዝሙር ስብስብን ለመቀየር የስብስብ ምርጫውን ይጠቀሙ።',
      });

  String get onboardingStep6Bullet1 => _localizedValue({
        'en': 'Hymnal collection',
        'am': 'የመዝሙር ስብስብ',
      });

  String get onboardingStep6Bullet2 => _localizedValue({
        'en': 'Font size',
        'am': 'የፊደል መጠን',
      });

  String get onboardingStep6Bullet3 => _localizedValue({
        'en': 'Bug report',
        'am': 'የስህተት ጥቆማ',
      });

  // Preview labels (used in onboarding previews)
  String get previewOpenByNumber => _localizedValue({
        'en': 'Open by number',
        'am': 'በቁጥር መክፈት',
      });

  String get previewSearchIndex => _localizedValue({
        'en': 'Search the index',
        'am': 'በማውጫ መፈለግ',
      });

  String get previewByTitleOrLyrics => _localizedValue({
        'en': 'By title or word from lyrics',
        'am': 'በርዕስ ወይም በግጥም ቃላት',
      });

  String get previewNumberHint => _localizedValue({
        'en': 'Enter the number and tap "Open"',
        'am': 'ቁጥሩን አስገብተው “ክፈት”ን ይንኩ',
      });

  String get previewOpen => _localizedValue({
        'en': 'Open',
        'am': 'ክፈት',
      });

  String get previewCategories => _localizedValue({
        'en': 'Categories',
        'am': 'ምድቦች',
      });

  String get previewSampleLyrics => _localizedValue({
        'en':
            'Praise our God,\nHonour be to Him,\n...',
        'am': 'አምላካችን አመስግኑ\nምስጋና ለእርሱ ይሁን\n...',
      });

  String get previewMediaAudio => _localizedValue({
        'en': 'Audio',
        'am': 'ድምፅ',
      });

  String get previewMediaSheet => _localizedValue({
        'en': 'Sheet music',
        'am': 'ኖታ',
      });

  String get previewSettingHymnalCollection => _localizedValue({
        'en': 'Hymnal collection',
        'am': 'የመዝሙር ስብስብ',
      });

  String get previewSettingFontSize => _localizedValue({
        'en': 'Font size',
        'am': 'የፊደል መጠን',
      });

  String get previewSettingBugReport => _localizedValue({
        'en': 'Report bug',
        'am': 'የስህተት ጥቆማ',
      });

  // Offline downloads
  String get downloadAllSheetsTitle => _localizedValue({
        'en': 'Download all sheet music',
        'am': 'ኖታዎችን በሙሉ አውርድ',
      });

  String get downloadAllSheetsDescription => _localizedValue({
        'en': 'For opening the hymnals\' sheet music without internet',
        'am': 'የመዝሙር መጻሕፍትን ኖታዎች ያለ ኢንተርኔት ለመክፈት',
      });

  String get downloadAllAudiosTitle => _localizedValue({
        'en': 'Download all audios',
        'am': 'ድምፆችን በሙሉ አውርድ',
      });

  String get downloadAllAudiosDescription => _localizedValue({
        'en': 'For listening to the hymnals without internet',
        'am': 'የመዝሙር መጻሕፍትን ድምፆች ያለ ኢንተርኔት ለማዳመጥ',
      });

  String get downloadSheetsConfirmTitle => _localizedValue({
        'en': 'Download all sheet music?',
        'am': 'ሁሉም ኖታዎች ይውረዱ?',
      });

  String get downloadAudiosConfirmTitle => _localizedValue({
        'en': 'Download all audios?',
        'am': 'ሁሉም ድምፆች ይውረዱ?',
      });

  String get downloadUnitPages => _localizedValue({
        'en': 'pages',
        'am': 'ገጾች',
      });

  String get downloadUnitAudios => _localizedValue({
        'en': 'audios',
        'am': 'ድምፆች',
      });

  String get downloadSheetsBenefit => _localizedValue({
        'en': 'Once downloaded, you can open the sheet music without internet.',
        'am': 'ከወረዱ በኋላ ኖታዎቹን ያለ ኢንተርኔት መክፈት ይችላሉ።',
      });

  String get downloadAudiosBenefit => _localizedValue({
        'en': 'Once downloaded, you can listen to the hymns without internet.',
        'am': 'ከወረዱ በኋላ መዝሙሮቹን ያለ ኢንተርኔት ማዳመጥ ይችላሉ።',
      });

  String get downloadWifiRecommended => _localizedValue({
        'en': 'Wi-Fi is recommended.',
        'am': 'Wi-Fi መጠቀም ይመከራል።',
      });

  String get downloadSheetsNone => _localizedValue({
        'en': 'This hymnal has no sheet music.',
        'am': 'ይህ የመዝሙር መጽሐፍ ኖታ የለውም።',
      });

  String get downloadAudiosNone => _localizedValue({
        'en': 'This hymnal has no audio.',
        'am': 'ይህ የመዝሙር መጽሐፍ ድምፅ የለውም።',
      });

  String get downloadSheetsNoneAll => _localizedValue({
        'en': 'These hymnals have no sheet music.',
        'am': 'እነዚህ የመዝሙር መጻሕፍት ኖታ የላቸውም።',
      });

  String get downloadAudiosNoneAll => _localizedValue({
        'en': 'These hymnals have no audio.',
        'am': 'እነዚህ የመዝሙር መጻሕፍት ድምፅ የላቸውም።',
      });

  String get downloadSheetsAllPresent => _localizedValue({
        'en': 'All sheet music is on your device.',
        'am': 'ሁሉም ኖታዎች በመሣሪያዎ ላይ አሉ።',
      });

  String get downloadAudiosAllPresent => _localizedValue({
        'en': 'All audio is on your device.',
        'am': 'ሁሉም ድምፆች በመሣሪያዎ ላይ አሉ።',
      });

  String get downloadSheetsStarted => _localizedValue({
        'en': 'Downloading sheet music. You can keep using the app.',
        'am': 'ኖታዎች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
      });

  String get downloadAudiosStarted => _localizedValue({
        'en': 'Downloading audio. You can keep using the app.',
        'am': 'ድምፆች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
      });

  String get downloadSheetsFinished => _localizedValue({
        'en': 'All sheet music has been downloaded.',
        'am': 'ሁሉም ኖታዎች ወርደዋል።',
      });

  String get downloadAudiosFinished => _localizedValue({
        'en': 'All audio has been downloaded.',
        'am': 'ሁሉም ድምፆች ወርደዋል።',
      });

  String downloadSheetsStopped(int saved) => _localizedValue({
        'en': 'Download stopped. $saved pages saved.',
        'am': 'ማውረድ ቆሟል። $saved ገጾች ተቀምጠዋል።',
      });

  String downloadAudiosStopped(int saved) => _localizedValue({
        'en': 'Download stopped. $saved audios saved.',
        'am': 'ማውረድ ቆሟል። $saved ድምፆች ተቀምጠዋል።',
      });

  String downloadSheetsFailed(int count) => _localizedValue({
        'en':
            'Could not download $count pages. Trying again will only fetch the ones that are still missing.',
        'am': '$count ገጾችን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።',
      });

  String downloadAudiosFailed(int count) => _localizedValue({
        'en':
            'Could not download $count audios. Trying again will only fetch the ones that are still missing.',
        'am': '$count ድምፆችን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።',
      });

  String downloadSheetsUpdated(int count) => _localizedValue({
        'en': '$count new pages downloaded.',
        'am': '$count አዲስ ገጾች ወርደዋል።',
      });

  String downloadAudiosUpdated(int count) => _localizedValue({
        'en': '$count new audios downloaded.',
        'am': '$count አዲስ ድምፆች ወርደዋል።',
      });

  String downloadAllDone(int itemCount, String unit, String size) =>
      _localizedValue({
        'en': 'All downloaded · $itemCount $unit · $size',
        'am': 'ሁሉም ወርደዋል · $itemCount $unit · $size',
      });

  String downloadUpdatesAvailable(int count, String unit, String size) =>
      _localizedValue({
        'en': '$count new $unit to download · $size',
        'am': '$count አዲስ $unit ለማውረድ · $size',
      });

  String get downloadListUnavailable => _localizedValue({
        'en': 'Could not get the list of hymns.',
        'am': 'የመዝሙሮቹን ዝርዝር ማግኘት አልተቻለም።',
      });

  String get downloadNeedInternet => _localizedValue({
        'en':
            'An internet connection is needed to download. Please try again later.',
        'am': 'ለማውረድ መጀመሪያ የኢንተርኔት ግንኙነት ያስፈልጋል። እባክዎ ቆይተው እንደገና ይሞክሩ።',
      });

  String downloadConfirmBodyAll(int items, String unit, String size,
          String benefit) =>
      _localizedValue({
        'en': 'All hymnals: $items $unit, $size.\n\n$benefit Wi-Fi is recommended.',
        'am': 'ሁሉም መዝሙር መጻሕፍት፦ $items $unit፣ $size።\n\n$benefit Wi-Fi መጠቀም ይመከራል።',
      });

  String downloadConfirmBodySingle(String hymnalLabel, int items, String unit,
          String size, String benefit) =>
      _localizedValue({
        'en': '$hymnalLabel: $items $unit, $size.\n\n$benefit Wi-Fi is recommended.',
        'am': '$hymnalLabel፦ $items $unit፣ $size።\n\n$benefit Wi-Fi መጠቀም ይመከራል።',
      });

  String get downloadCancel => _localizedValue({
        'en': 'Cancel',
        'am': 'ይቅር',
      });

  String get downloadStart => _localizedValue({
        'en': 'Download',
        'am': 'አውርድ',
      });

  String get downloadWaiting => _localizedValue({
        'en': 'Waiting',
        'am': 'በመጠባበቅ ላይ',
      });

  String get downloadChecking => _localizedValue({
        'en': 'Checking what is already downloaded…',
        'am': 'የተቀመጡትን በማጣራት ላይ…',
      });

  String get downloadOfferTitle => _localizedValue({
        'en': 'Download for offline use',
        'am': 'ያለ ኢንተርኔት ለመጠቀም ማውረድ',
      });

  String downloadOfferBody(String hymnalLabel) => _localizedValue({
        'en': 'What should be downloaded for offline use of $hymnalLabel?',
        'am': '${hymnalLabel}ን ያለ ኢንተርኔት ለመጠቀም ምን ይውረድ?',
      });

  String get downloadOfferHintLater => _localizedValue({
        'en': 'Wi-Fi is recommended. You can also download later from Settings.',
        'am': 'Wi-Fi መጠቀም ይመከራል። በኋላም ከቅንብሮች ማውረድ ይችላሉ።',
      });

  String get downloadOfferLater => _localizedValue({
        'en': 'Later',
        'am': 'በኋላ',
      });

  String get downloadOfferAudios => _localizedValue({
        'en': 'Audios',
        'am': 'ድምፆች',
      });

  String get downloadOfferSheets => _localizedValue({
        'en': 'Sheet music',
        'am': 'ኖታዎች',
      });

  // Main navigation & tabs
  String get navCategoriesTab => _localizedValue({
        'en': 'Categories',
        'am': 'ምድብ',
      });

  String get navIndexTab => _localizedValue({
        'en': 'Index',
        'am': 'ማውጫ',
      });

  String get navNumberTab => _localizedValue({
        'en': 'Number',
        'am': 'ቁጥር',
      });

  String get navFavouritesTab => _localizedValue({
        'en': 'Favourites',
        'am': 'ተወዳጅ',
      });

  String get navSettingsTab => _localizedValue({
        'en': 'Settings',
        'am': 'ቅንብሮች',
      });

  // Settings page fallbacks
  String get contributionLabel => _localizedValue({
        'en': 'Development & contribution',
        'am': 'ልማት እና አስተዋፅዖ',
      });

  String get contributionDescription => _localizedValue({
        'en': 'View source code and contribute',
        'am': 'የምንጭ ኮድ ይመልከቱ እና ይሳተፉ',
      });

  String get donateShortLabel => _localizedValue({
        'en': 'Donate',
        'am': 'ይለግሱ',
      });

  String get donateShortDescription => _localizedValue({
        'en': 'Support the development of this app',
        'am': 'የዚህን መተግበሪያ ልማት ድጋፍ ያድርጉ',
      });

  // Hymnal edition labels in English
  String hymnalLabelEn(String versionId) => _localizedValue({
        'en': _englishHymnalLabelFor(versionId),
        'am': _amharicHymnalLabelFor(versionId),
      });

  static String _englishHymnalLabelFor(String versionId) {
    switch (versionId) {
      case 'sda_new':
        return '2004 Wudase hymnal';
      case 'sda_old':
        return '1975 Wudase hymnal';
      case 'sda_1960':
        return '1961 Wudase hymnal';
      case 'hagerigna':
        return 'Hagerigna hymnal';
      default:
        return versionId;
    }
  }

  static String _amharicHymnalLabelFor(String versionId) {
    switch (versionId) {
      case 'sda_new':
        return 'የ2004 ውዳሴ መዝሙር';
      case 'sda_old':
        return 'የ1975 ውዳሴ መዝሙር';
      case 'sda_1960':
        return 'የ1961 ውዳሴ መዝሙር';
      case 'hagerigna':
        return 'የሀገርኛ መዝሙር';
      default:
        return versionId;
    }
  }

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
