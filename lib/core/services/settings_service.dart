// lib/core/services/settings_service.dart
import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init({double? systemTextScale}) async {
    _prefs = await SharedPreferences.getInstance();

    // Fix any existing out-of-range font size values in SharedPreferences
    final fontSize = _prefs?.getDouble(AppConstants.keyFontSize);
    if (fontSize == null) {
      await _seedFontSizeFromSystem(
        systemTextScale ??
            PlatformDispatcher.instance.textScaleFactor.toDouble(),
      );
      return;
    }
    final clampedFontSize =
        fontSize.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
    if ((fontSize - clampedFontSize).abs() > 0.01) {
      // Value was out of range, fix it immediately
      await _prefs?.setDouble(AppConstants.keyFontSize, clampedFontSize);
    }
  }

  /// On a fresh install the hymn text starts at the size the phone's own
  /// text-size setting implies, rather than at one fixed size. Afterwards
  /// the reader's own choice is what counts.
  static Future<void> _seedFontSizeFromSystem(double systemTextScale) async {
    final scale =
        systemTextScale.isFinite && systemTextScale > 0 ? systemTextScale : 1.0;
    await _prefs?.setDouble(
      AppConstants.keyFontSize,
      (AppConstants.defaultFontSize * scale)
          .clamp(AppConstants.minFontSize, AppConstants.maxFontSize),
    );
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
    return fontSize.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
  }

  static Future<bool> setFontSize(double fontSize) async {
    // Clamp to valid range before saving to prevent slider assertion errors
    final clampedFontSize =
        fontSize.clamp(AppConstants.minFontSize, AppConstants.maxFontSize);
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
    // Favourites saved before they were kept per book are moved into the
    // selected book once, the first time; after that the old list is gone, so
    // it can never leak into another book that has no favourites yet.
    if (_prefs?.getStringList(AppConstants.keyFavoriteHymnsVersioned) == null) {
      final legacy = _legacyFavoriteHymns();
      if (legacy.isNotEmpty) {
        _prefs?.setStringList(
          AppConstants.keyFavoriteHymnsVersioned,
          legacy.map((number) => _favoriteKey(version, number)).toSet().toList()
            ..sort(),
        );
        _prefs?.remove(AppConstants.keyFavoriteHymns);
        return legacy;
      }
    }
    return getFavoriteHymnKeys()
        .where((key) => key.startsWith('$version:'))
        .map((key) => int.tryParse(key.split(':').last) ?? 0)
        .where((e) => e > 0)
        .toList();
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

    await _prefs?.remove(AppConstants.keyFavoriteHymns);
    return await _prefs?.setStringList(
            AppConstants.keyFavoriteHymnsVersioned, merged) ??
        false;
  }

  static Future<bool> toggleFavorite(int hymnNumber, {String? version}) async {
    final selectedVersion = HymnalVersions.normalizeId(
      version ?? getSelectedVersion(),
    );
    final key = _favoriteKey(selectedVersion, hymnNumber);
    getFavoriteHymns(); // Move any old-format favourites first.
    final favorites = getFavoriteHymnKeys().toSet();
    if (favorites.contains(key)) {
      favorites.remove(key);
    } else {
      favorites.add(key);
    }
    final sorted = favorites.toList()..sort();
    // The old number-only list is not kept up to date; it would otherwise be
    // mistaken for favourites of a book that has none yet.
    await _prefs?.remove(AppConstants.keyFavoriteHymns);
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

  /// The chosen light/dark setting: 'system', 'light' or 'dark'. Read
  /// before the first frame, so the app never starts in the wrong one.
  static String getThemeMode() {
    return _prefs?.getString(AppConstants.keyThemeMode) ?? 'dark';
  }

  static Future<bool> setThemeMode(String value) async {
    return await _prefs?.setString(AppConstants.keyThemeMode, value) ?? false;
  }

  /// The chosen colour family, by its enum name.
  static String? getThemePalette() {
    return _prefs?.getString(AppConstants.keyThemePalette);
  }

  static Future<bool> setThemePalette(String value) async {
    return await _prefs?.setString(AppConstants.keyThemePalette, value) ??
        false;
  }

  /// The language the app speaks in, by its stored name: 'am', 'en' or
  /// 'system'. Not the hymns' language, which is chosen separately.
  static String? getUiLanguage() {
    return _prefs?.getString(AppConstants.keyUiLanguage);
  }

  static Future<bool> setUiLanguage(String value) async {
    return await _prefs?.setString(AppConstants.keyUiLanguage, value) ?? false;
  }

  /// Whether the development and contribution section is shown in Settings.
  /// Hidden until the app version is tapped several times.
  static bool isContributionUnlocked() {
    return _prefs?.getBool(AppConstants.keyContributionUnlocked) ?? false;
  }

  static Future<bool> setContributionUnlocked(bool value) async {
    return await _prefs?.setBool(AppConstants.keyContributionUnlocked, value) ??
        false;
  }

  /// Whether the person chose to keep all of [mediaType] for [version] on
  /// the phone, so files added or replaced later are fetched too.
  static bool isMediaKeptOffline(String version, String mediaType) {
    final kept = _prefs?.getStringList(AppConstants.keyMediaKeptOffline);
    return kept?.contains('$version|$mediaType') ?? false;
  }

  static Future<bool> setMediaKeptOffline(
    String version,
    String mediaType,
    bool value,
  ) async {
    final kept = {
      ...?_prefs?.getStringList(AppConstants.keyMediaKeptOffline),
    };
    value
        ? kept.add('$version|$mediaType')
        : kept.remove('$version|$mediaType');
    return await _prefs?.setStringList(
          AppConstants.keyMediaKeptOffline,
          kept.toList()..sort(),
        ) ??
        false;
  }

  /// Whether the offer to download sheet music and audio for offline use is
  /// still to be made. Set when onboarding finishes, cleared once answered.
  static bool isOfflineDownloadOfferPending() {
    return _prefs?.getBool(AppConstants.keyOfflineDownloadOfferPending) ??
        false;
  }

  static Future<bool> setOfflineDownloadOfferPending(bool value) async {
    return await _prefs?.setBool(
          AppConstants.keyOfflineDownloadOfferPending,
          value,
        ) ??
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
