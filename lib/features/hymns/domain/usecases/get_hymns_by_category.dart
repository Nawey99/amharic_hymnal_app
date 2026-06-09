// lib/features/hymns/domain/usecases/get_hymns_by_category.dart
import 'package:dartz/dartz.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/core/usecases/usecase.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';

class GetHymnsByCategoryParams {
  final String languageCode;
  final String version;
  final String category;

  GetHymnsByCategoryParams({
    required this.languageCode,
    required this.version,
    required this.category,
  });
}

class GetHymnsByCategory
    implements UseCase<List<Hymn>, GetHymnsByCategoryParams> {
  final HymnRepository repository;

  GetHymnsByCategory(this.repository);

  @override
  Future<Either<Failure, List<Hymn>>> call(
      GetHymnsByCategoryParams params) async {
    return await repository.getHymnsByCategory(
      params.languageCode,
      params.version,
      params.category,
    );
  }
}
