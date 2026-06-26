# Assets Optimization

## Current Asset Shape

- Sheet music is already stored as WebP and is the main bundled asset cost.
- Category and onboarding images are small enough for current use.
- Onboarding images under `assets/onboarding/` are screenshot-style guide placeholders. Replace them with final production screenshots before release if product screenshots are available.

## Rules

- Do not delete sheet music just to reduce APK size; it is part of current offline functionality.
- Prefer WebP for photos and scanned sheets.
- Keep UI guide images small, cropped, and readable at phone sizes.
- Use explicit asset declarations for small UI image groups so Android and Windows builds package the same assets.

## Future Remote Media Path

The code already has repository boundaries:

- `AudioRepository`
- `SheetMusicRepository`
- `DownloadRepository`

Use these to move large media out of the APK later:

1. Store sheet music/audio in backend or CDN.
2. Return media metadata from content API.
3. Download on demand.
4. Cache locally with eviction.
5. Keep bundled placeholders only for offline-critical or demo media.
