// lib/core/services/settings_service.dart
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Fix any existing out-of-range font size values in SharedPreferences
    final fontSize = _prefs?.getDouble(AppConstants.keyFontSize);
    if (fontSize != null) {
      final clampedFontSize = fontSize.clamp(12.0, 30.0);
      if ((fontSize - clampedFontSize).abs() > 0.01) {
        // Value was out of range, fix it immediately
        await _prefs?.setDouble(AppConstants.keyFontSize, clampedFontSize);
      }
    }
  }

  // Language
  static String getSelectedLanguage() {
    return _prefs?.getString(AppConstants.keySelectedLanguage) ??
        AppConstants.defaultLanguage;
  }

  static Future<bool> setSelectedLanguage(String languageCode) async {
    return await _prefs?.setString(
            AppConstants.keySelectedLanguage, languageCode) ??
        false;
  }

  // Version
  static String getSelectedVersion() {
    final stored = _prefs?.getString(AppConstants.keySelectedVersion) ??
        AppConstants.defaultVersion;
    return HymnalVersions.normalizeId(stored);
  }

  static Future<bool> setSelectedVersion(String version) async {
    return await _prefs?.setString(
          AppConstants.keySelectedVersion,
          HymnalVersions.normalizeId(version),
        ) ??
        false;
  }

  // Sort Type
  static String getSortType() {
    return _prefs?.getString(AppConstants.keySortType) ??
        AppConstants.defaultSortType;
  }

  static Future<bool> setSortType(String sortType) async {
    return await _prefs?.setString(AppConstants.keySortType, sortType) ?? false;
  }

  // Font Size
  // Always clamps to valid range (12.0-30.0) to prevent slider assertion errors
  static double getFontSize() {
    final fontSize = _prefs?.getDouble(AppConstants.keyFontSize) ??
        AppConstants.defaultFontSize;
    // Clamp to valid range to fix any existing out-of-range values
    return fontSize.clamp(12.0, 30.0);
  }

  static Future<bool> setFontSize(double fontSize) async {
    // Clamp to valid range before saving to prevent slider assertion errors
    final clampedFontSize = fontSize.clamp(12.0, 30.0);
    return await _prefs?.setDouble(AppConstants.keyFontSize, clampedFontSize) ??
        false;
  }

  // Keep Screen On
  static bool getKeepScreenOn() {
    return _prefs?.getBool(AppConstants.keyKeepScreenOn) ??
        AppConstants.defaultKeepScreenOn;
  }

  static Future<bool> setKeepScreenOn(bool value) async {
    return await _prefs?.setBool(AppConstants.keyKeepScreenOn, value) ?? false;
  }

  // Background Image Enabled
  static bool getBackgroundImageEnabled() {
    return _prefs?.getBool(AppConstants.keyBackgroundImageEnabled) ??
        AppConstants.defaultBackgroundImageEnabled;
  }

  static Future<bool> setBackgroundImageEnabled(bool value) async {
    return await _prefs?.setBool(
            AppConstants.keyBackgroundImageEnabled, value) ??
        false;
  }

  // Favorites
  static List<int> getFavoriteHymns() {
    final List<String>? favorites =
        _prefs?.getStringList(AppConstants.keyFavoriteHymns);
    if (favorites == null) return [];
    return favorites
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  static Future<bool> setFavoriteHymns(List<int> hymnNumbers) async {
    final List<String> favorites =
        hymnNumbers.map((e) => e.toString()).toList();
    return await _prefs?.setStringList(
            AppConstants.keyFavoriteHymns, favorites) ??
        false;
  }

  static Future<bool> toggleFavorite(int hymnNumber) async {
    final List<int> favorites = getFavoriteHymns();
    if (favorites.contains(hymnNumber)) {
      favorites.remove(hymnNumber);
    } else {
      favorites.add(hymnNumber);
    }
    return await setFavoriteHymns(favorites);
  }

  static bool isFavorite(int hymnNumber) {
    return getFavoriteHymns().contains(hymnNumber);
  }

  // Onboarding
  static bool isOnboardingCompleted() {
    return _prefs?.getBool(AppConstants.keyOnboardingCompleted) ?? false;
  }

  static Future<bool> setOnboardingCompleted(bool value) async {
    return await _prefs?.setBool(AppConstants.keyOnboardingCompleted, value) ??
        false;
  }

  // Data Collection Opt-Out
  static bool isDataCollectionEnabled() {
    return _prefs?.getBool(AppConstants.keyDataCollectionEnabled) ??
        AppConstants.defaultDataCollectionEnabled;
  }

  static Future<bool> setDataCollectionEnabled(bool value) async {
    return await _prefs?.setBool(
            AppConstants.keyDataCollectionEnabled, value) ??
        false;
  }
}
