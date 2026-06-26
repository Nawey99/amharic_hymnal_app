# Assets Optimization

## Completed

- Removed category images from the Flutter asset manifest.
- Replaced category thumbnails with icon mapping in the app UI.
- Removed full sheet music bundling from the Flutter asset manifest.
- Added one small audible WAV asset for hymn 1 dummy audio.
- Kept onboarding images because they are tiny and user-facing.

## Still In Repo

`assets/sheet_music/` and `assets/category/` still exist in the repository because they are useful source files for backend/CDN upload and data verification. They should not be bundled into the mobile base app unless a release intentionally opts into offline media.

## Rules Going Forward

- Store large sheet music/audio in backend object storage or CDN.
- Keep the base app focused on code, JSON fallback, font, tiny onboarding assets, and one audio test fixture.
- Prefer WebP/AVIF for images that must ship in-app.
- Keep generated folders out of commits: `build/`, `.dart_tool/`, `android/app/build/`, backend `node_modules/`.
