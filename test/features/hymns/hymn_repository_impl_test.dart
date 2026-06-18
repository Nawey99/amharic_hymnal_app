import 'package:flutter_test/flutter_test.dart';
// dartz not needed directly for these tests

import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
// domain Hymn imported implicitly through mapping
import 'package:amharic_hymnal_app/core/error/failures.dart';

class FakeLocalDataSource implements HymnLocalDataSource {
  final List<HymnModel> models;
  FakeLocalDataSource(this.models);

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    return models;
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

  test('HymnRepositoryImpl returns CacheFailure when datasource empty',
      () async {
    final repo = HymnRepositoryImpl(FakeLocalDataSource([]));
    final result = await repo.getHymns('am', 'hymnal');
    expect(result.isLeft(), true);
    result.fold(
        (l) => expect(l, isA<CacheFailure>()), (r) => fail('Expected failure'));
  });
}
