# Release Blockers — Phase 1

Audit date: 2026-10-01 · Commit audited: `b4d78a0` (branch `reading-experience`) · Read-only audit.

> **Re-checked after Phase 2 (2026-10-01):** STATE-01, DATA-01, DL-01 fixed and covered by tests
> that fail on the old code. IOS-01, IOS-03 fixed in the project, still to be VERIFIED ON MAC.
> IOS-02 open until an Xcode 26 build succeeds (CI job added). STORE-01 is console work.
> Full status: `PHASE-1-SUMMARY.md` → "Re-check after Phase 2".

A finding is listed here when it could materially cause store rejection, broken core
functionality, data corruption, or inability to ship (see the blocker rule in the brief).
Everything else is in the area reports and `PHASE-1-SUMMARY.md`.

| ID | Severity | Platform | Confidence | One line |
|---|---|---|---|---|
| IOS-01 | CRITICAL | iOS | CONFIRMED | Deployment target is iOS 12.0; App Store Connect has required iOS 13+ since 2026-09-09 |
| IOS-02 | CRITICAL | iOS | Requirement CONFIRMED; compatibility NOT VERIFIABLE FROM WINDOWS | Uploads must be built with Xcode 26; Flutter 3.27.2 predates Flutter's Xcode 26 support |
| STATE-01 | HIGH | Both | CONFIRMED (reproduced) | Two quick edition switches can leave the wrong edition on screen, and favourites then land in the wrong edition |
| DATA-01 | HIGH | Both | CONFIRMED (reproduced) | History shows "no history yet" after every cold start until a hymn is opened |
| DL-01 | HIGH | Both | LIKELY | A stalled download connection never times out, so a bulk download can hang forever and block the queue |
| IOS-03 | HIGH | iOS | LIKELY | Hundreds of MB of re-downloadable media sit in Application Support with no iCloud-backup exclusion |
| STORE-01 | HIGH | Both | Requirement CONFIRMED; console status UNKNOWN | Data safety / App Privacy answers must declare analytics, optional contact email and diagnostics |

Not blockers but must be decided before release: `TEST-01` (audio is the least-tested core
feature: 5.3 % / 22.7 % line coverage), `CONTENT-01` (placeholder hymn in the bundled
offline copy), `L10N-01` (English error messages on Amharic screens).

---

## IOS-01 — iOS deployment target below the App Store minimum

- **Severity:** CRITICAL · **Confidence:** CONFIRMED · **Release blocker:** yes (iOS)
- **Requirement:** "iOS and iPadOS apps uploaded to App Store Connect must target iOS 13 or later." Effective 2026-09-09.
  Source: https://developer.apple.com/news/upcoming-requirements/ — verified 2026-10-01.
- **Evidence:**
  - `ios/Runner.xcodeproj/project.pbxproj` lines 349, 475, 526: `IPHONEOS_DEPLOYMENT_TARGET = 12.0;`
  - `ios/Flutter/AppFrameworkInfo.plist`: `MinimumOSVersion` = `12.0`
  - `ios/Podfile` is not committed (`git ls-files ios`), so the Pods target is not pinned either.
- **Impact:** an upload built from this project is refused by App Store Connect.
- **Remediation direction:** raise the Runner, RunnerTests and Pods deployment targets to at
  least 13.0 (check what the plugins need — likely higher), commit the Podfile.

## IOS-02 — Xcode 26 is mandatory; the Flutter version in use is not known to support it

- **Severity:** CRITICAL · **Confidence:** requirement CONFIRMED; build compatibility NOT VERIFIABLE FROM WINDOWS · **Release blocker:** until proven on a Mac
- **Requirement:** "Apps uploaded to App Store Connect must be built with Xcode 26 or later using an SDK for iOS 26…" since 2026-04-28.
  Source: https://developer.apple.com/news/upcoming-requirements/ — verified 2026-10-01.
- **Evidence:** CI and the project pin Flutter `3.27.2` (`.github/workflows/test.yml`, `nightly.yml`).
  Flutter's release notes state that full iOS 26 / Xcode 26 support arrived in Flutter 3.38
  (https://blog.flutter.dev/whats-new-in-flutter-3-38-3f7b258f7228; https://docs.flutter.dev/deployment/ios).
- **Impact:** if 3.27.2 cannot produce a valid Xcode 26 archive, there is no iOS release
  without a Flutter upgrade — which is the largest change this project could face and would
  touch every plugin.
- **Remediation direction:** on the Mac, run `flutter build ipa --release` with Xcode 26 and
  upload to TestFlight. Classify the result as VERIFIED ON MAC. If it fails, plan the Flutter
  upgrade as its own phase.

## STATE-01 — Edition switch race shows the wrong edition and misfiles favourites

- **Severity:** HIGH · **Confidence:** CONFIRMED (reproduced in a throwaway test outside the repo)
- **Evidence:**
  - `lib/features/hymns/presentation/bloc/hymns_bloc.dart:240-259` — `_onChangeVersion` saves the
    new version, awaits `getHymns`, then emits whatever came back. `flutter_bloc` 9 processes
    events concurrently by default and no transformer is set (`hymns_bloc.dart:116-122`), and
    unlike `_onLoadHymns` there is no load-key guard.
  - Probe: `ChangeVersion(sda_1960)` (slow, first sync) then `ChangeVersion(sda_new)` (fast).
    Output: `PROBE race selected=sda_new shown=sda_1960`.
  - Favourites: the hymn page dispatches `ToggleFavorite(hymn.displayNumber)`
    (`hymn_detail_page.dart:566`); the bloc calls `settingsRepository.toggleFavorite(number)`
    with no version (`hymns_bloc.dart:283`), which uses the **selected** version
    (`settings_service.dart:190-194`). With 1961 on screen and 2004 selected, tapping the
    heart on 1961 #165 stores `sda_new:165`.
- **Impact:** wrong book displayed under the right book's name; favourites silently written to
  another edition (data integrity). Most likely on first use of an edition, when the full sync
  takes seconds.
- **Remediation direction:** make version/language changes restartable (drop stale results, e.g.
  a `restartable()` transformer or a load generation check), and pass the displayed edition
  explicitly to the favourite toggle.

## DATA-01 — History appears empty after every cold start

- **Severity:** HIGH · **Confidence:** CONFIRMED (reproduced)
- **Evidence:** `HistoryService._prefs` is set only by `HistoryService.init()`
  (`lib/core/services/history_service.dart:370-372`), whose only call site is
  `hymn_detail_page.dart:121`. `history_page.dart:71` reads
  `HistoryService.getHistoryEntries()` without initialising; with `_prefs == null` it returns
  `[]`. Probe with two saved entries: `PROBE history before init=0 after init=2`.
- **Impact:** after any restart the History screen says there is no history until the reader
  opens a hymn. Nothing is deleted, but it looks like data loss.
- **Remediation direction:** initialise `HistoryService` in `initDependencies()` with the other
  stores (or have it share `SettingsService`'s `SharedPreferences`).

## DL-01 — Downloads have no inactivity timeout

- **Severity:** HIGH · **Confidence:** LIKELY (code-confirmed; not reproduced on a degraded network)
- **Evidence:** `lib/core/services/local_media_cache_service.dart:181-198` — the 45 s
  `.timeout` applies to `_client.send()` (headers only). `await for (final chunk in response.stream)`
  has no timeout, so a connection that stops delivering bytes without closing waits forever.
  `downloadMissingMedia` (`offline_media_download.dart:309-338`) awaits all six workers, and
  `OfflineDownloadController._runQueue` (`offline_download_controller.dart:533-563`) awaits the
  run before starting the next media type.
- **Impact:** on mobile networks that drop silently, a bulk download stalls at a fixed
  percentage indefinitely; the other media type's queued download never starts; cancel only
  takes effect after in-flight files finish, so cancel also appears to do nothing.
- **Remediation direction:** apply an idle timeout per chunk (e.g. `stream.timeout`) and treat it
  as a failed file.

## IOS-03 — Re-downloadable media is backed up to iCloud

- **Severity:** HIGH · **Confidence:** LIKELY (code-confirmed; review outcome not verifiable)
- **Evidence:** media and stored editions use `getApplicationSupportDirectory`
  (`local_media_cache_service.dart:127-132`, `edition_store.dart:269-271`). On iOS that
  directory is included in iCloud/device backups. No `isExcludedFromBackup` / `NSURLIsExcludedFromBackupKey`
  call exists anywhere (`grep` over `lib/` and `ios/`: no matches).
- **Impact:** a full audio + sheet-music install (hundreds of files per edition; exact bytes
  not measured in this audit) is copied into the user's iCloud backup. Apple's data-storage guidance tells apps to keep re-downloadable content out of
  backups; apps have been rejected for this. It also consumes users' iCloud quota.
- **Remediation direction:** store media under Caches, or mark the `media_cache` directory
  excluded from backup through a small platform call. Decide which: Caches can be purged by
  iOS under storage pressure, which would silently undo "keep offline".

## STORE-01 — Store privacy declarations must match what the app sends

- **Severity:** HIGH · **Confidence:** requirement CONFIRMED; console status UNKNOWN (not in the repository)
- **Evidence of collection:**
  - Anonymous usage events, on in every release build: `analytics_service.dart:92`
    (`_enabled = !kDebugMode || …`), sent on hymn open (`main_navigation_page.dart:307`) and
    category open (`categories_page.dart:235`).
  - Bug reports with optional contact email/phone, app version, platform, OS version, model,
    screen and language (`bug_report_queue_service.dart:327-367`, `report_bug_page.dart:87-106`).
  - IP address seen by the API and storage on every request (stated in the policy).
  - Sentry crash reports only when built with `WUDASE_SENTRY_DSN` (`crash_reporting.dart:22-28`).
- **Requirements:** Apple 5.1.1(i) privacy policy in-app and in App Store Connect
  (https://developer.apple.com/app-store/review/guidelines/, verified 2026-10-01) plus App
  Privacy answers; Google Play Data safety form and foreground-service declaration
  (https://support.google.com/googleplay/android-developer/answer/13392821, verified 2026-10-01).
- **Project status:** the policy exists, is live (HTTP 200 at
  `https://nawey99.github.io/amharic_hymnal_app/privacy.html`) and is linked in Settings
  (`settings_page.dart:40-41`). It names Supabase for media storage while the backend issues
  presigned R2 URLs — see PRIV-01 in `PRIVACY-AUDIT.md`.
- **Remediation direction:** fill both forms from the inventory in `PRIVACY-AUDIT.md`; reconcile
  the policy's processor list with production storage.
