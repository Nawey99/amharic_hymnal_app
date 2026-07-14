import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
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
  bool usePlaceholderPagesForTesting = true,
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
            usePlaceholderPagesForTesting: usePlaceholderPagesForTesting,
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

    final navBar = tester.widget<AppBottomNavigationBar>(
      find.byType(AppBottomNavigationBar),
    );
    expect(navBar.selectedIndex, 2);
    expect(
      navBar.destinations.map((destination) => destination.id),
      ['category', 'index', 'number', 'favorites', 'settings'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('number destination is raised, centered, and tappable',
      (tester) async {
    final bloc = await _pumpShell(tester, initialDestination: 'index');
    addTearDown(bloc.close);

    final numberDestination = find.byKey(
      const ValueKey('bottom-nav-number'),
    );
    final categoryDestination = find.byKey(
      const ValueKey('bottom-nav-category'),
    );

    expect(numberDestination, findsOneWidget);
    expect(
      tester.getCenter(numberDestination).dx,
      closeTo(tester.view.physicalSize.width / 2, 0.5),
    );
    expect(
      tester.getTopLeft(numberDestination).dy,
      lessThan(tester.getTopLeft(categoryDestination).dy),
    );

    await tester.tap(numberDestination);
    await tester.pumpAndSettle();

    final navBar = tester.widget<AppBottomNavigationBar>(
      find.byType(AppBottomNavigationBar),
    );
    expect(navBar.selectedIndex, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category tab is hidden for Hagerigna', (tester) async {
    final bloc = await _pumpShell(tester, version: 'hagerigna');
    addTearDown(bloc.close);

    expect(find.text('ምድብ'), findsNothing);
    final navBar = tester.widget<AppBottomNavigationBar>(
      find.byType(AppBottomNavigationBar),
    );
    expect(navBar.selectedIndex, 1);
    expect(
      tester.getCenter(find.byKey(const ValueKey('bottom-nav-number'))).dx,
      closeTo(tester.view.physicalSize.width / 2, 0.5),
    );
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

    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape shell moves destinations into a compact side rail',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      size: const Size(844, 390),
      initialDestination: 'index',
    );
    addTearDown(bloc.close);

    expect(
      find.byKey(const ValueKey('landscape-navigation-rail')),
      findsOneWidget,
    );
    expect(find.byType(AppBottomNavigationBar), findsNothing);
    for (final label in const ['ምድብ', 'ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብር']) {
      expect(find.text(label), findsOneWidget);
    }

    final settingsDestination = find.byKey(
      const ValueKey('landscape-nav-settings'),
    );
    expect(
      find.descendant(
        of: settingsDestination,
        matching: find.byIcon(Icons.settings_outlined),
      ),
      findsOneWidget,
    );

    await tester.tap(settingsDestination);
    await tester.pump();

    expect(
      find.descendant(
        of: settingsDestination,
        matching: find.byIcon(Icons.settings_rounded),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape rail survives short height and larger text',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      size: const Size(640, 320),
      textScale: 1.6,
      initialDestination: 'settings',
    );
    addTearDown(bloc.close);

    expect(
      find.byKey(const ValueKey('landscape-navigation-rail')),
      findsOneWidget,
    );
    expect(find.byType(AppBottomNavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('landscape settings keeps a tall scrollable content area',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      size: const Size(844, 390),
      initialDestination: 'settings',
      usePlaceholderPagesForTesting: false,
    );
    addTearDown(bloc.close);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(AppBottomNavigationBar), findsNothing);
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(300));

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(find.text('ስህተት ላክ'), findsOneWidget);
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
