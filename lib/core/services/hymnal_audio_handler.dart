import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, debugPrint, debugPrintStack;
import 'package:just_audio/just_audio.dart';

class HymnalAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  static const String sourceTypeExtra = 'sourceType';
  static const String sourceExtra = 'source';
  static const String sourceTypeFile = 'file';
  static const String sourceTypeUri = 'uri';
  static const Duration seekInterval = Duration(seconds: 10);

  final AudioPlayer _player = AudioPlayer(
    handleInterruptions: true,
    handleAudioSessionActivation: true,
  );

  late final Future<void> _audioSessionReady = _configureAudioSession();

  HymnalAudioHandler() {
    _player.playbackEventStream.listen(
      _broadcastState,
      onError: (Object error, StackTrace stackTrace) {
        _broadcastError(error, stackTrace);
      },
    );
    _player.errorStream.listen((error) => _broadcastError(error, null));
    _player.currentIndexStream.listen((index) {
      _syncCurrentMediaItem(index);
      _broadcastState(_player.playbackEvent);
    });
    _player.durationStream.listen(_syncCurrentDuration);
    _broadcastState(_player.playbackEvent);
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    await _loadQueue(
      [mediaItem],
      initialIndex: 0,
      initialPosition: Duration.zero,
    );
    await play();
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (queue.isEmpty) {
      await stop();
      return;
    }

    final currentId = mediaItem.value?.id;
    final currentIndex = currentId == null
        ? 0
        : queue.indexWhere((item) => item.id == currentId);
    final initialIndex = currentIndex < 0 ? 0 : currentIndex;
    final keepPosition = currentIndex >= 0;
    final wasPlaying = _player.playing;

    await _loadQueue(
      queue,
      initialIndex: initialIndex,
      initialPosition: keepPosition ? _player.position : Duration.zero,
    );
    if (wasPlaying) await play();
  }

  Future<void> _loadQueue(
    List<MediaItem> items, {
    required int initialIndex,
    required Duration initialPosition,
  }) async {
    await _audioSessionReady;
    if (items.isEmpty || initialIndex < 0 || initialIndex >= items.length) {
      throw ArgumentError('Audio queue and initial index must be valid.');
    }

    final sources = items.map(_audioSourceFor).toList(growable: false);
    final immutableQueue = List<MediaItem>.unmodifiable(items);

    queue.add(immutableQueue);
    mediaItem.add(immutableQueue[initialIndex]);

    try {
      final duration = await _player.setAudioSources(
        sources,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
      );
      _syncCurrentDuration(duration);
      _broadcastState(_player.playbackEvent);
    } catch (error, stackTrace) {
      _broadcastError(error, stackTrace);
      rethrow;
    }
  }

  AudioSource _audioSourceFor(MediaItem item) {
    final extras = item.extras ?? const <String, dynamic>{};
    final sourceType = extras[sourceTypeExtra] as String?;
    final source = extras[sourceExtra] as String?;
    if (source == null || source.trim().isEmpty) {
      throw ArgumentError('Media item ${item.id} has no playable source.');
    }

    return switch (sourceType) {
      sourceTypeFile => AudioSource.file(source, tag: item),
      sourceTypeUri => AudioSource.uri(_validatedUri(source), tag: item),
      _ => throw ArgumentError(
          'Media item ${item.id} has an unsupported source type.',
        ),
    };
  }

  Uri _validatedUri(String source) {
    final uri = Uri.tryParse(source);
    if (uri == null || !uri.hasScheme) {
      throw ArgumentError('Audio URL is invalid: $source');
    }
    return uri;
  }

  @override
  Future<void> play() async {
    await _audioSessionReady;
    if (_player.audioSources.isEmpty) return;
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero, index: _player.currentIndex);
    }
    unawaited(
      _player.play().catchError((Object error, StackTrace stackTrace) {
        _broadcastError(error, stackTrace);
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.pause();
    await _player.stop();
    await _player.clearAudioSources();
    queue.add(const <MediaItem>[]);
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
      ),
    );
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(clampAudioPosition(position, _player.duration));
  }

  @override
  Future<void> rewind() => seek(_player.position - seekInterval);

  @override
  Future<void> fastForward() => seek(_player.position + seekInterval);

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  void _syncCurrentMediaItem(int? index) {
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;
    mediaItem.add(items[index]);
  }

  void _syncCurrentDuration(Duration? duration) {
    if (duration == null) return;
    final index = _player.currentIndex;
    final items = queue.value;
    if (index == null || index < 0 || index >= items.length) return;
    if (items[index].duration == duration) return;

    final updatedItems = List<MediaItem>.of(items);
    final updatedItem = updatedItems[index].copyWith(duration: duration);
    updatedItems[index] = updatedItem;
    queue.add(List<MediaItem>.unmodifiable(updatedItems));
    mediaItem.add(updatedItem);
  }

  void _broadcastState(PlaybackEvent event) {
    final hasPlaylist = queue.value.length > 1;
    final processingState = mapJustAudioProcessingState(
      _player.processingState,
    );
    final hasMediaItem = mediaItem.value != null;
    if (!hasMediaItem) {
      playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.idle,
          playing: false,
          updatePosition: Duration.zero,
          bufferedPosition: Duration.zero,
        ),
      );
      return;
    }
    final playing = _player.playing &&
        processingState != AudioProcessingState.idle &&
        processingState != AudioProcessingState.completed &&
        processingState != AudioProcessingState.error;
    final controls = mediaControlsFor(
      hasMediaItem: hasMediaItem,
      hasPlaylist: hasPlaylist,
      playing: playing,
    );

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: hasMediaItem
            ? const {
                MediaAction.seek,
                MediaAction.seekBackward,
                MediaAction.seekForward,
              }
            : const <MediaAction>{},
        androidCompactActionIndices:
            hasMediaItem ? const [0, 1, 2] : const <int>[],
        processingState: processingState,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
        errorCode: null,
        errorMessage: null,
      ),
    );
  }

  void _broadcastError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      debugPrint('Audio playback error: $error');
      if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
    }
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.error,
        playing: false,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        errorCode: 1,
        errorMessage: error.toString(),
      ),
    );
  }
}

AudioProcessingState mapJustAudioProcessingState(ProcessingState state) {
  return switch (state) {
    ProcessingState.idle => AudioProcessingState.idle,
    ProcessingState.loading => AudioProcessingState.loading,
    ProcessingState.buffering => AudioProcessingState.buffering,
    ProcessingState.ready => AudioProcessingState.ready,
    ProcessingState.completed => AudioProcessingState.completed,
  };
}

List<MediaControl> mediaControlsFor({
  required bool hasMediaItem,
  required bool hasPlaylist,
  required bool playing,
}) {
  if (!hasMediaItem) return const <MediaControl>[];
  final playControl = playing ? MediaControl.pause : MediaControl.play;
  return hasPlaylist
      ? <MediaControl>[
          MediaControl.skipToPrevious,
          playControl,
          MediaControl.skipToNext,
          MediaControl.stop,
        ]
      : <MediaControl>[
          MediaControl.rewind,
          playControl,
          MediaControl.fastForward,
          MediaControl.stop,
        ];
}

Duration clampAudioPosition(Duration position, Duration? duration) {
  var milliseconds = position.inMilliseconds;
  if (milliseconds < 0) milliseconds = 0;
  if (duration != null && milliseconds > duration.inMilliseconds) {
    milliseconds = duration.inMilliseconds;
  }
  return Duration(milliseconds: milliseconds);
}
