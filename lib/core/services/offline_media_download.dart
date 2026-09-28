import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn_media.dart';

/// What installing a whole edition's sheet music or audio would cost.
class MediaDownloadPlan {
  /// [MediaType.sheetMusic] or [MediaType.audio].
  final String mediaType;

  /// Pages or tracks the edition has, downloaded or not.
  final int itemCount;

  /// The size of all [itemCount] files.
  final int totalBytes;

  /// Distinct files not on the device yet. A file shared by two hymns, or by
  /// two editions, is one file.
  final List<MediaSource> missing;

  const MediaDownloadPlan({
    required this.mediaType,
    required this.itemCount,
    this.totalBytes = 0,
    required this.missing,
  });

  int get missingBytes =>
      missing.fold(0, (sum, source) => sum + (source.sizeBytes ?? 0));
}

class MediaDownloadResult {
  final int downloaded;
  final int failed;
  final bool cancelled;

  const MediaDownloadResult({
    required this.downloaded,
    required this.failed,
    required this.cancelled,
  });
}

/// The API's suggested ceiling for parallel file downloads: a full edition
/// in about a minute, well under the per-file rate limit.
const int mediaDownloadConcurrency = 6;

/// The size counted for a file the API gave no size for.
const int _assumedFileBytes = 1024 * 1024;

/// Downloads [plan]'s missing files a few at a time, each verified against
/// its checksum. A failed file is counted and skipped, so one bad file does
/// not cost the rest; running again fetches only what is still missing.
///
/// [onProgress] reports bytes, including files still arriving, so progress
/// moves before the first file is complete.
Future<MediaDownloadResult> downloadMissingMedia(
  MediaCache cache,
  MediaDownloadPlan plan, {
  void Function(int doneBytes, int totalBytes)? onProgress,
  bool Function()? isCancelled,
}) async {
  int sizeOf(MediaSource source) => source.sizeBytes ?? _assumedFileBytes;

  final queue = List.of(plan.missing);
  final total = queue.fold(0, (sum, source) => sum + sizeOf(source));
  var doneBytes = 0;
  var downloaded = 0;
  var failed = 0;

  Future<void> worker() async {
    while (queue.isNotEmpty && !(isCancelled?.call() ?? false)) {
      final source = queue.removeLast();
      final size = sizeOf(source);
      var counted = 0;
      void count(int bytes) {
        final clamped = bytes.clamp(0, size);
        doneBytes += clamped - counted;
        counted = clamped;
        onProgress?.call(doneBytes, total);
      }

      try {
        await cache.download(
          source,
          plan.mediaType,
          onProgress: (received, _) => count(received),
        );
        downloaded++;
      } catch (_) {
        failed++;
      }
      // A finished or failed file no longer waits on anything.
      count(size);
    }
  }

  await Future.wait([
    for (var i = 0; i < mediaDownloadConcurrency; i++) worker(),
  ]);
  return MediaDownloadResult(
    downloaded: downloaded,
    failed: failed,
    cancelled: isCancelled?.call() ?? false,
  );
}

/// Installs a whole edition's sheet music or audio for offline use.
///
/// Each synced hymn carries its pages' and its track's URL, size and
/// checksum, so the list is built from the hymns on the device: no request,
/// and the state is known offline. It matches the API's own page list.
class EditionMediaDownloader {
  EditionMediaDownloader({MediaCache? cache})
      : _cache = cache ?? LocalMediaCacheService.instance;

  final MediaCache _cache;

  static Iterable<HymnMediaFile> _filesOf(Hymn hymn, String mediaType) =>
      mediaType == MediaType.audio
          ? [if (hymn.audioInfo != null) hymn.audioInfo!.file]
          : [for (final page in hymn.sheetPages ?? const []) page.file];

  /// [mediaType]'s files for [hymns], each once, and which are missing.
  Future<MediaDownloadPlan> plan(List<Hymn> hymns, String mediaType) async {
    final missing = <MediaSource>[];
    final seen = <String>{};
    var totalBytes = 0;
    for (final hymn in hymns) {
      for (final file in _filesOf(hymn, mediaType)) {
        final source = mediaSourceForFile(file);
        if (!seen.add(source.checksumSha256 ?? file.url)) continue;
        totalBytes += source.sizeBytes ?? 0;
        if (await _cache.cachedPath(source, mediaType) == null) {
          missing.add(source);
        }
      }
    }
    return MediaDownloadPlan(
      mediaType: mediaType,
      itemCount: seen.length,
      totalBytes: totalBytes,
      missing: missing,
    );
  }

  Future<MediaDownloadResult> download(
    MediaDownloadPlan plan, {
    void Function(int doneBytes, int totalBytes)? onProgress,
    bool Function()? isCancelled,
  }) =>
      downloadMissingMedia(
        _cache,
        plan,
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
}
