# Sheet Music

## Current Behavior

Sheet music is no longer bundled into the base Flutter asset manifest. The UI shows a compact sheet-music box beside the audio area on the lyrics page. Tapping it opens a full-screen viewer with an X close button.

The viewer supports:

- full-screen image area
- pinch zoom and pan
- page indicators for multiple pages
- screenshot blocking on Android through the existing secure-screen service
- cached local file paths and bundled asset paths

## Download Flow

When a hymn provides remote sheet music URLs and they are not cached, the app asks in Amharic before downloading. Downloaded files are stored in app support storage and can be opened offline later.
