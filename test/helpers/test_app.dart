import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/l10n/app_localizations.dart';
import 'package:amharic_hymnal_app/core/services/history_service.dart';
import 'package:amharic_hymnal_app/core/theme/app_theme.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

import 'fakes.dart';

/// Wires the app's dependencies for a test with fake hymn content and the
/// given saved preferences, and returns the fake so tests can change it.
///
/// Never touches the network: the hymn data source is replaced before the
/// real one could be created.
Future<FakeHymnLocalDataSource> setUpTestApp({
  Map<String, List<HymnModel>>? content,
  Map<String, Object> prefs = const {},
  String version = 'sda_new',
}) async {
  await di.sl.reset();
  HistoryService.resetForTesting();
  SharedPreferences.setMockInitialValues({
    'onboarding_completed': true,
    'selected_language': 'am',
    'selected_version': version,
    'sort_type': 'number',
    ...prefs,
  });
  final source = FakeHymnLocalDataSource(
    content ?? {version: sampleHymns()},
  );
  di.sl.registerLazySingleton<HymnLocalDataSource>(() => source);
  await di.initDependencies();
  return source;
}

/// Pumps [child] inside the app's theme, localizations and a [HymnsBloc],
/// at a phone size unless [size] is given.
Future<HymnsBloc> pumpInApp(
  WidgetTester tester,
  Widget child, {
  HymnsBloc? bloc,
  Size size = const Size(390, 844),
  double textScale = 1,
  Locale locale = const Locale('am'),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final hymnsBloc = bloc ?? di.sl<HymnsBloc>();
  addTearDown(hymnsBloc.close);

  await tester.pumpWidget(
    BlocProvider<HymnsBloc>.value(
      value: hymnsBloc,
      child: MaterialApp(
        theme: AppTheme.darkTheme,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
  return hymnsBloc;
}

/// Loads [version] into [bloc] and waits for it to settle.
Future<void> loadHymns(
  WidgetTester tester,
  HymnsBloc bloc, {
  String version = 'sda_new',
  String sort = 'number',
}) async {
  bloc.add(LoadHymns('am', version, sort));
  await tester.pumpAndSettle();
}
