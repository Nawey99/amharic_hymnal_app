// lib/features/hymns/data/repositories/hymn_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:amharic_hymnal_app/core/error/exceptions.dart';
import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/mappers/hymn_mapper.dart';
import 'package:amharic_hymnal_app/core/services/search_engine.dart';

class HymnRepositoryImpl implements HymnRepository {
  final HymnLocalDataSource localDataSource;
  final SearchEngine _searchEngine = SearchEngine();

  HymnRepositoryImpl(this.localDataSource);

  /// The last mapped list per edition, reused while the data source hands
  /// back the same models. Number lookups, search and categories all read
  /// the whole edition, and mapping it again for each was wasted work.
  final Map<String, (List<HymnModel>, List<Hymn>)> _mapped = {};

  Future<List<Hymn>> _hymns(String languageCode, String version) async {
    final models = await localDataSource.getHymns(languageCode, version);
    final key = '$languageCode|$version';
    final cached = _mapped[key];
    if (cached != null && identical(cached.$1, models)) return cached.$2;
    final hymns = List<Hymn>.unmodifiable(HymnMapper.toDomainList(models));
    _mapped[key] = (models, hymns);
    return hymns;
  }

  /// The failure a reader can act on for [error].
  static Failure _failureFor(Object error) {
    // An edition with no bundled copy can only be loaded online.
    if (error is DatabaseNotFoundException) return const NetworkFailure();
    if (error is EditionUnavailableException) {
      return const EditionUnavailableFailure();
    }
    return CacheFailure(error.toString());
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
      String languageCode, String version) async {
    try {
      final hymns = await _hymns(languageCode, version);
      if (kDebugMode) {
        debugPrint(
            '✅ Retrieved ${hymns.length} hymns for $languageCode/$version');
      }
      return Right(hymns);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting hymns for $languageCode/$version: $e');
      }
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
      String languageCode, String version, int number) async {
    final List<Hymn> hymns;
    try {
      hymns = await _hymns(languageCode, version);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting hymn #$number: $e');
      }
      return Left(_failureFor(e));
    }
    for (final hymn in hymns) {
      if (hymn.displayNumber == number) return Right(hymn);
    }
    if (kDebugMode) {
      debugPrint('⚠️ Hymn #$number not found in $languageCode/$version');
    }
    return Left(NotFoundFailure(number));
  }

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
      String languageCode, String version, String query) async {
    try {
      final hymns = await _hymns(languageCode, version);

      // Use SearchEngine for pure, testable search logic with ranking
      final searchResults = _searchEngine.search(
        hymns: hymns,
        query: query,
      );

      // Extract hymns from search results (sorted by rank)
      final filtered = searchResults.map((result) => result.hymn).toList();

      if (kDebugMode) {
        debugPrint('🔍 Search "$query" returned ${filtered.length} results');
      }
      return Right(filtered);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error searching hymns: $e');
      }
      return Left(_failureFor(e));
    }
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
      String languageCode, String version, String category) async {
    try {
      final hymns = await _hymns(languageCode, version);
      final filtered = hymns.where((hymn) {
        return hymn.category != null &&
            hymn.category!.toLowerCase() == category.toLowerCase();
      }).toList();
      if (kDebugMode) {
        debugPrint('📂 Found ${filtered.length} hymns in category $category');
      }
      return Right(filtered);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting hymns by category: $e');
      }
      return Left(_failureFor(e));
    }
  }
}
