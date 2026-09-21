import 'package:http/http.dart' as http;

import 'package:amharic_hymnal_app/core/config/content_api_config.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_client.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_api_response.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/media_repositories.dart';

/// What a whole-edition sheet-music download would cost.
class SheetMusicDownloadPlan {
  final int pageCount;

  /// Distinct files not on the device yet. A sheet shared by two hymns is
  /// one file.
  final List<MediaSource> missing;

  const SheetMusicDownloadPlan(
      {required this.pageCount, required this.missing});

  int get missingBytes =>
      missing.fold(0, (sum, source) => sum + (source.sizeBytes ?? 0));
}

class SheetMusicDownloadResult {
  final int downloaded;
  final int failed;
  final bool cancelled;

  const SheetMusicDownloadResult({
    required this.downloaded,
    required this.failed,
    required this.cancelled,
  });
}

/// Installs every sheet-music page of an edition for offline use, page by
/// page as the API recommends: listed in one request, fetched a few at a
/// time, each verified against its checksum.
class SheetMusicBulkDownloadService {
  SheetMusicBulkDownloadService({
    http.Client? client,
    String? baseUrl,
    MediaCache? cache,
  })  : _api = HymnalApiClient(client: client),
        _baseUrl = baseUrl ?? ContentApiConfig.baseUrl,
        _cache = cache ?? LocalMediaCacheService.instance;

  /// The API's suggested ceiling: a full edition in about a minute, well
  /// under the per-file rate limit.
  static const concurrency = 6;

  final HymnalApiClient _api;
  final String _baseUrl;
  final MediaCache _cache;

  Future<SheetMusicDownloadPlan> plan(String versionCode) async {
    final uri = Uri.parse('$_baseUrl/downloads/sheet-music/pages').replace(
      queryParameters: {'language': 'am', 'version': versionCode},
    );
    final response = await _api.get(uri, timeout: const Duration(seconds: 20));
    final data = decodeHymnalApiData(response);
    final pages = data is Map ? data['pages'] : null;
    if (pages is! List) {
      return const SheetMusicDownloadPlan(pageCount: 0, missing: []);
    }

    final missing = <MediaSource>[];
    final seen = <String>{};
    for (final page in pages.whereType<Map<String, dynamic>>()) {
      final url = page['downloadUrl'];
      if (url is! String) continue;
      final source = MediaSource(
        Uri.parse(url),
        checksumSha256: page['checksumSha256']?.toString(),
        sizeBytes: (page['sizeBytes'] as num?)?.toInt(),
        fileName: page['fileName']?.toString(),
        contentType: page['contentType']?.toString(),
      );
      if (!seen.add(source.checksumSha256 ?? url)) continue;
      if (await _cache.cachedPath(source, MediaType.sheetMusic) == null) {
        missing.add(source);
      }
    }
    return SheetMusicDownloadPlan(pageCount: pages.length, missing: missing);
  }

  /// Downloads [plan]'s missing files. A failed page is counted and skipped,
  /// so one bad file does not cost the rest; running again fetches only what
  /// is still missing.
  Future<SheetMusicDownloadResult> download(
    SheetMusicDownloadPlan plan, {
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final queue = List.of(plan.missing);
    final total = queue.length;
    var done = 0;
    var downloaded = 0;
    var failed = 0;

    Future<void> worker() async {
      while (queue.isNotEmpty && !(isCancelled?.call() ?? false)) {
        final source = queue.removeLast();
        try {
          await _cache.download(source, MediaType.sheetMusic);
          downloaded++;
        } catch (_) {
          failed++;
        }
        onProgress?.call(++done, total);
      }
    }

    await Future.wait([
      for (var i = 0; i < concurrency; i++) worker(),
    ]);
    return SheetMusicDownloadResult(
      downloaded: downloaded,
      failed: failed,
      cancelled: isCancelled?.call() ?? false,
    );
  }
}
