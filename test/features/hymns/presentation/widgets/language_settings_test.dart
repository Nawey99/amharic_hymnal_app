import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/language_service.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/language_settings.dart';

/// The app's own language, which is not the hymns' language.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.init();
    LanguageService().resetForTesting();
  });

  /// Settings inside an app that speaks whatever has been chosen, as it
  /// does in the real one.
  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ListenableBuilder(
        listenable: LanguageService(),
        builder: (context, _) => MaterialApp(
          locale: LanguageService().locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: LanguageSettings()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the app opens in Amharic', (tester) async {
    await pumpSettings(tester);

    expect(LanguageService().language, AppLanguage.amharic);
    expect(find.text('የመተግበሪያ ቋንቋ'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('app-language-am')))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
  });

  testWidgets('choosing English changes the words, and is remembered',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('app-language-en')));
    await tester.pumpAndSettle();

    expect(find.text('App language'), findsOneWidget);
    expect(find.text('የመተግበሪያ ቋንቋ'), findsNothing);
    expect(SettingsService.getUiLanguage(), 'en');
  });

  testWidgets('each language names itself, whichever is chosen',
      (tester) async {
    await pumpSettings(tester);
    expect(find.text('አማርኛ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-language-en')));
    await tester.pumpAndSettle();

    // Someone who cannot read Amharic still has to find their way back.
    expect(find.text('አማርኛ'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
  });

  testWidgets('following the phone leaves the locale to Flutter',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const ValueKey('app-language-system')));
    await tester.pumpAndSettle();

    expect(LanguageService().locale, isNull);
    expect(SettingsService.getUiLanguage(), 'system');
  });

  test('a stored choice is read back, and an unknown one is Amharic', () async {
    SharedPreferences.setMockInitialValues({'ui_language': 'en'});
    await SettingsService.init();
    LanguageService().resetForTesting();
    LanguageService().loadPreferences();
    expect(LanguageService().language, AppLanguage.english);
    expect(LanguageService().locale, const Locale('en'));

    SharedPreferences.setMockInitialValues({'ui_language': 'klingon'});
    await SettingsService.init();
    LanguageService().resetForTesting();
    LanguageService().loadPreferences();
    expect(LanguageService().language, AppLanguage.amharic);
  });
}
