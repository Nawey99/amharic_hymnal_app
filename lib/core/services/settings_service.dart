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
  static String _favoriteKey(String version, int hymnNumber) {
    return '${HymnalVersions.normalizeId(version)}:$hymnNumber';
  }

  static List<String> getFavoriteHymnKeys() {
    final stored =
        _prefs?.getStringList(AppConstants.keyFavoriteHymnsVersioned) ??
            const <String>[];
    return stored
        .where((item) => RegExp(r'^[a-z0-9_]+:\d+$').hasMatch(item))
        .toSet()
        .toList()
      ..sort();
  }

  static List<int> getFavoriteHymns() {
    final version = getSelectedVersion();
    final versioned = getFavoriteHymnKeys()
        .where((key) => key.startsWith('$version:'))
        .map((key) => int.tryParse(key.split(':').last) ?? 0)
        .where((e) => e > 0)
        .toList();
    if (versioned.isNotEmpty) return versioned;

    final legacy = _legacyFavoriteHymns();
    if (legacy.isNotEmpty) {
      final migrated = legacy.map((number) => _favoriteKey(version, number));
      _prefs?.setStringList(
        AppConstants.keyFavoriteHymnsVersioned,
        migrated.toSet().toList()..sort(),
      );
    }
    return legacy;
  }

  static List<int> _legacyFavoriteHymns() {
    final favorites = _prefs?.getStringList(AppConstants.keyFavoriteHymns);
    if (favorites == null) return [];
    return favorites
        .map((e) => int.tryParse(e) ?? 0)
        .where((e) => e > 0)
        .toList();
  }

  static Future<bool> setFavoriteHymns(List<int> hymnNumbers) async {
    final version = getSelectedVersion();
    final otherVersionFavorites = getFavoriteHymnKeys()
        .where((key) => !key.startsWith('$version:'))
        .toList();
    final currentVersionFavorites = hymnNumbers
        .where((number) => number > 0)
        .map((number) => _favoriteKey(version, number));
    final merged = {
      ...otherVersionFavorites,
      ...currentVersionFavorites,
    }.toList()
      ..sort();

    await _prefs?.setStringList(
      AppConstants.keyFavoriteHymns,
      hymnNumbers.map((e) => e.toString()).toList(),
    );
    return await _prefs?.setStringList(
            AppConstants.keyFavoriteHymnsVersioned, merged) ??
        false;
  }

  static Future<bool> toggleFavorite(int hymnNumber, {String? version}) async {
    final selectedVersion = HymnalVersions.normalizeId(
      version ?? getSelectedVersion(),
    );
    final key = _favoriteKey(selectedVersion, hymnNumber);
    final favorites = getFavoriteHymnKeys().toSet();
    if (favorites.contains(key)) {
      favorites.remove(key);
    } else {
      favorites.add(key);
    }
    final sorted = favorites.toList()..sort();
    await _prefs?.setStringList(
      AppConstants.keyFavoriteHymns,
      sorted
          .where((item) => item.startsWith('${getSelectedVersion()}:'))
          .map((item) => item.split(':').last)
          .toList(),
    );
    return await _prefs?.setStringList(
            AppConstants.keyFavoriteHymnsVersioned, sorted) ??
        false;
  }

  static bool isFavorite(int hymnNumber, {String? version}) {
    final selectedVersion = HymnalVersions.normalizeId(
      version ?? getSelectedVersion(),
    );
    return getFavoriteHymnKeys().contains(_favoriteKey(
      selectedVersion,
      hymnNumber,
    ));
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
