import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// One edition's catalogue as last synced from the hymnal API.
class StoredEdition {
  static const schemaVersion = 1;

  final String code;

  /// The edition's change token when this copy was taken.
  final String? contentUpdatedAt;

  /// `serverTime` from the last completed sync: where the next delta starts.
  final String serverTime;

  /// When the whole edition was last downloaded rather than patched.
  final DateTime? fullSyncAt;

  /// API song objects by song ID, exactly as the API sent them.
  final Map<String, Map<String, dynamic>> songs;

  const StoredEdition({
    required this.code,
    required this.contentUpdatedAt,
    required this.serverTime,
    required this.songs,
    this.fullSyncAt,
  });

  /// Checksums of every audio track and sheet page this copy refers to.
  Set<String> get mediaChecksums {
    final checksums = <String>{};
    void add(Object? file) {
      final checksum = file is Map ? file['checksumSha256'] : null;
      if (checksum is String) checksums.add(checksum.toLowerCase());
    }

    for (final song in songs.values) {
      add(song['audio']);
      final sheetMusic = song['sheetMusic'];
      final pages = sheetMusic is Map ? sheetMusic['pages'] : null;
      if (pages is List) pages.forEach(add);
    }
    return checksums;
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'code': code,
        'contentUpdatedAt': contentUpdatedAt,
        'serverTime': serverTime,
        'fullSyncAt': fullSyncAt?.toUtc().toIso8601String(),
        'songs': songs.values.toList(),
      };

  /// Null when [json] is from another schema version or is malformed.
  static StoredEdition? fromJson(Object? json) {
    if (json is! Map<String, dynamic> ||
        json['schemaVersion'] != schemaVersion ||
        json['code'] is! String ||
        json['serverTime'] is! String ||
        json['songs'] is! List) {
      return null;
    }
    final songs = <String, Map<String, dynamic>>{};
    for (final song
        in (json['songs'] as List).whereType<Map<String, dynamic>>()) {
      final id = song['id'];
      if (id is String) songs[id] = song;
    }
    return StoredEdition(
      code: json['code'] as String,
      contentUpdatedAt: json['contentUpdatedAt'] as String?,
      serverTime: json['serverTime'] as String,
      fullSyncAt: DateTime.tryParse(json['fullSyncAt']?.toString() ?? ''),
      songs: songs,
    );
  }
}

/// Keeps synced editions on the device so they are available offline and
/// only changes need downloading next time.
abstract interface class EditionStore {
  Future<StoredEdition?> read(String key);

  Future<void> write(String key, StoredEdition edition);

  Future<void> delete(String key);

  /// Every stored edition, or null if any stored file cannot be read. Callers
  /// deciding what is safe to delete must treat null as "unknown".
  Future<List<StoredEdition>?> readAll();
}

typedef EditionStoreDirectoryProvider = Future<Directory> Function();

/// Stores each edition as a JSON file under application support.
class FileEditionStore implements EditionStore {
  FileEditionStore({EditionStoreDirectoryProvider? directoryProvider})
      : _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  final EditionStoreDirectoryProvider _directoryProvider;

  Future<Directory> _directory() async {
    final root = await _directoryProvider();
    return Directory(path.join(root.path, 'content_cache'));
  }

  Future<File> _fileFor(String key) async {
    final name = key.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return File(path.join((await _directory()).path, '$name.json'));
  }

  @override
  Future<List<StoredEdition>?> readAll() async {
    try {
      final directory = await _directory();
      if (!await directory.exists()) return const [];
      final editions = <StoredEdition>[];
      await for (final entity in directory.list()) {
        if (entity is! File || path.extension(entity.path) != '.json') continue;
        final edition =
            StoredEdition.fromJson(jsonDecode(await entity.readAsString()));
        if (edition == null) return null;
        editions.add(edition);
      }
      return editions;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StoredEdition?> read(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      return StoredEdition.fromJson(jsonDecode(await file.readAsString()));
    } catch (error) {
      // A damaged copy is only a cache: sync again from the API.
      if (kDebugMode) debugPrint('Ignoring unreadable edition $key: $error');
      return null;
    }
  }

  @override
  Future<void> write(String key, StoredEdition edition) async {
    final file = await _fileFor(key);
    await file.parent.create(recursive: true);
    // Write aside and rename, so a crash never leaves half a catalogue.
    final temporary =
        File('${file.path}.${DateTime.now().microsecondsSinceEpoch}.part');
    try {
      await temporary.writeAsString(jsonEncode(edition.toJson()), flush: true);
      await temporary.rename(file.path);
    } catch (_) {
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
  }

  @override
  Future<void> delete(String key) async {
    final file = await _fileFor(key);
    if (await file.exists()) await file.delete();
  }
}
