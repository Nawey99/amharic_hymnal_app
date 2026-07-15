# Downloadable Media

## Contract

The Flutter app does not derive media URLs from hymn numbers. The content
backend must return an explicit absolute HTTP(S) URL for each audio or
sheet-music file in hymn metadata. Relative paths and Flutter asset paths are
rejected because hymn media is no longer bundled with the application.

The media layer consists of:

- `MediaReference`, which validates remote URLs and downloaded local paths
- `AudioRepository` and `SheetMusicRepository`, which resolve hymn metadata
- `DownloadRepository`, which exposes download, delete, and clear operations
- `LocalMediaCacheService`, which stores downloaded media in app-support storage

Backend storage keys are not public download URLs. A future media backend or CDN
must resolve those keys before returning content to the app. Until that contract
is implemented, the media controls show an unavailable state.

## Download Flow

1. The selected hymn supplies one or more explicit media URLs.
2. The repository checks for a previously downloaded copy.
3. The app asks the user before downloading uncached media.
4. The response streams to a temporary file.
5. A complete non-empty response is atomically renamed into the media cache.
6. Audio plays from the downloaded file and sheet music opens from local paths.

Interrupted or incomplete downloads are deleted. Cache filenames include a
stable URL hash to prevent collisions between different backend objects with the
same filename.

Web offline media storage is intentionally not implemented yet. The web UI
handles this as unavailable instead of guessing a storage or endpoint contract.
