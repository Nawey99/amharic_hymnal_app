import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
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
}

class SheetMusicRepository {
  Future<List<String>> getFilesForHymn(Hymn hymn) async {
    final provided = hymn.sheetMusic
            ?.where((item) => item.trim().isNotEmpty)
            .toList(growable: false) ??
        const <String>[];
    if (provided.isNotEmpty) return provided;

    final discoveryService = SheetMusicDiscoveryService();
    return discoveryService.getSheetMusicFiles(hymn.displayNumber);
  }
}

class DownloadRepository {
  Future<bool> isDownloadAvailable(String mediaType) async {
    return mediaType == 'audio';
  }

  Future<void> requestDownload({
    required String mediaType,
    required int hymnNumber,
    required Uri source,
  }) async {
    throw UnsupportedError(
      'Download storage is not configured for $mediaType yet.',
    );
  }
}
