# Data Models

## Hymnal Versions

- `sda_new`: New SDA Hymnal display number/title/lyrics.
- `sda_old`: Old SDA Hymnal display number/title/lyrics.
- `hagerigna`: Amharic non-hymnal songs.
- `hymnal`: legacy alias mapped to `sda_new`.

Old/New SDA songs can share one backend work while exposing separate old and new hymn numbers.

## Categories

SDA categories are defined once in `HymnCategories`. The 31 ranges cover hymn numbers 1 through 325 without gaps or overlap. Hagerigna does not use SDA categories.

## Media

Sheet music is resolved through `SheetMusicRepository`, first from API/model data and then from discovered local assets. Audio is resolved through `AudioRepository`; hymn 1 currently exposes a dummy track for UI validation.

## User Reports

Bug reports are stored in the user/app PostgreSQL database through `backend/user_app`. Mobile reports include title, description, optional contact email inside diagnostics, app version, platform, selected version, and settings diagnostics.
