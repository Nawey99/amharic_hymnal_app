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
        'en': 'Something went wrong. Please try again.',
        'am': 'ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ።',
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

  // The hymn page, and what opens from it: sheet music and audio.
  String get hymnMore => _localizedValue({
        'en': 'More',
        'am': 'ተጨማሪ',
      });

  String get hymnShare => _localizedValue({
        'en': 'Share',
        'am': 'አጋራ',
      });

  String get hymnAddFavorite => _localizedValue({
        'en': 'Add to favourites',
        'am': 'ወደ ተወዳጅ ጨምር',
      });

  String get hymnRemoveFavorite => _localizedValue({
        'en': 'Remove from favourites',
        'am': 'ከተወዳጅ አስወግድ',
      });

  String get hymnNoLyrics => _localizedValue({
        'en': 'No lyrics found',
        'am': 'ግጥም አልተገኘም',
      });

  String hymnNotFoundNumber(int number) => _localizedValue({
        'en': 'Hymn number $number was not found',
        'am': 'መዝሙር ቁጥር $number አልተገኘም',
      });

  String get shareFailed => _localizedValue({
        'en': 'The hymn could not be shared. Please try again.',
        'am': 'መዝሙሩን ማጋራት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  // Other editions, under the hymn.
  String otherEditionsSpoken(String numbers) => _localizedValue({
        'en': 'In other books: $numbers',
        'am': 'በሌሎች መጻሕፍት፦ $numbers',
      });

  String similarHymnsSpoken(String numbers) => _localizedValue({
        'en': 'Similar hymns: $numbers',
        'am': 'ተመሳሳይ መዝሙሮች፦ $numbers',
      });

  String editionNumber(int number) => _localizedValue({
        'en': ' no. $number',
        'am': ' ቁጥር $number',
      });

  /// What separates one item from the next in a spoken or written list.
  String get listSeparator => _localizedValue({
        'en': ', ',
        'am': '፣ ',
      });

  // Sheet music.
  String get sheetOpen => _localizedValue({
        'en': 'Open sheet music',
        'am': 'ኖታ ክፈት',
      });

  String get sheetNotFound => _localizedValue({
        'en': 'No sheet music found',
        'am': 'ኖታ አልተገኘም',
      });

  String get sheetNoneForHymn => _localizedValue({
        'en': 'No sheet music was found for this hymn',
        'am': 'ለዚህ መዝሙር ኖታ አልተገኘም',
      });

  String get sheetImageNotFound => _localizedValue({
        'en': 'The sheet music image was not found',
        'am': 'የኖታ ምስል አልተገኘም',
      });

  String get sheetCannotDownloadHere => _localizedValue({
        'en': 'Sheet music cannot be downloaded on this device',
        'am': 'በዚህ መሣሪያ ላይ ኖታ ማውረድ አይቻልም',
      });

  String get sheetDownloadTitle => _localizedValue({
        'en': 'Download this sheet music?',
        'am': 'ኖታ ይውረድ?',
      });

  String get sheetDownloadBody => _localizedValue({
        'en': 'This sheet music is not saved on your device. Download it '
            'now and you can open it offline afterwards.',
        'am': 'ይህ ኖታ በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ከመስመር ውጭም መክፈት ይችላሉ።',
      });

  String get sheetDownloading => _localizedValue({
        'en': 'Downloading sheet music',
        'am': 'ኖታ በማውረድ ላይ',
      });

  String get sheetDownloadCorrupt => _localizedValue({
        'en': 'The downloaded sheet music is not valid. Please try again.',
        'am': 'የወረደው ኖታ ትክክል አልሆነም። እባክዎ እንደገና ይሞክሩ።',
      });

  String get sheetDownloadFailed => _localizedValue({
        'en': 'The sheet music could not be downloaded. Check your internet.',
        'am': 'ኖታውን ማውረድ አልተቻለም። ኢንተርኔትዎን ያረጋግጡ።',
      });

  String get sheetScreenshotBlocked => _localizedValue({
        'en': 'Screenshots of sheet music are not allowed.',
        'am': 'የኖታ ምስል ማንሳት (ስክሪንሽት) አይፈቀድም።',
      });

  String sheetBorrowedFrom(String edition, String number) => _localizedValue({
        'en': 'This sheet music is taken from $edition$number.',
        'am': 'ይህ ኖታ ከ$edition$number የተወሰደ ነው።',
      });

  String sheetBorrowedNumber(int number) => _localizedValue({
        'en': ' (no. $number)',
        'am': ' (ቁ. $number)',
      });

  String get sheetClose => _localizedValue({
        'en': 'Close',
        'am': 'ዝጋ',
      });

  // Audio.
  String get audioPlay => _localizedValue({
        'en': 'Play',
        'am': 'አጫውት',
      });

  /// For a hymn read from the copy bundled with the app: the server has
  /// not been asked, so the app cannot say there is no audio.
  String get audioNeedsInternet => _localizedValue({
        'en': 'Connect to the internet to check for audio',
        'am': 'ድምፅ መኖሩን ለማወቅ ከኢንተርኔት ጋር ይገናኙ',
      });

  String get audioNotFound => _localizedValue({
        'en': 'No audio found',
        'am': 'ድምፅ አልተገኘም',
      });

  String get audioInstrumentalOnly => _localizedValue({
        'en': 'Instrumental only',
        'am': 'የሙዚቃ መሣሪያ ብቻ',
      });

  String get audioDownloadTitle => _localizedValue({
        'en': 'Download this hymn audio?',
        'am': 'የመዝሙሩ ድምፅ ይውረድ?',
      });

  String get audioDownloadBody => _localizedValue({
        'en': 'This audio is not saved on your device. Download it now and '
            'you can play it without internet afterwards.',
        'am':
            'ይህ የድምፅ መዝሙር በመሣሪያዎ ላይ አልተቀመጠም። አሁን ካወረዱት በኋላ ያለ ኢንተርኔት ማጫወት ይችላሉ።',
      });

  String get audioDownloadCorrupt => _localizedValue({
        'en': 'The downloaded audio is not valid. Please try again.',
        'am': 'የወረደው ድምፅ ትክክል አልሆነም። እባክዎ እንደገና ይሞክሩ።',
      });

  /// The server could not be reached. Also what a phone with a signal but
  /// no working data gets.
  String get noInternet => _localizedValue({
        'en': 'No internet connection. Check your connection and try again.',
        'am': 'የኢንተርኔት ግንኙነት የለም። ግንኙነትዎን አረጋግጠው እንደገና ይሞክሩ።',
      });

  String get audioOpenFailed => _localizedValue({
        'en': 'The audio could not be opened. Please try again.',
        'am': 'ድምፁን መክፈት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  String get audioError => _localizedValue({
        'en': 'The audio could not be played. Please try again.',
        'am': 'ድምፁን ማጫወት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  // Shared words.
  String get actionDownload => _localizedValue({
        'en': 'Download',
        'am': 'አውርድ',
      });

  String get actionCancel => _localizedValue({
        'en': 'Cancel',
        'am': 'ይቅር',
      });

  String get pleaseWait => _localizedValue({
        'en': 'Please wait...',
        'am': 'እባክዎ ይጠብቁ...',
      });

  String mediaSizeLine(String size) => _localizedValue({
        'en': 'Size: $size',
        'am': 'መጠን፦ $size',
      });

  /// The short label on the sheet-music button, and what it says when the
  /// hymn has none.
  String get sheetShort => _localizedValue({
        'en': 'Sheet',
        'am': 'ኖታ',
      });

  String get sheetNone => _localizedValue({
        'en': 'None',
        'am': 'የለም',
      });

  // Keeping a book on the phone: the Settings tiles, their dialogs and
  // the messages they leave behind.
  String get downloadSheetsTitle => _localizedValue({
        'en': 'Download all sheet music',
        'am': 'ኖታዎችን በሙሉ አውርድ',
      });

  String get downloadSheetsDescription => _localizedValue({
        'en': 'To open this book’s sheet music without internet',
        'am': 'የተመረጠውን መጽሐፍ ኖታዎች ያለ ኢንተርኔት ለመክፈት',
      });

  String get downloadSheetsConfirmTitle => _localizedValue({
        'en': 'Download all sheet music?',
        'am': 'ሁሉም ኖታዎች ይውረዱ?',
      });

  String get downloadSheetsUnits => _localizedValue({
        'en': 'pages',
        'am': 'ገጾች',
      });

  String get downloadSheetsBenefit => _localizedValue({
        'en': 'Once downloaded you can open the sheet music without '
            'internet.',
        'am': 'ከወረዱ በኋላ ኖታዎቹን ያለ ኢንተርኔት መክፈት ይችላሉ።',
      });

  String get downloadSheetsNone => _localizedValue({
        'en': 'This hymnal has no sheet music.',
        'am': 'ይህ የመዝሙር መጽሐፍ ኖታ የለውም።',
      });

  String get downloadSheetsAllPresent => _localizedValue({
        'en': 'All the sheet music is already on your device.',
        'am': 'ሁሉም ኖታዎች በመሣሪያዎ ላይ አሉ።',
      });

  String get downloadSheetsStarted => _localizedValue({
        'en': 'Sheet music is downloading. You can keep using the app.',
        'am': 'ኖታዎች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
      });

  String get downloadSheetsFinished => _localizedValue({
        'en': 'All the sheet music has downloaded.',
        'am': 'ሁሉም ኖታዎች ወርደዋል።',
      });

  String get downloadAudiosTitle => _localizedValue({
        'en': 'Download all audio',
        'am': 'ድምፆችን በሙሉ አውርድ',
      });

  String get downloadAudiosDescription => _localizedValue({
        'en': 'To listen to this book without internet',
        'am': 'የተመረጠውን መጽሐፍ መዝሙሮች ያለ ኢንተርኔት ለማዳመጥ',
      });

  String get downloadAudiosConfirmTitle => _localizedValue({
        'en': 'Download all audio?',
        'am': 'ሁሉም ድምፆች ይውረዱ?',
      });

  String get downloadAudiosUnits => _localizedValue({
        'en': 'audio files',
        'am': 'ድምፆች',
      });

  String get downloadAudiosBenefit => _localizedValue({
        'en': 'Once downloaded you can listen without internet.',
        'am': 'ከወረዱ በኋላ መዝሙሮቹን ያለ ኢንተርኔት ማዳመጥ ይችላሉ።',
      });

  String get downloadAudiosNone => _localizedValue({
        'en': 'This hymnal has no audio.',
        'am': 'ይህ የመዝሙር መጽሐፍ ድምፅ የለውም።',
      });

  String get downloadAudiosAllPresent => _localizedValue({
        'en': 'All the audio is already on your device.',
        'am': 'ሁሉም ድምፆች በመሣሪያዎ ላይ አሉ።',
      });

  String get downloadAudiosStarted => _localizedValue({
        'en': 'Audio is downloading. You can keep using the app.',
        'am': 'ድምፆች በመውረድ ላይ ናቸው። መተግበሪያውን መጠቀም ይችላሉ።',
      });

  String get downloadAudiosFinished => _localizedValue({
        'en': 'All the audio has downloaded.',
        'am': 'ሁሉም ድምፆች ወርደዋል።',
      });

  String downloadStopped(int saved, String units) => _localizedValue({
        'en': 'Download stopped. $saved $units were saved.',
        'am': 'ማውረድ ቆሟል። $saved $units ተቀምጠዋል።',
      });

  String downloadFailedSome(int count, String units) => _localizedValue({
        'en': '$count $units could not be downloaded. Trying again fetches '
            'only what is left.',
        'am': '$count $unitsን ማውረድ አልተቻለም። እንደገና ሲሞክሩ የቀሩት ብቻ ይወርዳሉ።',
      });

  String downloadUpdated(int count, String units) => _localizedValue({
        'en': '$count new $units downloaded.',
        'am': '$count አዲስ $units ወርደዋል።',
      });

  String downloadAllDone(int count, String units, String size) =>
      _localizedValue({
        'en': 'All downloaded · $count $units · $size',
        'am': 'ሁሉም ወርደዋል · $count $units · $size',
      });

  String downloadUpdatesAvailable(int count, String units, String size) =>
      _localizedValue({
        'en': '$count new $units to download · $size',
        'am': '$count አዲስ $units ለማውረድ · $size',
      });

  String get downloadListUnavailable => _localizedValue({
        'en': 'The list of hymns could not be fetched.',
        'am': 'የመዝሙሮቹን ዝርዝር ማግኘት አልተቻለም።',
      });

  String get downloadNeedInternet => _localizedValue({
        'en': 'Downloading needs an internet connection first. '
            'Please try again later.',
        'am': 'ለማውረድ መጀመሪያ የኢንተርኔት ግንኙነት ያስፈልጋል። እባክዎ ቆይተው እንደገና ይሞክሩ።',
      });

  String downloadConfirmBody(
    String edition,
    int count,
    String units,
    String size,
    String benefit,
  ) =>
      _localizedValue({
        'en': '$edition: $count $units, $size.\n\n'
            '$benefit Wi-Fi is recommended.',
        'am': '$edition፦ $count $units፣ $size።\n\n'
            '$benefit Wi-Fi መጠቀም ይመከራል።',
      });

  String get downloadQueued => _localizedValue({
        'en': 'Waiting',
        'am': 'በመጠባበቅ ላይ',
      });

  String get downloadOfferTitle => _localizedValue({
        'en': 'Download for offline use',
        'am': 'ያለ ኢንተርኔት ለመጠቀም ማውረድ',
      });

  String downloadOfferBody(String edition) => _localizedValue({
        'en': 'What should be downloaded so you can use $edition without '
            'internet?',
        'am': '$editionን ያለ ኢንተርኔት ለመጠቀም ምን ይውረድ?',
      });

  String get downloadOfferHint => _localizedValue({
        'en': 'Wi-Fi is recommended. You can also download later from '
            'Settings.',
        'am': 'Wi-Fi መጠቀም ይመከራል። በኋላም ከቅንብሮች ማውረድ ይችላሉ።',
      });

  String get downloadLater => _localizedValue({
        'en': 'Later',
        'am': 'በኋላ',
      });

  String get downloadAudiosLabel => _localizedValue({
        'en': 'Audio',
        'am': 'ድምፆች',
      });

  String get downloadSheetsLabel => _localizedValue({
        'en': 'Sheet music',
        'am': 'ኖታዎች',
      });

  // The six pages of onboarding: what the app is, and how to
  // reach each part of it.
  String get onboardAboutTitle => _localizedValue({
        'en': 'About the Wudase app',
        'am': 'ስለ ውዳሴ መተግበሪያ',
      });

  String get onboardAboutBody => _localizedValue({
        'en':
            'Wudase brings the Amharic Adventist and Hagerigna hymns together '
                'in one place, with their words, their sheet music and their '
                'recordings.',
        'am': 'ውዳሴ የአማርኛ አድቬንቲስት እና የሀገርኛ መዝሙሮችን ከነግጥማቸው፣ ከሙዚቃ ኖታና ከድምፃቸው ጋር '
            'በአንድ ቦታ ያቀርባል።',
      });

  String get onboardAboutAccess => _localizedValue({
        'en':
            'The app opens on the Number page. The bar along the bottom moves '
                'you between the pages.',
        'am': 'መተግበሪያው ሲከፈት መጀመሪያ የቁጥር ገጽ ይታያል። ከታች የሚገኘው የማውጫ አሞሌ በገጾች መካከል '
            'ለመዘዋወር ያገለግላል።',
      });

  String get onboardAboutBullet1 => _localizedValue({
        'en': 'Hymn lyrics',
        'am': 'የመዝሙር ግጥሞች',
      });

  String get onboardAboutBullet2 => _localizedValue({
        'en': 'Open by number',
        'am': 'በቁጥር መክፈት',
      });

  String get onboardAboutBullet3 => _localizedValue({
        'en': 'Keep favourites',
        'am': 'ተወዳጆችን መመዝገብ',
      });

  String get onboardNumberTitle => _localizedValue({
        'en': 'Open a hymn by its number',
        'am': 'በቁጥር መዝሙር ይክፈቱ',
      });

  String get onboardNumberBody => _localizedValue({
        'en': 'If you know the number you can go straight to the hymn. If the '
            'number is not in the collection, the app will say so.',
        'am': 'የመዝሙሩን ቁጥር ካወቁ በፍጥነት ወደ ግጥሙ መግባት ይችላሉ። ቁጥሩ በስብስቡ ውስጥ ካልገኘ '
            'መተግበሪያው ያሳውቃል።',
      });

  String get onboardNumberAccess => _localizedValue({
        'en': 'Tap Number below, type the hymn number, then tap Open.',
        'am': 'ከታች “ቁጥር”ን ይንኩ፤ የመዝሙሩን ቁጥር ካስገቡ በኋላ “ክፈት”ን ይጫኑ።',
      });

  String get onboardNumberBullet1 => _localizedValue({
        'en': 'Search by number',
        'am': 'በቁጥር መፈለግ',
      });

  String get onboardNumberBullet2 => _localizedValue({
        'en': 'Open it directly',
        'am': 'በቀጥታ መክፈት',
      });

  String get onboardNumberBullet3 => _localizedValue({
        'en': 'Read the words',
        'am': 'ግጥሙን ማንበብ',
      });

  String get onboardIndexTitle => _localizedValue({
        'en': 'Look through the index',
        'am': 'በማውጫ ይፈልጉ',
      });

  String get onboardIndexBody => _localizedValue({
        'en': 'The index lists the hymns by number or by title. You can also '
            'search by title, by English title, or by words in the lyrics.',
        'am': 'ማውጫ መዝሙሮችን በቁጥር ወይም በርዕስ ቅደም ተከተል ያሳያል። በተጨማሪም በፍለጋ ሳጥኑ ውስጥ '
            'በርዕስ፣ በእንግሊዝኛ ርዕስ ወይም በግጥም ቃላት መፈለግ ይችላሉ።',
      });

  String get onboardIndexAccess => _localizedValue({
        'en': 'Tap Index below. Use the search icon to search, or the sort '
            'button to order the list by number or by title.',
        'am': 'ከታች “ማውጫ”ን ይንኩ። የፍለጋ ምልክቱን በመንካት መፈለግ፣ ወይም የአደራደር አዝራሩን በመንካት '
            'በቁጥር አሊያም በርዕስ ቅደም ተከተል ማስተካከል ይችላሉ።',
      });

  String get onboardIndexBullet1 => _localizedValue({
        'en': 'By title',
        'am': 'በርዕስ',
      });

  String get onboardIndexBullet2 => _localizedValue({
        'en': 'By lyrics',
        'am': 'በግጥም',
      });

  String get onboardIndexBullet3 => _localizedValue({
        'en': 'By number or letter',
        'am': 'በቁጥር ወይም በፊደል',
      });

  String get onboardCategoryTitle => _localizedValue({
        'en': 'Find hymns by category',
        'am': 'በምድብ ያግኙ',
      });

  String get onboardCategoryBody => _localizedValue({
        'en': 'Categories group the hymns by subject, such as praise, prayer, '
            'Sabbath, marriage and hope.',
        'am': 'ምድቦች መዝሙሮችን እንደ ምስጋና፣ ጸሎት፣ ሰንበት፣ ጋብቻ እና ተስፋ በርዕሰ ጉዳይ ያደራጃሉ።',
      });

  String get onboardCategoryAccess => _localizedValue({
        'en':
            'Tap Categories below and choose one; the hymns it holds are then '
                'listed.',
        'am': 'ከታች “ምድብ”ን ይንኩና የሚፈልጉትን ምድብ ይምረጡ፤ ከዚያም በምድቡ ሥር የተካተቱት መዝሙሮች '
            'ይዘረዘራሉ።',
      });

  String get onboardCategoryBullet1 => _localizedValue({
        'en': 'Praise',
        'am': 'ምስጋና',
      });

  String get onboardCategoryBullet2 => _localizedValue({
        'en': 'Prayer',
        'am': 'ጸሎት',
      });

  String get onboardCategoryBullet3 => _localizedValue({
        'en': 'Marriage',
        'am': 'ጋብቻ',
      });

  String get onboardHymnTitle => _localizedValue({
        'en': 'Words, audio and sheet music',
        'am': 'ግጥም፣ ድምፅ እና ኖታ',
      });

  String get onboardHymnBody => _localizedValue({
        'en': 'The hymn page shows its number, its Amharic and English titles '
            'and the full words. Where there is a recording you can play it '
            'there, and where there is sheet music you can open it full '
            'screen.',
        'am': 'የመዝሙሩ ገጽ ቁጥሩን፣ የአማርኛና የእንግሊዝኛ ርዕሱን እንዲሁም ሙሉ ግጥሙን ያሳያል። ድምፅ ሲኖረው '
            'ከዚያው ማጫወት፣ የሙዚቃ ኖታ ሲኖረውም በሙሉ ገጽ መክፈት ይችላሉ።',
      });

  String get onboardHymnAccess => _localizedValue({
        'en': 'Tap any hymn in any list. The heart adds it to your favourites, '
            'and the sheet music icon opens the music.',
        'am': 'ከማንኛውም የመዝሙር ዝርዝር ውስጥ የሚፈልጉትን መዝሙር ይንኩ። የልብ ምልክቱን በመንካት ወደ ተወዳጅ '
            'መዝሙሮች ማከል፣ የኖታ ምልክቱን በመንካት ደግሞ ኖታውን መክፈት ይችላሉ።',
      });

  String get onboardHymnBullet1 => _localizedValue({
        'en': 'Read the words',
        'am': 'ግጥም ማንበብ',
      });

  String get onboardHymnBullet2 => _localizedValue({
        'en': 'Play the audio',
        'am': 'ድምፅ መጫወት',
      });

  String get onboardHymnBullet3 => _localizedValue({
        'en': 'Open the sheet music',
        'am': 'ኖታ መክፈት',
      });

  String get onboardSettingsTitle => _localizedValue({
        'en': 'Make it yours in Settings',
        'am': 'ቅንብሮችን ያስተካክሉ',
      });

  String get onboardSettingsBody => _localizedValue({
        'en': 'Settings holds the hymnal collection, the text size, the '
            'background image, keeping the screen awake, supporting the app, '
            'and reporting a problem.',
        'am': 'ከቅንብሮች ገጽ የመዝሙር ስብስብን፣ የፊደል መጠንን፣ የጀርባ ምስልን፣ ማያ እንዳይጠፋ ማድረግን፣ '
            'የልገሳ ድጋፍን እና የስህተት ጥቆማን ያገኛሉ።',
      });

  String get onboardSettingsAccess => _localizedValue({
        'en': 'Tap Settings below. Use the collection picker to move between '
            'the 2004, 1975 and 1961 Wudase hymnals and the Hagerigna songs.',
        'am': 'ከታች “ቅንብሮች”ን ይንኩ። የ2004፣ የ1975 ወይም የ1961 ውዳሴ መዝሙርን አሊያም የሀገርኛ '
            'መዝሙር ስብስብን ለመቀየር የስብስብ ምርጫውን ይጠቀሙ።',
      });

  String get onboardSettingsBullet1 => _localizedValue({
        'en': 'Hymnal collection',
        'am': 'የመዝሙር ስብስብ',
      });

  String get onboardSettingsBullet2 => _localizedValue({
        'en': 'Text size',
        'am': 'የፊደል መጠን',
      });

  String get onboardSettingsBullet3 => _localizedValue({
        'en': 'Report a problem',
        'am': 'የስህተት ጥቆማ',
      });

  // Onboarding chrome, and the little mock screens it shows.
  String get onboardSkip => _localizedValue({
        'en': 'Skip',
        'am': 'ዝለል',
      });

  String get onboardNext => _localizedValue({
        'en': 'Next',
        'am': 'ቀጣይ',
      });

  String get onboardStart => _localizedValue({
        'en': 'Start',
        'am': 'ጀምር',
      });

  String get onboardPreviewByNumber => _localizedValue({
        'en': 'Open by number',
        'am': 'በቁጥር መክፈት',
      });

  String get onboardPreviewByNumberHint => _localizedValue({
        'en': 'Type the number and tap Open',
        'am': 'ቁጥሩን አስገብተው “ክፈት”ን ይንኩ',
      });

  String get onboardPreviewSearch => _localizedValue({
        'en': 'Search the index',
        'am': 'በማውጫ መፈለግ',
      });

  String get onboardPreviewSearchHint => _localizedValue({
        'en': 'By title or by words in the lyrics',
        'am': 'በርዕስ ወይም በግጥም ቃላት',
      });

  String get audioShort => _localizedValue({
        'en': 'Audio',
        'am': 'ድምፅ',
      });

  // Small pieces of chrome shared across the app.
  String get tryAgain => _localizedValue({
        'en': 'Try again',
        'am': 'እንደገና ይሞክሩ',
      });

  String get somethingWentWrong => _localizedValue({
        'en': 'Sorry, something went wrong',
        'am': 'ይቅርታ! የሆነ ችግር ተከስቷል',
      });

  String get clearSearch => _localizedValue({
        'en': 'Clear the search',
        'am': 'ፍለጋውን አጽዳ',
      });

  String get noTitle => _localizedValue({
        'en': 'No title',
        'am': 'ርዕስ የለም',
      });

  String startupFailed(String error) => _localizedValue({
        'en': 'The app could not be started: $error',
        'am': 'መተግበሪያውን ማስጀመር አልተቻለም: $error',
      });

  String get startupFailedShort => _localizedValue({
        'en': 'The app could not be started',
        'am': 'መተግበሪያውን ማስጀመር አልተቻለም',
      });

  // Reporting a problem: the form, its rules and what comes back.
  String get reportSent => _localizedValue({
        'en': 'Your report has been sent. Thank you.',
        'am': 'የስህተት ሪፖርት ተልኳል!',
      });

  String get reportQueued => _localizedValue({
        'en': 'The report is saved. It will be sent when you are online.',
        'am': 'ሪፖርቱ ተቀምጧል። ኢንተርኔት ሲኖር ይላካል።',
      });

  String get reportSendFailed => _localizedValue({
        'en': 'The report could not be sent. Please try again.',
        'am': 'የስህተት ሪፖርት መላክ አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  String get reportTypeLyrics => _localizedValue({
        'en': 'A problem with the words',
        'am': 'የግጥም ስህተት',
      });

  String get reportTypeSheet => _localizedValue({
        'en': 'A problem with the sheet music',
        'am': 'የኖታ ስህተት',
      });

  String get reportTypeAudio => _localizedValue({
        'en': 'A problem with the audio',
        'am': 'የድምፅ ችግር',
      });

  String get reportTypeApp => _localizedValue({
        'en': 'A problem with the app',
        'am': 'የመተግበሪያ ችግር',
      });

  String get reportTypeSuggestion => _localizedValue({
        'en': 'A suggestion',
        'am': 'የማሻሻያ ሐሳብ',
      });

  String get reportTypeOther => _localizedValue({
        'en': 'Something else',
        'am': 'ሌላ',
      });

  String get reportTitleLabel => _localizedValue({
        'en': 'Title',
        'am': 'ርዕስ',
      });

  String get reportTitleSemantic => _localizedValue({
        'en': 'Report title',
        'am': 'የስህተት ሪፖርት ርዕስ',
      });

  String get reportTitleHintShort => _localizedValue({
        'en': 'Enter a title',
        'am': 'ርዕስ ያስገቡ',
      });

  String get reportTitleHint => _localizedValue({
        'en': 'Enter a title for the problem...',
        'am': 'የችግሩን ርዕስ ያስገቡ...',
      });

  String get reportTitleRequired => _localizedValue({
        'en': 'Please enter a title',
        'am': 'እባክዎ ርዕስ ያስገቡ',
      });

  String get reportTitleTooShort => _localizedValue({
        'en': 'The title must be at least 3 characters',
        'am': 'ርዕሱ ቢያንስ 3 ፊደላት መሆን አለበት',
      });

  String get reportEmailLabel => _localizedValue({
        'en': 'Email address (optional)',
        'am': 'የኢሜይል አድራሻ (አማራጭ)',
      });

  String get reportEmailInvalid => _localizedValue({
        'en': 'Please enter a valid email address',
        'am': 'ትክክለኛ ኢሜይል ያስገቡ',
      });

  String get reportDescriptionLabel => _localizedValue({
        'en': 'Description',
        'am': 'መግለጫ',
      });

  String get reportDescriptionSemantic => _localizedValue({
        'en': 'Report description',
        'am': 'የስህተት ሪፖርት መግለጫ',
      });

  String get reportDescriptionHintShort => _localizedValue({
        'en': 'Describe the problem',
        'am': 'ችግሩን በዝርዝር ይግለጹ',
      });

  String get reportDescriptionHint => _localizedValue({
        'en': 'Describe the problem in detail...',
        'am': 'ችግሩን በዝርዝር ይግለጹ...',
      });

  String get reportDescriptionRequired => _localizedValue({
        'en': 'Please enter a description',
        'am': 'እባክዎ መግለጫ ያስገቡ',
      });

  String get reportDescriptionTooShort => _localizedValue({
        'en': 'The description must be at least 10 characters',
        'am': 'መግለጫው ቢያንስ 10 ፊደላት መሆን አለበት',
      });

  String get reportSendSemantic => _localizedValue({
        'en': 'Send the report',
        'am': 'የስህተት ሪፖርት ላክ',
      });

  String get reportSend => _localizedValue({
        'en': 'Send report',
        'am': 'ሪፖርት ላክ',
      });

  String get reportTypeHeading => _localizedValue({
        'en': 'What kind of problem',
        'am': 'የችግሩ ዓይነት',
      });

  String reportAboutHymn(int number, String title) => _localizedValue({
        'en': 'About hymn $number · $title',
        'am': 'ስለ መዝሙር $number · $title',
      });

  // History, category listings and the version footer.
  String get devSectionAlreadyShown => _localizedValue({
        'en': 'The developer section is already showing.',
        'am': 'የልማት ክፍሉ አስቀድሞ ይታያል።',
      });

  String get devSectionShown => _localizedValue({
        'en': 'The developer section is showing now.',
        'am': 'የልማት ክፍሉ አሁን ይታያል።',
      });

  String get devSectionHidden => _localizedValue({
        'en': 'The developer section is hidden.',
        'am': 'የልማት ክፍሉ ተደብቋል።',
      });

  String get noHymnsForSinger => _localizedValue({
        'en': 'No hymns were found for this singer',
        'am': 'ለዚህ ዘማሪ መዝሙር አልተገኘም',
      });

  String get noHymnsInCategory => _localizedValue({
        'en': 'No hymns were found in this category',
        'am': 'በዚህ ምድብ መዝሙር አልተገኘም',
      });

  String get historyEmptyTitle => _localizedValue({
        'en': 'No history yet',
        'am': 'እስካሁን ታሪክ የለም',
      });

  String get historyEmptyForBook => _localizedValue({
        'en': 'No history in this hymnal',
        'am': 'በዚህ የመዝሙር ስብስብ ውስጥ ታሪክ የለም',
      });

  String get historyEmptyMessage => _localizedValue({
        'en': 'The hymns you open will appear here',
        'am': 'የከፈቷቸው መዝሙሮች እዚህ ይታያሉ',
      });

  String get historyClear => _localizedValue({
        'en': 'Clear history',
        'am': 'ታሪክን አጽዳ',
      });

  String get historyClearConfirm => _localizedValue({
        'en': 'Delete the whole history of opened hymns?',
        'am': 'የተከፈቱ መዝሙሮች ታሪክ በሙሉ ይጥፋ?',
      });

  String get actionClear => _localizedValue({
        'en': 'Clear',
        'am': 'አጽዳ',
      });

  String devSectionTapsLeft(int remaining) => _localizedValue({
        'en': 'Tap $remaining more times to show it.',
        'am': 'ለማሳየት $remaining ጊዜ ይንኩ።',
      });

  String appNameWithVersion(String version) => _localizedValue({
        'en': 'Wudase $version',
        'am': 'ውዳሴ $version',
      });

  String appNameWithVersionLong(String version) => _localizedValue({
        'en': 'Wudase · version $version',
        'am': 'ውዳሴ · ስሪት $version',
      });

  // Supporting the app.
  String get donateBody => _localizedValue({
        'en': 'Your support helps us improve this app and keep it going. Thank '
            'you.',
        'am': 'ድጋፍዎ ይህን መተግበሪያ ለማሻሻል እና ለማስቀጠል ይረዳናል። ለድጋፍዎ እናመሰግናለን።',
      });

  String get donateComingSoon => _localizedValue({
        'en': 'Coming soon',
        'am': 'በቅርቡ ይጀምራል',
      });

  String get donateBankTransfer => _localizedValue({
        'en': 'By bank transfer',
        'am': 'በባንክ ማስተላለፊያ',
      });

  String get donateBankDetails => _localizedValue({
        'en': 'Bank transfer details',
        'am': 'የባንክ ማስተላለፊያ መረጃ',
      });

  String get donatePaypalSoon => _localizedValue({
        'en': 'PayPal support will start soon.',
        'am': 'የPayPal ድጋፍ በቅርቡ ይጀምራል።',
      });

  String get donateOk => _localizedValue({
        'en': 'OK',
        'am': 'እሺ',
      });

  String get donateBankLabel => _localizedValue({
        'en': 'Bank',
        'am': 'ባንክ',
      });

  String get donateBankName => _localizedValue({
        'en': 'Commercial Bank of Ethiopia',
        'am': 'የኢትዮጵያ ንግድ ባንክ',
      });

  String get donateAccountNameLabel => _localizedValue({
        'en': 'Account name',
        'am': 'የባንክ ሒሳብ ስም',
      });

  String get donateAccountNumberLabel => _localizedValue({
        'en': 'Account number',
        'am': 'የሒሳብ ቁጥር',
      });

  String get donateAccountNumberPending => _localizedValue({
        'en': 'To be added later',
        'am': 'በኋላ ይጨመራል',
      });

  String get donateNotice => _localizedValue({
        'en':
            'This page is ready to show bank details. The real account number '
                'will be filled in once it is arranged.',
        'am': 'ይህ ገጽ የባንክ ድጋፍ መረጃ ለማሳየት ተዘጋጅቷል። ትክክለኛው የባንክ ሒሳብ ቁጥር ሲዘጋጅ መረጃው '
            'ይሞላል።',
      });

  String get donateCopy => _localizedValue({
        'en': 'Copy',
        'am': 'ቅዳ',
      });

  String get donateCopied => _localizedValue({
        'en': 'The account number has been copied',
        'am': 'የሒሳብ ቁጥሩ ተቀድቷል',
      });

  // Books the app has not been taught the name of: built from the year
  // the server reports.
  String hymnalYearLabel(int year) => _localizedValue({
        'en': '$year Wudase Hymnal',
        'am': 'የ$year ውዳሴ መዝሙር',
      });

  String hymnalYearShortLabel(int year) => _localizedValue({
        'en': '$year Wudase',
        'am': '$year ውዳሴ',
      });

  String get hymnalBeingPrepared => _localizedValue({
        'en': ' (being prepared)',
        'am': ' (በዝግጅት ላይ)',
      });

  /// Names the hymn at the top of a report, for a bundled hymn the server
  /// has no ID for.
  String reportHymnReference(int number, String title, String description) =>
      _localizedValue({
        'en': 'Hymn $number ($title)\n\n$description',
        'am': 'መዝሙር $number ($title)\n\n$description',
      });

  // Why the hymns could not be shown.
  String get errorHymnsLoadFailed => _localizedValue({
        'en': 'Hymns could not be loaded. Please try again.',
        'am': 'መዝሙሮቹን መጫን አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  String get errorNeedsConnection => _localizedValue({
        'en': 'This hymnal needs an internet connection the first time it is '
            'opened. Please connect and try again.',
        'am': 'ይህ የመዝሙር ስብስብ ለመጀመሪያ ጊዜ ሲከፈት የኢንተርኔት ግንኙነት '
            'ያስፈልገዋል። እባክዎ ይገናኙና እንደገና ይሞክሩ።',
      });

  String get errorEditionUnavailable => _localizedValue({
        'en': 'This hymnal is no longer available. Please choose another one '
            'in Settings.',
        'am': 'ይህ የመዝሙር ስብስብ ከአሁን በኋላ አይገኝም። እባክዎ በቅንብሮች ውስጥ '
            'ሌላ ይምረጡ።',
      });

  String get errorSearchFailed => _localizedValue({
        'en': 'Search failed. Please try again.',
        'am': 'ፍለጋው አልተሳካም። እባክዎ እንደገና ይሞክሩ።',
      });

  String errorHymnLookupFailed(int number) => _localizedValue({
        'en': 'Hymn $number could not be opened. Please try again.',
        'am': 'መዝሙር ቁጥር $number መክፈት አልተቻለም። እባክዎ እንደገና ይሞክሩ።',
      });

  // Moving between hymns without swiping, for screen readers.
  String get hymnNext => _localizedValue({
        'en': 'Next hymn',
        'am': 'ቀጣይ መዝሙር',
      });

  String get hymnPrevious => _localizedValue({
        'en': 'Previous hymn',
        'am': 'ያለፈው መዝሙር',
      });

  // Anonymous usage counts.
  String get shareUsageLabel => _localizedValue({
        'en': 'Share anonymous usage counts',
        'am': 'ስም-አልባ የአጠቃቀም ቆጠራ ያጋሩ',
      });

  String get shareUsageDescription => _localizedValue({
        'en': 'Which hymns and categories are opened, with nothing that '
            'identifies you',
        'am': 'የትኞቹ መዝሙሮችና ምድቦች እንደሚከፈቱ ብቻ፤ እርስዎን የሚለይ '
            'ምንም መረጃ የለውም',
      });

  String downloadNotEnoughSpace(String needed, String free) => _localizedValue({
        'en': 'Not enough free space: this needs $needed and the phone has '
            '$free free.',
        'am': 'በቂ ቦታ የለም፦ $needed ያስፈልጋል፤ ስልኩ ላይ ያለው ነጻ ቦታ $free '
            'ብቻ ነው።',
      });

  // The audio notification's channel, as named in the phone's settings.
  String get audioChannelName => _localizedValue({
        'en': 'Hymn playback',
        'am': 'የመዝሙር ማጫወቻ',
      });

  String get audioChannelDescription => _localizedValue({
        'en': 'Controls for the hymn that is playing',
        'am': 'እየተጫወተ ያለውን መዝሙር መቆጣጠሪያ',
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
