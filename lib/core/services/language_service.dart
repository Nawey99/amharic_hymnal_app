import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';

/// The language the app speaks in.
///
/// Not the language of the hymns: that is a separate choice, and a reader
/// may well want an English interface over an Amharic hymnal.
enum AppLanguage {
  amharic('am'),
  english('en'),

  /// Whatever the phone is set to, falling back to Amharic when the phone
  /// speaks neither.
  system('system');

  const AppLanguage(this.storageValue);

  final String storageValue;

  static AppLanguage byStorageValue(String? value) {
    for (final language in values) {
      if (language.storageValue == value) return language;
    }
    return amharic;
  }

  /// What `MaterialApp.locale` should be. Null lets Flutter ask the phone.
  Locale? get locale => switch (this) {
        AppLanguage.amharic => const Locale('am'),
        AppLanguage.english => const Locale('en'),
        AppLanguage.system => null,
      };
}

/// The chosen interface language, read once at startup and watched by the
/// app so a change reaches every screen at once.
class LanguageService extends ChangeNotifier {
  static final LanguageService _instance = LanguageService._internal();

  factory LanguageService() => _instance;

  LanguageService._internal() {
    loadPreferences();
  }

  AppLanguage _language = AppLanguage.amharic;

  AppLanguage get language => _language;

  Locale? get locale => _language.locale;

  /// Safe to call again; it only tells listeners when something changed.
  void loadPreferences() {
    final stored = AppLanguage.byStorageValue(SettingsService.getUiLanguage());
    if (stored == _language) return;
    _language = stored;
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    await SettingsService.setUiLanguage(language.storageValue);
  }

  @visibleForTesting
  void resetForTesting() {
    _language = AppLanguage.amharic;
  }
}
