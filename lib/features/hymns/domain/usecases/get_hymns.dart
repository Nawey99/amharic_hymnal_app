// lib/features/hymns/domain/usecases/get_hymns.dart
import 'package:dartz/dartz.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/usecases/usecase.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';

class GetHymnsParams {
  final String languageCode;
  final String version;

  GetHymnsParams({required this.languageCode, required this.version});
}

class GetHymns implements UseCase<List<Hymn>, GetHymnsParams> {
  final HymnRepository repository;

  GetHymns(this.repository);

  @override
  Future<Either<Failure, List<Hymn>>> call(GetHymnsParams params) async {
    return await repository.getHymns(params.languageCode, params.version);
  }
}
