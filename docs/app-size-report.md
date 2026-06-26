# App Size Report

Measured on Windows from `D:\Church\App\amharic_hymnal_app`.

## Local Workspace Size

| Area | Size |
| --- | ---: |
| Project folder | 23534.11 MB |
| `assets/` | 146.72 MB |
| `assets/sheet_music/` | 140.81 MB |
| `assets/category/` | 4.40 MB |
| `assets/images/` | 0.45 MB |
| `assets/onboarding/` | 0.02 MB |
| `build/` | 1948.60 MB |
| `.dart_tool/` | 248.13 MB |

## What Made The App Large

The base APK was dominated by bundled sheet music. The sheet music folder alone is about 140.81 MB and category photos add another 4.40 MB. Generated folders such as `build/` and `.dart_tool/` are local-only and already ignored by Git.

## Packaging Change

`pubspec.yaml` no longer bundles:

- `assets/sheet_music/`
- `assets/category/*.webp`

Category UI now uses themed Material icons. Sheet music is resolved through repository/cache/download architecture and can be served by the content backend.

The base app still bundles small required assets:

- database JSON fallback
- Ethiopic font
- app background/favicon
- onboarding images
- audible dummy audio test tone

## Build Verification

Run:

```powershell
flutter clean
flutter pub get
flutter build apk --release --analyze-size
flutter build appbundle --release --analyze-size
```

The expected release package should be much smaller than the previous sheet-music bundled build. The exact APK/AAB output must be re-measured after each asset manifest change.

## Verified Release Output

After removing stale `android/app/build` output and rebuilding:

| Artifact | Size |
| --- | ---: |
| Release APK | 28.39 MB |
| Release AAB | 30.03 MB |

Packaged Flutter asset counts in the fresh release APK:

| Asset group | Count |
| --- | ---: |
| Sheet music | 0 |
| Category photos | 0 |
| Audio | 1 |
| Onboarding | 4 |
| Total app asset files | 10 |

## Current Post-Rebuild Workspace Snapshot

| Area | Size |
| --- | ---: |
| Project folder | 3305.58 MB |
| `assets/` | 146.82 MB |
| `assets/sheet_music/` | 140.81 MB |
| `assets/category/` | 4.40 MB |
| `assets/audio/` | 0.10 MB |
| `build/` | 1767.80 MB |
| `android/app/build/` | 616.21 MB |
| `.dart_tool/` | 95.03 MB |
# Final QA Update

Current source measurement on Windows:

- Repository working folder: 1790.72 MB before deleting generated build output
- `assets`: 61.22 MB
- `assets/audio`: 0.71 MB
- `assets/category`: 0.84 MB
- `assets/images`: 0.18 MB
- `assets/onboarding`: 0.02 MB
- `assets/sheet_music`: 58.44 MB
- `build`: 178.97 MB

The large repository size is generated build/cache output, not bundled Flutter media. The base app does not register `assets/sheet_music` or `assets/category` in `pubspec.yaml`; those folders are retained for backend/CDN/local development. The dummy hymn audio was replaced with `assets/audio/dummy_hymn_1.mp3` from the supplied audible MP3.

Final release size checks:

- Multi-ABI release APK: 28.7 MB
- `android-arm64` release APK with `--analyze-size`: 14.1 MB
- `android-arm64` release AAB with `--analyze-size`: 15.8 MB
