import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart' show PlayerException;
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_audio_handler.dart';

/// just_audio's platform side, standing in for ExoPlayer/AVPlayer. Modelled
/// on the mock in just_audio's own tests.
class _FakeJustAudio extends JustAudioPlatform with MockPlatformInterfaceMixin {
  _FakePlayer? player;
  bool failLoads = false;

  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async =>
      player = _FakePlayer(request.id, this);

  @override
  Future<DisposePlayerResponse> disposePlayer(
          DisposePlayerRequest request) async =>
      DisposePlayerResponse();

  @override
  Future<DisposeAllPlayersResponse> disposeAllPlayers(
          DisposeAllPlayersRequest request) async =>
      DisposeAllPlayersResponse();
}

class _FakePlayer extends AudioPlayerPlatform {
  _FakePlayer(super.id, this.platform);

  final _FakeJustAudio platform;
  final events = StreamController<PlaybackEventMessage>.broadcast();
  final data = StreamController<PlayerDataMessage>.broadcast();

  static const duration = Duration(seconds: 30);
  ProcessingStateMessage _state = ProcessingStateMessage.idle;
  Duration _position = Duration.zero;
  Completer<void>? _playing;
  final List<Duration> seeks = [];

  @override
  Stream<PlaybackEventMessage> get playbackEventMessageStream => events.stream;

  @override
  Stream<PlayerDataMessage> get playerDataMessageStream => data.stream;

  void _broadcast() => events.add(PlaybackEventMessage(
        processingState: _state,
        updateTime: DateTime.now(),
        updatePosition: _position,
        bufferedPosition: _position,
        duration: _state == ProcessingStateMessage.idle ? null : duration,
        icyMetadata: null,
        currentIndex: 0,
        androidAudioSessionId: null,
      ));

  /// The track reaches its end, as the platform reports it.
  void finish() {
    _position = duration;
    _state = ProcessingStateMessage.completed;
    _broadcast();
    _playing?.complete();
    _playing = null;
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    if (platform.failLoads) {
      final error = PlatformException(code: '404', message: 'Not found');
      events.addError(error);
      throw error;
    }
    _position = request.initialPosition ?? Duration.zero;
    _state = ProcessingStateMessage.ready;
    _broadcast();
    return LoadResponse(duration: duration);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    _playing ??= Completer<void>();
    await _playing!.future;
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    _playing?.complete();
    _playing = null;
    _broadcast();
    return PauseResponse();
  }

  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    _position = request.position ?? Duration.zero;
    seeks.add(_position);
    _broadcast();
    return SeekResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    _state = ProcessingStateMessage.idle;
    return DisposeResponse();
  }

  // Settings the handler never changes: accepted and ignored.
  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async =>
      SetVolumeResponse();
  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async =>
      SetSpeedResponse();
  @override
  Future<SetPitchResponse> setPitch(SetPitchRequest request) async =>
      SetPitchResponse();
  @override
  Future<SetSkipSilenceResponse> setSkipSilence(
          SetSkipSilenceRequest request) async =>
      SetSkipSilenceResponse();
  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async =>
      SetLoopModeResponse();
  @override
  Future<SetShuffleModeResponse> setShuffleMode(
          SetShuffleModeRequest request) async =>
      SetShuffleModeResponse();
  @override
  Future<SetShuffleOrderResponse> setShuffleOrder(
          SetShuffleOrderRequest request) async =>
      SetShuffleOrderResponse();
  @override
  Future<SetAutomaticallyWaitsToMinimizeStallingResponse>
      setAutomaticallyWaitsToMinimizeStalling(
              SetAutomaticallyWaitsToMinimizeStallingRequest request) async =>
          SetAutomaticallyWaitsToMinimizeStallingResponse();
  @override
  Future<SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse>
      setCanUseNetworkResourcesForLiveStreamingWhilePaused(
              SetCanUseNetworkResourcesForLiveStreamingWhilePausedRequest
                  request) async =>
          SetCanUseNetworkResourcesForLiveStreamingWhilePausedResponse();
  @override
  Future<SetPreferredPeakBitRateResponse> setPreferredPeakBitRate(
          SetPreferredPeakBitRateRequest request) async =>
      SetPreferredPeakBitRateResponse();
  @override
  Future<SetAllowsExternalPlaybackResponse> setAllowsExternalPlayback(
          SetAllowsExternalPlaybackRequest request) async =>
      SetAllowsExternalPlaybackResponse();
  @override
  Future<SetAndroidAudioAttributesResponse> setAndroidAudioAttributes(
          SetAndroidAudioAttributesRequest request) async =>
      SetAndroidAudioAttributesResponse();
  @override
  Future<ConcatenatingInsertAllResponse> concatenatingInsertAll(
          ConcatenatingInsertAllRequest request) async =>
      ConcatenatingInsertAllResponse();
  @override
  Future<ConcatenatingRemoveRangeResponse> concatenatingRemoveRange(
          ConcatenatingRemoveRangeRequest request) async =>
      ConcatenatingRemoveRangeResponse();
  @override
  Future<ConcatenatingMoveResponse> concatenatingMove(
          ConcatenatingMoveRequest request) async =>
      ConcatenatingMoveResponse();
}

MediaItem _hymn(int number, {String? source = '/data/media/hymn.m4a'}) =>
    buildHymnMediaItem(
      hymnNumber: number,
      mediaId: 'file:///data/media/hymn-$number.m4a',
      sourceType: HymnalAudioHandler.sourceTypeFile,
      source: source ?? '',
      version: 'sda_new',
      hymnTitle: 'መዝሙር $number',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const session = MethodChannel('com.ryanheise.audio_session');
  late _FakeJustAudio platform;
  late HymnalAudioHandler handler;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(session, (_) async => null);
    platform = _FakeJustAudio();
    JustAudioPlatform.instance = platform;
    handler = HymnalAudioHandler();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(session, null);
  });

  Future<void> settle() => pumpEventQueue();

  test('playing a hymn shows it with play-state controls and no skips',
      () async {
    await handler.playMediaItem(_hymn(12));
    await settle();

    final state = handler.playbackState.value;
    expect(handler.mediaItem.value?.extras?['hymnNumber'], 12);
    expect(state.playing, isTrue);
    expect(state.processingState, AudioProcessingState.ready);
    // One hymn at a time: pause and stop, never next/previous.
    expect(state.controls, [MediaControl.pause, MediaControl.stop]);
    expect(state.systemActions, {MediaAction.seek});
    expect(state.androidCompactActionIndices, [0, 1]);
  });

  test('pausing offers play again', () async {
    await handler.playMediaItem(_hymn(1));
    await settle();

    await handler.pause();
    await settle();

    final state = handler.playbackState.value;
    expect(state.playing, isFalse);
    expect(state.controls, [MediaControl.play, MediaControl.stop]);
  });

  test('seeking stays inside the track', () async {
    await handler.playMediaItem(_hymn(1));
    await settle();

    await handler.seek(const Duration(minutes: 5));
    await handler.seek(const Duration(seconds: -3));

    expect(platform.player!.seeks, [_FakePlayer.duration, Duration.zero]);
  });

  test('rewind and fast-forward move ten seconds', () async {
    await handler.playMediaItem(_hymn(1));
    // Paused, so the position does not creep on between the steps.
    await handler.pause();
    await handler.seek(const Duration(seconds: 15));
    await settle();

    await handler.fastForward();
    await settle();
    await handler.rewind();

    expect(platform.player!.seeks.skip(1),
        [const Duration(seconds: 25), const Duration(seconds: 15)]);
  });

  test('a finished hymn lets go of the notification', () async {
    await handler.playMediaItem(_hymn(1));
    await settle();

    platform.player!.finish();
    await settle();

    expect(handler.mediaItem.value, isNull);
    expect(handler.queue.value, isEmpty);
    expect(
        handler.playbackState.value.processingState, AudioProcessingState.idle);
    expect(handler.playbackState.value.controls, isEmpty);
  });

  test('swiping the app or the notification away stops playback', () async {
    await handler.playMediaItem(_hymn(1));
    await settle();
    await handler.onTaskRemoved();
    expect(handler.mediaItem.value, isNull);
    expect(handler.playbackState.value.playing, isFalse);

    await handler.playMediaItem(_hymn(2));
    await settle();
    await handler.onNotificationDeleted();
    expect(handler.mediaItem.value, isNull);
  });

  test('a file that will not load is reported as an error', () async {
    platform.failLoads = true;

    await expectLater(
        handler.playMediaItem(_hymn(1)), throwsA(isA<PlayerException>()));
    await settle();

    final state = handler.playbackState.value;
    expect(state.processingState, AudioProcessingState.error);
    expect(state.playing, isFalse);
    expect(
      audioPlayerStateFromPlaybackState(state, hasMediaItem: true),
      AudioPlayerState.error,
    );
  });

  test('a hymn with no playable source is refused before loading', () async {
    await expectLater(
      handler.playMediaItem(_hymn(1, source: null)),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('playing again after the end starts from the beginning', () async {
    await handler.playMediaItem(_hymn(1));
    await settle();
    await handler.playMediaItem(_hymn(1));
    await settle();

    expect(handler.playbackState.value.playing, isTrue);
    // Playing, so the position moves on in real time; it restarted at 0.
    expect(handler.playbackState.value.updatePosition,
        lessThan(const Duration(seconds: 1)));
  });
}
