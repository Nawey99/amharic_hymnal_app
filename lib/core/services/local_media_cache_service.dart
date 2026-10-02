import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:amharic_hymnal_app/core/error/network_failure.dart';
import 'package:amharic_hymnal_app/core/services/device_storage_service.dart';
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

  /// Bytes free where media is stored, or null when unknown.
  Future<int?> freeBytes();

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

  /// How long a download may go without receiving a byte before it is
  /// given up. Mobile connections can stop delivering without closing, and
  /// waiting for them would hold up every other file behind it.
  final Duration idleTimeout;

  /// The most a download may be when the content API gave no size for it.
  static const int maxBytesWithoutSize = 200 * 1024 * 1024;

  /// Partial files left by a run that was killed mid-download, cleared once
  /// before this run starts its own.
  Future<void>? _partialsCleared;

  /// How long to wait before the one retry of a request that could not
  /// reach the server.
  final Duration retryDelay;

  /// Makes the client for that retry, so it does not reuse a connection the
  /// first attempt found dead. Null when a client was supplied: the retry
  /// then goes through the same one.
  final http.Client Function()? _newClient;

  LocalMediaCacheService({
    http.Client? client,
    MediaCacheDirectoryProvider? directoryProvider,
    this.idleTimeout = const Duration(seconds: 30),
    this.retryDelay = const Duration(seconds: 1),
  })  : _client = client ?? http.Client(),
        _newClient = client == null ? http.Client.new : null,
        _directoryProvider =
            directoryProvider ?? getApplicationSupportDirectory;

  LocalMediaCacheService._()
      : _client = http.Client(),
        _newClient = http.Client.new,
        _directoryProvider = getApplicationSupportDirectory,
        idleTimeout = const Duration(seconds: 30),
        retryDelay = const Duration(seconds: 1);

  @override
  Future<int?> freeBytes() async {
    if (kIsWeb) return null;
    return DeviceStorageService.freeBytes(await _root());
  }

  /// Suffix of a file a background download has finished but the app has
  /// not yet checked against its checksum.
  static const stagedSuffix = '.unverified';

  /// Where a background download of [source] writes its file:
  /// `media_cache/<type>/incoming/<cache name>.unverified`. It only becomes
  /// cached media once [promoteStaged] has checked it.
  Future<File> stagingFileFor(MediaSource source, String mediaType) async {
    final target = await _fileFor(source, mediaType);
    return File(path.join(
      target.parent.path,
      'incoming',
      '${path.basename(target.path)}$stagedSuffix',
    ));
  }

  /// Checks a finished background download and moves it into the cache.
  ///
  /// The file is named after the checksum it must have, so this needs
  /// nothing else and also works for downloads that finished while the app
  /// was closed. A file that does not match is deleted. Returns whether the
  /// media is now cached.
  Future<bool> promoteStaged(File staged) async {
    if (!staged.path.endsWith(stagedSuffix) || !await staged.exists()) {
      return false;
    }
    final name = path
        .basename(staged.path)
        .substring(0, path.basename(staged.path).length - stagedSuffix.length);
    final target = File(path.join(staged.parent.parent.path, name));
    try {
      final match = _checksumFileName.firstMatch(name);
      final length = await staged.length();
      final valid = length > 0 &&
          (match == null ||
              (await sha256.bind(staged.openRead()).first).toString() ==
                  match.group(1));
      if (!valid) {
        await staged.delete();
        return false;
      }
      if (await target.exists()) {
        await staged.delete();
      } else {
        await staged.rename(target.path);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the file [staged] stands for is already in the cache, e.g.
  /// promoted by another follower of the same download.
  Future<bool> isPromoted(File staged) async {
    if (!staged.path.endsWith(stagedSuffix)) return false;
    final name = path.basename(staged.path);
    final target = File(path.join(
      staged.parent.parent.path,
      name.substring(0, name.length - stagedSuffix.length),
    ));
    return await target.exists() && await target.length() > 0;
  }

  /// Promotes every finished background download, e.g. after the app was
  /// closed while they ran. Returns how many were added to the cache.
  Future<int> promoteAllStaged() async {
    if (kIsWeb) return 0;
    var promoted = 0;
    final root = await _root();
    if (!await root.exists()) return 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File && entity.path.endsWith(stagedSuffix)) {
        if (await promoteStaged(entity)) promoted++;
      }
    }
    return promoted;
  }

  /// What a background download needs before it writes anything: partial
  /// files of a killed run gone, and the cache kept out of iOS backups.
  Future<void> prepareForTransfer() async {
    if (kIsWeb) return;
    await (_partialsCleared ??= _clearPartials());
    await DeviceStorageService.excludeFromBackup(await _root());
  }

  Future<Directory> _root() async =>
      Directory(path.join((await _directoryProvider()).path, 'media_cache'));

  /// Deletes `.part` files under the media cache. Only safe before this run
  /// has started any download, which is the only time it is called.
  Future<void> _clearPartials() async {
    try {
      final root = await _root();
      if (!await root.exists()) return;
      await for (final entity in root.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.part')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Tidying only; a file that cannot be removed now is tried next run.
    }
  }

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

    await (_partialsCleared ??= _clearPartials());
    final target = await _fileFor(source, mediaType);
    await target.parent.create(recursive: true);
    await DeviceStorageService.excludeFromBackup(await _root());
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.part',
    );

    IOSink? sink;
    http.Client? retryClient;
    try {
      // API download routes answer 302 to short-lived storage; the client
      // follows it. The redirect target is never stored.
      http.StreamedResponse response;
      try {
        response = await _client
            .send(http.Request('GET', uri))
            .timeout(const Duration(seconds: 45));
      } on Exception catch (error) {
        if (!isNetworkFailure(error)) rethrow;
        // Once more, on a new connection: a mobile signal drops for a moment,
        // and a connection kept from before the app was put away may be dead.
        // With no internet at all this fails again, and that is reported.
        await Future<void>.delayed(retryDelay);
        retryClient = _newClient?.call();
        response = await (retryClient ?? _client)
            .send(http.Request('GET', uri))
            .timeout(const Duration(seconds: 45));
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }

      final total = response.contentLength ?? source.sizeBytes;
      final digestSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(digestSink);
      sink = temporary.openWrite();
      var received = 0;
      // The promised size when there is one; otherwise a ceiling no hymn
      // file approaches, so a response that never ends cannot fill the
      // device.
      final ceiling = source.sizeBytes ?? maxBytesWithoutSize;
      await for (final chunk in response.stream.timeout(idleTimeout)) {
        received += chunk.length;
        if (received > ceiling) {
          throw MediaIntegrityException(
            uri,
            'Received more than the $ceiling bytes expected.',
          );
        }
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
    } finally {
      retryClient?.close();
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
    final cleanType = mediaType.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return Directory(path.join((await _root()).path, cleanType));
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
