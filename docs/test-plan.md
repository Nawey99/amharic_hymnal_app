# Test Plan — ውዳሴ (Draft for approval)

Status: **proposal**, nothing below is implemented yet.
Written 2026-09-21 against branch `flutter-app` (149 automated tests, all passing).

## 1. Where we are

- **Code:** ~130 Dart files / ~25,000 lines in `lib/`; 37 test files / ~4,800 lines.
- **Well covered:** hymnal API loading and sync (`hymn_sync_test`, 22 tests), media cache and checksums, search ranking, sheet-music viewer gestures, navigation shell layouts, categories, alphabet scrubber.
- **Not covered at all:**
  - Pages: number search, favorites, history, category hymns, report bug, onboarding completion, settings actions (edition switch, download-all).
  - Hymn detail: swipe to next/previous, share, history write.
  - Audio and sheet download controls: `hymn_media_controls`, `audio_section_widget`.
  - Offline fallback: bundled JSON parsing (`local_data_source`, `sda_parser`, `hagerigna_parser`).
  - Services and logic: `bug_report_queue_service`, `settings_repository_impl`, transliteration/phonetic/script detection, search debounce, localization table, API URL config, most `HymnsBloc` events.
- **Test quality issues:**
  - `integration_test/app_test.dart` wraps each step in `if (found)`, so it passes even when nothing works.
  - There are no golden (screenshot) tests, no accessibility checks, and no coverage measurement.
  - There is no mocking library; each test file hand-writes its own fakes.
- **Dead code** (no callers): `offline_cache_service`, `sync_service`, `search_index_service`, `category_service`, `error_handler`, `get_settings`, `language_config`, `feedback_page`, `support_page`, `font_size_slider`, and seven unused core widgets. The Drift database path is disabled by default (`WUDASE_ENABLE_LOCAL_CONTENT_DB=false`).
- **Platform-specific code to exercise on devices:**
  - `wudase/secure_screen` (Android `FLAG_SECURE`, iOS capture overlay)
  - background audio (`audio_service` foreground service, `mediaPlayback`)
  - `share_plus`, `wakelock_plus`, `url_launcher`, `path_provider` storage
- **Android 16 (API 36, now targeted):** edge-to-edge can no longer be switched off; predictive back is the default (the manifest already opts in); orientation locks are ignored on screens ≥ 600 dp (the app has none). [Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16)

## 2. Principles

1. **Tests must fail when the feature is broken.** No `if (found)` guards; every flow asserts its outcome.
2. **Deterministic by default.** Unit, widget and integration tests never touch the live API; they use recorded fixtures and fakes. Live checks run separately and on a schedule.
3. **Offline-first is the core promise.** Every content path is tested in each network state: online, offline with a stored copy, offline first launch, slow, flaky and rate-limited.
4. **Test on the devices people actually use.** That means low-end Android phones common in Ethiopia (Tecno, Infinix, Samsung A-series, Android 7–14), not only flagships.
5. **Delete dead code before testing it**, so coverage numbers mean something (needs your OK; see §6).

## 3. Test layers

### Layer A — Unit tests (pure logic)
| Area | What to prove |
|---|---|
| Bundled content (`local_data_source`, `sda_parser`, `hagerigna_parser`, `json_data_source`) | Expected hymn counts per book; numbers 1..N without gaps; every hymn has a title and lyrics; the right title/lyrics chosen per edition; the fallback order API → stored → bundled; the 1961 "online only" error |
| `HymnsBloc` (with `bloc_test`) | Every event: Load, Search, ChangeLanguage, ChangeVersion, ChangeSort, ToggleFavorite (optimistic + persisted), GetHymnByNumber, LoadHymnsByCategory; loading/error/pending states |
| Settings & favorites (`settings_repository_impl`, `settings_service`) | Per-edition favorites; language/version/sort persistence; legacy key migration |
| Bug report queue | Queue while offline; flush on start; retry after failure; the web no-op; nothing lost when the app is killed |
| Amharic text (`script_detector`, `amharic_transliteration_service`, `amharic_phonetic_service`, `title_cleaner`) | Table-driven cases from real hymn titles, including ስ/ሥ, ሀ/ሐ/ኀ, ጸ/ፀ and Latin input |
| Search | Debounce timing (350 ms, with `fake_async`); ranking on the **full real catalogue**; searching every title finds it at rank 1 |
| Localization | Every key has am and en; no empty strings; placeholders are consistent |
| Config | `WUDASE_*` URL validation; HTTPS required in release builds |
| Use cases | Each passes its parameters through and maps failures |

### Layer B — Widget tests (one screen at a time, fakes injected)
For every page: loading, empty, error and loaded states, plus the page's main actions.
- **Number search:** a valid number opens the hymn; invalid and out-of-range numbers show a message; switching book changes the valid range.
- **Index:** search mode, empty results, sort switch, scrubber jump. Part of this exists; extend it.
- **Categories and category hymns:** list, open, back, Hagerigna hides the tab.
- **Favorites:** add/remove, per-book separation, empty state, search.
- **History:** recorded on open, ordering, clear.
- **Hymn detail:** swipe next/previous at the ends of the book, pinch zoom, share (injected sharer), favorite, the other-editions line, the history write.
- **Media controls:**
  - no audio or sheet music;
  - download prompt shows the size;
  - a cached file plays straight away;
  - checksum-failure message;
  - offline message;
  - the synthesized badge.
- **Sheet viewer:** borrowed caption, multi-page, privacy overlay (some exists).
- **Settings:** book switch reloads content; keep-screen-on calls the service; download-all flow (plan → size → progress → cancel → partial failure message); links.
- **Report bug:** validation, submit, offline "queued" message, character limits.
- **Onboarding:** next/skip/finish sets the flag; not shown again; the `WUDASE_FORCE_ONBOARDING` override.
- **Update prompt** and **"(በዝግጅት ላይ)"** label.

### Layer C — Visual regression (golden tests)
- **Screens:** shell, index, detail, sheet viewer, settings, dialogs.
- **Layouts:**
  - small phone (320×640);
  - normal phone;
  - landscape;
  - tablet (800 dp, the side rail);
  - text scale 1.0, 1.3 and 2.0.
- **System insets** simulated for edge-to-edge: gesture navigation, 3-button navigation, display cutout. This is the Android 16 risk.
- **Fonts:** load NotoSansEthiopic for real so Ethiopic glyphs are checked.
- **Where they run:** goldens run on Linux in CI only, so font rendering is identical between runs.

### Layer D — Accessibility
- **Automated on every page:** `androidTapTargetGuideline`, `iOSTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline`.
- **Semantics:** every icon-only button has a label, in Amharic.
- **Manual:** a TalkBack pass and a VoiceOver pass, and 200 % font size on a small phone.

### Layer E — API contract and live checks
- **Contract (offline, every CI run):**
  - Keep recorded responses in `test/fixtures/`: `/hymn-versions`, one edition's `/sync`, a delta, `/songs/{id}`, `/manifest`, `/downloads/sheet-music/pages`, and each error code.
  - Validate the fixtures against the backend's `openapi.json`.
  - Feed them through the real parsers.
  - When the backend changes its contract, refreshing the fixtures makes the app tests fail before users hit the problem.
- **Live smoke (nightly scheduled CI job, tagged `live`, never blocks a PR):**
  - all four books load, and counts match `content.songCount`;
  - every song has a title and lyrics;
  - every media file has a checksum;
  - download a random sample of pages and tracks and verify SHA-256;
  - a delta from an older point equals a full download;
  - `otherEditions` answers;
  - `/manifest` answers.
- **Content audit (on demand):** compare bundled JSON against the API (numbers, titles) and report drift. This decides whether the bundled copy needs refreshing before a release.

### Layer F — End-to-end on real and virtual devices
- **Rewrite `integration_test`** with strict assertions and a fake API injected at startup, so runs are deterministic. Flows:
  1. first launch → onboarding → shell;
  2. number search → detail → favorite → appears in Favorites;
  3. book switch keeps each book's favorites apart;
  4. offline first launch uses bundled lyrics;
  5. restart with a stored copy and no network;
  6. audio: download then play;
  7. sheet music: download, view, back;
  8. Settings → download all, then cancel;
  9. report a bug offline, go online, it is sent.
- **Native interactions with [Patrol](https://patrol.leancode.co/):**
  - media notification controls and lock-screen playback;
  - playback continues with the screen off;
  - screenshot blocked on sheet music;
  - share sheet;
  - the predictive back gesture;
  - app killed mid-download.
  - *First check: which Patrol version supports Flutter 3.27.2.* Patrol 4 may need a newer Flutter; if so, run these by hand until Flutter is upgraded.
- **Android 16 checks:**
  - content not hidden under the status or navigation bars (gesture and 3-button);
  - back from detail, sheet viewer, dialogs and bottom sheets, including the back-preview animation;
  - tablet in landscape.
- **Device matrix (minimum):**

| Device class | Android | Why |
|---|---|---|
| Low-end, 2–3 GB RAM (Tecno/Infinix/Samsung A0x) | 8–11 | most common in Ethiopia; memory and speed |
| Oldest supported | 7.0 (API 24, `minSdk`) | lower bound |
| Mid-range Samsung | 13–14 | notification permission, One UI |
| Pixel / emulator | 16 (API 36) | the new target's behaviour |
| Tablet ≥ 600 dp | 14–16 | side rail; ignored orientation lock |
| iPhone (oldest supported + latest iOS) | — | audio background mode, capture overlay |
| Web: Chrome, Safari, Firefox | — | once the backend allows your web origin (`CORS_ORIGINS`) |

- **Cloud devices:** Firebase Test Lab for the device matrix. The free tier has a small daily quota. Also use Play's automatic **pre-launch report** on the internal testing track.

### Layer G — Network and failure conditions
- **Connection states:**
  - offline first launch;
  - offline with a stored copy;
  - airplane mode during a sync;
  - airplane mode during a page or audio download (no corrupt file afterwards).
- **Speed and bad responses:**
  - slow 2G (emulator network throttling);
  - a timeout on each request type;
  - 429 and 503 answers (fake server);
  - malformed JSON;
  - a captive-portal HTML page instead of JSON.
- **Device state:**
  - disk full while saving a book or media;
  - app killed while writing the stored book (the atomic rename must hold);
  - device clock wrong by a day or a year.
- **Upgrade path:** install the previous public build, add favorites and history, upgrade to this build → data kept; old IDs map to the new books.

### Layer H — Performance budgets (profile mode on the low-end phone)
| Measure | Budget (proposed) |
|---|---|
| Cold start to first hymn list (stored copy) | < 2.5 s |
| Parsing a 1 MB `/sync` response | < 300 ms, else move to an isolate (`compute`) |
| Search across a full book | < 50 ms per keystroke |
| Index scroll / scrubber | no frame over 16 ms (`flutter drive --profile` timeline) |
| Sheet page open (cached) | < 500 ms; memory stays bounded while zooming |
| Release AAB size | track with `tool/analyze_app_size.dart`; currently 29.5 MB |

### Layer I — Security and privacy
- `FLAG_SECURE` active on sheet music; the iOS capture overlay shows.
- Release build: no secrets or stray URLs in the binary (`strings` scan); only HTTPS; R8/ProGuard doesn't break `audio_service`, `just_audio` or JSON (a smoke test **of the release build**, not only debug).
- Bug-report contact email encrypted server-side; nothing sensitive logged in release.
- Existing CI scans stay (OSV, TruffleHog, `tool/security_scan.mjs`).

### Layer J — Language and content review
- Export every user-facing Amharic string to one list for your Gemini + native-speaker review.
- Check Ethiopic rendering on OEM fonts (Samsung, Tecno) and in notifications and the share text.
- Check long-title overflow across all four books (automated: render every title in the list tile at 320 dp).

## 4. CI changes
1. `flutter test --coverage` with a minimum. Start at today's number and ratchet up; the target is ≥ 80 % for `lib/core` and `lib/features/*/data`.
2. A golden-test job (Linux).
3. Integration tests on an Android emulator (API 24 and API 36) as well as Linux.
4. A nightly `live` job against production, reporting only.
5. Optional: an iOS simulator job. macOS runner minutes cost more.
6. Watch the first CI run after the Android upgrade (AGP 8.9.1, Gradle 8.11.1, NDK 27, API 36).

## 5. Order of work (proposed)
1. **Foundations:**
   - shared `test/helpers/` (fake API server, fake stores, `pumpApp`);
   - fixtures;
   - dev dependencies;
   - coverage reporting;
   - remove dead code (if approved).
2. Layer A unit tests.
3. Layer B widget tests.
4. Layers E (contract) and G (network) — where most real-world bugs will be.
5. Layers C and D (golden, accessibility).
6. Layer F integration rewrite + Patrol; device matrix run; Play internal track + pre-launch report.
7. Layer H performance on the low-end phone; Layer I on the release build.
8. Layer J string list handed to you for review.

Rough size: 250–350 new automated tests, plus one manual device pass per release using `docs/mobile-qa-checklist.md` (to be updated with the new features).

## 6. Decisions needed before starting
1. **Dev dependencies:**
   - `mocktail`, `bloc_test`, `fake_async`, and a JSON-schema validator (all test-only);
   - `patrol` for native flows.
2. **Delete the dead code** listed in §1 (and the disabled Drift path?), or keep it and test it?
3. **Firebase Test Lab** (needs a Firebase project) and/or the Play **internal testing** track: which will you use?
4. **Which physical devices do you have?** This decides what is tested by hand versus in the cloud.
5. **iOS:** is there a Mac available for simulator and device runs, or should iOS wait?
6. **Crash reporting** (e.g. Sentry or Firebase Crashlytics) for beta testers: add it or not? It is a privacy decision.
