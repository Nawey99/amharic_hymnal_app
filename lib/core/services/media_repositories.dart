import 'dart:convert';

import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/local_media_cache_service.dart';
import 'package:amharic_hymnal_app/core/services/sheet_music_discovery_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/services.dart';
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

class LocalTestAudioRepository {
  static const Set<String> supportedVersions = {'sda_new', 'hymnal'};
  static const int firstTestHymnNumber = 1;
  static const int lastTestHymnNumber = 43;

  final Map<int, String> _assetCache = {};
  bool _isInitialized = false;

  Future<AudioTrack?> getTrackForNumber(
    int hymnNumber, {
    required String version,
    String? title,
  }) async {
    if (!supportedVersions.contains(version) ||
        hymnNumber < firstTestHymnNumber ||
        hymnNumber > lastTestHymnNumber) {
      return null;
    }

    await _initialize();
    final assetPath = _assetCache[hymnNumber];
    if (assetPath == null) return null;

    final playerAssetPath = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;

    return AudioTrack(
      hymnNumber: hymnNumber,
      title: title ?? 'Hymn #$hymnNumber',
      url: '${GlobalAudioService.localAssetAudioScheme}$playerAssetPath',
    );
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final manifest = jsonDecode(manifestContent) as Map<String, dynamic>;
      final audioAssets = manifest.keys
          .where((key) => key.startsWith('assets/audio/'))
          .where(_isSupportedAudioAsset)
          .toList()
        ..sort();

      for (final assetPath in audioAssets) {
        final fileName = assetPath.split('/').last;
        final number = int.tryParse(fileName.split('.').first);
        if (number == null ||
            number < firstTestHymnNumber ||
            number > lastTestHymnNumber) {
          continue;
        }
        _assetCache.putIfAbsent(number, () => assetPath);
      }

      if (kDebugMode) {
        debugPrint(
          '🎧 Local test audio discovered for ${_assetCache.length} hymns',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Local test audio discovery failed: $e');
      }
    } finally {
      _isInitialized = true;
    }
  }

  bool _isSupportedAudioAsset(String assetPath) {
    final lower = assetPath.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.wav.ts') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg');
  }
}

class AudioRepository {
  final LocalTestAudioRepository _localTestAudioRepository =
      LocalTestAudioRepository();
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
    String version = 'sda_new',
  }) async {
    final localTrack = await _localTestAudioRepository.getTrackForNumber(
      hymnNumber,
      version: version,
      title: title,
    );
    if (localTrack != null) return localTrack;

    if (LocalTestAudioRepository.supportedVersions.contains(version)) {
      final dummyTrack = await _localDummyAudioRepository.getTrackForNumber(
        hymnNumber,
        title: title,
      );
      if (dummyTrack != null) return dummyTrack;
    }

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
