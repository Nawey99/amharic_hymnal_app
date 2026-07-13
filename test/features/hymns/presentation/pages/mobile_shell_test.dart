import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

Future<HymnsBloc> _pumpShell(
  WidgetTester tester, {
  String version = 'sda_new',
  double textScale = 1,
  Size size = const Size(390, 844),
  String initialDestination = 'number',
  Hymn? initialActiveHymn,
  String? initialActiveDestination,
  HymnDetailBuilder? hymnDetailBuilder,
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
          child: MainNavigationPage(
            loadInitialData: false,
            usePlaceholderPagesForTesting: true,
            initialDestination: initialDestination,
            initialActiveHymn: initialActiveHymn,
            initialActiveDestination: initialActiveDestination,
            hymnDetailBuilder: hymnDetailBuilder,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

void main() {
  testWidgets('bottom nav order is Category, Index, Number, Fav, Setting',
      (tester) async {
    final bloc = await _pumpShell(tester);
    addTearDown(bloc.close);

    expect(find.text('ምድብ'), findsOneWidget);
    expect(find.text('ማውጫ'), findsOneWidget);
    expect(find.text('ቁጥር'), findsOneWidget);
    expect(find.text('ተወዳጅ'), findsOneWidget);
    expect(find.text('ቅንብር'), findsOneWidget);

    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active bottom nav item has no selected pill container',
      (tester) async {
    final bloc = await _pumpShell(tester);
    addTearDown(bloc.close);

    final selectedDestination = tester.widget<NavigationDestination>(
      find
          .ancestor(
            of: find.text('ቁጥር'),
            matching: find.byType(NavigationDestination),
          )
          .first,
    );

    expect(selectedDestination.selectedIcon, isA<Icon>());
    expect((selectedDestination.icon as Icon).icon, Icons.numbers_rounded);
    expect(
      (selectedDestination.selectedIcon as Icon).icon,
      Icons.numbers_rounded,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('category tab is hidden for Hagerigna', (tester) async {
    final bloc = await _pumpShell(tester, version: 'hagerigna');
    addTearDown(bloc.close);

    expect(find.text('ምድብ'), findsNothing);
    final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(navBar.selectedIndex, 1);
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

  testWidgets('source tab restores its active hymn after visiting another tab',
      (tester) async {
    const hymn = Hymn(
      id: 'stored-number-hymn',
      number: 42,
      title: 'Stored hymn',
      lyrics: 'Stored lyrics',
    );
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'index',
      initialActiveHymn: hymn,
      initialActiveDestination: 'number',
      hymnDetailBuilder: _buildTestHymnDetail,
    );
    addTearDown(bloc.close);

    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail-index')));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);

    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('detail-number')));
    await _pumpNavigation(tester);
  });

  testWidgets('tapping the owning tab from its hymn clears hymn memory',
      (tester) async {
    const hymn = Hymn(
      id: 'toggle-number-hymn',
      number: 17,
      title: 'Toggle hymn',
      lyrics: 'Toggle lyrics',
    );
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'index',
      initialActiveHymn: hymn,
      initialActiveDestination: 'number',
      hymnDetailBuilder: _buildTestHymnDetail,
    );
    addTearDown(bloc.close);

    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('detail-number')));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);

    await tester.tap(find.text('ማውጫ'));
    await tester.pump();
    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);
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
        MaterialApp(
          key: ValueKey(size),
          home: const OnboardingPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ውዳሴ ምን ያደርጋል?'), findsOneWidget);
      expect(find.textContaining('ከታች'), findsWidgets);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull);

      for (final title in const [
        'በቁጥር መዝሙር ይክፈቱ',
        'በማውጫ ይፈልጉ',
        'በምድብ ያግኙ',
        'ግጥም፣ ድምፅ እና ኖታ',
        'ቅንብርን ይቆጣጠሩ',
      ]) {
        await tester.tap(find.text('ቀጣይ'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpNavigation(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

Widget _buildTestHymnDetail(
  Hymn hymn,
  String sourceDestination,
  ValueChanged<String> onDestinationSelected,
  ValueChanged<Hymn> onHymnChanged,
) {
  return Scaffold(
    key: const ValueKey('test-hymn-detail'),
    body: Text('${hymn.displayNumber}:$sourceDestination'),
    bottomNavigationBar: Row(
      children: [
        TextButton(
          key: const ValueKey('detail-index'),
          onPressed: () => onDestinationSelected('index'),
          child: const Text('Index'),
        ),
        TextButton(
          key: const ValueKey('detail-number'),
          onPressed: () => onDestinationSelected('number'),
          child: const Text('Number'),
        ),
      ],
    ),
  );
}
