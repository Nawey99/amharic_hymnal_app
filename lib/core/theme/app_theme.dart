// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme_spec.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

class AppTheme {
  /// The theme for a palette in one brightness, carrying the colours the
  /// screens read through `context.appColors`.
  static ThemeData forPalette(AppPalette palette, Brightness brightness) {
    return _build(AppThemeCatalog.colorsFor(palette, brightness), brightness);
  }

  /// The app's own dark look, kept for code and tests that ask for it by
  /// name.
  static ThemeData get darkTheme =>
      forPalette(AppPalette.emerald, Brightness.dark);

  static ThemeData _build(AppColorsExtension colors, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[colors],
      scaffoldBackgroundColor: colors.primaryBackground,
      // Note: primaryColor is ignored when colorScheme is set, so we only use colorScheme
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.accent,
        secondary: colors.accentLight,
        surface: colors.surface,
        error: isDark ? Colors.red.shade400 : Colors.red.shade700,
        onPrimary: colors.onAccent,
        onSecondary: colors.onAccent,
        onSurface: colors.primaryText,
        onError: colors.primaryText,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: colors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: colors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: colors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: colors.tertiaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 10,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.primaryBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: colors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: colors.primaryText),
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardTheme(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: colors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.accent, width: 2),
        ),
        hintStyle: TextStyle(
          color: colors.tertiaryText,
          fontFamily: 'NotoSansEthiopic',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.primaryBackground,
        selectedItemColor: colors.accent,
        unselectedItemColor: colors.secondaryText,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
      ),
      // Messages float as a card, so they never become a strip across the
      // floating navigation bar. The shell lifts them above the bar.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.surface,
        contentTextStyle: TextStyle(
          color: colors.primaryText,
          fontSize: 14,
          fontFamily: 'NotoSansEthiopic',
        ),
        actionTextColor: colors.accent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: colors.glassBorder),
        ),
      ),
    );
  }

  /// How a hymn's words are set, at the size the reader chose.
  ///
  /// The settings preview draws with this too, so what is chosen there is
  /// what appears on the hymn page: the line height and letter spacing
  /// both move with the size, and they are most of what "bigger" feels
  /// like.
  static TextStyle lyricsTextStyle({
    required Color color,
    required double fontSize,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      height: getLineHeight(fontSize),
      fontFamily: 'NotoSansEthiopic',
      letterSpacing: getLetterSpacing(fontSize),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Theme scale utilities for responsive spacing and sizing

  /// Base font sizes for different text styles
  static const double baseFontSizeBody = 16.0;
  static const double baseFontSizeHeading = 20.0;
  static const double baseFontSizeCaption = 12.0;
  static const double baseFontSizeTitle = 24.0;

  /// Responsive spacing scale based on font size
  /// Returns spacing multiplier (e.g., 1.0 = base, 1.5 = 50% larger)
  static double getSpacingScale(double fontSize) {
    // Normalize to base font size (20.0)
    final normalizedSize = fontSize / AppConstants.defaultFontSize;
    // Clamp between 0.8 and 2.0 to match zoom scale limits
    return normalizedSize.clamp(
        AppConstants.minZoomScale, AppConstants.maxZoomScale);
  }

  /// Get responsive padding based on font size
  static EdgeInsets getResponsivePadding(
    double fontSize, {
    double horizontalMultiplier = 1.0,
    double verticalMultiplier = 1.0,
  }) {
    final scale = getSpacingScale(fontSize);
    final baseHorizontal = 16.0 * horizontalMultiplier;
    final baseVertical = 16.0 * verticalMultiplier;
    return EdgeInsets.symmetric(
      horizontal: baseHorizontal * scale,
      vertical: baseVertical * scale,
    );
  }

  /// Get responsive margin based on font size
  static EdgeInsets getResponsiveMargin(
    double fontSize, {
    double horizontalMultiplier = 1.0,
    double verticalMultiplier = 1.0,
  }) {
    final scale = getSpacingScale(fontSize);
    final baseHorizontal = 8.0 * horizontalMultiplier;
    final baseVertical = 8.0 * verticalMultiplier;
    return EdgeInsets.symmetric(
      horizontal: baseHorizontal * scale,
      vertical: baseVertical * scale,
    );
  }

  /// Max width constraint for text containers to maintain readability
  static double getMaxTextWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use 90% of screen width or 600px, whichever is smaller
    return screenWidth * 0.9 > 600 ? 600.0 : screenWidth * 0.9;
  }

  /// Get responsive font size for headings based on base font size
  static double getHeadingFontSize(double baseFontSize) {
    return baseFontSize * 1.3; // 30% larger than base
  }

  /// Get responsive font size for captions based on base font size
  static double getCaptionFontSize(double baseFontSize) {
    return baseFontSize * 0.75; // 25% smaller than base
  }

  /// Get responsive line height based on font size
  static double getLineHeight(double fontSize) {
    // Smaller fonts need more line height, larger fonts need less
    if (fontSize < 16) return 1.9;
    if (fontSize > 24) return 1.6;
    return 1.8;
  }

  /// Get responsive letter spacing based on font size
  static double getLetterSpacing(double fontSize) {
    // Smaller fonts need less letter spacing
    if (fontSize < 16) return 0.2;
    return 0.3;
  }
}
