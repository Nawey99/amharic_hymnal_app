import 'package:flutter/material.dart';

/// The name a chosen theme is stored under.
///
/// Only the key: what the theme is called, the circle that stands for it
/// and its two faces belong to its entry in `AppThemeCatalog`. Cases are
/// never renamed, because someone has one of them saved.
enum AppPalette {
  emerald,
  scentaraPink,
  purplePetal,
  livoraFinance,
  nobleMane,
  tidalTeal,
  crimsonEmber,
  neonGraphite,
  violetDusk,
  terracottaSand,
  indigoAmber,
  slateMono,
  oliveGrove,
  roseGold,
  highContrast;

  /// The palette stored under [name], or [emerald] when the stored one is
  /// missing or from a build that offered more of them.
  static AppPalette byName(String? name) {
    for (final palette in values) {
      if (palette.name == name) return palette;
    }
    return emerald;
  }
}

/// The light/dark setting, stored as a short word rather than an index, so
/// adding a mode later cannot renumber what people already chose.
extension ThemeModeStorage on ThemeMode {
  String get storageValue => switch (this) {
        ThemeMode.system => 'system',
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
      };

  static ThemeMode fromStorage(String? value) => switch (value) {
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        _ => ThemeMode.dark,
      };
}
