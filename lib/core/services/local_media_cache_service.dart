import 'dart:io';

import 'package:crypto/crypto.dart';
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

/// A remote media file, with whatever the content API says about it.
class MediaSource {
  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');
  static final RegExp _extensionPattern = RegExp(r'^\.[a-z0-9]{1,5}$');

  static const Map<String, String> _extensionsByContentType = {
    'audio/mp4': '.m4a',
    'audio/x-m4a': '.m4a',
    'audio/aac': '.aac',
    'audio/mpeg': '.mp3',
    'image/webp': '.webp',
    'image/png': '.png',
    'image/jpeg': '.jpg',
  };

  final Uri uri;

  /// Lower-case hex SHA-256 of the file, when known. Files with a checksum
  /// are verified after download and stored under it, so one file shared by
  /// several hymns or editions is downloaded once.
  final String? checksumSha256;
  final int? sizeBytes;

  /// Extension for the stored file, including the dot. Some players pick a
  /// decoder from it, and API download routes end in `/file`.
  final String? fileExtension;

  MediaSource(
    this.uri, {
    String? checksumSha256,
    this.sizeBytes,
    String? fileName,
    String? contentType,
  })  : checksumSha256 = _validChecksum(checksumSha256),
        fileExtension = _extensionFor(fileName, contentType, uri);

  bool get isVerifiable => checksumSha256 != null;

  static String? _validChecksum(String? value) {
    final checksum = value?.trim().toLowerCase();
    return checksum != null && _sha256Pattern.hasMatch(checksum)
        ? checksum
        : null;
  }

  static String? _extensionFor(String? fileName, String? contentType, Uri uri) {
    for (final name in [fileName, uri.path]) {
      if (name == null) continue;
      final extension = path.extension(name).toLowerCase();
      if (_extensionPattern.hasMatch(extension)) return extension;
    }
    final type = contentType?.split(';').first.trim().toLowerCase();
    return _extensionsByContentType[type];
  }
}

/// A download whose bytes did not match the checksum or size the content API
/// promised. The file is discarded, never cached.
class MediaIntegrityException implements Exception {
  final Uri source;
  final String message;

  const MediaIntegrityException(this.source, this.message);

  @override
  String toString() => 'MediaIntegrityException($source): $message';
}

/// Storage contract for downloaded audio and sheet-music files.
abstract interface class MediaCache {
  Future<String?> cachedPath(MediaSource source, String mediaType);

  Future<CachedMediaFile> download(
    MediaSource source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  });

  Future<bool> delete(MediaSource source, String mediaType);

  Future<void> clearMediaType(String mediaType);

  /// Deletes downloaded files stored under a checksum that is not in
  /// [checksums]. Files keyed by URL are left alone.
  Future<void> retainOnly(Set<String> checksums, List<String> mediaTypes);
}

/// Stores explicitly supplied HTTP(S) media URLs for offline use.
///
/// Downloads are written to a temporary file and atomically renamed only after
/// the response completes and, when the source has a checksum, only after the
/// bytes match it. Interrupted or corrupt downloads therefore never appear as
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
  Future<String?> cachedPath(MediaSource source, String mediaType) async {
    if (kIsWeb || !MediaReference.isDownloadableUri(source.uri)) return null;

    final file = await _fileFor(source, mediaType);
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length > 0 &&
        (source.sizeBytes == null || length == source.sizeBytes)) {
      return file.path;
    }

    await file.delete();
    return null;
  }

  @override
  Future<CachedMediaFile> download(
    MediaSource source,
    String mediaType, {
    void Function(int received, int? total)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Offline media downloads are unavailable on web.');
    }
    final uri = source.uri;
    if (!MediaReference.isDownloadableUri(uri)) {
      throw ArgumentError.value(uri, 'source', 'Expected an HTTP(S) URL.');
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
      // API download routes answer 302 to short-lived storage; the client
      // follows it. The redirect target is never stored.
      final request = http.Request('GET', uri);
      final response =
          await _client.send(request).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }

      final total = response.contentLength ?? source.sizeBytes;
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      sink = temporary.openWrite();
      var received = 0;
      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);
        hasher.add(chunk);
        onProgress?.call(received, total);
      }
      hasher.close();
      await sink.flush();
      await sink.close();
      sink = null;

      if (received == 0 ||
          (response.contentLength != null &&
              received != response.contentLength)) {
        throw const FileSystemException('Downloaded media is incomplete.');
      }
      if (source.sizeBytes != null && received != source.sizeBytes) {
        throw MediaIntegrityException(
          uri,
          'Expected ${source.sizeBytes} bytes, received $received.',
        );
      }
      final checksum = source.checksumSha256;
      if (checksum != null && digestSink.value.toString() != checksum) {
        throw MediaIntegrityException(uri, 'SHA-256 does not match.');
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
  Future<bool> delete(MediaSource source, String mediaType) async {
    if (kIsWeb || !MediaReference.isDownloadableUri(source.uri)) return false;
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

  static final RegExp _checksumFileName =
      RegExp(r'^([0-9a-f]{64})(\.[a-z0-9]{1,5})?$');

  @override
  Future<void> retainOnly(
      Set<String> checksums, List<String> mediaTypes) async {
    if (kIsWeb) return;
    for (final mediaType in mediaTypes) {
      final directory = await _directoryFor(mediaType);
      if (!await directory.exists()) continue;
      await for (final entity in directory.list()) {
        if (entity is! File) continue;
        final match = _checksumFileName.firstMatch(path.basename(entity.path));
        if (match != null && !checksums.contains(match.group(1))) {
          await entity.delete();
        }
      }
    }
  }

  Future<File> _fileFor(MediaSource source, String mediaType) async {
    final directory = await _directoryFor(mediaType);
    final checksum = source.checksumSha256;
    if (checksum != null) {
      return File(
        path.join(directory.path, '$checksum${source.fileExtension ?? ''}'),
      );
    }

    // Sources without a checksum are keyed by their URL.
    final uri = source.uri;
    final sourceName = path.basename(uri.path).replaceAll(
          RegExp(r'[^a-zA-Z0-9._-]'),
          '_',
        );
    final readableName = sourceName.isEmpty ? 'media' : sourceName;
    final fileName = '${_stableHash(uri.toString())}-$readableName';
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

class _DigestSink implements Sink<Digest> {
  Digest? _value;

  Digest get value => _value!;

  @override
  void add(Digest data) => _value = data;

  @override
  void close() {}
}
