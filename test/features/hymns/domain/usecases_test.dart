import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns_by_category.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart';

/// Records each call's arguments and answers with [result].
class _RecordingRepository implements HymnRepository {
  final List<List<Object?>> calls = [];
  Either<Failure, Object?> result = const Right(<Hymn>[]);

  Future<Either<Failure, T>> _answer<T>(List<Object?> args) async {
    calls.add(args);
    return result.map((value) => value as T);
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
          String languageCode, String version) =>
      _answer(['getHymns', languageCode, version]);

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
          String languageCode, String version, int number) =>
      _answer(['getHymnByNumber', languageCode, version, number]);

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
          String languageCode, String version, String query) =>
      _answer(['searchHymns', languageCode, version, query]);

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
          String languageCode, String version, String category) =>
      _answer(['getHymnsByCategory', languageCode, version, category]);
}

void main() {
  late _RecordingRepository repository;
  const hymns = [Hymn(number: 1, title: 'አምላካችን')];

  setUp(() => repository = _RecordingRepository());

  group('arguments reach the repository unchanged', () {
    test('GetHymns', () async {
      await GetHymns(repository)(
          GetHymnsParams(languageCode: 'am', version: 'sda_old'));
      expect(repository.calls.single, ['getHymns', 'am', 'sda_old']);
    });

    test('GetHymnByNumber', () async {
      repository.result = const Right(null);
      await GetHymnByNumber(repository)(GetHymnByNumberParams(
          languageCode: 'am', version: 'sda_new', number: 132));
      expect(
          repository.calls.single, ['getHymnByNumber', 'am', 'sda_new', 132]);
    });

    test('SearchHymns', () async {
      await SearchHymns(repository)(SearchHymnsParams(
          languageCode: 'am', version: 'hagerigna', query: 'ፍቅር'));
      expect(
          repository.calls.single, ['searchHymns', 'am', 'hagerigna', 'ፍቅር']);
    });

    test('GetHymnsByCategory', () async {
      await GetHymnsByCategory(repository)(GetHymnsByCategoryParams(
          languageCode: 'am', version: 'sda_new', category: 'ጸሎት'));
      expect(repository.calls.single,
          ['getHymnsByCategory', 'am', 'sda_new', 'ጸሎት']);
    });
  });

  group('results pass through', () {
    test('hymns on success', () async {
      repository.result = const Right(hymns);

      final result = await GetHymns(repository)(
          GetHymnsParams(languageCode: 'am', version: 'sda_new'));

      expect(result.getOrElse(() => []), hymns);
    });

    test('a missing hymn is a successful null, not a failure', () async {
      repository.result = const Right(null);

      final result = await GetHymnByNumber(repository)(GetHymnByNumberParams(
          languageCode: 'am', version: 'sda_new', number: 999));

      expect(result, const Right<Failure, Hymn?>(null));
    });

    for (final failure in <Failure>[
      const CacheFailure(),
      const NetworkFailure(),
      const ServerFailure('boom'),
    ]) {
      test('${failure.runtimeType} is returned as-is', () async {
        repository.result = Left(failure);

        final results = [
          await GetHymns(repository)(
              GetHymnsParams(languageCode: 'am', version: 'sda_new')),
          await SearchHymns(repository)(SearchHymnsParams(
              languageCode: 'am', version: 'sda_new', query: 'x')),
          await GetHymnsByCategory(repository)(GetHymnsByCategoryParams(
              languageCode: 'am', version: 'sda_new', category: 'x')),
          await GetHymnByNumber(repository)(GetHymnByNumberParams(
              languageCode: 'am', version: 'sda_new', number: 1)),
        ];

        for (final result in results) {
          expect(result.fold((f) => f, (_) => null), failure);
        }
      });
    }
  });
}
