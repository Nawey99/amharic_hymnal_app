import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/utils/index_section_utils.dart';
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
  testWidgets('selecting a letter displays hymns from that Fidel group',
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
    await di.initDependencies(startDatabase: false);

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
    final targetLetter = find.descendant(
      of: rail,
      matching: find.text('ተ'),
    );
    expect(targetLetter, findsOneWidget);

    await tester.tap(targetLetter);
    await tester.pumpAndSettle();

    final listRect = tester.getRect(find.byType(ListView));
    final visibleItems = <({double top, Hymn hymn})>[];
    final itemFinder = find.byType(HymnListItem);
    for (var index = 0; index < itemFinder.evaluate().length; index++) {
      final finder = itemFinder.at(index);
      final rect = tester.getRect(finder);
      if (rect.bottom > listRect.top && rect.top < listRect.bottom) {
        visibleItems.add((
          top: rect.top,
          hymn: tester.widget<HymnListItem>(finder).hymn,
        ));
      }
    }
    visibleItems.sort((a, b) => a.top.compareTo(b.top));

    expect(visibleItems, isNotEmpty);
    expect(
      amharicSectionForText(visibleItems.first.hymn.displayTitle),
      'ተ',
    );
  });
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
  ];
}

class _FakeHymnRepository implements HymnRepository {
  final List<Hymn> hymns;

  const _FakeHymnRepository(this.hymns);

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
