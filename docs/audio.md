# Audio

## Current Behavior

Hymn 1 has one bundled audible dummy audio track:

`assets/audio/dummy_hymn_1.wav`

The audio player uses `GlobalAudioService` with `audioplayers`. The dummy asset is intentionally tiny and exists only to verify play/pause/progress behavior.

## Future Backend Audio

`AudioRepository`, `RemoteAudioDataSource`, `DownloadRepository`, and `LocalMediaCacheService` are in place for remote audio. The backend should provide stable audio URLs or return exact URLs in hymn data.

For production background notifications and lock-screen controls, migrate to `just_audio` plus `audio_service`/`just_audio_background`.
