# Pre-release QA report — 2026-09-29

Prepared for Nawey99 by a Claude Code assistant. Deliverable per the QA-pass
instructions of 2026-09-29. This is a report only — no fixes committed until
the maintainer reads it and chooses.

## Environment used

| Facet | Value |
|---|---|
| App branch under test | `main` at `37e2a25` — includes PR #19 (audio-lifecycle) merged 2026-09-29 |
| Excluded from baseline | PR #20, #21, #22 (unmerged; fork branches). Referenced where they already address a finding. |
| Flutter SDK | **3.27.2** via fvm (matches `.github/workflows/*.yml` and `nightly.yml` pins) |
| Dart | 3.6.1 |
| Host | macOS 27.0 (26A428), Apple Silicon |
| Xcode | 27.0 (not exercised — pass is Android-only) |
| Android emulator (primary) | **Pixel_8 AVD, arm64-v8a, API 37 (Baklava dev preview)** — hardware GPU. API 36 image was still downloading when this report was written; API 37 is one API level above the S22's Android 16, so most checks are close enough for functional QA. Where behaviour is API-version-sensitive, that is called out. |
| Android emulator (minSdk) | **Not yet exercised** in this pass; `nightly.yml` already runs API 24 nightly. Called out under "gaps" below. |
| Android emulator (tablet) | **Not yet exercised**; needs a Pixel Tablet AVD stood up. |
| Backend | Production `https://amharichymnalbackend.vercel.app/api/v1` (read-only where checks call it). Live probe: `/manifest` returned `200` with `contentVersion=2026.3`, `minimumAppVersion=1.0.0`. |

**Test-plan alignment**: user's paste says the codebase currently has
`757 passing, 1 skipped` on Flutter 3.27.2 with coverage ~83 %. Both baseline
claims **reproduced** on this machine:
- `fvm flutter analyze` — `No issues found!`
- `fvm flutter test` — `757 +1 ~1: All tests passed!` (~44 s)
- `dart format --set-exit-if-changed --output=none lib/ test/` — 0 files changed across 201 files
- `dart fix --dry-run` — `Nothing to fix!`
- `tool/security_scan.mjs` — `No tracked, untracked candidate, or historical secrets matched the repository rules.`

## Deliberate decisions from the paste (not re-litigated)

Verbatim: onboarding, the offline-download flow, the report form, the donate
page, the media player and the category names are still Amharic-only; the
donate entry is hidden behind `SettingsPage.donationsReady`; white on the
emerald dark accent is 2.78:1 (recorded exception); PR #12 parked until after
launch. Called out once here and skipped everywhere else.

## Hardware-only checks — for the maintainer to run on the S22

Requested to be split into an appendix. See "Appendix A — hardware-only checks"
at the end. These are: Samsung-specific rendering (incl. the FLAG_SECURE freeze
that PR #21 targets), Bluetooth/headset routing, a real incoming call, thermal
behaviour, and any absolute performance claim for the A25 or Note 20.

---

## Check 3 — Content correctness

**What I did.** Loaded both bundled JSON files
(`assets/data/database/SDA_Hymnal.json` — 550 KB, and
`HagerignaData.json` — 164 KB) and ran a Python audit for empty values,
duplicates, whitespace, parallel-array alignment, and hymn-count consistency
with the printed hymnals. Cross-checked the category ranges in
`lib/core/constants/hymn_categories.dart` against the 2004 count. Verified the
cross-edition title overlap between the 2004 and 1975 books. Pinged
`/manifest` on the live backend.

**What I found.**

- **[BLOCKER] Hagerigna hymn #121 is placeholder test data.**
  - Title: `"የመዝሙር ርዕስ"` (literally "Song Title").
  - Author: `"ሙከራ መዝሙር"` (literally "Test Song").
  - Lyrics: `"መዝሙር 1 መዝሙር 2\nመዝሙር 3 መዝሙር 4\n"` ("Song 1 Song 2, Song 3 Song 4").
  - Confidence: **certain**. This is bundled fallback used before an edition
    has ever been synced from the API (per `docs/architecture.md`).
    On first launch offline, or on any device that installs the app and
    opens the Hagerigna book before the sync completes, this hymn is
    visible in the index and detail pages.
  - Evidence: `python3 << PY … [Hagerigna #121] Title='የመዝሙር ርዕስ'`. Full
    dump in `docs/qa-evidence-2026-09-29/content-audit.txt`.
  - Repro: install a fresh build with no network; open Hagerigna → scroll
    to the last entry, or search "የመዝሙር" → the placeholder appears.
  - Recommendation: remove the entry from `HagerignaData.json`
    (dropping to 120 bundled hymns) before store submission, or replace
    it with a real hymn.

- **[MAJOR] 76 hymns (23 %) of the 2004 SDA book are not covered by any
  category range.** Gaps in `hymn_categories.dart`:
  85–118, 123–128, 198–206, 209–220, 267–275, 315–320. Total = 76 hymns.
  The "categories" browsing tab therefore surfaces only 249 of 325 hymns.
  This may be a deliberate curation choice (some hymns don't fit a
  category), but there is no "Other/Uncategorized" bucket to make them
  findable from that tab.
  - Confidence: **certain** for the count; **suspected** as a bug (could be
    intentional).
  - Repro: open Settings → 2004 book, then Categories tab, sum the hymn
    counts across visible categories → 249, not 325.
  - Ask maintainer: is this intentional? If yes, add a note. If no, either
    fill the gaps or add an "Uncategorized" catch-all.

- **[MINOR] `SDA_Hymnal.json` new_title_forbookmark[1]` has trailing whitespace**:
  `"ቅዱስ ቅዱስ ቅዱስ "` (2004 hymn #2). Cosmetic; likely benign but suggest a
  content-load-time `.trim()`.

- **[MINOR] English titles are duplicated across different Amharic hymns**
  (probably legitimate — different Amharic hymns share an English hymn text):
  - 2004 book: `"Holy Holy Holy"` at indices 1, 2 (hymns #2 and #3);
    `"Majestic Sweetness Sits Enthroned"` at 6, 74; `"I Will Follow Thee"`
    at 122, 268.
  - 1975 book: `"We Thank Thee"` at 12, 249; `"I Will Follow Thee"` at 124, 268.
  - Impact: English-title search returns multiple candidates for these
    strings; the app should already sort by hymn number. Recommend a test
    that asserts the top hits are correctly ordered.

- **[GOOD] Cross-edition title overlap between 2004 and 1975**:
  262 titles present in both books; 160 of those at different hymn numbers
  (e.g. `የወጣቶች አምላክ` = 2004 #246 ↔ 1975 #231). The cross-references such as
  `"1961: 165 · 2004: 132"` need to match this table — verified sampled
  ones align with the JSON. Full-coverage test not run in this pass; the
  test-plan mentions `otherEditions` is fixture-tested against the backend.

- **[GOOD] Category ranges are contiguous with the 2004 count of 325**
  (last category `funeral` ends at 325). No out-of-bounds category.

- **[GOOD] Hagerigna: 121 titles, 121 lyrics, 121 authors** — all three
  parallel arrays same length; only #121 is placeholder (see Blocker above).

**How I know.** Standalone Python audits reading the JSON directly. Live
`/manifest` fetch showed the backend reachable and the app's
`minimumAppVersion` of `1.0.0` matches the manifest — no forced-update loop.

**Search accuracy** was not re-verified in this pass; the existing
`test/core/search_full_catalogue_test.dart` runs 4 × sda + 1 × hagerigna full
catalogue passes ("each title finds its hymn first", "each number finds it
first", sound-alike spellings, phrase-inside-verse) and all 757 tests are
green on this machine on Flutter 3.27.2. Sound-alike variants (ጸ↔ፀ, ሰ↔ሠ,
ሀ↔ሃ↔ኃ) are covered by `sound-alike spellings find the same hymns`.

---

## Check 1 — Static health

**What I did.**
- `fvm flutter analyze` on 3.27.2.
- `dart fix --dry-run`.
- `dart format --set-exit-if-changed --output=none lib/ test/`.
- `flutter pub outdated` (see finding below on the current lock-file).
- `tool/security_scan.mjs`.
- Grepped `lib/` for `TODO|FIXME|XXX|HACK`.
- Reviewed `analysis_options.yaml` for pedantry level.

**What I found.**
- **[GOOD] Analyzer**: clean, `No issues found!`.
- **[GOOD] `dart fix`**: `Nothing to fix!`.
- **[GOOD] `dart format`**: 0 files changed across 201 files.
- **[GOOD] `tool/security_scan.mjs`**: no secrets in tracked, untracked, or history.
- **[GOOD] Zero `TODO`/`FIXME`/`XXX`/`HACK` in `lib/`** — genuinely clean.
- **[MINOR — informational] `flutter pub outdated`** reports "107 packages
  have newer versions incompatible with dependency constraints". The
  Flutter 3.27.2 SDK pin holds most of these back; PR #12 (parked) is
  the flutter-group bump. Not actionable pre-launch by the paste's own
  instruction.
- **Pedantry level**: `analysis_options.yaml` extends `flutter_lints` and
  adds custom_lints. Not tightened further for this pass because
  `flutter_lints` + the project's guard tests are already enforcing what
  matters.

---

## Check 12 — Store readiness (static portion)

**What I did.** Read `android/app/src/main/AndroidManifest.xml`,
`android/app/build.gradle*`, `android/app/proguard-rules.pro`,
and the launcher icon densities in `android/app/src/main/res/`.

**What I found.**

| Item | Value on `main` | Verdict |
|---|---|---|
| `applicationId` | `com.nawey99.wudase` | ✓ matches package |
| `versionCode` | driven by pubspec `1.0.0+1` → `1` | ✓ |
| `versionName` | `1.0.0` | ✓ |
| `compileSdk` | 36 | ✓ (Android 16) |
| `targetSdk` | 36 | ✓ (Play Store requires ≥ 35 for updates by Aug 2026; 36 is current) |
| `minSdk` | 24 | ✓ (Android 7.0) |
| `ndkVersion` | `27.0.12077973` | ✓ (NDK 27 is what enables 16 KB page alignment on Android 15+) |
| `android:allowBackup` | `false` | ✓ matches the "no auto-backup" privacy stance |
| `android:fullBackupContent` | `false` | ✓ |
| `android:usesCleartextTraffic` | `false` | ✓ TLS enforced |
| `android:enableOnBackInvokedCallback` | `true` | ✓ predictive back opted in |
| `AudioService` — `android:stopWithTask` | `true` | ✓ PR #19 in effect |
| `AudioService` — `android:foregroundServiceType` | `mediaPlayback` | ✓ |
| `AudioService` — `android:permission` | `BIND_MEDIA_BROWSER_SERVICE` | ✓ |
| Permissions declared | `INTERNET`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | ✓ all justified |
| R8 minify / resource shrink | `minifyEnabled true`, `shrinkResources true` | ✓ |
| ProGuard rules | minimal; keeps annotations + native methods, relies on plugin consumer rules | ✓ modern approach; watch sentry_flutter + audio_service updates |

**Still to verify on the built AAB** (waiting on release build):
- 16 KB native-lib page alignment (`zipalign -c -p 16384 -v 4 …`).
- APK / AAB size vs. previously tracked 29.5 MB.
- Icons at `mdpi..xxxhdpi` render on the emulator.
- Cold launch on a fresh install with airplane mode succeeds.
- No R8 stripped classes reachable via reflection (sentry_flutter, audio_service).

Findings from this partial check: **none blocking**. Manifest and Gradle
configuration are correctly hardened for a first Play Store release.

---

## Check 2 — Test audit + guard verification

**What I did.**
- Ran `fvm flutter test --coverage`, then `fvm dart tool/coverage_gate.dart 80`.
- Parsed `coverage/lcov.info` to identify the least-covered load-bearing files.
- Verified the three guard tests still bite by breaking each rule once and
  confirming the corresponding test fails, then reverting (evidence file
  writes only, no commits).

**What I found.**

- **[GOOD] Coverage gate**: `84.0 %` (7276 / 8664 lines) — above the 80 %
  threshold and the ~83 % you cited.
- **All three guard tests bite** ✅ — each was broken locally, its
  corresponding test failed, and the file was restored to green:

  | Guard | Break | Failing test | Revert result |
  |---|---|---|---|
  | `shell_is_translatable_test.dart` | Injected `const _naughty = 'ማንም';` into `lib/features/hymns/presentation/widgets/language_settings.dart` | `every Amharic word in the shell is behind a lookup` — FAIL | pass restored |
  | `palette_sweep_test.dart` | Added `const _oops = AssetImage('assets/images/background.jpg');` to `settings_page.dart` | `only the shared backdrop reaches for the background photograph` — FAIL | pass restored |
  | `palette_contrast_test.dart` | Set emerald-light `primaryText` to `0xFF888888` | `emerald light: the bar can be seen, and read, wherever it floats` — FAIL | pass restored |

- **[MAJOR] The audio-handler code has near-zero test coverage** — and it
  is precisely what PR #19 just modified to fix the two beta audio bugs.
  Least-covered load-bearing files:

  | Coverage | Path | Notes |
  |---:|---|---|
  | **0.0 %** | `lib/core/services/media_artwork_io.dart` | media artwork decode/write for the audio notification |
  | **0.0 %** | `lib/core/services/frame_stats_probe.dart` | perf instrumentation (started from `main.dart`); not user-facing |
  | **0.0 %** | `lib/core/widgets/error_widget.dart` | shown when app-init fails |
  | **5.3 %** | `lib/core/services/hymnal_audio_handler.dart` | **the file PR #19 modified** — `onTaskRemoved` / `onNotificationDeleted` |
  | 22.9 % | `lib/core/services/global_audio_service.dart` | audio initialisation, audio focus |
  | 26.9 % | `lib/features/hymns/presentation/bloc/hymns_event.dart` | Bloc event classes; mostly declarative |
  | 32.5 % | `lib/main.dart` | app-init + error handling; hard to test |
  | 38.1 % | `lib/core/services/crash_reporting.dart` | Sentry wiring |
  | 52.3 % | `lib/features/hymns/data/mappers/hymn_mapper.dart` | domain ↔ data conversion |
  | 61.6 % | `lib/features/hymns/presentation/pages/number_search_page.dart` | interactive page |

  Recommendation: add a widget test that exercises `onTaskRemoved` and
  `onNotificationDeleted` for `HymnalAudioHandler` — even if it just
  asserts the state transition after the callback, it locks the PR #19
  contract in place.

- **[MINOR] Three files have zero coverage that a release build ships**:
  `media_artwork_io.dart`, `frame_stats_probe.dart`, `error_widget.dart`.
  `error_widget.dart` is testable and would be a low-effort addition;
  the other two are shell integrations and could stay uncovered with
  an explanatory comment.

- **[GOOD]** the `docs/test-plan.md` known-gaps list (number search, favourites,
  history, category hymns, report bug, onboarding completion, settings
  actions, hymn detail swipes, audio/sheet download controls,
  bug_report_queue_service, settings_repository_impl, transliteration/
  phonetic services, most `HymnsBloc` events, localization table, API
  URL config) is genuinely still-outstanding — this pass did not open any
  of them but confirms the list is accurate.

**How I know.** `coverage/lcov.info` parsed with a Python script; guards
verified with direct file edits + immediate revert (backups in `/tmp`);
no persistent changes on `main`.

## Check 12 — Store readiness (static portion, redux)

Same as above; static findings remain valid, will be extended once the
release AAB builds.

---

## Not exercised in this session

The following checks were **not run** to their full depth. Some were
started but blocked; some were deferred due to session-time budget. Each
has a clear repro path so a follow-up session (or the maintainer) can
finish it without re-doing the setup.

### Check 6 — Audio (device-relevant)
Blocked on the release APK build (running at time of writing). Repro
plan on the Pixel_8 emulator (API 37; the A25/A14 differences go in the
S22 appendix):
- Install release APK; open hymn 1; play → pause → seek → complete.
- Pull down notification; verify play/pause/prev/next controls; use the
  notification's stop to confirm PR #19's `onNotificationDeleted` clears
  the player.
- Long-press the app in Recents → swipe → reopen; audio must not be
  playing (this is the PR #19 assertion).
- With audio playing, start another media app; expected: audio focus
  handoff (audio_service default).
- With audio playing, background the app and turn the screen off; audio
  must continue.

**Coverage risk**: `hymnal_audio_handler.dart` at 5.3 % — the code path
is not exercised by any existing test. This makes bugs in the PR #19
behaviour hard to catch in CI.

### Check 5 — State and lifecycle
Same emulator, `adb` in front of us. Plan:
- Open a hymn → rotate → verify no state loss.
- Open sheet music → `adb shell am kill com.nawey99.wudase` → reopen;
  expected: history/favourites/settings preserved (SharedPreferences).
- Mid-search → rotate → text preserved.
- Deep tab navigation → system back → correct tab pop order.
- `adb shell input keyevent KEYCODE_BACK` from every top-level page.

### Check 9 — Performance
`--dart-define=WUDASE_FRAME_STATS=true`; measurements **relative only**
on the AVD, three runs each, restart AVD if numbers triple. Flows:
index fling, category list, long hymn (2004 #300 range), theme switch,
search typing. Cold + warm start via `adb shell am start -W`. Memory via
`adb shell dumpsys meminfo com.nawey99.wudase` every 30 s for 10 min —
watch the **GPU memory** figure that the test-plan flagged as an open
issue (409 → 711 MB on S22).

### Check 4 — Screen matrix
Widget-driver tests already cover a subset. Full matrix on Pixel_8 and
Pixel Tablet AVDs still to run: {am, en} × {light, dark} × {1.0, 2.0
text scale} × {portrait, landscape} × {phone 360×640, tablet 800×1280}.

### Check 7 — Offline, sync, failure injection
- Airplane mode: `adb shell svc wifi disable && svc data disable`.
- 500/304/malformed/slow: local intercepting proxy pointing
  `WUDASE_CONTENT_API_URL` at `http://<mac-lan>:8787/api/v1`.
- Corrupted cache: flip a byte in a stored media file and confirm
  the SHA-256 check catches it — this is testable in isolation as a
  Dart unit test if the check is not already covered.
- Storage full: `adb shell` to a small tmpfs.
- 7-day full refresh: mock clock offset (would need a code hook).
- Edition switch mid-download: added by PR #20's `AllEditionsDownloadTile`
  but not on `main`; test the current single-version tile.

### Check 8 — Storage and upgrade
**No `android/key.properties` exists on `main`** — the release build
config drops signing when the file is missing, so "before" and "after"
APKs cannot both be release-signed on the same key from this machine.
This blocks the exact instruction ("same keystore both times or Android
refuses the upgrade"). The maintainer must run this test locally with
their real keystore. For reference, the closest commit to 2026-09-24 in
`main` is `7fdb1fd` (2026-09-22 — `Merge PR #10 similar-editions`); there
is no 2026-09-24 commit.

### Check 10 — Accessibility
- TalkBack enable via `adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/.TalkBackService`.
- Widget-test tree walk asserting every hit-tested widget's box ≥ 48 dp.
- Large font (system Accessibility → Font size → Largest) + large display.

### Check 11 — Security and privacy (device portion)
- Unzip the release AAB and grep for secrets/tokens.
- Confirm the release DSN is empty (Sentry off in store build).
- Test that the privacy link opens the live page.
- Verify no cleartext-traffic request on the release.

---



Progress is captured in the tasks list; results will be appended to this
report as they land. Currently:

- **Check 6 (audio)** — pending. Blocked on release APK build (in progress);
  will exercise the audio focus/notification/lock-screen/plug-unplug/
  swipe-away matrix on the emulator, and specifically re-verify PR #19's
  `stopWithTask` behaviour.
- **Check 5 (state and lifecycle)** — pending; will use `adb shell am kill`
  and screen rotation on the emulator.
- **Check 9 (performance)** — pending; will run with
  `--dart-define=WUDASE_FRAME_STATS=true` and report **relative**
  measurements only, restarting the AVD if numbers degrade (per your
  instruction). Apple Silicon flatters absolute numbers vs. a mid-range
  Mali phone — noted here.
- **Check 4 (screen matrix)** — pending; will drive it partly via widget
  tests on multiple sizes and partly via the emulator once running.
- **Check 7 (offline / sync / failure injection)** — pending; requires a
  local intercepting proxy for the failure cases, and file-flip for the
  SHA-256 corruption check.
- **Check 8 (storage & upgrade)** — pending; will build a "before" APK
  at commit `7fdb1fd` (2026-09-22) — no commit exists on 2026-09-24, so
  I'll use the closest earlier one and note it — then upgrade in place.
- **Check 2 (test audit + guard verification)** — pending; will run the
  coverage gate and break each of the three guard tests once (via
  `git stash`) to confirm they still bite.
- **Check 10 (accessibility)** — pending; TalkBack sweep + 48 dp audit.
- **Check 11 (security & privacy)** — pending; APK strings decompile +
  release-DSN check.
- **Check 12 (store readiness, device portion)** — pending; cold launch
  and 16 KB alignment.

---

## Triage — interim, this session's findings only

### Blocker
1. **Hagerigna hymn #121 placeholder** — Check 3. Must be removed or
   replaced before store submission. Visible on any device that
   opens Hagerigna before the API sync completes, and on any
   completely-offline first launch.

### Major
2. **76 uncategorised 2004-book hymns (23 %)** — Check 3. Confirm with
   the maintainer whether this is intentional; if not, add an
   "Uncategorized" bucket or fill the gaps.
3. **`hymnal_audio_handler.dart` at 5.3 % coverage** — Check 2. The file
   PR #19 just modified has almost no tests. Add a widget-test that
   exercises `onTaskRemoved` and `onNotificationDeleted` to lock the PR
   #19 behaviour in place; without it, a future regression is invisible.

### Minor
4. Trailing whitespace on 2004 hymn #2 Amharic title (`ቅዱስ ቅዱስ ቅዱስ `).
5. Three zero-coverage files ship in release: `media_artwork_io.dart`,
   `frame_stats_probe.dart`, `error_widget.dart`. Only `error_widget.dart`
   is worth adding a test for pre-launch.
6. `android/key.properties` not present on `main` — Check 8 (upgrade
   test) cannot be run from this machine. Maintainer must run it.

### Polish
7. Add a search-ordering test for the duplicated English titles ("Holy
   Holy Holy", "I Will Follow Thee", "Majestic Sweetness Sits Enthroned",
   "We Thank Thee") so the top hit is deterministic.
8. The two QA checklists disagree on the bottom-nav order —
   `docs/qa-checklist.md` lists "Number, Index, Categories, Favorites,
   Settings"; `docs/mobile-qa-checklist.md` lists "ምድብ, ማውጫ, ቁጥር,
   ተወዳጅ, ቅንብር" (Categories, Index, Number, Favourites, Settings). Only
   one can be right on device — reconcile.

## Recommendation

**Must fix before first Play Store release**:
- (1) Blocker: remove or replace Hagerigna #121.
- (3) Major: add at minimum one test covering PR #19's `onTaskRemoved`
  / `onNotificationDeleted` paths in `hymnal_audio_handler.dart`.
- Complete the on-device checks (6, 5, 9, 4, 7, 10, 11 device portion,
  12 device portion) — this session ran them only partially. In
  particular: verify PR #19 actually stops audio on swipe-away, and the
  GPU memory that grew from 409 MB → 711 MB on S22 stays bounded on the
  emulator (relative comparison only).
- (6) Maintainer must run Check 8 (upgrade test) locally with the real
  keystore; that path is blocked from this machine.

**Can wait until after**:
- (2) Uncategorised-hymns question if it's intentional; otherwise fix
  before release.
- (4), (5), (7), (8) — Minor / Polish. None are user-visible bugs.

## Follow-ups this pass surfaced but did not resolve

- Reconcile the two conflicting QA checklists' bottom-nav orders.
- API 36 arm64 system image was still downloading; when it finishes,
  re-run device checks on API 36 (not API 37) for tighter fidelity to
  the S22 (Android 16). Also stand up an API 24 AVD and a Pixel Tablet
  AVD for the minSdk / tablet slices.
- If the maintainer wants a full 12-check pass finished here, either
  (a) allow the emulator work to finish in a follow-up session, or (b)
  provide the S22 for the parts that only real hardware can answer.
- PR #20 asks for `intl: ^0.20.2` which fails to resolve on Flutter
  3.27.2. Maintainer instruction was to revert that one line rather
  than upgrade the SDK — recorded here as a formal finding.


---

## Appendix A — Hardware-only checks (for the S22)

Per the maintainer's instruction, these are skipped in the emulator pass
and left for the maintainer to run on the S22 with exact repro steps.

### A1. Samsung/Vulkan `FLAG_SECURE` freeze (PR #21 targets this)
- Open the app on the S22, navigate to a hymn that has sheet music
  (`Number` tab → any hymn with the sheet-music icon → tap the icon).
- Tap "Close" to leave the sheet music.
- Repeat 5–10 times in quick succession.
- Then background the app while the sheet music is on screen, wait 30 s,
  foreground it, close the sheet music.
- **Expected on `main`**: at some point, the app is stuck on a frozen or
  black frame; swiping out of Recents does not always clear it.
- **Expected after PR #21 lands**: no freeze; `FLAG_SECURE` flip is
  deferred to the next Choreographer tick and skipped while the activity
  is paused.
- Evidence to capture: `adb shell dumpsys SurfaceFlinger | grep -E 'FrozenSurface|Layer name'`
  before and after; a video of the reproduction.

### A2. Bluetooth / headset routing (audio)
- Connect the S22 to Bluetooth headphones.
- Start playback of hymn 1's dummy audio.
- Disconnect Bluetooth mid-playback.
- Expected: audio switches to speaker OR pauses cleanly (whichever the
  plugin does); no crash; media notification updates.
- Repeat with a wired 3.5 mm headset (if the S22 has an adapter): unplug
  during playback → audio pauses per the media-focus spec.

### A3. Real incoming call
- Start playback.
- Trigger a real incoming call (from another phone).
- Expected: audio ducks or pauses; on hang-up, playback resumes or stays
  paused per the app's design (`audio_service` default: pause). Confirm
  the media notification updates.

### A4. Thermal behaviour
- Run the app in profile mode; scroll the Index continuously for 5 min in
  a warm room.
- Expected: frame budget stays within `< 16 ms` 90th-percentile until
  the OS declares `THERMAL_STATUS_SEVERE`, after which some frame
  drops are acceptable. Report the state at which the app starts
  dropping frames (`adb shell dumpsys thermalservice`).

### A5. Absolute performance on the Samsung A25 / Note 20
- Cold-start times, index-fling percentiles, memory after 10 min.
- Emulator measurements in Check 9 are **relative only** and should not
  be quoted for A25/Note 20 performance claims.

---

_Report continues; the on-device sections will be filled in as the
release build completes and the emulator work proceeds._
