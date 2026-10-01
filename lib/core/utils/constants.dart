// lib/core/utils/constants.dart

class AppConstants {
  // SharedPreferences keys
  static const String keySelectedLanguage = 'selected_language';
  static const String keySelectedVersion = 'selected_version';
  static const String keySortType = 'sort_type';
  static const String keyFontSize = 'font_size';
  static const String keyKeepScreenOn = 'keep_screen_on';
  static const String keyBackgroundImageEnabled = 'background_image_enabled';
  static const String keyFavoriteHymns = 'favorite_hymns';
  static const String keyFavoriteHymnsVersioned = 'favorite_hymns_by_version';
  static const String keyHistory = 'hymn_history';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyMediaKeptOffline = 'media_kept_offline';
  static const String keyContributionUnlocked = 'contribution_unlocked';
  static const String keyThemeMode = 'theme_mode';
  static const String keyThemePalette = 'theme_palette';
  static const String keyUiLanguage = 'ui_language';
  static const String keyOfflineDownloadOfferPending =
      'offline_download_offer_pending';
  static const String keyDataCollectionEnabled = 'data_collection_enabled';
  static const String keyCacheUpdated = 'cache_updated';
  static const String keyZoomScale = 'zoom_scale';

  // Default values
  static const String defaultLanguage = 'am'; // Default to Amharic
  static const String defaultVersion =
      'sda_new'; // Default to the 2004 SDA Hymnal
  static const String defaultSortType = 'number';
  static const double defaultFontSize = 20.0;
  static const bool defaultKeepScreenOn = false;
  static const bool defaultBackgroundImageEnabled = true;
  static const bool defaultDataCollectionEnabled = true;

  // Zoom scale constants (font scale multipliers)
  static const double minZoomScale = 0.85; // Minimum 0.85x font scale
  static const double maxZoomScale =
      1.8; // Maximum 1.8x font scale for readable lyrics
  static const double defaultZoomScale = 1.0;
  static const double scaleSensitivity = 1.0; // Multiplier for responsiveness
  static const Duration animationDurationOnRelease =
      Duration(milliseconds: 200);

  /// The sizes a reader may choose the hymn's words to be.
  ///
  /// Nothing may hardcode these numbers: the slider's divisions and the
  /// height of the settings preview are both derived from them, and a
  /// literal left behind somewhere would silently clamp a reader's choice
  /// back to an older maximum.
  static const double minFontSize = 12.0;
  static const double maxFontSize = 40.0;

  /// One division per whole point, so two readers on "17" have the same
  /// text.
  static int get fontSizeDivisions => (maxFontSize - minFontSize).round();

  // Sheet music path
  static const String sheetMusicPath = 'D:\\Church\\App\\Amharic_Hymnal_Songs';
}
