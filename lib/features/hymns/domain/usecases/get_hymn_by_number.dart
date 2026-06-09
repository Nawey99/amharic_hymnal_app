// lib/features/hymns/domain/usecases/get_hymn_by_number.dart
import 'package:dartz/dartz.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/usecases/usecase.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';

class GetHymnByNumberParams {
  final String languageCode;
  final String version;
  final int number;

  GetHymnByNumberParams({
    required this.languageCode,
    required this.version,
    required this.number,
  });
}

class GetHymnByNumber implements UseCase<Hymn?, GetHymnByNumberParams> {
  final HymnRepository repository;

  GetHymnByNumber(this.repository);

  @override
  Future<Either<Failure, Hymn?>> call(GetHymnByNumberParams params) async {
    return await repository.getHymnByNumber(
      params.languageCode,
      params.version,
      params.number,
    );
  }
}
