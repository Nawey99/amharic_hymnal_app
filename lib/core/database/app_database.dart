// lib/core/database/app_database.dart
import 'package:drift/drift.dart';
// Conditional imports for native vs web
// Conditional imports must use relative paths, not package imports
// ignore: always_use_package_imports
import 'database_stub.dart'
    if (dart.library.io) 'database_native.dart'
    if (dart.library.html) 'database_web.dart';
import 'package:amharic_hymnal_app/core/database/database_schema_helper.dart';

part 'app_database.g.dart';

// Hymns table definition
class Hymns extends Table {
  TextColumn get hymnId => text().named('id').withLength(min: 1, max: 100)();
  TextColumn get languageCode => text().withLength(min: 2, max: 10)();
  TextColumn get version => text().withLength(min: 1, max: 50)();
  IntColumn get number => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get lyrics => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get audioUrl => text().nullable().named('audio_url')();
  TextColumn get sheetMusic => text().nullable().named('sheet_music')();
  // Hagerigna fields
  TextColumn get artist => text().nullable()();
  TextColumn get song => text().nullable()();
  // SDA fields
  TextColumn get newHymnalTitle =>
      text().nullable().named('new_hymnal_title')();
  TextColumn get oldHymnalTitle =>
      text().nullable().named('old_hymnal_title')();
  TextColumn get newHymnalLyrics =>
      text().nullable().named('new_hymnal_lyrics')();
  TextColumn get englishTitleOld =>
      text().nullable().named('english_title_old')();
  TextColumn get oldHymnalLyrics =>
      text().nullable().named('old_hymnal_lyrics')();
  IntColumn get newHymnalNumber =>
      integer().nullable().named('new_hymnal_number')();
  IntColumn get oldHymnalNumber =>
      integer().nullable().named('old_hymnal_number')();
  IntColumn get createdAt => integer().named('created_at')();
  IntColumn get updatedAt => integer().named('updated_at')();
  BoolColumn get isFavorite =>
      boolean().named('is_favorite').withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {hymnId};
}

@DriftDatabase(tables: [Hymns])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    final schemaHelper = DatabaseSchemaHelper(this);
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await schemaHelper.initializeSchema(m);
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await schemaHelper.upgradeFromV1();
        }
        if (from <= 2) {
          await schemaHelper.upgradeFromV2();
        }
        if (from <= 3) {
          await schemaHelper.upgradeFromV3();
        }
      },
    );
  }

  // Get all hymns for a language and version
  Future<List<Hymn>> getHymns(String languageCode, String version) {
    return (select(hymns)
          ..where((h) =>
              h.languageCode.equals(languageCode) & h.version.equals(version))
          ..orderBy([
            (h) => OrderingTerm(expression: h.number, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // Get hymn by ID
  Future<Hymn?> getHymnById(String hymnId) {
    return (select(hymns)..where((h) => h.hymnId.equals(hymnId)))
        .getSingleOrNull();
  }

  // Get hymn by number
  Future<Hymn?> getHymnByNumber(
      String languageCode, String version, int number) {
    return (select(hymns)
          ..where((h) =>
              h.languageCode.equals(languageCode) &
              h.version.equals(version) &
              h.number.equals(number)))
        .getSingleOrNull();
  }

  // Full-text search using FTS5
  Future<List<Hymn>> searchHymns(
      String languageCode, String version, String query) async {
    // Escape special characters in query for FTS5 and prepare for MATCH
    final escapedQuery = query.replaceAll('"', '""').replaceAll("'", "''");
    // Build FTS5 query - search across all text fields with prefix matching
    final ftsQuery = '$escapedQuery*';

    final rows = await customSelect(
      '''
      SELECT h.* FROM hymns h
      INNER JOIN hymns_fts fts ON h.rowid = fts.rowid
      WHERE h.language_code = ? AND h.version = ?
      AND fts MATCH ?
      ORDER BY bm25(fts) ASC, h.number ASC
      LIMIT 100
      ''',
      variables: [
        Variable.withString(languageCode),
        Variable.withString(version),
        Variable.withString(ftsQuery)
      ],
      readsFrom: {hymns},
    ).get();

    return rows.map((row) {
      final data = row.data;
      return Hymn(
        hymnId: data['id'] as String,
        languageCode: data['language_code'] as String,
        version: data['version'] as String,
        number: data['number'] as int?,
        title: data['title'] as String?,
        lyrics: data['lyrics'] as String?,
        category: data['category'] as String?,
        audioUrl: data['audio_url'] as String?,
        sheetMusic: data['sheet_music'] as String?,
        artist: data['artist'] as String?,
        song: data['song'] as String?,
        newHymnalTitle: data['new_hymnal_title'] as String?,
        oldHymnalTitle: data['old_hymnal_title'] as String?,
        newHymnalLyrics: data['new_hymnal_lyrics'] as String?,
        englishTitleOld: data['english_title_old'] as String?,
        oldHymnalLyrics: data['old_hymnal_lyrics'] as String?,
        newHymnalNumber: data['new_hymnal_number'] as int?,
        oldHymnalNumber: data['old_hymnal_number'] as int?,
        createdAt: data['created_at'] as int,
        updatedAt: data['updated_at'] as int,
        isFavorite: (data['is_favorite'] as int?) == 1,
      );
    }).toList();
  }

  // Get hymns by category
  Future<List<Hymn>> getHymnsByCategory(
      String languageCode, String version, String category) {
    return (select(hymns)
          ..where((h) =>
              h.languageCode.equals(languageCode) &
              h.version.equals(version) &
              h.category.equals(category))
          ..orderBy([
            (h) => OrderingTerm(expression: h.number, mode: OrderingMode.asc)
          ]))
        .get();
  }

  // Insert hymn
  Future<int> insertHymn(HymnsCompanion hymn) {
    return into(hymns).insert(hymn);
  }

  // Insert multiple hymns
  Future<void> insertHymns(List<HymnsCompanion> hymnList) {
    return batch((batch) {
      batch.insertAll(hymns, hymnList);
    });
  }

  // Clear all hymns for a language/version
  Future<void> clearHymns(String languageCode, String version) {
    return (delete(hymns)
          ..where((h) =>
              h.languageCode.equals(languageCode) & h.version.equals(version)))
        .go();
  }

  // Check if database is empty
  Future<bool> isEmpty() {
    return customSelect('SELECT COUNT(*) as count FROM hymns',
            readsFrom: {hymns})
        .getSingle()
        .then((row) => row.read<int>('count') == 0);
  }
}

LazyDatabase _openConnection() {
  return openConnection();
}
