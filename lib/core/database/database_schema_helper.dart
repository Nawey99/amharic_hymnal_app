// lib/core/database/database_schema_helper.dart
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper class for database schema creation and migration
class DatabaseSchemaHelper {
  final GeneratedDatabase database;

  DatabaseSchemaHelper(this.database);

  /// Create FTS5 virtual table for full-text search
  Future<void> createFtsTable({bool ifNotExists = false}) async {
    final ifNotExistsClause = ifNotExists ? 'IF NOT EXISTS' : '';
    await database.customStatement('''
      CREATE VIRTUAL TABLE $ifNotExistsClause hymns_fts USING fts5(
        title,
        lyrics,
        artist,
        song,
        new_hymnal_title,
        old_hymnal_title,
        new_hymnal_lyrics,
        english_title_old,
        old_hymnal_lyrics,
        content='hymns',
        content_rowid='rowid'
      )
    ''');
  }

  /// Create triggers to keep FTS table in sync with hymns table
  Future<void> createFtsTriggers({bool ifNotExists = false}) async {
    final ifNotExistsClause = ifNotExists ? 'IF NOT EXISTS' : '';

    // Insert trigger
    await database.customStatement('''
      CREATE TRIGGER $ifNotExistsClause hymns_fts_insert AFTER INSERT ON hymns BEGIN
        INSERT INTO hymns_fts(rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics)
        VALUES (new.rowid, new.title, new.lyrics, new.artist, new.song, new.new_hymnal_title, new.old_hymnal_title, new.new_hymnal_lyrics, new.english_title_old, new.old_hymnal_lyrics);
      END
    ''');

    // Delete trigger
    await database.customStatement('''
      CREATE TRIGGER $ifNotExistsClause hymns_fts_delete AFTER DELETE ON hymns BEGIN
        INSERT INTO hymns_fts(hymns_fts, rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics)
        VALUES('delete', old.rowid, old.title, old.lyrics, old.artist, old.song, old.new_hymnal_title, old.old_hymnal_title, old.new_hymnal_lyrics, old.english_title_old, old.old_hymnal_lyrics);
      END
    ''');

    // Update trigger
    await database.customStatement('''
      CREATE TRIGGER $ifNotExistsClause hymns_fts_update AFTER UPDATE ON hymns BEGIN
        INSERT INTO hymns_fts(hymns_fts, rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics)
        VALUES('delete', old.rowid, old.title, old.lyrics, old.artist, old.song, old.new_hymnal_title, old.old_hymnal_title, old.new_hymnal_lyrics, old.english_title_old, old.old_hymnal_lyrics);
        INSERT INTO hymns_fts(rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics)
        VALUES (new.rowid, new.title, new.lyrics, new.artist, new.song, new.new_hymnal_title, new.old_hymnal_title, new.new_hymnal_lyrics, new.english_title_old, new.old_hymnal_lyrics);
      END
    ''');
  }

  /// Populate FTS table with existing data
  Future<void> populateFtsTable() async {
    await database.customStatement('''
      INSERT INTO hymns_fts(rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics)
      SELECT rowid, title, lyrics, artist, song, new_hymnal_title, old_hymnal_title, new_hymnal_lyrics, english_title_old, old_hymnal_lyrics
      FROM hymns
    ''');
  }

  /// Create indexes for better query performance
  Future<void> createIndexes() async {
    await database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_language_version ON hymns(language_code, version)');
    await database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_number ON hymns(number)');
    await database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_favorites ON hymns(language_code, version, is_favorite) WHERE is_favorite = 1');
    await database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_language_version_number ON hymns(language_code, version, number)');
  }

  /// Initialize schema for new database (onCreate)
  Future<void> initializeSchema(Migrator m) async {
    await m.createAll();
    await createFtsTable();
    await createFtsTriggers();
    await createIndexes();
  }

  /// Upgrade schema from version 1 to 2
  Future<void> upgradeFromV1() async {
    try {
      await createFtsTable(ifNotExists: true);
      await populateFtsTable();
      await createFtsTriggers(ifNotExists: true);
    } catch (e) {
      // FTS table might already exist, ignore error
    }
  }

  /// Upgrade schema from version 2 to 3 - Add is_favorite column
  Future<void> upgradeFromV2() async {
    try {
      // Add is_favorite column if it doesn't exist
      await database.customStatement('''
        ALTER TABLE hymns ADD COLUMN is_favorite INTEGER NOT NULL DEFAULT 0
      ''');

      // Migrate existing favorites from SharedPreferences to database
      await _migrateFavoritesFromSharedPreferences();
    } catch (e) {
      // Column might already exist, ignore error
    }
  }

  /// Upgrade schema from version 3 to 4 - Add old/new hymnal number metadata.
  Future<void> upgradeFromV3() async {
    try {
      await database.customStatement('''
        ALTER TABLE hymns ADD COLUMN new_hymnal_number INTEGER
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }

    try {
      await database.customStatement('''
        ALTER TABLE hymns ADD COLUMN old_hymnal_number INTEGER
      ''');
    } catch (e) {
      // Column might already exist, ignore error
    }

    await createIndexes();
  }

  /// Migrate favorites from SharedPreferences to database
  Future<void> _migrateFavoritesFromSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteHymns = prefs.getStringList('favorite_hymns') ?? [];

      if (favoriteHymns.isNotEmpty) {
        // Update database with favorites
        for (final hymnNumberStr in favoriteHymns) {
          final hymnNumber = int.tryParse(hymnNumberStr);
          if (hymnNumber != null) {
            await database.customStatement(
              'UPDATE hymns SET is_favorite = 1 WHERE number = ?',
              [Variable.withInt(hymnNumber)],
            );
          }
        }
      }
    } catch (e) {
      // If migration fails, continue - favorites will be managed going forward
    }
  }
}
