// lib/features/hymns/domain/usecases/search_hymns.dart
import 'package:dartz/dartz.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/usecases/usecase.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';

class SearchHymnsParams {
  final String languageCode;
  final String version;
  final String query;

  SearchHymnsParams({
    required this.languageCode,
    required this.version,
    required this.query,
  });
}

class SearchHymns implements UseCase<List<Hymn>, SearchHymnsParams> {
  final HymnRepository repository;

  SearchHymns(this.repository);

  @override
  Future<Either<Failure, List<Hymn>>> call(SearchHymnsParams params) async {
    return await repository.searchHymns(
      params.languageCode,
      params.version,
      params.query,
    );
  }
}
