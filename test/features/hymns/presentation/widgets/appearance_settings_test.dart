import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/services/theme_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_colors_extension.dart';
import 'package:amharic_hymnal_app/core/theme/app_palette.dart';
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
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: ThemeService(),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.forPalette(ThemeService().palette, Brightness.light),
          darkTheme:
              AppTheme.forPalette(ThemeService().palette, Brightness.dark),
          themeMode: ThemeService().themeMode,
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

  testWidgets('one palette so far, so no swatches to choose between',
      (tester) async {
    await pumpSettings(tester);

    expect(AppPalette.values, hasLength(1));
    expect(
      find.byKey(const ValueKey('theme-palette-emerald')),
      findsNothing,
      reason: 'a row of one swatch chooses nothing',
    );
  });
}
