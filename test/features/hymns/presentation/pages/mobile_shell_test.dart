import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

Future<HymnsBloc> _pumpShell(
  WidgetTester tester, {
  String version = 'sda_new',
  double textScale = 1,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({
    'onboarding_completed': true,
    'selected_language': 'am',
    'selected_version': version,
    'sort_type': 'number',
  });
  await di.initDependencies(startDatabase: false);
  final bloc = di.sl<HymnsBloc>();

  await tester.pumpWidget(
    BlocProvider<HymnsBloc>.value(
      value: bloc,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const MainNavigationPage(
            loadInitialData: false,
            usePlaceholderPagesForTesting: true,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

void main() {
  testWidgets('bottom nav order is Index, Favourite, Number, Category, Setting',
      (tester) async {
    final bloc = await _pumpShell(tester);
    addTearDown(bloc.close);

    expect(find.text('Index'), findsOneWidget);
    expect(find.text('Favourite'), findsOneWidget);
    expect(find.text('Number'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category tab is hidden for Hagerigna', (tester) async {
    final bloc = await _pumpShell(tester, version: 'hagerigna');
    addTearDown(bloc.close);

    expect(find.text('Category'), findsNothing);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom nav survives compact width and larger text scale',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      size: const Size(360, 640),
      textScale: 1.6,
    );
    addTearDown(bloc.close);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarding renders without overflow on mobile constraints',
      (tester) async {
    const sizes = [
      Size(360, 640),
      Size(375, 667),
      Size(390, 844),
      Size(412, 915),
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(
        const MaterialApp(home: OnboardingPage()),
      );
      await tester.pumpAndSettle();

      expect(find.text('በውዳሴ እንኳን ደህና መጡ'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull);
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    expect(tester.takeException(), isNull);
  });
}
