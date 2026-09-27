import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';

/// The colours a screen actually asks for, carried by the theme so they can
/// change with the palette and with light or dark.
///
/// The names match the [AppColors] constants the app grew up with, so a
/// screen moves over one line at a time, and the glass tokens describe the
/// frosted panels: what tints them, how far they let the background
/// through, and the hairline around them.
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.primaryBackground,
    required this.secondaryBackground,
    required this.surface,
    required this.surfaceLight,
    required this.primaryText,
    required this.secondaryText,
    required this.tertiaryText,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    required this.divider,
    required this.glassTint,
    required this.glassOpacity,
    required this.glassOpacityOverPhoto,
    required this.glassBorder,
    required this.glassShadow,
    required this.scrim,
  });

  final Color primaryBackground;
  final Color secondaryBackground;
  final Color surface;
  final Color surfaceLight;

  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;

  final Color accent;
  final Color accentDark;
  final Color accentLight;

  final Color divider;

  /// What a frosted panel is tinted with before its opacity is applied.
  final Color glassTint;

  /// How solid a plain panel is, and how solid a card over the
  /// photograph is, where it has to hold text against a busy picture.
  /// Both are the values the app has always drawn with.
  final double glassOpacity;
  final double glassOpacityOverPhoto;

  /// The hairline around a panel, and the shadow beneath it.
  final Color glassBorder;
  final Color glassShadow;

  /// Laid over the photograph so text stays readable on it.
  final Color scrim;

  /// The app's own dark green: the same values the constants held, so
  /// moving a screen onto the theme changes nothing on screen.
  static const AppColorsExtension emeraldDark = AppColorsExtension(
    primaryBackground: AppColors.primaryBackground,
    secondaryBackground: AppColors.secondaryBackground,
    surface: AppColors.surface,
    surfaceLight: AppColors.surfaceLight,
    primaryText: AppColors.primaryText,
    secondaryText: AppColors.secondaryText,
    tertiaryText: AppColors.tertiaryText,
    accent: AppColors.accentGreen,
    accentDark: AppColors.accentGreenDark,
    accentLight: AppColors.accentGreenLight,
    divider: AppColors.divider,
    glassTint: AppColors.surface,
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x33000000),
    scrim: Color(0xCC000000),
  );

  /// The palette and brightness a screen should paint in.
  static AppColorsExtension of(AppPalette palette, Brightness brightness) {
    return switch ((palette, brightness)) {
      // Light emerald is drawn in the next phase, with the glass reworked
      // for a pale background; until then dark is what the app wears.
      (AppPalette.emerald, _) => emeraldDark,
    };
  }

  @override
  AppColorsExtension copyWith({
    Color? primaryBackground,
    Color? secondaryBackground,
    Color? surface,
    Color? surfaceLight,
    Color? primaryText,
    Color? secondaryText,
    Color? tertiaryText,
    Color? accent,
    Color? accentDark,
    Color? accentLight,
    Color? divider,
    Color? glassTint,
    double? glassOpacity,
    double? glassOpacityOverPhoto,
    Color? glassBorder,
    Color? glassShadow,
    Color? scrim,
  }) {
    return AppColorsExtension(
      primaryBackground: primaryBackground ?? this.primaryBackground,
      secondaryBackground: secondaryBackground ?? this.secondaryBackground,
      surface: surface ?? this.surface,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      tertiaryText: tertiaryText ?? this.tertiaryText,
      accent: accent ?? this.accent,
      accentDark: accentDark ?? this.accentDark,
      accentLight: accentLight ?? this.accentLight,
      divider: divider ?? this.divider,
      glassTint: glassTint ?? this.glassTint,
      glassOpacity: glassOpacity ?? this.glassOpacity,
      glassOpacityOverPhoto:
          glassOpacityOverPhoto ?? this.glassOpacityOverPhoto,
      glassBorder: glassBorder ?? this.glassBorder,
      glassShadow: glassShadow ?? this.glassShadow,
      scrim: scrim ?? this.scrim,
    );
  }

  /// Lets one palette fade into another rather than snapping.
  @override
  AppColorsExtension lerp(
    covariant ThemeExtension<AppColorsExtension>? other,
    double t,
  ) {
    if (other is! AppColorsExtension) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorsExtension(
      primaryBackground: mix(primaryBackground, other.primaryBackground),
      secondaryBackground: mix(secondaryBackground, other.secondaryBackground),
      surface: mix(surface, other.surface),
      surfaceLight: mix(surfaceLight, other.surfaceLight),
      primaryText: mix(primaryText, other.primaryText),
      secondaryText: mix(secondaryText, other.secondaryText),
      tertiaryText: mix(tertiaryText, other.tertiaryText),
      accent: mix(accent, other.accent),
      accentDark: mix(accentDark, other.accentDark),
      accentLight: mix(accentLight, other.accentLight),
      divider: mix(divider, other.divider),
      glassTint: mix(glassTint, other.glassTint),
      glassOpacity: lerpDouble(glassOpacity, other.glassOpacity, t),
      glassOpacityOverPhoto: lerpDouble(
        glassOpacityOverPhoto,
        other.glassOpacityOverPhoto,
        t,
      ),
      glassBorder: mix(glassBorder, other.glassBorder),
      glassShadow: mix(glassShadow, other.glassShadow),
      scrim: mix(scrim, other.scrim),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// `context.appColors.accent` instead of reaching into the theme by hand.
extension AppColorsContext on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      AppColorsExtension.emeraldDark;
}
