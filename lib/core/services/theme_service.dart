import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';

/// The chosen look: light or dark, and which colour family.
///
/// A singleton [ChangeNotifier] like [FontSizeService], so the app watches
/// it the same way. Both choices are read straight from settings the moment
/// this is first used, which is after `SettingsService.init()` and before
/// the first frame, so the app never opens in one look and jumps to
/// another.
class ThemeService extends ChangeNotifier {
  static final ThemeService _instance = ThemeService._internal();

  factory ThemeService() => _instance;

  ThemeService._internal() {
    loadPreferences();
  }

  ThemeMode _themeMode = ThemeMode.dark;
  AppPalette _palette = AppPalette.emerald;

  ThemeMode get themeMode => _themeMode;
  AppPalette get palette => _palette;

  /// Reads both choices from storage. Safe to call again; it only tells
  /// listeners when something actually changed.
  void loadPreferences() {
    final storedMode = ThemeModeStorage.fromStorage(
      SettingsService.getThemeMode(),
    );
    final storedPalette = AppPalette.byName(SettingsService.getThemePalette());
    if (storedMode == _themeMode && storedPalette == _palette) return;
    _themeMode = storedMode;
    _palette = storedPalette;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await SettingsService.setThemeMode(mode.storageValue);
  }

  Future<void> setPalette(AppPalette palette) async {
    if (palette == _palette) return;
    _palette = palette;
    notifyListeners();
    await SettingsService.setThemePalette(palette.name);
  }

  @visibleForTesting
  void resetForTesting() {
    _themeMode = ThemeMode.dark;
    _palette = AppPalette.emerald;
  }
}
