// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/utils/constants.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.primaryBackground,
      // Note: primaryColor is ignored when colorScheme is set, so we only use colorScheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        secondary: AppColors.accentGreenLight,
        surface: AppColors.surface,
        error: Colors.red,
        onPrimary: AppColors.primaryText,
        onSecondary: AppColors.primaryText,
        onSurface: AppColors.primaryText,
        onError: AppColors.primaryText,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        titleSmall: TextStyle(
          color: AppColors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: AppColors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        labelLarge: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelMedium: TextStyle(
          color: AppColors.secondaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        labelSmall: TextStyle(
          color: AppColors.tertiaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 10,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontFamily: 'NotoSansEthiopic',
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: AppColors.divider,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
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
          borderSide: const BorderSide(color: AppColors.accentGreen, width: 2),
        ),
        hintStyle: const TextStyle(
          color: AppColors.tertiaryText,
          fontFamily: 'NotoSansEthiopic',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.primaryText,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBackground,
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.secondaryText,
        selectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'NotoSansEthiopic',
          fontSize: 12,
        ),
      ),
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
