# Testing Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only (no test was added or changed).

## Current state (measured)

- `flutter test`: **823 passed, 1 skipped, 0 failed** (≈ 77 s).
- Line coverage: **83.4 %** (7787/9340); CI gate 80 % (`tool/coverage_gate.dart`).
- Suites: 39 core, 33 feature (16 page, 9 widget, 2 bloc, data/domain), accessibility guidelines,
  OpenAPI contract validation (`test/contract`), live API tests (`test_live/`, nightly),
  `integration_test/app_test.dart`, Patrol native flows (`integration_test/native/`), perf test
  with flutter_driver.

### Lowest-covered files (≥ 40 lines)

| File | Line coverage |
|---|---|
| `core/services/hymnal_audio_handler.dart` | **5.3 %** |
| `core/services/global_audio_service.dart` | **22.7 %** |
| `main.dart` | 34.5 % |
| `features/hymns/data/mappers/hymn_mapper.dart` | 52.3 % |
| `core/l10n/app_localizations.dart` | 58.6 % |
| `features/hymns/presentation/pages/category_hymns_page.dart` | 61.5 % |
| `features/hymns/data/repositories/hymn_repository_impl.dart` | 70.0 % |
| `features/hymns/presentation/pages/number_search_page.dart` | 72.7 % |
| `features/hymns/data/datasources/local_data_source.dart` | 73.2 % |
| `features/hymns/presentation/pages/main_navigation_page.dart` | 75.0 % |
| `features/hymns/presentation/widgets/music_player_widget.dart` | 75.5 % |

## Critical flows vs automated coverage

| Flow | Automated? | Gap |
|---|---|---|
| First launch / onboarding | widget tests; `WUDASE_FORCE_ONBOARDING` | first launch **offline** (bundled fallback) not tested end-to-end |
| Navigation / tab ownership | yes (mobile shell tests) | — |
| Hymn lookup by number | yes | not-found vs offline distinction untested (ERR-01) |
| Search ranking | yes (search engine tests) | per-tab isolation (ARCH-01) not asserted |
| Sorting persistence | yes | — |
| Favourites per edition | yes | **edition-switch race (STATE-01) not covered** |
| History | yes | **cold start without `init()` (DATA-01) not covered** — tests initialise the service |
| Version switching | yes | concurrency not covered |
| Audio playback | **barely** (5 % / 23 %) | no tests for handler state mapping on errors, completion → stop, interruptions, seek clamping at boundaries beyond helpers |
| Background audio / lock screen | **no** (needs device; Patrol could cover Android) | |
| Downloads (single, bulk) | yes for planner, cache, controller | stalled stream (DL-01), killed-process `.part` cleanup (DL-02), low disk (DL-04) |
| Sheet music | yes (viewer, page) | very large images, low-RAM behaviour |
| Offline mode | partly (remote data source served-offline tests) | full app offline from cold start |
| API failure / malformed data | yes at data-source level | UI messages untested in Amharic (L10N-01) |
| Missing song | yes at data-source level (`SONG_NOT_FOUND`) | — |
| Corrupted stored edition | yes (`readAll` returns null → no pruning) | — |
| Orientation change | **no** | |
| App restart / state restoration | **no** | DATA-01 would have been caught |
| iOS | **no CI at all** (CI-01) | |

## Findings

### TEST-01 — Audio, a core feature, is the least-tested code · HIGH · CONFIRMED
Coverage 5.3 % and 22.7 % for the two audio services. Audio-handler tests written earlier in
this project were reverted and not restored. Direction: unit-test `HymnalAudioHandler` against a
fake `AudioPlayer` (state broadcast, error path, completion, stop, task removal), and add one
Patrol Android flow for background playback + notification controls.

### TEST-02 — No restart/cold-start tests · MEDIUM · CONFIRMED
Tests construct services already initialised; nothing simulates a fresh process reading persisted
state. DATA-01 slipped through for this reason.

### TEST-03 — No concurrency tests on the bloc · MEDIUM · CONFIRMED
No test dispatches overlapping `ChangeVersion`/`ChangeLanguage`/`SearchHymnsEvent`. STATE-01 was
reproduced in a 30-line throwaway test (kept out of the repo).

### TEST-04 — Tests pin a content defect · LOW · CONFIRMED
Four assertions require exactly 121 Hagerigna songs including the placeholder (CONTENT-01).

### TEST-05 — Integration/Patrol suites not run in this phase · INFO
They need an emulator/device; CI runs them on Android. Their latest CI results were not inspected.

### TEST-06 — `flutter_driver` remnant · INFO
`test_driver/perf_driver.dart` + `integration_test/perf/` use flutter_driver for frame timing;
still valid on 3.27 but a legacy API. Keep or move to `integration_test`'s `traceAction`.
