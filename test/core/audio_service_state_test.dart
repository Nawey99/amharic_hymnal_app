import 'package:amharic_hymnal_app/core/services/global_audio_service.dart';
import 'package:amharic_hymnal_app/core/services/hymnal_audio_handler.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  test('maps every just_audio processing state to audio_service', () {
    expect(
      mapJustAudioProcessingState(ProcessingState.idle),
      AudioProcessingState.idle,
    );
    expect(
      mapJustAudioProcessingState(ProcessingState.loading),
      AudioProcessingState.loading,
    );
    expect(
      mapJustAudioProcessingState(ProcessingState.buffering),
      AudioProcessingState.buffering,
    );
    expect(
      mapJustAudioProcessingState(ProcessingState.ready),
      AudioProcessingState.ready,
    );
    expect(
      mapJustAudioProcessingState(ProcessingState.completed),
      AudioProcessingState.completed,
    );
  });

  test('maps native playback updates back to the Flutter player state', () {
    expect(
      audioPlayerStateFromPlaybackState(
        PlaybackState(
          processingState: AudioProcessingState.ready,
          playing: true,
        ),
        hasMediaItem: true,
      ),
      AudioPlayerState.playing,
    );
    expect(
      audioPlayerStateFromPlaybackState(
        PlaybackState(
          processingState: AudioProcessingState.ready,
          playing: false,
        ),
        hasMediaItem: true,
      ),
      AudioPlayerState.paused,
    );
    expect(
      audioPlayerStateFromPlaybackState(
        PlaybackState(
          processingState: AudioProcessingState.completed,
        ),
        hasMediaItem: true,
      ),
      AudioPlayerState.completed,
    );
  });

  test('the notification offers only playing the hymn and putting it away', () {
    final playing = mediaControlsFor(hasMediaItem: true, playing: true);
    expect(playing, [MediaControl.pause, MediaControl.stop]);

    final paused = mediaControlsFor(hasMediaItem: true, playing: false);
    expect(paused, [MediaControl.play, MediaControl.stop]);

    // One hymn is open at a time: nothing that looks like track navigation.
    for (final controls in [playing, paused]) {
      expect(
        controls,
        isNot(anyElement(isIn([
          MediaControl.skipToNext,
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          MediaControl.fastForward,
        ]))),
      );
    }

    expect(mediaControlsFor(hasMediaItem: false, playing: false), isEmpty);
  });
}
