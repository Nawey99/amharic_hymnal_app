// lib/core/database/database_migration.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:amharic_hymnal_app/core/constants/asset_paths.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:amharic_hymnal_app/core/database/database_helper.dart';
import 'package:amharic_hymnal_app/core/services/cache_service.dart';
import 'package:amharic_hymnal_app/core/database/parsers/hagerigna_parser.dart';
import 'package:amharic_hymnal_app/core/database/parsers/sda_parser.dart';

class DatabaseMigration {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Migrate JSON data to SQLite
  Future<void> migrate() async {
    try {
      // Don't wait for readiness - migration is what makes the database ready
      // Just ensure the database instance is initialized (not ready, but initialized)
      // The database should be initialized before migration is called

      // Check if database is already populated
      // Use a direct query to avoid readiness check
      bool isEmpty;
      try {
        isEmpty = await _dbHelper.database.isEmpty();
      } catch (e) {
        // If database query fails, assume it's empty and proceed with migration
        if (kDebugMode) {
          debugPrint(
              '⚠️ Could not check if database is empty, assuming empty: $e');
        }
        isEmpty = true;
      }

      if (!isEmpty) {
        // Database already has data, verify and mark cache
        if (kDebugMode) {
          debugPrint('ℹ️ Database already has data, verifying cache status...');
        }
        await _verifyAndMarkCache();
        return;
      }

      if (kDebugMode) {
        debugPrint('🔄 Starting database migration...');
      }

      // Migrate Hagerigna data
      await _migrateHagerigna();
      // Verify data was inserted before marking cache
      final hagerignaCount = await _verifyDataInserted('am', 'hagerigna');
      if (hagerignaCount > 0) {
        await CacheService.markCacheUpdated('am', 'hagerigna');
        if (kDebugMode) {
          debugPrint('✅ Hagerigna migration completed: $hagerignaCount hymns');
        }
      }

      // Migrate SDA data
      await _migrateSDA();
      // Verify data was inserted before marking cache
      final hymnalCount = await _verifyDataInserted('am', 'hymnal');
      if (hymnalCount > 0) {
        await CacheService.markCacheUpdated('am', 'hymnal');
        if (kDebugMode) {
          debugPrint('✅ SDA Hymnal migration completed: $hymnalCount hymns');
        }
      }

      if (kDebugMode) {
        final totalCount = await _dbHelper.database.customSelect(
          'SELECT COUNT(*) as count FROM hymns',
          readsFrom: {_dbHelper.database.hymns},
        ).getSingle();
        debugPrint(
            '✅ Total hymns in database: ${totalCount.read<int>('count')}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Migration error: $e');
      }
      rethrow; // Let injection_container handle it
    }
  }

  /// Verify data exists and mark cache accordingly
  Future<void> _verifyAndMarkCache() async {
    try {
      final hagerignaCount = await _verifyDataInserted('am', 'hagerigna');
      if (hagerignaCount > 0) {
        await CacheService.markCacheUpdated('am', 'hagerigna');
      }

      final hymnalCount = await _verifyDataInserted('am', 'hymnal');
      if (hymnalCount > 0) {
        await CacheService.markCacheUpdated('am', 'hymnal');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error verifying cache: $e');
      }
    }
  }

  /// Verify data was inserted for a language/version
  Future<int> _verifyDataInserted(String languageCode, String version) async {
    try {
      final hymns = await _dbHelper.getHymns(languageCode, version);
      return hymns.length;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error verifying data for $languageCode/$version: $e');
      }
      return 0;
    }
  }

  /// Migrate Hagerigna JSON to SQLite
  Future<void> _migrateHagerigna() async {
    if (kDebugMode) {
      debugPrint('🔄 Migrating Hagerigna data...');
    }
    try {
      final String response = await rootBundle.loadString(
        AssetPaths.hagerignaHymnalJson,
      );
      final dynamic jsonData = json.decode(response);

      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('resources')) {
        final hymns = HagerignaParser.parse(jsonData);
        if (kDebugMode) {
          debugPrint('📦 Parsed ${hymns.length} Hagerigna hymns');
        }
        await _insertHymns(hymns, 'am', 'hagerigna');
      } else {
        throw Exception('Invalid Hagerigna JSON format: missing resources');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Hagerigna migration failed: $e');
      }
      rethrow;
    }
  }

  /// Migrate SDA JSON to SQLite
  Future<void> _migrateSDA() async {
    if (kDebugMode) {
      debugPrint('🔄 Migrating SDA Hymnal data...');
    }
    try {
      final String response = await rootBundle.loadString(
        AssetPaths.sdaHymnalJson,
      );
      final dynamic jsonData = json.decode(response);

      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('resources')) {
        final hymns = SdaParser.parse(jsonData);
        if (kDebugMode) {
          debugPrint('📦 Parsed ${hymns.length} SDA Hymnal hymns');
        }
        await _insertHymns(hymns, 'am', 'hymnal');
      } else {
        throw Exception('Invalid SDA JSON format: missing resources');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ SDA migration failed: $e');
      }
      rethrow;
    }
  }

  /// Insert hymns into database
  Future<void> _insertHymns(
    List<Map<String, dynamic>> hymns,
    String languageCode,
    String version,
  ) async {
    if (hymns.isEmpty) {
      if (kDebugMode) {
        debugPrint('⚠️ No hymns to insert for $languageCode/$version');
      }
      return;
    }

    // Database should be initialized at this point (migration is called after initialization)
    // No need to wait for readiness - we're in the process of making it ready

    // Convert sheet_music list to JSON string if needed
    final dbHymns = hymns.map((hymn) {
      final dbHymn = Map<String, dynamic>.from(hymn);
      // Handle sheet_music if it's a list
      if (dbHymn.containsKey('sheet_music') && dbHymn['sheet_music'] is List) {
        dbHymn['sheet_music'] = json.encode(dbHymn['sheet_music']);
      }
      return dbHymn;
    }).toList();

    if (kDebugMode) {
      debugPrint('💾 Inserting ${dbHymns.length} hymns into database...');
    }

    try {
      await _dbHelper.insertHymns(dbHymns);

      if (kDebugMode) {
        debugPrint('✅ Successfully inserted ${dbHymns.length} hymns');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to insert hymns: $e');
      }
      rethrow;
    }
  }
}
