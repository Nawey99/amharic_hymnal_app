# Contributing

## Local Setup

1. Run `flutter pub get`.
2. Run Flutter. Hymn content comes from the hymnal API
   (`https://amharichymnalbackend.vercel.app/api/v1`, repository
   `amharic_hymnal_backend`) unless you point it at a local copy. The override
   is the API root including `/api/v1`:

```powershell
flutter run -d windows `
  --dart-define=WUDASE_CONTENT_API_URL=http://localhost:8787/api/v1
```

## Change Rules

- Keep `sda_new` (2004), `sda_old` (1975), `sda_1960` (1961) and `hagerigna`
  as the stable local version IDs; favorites and history are stored under
  them. `HymnalVersions.apiCode` maps them to the API's edition codes
  (`am-sda-2004`, `am-sda-1975`, `am-sda-1961`, `am-hagerigna`).
- Keep `hymnal` as a compatibility alias only.
- Do not duplicate SDA category ranges; update `HymnCategories` first.
- Do not allow sheet music screenshots or sheet music sharing.
- Run `dart format`, `flutter analyze`, and `flutter test` before submitting.

## Git

Use feature branches, not `main`. Keep commits small enough to review.
