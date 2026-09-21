import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

class _MutableHymnRepository implements HymnRepository {
  List<Hymn> hymns;
  int loadCount = 0;

  _MutableHymnRepository(this.hymns);

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
    String languageCode,
    String version,
  ) async {
    loadCount += 1;
    return Right(List<Hymn>.unmodifiable(hymns));
  }

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
    String languageCode,
    String version,
    int number,
  ) async {
    for (final hymn in hymns) {
      if (hymn.displayNumber == number) return Right(hymn);
    }
    return const Right(null);
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
    String languageCode,
    String version,
    String category,
  ) async =>
      Right(hymns);

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
    String languageCode,
    String version,
    String query,
  ) async =>
      Right(hymns);
}

class _FakeSettingsRepository implements SettingsRepository {
  String language = 'am';
  String version = 'sda_new';
  String sortType = 'number';

  @override
  bool getBackgroundImageEnabled() => true;
  @override
  List<int> getFavoriteHymns() => const [];
  @override
  List<String> getFavoriteHymnKeys() => const [];
  @override
  double getFontSize() => 20;
  @override
  bool getKeepScreenOn() => false;
  @override
  String getSelectedLanguage() => language;
  @override
  String getSelectedVersion() => version;
  @override
  String getSortType() => sortType;
  @override
  bool isFavorite(int hymnNumber, {String? version}) => false;
  @override
  bool isOnboardingCompleted() => true;
  @override
  Future<bool> setBackgroundImageEnabled(bool value) async => true;
  @override
  Future<bool> setFavoriteHymns(List<int> hymnNumbers) async => true;
  @override
  Future<bool> setFontSize(double fontSize) async => true;
  @override
  Future<bool> setKeepScreenOn(bool value) async => true;
  @override
  Future<bool> setOnboardingCompleted(bool value) async => true;
  @override
  Future<bool> setSelectedLanguage(String languageCode) async {
    language = languageCode;
    return true;
  }

  @override
  Future<bool> setSelectedVersion(String value) async {
    version = value;
    return true;
  }

  @override
  Future<bool> setSortType(String value) async {
    sortType = value;
    return true;
  }

  @override
  Future<bool> toggleFavorite(int hymnNumber, {String? version}) async => true;
}

void main() {
  test('force refresh reloads an already selected hymnal', () async {
    final repository = _MutableHymnRepository(const [
      Hymn(id: 'work-1', number: 1, title: 'Before editor save'),
    ]);
    final bloc = HymnsBloc(
      getHymns: GetHymns(repository),
      searchHymns: SearchHymns(repository),
      getHymnByNumber: GetHymnByNumber(repository),
      settingsRepository: _FakeSettingsRepository(),
    );
    addTearDown(bloc.close);

    final firstLoad = bloc.stream
        .where((state) => state is HymnsLoaded)
        .cast<HymnsLoaded>()
        .first;
    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    expect((await firstLoad).hymns.single.title, 'Before editor save');
    expect(repository.loadCount, 1);

    bloc.add(LoadHymns('am', 'sda_new', 'number'));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(repository.loadCount, 1);

    repository.hymns = const [
      Hymn(id: 'work-1', number: 1, title: 'After editor save'),
    ];
    final refreshed = bloc.stream
        .where((state) => state is HymnsLoaded)
        .cast<HymnsLoaded>()
        .firstWhere(
          (state) => state.hymns.single.title == 'After editor save',
        );
    bloc.add(
      LoadHymns(
        'am',
        'sda_new',
        'number',
        forceRefresh: true,
      ),
    );

    expect((await refreshed).hymns.single.title, 'After editor save');
    expect(repository.loadCount, 2);
  });
}
