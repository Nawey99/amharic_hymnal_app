# Phase 1 — Forensic Pre-Release Audit: Summary

Audit date: 2026-10-01 · Commit `b4d78a0` (branch `reading-experience`) · Flutter 3.27.2 / Dart 3.6.
Phase 1 was read-only: the only files created are the twelve documents in `docs/release-audit/`.
Throwaway probes, stricter lints and coverage output were written to a scratch directory outside
the repository. A release AAB was built into the git-ignored `build/` directory for measurement.

## Audit scope
Whole Flutter repository (lib, tests, Android, iOS, CI, assets, docs), its integration with the
hymnal API (client code, plus read-only inspection of the backend's download flow and one GET to
the live API), and current Google Play / App Store requirements verified from official sources on
2026-10-01. Not covered: on-device profiling, screen-reader sessions, anything requiring a Mac,
Play/App Store Connect console state, backend internals beyond the download redirect.

## Repository overview
119 Dart files / 25,652 lines in `lib/`; 97 test files; 823 tests passing; 83.4 % line coverage;
analyzer and formatter clean. Android config current (compile/target 36, AGP 8.9.1). iOS project
largely template plus a secure-screen channel. CI: GitHub Actions for Android and web only.

## Architecture summary
Clean-architecture layout for hymns (bloc → use cases → repository → data sources), with many
singleton services alongside. Content is **API-first**: each edition syncs from the Vercel API
(`/hymn-versions` with ETag, `/sync` paged deltas), is stored on the device atomically, and falls
back to bundled JSON only when the API path fails and the edition is one of the three bundled ones.
Media is downloaded on demand through a 302 to presigned object storage, verified by SHA-256 and
stored content-addressed, so shared files download once and large bytes never pass through
Vercel. Audio plays downloaded files through just_audio inside audio_service. One app-wide
`HymnsBloc` drives all five tabs. Details: `ARCHITECTURE-AUDIT.md`.

## Major strengths (evidence in the area reports)
- Thoughtful sync: delta + periodic full refresh, ETag, rate-limit backoff, in-flight dedup,
  offline service from the stored copy, retired editions forgotten.
- Download integrity: size + checksum verification, atomic rename, content addressing, pruning of
  unreferenced files, honest size disclosure and Wi-Fi advice.
- Editions discovered from the API rather than hard-coded; favourites and history are per edition.
- Android store requirements met, including 16 KB alignment (measured).
- Privacy posture: no ads, no tracking, PII scrubbed, encrypted report queue, live policy that
  mostly matches the code.
- Exact Fidel ordering in the index; proper Ethiopic font weights.
- Large automated suite with contract tests, accessibility guideline tests and a coverage gate.

## Findings by severity

| Severity | Count | IDs |
|---|---|---|
| CRITICAL | 2 | IOS-01, IOS-02 |
| HIGH | 6 | STATE-01, DATA-01, DL-01, IOS-03, STORE-01, TEST-01 |
| MEDIUM | 17 | ARCH-01, ERR-01, DATA-02, DATA-03, CONTENT-01, IOS-04, A11Y-01, L10N-01, PERF-01, CI-01, DL-02, DL-03, DL-04, PRIV-01, TEST-02, TEST-03, DOC-01 |
| LOW | 19 | CODE-01, CODE-02, AND-02, AND-03, AUD-01, IOS-05, IOS-06, IOS-07, A11Y-03, L10N-02, PERF-02, PERF-03, PERF-04, CI-02, REL-01, DEP-02, PRIV-02, TEST-04, SRCH-01 |
| INFO | 14 | SCALE-01, MEM-01, MEM-02, IOS-08, DEP-03, DEP-04, DL-05, PRIV-03, PRIV-04, PRIV-05, A11Y-02, L10N-03, TEST-05, TEST-06 |

(DEP-01 in `DEPENDENCY-AUDIT.md` is the dependency side of IOS-02 and is not counted twice.)

### CRITICAL
- **IOS-01** iOS deployment target 12.0; uploads require iOS 13+ since 2026-09-09. CONFIRMED.
- **IOS-02** Uploads require Xcode 26; Flutter 3.27.2 predates Flutter's Xcode 26 support. Requirement CONFIRMED, compatibility NOT VERIFIABLE FROM WINDOWS.

### HIGH
- **STATE-01** Overlapping edition switches display the wrong edition and can file favourites under another edition. CONFIRMED by reproduction.
- **DATA-01** History reads as empty after every cold start until a hymn is opened. CONFIRMED by reproduction.
- **DL-01** No idle timeout on download streams; a stalled bulk download hangs and blocks the queue. LIKELY.
- **IOS-03** Re-downloadable media stored in a backed-up location without exclusion. LIKELY.
- **STORE-01** Data safety / App Privacy declarations must cover analytics (always on), optional contact details and diagnostics. Console state UNKNOWN.
- **TEST-01** Audio services at 5.3 % / 22.7 % coverage; no automated background/lock-screen checks. CONFIRMED.

### MEDIUM (one line each; details in the area reports)
ARCH-01 shared bloc carries per-tab search state · ERR-01 failure kinds collapse to two English messages · DATA-02 bundled-data errors appear as an empty hymnal · DATA-03 retired edition appears as an empty hymnal · CONTENT-01 placeholder "test song" #121 in bundled Hagerigna data (inactive on the live API) · IOS-04 no app privacy manifest verified · A11Y-01 next/previous hymn is swipe-only · L10N-01 English error strings on Amharic screens · PERF-01 per-chunk progress notifications · CI-01 no iOS CI · DL-02 `.part` files never cleaned · DL-03 foreground-only bulk downloads · DL-04 no free-space check · PRIV-01 policy's processor list likely omits the real media host · TEST-02 no cold-start tests · TEST-03 no bloc concurrency tests · DOC-01 documentation gaps (below).

### LOW
Template/notification-channel leftovers, stray Gradle line, unsigned-release fallback, iOS
localisation/export/Podfile hygiene, 200 % text cap, small English strings, UI-isolate JSON
decode, uncached search normalisation, no obfuscation/symbol plan, unused `cupertino_icons`,
unused data-collection flag, tests pinning #121, and:
- **SRCH-01** Ranking order differs from the stated intent: implemented order is number (rank 0) →
  exact Amharic title (1) → exact English title (2) → Amharic prefix/contains (3/4) → English
  prefix/contains (3/4) → lyrics (8) (`search_engine.dart:173-305`). The brief's order puts English
  title after Amharic prefix and contains; here an exact English title outranks an Amharic prefix
  match. Deterministic tie-breaks (occurrences, number, title) are in place. LOW · CONFIRMED.

## Release blockers
IOS-01, IOS-02, STATE-01, DATA-01, DL-01, IOS-03, STORE-01 — see `RELEASE-BLOCKERS.md`.
Android is blocked only by the cross-platform items (STATE-01, DATA-01, DL-01, STORE-01).

## Windows-verifiable items (can be done without a Mac)
All Android device checks (`ANDROID-AUDIT.md`), low-end performance measurement
(`PERFORMANCE-AUDIT.md`), responsive/text-scale widget matrix, TalkBack pass, reproduction of
DL-01/DL-02 with a throttled network and a killed process, Play Console declarations,
production storage host for PRIV-01.

## Mac-only verification items
Xcode 26 build + TestFlight upload (IOS-02); deployment-target change validation with CocoaPods
(IOS-01); privacy report (IOS-04); iCloud backup size (IOS-03); background audio, Control Center,
interruptions, route changes; VoiceOver; iPad layouts; secure-screen overlay.

## Store-readiness status
Google Play: technically ready on all repository-checkable requirements; console declarations and
the closed-testing requirement are unknown. App Store: **not ready** (see `STORE-READINESS-AUDIT.md`).

## Test-readiness status
Strong unit/widget base (823 passing, 83.4 %), but the riskiest areas — audio, restart, concurrency,
iOS — are the least covered. Not sufficient on its own to sign off audio or iOS.

## Performance concerns
Not measured on device in this phase. Code is already optimised in the obvious places (blur,
image decode size, memoised lists). Remaining risks are download-progress rebuild storms,
UI-isolate JSON decoding of whole editions, and a first-launch path that waits on network
timeouts (up to ~20 s on a bad network) before falling back to bundled data.

## Data/integration concerns
Wrong-edition writes (STATE-01); favourites keyed by number, not song id, so server renumbering
would retarget them (SCALE-01); empty-list-as-success for retired editions and broken bundles
(DATA-02/03); error kinds lost before the UI (ERR-01); bundled placeholder content (CONTENT-01).

### DOC-01 — Documentation gaps · MEDIUM · CONFIRMED
No documents cover: release process (versioning, building, signing, uploading), iOS/TestFlight
release, rollback, backup/recovery of the database and media bucket, or store-console
declarations. `grep` across `docs/` and root `*.md` for "rollback", "backup", "TestFlight",
"App Store Connect", "release process" finds nothing relevant. Root holds five stale status files.
Existing docs cover architecture, local development, media, privacy and QA checklists.

## Recommended remediation order (Phase 2 proposal — not started)
1. **iOS toolchain decision (IOS-02) on the Mac first**, because its answer (Flutter upgrade or not)
   changes the scope of everything else. In the same session: deployment target ≥ 13 (IOS-01),
   commit the Podfile, privacy report (IOS-04).
2. **Correctness blockers:** STATE-01 (restartable version/language changes + explicit edition on
   favourite toggle), DATA-01 (initialise history at startup), DL-01 (stream idle timeout) — each
   with the regression test that would have caught it (TEST-02, TEST-03).
3. **Storage placement:** IOS-03 backup exclusion; DL-02 `.part` cleanup; DL-04 free-space check.
4. **Store paperwork:** PRIV-01 policy provider list, STORE-01 forms, FGS declaration, iOS keys
   (IOS-05/06).
5. **User-facing quality:** L10N-01/ERR-01 localised, specific error states; DATA-02/03 explicit
   states; CONTENT-01 remove the placeholder (and the tests that pin it); A11Y-01 semantic actions.
6. **Audio test coverage** (TEST-01) and an Android Patrol background-playback flow.
7. **CI:** add an iOS build job (CI-01); decide obfuscation/symbols (REL-01).
8. Low/INFO items opportunistically.

Phase 1 is complete. No remediation has been started; awaiting approval.

---

# Re-check after Phase 2 — 2026-10-01

Phase 2 was approved ("fix everything and do the check again"). Nothing is committed. This
section records the re-check; the sections above are the original Phase 1 findings, left as
they were.

## Commands re-run

| Check | Result |
|---|---|
| `flutter analyze lib test` | No issues |
| `dart format --set-exit-if-changed .` | 220 files, 0 changed |
| `flutter test` | **847 passed**, 1 skipped, 0 failed (was 823) |
| Coverage | **84.4 %** (was 83.4 %); `hymnal_audio_handler.dart` **78.3 %** (was 5.3 %) |
| `flutter build appbundle --release` | exit 0, 32.5 MB; `CupertinoIcons.ttf` no longer bundled |
| 16 KB ELF alignment, all 64-bit `.so` | 0 failures |
| Release-mode (profile, AOT) run on an Android 16 **16 KB-page** emulator | starts, no errors in logcat; History shows saved entries on a cold start before any hymn is opened; the usage-counts switch renders; the bulk-download flow (which now queries free space through the new Kotlin channel) reaches its confirmation dialog |
| Regression tests vs. the original code | the History, edition-race, stalled-download and partial-file tests **fail** with the old code restored (checked in a scratch copy) and pass with the fixes |
| iOS build | NOT VERIFIABLE FROM WINDOWS — a CI job now builds it with Xcode 26 |

## Status of every finding

| ID | Status | What changed |
|---|---|---|
| IOS-01 | **FIXED** (verify on Mac) | Deployment target 13.0 in all three build configurations, `AppFrameworkInfo.plist`, and a committed `ios/Podfile` (`platform :ios, '13.0'`, pods raised to 13.0). Every plugin podspec needs ≤ 12.0. |
| IOS-02 | **OPEN — needs Xcode 26** | Cannot be settled from Windows. New CI job *Build iOS (unsigned, Xcode 26)* builds with Flutter 3.27.2 on Xcode 26 and fails loudly if it cannot. |
| STATE-01 | **FIXED** | Load generation in `HymnsBloc` drops answers overtaken by a newer request; `ToggleFavorite` carries the edition shown. 6 tests. |
| DATA-01 | **FIXED** | `HistoryService.init()` in `initDependencies()`. Test + device check. |
| DL-01 | **FIXED** | 30 s idle timeout on download streams. Test. |
| IOS-03 | **FIXED** (verify on Mac) | `media_cache/` and `content_cache/` marked `isExcludedFromBackup` via a new `wudase/storage` channel. |
| STORE-01 | **OWNER ACTION** | Console forms. `ios/Runner/PrivacyInfo.xcprivacy` and `docs/RELEASE.md` §3 give the answers. |
| TEST-01 | **FIXED** | 9 handler tests on a fake just_audio platform. `GlobalAudioService` stays at 25.8 % (needs `AudioService.init`). |
| ARCH-01 | **MITIGATED** | Search no longer emits a spinner app-wide; stale search answers are dropped; app resume no longer replaces search results. Per-page search state was not refactored out of the shared bloc. |
| ERR-01 | **FIXED** | `HymnsErrorKind` (load failed / needs connection / edition withdrawn / search failed / not found / lookup failed); `NotFoundFailure`, `EditionUnavailableFailure`. |
| DATA-02 | **FIXED** | Bundled-data errors are thrown, not returned as an empty list. |
| DATA-03 | **FIXED** | Withdrawn edition → `EditionUnavailableException` → "no longer available, choose another"; no bundled substitute. |
| CONTENT-01 | **FIXED** | Placeholder #121 removed from the bundled file (120 songs); a test rejects placeholders. |
| IOS-04 | **FIXED** (verify on Mac) | App privacy manifest added and registered in the Xcode project. |
| A11Y-01 | **FIXED** | Screen-reader custom actions "Next hymn" / "Previous hymn". |
| L10N-01 | **FIXED** | Errors worded per language by `hymnsErrorText`. |
| PERF-01 | **FIXED** | Progress notifications at most every 100 ms. |
| CI-01 | **FIXED** | iOS job added (see IOS-02). |
| DL-02 | **FIXED** | Orphaned `.part` files cleared before a run's first download/write. Test. |
| DL-03 | **NOT FIXED — decision needed** | True background transfer needs WorkManager / background `URLSession` (a new plugin and native work). Files already saved are kept and a retry fetches only what is missing. |
| DL-04 | **FIXED** | Free space checked (50 MB spare) before a bulk download. 2 tests. |
| PRIV-01 | **WITHDRAWN — false positive** | A live download redirect goes to `*.supabase.co`; the backend README says production media is Supabase Storage. The policy was right. |
| TEST-02 / TEST-03 | **FIXED** | Cold-start and concurrency tests added. |
| DOC-01 | **FIXED** | `docs/RELEASE.md`: build, symbols, signing, upload, declarations, backing out, backup/recovery. |
| CODE-01 | **FIXED** (except root files) | Stale comment, duplicate tooltip, getter side effect (migration moved into `init`), stray Gradle `2`. The five stale root status files were left for the owner to remove. |
| CODE-02 | **FIXED** | Real in-flight de-duplication in `JsonDataSource`. |
| AND-02 | **KEPT BY DESIGN** | No backup, consistent with the policy's "never leave your device"; documented in `RELEASE.md`. |
| AND-03 | **FIXED** | Gradle warns loudly when building unsigned. |
| AUD-01 / L10N-02 | **FIXED** | Channel `com.nawey99.wudase.audio`, named in the phone's language; lock-screen fallback title localised. |
| IOS-05 / IOS-06 / IOS-07 | **FIXED** | `CFBundleLocalizations` am/en; `ITSAppUsesNonExemptEncryption=false`; Podfile committed. |
| A11Y-03 | **KEPT** | 200 % cap left; raising it needs a layout sweep at larger sizes first. |
| PERF-02 | **NOT FIXED** | Moving decoding to an isolate stalls widget tests that load bundled data under fake async; unmeasured benefit. |
| PERF-03 | **FIXED** | Normalised search fields cached per hymn. |
| PERF-04 | **FIXED** | (with ARCH-01) |
| MEM-01 | **FIXED** | Repository reuses the mapped list while the source returns the same models. |
| CI-02 / REL-01 | **DOCUMENTED** | `--split-debug-info` and archiving in `RELEASE.md`; release builds remain manual. |
| DEP-02 | **FIXED** | `cupertino_icons` removed. |
| PRIV-02 | **FIXED** | Settings switch "Share anonymous usage counts"; `AnalyticsService` honours it; policy updated (effective date 1 October 2026 — goes live when pushed). |
| TEST-04 | **FIXED** | Tests now expect 120 songs. |
| SRCH-01 | **FIXED** | Order: number → Amharic exact/prefix/contains → English exact/prefix/contains → lyrics. |
| SCALE-01 | **OPEN — decision needed** | Favourites/history keyed by number; moving to song IDs is a data migration. |

## Found during Phase 2
- **SORT-01 (fixed):** `HymnsLoaded._sortHymns` set `Intl.defaultLocale = 'am'` on every
  name sort. It had no effect on sorting (`String.compareTo` ignores it) but changed
  number/date formatting app-wide. Removed.
- **iOS backup (note):** on iPhone, favourites and history (UserDefaults) are part of the
  normal device backup, while the policy says they "never leave your device". Consider
  rewording that sentence.

## Release blockers after re-check
- **IOS-02** — still open until the CI job or the Mac shows an Xcode 26 build.
- **IOS-01, IOS-03, IOS-04** — fixed in the project but VERIFIED ON MAC is still required.
- **STORE-01** — owner's console work.
- Android: no code blockers remain from this audit.

## Follow-up (same day): the three open decisions, done

| ID | Status | What changed |
|---|---|---|
| DL-03 | **FIXED** | Whole-edition downloads are handed to the system with `background_downloader` 9.5.5 (WorkManager on Android, background `URLSession` on iOS) and continue with the app in the background or closed. Files land as `<sha256>.<ext>.unverified` and are cached only after their checksum matches. A download the app was closed in the middle of is remembered and carried on at the next start; running ones are picked up so progress and Stop work. Verified on the Android 16 emulator: 399 pages finished with the app in the background; after a Force stop 3 s into an audio download, reopening finished all 289 files. A Force stop itself pauses downloads until the app is opened (the system's rule). |
| SCALE-01 | **FIXED** | Favourites and history are kept by song ID (`am-sda-2004-0132`). Every live song's ID is `<edition>-<4-digit number>` and the bundled numbering matches the API for all 739 songs (checked 2026-10-01), so old data migrates exactly, once, at start-up; bundled hymns carry the same IDs (marked `isBundled`). Verified on the emulator with planted old-format data. |
| CODE-01 (root files) | **FIXED** | The five stale summaries deleted; the two live items in `MAINTAINER_ACTIONS.md` (placeholder donation details; check screenshot blocking on a physical phone) moved to `docs/RELEASE.md` §1. |

Consequences: the iOS minimum is now **14.0** (the plugin's pod requires it). Android gains `ACCESS_NETWORK_STATE` and `RECEIVE_BOOT_COMPLETED` (WorkManager); the plugin's unused `dataSync` job service is removed, so no new Play declaration. Both privacy-policy copies list the two permissions. Tests: **872 passed**.
