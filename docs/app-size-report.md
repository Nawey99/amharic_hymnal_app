# App Size Report

Date: 2026-06-26

## Findings

PowerShell folder measurements from the project root:

| Path | Size |
| --- | ---: |
| `.` | 21274.94 MB |
| `android/app/build` | 18492.13 MB |
| `build` | 1834.42 MB |
| `.dart_tool` | 124.07 MB |
| `assets` | 146.72 MB |
| `assets/sheet_music` | 140.81 MB |
| `assets/category` | 4.40 MB |
| `assets/onboarding` | 0.02 MB |
| `backend` | 349.33 MB |

The reported 1.81 GB mobile concern is local build output, not source code alone. The largest generated folder is `android/app/build`, and it is ignored by Git. The largest source asset area is bundled sheet music.

## Build Output Notes

The Android Gradle config now generates a universal debug APK and syncs Flutter's top-level APK output after Gradle finishes. This prevents stale Android installs from using an old `build/app/outputs/flutter-apk/app-debug.apk`.

Verified build outputs:

| Artifact | Size | Notes |
| --- | ---: | --- |
| Debug APK | 1642.00 MB | Debug/universal build; not representative for store release. |
| Release APK, `android-arm64` | 159.1 MB | `flutter build apk --release --target-platform android-arm64 --analyze-size` |
| Release AAB, `android-arm64` | 147.6 MB | `flutter build appbundle --release --target-platform android-arm64 --analyze-size` |

Release size analysis shows Flutter assets are the dominant cost:

- APK: `assets/flutter_assets` is about 146 MB.
- AAB: `base/assets` is about 133 MB.

Release builds required adding the Play Core dependency because R8 otherwise reported missing Flutter deferred-component split-install classes.

## Recommendations

- Keep `build/`, `.dart_tool/`, `android/app/build/`, backend `node_modules/`, and temporary logs untracked.
- Keep current bundled sheet music until the remote download/cache path is fully deployed.
- For production, move sheet music and future audio to a CDN or backend media endpoint and cache on device through `SheetMusicRepository` and `DownloadRepository`.
- Run release size checks before store submission:

```powershell
flutter clean
flutter pub get
flutter build apk --release --target-platform android-arm64 --analyze-size
flutter build appbundle --release --target-platform android-arm64 --analyze-size
```

## Current Reason For Large Local Folder

The local folder is large because debug/release intermediates were generated locally. These are rebuildable and should not be committed.
