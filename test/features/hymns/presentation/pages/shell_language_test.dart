import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

/// The shell reads in whichever language the app is set to. The hymns
/// themselves stay as they are written.
Future<HymnsBloc> _pumpShell(WidgetTester tester, Locale locale) async {
  const size = Size(390, 844);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    'onboarding_completed': true,
    'selected_language': 'am',
    'selected_version': 'sda_new',
    'sort_type': 'number',
  });
  await di.initDependencies();
  final bloc = di.sl<HymnsBloc>();
  addTearDown(bloc.close);

  await tester.pumpWidget(
    BlocProvider<HymnsBloc>.value(
      value: bloc,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MediaQuery(
          data: MediaQueryData(size: size),
          child: MainNavigationPage(
            loadInitialData: false,
            usePlaceholderPagesForTesting: true,
            initialDestination: 'number',
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

void main() {
  testWidgets('the tabs are named in English when the app is', (tester) async {
    await _pumpShell(tester, const Locale('en'));

    for (final label in [
      'Categories',
      'Index',
      'Number',
      'Favourites',
      'Settings'
    ]) {
      expect(find.text(label), findsWidgets, reason: '$label is missing');
    }
    for (final amharic in ['ምድብ', 'ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብሮች']) {
      expect(find.text(amharic), findsNothing);
    }
  });

  testWidgets('and in Amharic when it is', (tester) async {
    await _pumpShell(tester, const Locale('am'));

    for (final label in ['ምድብ', 'ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብሮች']) {
      expect(find.text(label), findsWidgets, reason: '$label is missing');
    }
    expect(find.text('Index'), findsNothing);
  });
}
