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

  test('uses seek controls for one item and queue controls for playlists', () {
    final single = mediaControlsFor(
      hasMediaItem: true,
      hasPlaylist: false,
      playing: true,
    );
    expect(
        single, containsAll([MediaControl.rewind, MediaControl.fastForward]));
    expect(single, contains(MediaControl.pause));

    final playlist = mediaControlsFor(
      hasMediaItem: true,
      hasPlaylist: true,
      playing: false,
    );
    expect(
      playlist,
      containsAll([MediaControl.skipToPrevious, MediaControl.skipToNext]),
    );
    expect(playlist, contains(MediaControl.play));

    expect(
      mediaControlsFor(
        hasMediaItem: false,
        hasPlaylist: false,
        playing: false,
      ),
      isEmpty,
    );
  });

  test('builds complete serializable notification metadata', () {
    final artwork = Uri.file('/tmp/wudase_media_artwork.png');
    final item = buildHymnMediaItem(
      hymnNumber: 12,
      mediaId: 'asset:///assets/audio/12.mp3?version=sda_new',
      sourceType: HymnalAudioHandler.sourceTypeAsset,
      source: 'assets/audio/12.mp3',
      version: 'sda_new',
      hymnTitle: 'Test hymn',
      artworkUri: artwork,
    );

    expect(item.title, 'Test hymn');
    expect(item.album, GlobalAudioService.appAlbumName);
    expect(item.artUri, artwork);
    expect(item.extras?['hymnNumber'], 12);
    expect(item.extras?['version'], 'sda_new');
    expect(
      item.extras?[HymnalAudioHandler.sourceExtra],
      'assets/audio/12.mp3',
    );
  });

  test('clamps seek positions without platform-sized integer assumptions', () {
    const duration = Duration(minutes: 2);

    expect(
      clampAudioPosition(const Duration(seconds: -5), duration),
      Duration.zero,
    );
    expect(
      clampAudioPosition(const Duration(minutes: 3), duration),
      duration,
    );
    expect(
      clampAudioPosition(const Duration(seconds: 45), null),
      const Duration(seconds: 45),
    );
  });
}
