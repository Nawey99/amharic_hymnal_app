# Sheet Music

## Current Behavior

Sheet music is not bundled in the Flutter asset manifest. The lyrics page shows
its compact sheet-music control only when the selected hymn contains at least
one valid remote URL or downloaded local path.

When remote sheet music is not cached, the app asks in Amharic before
downloading. Completed files are stored in app-support storage and can be opened
offline later. Missing, relative, or invalid references are handled without a
crash.

The full-screen viewer preserves:

- width-fitted pages in portrait and landscape
- pinch zoom, double-tap zoom, and bounded pan
- pagination for multiple downloaded pages
- Android screenshot blocking
- iOS capture/background privacy overlays
- graceful no-op capture protection where the platform cannot provide it

The viewer reads downloaded local files only. The content backend must resolve
storage keys to explicit HTTP(S) URLs before returning hymn metadata.
