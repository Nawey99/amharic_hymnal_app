import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/hymn_open_callback.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/pages/index_page.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/widgets/hymn_list_item.dart';
import 'package:amharic_hymnal_app/injection_container.dart' as di;

/// The index following the hymn the reader last opened: reading 78 in one
/// tab and turning to the index should land on 78, not on the first page.
void main() {
  late HymnsBloc bloc;
  late HymnTabSession session;

  Future<void> pumpIndex(WidgetTester tester) async {
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

    final repository = _FakeHymnRepository(_hymns());
    bloc = HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: di.sl<SettingsRepository>(),
    );
    addTearDown(bloc.close);
    session = HymnTabSession();
    addTearDown(session.dispose);

    await tester.pumpWidget(
      BlocProvider<HymnsBloc>.value(
        value: bloc,
        child: MaterialApp(
          home: Scaffold(body: IndexPage(session: session)),
        ),
      ),
    );
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await tester.pumpAndSettle();
  }

  /// The hymn numbers on screen, top to bottom.
  List<int> shownNumbers(WidgetTester tester) {
    final numbers = <int>[];
    for (final element in find.byType(HymnListItem).evaluate()) {
      final box = element.renderObject as RenderBox?;
      if (box == null || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top < 0 || top > tester.view.physicalSize.height) continue;
      numbers.add((element.widget as HymnListItem).hymn.displayNumber);
    }
    numbers.sort();
    return numbers;
  }

  void openHymn(int number) {
    session.open(
      hymn: _hymns().firstWhere((hymn) => hymn.displayNumber == number),
      sourceDestination: 'number',
      version: 'sda_new',
    );
  }

  testWidgets('a hymn opened in another tab is what the index shows',
      (tester) async {
    await pumpIndex(tester);
    expect(shownNumbers(tester).first, 1, reason: 'starts at the beginning');

    openHymn(78);
    await tester.pumpAndSettle();

    final shown = shownNumbers(tester);
    expect(shown, contains(78));
    expect(
      shown.first,
      lessThan(78),
      reason: 'the hymns before it are in view too, not 78 pinned to the top',
    );
    expect(shown.last, greaterThan(78));
  });

  testWidgets('closing the hymn does not lose where the reader was',
      (tester) async {
    await pumpIndex(tester);

    openHymn(78);
    session.clear(); // what back does
    await tester.pumpAndSettle();

    expect(shownNumbers(tester), contains(78));
  });

  testWidgets('the list stays where the reader puts it afterwards',
      (tester) async {
    await pumpIndex(tester);
    openHymn(78);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    final afterScroll = shownNumbers(tester);
    expect(afterScroll, isNot(contains(78)));

    // Nothing new was opened, so nothing should move it back.
    session.notifyListeners();
    await tester.pumpAndSettle();
    expect(shownNumbers(tester), afterScroll);
  });

  testWidgets('opening another hymn moves the list again', (tester) async {
    await pumpIndex(tester);
    openHymn(78);
    await tester.pumpAndSettle();
    expect(shownNumbers(tester), contains(78));

    openHymn(150);
    await tester.pumpAndSettle();
    expect(shownNumbers(tester), contains(150));
  });

  testWidgets('a hymn from another book is left alone', (tester) async {
    await pumpIndex(tester);
    final before = shownNumbers(tester);

    session.open(
      hymn: _hymns().first,
      sourceDestination: 'number',
      version: 'sda_old',
    );
    await tester.pumpAndSettle();

    expect(shownNumbers(tester), before);
  });
}

List<Hymn> _hymns() => [
      for (var number = 1; number <= 200; number++)
        Hymn(
          id: 'hymn-${number.toString().padLeft(3, '0')}',
          number: number,
          title: 'መዝሙር $number',
          lyrics: 'የመዝሙር $number ግጥም',
          englishTitleOld: 'Hymn $number',
        ),
    ];

class _FakeHymnRepository implements HymnRepository {
  final List<Hymn> hymns;

  _FakeHymnRepository(this.hymns);

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
    String languageCode,
    String version,
  ) async =>
      Right(hymns);

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
    String languageCode,
    String version,
    int number,
  ) async =>
      Right(hymns.where((hymn) => hymn.displayNumber == number).firstOrNull);

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
    String languageCode,
    String version,
    String category,
  ) async =>
      const Right([]);

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
    String languageCode,
    String version,
    String query,
  ) async =>
      Right(hymns.where((hymn) => hymn.displayTitle.contains(query)).toList());
}
