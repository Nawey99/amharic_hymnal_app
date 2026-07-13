// lib/features/hymns/data/repositories/hymn_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

import 'package:amharic_hymnal_app/core/error/failures.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/mappers/hymn_mapper.dart';
import 'package:amharic_hymnal_app/core/services/search_engine.dart';

class HymnRepositoryImpl implements HymnRepository {
  final HymnLocalDataSource localDataSource;
  final SearchEngine _searchEngine = SearchEngine();

  HymnRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Hymn>>> getHymns(
      String languageCode, String version) async {
    try {
      final hymnModels = await localDataSource.getHymns(languageCode, version);
      // Verify we have cached data
      if (hymnModels.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No hymns found for $languageCode/$version');
        }
        return const Left(CacheFailure());
      }
      // Convert data models to domain entities
      final hymns = HymnMapper.toDomainList(hymnModels);
      if (kDebugMode) {
        debugPrint(
            '✅ Retrieved ${hymns.length} hymns for $languageCode/$version');
      }
      return Right(hymns);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting hymns for $languageCode/$version: $e');
      }
      // Check if it's a database not ready error
      if (e.toString().contains('not ready') ||
          e.toString().contains('initialization')) {
        return const Left(CacheFailure());
      }
      // Check if it's a cache issue
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Hymn?>> getHymnByNumber(
      String languageCode, String version, int number) async {
    try {
      final hymnModels = await localDataSource.getHymns(languageCode, version);
      if (hymnModels.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No hymns available to search for hymn #$number');
        }
        return const Left(CacheFailure());
      }
      final hymns = HymnMapper.toDomainList(hymnModels);
      try {
        final hymn = hymns.firstWhere(
          (h) => h.displayNumber == number,
        );
        return Right(hymn);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Hymn #$number not found in $languageCode/$version');
        }
        return Left(ServerFailure('Hymn #$number not found'));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting hymn #$number: $e');
      }
      if (e.toString().contains('not ready') ||
          e.toString().contains('initialization')) {
        return const Left(CacheFailure());
      }
      return Left(ServerFailure('Failed to retrieve hymn: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Hymn>>> searchHymns(
      String languageCode, String version, String query) async {
    try {
      final hymnModels = await localDataSource.getHymns(languageCode, version);
      if (hymnModels.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No hymns available for search');
        }
        return const Left(CacheFailure());
      }
      final hymns = HymnMapper.toDomainList(hymnModels);

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
      if (e.toString().contains('not ready') ||
          e.toString().contains('initialization')) {
        return const Left(CacheFailure());
      }
      return Left(ServerFailure('Search failed: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Hymn>>> getHymnsByCategory(
      String languageCode, String version, String category) async {
    try {
      final hymnModels = await localDataSource.getHymns(languageCode, version);
      if (hymnModels.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ No hymns available for category filter');
        }
        return const Left(CacheFailure());
      }
      final hymns = HymnMapper.toDomainList(hymnModels);
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
      if (e.toString().contains('not ready') ||
          e.toString().contains('initialization')) {
        return const Left(CacheFailure());
      }
      return Left(ServerFailure('Failed to get hymns by category: $e'));
    }
  }
}
