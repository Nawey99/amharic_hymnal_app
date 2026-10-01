# Performance & Memory Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only.

**Scope limit, stated plainly:** no on-device profiling was done in this phase (no frame
timings, memory snapshots or startup traces on a low-end phone). Findings below come from code
reading and from measurements on the build artifacts. The project already contains the tools to
measure: `FrameStatsProbe` (`--dart-define=WUDASE_FRAME_STATS=true`) and
`integration_test/perf/performance_test.dart` with `test_driver/perf_driver.dart`.
A Phase 2 measurement pass on a 2–3 GB RAM Android device is recommended before calling
performance "verified".

## What is already done well (CONFIRMED in code)

- Blur is opt-in per panel and wrapped in `RepaintBoundary`, clamped to sigma 8; list rows do not
  blur (`glass_container.dart:87-110`). Text shadows were removed in commit `fee7451`.
- Sheet-music pages are decoded at 2× screen width, not full scan resolution
  (`sheet_music_viewer.dart:355-384`), which bounds image memory per page.
- Index display list is memoised per sort (`index_page.dart:948-958`).
- Edition loads are de-duplicated in flight and served from memory for one minute
  (`hymn_remote_data_source.dart:39, 60-68`).
- Downloads stream to disk (no whole-file buffering) and hash incrementally
  (`local_media_cache_service.dart:189-198`).

## Findings

### PERF-01 — Download progress notifies listeners on every network chunk · MEDIUM · POSSIBLE
`downloadMissingMedia` calls `onProgress` per chunk from up to 6 workers
(`offline_media_download.dart:314-326`); the controller calls `notifyListeners()` each time
(`offline_download_controller.dart:543-546`). On a fast connection that is hundreds of
notifications a second during a bulk download, each rebuilding every listening widget (Settings
tiles, the hymn-page media controls). Impact is unmeasured; on low-end devices it can cost
frames while the user keeps reading. Direction: throttle to ~4–10 Hz.

### PERF-02 — Bundled and stored catalogues are decoded on the UI isolate · LOW · CONFIRMED
`json_data_source.dart:67-68` (`SDA_Hymnal.json`, 552 KB) and `edition_store.dart:128, 143`
(stored editions, each a few hundred KB with lyrics) use `jsonDecode` on the main isolate. On a
fast phone this is tens of milliseconds; on a slow one it can drop frames at startup or on first
open of an edition. `_CachedEdition.fromSongs` also maps and sorts all songs synchronously
(`hymn_remote_data_source.dart:541-544`). Direction: `compute()` for decode + map when measured
to matter.

### PERF-03 — Search re-normalises every title and lyric on every query · LOW · CONFIRMED
`SearchEngine._matchHymn` calls `_normalizeAmharic`/`_normalizeEnglish` on each field for each
hymn per query (`search_engine.dart:330, 343, 365, 384, 426, 434`); there is no precomputed index
(the `normalizedIndex` parameter is unused). With ~325 hymns it is fine; it scales linearly with
edition size and runs on the UI isolate per (debounced) keystroke. Direction: cache normalised
fields per loaded edition.

### PERF-04 — Every search keystroke emits `HymnsLoading` app-wide · LOW · CONFIRMED
See ARCH-01. All five IndexedStack tabs rebuild twice per search.

### MEM-01 — Memory profile of a full edition · INFO · CONFIRMED (code)
Per loaded edition the app holds: the raw API song maps (`_CachedEdition.songs`), the mapped
`HymnModel` list, the domain `Hymn` list (mapped again on every repository call:
`hymn_repository_impl.dart:363, 399, 428, 460`), plus the last bloc state. Lyrics therefore exist
in 2–3 copies. Not a leak, and modest for 300-song editions; it grows with every edition opened
in a session because `_cache` in `HymnRemoteDataSource` is never trimmed.

### MEM-02 — No leak patterns found by static scan · INFO
Controllers, focus nodes and subscriptions created in widgets are disposed (scan of
`lib/`: every file creating them has matching `dispose`/`cancel`; `addListener`/`removeListener`
counts match per file). Stricter lints (`cancel_subscriptions`, `close_sinks`) on a scratch copy
reported one subscription, which is in fact cancelled in `_stopScreenProtection`
(`sheet_music_viewer_page.dart:178-183`). Singleton stream controllers in
`GlobalAudioService` live for the app's lifetime by design.

### Sheet music zoom (INFO)
`InteractiveViewer` 1×–4× (`sheet_music_viewer.dart:38-39, 229-243`), images decoded at 2× screen
width: beyond 2× zoom the page is upscaled and softer. A trade of sharpness for memory; check on
a tablet whether notes stay legible at the zoom readers actually use.

## Startup path (code)
`main()` awaits `AudioService.init` before `runApp` (`main.dart:33-41`), then
`initDependencies()` + `ScreenService.initialize()` behind a blank splash
(`main.dart:81-94, 138-146`), then the first `LoadHymns`, which on first launch performs a
network check (5 s timeout) and a full `/sync` (15 s per page) before content appears, falling
back to bundled data only after those fail. On a slow or captive network the first launch can
show a spinner for up to ~20 s. Not measured.

## Low-end device checklist for Phase 2 (Windows-verifiable)
Run on an API 24–28, 2 GB device: cold start to first list; scroll Index by name (alphabet bar);
open hymn → swipe 20 hymns; pinch lyrics; open sheet music and zoom; bulk download while
scrolling; switch editions. Record `FrameStatsProbe` output and `adb shell dumpsys meminfo`.
