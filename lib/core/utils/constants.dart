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
  static const String keyHistory = 'hymn_history';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyDataCollectionEnabled = 'data_collection_enabled';
  static const String keyCacheUpdated = 'cache_updated';
  static const String keyZoomScale = 'zoom_scale';

  // Default values
  static const String defaultLanguage = 'am'; // Default to Amharic
  static const String defaultVersion = 'sda_new'; // Default to New SDA Hymnal
  static const String defaultSortType = 'number';
  static const double defaultFontSize = 20.0;
  static const bool defaultKeepScreenOn = false;
  static const bool defaultBackgroundImageEnabled = true;
  static const bool defaultDataCollectionEnabled = true;

  // Zoom scale constants (font scale multipliers)
  static const double minZoomScale = 0.8; // Minimum 0.8x font scale
  static const double maxZoomScale =
      2.0; // Maximum 2.0x font scale (per requirements)
  static const double defaultZoomScale = 1.0;
  static const double scaleSensitivity = 1.0; // Multiplier for responsiveness
  static const Duration animationDurationOnRelease =
      Duration(milliseconds: 200);

  // Font size limits for zoom calculations
  static const double minFontSize = 12.0;
  static const double maxFontSize = 30.0;

  // Sheet music path
  static const String sheetMusicPath = 'D:\\Church\\App\\Amharic_Hymnal_Songs';
}
