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

Bug reports are sent to the hymnal API (`POST /api/v1/reports`) with the type the user picks (`LYRICS`, `SHEET_MUSIC`, `AUDIO`, `APP_BUG`, `SUGGESTION`, `OTHER`): the title and description as the message, the optional contact the user typed, and the app version, platform, screen and language as context. A report written from a hymn's page (the flag button) carries that hymn's `songId` and is filed under its edition; otherwise the selected edition is sent as `version`. If the server no longer knows the hymn (`404`), the report is resent without it.
