# Build, Release, Size & Download Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only.

## Commands run and results

| Command | Result |
|---|---|
| `flutter analyze lib test` | No issues |
| `dart format --output=none --set-exit-if-changed .` | 216 files, 0 changed |
| `flutter test --coverage` (coverage written to scratch, not the repo) | **823 passed, 1 skipped, 0 failed**; line coverage 83.4 % (7787/9340) |
| `flutter build appbundle --release` | exit 0, 32.6 MB, signed with the local upload key (key material not read) |
| Stricter lints on a scratch copy (`discarded_futures`, `unawaited_futures`, `cancel_subscriptions`, `close_sinks`, `avoid_dynamic_calls`, …) | 156 infos: 65 discarded futures (mostly intentional fire-and-forget), 51 catch-alls, 11 dynamic calls, 1 false-positive subscription |
| `flutter pub outdated` | see DEPENDENCY-AUDIT.md |
| iOS build | NOT VERIFIABLE FROM WINDOWS |

`git status` after all of the above: unchanged apart from the pre-existing modified desktop plugin
registrants and the two untracked `docs/churchofjesuschrist_*` files (both existed before the audit).

## Release configuration

| Item | State | Evidence |
|---|---|---|
| Version | `1.0.0+1` | `pubspec.yaml:19` |
| Flavors / environments | none; environment by `--dart-define` (`WUDASE_CONTENT_API_URL`, `WUDASE_SENTRY_DSN`, `WUDASE_SENTRY_ENVIRONMENT`, `WUDASE_ANALYTICS`, `WUDASE_FRAME_STATS`, `WUDASE_FORCE_ONBOARDING`) | grep `fromEnvironment` |
| Production API default | `https://amharichymnalbackend.vercel.app/api/v1`; HTTPS enforced in release | `content_api_config.dart` |
| Obfuscation / symbols | **not used** (`--obfuscate --split-debug-info` absent from CI and docs) | `test.yml` |
| Crash reporting | off unless DSN given; no symbol upload configured | `crash_reporting.dart` |
| Android signing | key.properties (ignored); unsigned if absent (AND-03) | `build.gradle` |
| iOS signing | automatic, no team committed | `project.pbxproj` |
| App label / icon | `ውዳሴ`; launcher icons present for both platforms | manifests, `AppIcon.appiconset` |
| Splash | Android `launch_background.xml`; iOS `LaunchScreen.storyboard`; Flutter shows a blank coloured scaffold during init | `main.dart:138-146` |
| Debug leakage | `debugPrint` calls are `kDebugMode`-guarded; `FrameStatsProbe` off unless defined; no `print` in release paths found | grep |

## CI/CD (`.github/workflows`)

- `test.yml`: secret scan (`tool/security_scan.mjs`), dependency advisories, format, analyze,
  tests with an 80 % coverage gate (`tool/coverage_gate.dart`), Android debug APK, release AAB,
  web build, emulator full-app tests.
- `nightly.yml`: live API tests (`test_live/`), full-app tests on Android 24.

### CI-01 — No iOS job · MEDIUM · CONFIRMED
No macOS runner; nothing compiles the iOS project, runs `pod install`, or checks the deployment
target. IOS-01 and IOS-02 would have been caught by one `flutter build ios --no-codesign` job.

### CI-02 — Release builds are not reproducible from CI · LOW · CONFIRMED
The CI release AAB is unsigned (no key) and unobfuscated; the shipped artifact is built on a
developer machine. No documented release script.

### REL-01 — No obfuscation/symbol strategy · LOW · CONFIRMED
If Sentry is ever enabled for store builds, stack traces need the Dart symbols; if obfuscation is
added, `--split-debug-info` output must be archived per release. Decide before the first release,
because symbols cannot be recovered afterwards.

## Application size

| Component (AAB, per ABI where relevant) | Size |
|---|---|
| Whole AAB (4 ABIs) | 32.6 MB |
| arm64-v8a native libs (libflutter 10.8 MB, libapp 8.5 MB, Sentry 0.87 MB, others) | ~20 MB uncompressed |
| dex | 4.2 MB |
| Flutter assets | 3.7 MB — 6 fonts 2.43 MB, `SDA_Hymnal.json` 552 KB, `CupertinoIcons.ttf` 258 KB (unused), `background.jpg` 185 KB, `HagerignaData.json` 164 KB |
| res | 1.2 MB |

The installed base app is far below the 200–300 MB target (well under 50 MB per device by these
components). No audio or sheet music is bundled; `MediaReference` rejects asset paths by design
(`media_reference.dart:7-11`). Reduction opportunities, all small: drop `cupertino_icons`
(258 KB); Sentry native libs if crash reporting will never ship (~0.85 MB/ABI); the three serif
weights (~1.3 MB) if English UI is rare.

Downloaded media size was **not measured** in this phase (requires a device install of each
edition).

## Download system

| Concern | State | Evidence |
|---|---|---|
| Routing | API URL → 302 → presigned storage; bytes never through Vercel | backend `download-service.ts:155-157` |
| Integrity | size + SHA-256 verified before use; content-addressed by checksum; shared files downloaded once | `local_media_cache_service.dart:204-218, 273-280` |
| Atomicity | `.part` file then rename; failed download deletes its temp | `:171-234` |
| Concurrency | 6 parallel per bulk run; one media type at a time | `offline_media_download.dart:284`, controller |
| Resume | no byte-range resume; re-running fetches only missing files | — |
| Cancellation | stops after files in flight finish | `offline_download_controller.dart:516-531` |
| Stale cleanup | files not referenced by any stored edition pruned after each sync | `hymn_remote_data_source.dart:193-208` |
| Size disclosure | sizes shown; Wi-Fi recommended in the text; automatic re-downloads capped by `automaticUpdateLimitBytes` | `offline_download_flow.dart:35, 79-91, 237-243, 288` |

### DL-01 — No inactivity timeout · HIGH · LIKELY — see RELEASE-BLOCKERS.md

### DL-02 — Interrupted downloads leave `.part` files forever · MEDIUM · CONFIRMED
If the process is killed mid-download, `<sha>.<ext>.<timestamp>.part` remains. `retainOnly` only
matches `^<sha256>(\.ext)?$` (`local_media_cache_service.dart:253-270`), and nothing else deletes
`.part` files. Each interrupted bulk download can leave up to six partial files.

### DL-03 — Bulk downloads run only while the app is in the foreground · MEDIUM · CONFIRMED (code) / LIKELY (behaviour)
Downloads are plain Dart HTTP in the UI isolate; no background transfer (Android WorkManager /
iOS background `URLSession`). iOS suspends the app shortly after it leaves the foreground, so a
multi-hundred-MB audio install needs the app kept open. Files completed so far are kept.

### DL-04 — No free-space check before a bulk install · MEDIUM · CONFIRMED
The plan knows `missingBytes` but never compares it with free storage; on a full device each file
fails individually and is counted as `failed`. The app cannot tell Wi-Fi from mobile data (no
connectivity dependency) — the UI acknowledges this and recommends Wi-Fi in text.

### DL-05 — Cache files are verified by size only on reuse · INFO
`cachedPath` accepts a file whose length matches (`:135-148`); the checksum is checked once, at
download. A file corrupted later on disk is not detected. Acceptable; noted.
