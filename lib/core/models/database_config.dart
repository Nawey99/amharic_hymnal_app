// lib/core/models/database_config.dart
import 'package:amharic_hymnal_app/core/models/hymnal_version.dart';

class DatabaseConfig {
  final String languageCode; // e.g., 'am', 'en'
  final String version; // e.g., 'hymnal', 'hagerigna'
  final String filePath; // Path to the JSON file
  final String displayName; // Display name for the version in this language

  const DatabaseConfig({
    required this.languageCode,
    required this.version,
    required this.filePath,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseConfig &&
          runtimeType == other.runtimeType &&
          languageCode == other.languageCode &&
          version == other.version;

  @override
  int get hashCode => Object.hash(languageCode, version);
}

// Database registry - maps language+version to database files
class DatabaseRegistry {
  // Format: 'languageCode_version' -> DatabaseConfig
  static final Map<String, DatabaseConfig> _databases = {
    // Amharic databases
    'am_hymnal': const DatabaseConfig(
      languageCode: 'am',
      version: 'hymnal',
      filePath: 'assets/data/database/SDA_Hymnal.json',
      displayName: 'Hymnal',
    ),
    'am_sda_new': const DatabaseConfig(
      languageCode: 'am',
      version: HymnalVersions.sdaNew,
      filePath: 'assets/data/database/SDA_Hymnal.json',
      displayName: 'New SDA Hymnal',
    ),
    'am_sda_old': const DatabaseConfig(
      languageCode: 'am',
      version: HymnalVersions.sdaOld,
      filePath: 'assets/data/database/SDA_Hymnal.json',
      displayName: 'Old SDA Hymnal',
    ),
    'am_hagerigna': const DatabaseConfig(
      languageCode: 'am',
      version: 'hagerigna',
      filePath: 'assets/data/database/HagerignaData.json',
      displayName: 'Hagerigna',
    ),
    // English databases (example - add when available)
    // 'en_hymnal': const DatabaseConfig(
    //   languageCode: 'en',
    //   version: 'hymnal',
    //   filePath: 'assets/data/database/SDA_Hymnal_en.json',
    //   displayName: 'Hymnal',
    // ),
  };

  /// Get database config for a language and version
  static DatabaseConfig? getDatabase(String languageCode, String version) {
    final normalizedVersion = HymnalVersions.normalizeId(version);
    final key = '${languageCode}_$normalizedVersion';
    return _databases[key];
  }

  /// Get all available versions for a language
  static List<String> getAvailableVersions(String languageCode) {
    return _databases.values
        .where((db) => db.languageCode == languageCode)
        .map((db) => db.version)
        .toSet()
        .toList();
  }

  /// Get all available languages
  static List<String> getAvailableLanguages() {
    return _databases.values.map((db) => db.languageCode).toSet().toList();
  }

  /// Get display name for a version in a language
  static String getVersionDisplayName(String languageCode, String version) {
    final db = getDatabase(languageCode, version);
    return db?.displayName ?? version;
  }

  /// Register a new database (for dynamic discovery in the future)
  static void registerDatabase(DatabaseConfig config) {
    final key = '${config.languageCode}_${config.version}';
    _databases[key] = config;
  }

  /// Check if a database exists
  static bool hasDatabase(String languageCode, String version) {
    final key = '${languageCode}_$version';
    return _databases.containsKey(key);
  }
}
