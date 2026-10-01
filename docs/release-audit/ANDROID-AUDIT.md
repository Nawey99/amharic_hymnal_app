# Android Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only (a release AAB was built for measurement;
no tracked file changed).

## Configuration (actual values)

| Item | Value | Evidence |
|---|---|---|
| applicationId / namespace | `com.nawey99.wudase` | `android/app/build.gradle` |
| minSdk / compileSdk / targetSdk | 24 / 36 / 36 | same |
| versionCode / versionName | from `pubspec.yaml` `1.0.0+1` | `flutter.versionCode` |
| AGP / Kotlin / Gradle | 8.9.1 / 2.2.0 / 8.11.1 | `settings.gradle`, `gradle-wrapper.properties` |
| NDK | 27.0.12077973 | `build.gradle` |
| Java target | 17 | `compileOptions` |
| Minify / shrink resources | on (R8, `proguard-android-optimize.txt` + `proguard-rules.pro`) | release buildType |
| Signing | `key.properties` (git-ignored) → `signingConfigs.release`; **null if the file is missing** | `build.gradle` |
| Backup | `allowBackup="false"`, `fullBackupContent="false"` | manifest |
| Cleartext | `usesCleartextTraffic="false"` (debug manifest re-enables for tooling) | manifests |
| Predictive back | `enableOnBackInvokedCallback="true"` | manifest |
| Activity | `MainActivity : AudioServiceActivity`, `singleTop`, `adjustResize` | `MainActivity.kt` |
| Permissions | INTERNET, WAKE_LOCK, FOREGROUND_SERVICE, FOREGROUND_SERVICE_MEDIA_PLAYBACK | manifest |
| Services | `com.ryanheise.audioservice.AudioService` `foregroundServiceType="mediaPlayback"`, `stopWithTask="true"`; `MediaButtonReceiver` | manifest |
| Orientation | not locked (no `screenOrientation`, no `setPreferredOrientations`) | grep |
| Screenshot blocking | `FLAG_SECURE` while sheet music is shown | `MainActivity.kt` |

## Measurements

`flutter build appbundle --release` → **exit 0**, `app-release.aab` **32.6 MB** (167 s).

16 KB page-size check (ELF `PT_LOAD` `p_align` read directly from every `.so` in the AAB):

| ABI | libraries | alignment | Result |
|---|---|---|---|
| arm64-v8a | libapp, libflutter (0x10000); libdartjni, libdatastore_shared_counter, libsentry, libsentry-android (0x4000) | ≥ 16 KB | PASS |
| x86_64 | same set | ≥ 16 KB | PASS |
| armeabi-v7a, x86 | 32-bit (requirement applies to 64-bit) | ≥ 16 KB anyway | PASS |

Per-ABI contents (arm64): native libs ≈ 20 MB uncompressed, dex 4.2 MB, assets 3.7 MB, res 1.2 MB.

## Store requirements (verified 2026-10-01)

| Requirement | Source | Status | Evidence |
|---|---|---|---|
| New apps/updates target API 36 from 2026-08-31 (extension to 2026-11-01 on request) | https://developer.android.com/google/play/requirements/target-sdk | MET | `targetSdk = 36` |
| 64-bit native code | https://support.google.com/googleplay/android-developer/answer/17492799 | MET | arm64-v8a and x86_64 present |
| 16 KB page size for native code (enforced now) | same; https://developer.android.com/guide/practices/page-sizes | MET | table above |
| Foreground service type declared in manifest **and** in Play Console App content, with description and demo video | https://support.google.com/googleplay/android-developer/answer/13392821 ; https://developer.android.com/develop/background-work/services/fgs/declare | Manifest MET; Console UNKNOWN | manifest service entry |
| New personal accounts (created after 2023-11-13): closed test, ≥12 testers opted in 14 consecutive days | https://support.google.com/googleplay/android-developer/answer/14151465 | UNKNOWN (account type/date not in repo) | — |
| Data safety form | Play Console | UNKNOWN | see PRIVACY-AUDIT.md |
| Upcoming (not yet enforced): memory "bad behaviour" and code-optimisation thresholds Feb 2027 | answer/17492799 | INFO | — |

## Findings

### AND-02 — No backup of favourites, history or settings · LOW · CONFIRMED (product decision to document)
`allowBackup="false"` excludes SharedPreferences from cloud backup and restore, so a reader
moving to a new phone loses favourites and history. Turning backup on without rules would
also try to back up the media cache (Auto Backup skips apps over 25 MB entirely). If the
decision stands, say so in the store listing/FAQ; otherwise add `dataExtractionRules` that
include only preferences.

### AND-03 — Release build silently unsigned without `key.properties` · LOW · CONFIRMED
`signingConfig = keystorePropertiesFile.exists() ? signingConfigs.release : null`. A CI or new
machine produces an unsigned bundle without failing. CI builds `appbundle --release`
(`test.yml`) and would pass while producing an unusable artifact. Direction: fail release
builds without signing material, or make CI's purpose (compile check) explicit.

### AUD-01 — Notification channel naming · LOW · CONFIRMED
Channel id `com.example.amharic_hymnal_app.audio`; name "Audio Playback" and description
"Hymn accompaniment playback controls" are English literals shown in Android's system
notification settings (`global_audio_service.dart:31-33, 76-79`). Changing the id after
release leaves a stale channel on users' devices, so decide before first release.

### CODE-01 (Android part) — stray `2` on `android/build.gradle:7` · LOW · CONFIRMED

### Platform behaviour notes (INFO)
- Android 13+ notification permission: not requested; media-session notifications from a
  media-playback foreground service are exempt, so playback controls still appear. VERIFIED by
  reasoning only — confirm on an Android 13+ device with notifications denied.
- Android 15/16 edge-to-edge: status/navigation bars are made transparent in `main.dart:44-55`;
  layouts use `SafeArea`. No overflow seen in widget tests; not audited screen by screen on a
  device in this phase.
- Android 16 (target 36) ignores orientation/resizability restrictions on large screens; the
  app sets none, so nothing changes.
- `stopWithTask="true"` plus `onTaskRemoved → stop()` (`hymnal_audio_handler.dart:530-534`):
  swiping the app away stops playback by design.
- Audio focus/noisy events: `AudioPlayer(handleInterruptions: true)` with a music session
  (`hymnal_audio_handler.dart:368-399`). Calls, Bluetooth disconnect and headphone unplug are
  handled by just_audio/audio_session; **not verified on device** in this phase.

## Device verification still required (Windows can do this)
Install the signed AAB via internal testing (or `bundletool build-apks`) on an Android 14+ and an
Android 7 (API 24) device and check: first launch offline, background playback with screen off,
lock-screen controls, Bluetooth disconnect pause, call interruption, bulk download with airplane
mode toggled mid-way, and the sheet-music screenshot block.
