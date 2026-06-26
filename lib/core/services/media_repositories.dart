import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_discovery_service.dart';
import 'package:amharic_hymnal_app/features/hymns/domain/entities/hymn.dart';

class AudioTrack {
  final int hymnNumber;
  final String title;
  final String url;
  final Duration? duration;
  final bool isDummy;

  const AudioTrack({
    required this.hymnNumber,
    required this.title,
    required this.url,
    this.duration,
    this.isDummy = false,
  });
}

class LocalDummyAudioRepository {
  static const int dummyHymnNumber = 1;

  Future<AudioTrack?> getTrackForNumber(
    int hymnNumber, {
    String? title,
  }) async {
    if (hymnNumber != dummyHymnNumber) return null;
    return AudioTrack(
      hymnNumber: hymnNumber,
      title: title ?? 'Hymn #$hymnNumber',
      url: '${GlobalAudioService.dummyAudioScheme}hymn-$hymnNumber',
      duration: GlobalAudioService.dummyDuration,
      isDummy: true,
    );
  }
}

class AudioRepository {
  final LocalDummyAudioRepository _localDummyAudioRepository =
      LocalDummyAudioRepository();
  final LocalMediaCacheService _cache = LocalMediaCacheService.instance;
  final RemoteAudioDataSource _remoteAudioDataSource =
      const RemoteAudioDataSource();

  Future<AudioTrack?> getTrackForHymn(Hymn hymn) async {
    return getTrackForNumber(
      hymn.displayNumber,
      title: hymn.displayTitle,
    );
  }

  Future<AudioTrack?> getTrackForNumber(
    int hymnNumber, {
    String? title,
  }) async {
    final dummyTrack = await _localDummyAudioRepository.getTrackForNumber(
      hymnNumber,
      title: title,
    );
    if (dummyTrack != null) return dummyTrack;

    final url = await GlobalAudioService().resolveAudioUrl(hymnNumber);
    if (url == null || url.isEmpty) return null;
    return AudioTrack(
      hymnNumber: hymnNumber,
      title: title ?? 'Hymn #$hymnNumber',
      url: url,
      duration: url.startsWith(GlobalAudioService.dummyAudioScheme)
          ? GlobalAudioService.dummyDuration
          : null,
      isDummy: url.startsWith(GlobalAudioService.dummyAudioScheme),
    );
  }

  Future<Uri?> remoteSourceForNumber(int hymnNumber) {
    return _remoteAudioDataSource.resolve(hymnNumber);
  }

  Future<String?> cachedPathFor(Uri source) {
    return _cache.cachedPath(source, 'audio');
  }
}

class SheetMusicRepository {
  final LocalMediaCacheService _cache = LocalMediaCacheService.instance;
  final RemoteSheetMusicDataSource _remoteSheetMusicDataSource =
      const RemoteSheetMusicDataSource();

  Future<List<String>> getFilesForHymn(Hymn hymn) async {
    final provided = hymn.sheetMusic
            ?.where((item) => item.trim().isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (provided.isNotEmpty) return provided;

    final discoveryService = SheetMusicDiscoveryService();
    final discovered = discoveryService.getSheetMusicFiles(hymn.displayNumber);
    if (discovered.isNotEmpty) return discovered;

    final remote = await remoteSourcesForHymn(hymn);
    return remote.map((source) => source.toString()).toList();
  }

  Future<List<Uri>> remoteSourcesForHymn(Hymn hymn) {
    return _remoteSheetMusicDataSource.resolve(hymn.displayNumber);
  }

  Future<List<String>> cachedFilesForSources(List<Uri> sources) async {
    final paths = <String>[];
    for (final source in sources) {
      final cached = await _cache.cachedPath(source, 'sheet_music');
      if (cached != null) paths.add(cached);
    }
    return paths;
  }
}

class DownloadRepository {
  final LocalMediaCacheService _cache = LocalMediaCacheService.instance;

  Future<bool> isDownloadAvailable(String mediaType, Uri? source) async {
    return source != null && source.scheme.startsWith('http');
  }

  Future<CachedMediaFile> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required Uri source,
    void Function(int received, int? total)? onProgress,
  }) async {
    return _cache.download(
      source,
      mediaType,
      onProgress: onProgress,
    );
  }
}
