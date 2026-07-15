# Audio

## Current Behavior

No hymn audio is bundled with the Flutter app. A hymn exposes the player only
when its content metadata contains a valid absolute audio URL or a downloaded
local file path. Missing or legacy relative references produce the normal
Amharic unavailable state.

Remote audio requires user confirmation before download. The completed file is
stored in app-support storage and played from that local path, so it remains
available offline.

Playback uses `just_audio`, `audio_service`, and `audio_session` through
`GlobalAudioService` and `HymnalAudioHandler`. Android background playback,
notification controls, seek controls, pause/resume, completion restart, and the
single-active-track behavior remain available.

## Backend Requirement

The content backend must place the exact downloadable URL in `audio_url`. The
app does not assume `/audio/{number}` routes, API keys, providers, or filename
conventions.
