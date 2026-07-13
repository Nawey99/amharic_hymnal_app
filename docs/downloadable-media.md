# Downloadable Media

## Architecture

The app now has repository/cache abstractions for media:

- `SheetMusicRepository`
- `AudioRepository`
- `DownloadRepository`
- `LocalMediaCacheService`
- `RemoteSheetMusicDataSource`
- `RemoteAudioDataSource`

Sheet music lookup order:

1. Use paths supplied by hymn data if present.
2. Use bundled asset discovery only if a build intentionally bundles sheet music.
3. Fall back to content API remote candidates such as `/sheet_music/{number}.webp`, `/sheet_music/{number}_L.webp`, and `/sheet_music/{number}_R.webp`.
4. If remote files are not cached, show an Amharic download confirmation dialog.
5. Download into app support storage and open cached files offline later.

## User Flow

When remote sheet music is not cached, the lyrics page asks before downloading. Cancel does not download. Download failure shows an Amharic message.

## Maintainer Action

The content backend should expose sheet music/audio files at stable URLs or return exact media URLs in the hymn API. The Flutter app is ready to consume those URLs through the repository layer.
# Final QA Update

Media repository abstractions remain in place:

- `SheetMusicRepository`
- `AudioRepository`
- `DownloadRepository`
- `LocalMediaCacheService`
- `RemoteSheetMusicDataSource`
- `RemoteAudioDataSource`

Sheet music and category source images are not bundled in the base app asset list. Future production media should be served from backend/CDN URLs with file-size metadata so the app can show Amharic download prompts before caching media offline.
