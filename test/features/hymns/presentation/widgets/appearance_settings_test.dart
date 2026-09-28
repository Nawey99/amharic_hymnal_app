import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme_spec.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/appearance_settings.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    ThemeService().resetForTesting();
  });

  /// The appearance section inside an app that follows the chosen look, as
  /// Settings sits inside the real one.
  Future<void> pumpSettings(
    WidgetTester tester, {
    Locale locale = const Locale('am'),
  }) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: ThemeService(),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.forPalette(ThemeService().palette, Brightness.light),
          darkTheme:
              AppTheme.forPalette(ThemeService().palette, Brightness.dark),
          themeMode: ThemeService().themeMode,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppearanceSettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Brightness shownBrightness(WidgetTester tester) => Theme.of(
        tester.element(find.byType(AppearanceSettings)),
      ).brightness;

  testWidgets('choosing light turns the app light, and it is remembered',
      (tester) async {
    await pumpSettings(tester);
    expect(shownBrightness(tester), Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('theme-mode-light')));
    await tester.pumpAndSettle();

    expect(shownBrightness(tester), Brightness.light);
    expect(
      tester
          .element(find.byType(AppearanceSettings))
          .appColors
          .primaryBackground,
      AppColorsExtension.emeraldLight.primaryBackground,
    );
    expect(SettingsService.getThemeMode(), 'light');
  });

  testWidgets('and back to dark, or to whatever the phone is doing',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('theme-mode-light')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('theme-mode-dark')));
    await tester.pumpAndSettle();
    expect(shownBrightness(tester), Brightness.dark);

    await tester.tap(find.byKey(const ValueKey('theme-mode-system')));
    await tester.pumpAndSettle();
    expect(ThemeService().themeMode, ThemeMode.system);
    expect(SettingsService.getThemeMode(), 'system');
  });

  testWidgets('the chosen mode is the one marked as chosen', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('theme-mode-light')));
    await tester.pumpAndSettle();

    final semantics = tester.getSemantics(
      find.byKey(const ValueKey('theme-mode-light')),
    );
    expect(semantics.hasFlag(SemanticsFlag.isSelected), isTrue);
  });

  testWidgets('the chosen theme is the centred one, and it is named',
      (tester) async {
    await pumpSettings(tester);

    final emerald = find.byKey(const ValueKey('theme-palette-emerald'));
    expect(emerald, findsOneWidget);
    expect(
      tester.getSemantics(emerald).hasFlag(SemanticsFlag.isSelected),
      isTrue,
    );
    // One name under the row, not one under every circle.
    expect(find.text('አረንጓዴ'), findsOneWidget);
    for (final spec in AppThemeCatalog.themes.skip(1)) {
      expect(find.text(spec.label), findsNothing);
    }
    expect(
      tester.getCenter(emerald).dx,
      moreOrLessEquals(
        tester.getCenter(find.byKey(const ValueKey('theme-carousel'))).dx,
        epsilon: 1,
      ),
      reason: 'the chosen circle sits in the middle of the row',
    );
  });

  testWidgets('choosing a theme recolours the app, and it is remembered',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('theme-palette-purplePetal')));
    await tester.pumpAndSettle();

    expect(
      tester.element(find.byType(AppearanceSettings)).appColors.accent,
      AppColorsExtension.purplePetalDark.accent,
    );
    expect(SettingsService.getThemePalette(), 'purplePetal');
    expect(find.text('ወይንጠጅ'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-mode-light')));
    await tester.pumpAndSettle();
    expect(
      tester.element(find.byType(AppearanceSettings)).appColors.accent,
      AppColorsExtension.purplePetalLight.accent,
    );
  });

  testWidgets('a flick across the row settles on one theme, and writes once',
      (tester) async {
    await pumpSettings(tester);
    var writes = 0;
    ThemeService().addListener(() => writes++);

    await tester.fling(
      find.byKey(const ValueKey('theme-carousel')),
      const Offset(-600, 0),
      1200,
    );
    await tester.pumpAndSettle();

    final settled = AppThemeCatalog.byStoredName(
      SettingsService.getThemePalette(),
    );
    expect(
      settled.id,
      isNot(AppPalette.emerald),
      reason: 'the flick should have moved the row along',
    );
    expect(find.text(settled.label), findsOneWidget);
    expect(
      writes,
      1,
      reason: 'the app repaints once, when the row comes to rest',
    );
  });

  testWidgets('every theme in the catalogue can be reached and chosen',
      (tester) async {
    await pumpSettings(tester);

    for (final spec in AppThemeCatalog.themes) {
      final swatch = find.byKey(ValueKey('theme-palette-${spec.id.name}'));
      if (swatch.evaluate().isEmpty) {
        // Off the end of the row: drag towards it and look again.
        await tester.drag(
          find.byKey(const ValueKey('theme-carousel')),
          const Offset(-200, 0),
        );
        await tester.pumpAndSettle();
      }
      expect(swatch, findsOneWidget, reason: '${spec.id.name} is out of reach');
      await tester.tap(swatch);
      await tester.pumpAndSettle();
      expect(ThemeService().palette, spec.id);
      expect(find.text(spec.label), findsOneWidget);
    }
  });

  testWidgets('a theme chosen elsewhere brings its circle to the centre',
      (tester) async {
    await pumpSettings(tester);

    await ThemeService().setPalette(AppPalette.nobleMane);
    await tester.pumpAndSettle();

    expect(find.text('ወርቃማ'), findsOneWidget);
    expect(
      tester
          .getCenter(find.byKey(const ValueKey('theme-palette-nobleMane')))
          .dx,
      moreOrLessEquals(
        tester.getCenter(find.byKey(const ValueKey('theme-carousel'))).dx,
        epsilon: 1,
      ),
    );
  });

  testWidgets('in English the modes and the themes are named in English',
      (tester) async {
    await pumpSettings(tester, locale: const Locale('en'));

    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('አረንጓዴ'), findsNothing);
  });
}
