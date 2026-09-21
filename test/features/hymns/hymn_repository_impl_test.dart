import 'package:flutter_test/flutter_test.dart';
// dartz not needed directly for these tests

import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
// domain Hymn imported implicitly through mapping
import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';

class FakeLocalDataSource implements HymnLocalDataSource {
  final List<HymnModel> models;
  FakeLocalDataSource(this.models);

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    return models;
  }
}

class OnlineOnlyDataSource implements HymnLocalDataSource {
  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) {
    throw DatabaseNotFoundException('No offline database for $version');
  }
}

void main() {
  test('HymnRepositoryImpl returns hymns when datasource has them', () async {
    final model = const HymnModel(id: '1', number: 1, title: 'A', lyrics: 'L');
    final repo = HymnRepositoryImpl(FakeLocalDataSource([model]));

    final result = await repo.getHymns('am', 'hymnal');
    expect(result.isRight(), true);
    result.fold((l) => expect(l, isA<Failure>()), (r) => expect(r.length, 1));
  });

  test('HymnRepositoryImpl treats an empty edition as valid content', () async {
    final repo = HymnRepositoryImpl(FakeLocalDataSource([]));
    final result = await repo.getHymns('am', 'hymnal');
    expect(result.isRight(), true);
    result.fold(
      (failure) => fail('Expected an empty successful result, got $failure'),
      (hymns) => expect(hymns, isEmpty),
    );
  });

  test('HymnRepositoryImpl reports an online-only edition as a network failure',
      () async {
    final repo = HymnRepositoryImpl(OnlineOnlyDataSource());
    final result = await repo.getHymns('am', 'sda_1960');
    result.fold(
      (failure) => expect(failure, isA<NetworkFailure>()),
      (_) => fail('Expected a failure'),
    );
  });
}
