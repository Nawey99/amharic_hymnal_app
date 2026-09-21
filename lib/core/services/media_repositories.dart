import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_reference.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';

/// A download size for people, e.g. `1.6 MB`.
String formatMediaSize(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).ceil()} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// The cache key and integrity data for a file described by the content API.
MediaSource mediaSourceForFile(HymnMediaFile file) => MediaSource(
      Uri.parse(file.url),
      checksumSha256: file.checksumSha256,
      sizeBytes: file.sizeBytes,
      fileName: file.fileName,
      contentType: file.contentType,
    );

/// The source for [uri], using [file]'s details when they describe it.
MediaSource mediaSourceForUri(Uri uri, [HymnMediaFile? file]) =>
    file != null && file.url == uri.toString()
        ? mediaSourceForFile(file)
        : MediaSource(uri);

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

  Future<String?> cachedPathFor(MediaSource source);
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
  Future<String?> cachedPathFor(MediaSource source) {
    return _cache.cachedPath(source, MediaType.audio);
  }
}

/// One sheet-music page, either already on the device or still remote.
class ResolvedMediaFile {
  final String? localPath;
  final MediaSource? remote;

  const ResolvedMediaFile.local(String this.localPath) : remote = null;

  const ResolvedMediaFile.remote(MediaSource this.remote) : localPath = null;

  bool get isLocal => localPath != null;
}

/// Resolves sheet-music references and their downloaded cache entries.
abstract interface class SheetMusicMediaRepository {
  bool hasMediaForHymn(Hymn hymn);

  List<MediaReference> referencesForHymn(Hymn hymn);

  /// Every page in order, as a downloaded file when one is cached.
  Future<List<ResolvedMediaFile>> resolveFilesForHymn(Hymn hymn);
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

  @override
  Future<List<ResolvedMediaFile>> resolveFilesForHymn(Hymn hymn) async {
    final pagesByUrl = {
      for (final page in hymn.sheetPages ?? const <HymnSheetPage>[])
        page.file.url: page.file,
    };

    final files = <ResolvedMediaFile>[];
    for (final reference in referencesForHymn(hymn)) {
      if (reference.isLocalFile) {
        files.add(ResolvedMediaFile.local(reference.localPath));
        continue;
      }

      final source = mediaSourceForUri(
        reference.uri,
        pagesByUrl[reference.uri.toString()],
      );
      final cached = await _cache.cachedPath(source, MediaType.sheetMusic);
      files.add(cached != null
          ? ResolvedMediaFile.local(cached)
          : ResolvedMediaFile.remote(source));
    }
    return files;
  }
}

/// Downloads and manages media files selected by the user.
abstract interface class MediaDownloadRepository {
  Future<bool> isDownloadAvailable(String mediaType, MediaSource? source);

  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required MediaSource source,
    void Function(int received, int? total)? onProgress,
  });

  Future<bool> deleteDownload(String mediaType, MediaSource source);

  Future<void> clearDownloads(String mediaType);
}

/// Media download repository backed by application-support storage.
class DownloadRepository implements MediaDownloadRepository {
  final MediaCache _cache;

  DownloadRepository({MediaCache? cache})
      : _cache = cache ?? LocalMediaCacheService.instance;

  @override
  Future<bool> isDownloadAvailable(
    String mediaType,
    MediaSource? source,
  ) async {
    return !kIsWeb &&
        source != null &&
        MediaReference.isDownloadableUri(source.uri);
  }

  @override
  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required MediaSource source,
    void Function(int received, int? total)? onProgress,
  }) {
    return _cache.download(
      source,
      mediaType,
      onProgress: onProgress,
    );
  }

  @override
  Future<bool> deleteDownload(String mediaType, MediaSource source) {
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
