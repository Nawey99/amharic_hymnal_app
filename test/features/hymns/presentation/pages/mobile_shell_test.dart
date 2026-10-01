import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/widgets/app_bottom_navigation_bar.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/categories_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/main_navigation_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/onboarding_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/settings_page.dart';
import 'package:amharic_hymnal_app/features/settings/presentation/pages/report_bug_page.dart';
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
  ValueNotifier<int>? numberPageReveals,
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
  await di.initDependencies();
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
            numberPageRevealsForTesting: numberPageReveals,
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
    expect(find.text('ቅንብሮች'), findsOneWidget);

    final navBar = tester.widget<AppBottomNavigationBar>(
      find.byType(AppBottomNavigationBar),
    );
    final shell = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(shell.bottomNavigationBar, isNull);
    expect(navBar.selectedIndex, 2);
    expect(
      navBar.destinations.map((destination) => destination.id),
      ['category', 'index', 'number', 'favorites', 'settings'],
    );
    expect(
      find.byKey(const ValueKey('navigation-outer-scrim')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('navigation-inner-glass')),
      findsOneWidget,
    );
    // The page fades into the bar over a wider, deeper area than the bar
    // itself covers.
    final scrim = tester.getRect(
      find.byKey(const ValueKey('navigation-outer-scrim')),
    );
    final innerGlass = tester.getRect(
      find.byKey(const ValueKey('navigation-inner-glass')),
    );
    expect(scrim.width, greaterThan(innerGlass.width));
    expect(scrim.bottom, greaterThan(innerGlass.bottom));
    // One frost, not three. Each one costs the phone a layer to save and
    // a backdrop to read, on every frame of every scroll underneath it.
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(find.byType(ShaderMask), findsNothing);
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

  for (final id in ['category', 'settings']) {
    testWidgets('selected $id tab keeps an even gap inside the bar',
        (tester) async {
      final bloc = await _pumpShell(tester, initialDestination: id);
      addTearDown(bloc.close);
      await tester.pumpAndSettle();

      final bar = tester.getRect(
        find.byKey(const ValueKey('navigation-inner-glass')),
      );
      final indicator = tester.getRect(
        find.byKey(const ValueKey('bottom-nav-indicator')),
      );
      final tab = tester.getRect(find.byKey(ValueKey('bottom-nav-$id')));

      final gaps = [
        indicator.top - bar.top,
        bar.bottom - indicator.bottom,
        id == 'category'
            ? indicator.left - bar.left
            : bar.right - indicator.right,
      ];
      for (final gap in gaps) {
        expect(gap, closeTo(5, 0.5));
      }
      expect(indicator, tab, reason: 'the highlight sits on the tab');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('messages float above the bottom bar, leaving it tappable',
      (tester) async {
    final bloc = await _pumpShell(tester, initialDestination: 'index');
    addTearDown(bloc.close);

    ScaffoldMessenger.of(
      tester.element(find.byType(AppBottomNavigationBar)),
    ).showSnackBar(const SnackBar(content: Text('message')));
    await tester.pumpAndSettle();

    // The card itself; the SnackBar's box includes its inset padding.
    final message = tester.getRect(find
        .descendant(of: find.byType(SnackBar), matching: find.byType(Material))
        .first);
    final bar = tester.getRect(
      find.byKey(const ValueKey('navigation-inner-glass')),
    );
    expect(message.bottom, lessThanOrEqualTo(bar.top));

    await tester.tap(find.byKey(const ValueKey('bottom-nav-settings')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppBottomNavigationBar>(find.byType(AppBottomNavigationBar))
          .selectedIndex,
      4,
    );
  });

  testWidgets('the highlight hides when the number action is selected',
      (tester) async {
    final bloc = await _pumpShell(tester, initialDestination: 'number');
    addTearDown(bloc.close);
    await tester.pumpAndSettle();

    final opacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byKey(const ValueKey('bottom-nav-indicator')),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacity.opacity, 0);
  });

  testWidgets('the report form opens clear of the bottom bar', (tester) async {
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'settings',
      usePlaceholderPagesForTesting: false,
    );
    addTearDown(bloc.close);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final reportTile = find.byKey(const ValueKey('report-bug-tile'));
    for (var scroll = 0;
        scroll < 12 && reportTile.evaluate().isEmpty;
        scroll++) {
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.ensureVisible(reportTile);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(reportTile);
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(ReportBugPage), findsOneWidget);
    expect(
      find.byType(AppBottomNavigationBar),
      findsNothing,
      reason: 'the floating bar would cover the send button',
    );

    await tester.pageBack();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(ReportBugPage), findsNothing);
    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
  });

  testWidgets('the bar holds its shape at the largest phone text size',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      size: const Size(360, 640),
      textScale: 2,
    );
    addTearDown(bloc.close);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull, reason: 'nothing overflows');
    final bar = tester.getRect(find.byType(AppBottomNavigationBar));
    expect(bar.height, lessThanOrEqualTo(120));
    for (final label in ['ምድብ', 'ማውጫ', 'ቁጥር', 'ተወዳጅ']) {
      expect(find.text(label), findsOneWidget, reason: '$label is still there');
    }
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

  testWidgets('category subpages keep the shell navigation visible',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'category',
      usePlaceholderPagesForTesting: false,
    );
    addTearDown(bloc.close);
    await tester.pumpAndSettle();

    final categoryContext = tester.element(find.byType(CategoriesPage));
    Navigator.of(categoryContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          key: ValueKey('category-subpage'),
          body: Text('Category songs'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-subpage')), findsOneWidget);
    expect(find.byType(AppBottomNavigationBar), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('bottom-nav-category')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-subpage')), findsNothing);
    expect(find.byType(CategoriesPage), findsOneWidget);
    expect(find.byType(AppBottomNavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back returns from a category subpage before the shell',
      (tester) async {
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'category',
      usePlaceholderPagesForTesting: false,
    );
    addTearDown(bloc.close);
    await tester.pumpAndSettle();

    final categoryContext = tester.element(find.byType(CategoriesPage));
    Navigator.of(categoryContext).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(
          key: ValueKey('category-back-subpage'),
          body: Text('Category songs'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('category-back-subpage')), findsNothing);
    expect(find.byType(CategoriesPage), findsOneWidget);
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
    for (final label in const ['ምድብ', 'ማውጫ', 'ቁጥር', 'ተወዳጅ', 'ቅንብሮች']) {
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
    expect(find.text('የስህተት ጥቆማ'), findsOneWidget);
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

  testWidgets('back on a hymn ends it, in that tab and after another tab',
      (tester) async {
    const hymn = Hymn(
      id: 'closed-number-hymn',
      number: 21,
      title: 'Closed hymn',
      lyrics: 'Closed lyrics',
    );
    final bloc = await _pumpShell(
      tester,
      initialDestination: 'number',
      initialActiveHymn: hymn,
      initialActiveDestination: 'number',
      hymnDetailBuilder: _buildTestHymnDetail,
    );
    addTearDown(bloc.close);

    // Reopened by tapping its own tab, as before the hymn was closed.
    await tester.tap(find.text('ማውጫ'));
    await _pumpNavigation(tester);
    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);

    // The system back gesture, as from the back arrow.
    await tester.binding.handlePopRoute();
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);

    // The tab it was opened from now shows its list, not the hymn again.
    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);

    await tester.tap(find.text('ማውጫ'));
    await _pumpNavigation(tester);
    await tester.tap(find.text('ቁጥር'));
    await _pumpNavigation(tester);
    expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);
    expect(tester.takeException(), isNull);
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

  /// Coming to the Number page means coming to type a number, so the shell
  /// tells it so and it clears its field and opens the keyboard. Reopening
  /// the hymn that tab still holds is not coming to the page: the reader ends
  /// up on the hymn, and a keyboard behind it is nobody's intention.
  ///
  /// This is the shell's half -- *when* the page is arrived at. What arriving
  /// does to the field is covered in number_search_page_test.dart.
  group('telling the Number page it has been arrived at', () {
    late ValueNotifier<int> reveals;

    setUp(() => reveals = ValueNotifier<int>(0));
    tearDown(() => reveals.dispose());

    testWidgets('from another tab, with no hymn held', (tester) async {
      final bloc = await _pumpShell(
        tester,
        initialDestination: 'index',
        numberPageReveals: reveals,
      );
      addTearDown(bloc.close);
      expect(reveals.value, 0);

      await tester.tap(find.text('ቁጥር'));
      await _pumpNavigation(tester);

      expect(reveals.value, 1);
    });

    testWidgets('not on the tap that reopens the hymn it holds',
        (tester) async {
      const hymn = Hymn(
        id: 'reveal-number-hymn',
        number: 42,
        title: 'Reveal hymn',
        lyrics: 'Reveal lyrics',
      );
      final bloc = await _pumpShell(
        tester,
        initialDestination: 'index',
        initialActiveHymn: hymn,
        initialActiveDestination: 'number',
        hymnDetailBuilder: _buildTestHymnDetail,
        numberPageReveals: reveals,
      );
      addTearDown(bloc.close);

      await tester.tap(find.text('ቁጥር'));
      await _pumpNavigation(tester);

      // The hymn, not the page.
      expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);
      expect(reveals.value, 0, reason: 'no keyboard behind the hymn');

      // The second tap, from the bar on the hymn itself, leaves the hymn and
      // shows the page -- and only now is the page arrived at.
      await tester.tap(find.byKey(const ValueKey('detail-number')));
      await _pumpNavigation(tester);

      expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);
      expect(reveals.value, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('again when the tab is tapped a second time', (tester) async {
      final bloc = await _pumpShell(
        tester,
        initialDestination: 'index',
        numberPageReveals: reveals,
      );
      addTearDown(bloc.close);

      await tester.tap(find.text('ቁጥር'));
      await _pumpNavigation(tester);
      // Already on Number: tapping it again is still arriving at it, and the
      // shell returns early for that case, so the bump has to come first.
      await tester.tap(find.text('ቁጥር'));
      await _pumpNavigation(tester);

      expect(reveals.value, 2);
    });

    testWidgets('not when a hymn is left by the back gesture', (tester) async {
      const hymn = Hymn(
        id: 'back-number-hymn',
        number: 21,
        title: 'Back hymn',
        lyrics: 'Back lyrics',
      );
      final bloc = await _pumpShell(
        tester,
        initialDestination: 'number',
        initialActiveHymn: hymn,
        initialActiveDestination: 'number',
        hymnDetailBuilder: _buildTestHymnDetail,
        numberPageReveals: reveals,
      );
      addTearDown(bloc.close);

      await tester.tap(find.text('ማውጫ'));
      await _pumpNavigation(tester);
      await tester.tap(find.text('ቁጥር'));
      await _pumpNavigation(tester);
      expect(find.byKey(const ValueKey('test-hymn-detail')), findsOneWidget);
      final beforeBack = reveals.value;

      await tester.binding.handlePopRoute();
      await _pumpNavigation(tester);

      // Back is not a tap on the Number destination. Throwing a keyboard at
      // someone who just pressed back is the wrong instinct.
      expect(find.byKey(const ValueKey('test-hymn-detail')), findsNothing);
      expect(reveals.value, beforeBack);
    });
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

      expect(find.text('ስለ ውዳሴ መተግበሪያ'), findsOneWidget);
      expect(find.textContaining('ከታች'), findsWidgets);
      expect(find.text('Skip'), findsNothing);
      expect(find.text('Next'), findsNothing);
      expect(tester.takeException(), isNull);

      for (final title in const [
        'በቁጥር መዝሙር ይክፈቱ',
        'በማውጫ ይፈልጉ',
        'በምድብ ያግኙ',
        'ግጥም፣ ድምፅ እና ኖታ',
        'ቅንብሮችን ያስተካክሉ',
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

/// Stands in for the hymn page: it reports being closed the same way, so
/// the shell's back handling is exercised.
Widget _buildTestHymnDetail(
  Hymn hymn,
  String sourceDestination,
  ValueChanged<String> onDestinationSelected,
  ValueChanged<Hymn> onHymnChanged,
  VoidCallback onClosed,
) {
  return PopScope(
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) onClosed();
    },
    child: _testHymnDetailBody(hymn, sourceDestination, onDestinationSelected),
  );
}

Widget _testHymnDetailBody(
  Hymn hymn,
  String sourceDestination,
  ValueChanged<String> onDestinationSelected,
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
