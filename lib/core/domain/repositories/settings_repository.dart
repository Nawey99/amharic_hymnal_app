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
  Future<bool> setFavoriteHymns(List<int> hymnNumbers);
  Future<bool> toggleFavorite(int hymnNumber);
  bool isFavorite(int hymnNumber);

  // Onboarding
  bool isOnboardingCompleted();
  Future<bool> setOnboardingCompleted(bool value);
}
