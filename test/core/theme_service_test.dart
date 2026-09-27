import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';

void main() {
  group('ThemeService', () {
    setUp(() => ThemeService().resetForTesting());

    test('a fresh install opens in the look the app has always had', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init();
      ThemeService().loadPreferences();

      expect(ThemeService().themeMode, ThemeMode.dark);
      expect(ThemeService().palette, AppPalette.emerald);
    });

    test('what was chosen is there before the first frame', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'system',
        'theme_palette': 'emerald',
      });
      await SettingsService.init();
      ThemeService().loadPreferences();

      expect(ThemeService().themeMode, ThemeMode.system);
    });

    test('a choice is kept, and told to whoever is listening', () async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.init();
      ThemeService().loadPreferences();
      var told = 0;
      void listener() => told++;
      ThemeService().addListener(listener);
      addTearDown(() => ThemeService().removeListener(listener));

      await ThemeService().setThemeMode(ThemeMode.light);

      expect(told, 1);
      expect(SettingsService.getThemeMode(), 'light');
      // Choosing the same again says nothing.
      await ThemeService().setThemeMode(ThemeMode.light);
      expect(told, 1);
    });

    test('a palette from a later build reads as the one we have', () async {
      SharedPreferences.setMockInitialValues({'theme_palette': 'nobleMane'});
      await SettingsService.init();
      ThemeService().loadPreferences();

      expect(ThemeService().palette, AppPalette.emerald);
    });
  });

  group('AppColorsExtension', () {
    test('carries the colours the app has been painting with', () {
      const colors = AppColorsExtension.emeraldDark;

      expect(colors.accent, AppColors.accentGreen);
      expect(colors.primaryText, AppColors.primaryText);
      expect(colors.primaryBackground, AppColors.primaryBackground);
      expect(colors.glassOpacityOverPhoto, greaterThan(colors.glassOpacity),
          reason: 'a panel over the photograph has to hold its text');
    });

    testWidgets('a screen reads them from its context', (tester) async {
      late AppColorsExtension seen;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.forPalette(AppPalette.emerald, Brightness.dark),
        home: Builder(
          builder: (context) {
            seen = context.appColors;
            return const SizedBox.shrink();
          },
        ),
      ));

      expect(seen.accent, AppColors.accentGreen);
    });

    testWidgets('a screen with no theme of ours still has colours',
        (tester) async {
      late AppColorsExtension seen;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            seen = context.appColors;
            return const SizedBox.shrink();
          },
        ),
      ));

      expect(seen, AppColorsExtension.emeraldDark);
    });

    test('one palette can fade into another', () {
      const from = AppColorsExtension.emeraldDark;
      final to = from.copyWith(
        accent: const Color(0xFF000000),
        glassOpacity: 0.5,
      );

      final middle = from.lerp(to, 0.5);

      expect(middle.accent, Color.lerp(from.accent, to.accent, 0.5));
      expect(middle.glassOpacity, closeTo((from.glassOpacity + 0.5) / 2, 1e-9));
      expect(from.lerp(null, 0.5), from);
    });
  });
}
