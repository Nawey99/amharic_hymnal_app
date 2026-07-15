import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kDebugMode, kIsWeb, debugPrint;

import 'package:amharic_hymnal_app/core/services/hymnal_audio_handler.dart';
import 'package:amharic_hymnal_app/core/services/media_artwork_service.dart';

enum AudioPlayerState {
  stopped,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

class GlobalAudioService {
  static final GlobalAudioService _instance = GlobalAudioService._internal();

  factory GlobalAudioService() => _instance;

  GlobalAudioService._internal();

  static const String notificationChannelId =
      'com.example.amharic_hymnal_app.audio';
  static const String notificationChannelName = 'Audio Playback';
  static const String appAlbumName = 'ውዳሴ';

  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration?> _durationController =
      StreamController<Duration?>.broadcast();
  final StreamController<AudioPlayerState> _playbackStateController =
      StreamController<AudioPlayerState>.broadcast();
  final StreamController<int?> _currentHymnController =
      StreamController<int?>.broadcast();

  AudioHandler? _handler;
  StreamSubscription<PlaybackState>? _playbackSubscription;
  StreamSubscription<MediaItem?>? _mediaItemSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  int? _currentHymnNumber;
  String? _currentAudioUrl;
  Duration _currentPosition = Duration.zero;
  Duration? _totalDuration;
  AudioPlayerState _playbackState = AudioPlayerState.stopped;
  bool _isInitialized = false;
  bool _audioBackendAvailable = false;

  Future<AudioHandler?> initialize({String? apiKey, String? baseUrl}) async {
    if (_isInitialized) return _handler;

    if (!_isSupportedPlatform) {
      _isInitialized = true;
      _audioBackendAvailable = false;
      if (kDebugMode) {
        debugPrint(
          'Audio playback is unavailable on this desktop platform.',
        );
      }
      return null;
    }

    final handler = await AudioService.init(
      builder: HymnalAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: notificationChannelId,
        androidNotificationChannelName: notificationChannelName,
        androidNotificationChannelDescription:
            'Hymn accompaniment playback controls',
        androidStopForegroundOnPause: false,
        fastForwardInterval: HymnalAudioHandler.seekInterval,
        rewindInterval: HymnalAudioHandler.seekInterval,
        preloadArtwork: true,
      ),
    );

    _attachHandler(handler);
    _audioBackendAvailable = true;
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('GlobalAudioService initialized with audio_service.');
    }
    return handler;
  }

  /// Retained for source compatibility with older app integrations.
  ///
  /// Media endpoints are no longer inferred from one base URL. The content API
  /// must provide each audio URL in hymn metadata before playback is offered.
  @Deprecated('Supply explicit audio URLs through hymn content metadata.')
  void setApiConfig({String? apiKey, String? baseUrl}) {
    if (kDebugMode &&
        ((apiKey?.isNotEmpty ?? false) || (baseUrl?.isNotEmpty ?? false))) {
      debugPrint(
        'Global audio endpoint configuration is ignored; use hymn metadata.',
      );
    }
  }

  void _attachHandler(AudioHandler handler) {
    _handler = handler;
    _playbackSubscription?.cancel();
    _mediaItemSubscription?.cancel();
    _positionSubscription?.cancel();

    _playbackSubscription = handler.playbackState.listen(_onPlaybackState);
    _mediaItemSubscription = handler.mediaItem.listen(_onMediaItem);
    _positionSubscription = AudioService.position.listen(_onPosition);

    _onPlaybackState(handler.playbackState.value);
    _onMediaItem(handler.mediaItem.value);
  }

  void _onPlaybackState(PlaybackState state) {
    _playbackState = audioPlayerStateFromPlaybackState(
      state,
      hasMediaItem: _handler?.mediaItem.value != null,
    );
    _playbackStateController.add(_playbackState);
    _onPosition(state.updatePosition);
  }

  void _onMediaItem(MediaItem? item) {
    final extras = item?.extras;
    final hymnNumber = extras?['hymnNumber'];
    _currentHymnNumber = hymnNumber is num ? hymnNumber.toInt() : null;
    _currentAudioUrl = extras?[HymnalAudioHandler.sourceExtra] as String?;
    _totalDuration = item?.duration;
    _currentHymnController.add(_currentHymnNumber);
    _durationController.add(_totalDuration);

    if (item == null) {
      _onPosition(Duration.zero);
    }
  }

  void _onPosition(Duration position) {
    final normalizedPosition =
        _currentHymnNumber == null ? Duration.zero : position;
    _currentPosition = normalizedPosition;
    _positionController.add(normalizedPosition);
  }

  /// Legacy resolver retained without inventing an endpoint contract.
  @Deprecated('Read the explicit audio URL from Hymn.audioUrl instead.')
  Future<String?> resolveAudioUrl(int hymnNumber) async {
    return null;
  }

  Future<void> play(
    int hymnNumber, {
    String? hymnTitle,
    String? artist,
    String version = 'sda_new',
  }) async {
    throw StateError(
      'Audio playback requires an explicit downloaded file for hymn '
      '$hymnNumber.',
    );
  }

  Future<void> playLocalFile(
    int hymnNumber,
    String filePath, {
    String? hymnTitle,
    String? artist,
    String version = 'sda_new',
  }) {
    return _playSource(
      hymnNumber: hymnNumber,
      mediaId: Uri.file(filePath).toString(),
      sourceType: HymnalAudioHandler.sourceTypeFile,
      source: filePath,
      hymnTitle: hymnTitle,
      artist: artist,
      version: version,
    );
  }

  Future<void> _playSource({
    required int hymnNumber,
    required String mediaId,
    required String sourceType,
    required String source,
    required String version,
    String? hymnTitle,
    String? artist,
  }) async {
    final handler = _handler;
    if (!_audioBackendAvailable || handler == null) {
      throw StateError('Audio playback is not available on this platform.');
    }

    final artworkUri = await MediaArtworkService.instance.getArtworkUri();
    final normalizedTitle = hymnTitle?.trim();
    final normalizedArtist = artist?.trim();
    final item = buildHymnMediaItem(
      hymnNumber: hymnNumber,
      mediaId: mediaId,
      sourceType: sourceType,
      source: source,
      version: version,
      hymnTitle: normalizedTitle,
      artist: normalizedArtist,
      artworkUri: artworkUri,
    );

    try {
      await handler.playMediaItem(item);
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Audio playback failed for hymn $hymnNumber: $error');
      }
      rethrow;
    }
  }

  Future<void> pause() async {
    await _handler?.pause();
  }

  Future<void> resume() async {
    await _handler?.play();
  }

  Future<void> stop() async {
    await _handler?.stop();
  }

  Future<void> seek(Duration position) async {
    await _handler?.seek(position);
  }

  Future<void> seekBackward() async {
    await _handler?.rewind();
  }

  Future<void> seekForward() async {
    await _handler?.fastForward();
  }

  Future<void> skipToPrevious() async {
    await _handler?.skipToPrevious();
  }

  Future<void> skipToNext() async {
    await _handler?.skipToNext();
  }

  Future<void> togglePlayPause() async {
    if (_playbackState == AudioPlayerState.playing) {
      await pause();
      return;
    }
    if (_playbackState == AudioPlayerState.completed) {
      await seek(Duration.zero);
    }
    await resume();
  }

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<AudioPlayerState> get playbackStateStream =>
      _playbackStateController.stream;
  Stream<int?> get currentHymnStream => _currentHymnController.stream;

  AudioHandler? get audioHandler => _handler;
  int? get currentHymnNumber => _currentHymnNumber;
  Duration get position => _currentPosition;
  Duration? get duration => _totalDuration;
  AudioPlayerState get playbackState => _playbackState;
  bool get isPlaying => _playbackState == AudioPlayerState.playing;
  bool get isPaused => _playbackState == AudioPlayerState.paused;
  bool get isStopped => _playbackState == AudioPlayerState.stopped;
  String? get currentAudioUrl => _currentAudioUrl;

  bool get _isSupportedPlatform {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }
}

AudioPlayerState audioPlayerStateFromPlaybackState(
  PlaybackState state, {
  required bool hasMediaItem,
}) {
  return switch (state.processingState) {
    AudioProcessingState.error => AudioPlayerState.error,
    AudioProcessingState.loading => AudioPlayerState.loading,
    AudioProcessingState.buffering => AudioPlayerState.buffering,
    AudioProcessingState.completed => AudioPlayerState.completed,
    AudioProcessingState.idle => AudioPlayerState.stopped,
    AudioProcessingState.ready => state.playing
        ? AudioPlayerState.playing
        : hasMediaItem
            ? AudioPlayerState.paused
            : AudioPlayerState.stopped,
  };
}

MediaItem buildHymnMediaItem({
  required int hymnNumber,
  required String mediaId,
  required String sourceType,
  required String source,
  required String version,
  String? hymnTitle,
  String? artist,
  Uri? artworkUri,
}) {
  final normalizedTitle = hymnTitle?.trim();
  final normalizedArtist = artist?.trim();
  return MediaItem(
    id: mediaId,
    title: normalizedTitle == null || normalizedTitle.isEmpty
        ? 'መዝሙር $hymnNumber'
        : normalizedTitle,
    album: GlobalAudioService.appAlbumName,
    artist: normalizedArtist == null || normalizedArtist.isEmpty
        ? null
        : normalizedArtist,
    artUri: artworkUri,
    extras: {
      'hymnNumber': hymnNumber,
      'version': version,
      HymnalAudioHandler.sourceTypeExtra: sourceType,
      HymnalAudioHandler.sourceExtra: source,
    },
  );
}
