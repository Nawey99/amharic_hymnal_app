# Audio

## Current Behavior

Hymn 1 has one bundled audible dummy audio track:

`assets/audio/dummy_hymn_1.wav`

The audio player uses `GlobalAudioService` with `audioplayers`. The dummy asset is intentionally tiny and exists only to verify play/pause/progress behavior.

## Future Backend Audio

`AudioRepository`, `RemoteAudioDataSource`, `DownloadRepository`, and `LocalMediaCacheService` are in place for remote audio. The backend should provide stable audio URLs or return exact URLs in hymn data.

For production background notifications and lock-screen controls, migrate to `just_audio` plus `audio_service`/`just_audio_background`.
# Final QA Update

The dummy hymn-1 audio asset is now `assets/audio/dummy_hymn_1.mp3`, copied from the supplied `new1.mp3`, and is registered in `pubspec.yaml`. The media asset test verifies the asset exists and is non-empty.

Background notification controls are not complete yet. The current implementation uses `audioplayers`; full Android lock-screen/media notification controls require a follow-up migration to `audio_service` plus `just_audio`/`just_audio_background`.
