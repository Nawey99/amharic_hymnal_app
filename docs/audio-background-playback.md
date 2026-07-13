# Audio Background Playback

## Current State

The app currently uses `audioplayers` through `GlobalAudioService`. Hymn number 1 has a dummy timer-backed audio track for UI testing. That dummy track does not produce a real Android media notification because it is not backed by an Android media session.

## What Works Now

- The in-app compact audio controls can show and control the dummy track.
- Future audio URLs can be resolved through `AudioRepository`.
- Missing audio fails gracefully.

## Remaining Production Work

To meet lock-screen and notification-control requirements, replace or wrap the player with:

- `just_audio`
- `audio_service`
- `just_audio_background`

Required native setup:

- Android media service and notification channel.
- Android foreground service permissions where required.
- iOS background audio capability.
- Metadata: `መዝሙር {number}` and hymn title.

## Android QA

After implementation, verify on a real Android device:

1. Open hymn 1.
2. Start audio.
3. Pull notification shade.
4. Confirm pause, resume, stop, and seek controls.
5. Lock the phone and confirm lock-screen controls.

This pass documents the gap instead of claiming notification support that the current dummy audio cannot provide.
