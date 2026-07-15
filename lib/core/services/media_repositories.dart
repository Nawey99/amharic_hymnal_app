import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_reference.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

/// Playable audio metadata for one hymn.
class AudioTrack {
  final int hymnNumber;
  final String title;
  final MediaReference source;
  final Duration? duration;

  const AudioTrack({
    required this.hymnNumber,
    required this.title,
    required this.source,
    this.duration,
  });

  String get url => source.value;
}

/// Resolves audio references supplied by hymn content metadata.
abstract interface class AudioMediaRepository {
  AudioTrack? getTrackForHymn(Hymn hymn);

  AudioTrack? getTrackForNumber(
    int hymnNumber, {
    String? title,
    String version,
    String? mediaSource,
  });

  Future<String?> cachedPathFor(Uri source);
}

/// Audio repository that never guesses a backend URL from a hymn number.
class AudioRepository implements AudioMediaRepository {
  final MediaCache _cache;

  AudioRepository({MediaCache? cache})
      : _cache = cache ?? LocalMediaCacheService.instance;

  @override
  AudioTrack? getTrackForHymn(Hymn hymn) {
    return getTrackForNumber(
      hymn.displayNumber,
      title: hymn.displayTitle,
      mediaSource: hymn.audioUrl,
    );
  }

  @override
  AudioTrack? getTrackForNumber(
    int hymnNumber, {
    String? title,
    String version = 'sda_new',
    String? mediaSource,
  }) {
    final reference = MediaReference.tryParse(mediaSource);
    if (reference == null) return null;

    return AudioTrack(
      hymnNumber: hymnNumber,
      title: title?.trim().isNotEmpty == true
          ? title!.trim()
          : 'Hymn #$hymnNumber',
      source: reference,
    );
  }

  @override
  Future<String?> cachedPathFor(Uri source) {
    return _cache.cachedPath(source, MediaType.audio);
  }
}

/// Resolves sheet-music references and their downloaded cache entries.
abstract interface class SheetMusicMediaRepository {
  bool hasMediaForHymn(Hymn hymn);

  List<MediaReference> referencesForHymn(Hymn hymn);

  Future<List<String>> getFilesForHymn(Hymn hymn);

  Future<List<String>> cachedFilesForSources(List<Uri> sources);
}

/// Sheet-music repository backed by content metadata and the local media cache.
class SheetMusicRepository implements SheetMusicMediaRepository {
  final MediaCache _cache;

  SheetMusicRepository({MediaCache? cache})
      : _cache = cache ?? LocalMediaCacheService.instance;

  @override
  bool hasMediaForHymn(Hymn hymn) => referencesForHymn(hymn).isNotEmpty;

  @override
  List<MediaReference> referencesForHymn(Hymn hymn) {
    final references = <MediaReference>[];
    final seen = <String>{};

    for (final value in hymn.sheetMusic ?? const <String>[]) {
      final reference = MediaReference.tryParse(value);
      if (reference == null || !seen.add(reference.uri.toString())) continue;
      references.add(reference);
    }

    return List<MediaReference>.unmodifiable(references);
  }

  /// Returns local paths for downloaded media and URLs for files still remote.
  @override
  Future<List<String>> getFilesForHymn(Hymn hymn) async {
    final files = <String>[];
    for (final reference in referencesForHymn(hymn)) {
      if (reference.isLocalFile) {
        files.add(reference.localPath);
        continue;
      }

      final cached = await _cache.cachedPath(
        reference.uri,
        MediaType.sheetMusic,
      );
      files.add(cached ?? reference.uri.toString());
    }
    return files;
  }

  /// Returns only explicit remote URLs present in hymn metadata.
  Future<List<Uri>> remoteSourcesForHymn(Hymn hymn) async {
    return referencesForHymn(hymn)
        .where((reference) => reference.isRemote)
        .map((reference) => reference.uri)
        .toList(growable: false);
  }

  @override
  Future<List<String>> cachedFilesForSources(List<Uri> sources) async {
    final paths = <String>[];
    for (final source in sources) {
      final cached = await _cache.cachedPath(source, MediaType.sheetMusic);
      if (cached != null) paths.add(cached);
    }
    return paths;
  }
}

/// Downloads and manages media files selected by the user.
abstract interface class MediaDownloadRepository {
  Future<bool> isDownloadAvailable(String mediaType, Uri? source);

  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required Uri source,
    void Function(int received, int? total)? onProgress,
  });

  Future<bool> deleteDownload(String mediaType, Uri source);

  Future<void> clearDownloads(String mediaType);
}

/// Media download repository backed by application-support storage.
class DownloadRepository implements MediaDownloadRepository {
  final MediaCache _cache;

  DownloadRepository({MediaCache? cache})
      : _cache = cache ?? LocalMediaCacheService.instance;

  @override
  Future<bool> isDownloadAvailable(String mediaType, Uri? source) async {
    return !kIsWeb &&
        source != null &&
        MediaReference.isDownloadableUri(source);
  }

  @override
  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required Uri source,
    void Function(int received, int? total)? onProgress,
  }) {
    return _cache.download(
      source,
      mediaType,
      onProgress: onProgress,
    );
  }

  @override
  Future<bool> deleteDownload(String mediaType, Uri source) {
    return _cache.delete(source, mediaType);
  }

  @override
  Future<void> clearDownloads(String mediaType) {
    return _cache.clearMediaType(mediaType);
  }
}

/// Stable cache directory names shared by download and playback features.
abstract final class MediaType {
  static const String audio = 'audio';
  static const String sheetMusic = 'sheet_music';
}
