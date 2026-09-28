import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';

/// What a theme's circle shows in the chooser.
///
/// One colour for a theme built on a single idea, two for a theme that
/// pairs a canvas with an accent from another family.
@immutable
class SwatchFill {
  final Color start;
  final Color? end;

  const SwatchFill(this.start, [this.end]);

  bool get isGradient => end != null;

  /// The paint for the circle: a flat fill reads as a gradient of one
  /// colour, so callers need no branch.
  Gradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [start, end ?? start],
      );
}

/// Everything that makes one theme: what it is called, the circle that
/// stands for it, and its two faces.
///
/// A theme used to be spread across three places — a case in [AppPalette]
/// carrying the label, a pair of constants in [AppColorsExtension], and a
/// branch in a lookup that tied them together. Here it is one object, so
/// adding a theme is adding an entry to [AppThemeCatalog.themes] and
/// nothing else.
@immutable
class AppThemeSpec {
  /// The name this theme is stored under. Never renamed: someone has it
  /// saved.
  final AppPalette id;

  /// Shown under the chooser while this theme is the centred one.
  final String label;

  final SwatchFill swatch;

  final AppColorsExtension light;
  final AppColorsExtension dark;

  const AppThemeSpec({
    required this.id,
    required this.label,
    required this.swatch,
    required this.light,
    required this.dark,
  });

  AppColorsExtension colorsFor(Brightness brightness) =>
      brightness == Brightness.light ? light : dark;
}

/// The themes the app offers, in the order the chooser shows them.
///
/// The single source of truth: the chooser walks it, the theme builder
/// reads it, and the contrast tests measure every entry, so a new theme
/// is covered the moment it is listed.
abstract final class AppThemeCatalog {
  static const List<AppThemeSpec> themes = <AppThemeSpec>[
    AppThemeSpec(
      id: AppPalette.emerald,
      label: 'አረንጓዴ',
      swatch: SwatchFill(Color(0xFF4CAF50)),
      light: AppColorsExtension.emeraldLight,
      dark: AppColorsExtension.emeraldDark,
    ),
    AppThemeSpec(
      id: AppPalette.scentaraPink,
      label: 'ሮዝ',
      swatch: SwatchFill(Color(0xFFD2648F)),
      light: AppColorsExtension.scentaraPinkLight,
      dark: AppColorsExtension.scentaraPinkDark,
    ),
    AppThemeSpec(
      id: AppPalette.purplePetal,
      label: 'ወይንጠጅ',
      swatch: SwatchFill(Color(0xFF7E57D6)),
      light: AppColorsExtension.purplePetalLight,
      dark: AppColorsExtension.purplePetalDark,
    ),
    AppThemeSpec(
      id: AppPalette.livoraFinance,
      label: 'ሰማያዊ',
      swatch: SwatchFill(Color(0xFF1E6FD9)),
      light: AppColorsExtension.livoraFinanceLight,
      dark: AppColorsExtension.livoraFinanceDark,
    ),
    AppThemeSpec(
      id: AppPalette.nobleMane,
      label: 'ወርቃማ',
      swatch: SwatchFill(Color(0xFFD9A441)),
      light: AppColorsExtension.nobleManeLight,
      dark: AppColorsExtension.nobleManeDark,
    ),
    AppThemeSpec(
      id: AppPalette.tidalTeal,
      label: 'ቱርኳዝ',
      swatch: SwatchFill(Color(0xFF2FD4C7), Color(0xFF00695F)),
      light: AppColorsExtension.tidalTealLight,
      dark: AppColorsExtension.tidalTealDark,
    ),
    AppThemeSpec(
      id: AppPalette.crimsonEmber,
      label: 'ቀይ',
      swatch: SwatchFill(Color(0xFFF2635F), Color(0xFFB3261E)),
      light: AppColorsExtension.crimsonEmberLight,
      dark: AppColorsExtension.crimsonEmberDark,
    ),
    AppThemeSpec(
      id: AppPalette.neonGraphite,
      label: 'ኒዮን',
      swatch: SwatchFill(Color(0xFF4DFF9F), Color(0xFF23303A)),
      light: AppColorsExtension.neonGraphiteLight,
      dark: AppColorsExtension.neonGraphiteDark,
    ),
    AppThemeSpec(
      id: AppPalette.violetDusk,
      label: 'ሐምራዊ',
      swatch: SwatchFill(Color(0xFFB69CFF), Color(0xFF5B3FBF)),
      light: AppColorsExtension.violetDuskLight,
      dark: AppColorsExtension.violetDuskDark,
    ),
    AppThemeSpec(
      id: AppPalette.terracottaSand,
      label: 'አሸዋ',
      swatch: SwatchFill(Color(0xFFE8935C), Color(0xFFA34A1B)),
      light: AppColorsExtension.terracottaSandLight,
      dark: AppColorsExtension.terracottaSandDark,
    ),
    AppThemeSpec(
      id: AppPalette.indigoAmber,
      label: 'ኢንዲጎ',
      swatch: SwatchFill(Color(0xFFF5B233), Color(0xFF2E3F8F)),
      light: AppColorsExtension.indigoAmberLight,
      dark: AppColorsExtension.indigoAmberDark,
    ),
    AppThemeSpec(
      id: AppPalette.slateMono,
      label: 'ግራጫ',
      swatch: SwatchFill(Color(0xFFA9BCC9), Color(0xFF3C5766)),
      light: AppColorsExtension.slateMonoLight,
      dark: AppColorsExtension.slateMonoDark,
    ),
    AppThemeSpec(
      id: AppPalette.oliveGrove,
      label: 'ወይራ',
      swatch: SwatchFill(Color(0xFFA8D14A), Color(0xFF46660F)),
      light: AppColorsExtension.oliveGroveLight,
      dark: AppColorsExtension.oliveGroveDark,
    ),
    AppThemeSpec(
      id: AppPalette.roseGold,
      label: 'መዳብ',
      swatch: SwatchFill(Color(0xFFE8A598), Color(0xFFA0503C)),
      light: AppColorsExtension.roseGoldLight,
      dark: AppColorsExtension.roseGoldDark,
    ),
    // Last in the row: the one chosen for need rather than taste.
    AppThemeSpec(
      id: AppPalette.highContrast,
      label: 'ንጽጽር',
      swatch: SwatchFill(Color(0xFFFFEB3B), Color(0xFF000000)),
      light: AppColorsExtension.highContrastLight,
      dark: AppColorsExtension.highContrastDark,
    ),
  ];

  /// The app's own green: what an unknown or missing choice falls back to.
  static AppThemeSpec get fallback => themes.first;

  static AppThemeSpec byId(AppPalette id) {
    for (final theme in themes) {
      if (theme.id == id) return theme;
    }
    return fallback;
  }

  /// The theme stored under [name], or [fallback] when the stored one came
  /// from a build that offered more of them.
  static AppThemeSpec byStoredName(String? name) =>
      byId(AppPalette.byName(name));

  /// Where [id] sits in the chooser.
  static int indexOf(AppPalette id) {
    for (var i = 0; i < themes.length; i++) {
      if (themes[i].id == id) return i;
    }
    return 0;
  }

  /// The colours for a theme in one brightness.
  static AppColorsExtension colorsFor(AppPalette id, Brightness brightness) =>
      byId(id).colorsFor(brightness);
}
