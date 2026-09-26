import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';
import 'package:amharic_hymnal_app/core/utils/nav_bar_constants.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('sort dialog applies name choice from nested tab navigator',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'sda_new',
      'sort_type': 'number',
    });
    await di.initDependencies();

    final repository = _FakeHymnRepository(_buildGroupedHymns());
    final bloc = HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: di.sl<SettingsRepository>(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<HymnsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(
            body: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const IndexPage(),
              ),
            ),
          ),
        ),
      ),
    );
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.sort));
    await tester.pumpAndSettle();
    expect(find.text('አደራደር'), findsOneWidget);

    await tester.tap(find.text('በስም'));
    await tester.pumpAndSettle();

    expect(find.text('አደራደር'), findsNothing);
    expect(find.byType(IndexPage), findsOneWidget);
    expect((bloc.state as HymnsLoaded).sortType, 'name');
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected letter, indicator, and first hymn stay in sync',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'sda_new',
      'sort_type': 'name',
    });
    await di.initDependencies();

    final repository = _FakeHymnRepository(_buildGroupedHymns());
    final bloc = HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: di.sl<SettingsRepository>(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<HymnsBloc>.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(
            body: IndexPage(),
          ),
        ),
      ),
    );
    bloc.add(LoadHymns('am', 'sda_new', 'name'));
    await tester.pumpAndSettle();

    final rail = find.byKey(const ValueKey('alphabet-vertical-rail'));
    final railContext = tester.element(rail);
    final indexRect = tester.getRect(find.byType(IndexPage));
    final railRect = tester.getRect(rail);
    expect(
      railRect.bottom,
      lessThanOrEqualTo(
        indexRect.bottom - NavBarConstants.getBottomPadding(railContext),
      ),
    );
    final targetLetter = find.descendant(
      of: rail,
      matching: find.text('ተ'),
    );
    expect(targetLetter, findsOneWidget);

    await tester.tap(targetLetter);
    await tester.pumpAndSettle();

    var visibleItems = _visibleHymns(tester);
    expect(visibleItems, isNotEmpty);
    expect(
      amharicSectionForText(visibleItems.first.hymn.displayTitle),
      'ተ',
    );

    final endLetter = find.descendant(
      of: rail,
      matching: find.text('ጸ'),
    );
    expect(endLetter, findsOneWidget);

    await tester.tap(endLetter);
    await tester.pumpAndSettle();

    // The last section cannot reach the top without empty filler below the
    // list, so the list goes to its end and the letter stays selected.
    final position = tester
        .state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        )
        .position;
    expect(position.pixels, position.maxScrollExtent);
    visibleItems = _visibleHymns(tester);
    expect(
      visibleItems.map((item) => item.hymn.displayTitle),
      containsAll(['ጸ መዝሙር 00', 'ጸ መዝሙር 01']),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('index-section-indicator')),
          )
          .data,
      'ጸ',
    );
  });

  for (final sort in ['number', 'name']) {
    testWidgets('sorted by $sort, the list ends just above the nav bar',
        (tester) async {
      await _pumpIndexAtEnd(tester, sort);

      final last = tester.getRect(find.byType(HymnListItem).last);
      final lastCardBottom = last.bottom -
          HymnListItem.bottomGap(tester.element(find
              .byType(
                HymnListItem,
              )
              .last));
      // As on the category list: the nav bar's space plus the content inset
      // above the system navigation area, counted once.
      const screenBottom = 780.0;
      const systemInset = 48.0;
      expect(
        lastCardBottom,
        closeTo(
          screenBottom -
              systemInset -
              NavBarConstants.navBarTotalSpace -
              NavBarConstants.contentPadding,
          0.5,
        ),
      );
      if (sort == 'name') {
        // The letter heading follows the top card, not the gap left by one
        // that has scrolled away.
        final topCard = _visibleHymns(tester).first;
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('index-section-indicator')),
              )
              .data,
          amharicSectionForText(topCard.hymn.displayTitle),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  group('letter rail and search', () {
    final vertical = find.byKey(const ValueKey('alphabet-vertical-rail'));
    final horizontal = find.byKey(const ValueKey('alphabet-horizontal-rail'));
    double listRightPadding(WidgetTester tester) =>
        (tester.widget<ListView>(find.byType(ListView)).padding! as EdgeInsets)
            .right;

    testWidgets('opening search hides the rail; closing it brings it back',
        (tester) async {
      await _pumpIndex(tester, const Size(360, 780));
      expect(vertical, findsOneWidget);
      expect(listRightPadding(tester), 54);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(vertical, findsNothing);
      expect(horizontal, findsNothing);
      expect(listRightPadding(tester), 16, reason: 'the list uses the width');

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(vertical, findsNothing);
      expect(horizontal, findsNothing);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(vertical, findsOneWidget);
      expect(horizontal, findsNothing);
      expect(listRightPadding(tester), 54);
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing a search brings back the sorted list and its rail',
        (tester) async {
      await _pumpIndex(tester, const Size(360, 780));

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ተ');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('ሀ መዝሙር 00'), findsNothing, reason: 'filtered');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('ሀ መዝሙር 00'), findsOneWidget);
      expect(vertical, findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
        reason: 'a reopened search starts empty',
      );
    });

    testWidgets('a screen too short for the rail still gets the strip',
        (tester) async {
      await _pumpIndex(tester, const Size(360, 520));
      expect(horizontal, findsOneWidget);
      expect(listRightPadding(tester), 16);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(horizontal, findsNothing);
    });
  });

  testWidgets('same-length content refresh repaints edited song titles',
      (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({
      'selected_language': 'am',
      'selected_version': 'sda_new',
      'sort_type': 'number',
    });
    await di.initDependencies();

    final repository = _FakeHymnRepository(const [
      Hymn(id: 'shared-work', number: 1, title: 'Before editor save'),
    ]);
    final bloc = HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: di.sl<SettingsRepository>(),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<HymnsBloc>.value(
        value: bloc,
        child: const MaterialApp(
          home: Scaffold(body: IndexPage()),
        ),
      ),
    );
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await tester.pumpAndSettle();
    expect(find.text('Before editor save'), findsOneWidget);

    repository.hymns = const [
      Hymn(id: 'shared-work', number: 1, title: 'After editor save'),
    ];
    bloc.add(
      LoadHymns(
        'am',
        'sda_new',
        'number',
        forceRefresh: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Before editor save'), findsNothing);
    expect(find.text('After editor save'), findsOneWidget);
  });
}

/// Pumps the index page sorted by name at [size].
Future<void> _pumpIndex(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'selected_language': 'am',
    'selected_version': 'sda_new',
    'sort_type': 'name',
  });
  await di.initDependencies();

  final repository = _FakeHymnRepository(_buildGroupedHymns());
  final bloc = HymnsBloc(
    getHymns: GetHymns(repository),
    searchHymns: SearchHymns(repository),
    getHymnByNumber: GetHymnByNumber(repository),
    settingsRepository: di.sl<SettingsRepository>(),
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    BlocProvider<HymnsBloc>.value(
      value: bloc,
      child: const MaterialApp(home: Scaffold(body: IndexPage())),
    ),
  );
  bloc.add(LoadHymns('am', 'sda_new', 'name'));
  await tester.pumpAndSettle();
}

/// Pumps the index page on a phone with a 48 dp system navigation area and
/// scrolls to the end of the list sorted by [sort].
Future<void> _pumpIndexAtEnd(WidgetTester tester, String sort) async {
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  tester.view.padding = const FakeViewPadding(bottom: 48);
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    'selected_language': 'am',
    'selected_version': 'sda_new',
    'sort_type': sort,
  });
  await di.initDependencies();

  final repository = _FakeHymnRepository(_buildGroupedHymns());
  final bloc = HymnsBloc(
    getHymns: GetHymns(repository),
    searchHymns: SearchHymns(repository),
    getHymnByNumber: GetHymnByNumber(repository),
    settingsRepository: di.sl<SettingsRepository>(),
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    BlocProvider<HymnsBloc>.value(
      value: bloc,
      child: const MaterialApp(home: Scaffold(body: IndexPage())),
    ),
  );
  bloc.add(LoadHymns('am', 'sda_new', sort));
  await tester.pumpAndSettle();

  final position = tester
      .state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      )
      .position;
  // The extent is an estimate until the end has been laid out.
  while (position.pixels < position.maxScrollExtent) {
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
  }
}

List<({double top, Hymn hymn})> _visibleHymns(WidgetTester tester) {
  final listRect = tester.getRect(find.byType(ListView));
  final visibleItems = <({double top, Hymn hymn})>[];
  final itemFinder = find.byType(HymnListItem);
  for (var index = 0; index < itemFinder.evaluate().length; index++) {
    final finder = itemFinder.at(index);
    final rect = tester.getRect(finder);
    // The card, without the gap below it.
    final cardBottom =
        rect.bottom - HymnListItem.bottomGap(tester.element(finder));
    if (cardBottom > listRect.top && rect.top < listRect.bottom) {
      visibleItems.add((
        top: rect.top,
        hymn: tester.widget<HymnListItem>(finder).hymn,
      ));
    }
  }
  visibleItems.sort((a, b) => a.top.compareTo(b.top));
  return visibleItems;
}

List<Hymn> _buildGroupedHymns() {
  var number = 1;
  return [
    for (final letter in amharicFidelIndexOrder.take(18))
      for (var index = 0; index < 10; index++)
        Hymn(
          id: 'grouped-${number.toString().padLeft(3, '0')}',
          number: number++,
          title: '$letter መዝሙር ${index.toString().padLeft(2, '0')}',
          lyrics: '$letter መዝሙር',
          englishTitleOld: 'Test hymn $index',
        ),
    for (var index = 0; index < 2; index++)
      Hymn(
        id: 'grouped-${number.toString().padLeft(3, '0')}',
        number: number++,
        title: 'ጸ መዝሙር ${index.toString().padLeft(2, '0')}',
        lyrics: 'ጸ መዝሙር',
        englishTitleOld: 'End hymn $index',
      ),
  ];
}

class _FakeHymnRepository implements HymnRepository {
  List<Hymn> hymns;

  _FakeHymnRepository(this.hymns);

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
    String languageCode,
    String version,
  ) async {
    return Right(hymns);
  }

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
    String languageCode,
    String version,
    int number,
  ) async {
    return Right(
        hymns.where((hymn) => hymn.displayNumber == number).firstOrNull);
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
    String languageCode,
    String version,
    String category,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
    String languageCode,
    String version,
    String query,
  ) async {
    return Right(
      hymns.where((hymn) => hymn.displayTitle.contains(query)).toList(),
    );
  }
}
