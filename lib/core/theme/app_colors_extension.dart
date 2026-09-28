import 'package:flutter/material.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';

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
    required this.barTint,
    required this.barOpacity,
    required this.barBorder,
    required this.raisedAction,
    required this.onAccent,
    required this.veil,
    required this.shade,
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

  /// The floating navigation bar. It sits over anything - a photograph, a
  /// white card, a page of lyrics - so it carries its own fill and edge
  /// rather than the panel's: barely there over a dark app, nearly solid
  /// over a light one, where a faint white pill would vanish.
  final Color barTint;
  final double barOpacity;
  final Color barBorder;

  /// The raised number button. The same green the selected tab uses, so
  /// the two do not sit side by side a shade apart.
  final Color raisedAction;

  /// What is written on the accent: white over a deep colour, near-black
  /// over a pastel or a gold, which is why it cannot be assumed.
  final Color onAccent;

  /// Laid over the photograph so text stays readable on it.
  /// A thin overlay that lifts something off what is behind it: a
  /// hairline, a switch track, the ink of a press. White on a dark
  /// palette, near-black on a light one, so the same alpha reads the same
  /// way in both.
  final Color veil;

  /// The opposite of [veil]: a wash that pushes a panel behind the page.
  /// Black on a dark palette, white on a light one.
  final Color shade;

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
    barTint: AppColors.surface,
    barOpacity: 0.15,
    barBorder: Color(0x3DFFFFFF),
    raisedAction: AppColors.accentGreenDark,
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC000000),
  );

  /// The same green in daylight.
  ///
  /// Not an inversion: the green darkens so it can carry text on white,
  /// and the frost turns heavy and pale, because white glass over a bright
  /// photograph needs body to hold dark text. The hairline flips from a
  /// white highlight to a dark edge, and the shadow softens.
  static const AppColorsExtension emeraldLight = AppColorsExtension(
    primaryBackground: Color(0xFFF7F7F5),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEDEDE9),
    primaryText: Color(0xFF1A1C19),
    secondaryText: Color(0xFF4A4F46),
    tertiaryText: Color(0xFF6B7065),
    accent: Color(0xFF2E7D32),
    accentDark: Color(0xFF1B5E20),
    accentLight: Color(0xFF43A047),
    divider: Color(0xFFDCDCD6),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.55,
    glassOpacityOverPhoto: 0.72,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.86,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF2E7D32),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF1A1C19),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFFFFFF),
  );

  /// Blush paper and a deep rose in daylight; at night a pastel pink that
  /// is too pale to carry white, so it is written on in ink instead.
  static const AppColorsExtension scentaraPinkLight = AppColorsExtension(
    primaryBackground: Color(0xFFFDF7F9),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF3E7EC),
    primaryText: Color(0xFF241419),
    secondaryText: Color(0xFF54404A),
    tertiaryText: Color(0xFF6E5A63),
    accent: Color(0xFFA32B62),
    accentDark: Color(0xFF7D1E4A),
    accentLight: Color(0xFFD2648F),
    divider: Color(0xFFEBD8E0),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.55,
    glassOpacityOverPhoto: 0.72,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.86,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFFA32B62),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF1F1015),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFFF7FA),
  );

  static const AppColorsExtension scentaraPinkDark = AppColorsExtension(
    primaryBackground: Color(0xFF140D11),
    secondaryBackground: Color(0xFF20161B),
    surface: Color(0xFF2A1E24),
    surfaceLight: Color(0xFF3A2A32),
    primaryText: Color(0xFFFDF2F6),
    secondaryText: Color(0xFFDCC2CE),
    tertiaryText: Color(0xFFB99CAA),
    accent: Color(0xFFF2A0BF),
    accentDark: Color(0xFFC4718F),
    accentLight: Color(0xFFFFC2D6),
    divider: Color(0xFF3F2E37),
    glassTint: Color(0xFF2A1E24),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x33000000),
    barTint: Color(0xFF2A1E24),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFFFFF),
    raisedAction: Color(0xFFF2A0BF),
    onAccent: Color(0xFF2A0A18),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC120A0E),
  );

  /// A branding purple: vivid on white, softened to lilac at night.
  static const AppColorsExtension purplePetalLight = AppColorsExtension(
    primaryBackground: Color(0xFFFAF7FE),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEEE8F8),
    primaryText: Color(0xFF1C1626),
    secondaryText: Color(0xFF4A4159),
    tertiaryText: Color(0xFF665C78),
    accent: Color(0xFF6B3FC4),
    accentDark: Color(0xFF512D9B),
    accentLight: Color(0xFF9575E0),
    divider: Color(0xFFE4DCF3),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.55,
    glassOpacityOverPhoto: 0.72,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.86,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF6B3FC4),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF161022),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFAF7FE),
  );

  static const AppColorsExtension purplePetalDark = AppColorsExtension(
    primaryBackground: Color(0xFF110D19),
    secondaryBackground: Color(0xFF1B1526),
    surface: Color(0xFF241C33),
    surfaceLight: Color(0xFF332847),
    primaryText: Color(0xFFF4F0FF),
    secondaryText: Color(0xFFCCC2E2),
    tertiaryText: Color(0xFFA598C2),
    accent: Color(0xFFB79CFF),
    accentDark: Color(0xFF8E73D6),
    accentLight: Color(0xFFD2C1FF),
    divider: Color(0xFF3A2F4F),
    glassTint: Color(0xFF241C33),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x33000000),
    barTint: Color(0xFF241C33),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFFFFF),
    raisedAction: Color(0xFFB79CFF),
    onAccent: Color(0xFF1A1030),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC0E0A16),
  );

  /// Breathable white and a crisp blue, the plainest of the five; at night
  /// it keeps the same coolness against near-black.
  static const AppColorsExtension livoraFinanceLight = AppColorsExtension(
    primaryBackground: Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFEDF1F5),
    primaryText: Color(0xFF0B1620),
    secondaryText: Color(0xFF3B4A57),
    tertiaryText: Color(0xFF5B6B79),
    accent: Color(0xFF0B5FC4),
    accentDark: Color(0xFF07458F),
    accentLight: Color(0xFF4F92E8),
    divider: Color(0xFFE1E7EC),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.6,
    glassOpacityOverPhoto: 0.75,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x12000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.9,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF0B5FC4),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF0F1725),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0xA8FFFFFF),
  );

  static const AppColorsExtension livoraFinanceDark = AppColorsExtension(
    primaryBackground: Color(0xFF080C11),
    secondaryBackground: Color(0xFF111820),
    surface: Color(0xFF17202B),
    surfaceLight: Color(0xFF223040),
    primaryText: Color(0xFFF3F7FB),
    secondaryText: Color(0xFFC4D0DC),
    tertiaryText: Color(0xFF97A6B5),
    accent: Color(0xFF6FB2FF),
    accentDark: Color(0xFF4A8FE0),
    accentLight: Color(0xFF9CCCFF),
    divider: Color(0xFF2A3947),
    glassTint: Color(0xFF17202B),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x33000000),
    barTint: Color(0xFF17202B),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFFFFF),
    raisedAction: Color(0xFF6FB2FF),
    onAccent: Color(0xFF05172B),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC060A0F),
  );

  /// Gold on near-black, the palette this one is really for; in daylight
  /// it becomes warm parchment with a darkened amber that can be read.
  static const AppColorsExtension nobleManeLight = AppColorsExtension(
    primaryBackground: Color(0xFFFBF6EC),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFDF8),
    surfaceLight: Color(0xFFF2E8D6),
    primaryText: Color(0xFF211A0F),
    secondaryText: Color(0xFF4E4330),
    tertiaryText: Color(0xFF6B5E47),
    accent: Color(0xFF8A5A0B),
    accentDark: Color(0xFF6B4507),
    accentLight: Color(0xFFC79A3E),
    divider: Color(0xFFE7DCC7),
    glassTint: Color(0xFFFFFDF8),
    glassOpacity: 0.58,
    glassOpacityOverPhoto: 0.74,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFDF8),
    barOpacity: 0.88,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF8A5A0B),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF1F1808),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFBF6EC),
  );

  static const AppColorsExtension nobleManeDark = AppColorsExtension(
    primaryBackground: Color(0xFF0C0906),
    secondaryBackground: Color(0xFF17120B),
    surface: Color(0xFF1F1811),
    surfaceLight: Color(0xFF2E241A),
    primaryText: Color(0xFFFCF6EA),
    secondaryText: Color(0xFFDCC9A6),
    tertiaryText: Color(0xFFB4A181),
    accent: Color(0xFFE0A32E),
    accentDark: Color(0xFFB07F1E),
    accentLight: Color(0xFFF0C766),
    divider: Color(0xFF3A2E20),
    glassTint: Color(0xFF1F1811),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFE9C2),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF1F1811),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFE9C2),
    raisedAction: Color(0xFFE0A32E),
    onAccent: Color(0xFF1A1204),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC0A0805),
  );

  /// Deep water: a teal canvas under a bright cyan.
  static const AppColorsExtension tidalTealDark = AppColorsExtension(
    primaryBackground: Color(0xFF05100F),
    secondaryBackground: Color(0xFF0C1A18),
    surface: Color(0xFF12211F),
    surfaceLight: Color(0xFF1B2E2B),
    primaryText: Color(0xFFEAF7F5),
    secondaryText: Color(0xFFB8D6D2),
    tertiaryText: Color(0xFF8FB0AC),
    accent: Color(0xFF2FD4C7),
    accentDark: Color(0xFF1FA79C),
    accentLight: Color(0xFF7BE7DD),
    divider: Color(0xFF26403C),
    glassTint: Color(0xFF12211F),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DC9F5EF),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF12211F),
    barOpacity: 0.15,
    barBorder: Color(0x3DC9F5EF),
    raisedAction: Color(0xFF2FD4C7),
    onAccent: Color(0xFF04211E),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC040F0E),
  );

  static const AppColorsExtension tidalTealLight = AppColorsExtension(
    primaryBackground: Color(0xFFF1F9F7),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFDCEFEB),
    primaryText: Color(0xFF0F1F1D),
    secondaryText: Color(0xFF3A5350),
    tertiaryText: Color(0xFF5B7370),
    accent: Color(0xFF00695F),
    accentDark: Color(0xFF004F47),
    accentLight: Color(0xFF2E9187),
    divider: Color(0xFFD2E6E2),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF00695F),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF0F1F1D),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF1F9F7),
  );

  /// Embers: a near-black red that carries a warm coral.
  static const AppColorsExtension crimsonEmberDark = AppColorsExtension(
    primaryBackground: Color(0xFF120506),
    secondaryBackground: Color(0xFF1E090B),
    surface: Color(0xFF260C0F),
    surfaceLight: Color(0xFF351317),
    primaryText: Color(0xFFFCEDEE),
    secondaryText: Color(0xFFE3B9BD),
    tertiaryText: Color(0xFFB98F93),
    accent: Color(0xFFF2635F),
    accentDark: Color(0xFFC4413E),
    accentLight: Color(0xFFFF9C94),
    divider: Color(0xFF43211F),
    glassTint: Color(0xFF260C0F),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFD2CE),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF260C0F),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFD2CE),
    raisedAction: Color(0xFFF2635F),
    onAccent: Color(0xFF2A0606),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC0E0405),
  );

  static const AppColorsExtension crimsonEmberLight = AppColorsExtension(
    primaryBackground: Color(0xFFFFF6F4),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFFAE3DF),
    primaryText: Color(0xFF21100F),
    secondaryText: Color(0xFF573B39),
    tertiaryText: Color(0xFF6F504E),
    accent: Color(0xFFB3261E),
    accentDark: Color(0xFF8C1B15),
    accentLight: Color(0xFFD9544A),
    divider: Color(0xFFF0DAD6),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFFB3261E),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF21100F),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFFF6F4),
  );

  /// Graphite with a neon mint on it: the coldest of the family.
  static const AppColorsExtension neonGraphiteDark = AppColorsExtension(
    primaryBackground: Color(0xFF08090B),
    secondaryBackground: Color(0xFF121417),
    surface: Color(0xFF181B1F),
    surfaceLight: Color(0xFF23272D),
    primaryText: Color(0xFFF2F4F7),
    secondaryText: Color(0xFFC2C8D0),
    tertiaryText: Color(0xFF969DA7),
    accent: Color(0xFF4DFF9F),
    accentDark: Color(0xFF23C976),
    accentLight: Color(0xFF8DFFC5),
    divider: Color(0xFF2C3138),
    glassTint: Color(0xFF181B1F),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DD8FFEA),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF181B1F),
    barOpacity: 0.15,
    barBorder: Color(0x3DD8FFEA),
    raisedAction: Color(0xFF4DFF9F),
    onAccent: Color(0xFF04150C),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC06070A),
  );

  static const AppColorsExtension neonGraphiteLight = AppColorsExtension(
    primaryBackground: Color(0xFFF4F6F8),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE3E8ED),
    primaryText: Color(0xFF12161A),
    secondaryText: Color(0xFF3E464F),
    tertiaryText: Color(0xFF5B646E),
    accent: Color(0xFF00735A),
    accentDark: Color(0xFF005739),
    accentLight: Color(0xFF2FA37B),
    divider: Color(0xFFDDE3E8),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF00735A),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF12161A),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF4F6F8),
  );

  /// Dusk: a charcoal shot through with violet.
  static const AppColorsExtension violetDuskDark = AppColorsExtension(
    primaryBackground: Color(0xFF0A0917),
    secondaryBackground: Color(0xFF131230),
    surface: Color(0xFF1B1A3B),
    surfaceLight: Color(0xFF26264E),
    primaryText: Color(0xFFEEEFFC),
    secondaryText: Color(0xFFC3C6EE),
    tertiaryText: Color(0xFF9699C6),
    accent: Color(0xFF8E99FF),
    accentDark: Color(0xFF6B76E0),
    accentLight: Color(0xFFBFC6FF),
    divider: Color(0xFF2C2D55),
    glassTint: Color(0xFF1B1A3B),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DDCDFFF),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF1B1A3B),
    barOpacity: 0.15,
    barBorder: Color(0x3DDCDFFF),
    raisedAction: Color(0xFF8E99FF),
    onAccent: Color(0xFF0A0C33),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC070714),
  );

  static const AppColorsExtension violetDuskLight = AppColorsExtension(
    primaryBackground: Color(0xFFF5F5FE),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE4E5F8),
    primaryText: Color(0xFF16172B),
    secondaryText: Color(0xFF3E4064),
    tertiaryText: Color(0xFF585A7E),
    accent: Color(0xFF4340C4),
    accentDark: Color(0xFF322F99),
    accentLight: Color(0xFF7573DB),
    divider: Color(0xFFDADBF2),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF4340C4),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF16172B),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF5F5FE),
  );

  /// Sand and fired clay: the warmest of the family.
  static const AppColorsExtension terracottaSandDark = AppColorsExtension(
    primaryBackground: Color(0xFF120B07),
    secondaryBackground: Color(0xFF1E140D),
    surface: Color(0xFF271A12),
    surfaceLight: Color(0xFF35251A),
    primaryText: Color(0xFFFBF0E6),
    secondaryText: Color(0xFFE0C5AB),
    tertiaryText: Color(0xFFB79A81),
    accent: Color(0xFFE8935C),
    accentDark: Color(0xFFBC7040),
    accentLight: Color(0xFFF7B98C),
    divider: Color(0xFF453224),
    glassTint: Color(0xFF271A12),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFDEC4),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF271A12),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFDEC4),
    raisedAction: Color(0xFFE8935C),
    onAccent: Color(0xFF2A1307),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC0E0805),
  );

  static const AppColorsExtension terracottaSandLight = AppColorsExtension(
    primaryBackground: Color(0xFFFDF6EF),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF5E6D6),
    primaryText: Color(0xFF241710),
    secondaryText: Color(0xFF5A4234),
    tertiaryText: Color(0xFF75594A),
    accent: Color(0xFFA34A1B),
    accentDark: Color(0xFF80380F),
    accentLight: Color(0xFFCE7742),
    divider: Color(0xFFEEDCCA),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFFA34A1B),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF241710),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFDF6EF),
  );

  /// Indigo night with a lamp in it: the one pairing opposites.
  static const AppColorsExtension indigoAmberDark = AppColorsExtension(
    primaryBackground: Color(0xFF070A16),
    secondaryBackground: Color(0xFF101627),
    surface: Color(0xFF161D33),
    surfaceLight: Color(0xFF222B45),
    primaryText: Color(0xFFEFF2FB),
    secondaryText: Color(0xFFBFC8E4),
    tertiaryText: Color(0xFF95A0C0),
    accent: Color(0xFFF5B233),
    accentDark: Color(0xFFC88A18),
    accentLight: Color(0xFFFFD37A),
    divider: Color(0xFF2B3450),
    glassTint: Color(0xFF161D33),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DCBD8FF),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF161D33),
    barOpacity: 0.15,
    barBorder: Color(0x3DCBD8FF),
    raisedAction: Color(0xFFF5B233),
    onAccent: Color(0xFF1C1203),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC05070F),
  );

  static const AppColorsExtension indigoAmberLight = AppColorsExtension(
    primaryBackground: Color(0xFFF4F6FC),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE2E7F5),
    primaryText: Color(0xFF12162A),
    secondaryText: Color(0xFF3C4462),
    tertiaryText: Color(0xFF58607E),
    accent: Color(0xFF2E3F8F),
    accentDark: Color(0xFF1F2C6B),
    accentLight: Color(0xFF5A6CC0),
    divider: Color(0xFFDCE2F0),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF2E3F8F),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF12162A),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF4F6FC),
  );

  /// Slate: no colour at all, for reading and nothing else.
  static const AppColorsExtension slateMonoDark = AppColorsExtension(
    primaryBackground: Color(0xFF0A0B0C),
    secondaryBackground: Color(0xFF141618),
    surface: Color(0xFF1B1E21),
    surfaceLight: Color(0xFF272B2F),
    primaryText: Color(0xFFF2F4F5),
    secondaryText: Color(0xFFC6CBCF),
    tertiaryText: Color(0xFF9AA1A6),
    accent: Color(0xFFA9BCC9),
    accentDark: Color(0xFF7E929F),
    accentLight: Color(0xFFD3E1EB),
    divider: Color(0xFF30353A),
    glassTint: Color(0xFF1B1E21),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DDCE6EE),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF1B1E21),
    barOpacity: 0.15,
    barBorder: Color(0x3DDCE6EE),
    raisedAction: Color(0xFFA9BCC9),
    onAccent: Color(0xFF10171C),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC08090A),
  );

  static const AppColorsExtension slateMonoLight = AppColorsExtension(
    primaryBackground: Color(0xFFF5F6F7),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE5E8EA),
    primaryText: Color(0xFF15181A),
    secondaryText: Color(0xFF414750),
    tertiaryText: Color(0xFF5D646B),
    accent: Color(0xFF3C5766),
    accentDark: Color(0xFF2A3F4B),
    accentLight: Color(0xFF6C8794),
    divider: Color(0xFFDFE3E6),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF3C5766),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF15181A),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF5F6F7),
  );

  /// Black and white with one loud colour: for eyes that need the
  /// most separation the app can give.
  static const AppColorsExtension highContrastDark = AppColorsExtension(
    primaryBackground: Color(0xFF000000),
    secondaryBackground: Color(0xFF0A0A0A),
    surface: Color(0xFF121212),
    surfaceLight: Color(0xFF1E1E1E),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFE0E0E0),
    tertiaryText: Color(0xFFBDBDBD),
    accent: Color(0xFFFFEB3B),
    accentDark: Color(0xFFC8B900),
    accentLight: Color(0xFFFFF59D),
    divider: Color(0xFF2E2E2E),
    glassTint: Color(0xFF121212),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFFFFF),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF121212),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFFFFF),
    raisedAction: Color(0xFFFFEB3B),
    onAccent: Color(0xFF000000),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    // Named for contrast, so the photograph is pushed almost out of
    // the way rather than merely darkened.
    scrim: Color(0xF5000000),
  );

  static const AppColorsExtension highContrastLight = AppColorsExtension(
    primaryBackground: Color(0xFFFFFFFF),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF0F0F0),
    primaryText: Color(0xFF000000),
    secondaryText: Color(0xFF2B2B2B),
    tertiaryText: Color(0xFF4A4A4A),
    accent: Color(0xFF0F4FB5),
    accentDark: Color(0xFF093A87),
    accentLight: Color(0xFF4A80D8),
    divider: Color(0xFFD6D6D6),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF0F4FB5),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF000000),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0xF0FFFFFF),
  );

  /// An olive grove: green gone quiet and yellow.
  static const AppColorsExtension oliveGroveDark = AppColorsExtension(
    primaryBackground: Color(0xFF0B0E06),
    secondaryBackground: Color(0xFF141A0C),
    surface: Color(0xFF1B2210),
    surfaceLight: Color(0xFF28311A),
    primaryText: Color(0xFFF2F6E9),
    secondaryText: Color(0xFFCBD8B4),
    tertiaryText: Color(0xFFA2B089),
    accent: Color(0xFFA8D14A),
    accentDark: Color(0xFF7FA430),
    accentLight: Color(0xFFC9E88A),
    divider: Color(0xFF333D22),
    glassTint: Color(0xFF1B2210),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DE3F2C6),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF1B2210),
    barOpacity: 0.15,
    barBorder: Color(0x3DE3F2C6),
    raisedAction: Color(0xFFA8D14A),
    onAccent: Color(0xFF111A05),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC090C05),
  );

  static const AppColorsExtension oliveGroveLight = AppColorsExtension(
    primaryBackground: Color(0xFFF6F8EF),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFE7EED6),
    primaryText: Color(0xFF1A1E10),
    secondaryText: Color(0xFF444C33),
    tertiaryText: Color(0xFF5F6849),
    accent: Color(0xFF46660F),
    accentDark: Color(0xFF324A08),
    accentLight: Color(0xFF7A9B3C),
    divider: Color(0xFFDFE6CE),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFF46660F),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF1A1E10),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EF6F8EF),
  );

  /// Rose gold: copper warmed with pink.
  static const AppColorsExtension roseGoldDark = AppColorsExtension(
    primaryBackground: Color(0xFF140A0C),
    secondaryBackground: Color(0xFF1F1114),
    surface: Color(0xFF29171A),
    surfaceLight: Color(0xFF372126),
    primaryText: Color(0xFFFCEFEE),
    secondaryText: Color(0xFFE6C5BE),
    tertiaryText: Color(0xFFBE9A93),
    accent: Color(0xFFE8A598),
    accentDark: Color(0xFFBC7A65),
    accentLight: Color(0xFFF7C7B8),
    divider: Color(0xFF46292A),
    glassTint: Color(0xFF29171A),
    glassOpacity: 0.1,
    glassOpacityOverPhoto: 0.3,
    glassBorder: Color(0x4DFFD9CE),
    glassShadow: Color(0x40000000),
    barTint: Color(0xFF29171A),
    barOpacity: 0.15,
    barBorder: Color(0x3DFFD9CE),
    raisedAction: Color(0xFFE8A598),
    onAccent: Color(0xFF2B120C),
    veil: Color(0xFFFFFFFF),
    shade: Color(0xFF000000),
    scrim: Color(0xCC0F0709),
  );

  static const AppColorsExtension roseGoldLight = AppColorsExtension(
    primaryBackground: Color(0xFFFDF4F1),
    secondaryBackground: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceLight: Color(0xFFF7E2DB),
    primaryText: Color(0xFF231513),
    secondaryText: Color(0xFF58403C),
    tertiaryText: Color(0xFF705551),
    accent: Color(0xFFA0503C),
    accentDark: Color(0xFF7D3A2B),
    accentLight: Color(0xFFC87C66),
    divider: Color(0xFFEEDBD4),
    glassTint: Color(0xFFFFFFFF),
    glassOpacity: 0.56,
    glassOpacityOverPhoto: 0.73,
    glassBorder: Color(0x1F000000),
    glassShadow: Color(0x14000000),
    barTint: Color(0xFFFFFFFF),
    barOpacity: 0.87,
    barBorder: Color(0x1A000000),
    raisedAction: Color(0xFFA0503C),
    onAccent: Color(0xFFFFFFFF),
    veil: Color(0xFF231513),
    shade: Color(0xFFFFFFFF),
    scrim: Color(0x9EFDF4F1),
  );

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
    Color? barTint,
    double? barOpacity,
    Color? barBorder,
    Color? raisedAction,
    Color? onAccent,
    Color? veil,
    Color? shade,
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
      barTint: barTint ?? this.barTint,
      barOpacity: barOpacity ?? this.barOpacity,
      barBorder: barBorder ?? this.barBorder,
      raisedAction: raisedAction ?? this.raisedAction,
      onAccent: onAccent ?? this.onAccent,
      veil: veil ?? this.veil,
      shade: shade ?? this.shade,
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
      barTint: mix(barTint, other.barTint),
      barOpacity: lerpDouble(barOpacity, other.barOpacity, t),
      barBorder: mix(barBorder, other.barBorder),
      raisedAction: mix(raisedAction, other.raisedAction),
      onAccent: mix(onAccent, other.onAccent),
      veil: mix(veil, other.veil),
      shade: mix(shade, other.shade),
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
