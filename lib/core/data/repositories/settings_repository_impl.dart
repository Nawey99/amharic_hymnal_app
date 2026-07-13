// lib/core/data/repositories/settings_repository_impl.dart
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';

/// Implementation of SettingsRepository
///
/// Provides access to app settings through the SettingsService.
/// This is the data layer implementation that bridges the domain layer
/// with the infrastructure layer (SharedPreferences via SettingsService).
class SettingsRepositoryImpl implements SettingsRepository {
  @override
  String getSelectedLanguage() {
    return SettingsService.getSelectedLanguage();
  }

  @override
  Future<bool> setSelectedLanguage(String languageCode) async {
    return await SettingsService.setSelectedLanguage(languageCode);
  }

  @override
  String getSelectedVersion() {
    return SettingsService.getSelectedVersion();
  }

  @override
  Future<bool> setSelectedVersion(String version) async {
    return await SettingsService.setSelectedVersion(version);
  }

  @override
  String getSortType() {
    return SettingsService.getSortType();
  }

  @override
  Future<bool> setSortType(String sortType) async {
    return await SettingsService.setSortType(sortType);
  }

  @override
  double getFontSize() {
    // SettingsService.getFontSize() already clamps, but add extra safety
    return SettingsService.getFontSize().clamp(12.0, 30.0);
  }

  @override
  Future<bool> setFontSize(double fontSize) async {
    // Clamp font size before passing to services to prevent slider assertion errors
    final clampedFontSize = fontSize.clamp(12.0, 30.0);
    // SettingsService.setFontSize() also clamps, but we clamp here for extra safety
    final result = await SettingsService.setFontSize(clampedFontSize);
    // Also update FontSizeService for real-time updates (it also clamps internally)
    await FontSizeService().setFontSize(clampedFontSize);
    return result;
  }

  @override
  bool getKeepScreenOn() {
    return SettingsService.getKeepScreenOn();
  }

  @override
  Future<bool> setKeepScreenOn(bool value) async {
    return await SettingsService.setKeepScreenOn(value);
  }

  @override
  bool getBackgroundImageEnabled() {
    return SettingsService.getBackgroundImageEnabled();
  }

  @override
  Future<bool> setBackgroundImageEnabled(bool value) async {
    return await SettingsService.setBackgroundImageEnabled(value);
  }

  @override
  List<int> getFavoriteHymns() {
    return SettingsService.getFavoriteHymns();
  }

  @override
  List<String> getFavoriteHymnKeys() {
    return SettingsService.getFavoriteHymnKeys();
  }

  @override
  Future<bool> setFavoriteHymns(List<int> hymnNumbers) async {
    return await SettingsService.setFavoriteHymns(hymnNumbers);
  }

  @override
  Future<bool> toggleFavorite(int hymnNumber, {String? version}) async {
    return await SettingsService.toggleFavorite(hymnNumber, version: version);
  }

  @override
  bool isFavorite(int hymnNumber, {String? version}) {
    return SettingsService.isFavorite(hymnNumber, version: version);
  }

  @override
  bool isOnboardingCompleted() {
    return SettingsService.isOnboardingCompleted();
  }

  @override
  Future<bool> setOnboardingCompleted(bool value) async {
    return await SettingsService.setOnboardingCompleted(value);
  }
}
