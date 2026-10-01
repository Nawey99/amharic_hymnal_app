# Android Security Audit

Audit date: 2026-10-01. All items **VERIFIED ON WINDOWS** by source review and
by inspecting the built release APK with `aapt2` and `apksigner` (build-tools
36.0.0), unless marked otherwise. No device or emulator test was run.

Artifact: `build/app/outputs/flutter-apk/app-release.apk`, 63.8 MB, universal,
built 2026-09-29. `applicationId` `com.nawey99.wudase`, versionCode 1,
versionName 1.0.0, minSdk 24, targetSdk 36, compileSdk 36.

## Application flags (built manifest)

| Attribute | Value | Assessment |
| --- | --- | --- |
| `debuggable` | absent (false) | Correct |
| `allowBackup` | false | Correct |
| `fullBackupContent` | false | Correct |
| `usesCleartextTraffic` | false | Correct |
| `networkSecurityConfig` | absent | Platform defaults; system CAs only |
| `extractNativeLibs` | false | Fine |
| `testOnly` | absent | Correct |
| `enableOnBackInvokedCallback` | true | Not security-relevant |

## Components

| Component | Type | Exported | Guard | Origin | Assessment |
| --- | --- | --- | --- | --- | --- |
| `.MainActivity` | activity | true | none | app | Launcher only: one `MAIN`/`LAUNCHER` filter. `launchMode="singleTop"`. Reads no intent data. |
| `com.ryanheise.audioservice.AudioService` | service | true | `android.permission.BIND_MEDIA_BROWSER_SERVICE` | audio_service | Media browser service. The permission name is not one Android defines (F-19). |
| `com.ryanheise.audioservice.MediaButtonReceiver` | receiver | true | none | audio_service | Standard for media buttons; accepts play/pause style key events only. |
| `dev.fluttercommunity.plus.share.ShareFileProvider` | provider | false | `grantUriPermissions=true` | share_plus | Never handed a file by this app (text share only). |
| `dev.fluttercommunity.plus.share.SharePlusPendingIntent` | receiver | false | — | share_plus | Fine |
| `io.flutter.plugins.urllauncher.WebViewActivity` | activity | false | — | url_launcher | Present but unused: both links launch with `LaunchMode.externalApplication`. |
| `io.sentry.android.core.SentryPerformanceProvider`, `io.sentry.ndk.SentryNdkPreloadProvider` | provider | false | — | sentry_flutter | Present in every build; Sentry initialises only when a DSN is compiled in. |
| `androidx.startup.InitializationProvider` | provider | false | — | AndroidX | Fine |
| `androidx.profileinstaller.ProfileInstallReceiver` | receiver | true | `android.permission.DUMP` | AndroidX | Standard; `DUMP` is held only by the shell and system. |
| `androidx.test.core.app.InstrumentationActivityInvoker$BootstrapActivity`, `$EmptyActivity`, `$EmptyFloatingActivity` | activity | **true** | none | test dependency | **Should not be in a release build (F-05).** Empty activities with a `LAUNCHER`-category filter and no action; they do not create launcher icons. |

Can another app abuse a component? It can start `MainActivity` (which ignores
intent contents), send media-button events (pause or resume a hymn), and start
three blank test activities. None exposes data or a privileged action.

## Permissions

| Permission | Why | Used by | Runtime? | Dangerous? | Necessary? |
| --- | --- | --- | --- | --- | --- |
| `INTERNET` | API and media | app | No | No | Yes |
| `WAKE_LOCK` | Keep screen on; audio playback | wakelock_plus, audio_service | No | No | Yes |
| `FOREGROUND_SERVICE` | Background audio | audio_service | No | No | Yes |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Required type on API 34+ | audio_service | No | No | Yes |
| `ACCESS_NETWORK_STATE` | Merged from a plugin | plugin | No | No | Harmless |
| `REORDER_TASKS` | Merged from `androidx.test` | test dependency | No | No | **No (F-05)** |
| `com.nawey99.wudase.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX internal, signature-level | AndroidX | No | No | Standard |

No dangerous or runtime permission is requested: no storage, location, contacts,
camera, microphone, notifications or phone state. `POST_NOTIFICATIONS` is not
declared; on Android 13+ the media notification still appears as a media
session, which is a functional matter to confirm on a device. The manifest
comment on `INTERNET` ("Required for url_launcher") is out of date; the
permission is needed for the API.

`<queries>` declares `PROCESS_TEXT` (Flutter engine) and, from the test
dependency, `androidx.test.orchestrator`, `androidx.test.services`,
`com.google.android.apps.common.testing.services` (F-05).

## Intents and deep links

- No `VIEW` filter, no custom scheme, no App Links. **No deep-link surface.**
- No `SEND`, `PROCESS_TEXT` or file-open filter: other apps cannot hand this app content.
- Outbound: two fixed HTTPS URLs via `url_launcher` in the external browser, and a plain-text share. Neither is built from server data.

## WebView

`url_launcher` ships a `WebViewActivity` (not exported). The app never requests
in-app web view mode. No Dart code references a WebView and no JavaScript bridge
exists.

**NO WEBVIEW ATTACK SURFACE FOUND** in application code.

## File sharing

No file is ever shared, so the FileProvider grants no URI. Its path
configuration is `share_plus`'s own (a cache subdirectory) and was not altered.
No app database or media file can be exposed through it by this app's code.

## Native code

| Library | Origin |
| --- | --- |
| `libapp.so` | Compiled Dart (AOT) |
| `libflutter.so` | Flutter engine 3.27.2 |
| `libsentry.so`, `libsentry-android.so` | Sentry NDK |
| `libdartjni.so` | `jni` package (Sentry dependency) |
| `libdatastore_shared_counter.so` | AndroidX DataStore (shared_preferences) |

Project-owned native code is `MainActivity.kt` (56 lines): one method channel,
`wudase/secure_screen`, with methods `enable`, `disable`, `isCaptured` that set
or clear `FLAG_SECURE`. It takes no arguments and touches no file, intent or
network. No JNI is written by the project.

## Backup and data extraction

`allowBackup="false"`: no adb backup, no cloud backup, no device transfer of
prefs, the secure-storage file, the catalogue cache or media. No credential is
stored that a backup could leak in any case.

## Release build, shrinking and symbols

| Item | Finding |
| --- | --- |
| R8 | `minifyEnabled true`, `shrinkResources true`, `proguard-android-optimize.txt` plus a 10-line project rules file |
| Mapping | `build/app/outputs/mapping/release/mapping.txt` (R8 8.9.32); keep it per release for crash symbolication, never ship it |
| Native debug symbols | `native-debug-symbols.zip` produced separately |
| Dart obfuscation | Not enabled (F-20) |
| Debug artefacts in the APK | Test dependency remnants (F-05); no debug endpoint, mock API or test credential |

## Signing

| Item | Finding | Status |
| --- | --- | --- |
| Release config | Reads `android/key.properties`; if absent, `signingConfig` is null and the output is unsigned (`build.gradle:50-66`) | VERIFIED |
| Inspected APK | Signed, one signer, APK Signature Scheme v2 only (v1 not needed at minSdk 24), RSA 2048 | VERIFIED (`apksigner verify`) |
| Certificate SHA-256 | `bb856963507c2a40e69a0e05ac0f463885dc83a454bae4aabbc3fa594bf7e7b0` | Compare with Play Console |
| Debug keystore used for release | No | VERIFIED: the certificate DN is the developer's, not `Android Debug` |
| Keystore location | `D:/Church/App/keys/wudase-upload.jks`, outside the repository | VERIFIED |
| Passwords | Plaintext in git-ignored `android/key.properties` (F-14) | VERIFIED |
| Committed to git | Never | VERIFIED across all refs |
| CI signing | None: CI builds an unsigned bundle; no signing secret in workflows | VERIFIED |
| Play App Signing | — | **NOT VERIFIABLE** without Play Console access |
| v3 signature / key rotation | Not present | Informational |

## Root, emulator, tampering, instrumentation

| Mechanism | Present | Relevance to this app |
| --- | --- | --- |
| Root detection | No | Unnecessary: nothing on the device is worth protecting from its owner |
| Emulator detection | No | Unnecessary |
| Debugger / Frida detection | No | Unnecessary |
| Integrity / tamper check | No (Play Integrity not used) | Unnecessary: no server decision depends on the client being genuine |
| Obfuscation | R8 yes, Dart no | Optional |
| `FLAG_SECURE` on sheet music | Yes | Courtesy control; trivially bypassed with instrumentation, which is acceptable |

The app runs normally on rooted devices and emulators, which is the right
behaviour for a hymnal. A repackaged copy could show altered content to people
who install it from outside the store; that is a distribution-channel risk that
store signing addresses.

## Not verified

| Item | Classification |
| --- | --- |
| Runtime behaviour of exported components against a second app | REQUIRES PHYSICAL DEVICE |
| `FLAG_SECURE` effectiveness and recent-apps thumbnail | REQUIRES PHYSICAL DEVICE (also listed in `MAINTAINER_ACTIONS.md`) |
| EncryptedSharedPreferences file contents on device | REQUIRES PHYSICAL DEVICE |
| Logcat during a release run | REQUIRES PHYSICAL DEVICE |
| The `.aab` (dated 2026-09-24, older than the APK) | Not inspected; `bundletool` NOT AVAILABLE |
| MobSF, jadx, apktool | NOT AVAILABLE; `aapt2`, `apksigner`, `strings`, `unzip` were used instead |

## Findings from this area

F-05 (LOW), F-14 (LOW), F-19, F-20, F-23 (INFO).
