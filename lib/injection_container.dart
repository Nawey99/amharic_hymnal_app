// lib/injection_container.dart
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, kIsWeb;
import 'package:get_it/get_it.dart';

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/database/database_helper.dart';
import 'package:amharic_hymnal_app/core/database/database_migration.dart';
import 'package:amharic_hymnal_app/core/services/settings_service.dart';
import 'package:amharic_hymnal_app/core/services/cache_service.dart';
import 'package:amharic_hymnal_app/core/services/background_image_service.dart';
import 'package:amharic_hymnal_app/core/services/font_size_service.dart';
import 'package:amharic_hymnal_app/core/domain/repositories/settings_repository.dart';
import 'package:amharic_hymnal_app/core/data/repositories/settings_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/repositories/hymn_repository_impl.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/repositories/hymn_repository.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymn_by_number.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/search_hymns.dart'
    as usecases;
import 'package:amharic_hymnal_app/features/hymns/domain/usecases/get_hymns_by_category.dart';
import 'package:amharic_hymnal_app/features/hymns/presentation/bloc/hymns_bloc.dart';

final sl = GetIt.instance;
bool _databaseInitializationStarted = false;

Future<void> initDependencies({bool startDatabase = true}) async {
  try {
    // Initialize settings service
    await SettingsService.init();

    // Initialize cache service
    await CacheService.init();

    // Initialize BackgroundImageService with current setting
    BackgroundImageService()
        .initialize(SettingsService.getBackgroundImageEnabled());

    // Initialize FontSizeService with current setting (clamped to valid range)
    FontSizeService().initialize(SettingsService.getFontSize());

    // Initialize database with Drift (works on all platforms including web)
    // Run migration in background to avoid blocking app startup
    if (startDatabase &&
        ContentApiConfig.enableLocalContentDatabase &&
        !_databaseInitializationStarted) {
      _databaseInitializationStarted = true;
      unawaited(_initializeDatabaseAsync());
    } else if (kDebugMode &&
        startDatabase &&
        !ContentApiConfig.enableLocalContentDatabase) {
      debugPrint(
        'ℹ️ Local content database migration disabled; using content API/local JSON fallback.',
      );
    }
  } catch (e) {
    // Only rethrow critical errors (like SettingsService failure)
    rethrow;
  }

  // Data sources
  // Register data source by its abstract contract so it can be mocked in tests
  if (!sl.isRegistered<HymnLocalDataSource>()) {
    sl.registerLazySingleton<HymnLocalDataSource>(() => LocalDataSource());
  }

  // Repositories
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl());
  }
  if (!sl.isRegistered<HymnRepository>()) {
    sl.registerLazySingleton<HymnRepository>(() => HymnRepositoryImpl(sl()));
  }

  // Use cases
  if (!sl.isRegistered<GetHymns>()) {
    sl.registerLazySingleton<GetHymns>(() => GetHymns(sl()));
  }
  if (!sl.isRegistered<GetHymnByNumber>()) {
    sl.registerLazySingleton<GetHymnByNumber>(() => GetHymnByNumber(sl()));
  }
  if (!sl.isRegistered<usecases.SearchHymns>()) {
    sl.registerLazySingleton<usecases.SearchHymns>(
        () => usecases.SearchHymns(sl()));
  }
  if (!sl.isRegistered<GetHymnsByCategory>()) {
    sl.registerLazySingleton<GetHymnsByCategory>(
        () => GetHymnsByCategory(sl()));
  }

  // BLoC
  if (!sl.isRegistered<HymnsBloc>()) {
    sl.registerFactory<HymnsBloc>(() => HymnsBloc(
          getHymns: sl(),
          searchHymns: sl<usecases.SearchHymns>(),
          getHymnByNumber: sl(),
          settingsRepository: sl(),
        ));
  }
}

// Initialize database asynchronously without blocking app startup
Future<void> _initializeDatabaseAsync() async {
  // On web, wait a bit for sql.js to load (reduced delay for faster startup)
  // On other platforms, start immediately
  if (kIsWeb) {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  final dbHelper = DatabaseHelper.instance;

  try {
    // Initialize Drift database - works on web via IndexedDB automatically
    // The database is lazy, so accessing it won't block, but we need to trigger initialization
    // On web, we need to ensure sql.js is loaded first
    try {
      // Try to access database to trigger lazy initialization
      // This will fail on web if sql.js isn't loaded, so we catch and retry
      final _ = dbHelper.database;
      dbHelper.markInitialized();

      if (kDebugMode) {
        debugPrint('✅ Database instance initialized');
      }
    } catch (e) {
      // On web, if sql.js isn't ready, wait a bit and retry with optimized delays
      if (kIsWeb &&
          (e.toString().contains('sql.js') || e.toString().contains('sqljs'))) {
        if (kDebugMode) {
          debugPrint('⏳ Waiting for sql.js to load...');
        }
        // Wait up to 10 seconds for sql.js with optimized exponential backoff
        bool initialized = false;
        for (int i = 0; i < 50; i++) {
          // Start with 50ms, then gradually increase: 50ms, 100ms, 150ms, 200ms, etc.
          final delayMs = (50 + (i * 10)).clamp(50, 500);
          await Future.delayed(Duration(milliseconds: delayMs));
          try {
            final _ = dbHelper.database;
            dbHelper.markInitialized();
            initialized = true;
            if (kDebugMode) {
              debugPrint('✅ Database initialized after waiting for sql.js');
            }
            break;
          } catch (e2) {
            if (i == 49) {
              // Last attempt failed
              throw Exception('sql.js not available after 10 seconds: $e2');
            }
          }
        }
        if (!initialized) {
          throw Exception('sql.js initialization failed after retries');
        }
      } else {
        rethrow;
      }
    }

    // Now that database instance is initialized, run migration
    // Migration will populate the database and then we mark it as ready
    try {
      if (kDebugMode) {
        debugPrint('🔄 Starting database migration...');
      }

      final migration = DatabaseMigration();
      await migration.migrate().timeout(
        const Duration(seconds: 180), // Increased timeout for large datasets
        onTimeout: () {
          if (kDebugMode) {
            debugPrint('⚠️ Migration timed out after 180 seconds');
          }
          throw TimeoutException('Migration timed out after 180 seconds');
        },
      );

      // Verify migration completed successfully by checking if database has data
      final isEmpty = await dbHelper.isEmpty();
      if (isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ Migration completed but database appears empty');
        }
        // Still mark as ready - empty database is valid state
      }

      dbHelper.markReady();
      if (kDebugMode) {
        debugPrint('✅ Database migration completed successfully');
        debugPrint('✅ Database is now ready for queries');
      }
    } catch (e) {
      // Check if database already has data despite migration error
      try {
        final isEmpty = await dbHelper.isEmpty();
        if (!isEmpty) {
          // Database has data, mark as ready even if migration had errors
          dbHelper.markReady();
          if (kDebugMode) {
            debugPrint('✅ Database already has data, marking as ready');
            debugPrint('ℹ️ Migration error was non-critical: $e');
          }
        } else {
          // Database is empty and migration failed
          final errorMsg = 'Migration failed: $e';
          dbHelper.markFailed(errorMsg);
          if (kDebugMode) {
            debugPrint('❌ Migration failed and database is empty: $e');
            debugPrint('ℹ️ Database may need manual migration');
          }
        }
      } catch (e2) {
        // Could not check database status
        final errorMsg =
            'Could not verify database status: $e2. Original error: $e';
        dbHelper.markFailed(errorMsg);
        if (kDebugMode) {
          debugPrint('❌ Could not check database status: $e2');
          debugPrint('❌ Original migration error: $e');
        }
      }
    }
  } catch (e) {
    // Database initialization failed at the database level
    final errorMsg = 'Database initialization failed: $e';
    dbHelper.markFailed(errorMsg);
    if (kDebugMode) {
      debugPrint('❌ Database initialization failed: $e');
      debugPrint('⚠️ App will continue with limited functionality.');
    }
    // Don't rethrow - allow app to continue
  }
}
