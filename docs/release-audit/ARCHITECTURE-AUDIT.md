# Architecture Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only.

## 1. Repository map

| Path | Tracked files | Notes |
|---|---|---|
| `lib/` | 119 Dart files, 25,652 lines | app code |
| `test/` | 97 files | unit, widget, bloc, contract, accessibility tests |
| `integration_test/` | `app_test.dart`, `native/native_flows_test.dart` (Patrol), `perf/performance_test.dart` | `test_bundle.dart` is generated and git-ignored |
| `test_driver/` | `perf_driver.dart` | flutter_driver remnant used by perf test |
| `test_live/` | `live_api_test.dart` | hits the production API (nightly) |
| `android/` | 25 tracked | Kotlin `MainActivity`, Gradle (Groovy) |
| `ios/` | 21 tracked (no Podfile) | Swift `AppDelegate` |
| `web/`, `windows/`, `macos/`, `linux/` | scaffolds | not release targets |
| `assets/` | data (2 JSON), 6 fonts, 3 images, 4 onboarding WebP, **34 category WebP not declared in pubspec** | |
| `tool/` | security scan, coverage gate | used by CI |
| `.github/workflows/` | `test.yml`, `nightly.yml` | Android/web only |
| `docs/` | 39 files | plus 5 stale summaries at repo root |
| Backend (separate repo) | `D:\Church\App\amharic_hymnal_backend` | Express on Vercel, Prisma/Postgres, S3-compatible storage |

## 2. Runtime architecture (actual)

```
main() ─ GlobalAudioService.initialize() → AudioService.init(HymnalAudioHandler)   [before runApp]
       ─ CrashReporting.run(runApp(AppInitializer))      [Sentry only if DSN defined]
AppInitializer → initDependencies() (get_it) → MyApp
MyApp: one app-wide HymnsBloc (BlocProvider) + MaterialApp rebuilt on Theme/Language change
MainNavigationPage: IndexedStack of 5 tabs (Number, Index, Categories, Favorites, Settings)
                    all reading the same HymnsBloc state

HymnsBloc → use cases → HymnRepositoryImpl → LocalDataSource
LocalDataSource: HymnRemoteDataSource first (API + on-device EditionStore),
                 bundled JSON (JsonDataSource) only if the API path throws and the edition
                 is one of the three bundled ones
HymnRemoteDataSource: GET /hymn-versions/{code} (ETag) → GET /sync (paged, delta by serverTime)
                      → FileEditionStore (Application Support/content_cache/*.json, atomic rename)
                      → prune media not referenced by any stored edition
Media: API downloadUrl → 302 → presigned object-storage URL → LocalMediaCacheService
       (Application Support/media_cache/{audio|sheet_music}/<sha256>.<ext>, verified, atomic)
Audio: just_audio inside audio_service handler; plays downloaded files only
Persistence: SharedPreferences (settings, favourites, history), flutter_secure_storage (report queue)
Singletons: ~15 ChangeNotifier/static services (Theme, Language, FontSize, Background,
            HymnalVersionService, OfflineDownloadController, SettingsService, HistoryService, …)
```

**Correction to an earlier statement in this project:** content is API-first. `HymnRemoteDataSource._pull`
calls `/sync` (`hymn_remote_data_source.dart:259-322`). Bundled JSON is only an offline fallback.
An earlier conversation stated no app code called `/sync`; that was wrong for this commit.

## 3. Intended vs actual

| Intended (from structure/names) | Actual |
|---|---|
| Clean architecture: data → domain → presentation | Mostly followed for hymns. Settings, history, media, audio, versions bypass it as static/singleton services called from widgets. |
| "LocalDataSource" | Is the remote-first source; the name hides that every load may hit the network. |
| DI via get_it | Only 9 registrations. Most services are `X.instance` / factory singletons constructed in widgets. Test seams exist via constructor parameters. |
| Feature state in blocs | One app-wide `HymnsBloc` holds the catalogue **and** per-tab view state (search results, sort, single-hymn lookups). See ARCH-01. |
| `failures.dart` taxonomy (Server/Cache/Network/Sync) | Collapsed into two English messages in the bloc. See ERR-01. |

## 4. Findings

### ARCH-01 — One bloc carries every tab's view state · MEDIUM · CONFIRMED (code) / impact POSSIBLE
- `index_page.dart:575`, `number_search_page.dart:107`, `favorites_page.dart:86` dispatch
  `SearchHymnsEvent` on the shared bloc; `_onSearchHymns` emits `HymnsLoading` then
  `HymnsLoaded(results, 'search')` (`hymns_bloc.dart:186-216`). Every tab in the IndexedStack
  rebuilds from that state.
- Mitigated by reloading on tab switch (`main_navigation_page.dart:430-448`). Remaining
  exposure: each keystroke flashes a spinner state app-wide; a forced refresh while a search is
  showing (`main_navigation_page.dart:125-145`, keeps `sortType` `'search'`) replaces the results
  with the full list still labelled as a search.
- Direction: keep the catalogue in the bloc; move search results and lookups into per-page state.

### ERR-01 — Failure taxonomy collapses · MEDIUM · CONFIRMED
- `hymn_repository_impl.dart:369-385` maps every non-`DatabaseNotFoundException` to
  `CacheFailure`; `getHymnByNumber` returns `ServerFailure('Hymn #n not found')` for a missing
  number (`:397`, `:409`) and for real errors (`:419`). The bloc shows "Hymn #n not found." for
  any failure, including offline (`hymns_bloc.dart:341-342`), and only two load messages exist
  (`:126-132`).
- The API client *does* carry stable codes (`HymnalApiException.code`, `hymnal_api_response.dart`)
  and handles `SONG_NOT_FOUND`, `HYMN_VERSION_NOT_FOUND`, `RATE_LIMIT_EXCEEDED`,
  `INVALID_SYNC_CURSOR` correctly internally; the codes are lost before the UI.
- Effect: the reader cannot tell "no internet", "server down", "not found" or "rate limited" apart.

### DATA-02 — Bundled data errors look like an empty hymnal · MEDIUM · CONFIRMED
- `json_data_source.dart:247-251` returns `[]` on any parse/asset error; `LocalDataSource`
  maps it to an empty list and the bloc emits `HymnsLoaded([])`.

### DATA-03 — An edition retired on the server appears as an empty book · MEDIUM · CONFIRMED
- `hymn_remote_data_source.dart:123-126`: `isActive == false` → `return const []`, a success.
  `LocalDataSource` does not fall back (`local_data_source.dart:31-36`: "A successful empty
  response is authoritative"). If the selected edition is retired, the user sees an empty list
  with no explanation and no prompt to pick another.

### CONTENT-01 — Placeholder hymn in the bundled Hagerigna data · MEDIUM · CONFIRMED
- `assets/data/database/HagerignaData.json` entry 121: author `ሙከራ መዝሙር` ("test song"),
  title `የመዝሙር ርዕስ` ("song title"), lyrics `መዝሙር 1 መዝሙር 2 …`.
- Live API (checked 2026-10-01, `GET /sync?version=am-hagerigna`): song 121 has
  `isActive: false`, and `_applySongs` drops inactive songs (`hymn_remote_data_source.dart:340-341`).
  So it is shown **only** from the bundled fallback: first launch with no connection, or when
  the API is unreachable before a stored copy exists.
- The tests pin the defect: `test/core/bundled_content_test.dart:100-104, 158-159, 185` and
  `test/features/hymns/data/local_data_source_test.dart:86-89` assert exactly 121 Hagerigna
  songs, so removing the placeholder requires updating them.

### SCALE-01 — Scalability to new hymnals · INFO (strength with limits)
Strengths: editions are discovered from `/hymn-versions` (`hymnal_version_service.dart:50-71`)
with the four known ones as fallback; API codes map generically (`hymnal_version.dart:181-206`);
media is content-addressed by SHA-256 so files shared between editions download once; delta sync
and ETags keep metadata traffic small.
Hard-coded limits a new edition will hit:
- Offline fallback exists only for 2004/1975/Hagerigna (`database_config.dart:302-335`); 1961
  and any new edition need the network on first use (`local_data_source.dart:45-50`).
- Category-by-number ranges apply only to `sda_new` (`hymn_categories.dart`,
  `local_data_source.dart:66-69`, `hymn_remote_data_source.dart:426-429`).
- `newHymnalNumber`/`oldHymnalNumber` fields are 2004/1975 specific (`hymn_remote_data_source.dart:437-440`).
- Bundled parsers are format-specific (`SdaParser`, `HagerignaParser`; `json_data_source.dart:227-236`).
- Favourites and history are keyed by `version:number` (`settings_service.dart:122-124`,
  `history_service.dart:340`). If a server edit renumbers a song, favourites silently point at a
  different hymn. Song IDs are available and stable but unused for persistence.
- Unknown editions get their raw id as label in `HymnalVersions.byId` (`hymnal_version.dart:160-176`)
  unless `HymnalVersionService` supplies the API name.

### CODE-02 — Bundled loader concurrency guard is ineffective · LOW · CONFIRMED
- `json_data_source.dart:195-202`: a second caller waits 100 ms, then loads again if not cached;
  `_isLoading` is cleared by whichever finishes first. Duplicate parsing only, no corruption.

### CODE-01 — Small correctness/maintainability items · LOW · CONFIRMED
- `settings_service.dart:83` comment says 12.0–30.0; maximum is now 40.
- `history_page.dart:61-62`: `historyClear ?? historyClear ?? …` duplicated lookup.
- `settings_service.dart:137-159`: `getFavoriteHymns()` writes to storage (unawaited) from a getter.
- `android/build.gradle:7`: a stray line containing only `2` (valid Groovy, so harmless, but garbage).
- `global_audio_service.dart:31-32`: notification channel id `com.example.amharic_hymnal_app.audio`
  (template leftover; changing it later creates a second channel on users' phones).
- Five stale status files at the repo root (`GAP_FILLING_SUMMARY.md`, `IMPLEMENTATION_COMPLETE.md`,
  `PERFORMANCE_SUMMARY.md`, `PR_SUMMARY.md`, `MAINTAINER_ACTIONS.md`).
- `assets/category/` holds 34 WebP files not declared in `pubspec.yaml` (not shipped; repo weight only).

## 5. API / network behaviour (client side)

| Concern | Status | Evidence |
|---|---|---|
| Timeouts | metadata 5 s, sync page 15 s, media headers 45 s, analytics 5 s; **no stream idle timeout** (DL-01) | `hymn_remote_data_source.dart:46-47`, `local_media_cache_service.dart:183` |
| Retries/backoff | honours `429/503` with `RateLimit t=` / `Retry-After`, capped 5 min; no automatic retry storms | `hymnal_api_client.dart:61-104` |
| Conditional requests | ETag/`If-None-Match` on edition metadata | `hymnal_api_client.dart:70-88` |
| Request dedup | in-flight map per edition | `hymn_remote_data_source.dart:60-68` |
| Freshness | 1-minute window between checks; full resync every 7 days to catch hard deletes | `:39-44` |
| Malformed responses | non-JSON / non-object → `INVALID_RESPONSE`; missing fields → `FormatException` → served offline copy if any | `hymnal_api_response.dart:125-155` |
| Not found | `SONG_NOT_FOUND` handled on refetch; `HYMN_VERSION_NOT_FOUND` forgets the stored edition | `:90-95`, `:393-396` |
| HTTPS | release builds reject non-HTTPS overrides | `content_api_config.dart:25-28` |
| Request IDs / app version header | none sent | — (INFO) |
| Large media through Vercel | no: 302 to presigned storage URL | backend `src/services/download-service.ts:155-157` |

Backend not-found behaviour (404 `SONG_NOT_FOUND` vs 500) was not exercised beyond the
client's handling; the backend has its own tests and was not audited in depth.
