// lib/core/services/settings_service.dart
import 'dart:ui' show PlatformDispatcher;

import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

class SettingsService {
  static SharedPreferences? _prefs;

  static Future<void> init({double? systemTextScale}) async {
    _prefs = await SharedPreferences.getInstance();
    await _migrateFavoritesToSongIds();

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
  // Always clamps to the valid range (AppConstants.minFontSize to
  // maxFontSize) to prevent slider assertion errors
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

  // Favourites, kept by song ID (`am-sda-2004-0132`). The ID names the
  // edition, so each book keeps its own; and it survives a hymn being
  // renumbered, which a number would not.
  static final RegExp _songIdPattern =
      RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,99}$');

  static List<String> getFavoriteSongIds() {
    final stored =
        _prefs?.getStringList(AppConstants.keyFavoriteSongIds) ?? const [];
    return stored.where(_songIdPattern.hasMatch).toSet().toList()..sort();
  }

  static bool isFavoriteSong(String songId) =>
      getFavoriteSongIds().contains(songId);

  static Future<bool> setFavoriteSongIds(Iterable<String> songIds) async {
    final cleaned = songIds.where(_songIdPattern.hasMatch).toSet().toList()
      ..sort();
    return await _prefs?.setStringList(
          AppConstants.keyFavoriteSongIds,
          cleaned,
        ) ??
        false;
  }

  static Future<bool> toggleFavoriteSong(String songId) async {
    final favorites = getFavoriteSongIds().toSet();
    if (!favorites.remove(songId)) favorites.add(songId);
    return setFavoriteSongIds(favorites);
  }

  /// Moves favourites saved by an older version into song IDs, once, at
  /// start-up. `sda_new:132` becomes `am-sda-2004-0132`; the oldest,
  /// number-only list belonged to the selected book. Exact, because every
  /// song was created under the ID its number gives (`HymnalVersions.songId`).
  static Future<void> _migrateFavoritesToSongIds() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final byVersion =
        prefs.getStringList(AppConstants.keyFavoriteHymnsVersioned);
    final numbersOnly = prefs.getStringList(AppConstants.keyFavoriteHymns);
    if (byVersion == null && numbersOnly == null) return;

    final migrated = {...getFavoriteSongIds()};
    final versionedKey = RegExp(r'^([a-z0-9_]+):(\d+)$');
    for (final key in byVersion ?? const <String>[]) {
      final match = versionedKey.firstMatch(key);
      final number = int.tryParse(match?.group(2) ?? '');
      if (match == null || number == null || number <= 0) continue;
      migrated.add(HymnalVersions.songId(match.group(1)!, number));
    }
    final selected = getSelectedVersion();
    for (final value in numbersOnly ?? const <String>[]) {
      final number = int.tryParse(value);
      if (number != null && number > 0) {
        migrated.add(HymnalVersions.songId(selected, number));
      }
    }
    await setFavoriteSongIds(migrated);
    await prefs.remove(AppConstants.keyFavoriteHymnsVersioned);
    await prefs.remove(AppConstants.keyFavoriteHymns);
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

  /// Whole-edition downloads the reader started that have not ended, as
  /// (version, media type). Each is cleared when its download ends, however
  /// it ends, so one still here at start-up was cut off by the app closing.
  static List<(String, String)> getUnfinishedDownloads() => [
        for (final entry
            in _prefs?.getStringList(AppConstants.keyUnfinishedDownloads) ??
                const <String>[])
          if (entry.split('|') case [final version, final mediaType])
            (version, mediaType),
      ];

  static Future<bool> setDownloadUnfinished(
    String version,
    String mediaType,
    bool value,
  ) async {
    final entries = {
      ...?_prefs?.getStringList(AppConstants.keyUnfinishedDownloads),
    };
    value
        ? entries.add('$version|$mediaType')
        : entries.remove('$version|$mediaType');
    return await _prefs?.setStringList(
          AppConstants.keyUnfinishedDownloads,
          entries.toList()..sort(),
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
