import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:amharic_hymnal_app/core/services/media_reference.dart';

typedef MediaCacheDirectoryProvider = Future<Directory> Function();

/// Information about a media file stored in the application cache.
class CachedMediaFile {
  final String path;
  final int bytes;

  const CachedMediaFile({
    required this.path,
    required this.bytes,
  });
}

/// Storage contract for downloaded audio and sheet-music files.
abstract interface class MediaCache {
  Future<String?> cachedPath(Uri source, String mediaType);

  Future<CachedMediaFile> download(
    Uri source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  });

  Future<bool> delete(Uri source, String mediaType);

  Future<void> clearMediaType(String mediaType);
}

/// Stores explicitly supplied HTTP(S) media URLs for offline use.
///
/// Downloads are written to a temporary file and atomically renamed only after
/// the response completes. Interrupted downloads therefore never appear as
/// valid cached media.
class LocalMediaCacheService implements MediaCache {
  static final LocalMediaCacheService instance = LocalMediaCacheService._();

  final http.Client _client;
  final MediaCacheDirectoryProvider _directoryProvider;

  LocalMediaCacheService({
    http.Client? client,
    MediaCacheDirectoryProvider? directoryProvider,
  })  : _client = client ?? http.Client(),
        _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  LocalMediaCacheService._()
      : _client = http.Client(),
        _directoryProvider = getApplicationSupportDirectory;

  @override
  Future<String?> cachedPath(Uri source, String mediaType) async {
    if (kIsWeb || !MediaReference.isDownloadableUri(source)) return null;

    final file = await _fileFor(source, mediaType);
    if (!await file.exists()) return null;
    if (await file.length() > 0) return file.path;

    await file.delete();
    return null;
  }

  @override
  Future<CachedMediaFile> download(
    Uri source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Offline media downloads are unavailable on web.');
    }
    if (!MediaReference.isDownloadableUri(source)) {
      throw ArgumentError.value(source, 'source', 'Expected an HTTP(S) URL.');
    }

    final existingPath = await cachedPath(source, mediaType);
    if (existingPath != null) {
      final existing = File(existingPath);
      return CachedMediaFile(
          path: existingPath, bytes: await existing.length());
    }

    final target = await _fileFor(source, mediaType);
    await target.parent.create(recursive: true);
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.part',
    );

    IOSink? sink;
    try {
      final request = http.Request('GET', source);
      final response =
          await _client.send(request).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: source);
      }

      sink = temporary.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        onProgress?.call(received, response.contentLength);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (received == 0 ||
          (response.contentLength != null &&
              received != response.contentLength)) {
        throw const FileSystemException('Downloaded media is incomplete.');
      }

      if (await target.exists()) {
        await temporary.delete();
        return CachedMediaFile(
          path: target.path,
          bytes: await target.length(),
        );
      }

      final completed = await temporary.rename(target.path);
      return CachedMediaFile(path: completed.path, bytes: received);
    } catch (_) {
      if (sink != null) await sink.close();
      if (await temporary.exists()) await temporary.delete();
      rethrow;
    }
  }

  @override
  Future<bool> delete(Uri source, String mediaType) async {
    if (kIsWeb || !MediaReference.isDownloadableUri(source)) return false;
    final file = await _fileFor(source, mediaType);
    if (!await file.exists()) return false;
    await file.delete();
    return true;
  }

  @override
  Future<void> clearMediaType(String mediaType) async {
    if (kIsWeb) return;
    final directory = await _directoryFor(mediaType);
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  Future<File> _fileFor(Uri source, String mediaType) async {
    final directory = await _directoryFor(mediaType);
    final sourceName = path.basename(source.path).replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
    final readableName = sourceName.isEmpty ? 'media' : sourceName;
    final fileName = '${_stableHash(source.toString())}-$readableName';
    return File(path.join(directory.path, fileName));
  }

  Future<Directory> _directoryFor(String mediaType) async {
    final root = await _directoryProvider();
    final cleanType = mediaType.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return Directory(path.join(root.path, 'media_cache', cleanType));
  }

  String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
