import 'dart:convert';

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/edition_store.dart';
import 'package:amharic_hymnal_app/features/hymns/data/datasources/hymn_local_data_source.dart';
import 'package:amharic_hymnal_app/features/hymns/data/models/hymn_model.dart';

/// An [EditionStore] in memory, round-tripping through JSON like the file
/// store so serialisation bugs still show.
class MemoryEditionStore implements EditionStore {
  final Map<String, String> files = {};

  @override
  Future<StoredEdition?> read(String key) async {
    final json = files[key];
    return json == null ? null : StoredEdition.fromJson(jsonDecode(json));
  }

  @override
  Future<void> write(String key, StoredEdition edition) async {
    files[key] = jsonEncode(edition.toJson());
  }

  @override
  Future<void> delete(String key) async => files.remove(key);

  @override
  Future<List<StoredEdition>?> readAll() async => [
        for (final json in files.values)
          StoredEdition.fromJson(jsonDecode(json))!,
      ];
}

/// A [MediaCache] in memory: files are "stored" by checksum (or URL).
class MemoryMediaCache implements MediaCache {
  final Map<String, int> stored = {};
  final Set<String> failing = {};
  final List<MediaSource> downloads = [];
  Set<String>? retained;

  static String keyOf(MediaSource source) =>
      source.checksumSha256 ?? source.uri.toString();

  @override
  Future<String?> cachedPath(MediaSource source, String mediaType) async =>
      stored.containsKey(keyOf(source)) ? '/cache/${keyOf(source)}' : null;

  @override
  Future<CachedMediaFile> download(
    MediaSource source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  }) async {
    downloads.add(source);
    if (failing.contains(keyOf(source))) {
      throw MediaIntegrityException(source.uri, 'SHA-256 does not match.');
    }
    final size = source.sizeBytes ?? 1;
    onProgress?.call(size, size);
    stored[keyOf(source)] = size;
    return CachedMediaFile(path: '/cache/${keyOf(source)}', bytes: size);
  }

  @override
  Future<bool> delete(MediaSource source, String mediaType) async =>
      stored.remove(keyOf(source)) != null;

  @override
  Future<void> clearMediaType(String mediaType) async => stored.clear();

  @override
  Future<void> retainOnly(
      Set<String> checksums, List<String> mediaTypes) async {
    retained = checksums;
    stored.removeWhere((key, _) =>
        RegExp(r'^[0-9a-f]{64}$').hasMatch(key) && !checksums.contains(key));
  }
}

/// Hymn content by version, or an error to throw, for tests above the data
/// layer.
class FakeHymnLocalDataSource implements HymnLocalDataSource {
  FakeHymnLocalDataSource([Map<String, List<HymnModel>>? content])
      : content = content ?? {};

  final Map<String, List<HymnModel>> content;
  Object? error;
  final List<String> requestedVersions = [];

  @override
  Future<List<HymnModel>> getHymns(String languageCode, String version) async {
    requestedVersions.add(version);
    final failure = error;
    if (failure != null) throw failure;
    return content[version] ?? const [];
  }
}

/// A small, readable SDA book for page tests: numbers 1..[count] titled
/// "መዝሙር n".
List<HymnModel> sampleHymns({int count = 5, String prefix = 'am-sda-2004'}) => [
      for (var n = 1; n <= count; n++)
        HymnModel(
          id: '$prefix-${n.toString().padLeft(4, '0')}',
          number: n,
          title: 'መዝሙር $n',
          lyrics: 'የመዝሙር $n ግጥም\nሁለተኛ መስመር',
          newHymnalNumber: n,
        ),
    ];
