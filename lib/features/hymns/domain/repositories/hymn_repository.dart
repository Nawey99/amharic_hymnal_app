// lib/features/hymns/domain/repositories/hymn_repository.dart
import 'package:dartz/dartz.dart';

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Repository interface for hymn data operations
///
/// Following Clean Architecture, this is a domain layer interface that
/// defines the contract for hymn data access. Implementations in the
/// data layer handle the actual data retrieval from local/remote sources.
///
/// All methods return Either[Failure, T] for consistent error handling.
abstract class HymnRepository {
  Future<Either<Failure, List<Hymn>>> getHymns(
      String languageCode, String version);
  Future<Either<Failure, Hymn?>> getHymnByNumber(
      String languageCode, String version, int number);
  Future<Either<Failure, List<Hymn>>> searchHymns(
      String languageCode, String version, String query);
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
      String languageCode, String version, String category);
}
