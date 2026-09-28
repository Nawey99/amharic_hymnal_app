// lib/core/domain/repositories/settings_repository.dart
/// Domain repository interface for app settings
/// This abstraction allows the domain layer to be independent of implementation details
abstract class SettingsRepository {
  // Language
  String getSelectedLanguage();
  Future<bool> setSelectedLanguage(String languageCode);

  // Version
  String getSelectedVersion();
  Future<bool> setSelectedVersion(String version);

  // Sort Type
  String getSortType();
  Future<bool> setSortType(String sortType);

  // Font Size
  double getFontSize();
  Future<bool> setFontSize(double fontSize);

  // Keep Screen On
  bool getKeepScreenOn();
  Future<bool> setKeepScreenOn(bool value);

  // Background Image Enabled
  bool getBackgroundImageEnabled();
  Future<bool> setBackgroundImageEnabled(bool value);

  // Favorites
  List<int> getFavoriteHymns();
  List<String> getFavoriteHymnKeys();
  Future<bool> setFavoriteHymns(List<int> hymnNumbers);
  Future<bool> toggleFavorite(int hymnNumber, {String? version});
  bool isFavorite(int hymnNumber, {String? version});

  // Onboarding
  bool isOnboardingCompleted();
  Future<bool> setOnboardingCompleted(bool value);

  // Offline downloads offered after onboarding
  bool isOfflineDownloadOfferPending();
  Future<bool> setOfflineDownloadOfferPending(bool value);

  // The hidden development and contribution section
  bool isContributionUnlocked();
  Future<bool> setContributionUnlocked(bool value);

  // A whole edition's sheet music or audio kept on the phone
  bool isMediaKeptOffline(String version, String mediaType);
  Future<bool> setMediaKeptOffline(
    String version,
    String mediaType,
    bool value,
  );
}
