import 'package:flutter/material.dart';

/// The colour families the app can wear.
///
/// Only [emerald] is designed so far; it is the app's own dark green look,
/// and the others arrive once their light and dark variants have been drawn
/// and checked on a phone.
enum AppPalette {
  emerald('አረንጓዴ', Color(0xFF4CAF50));

  const AppPalette(this.label, this.swatch);

  /// Shown beside the palette's swatch in Settings.
  final String label;

  /// The single colour that stands for the palette in a chooser.
  final Color swatch;

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
