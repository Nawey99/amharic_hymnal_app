# Privacy Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only. This is an inventory of what the code
does, for filling store forms. It is not a privacy policy and does not replace one.

## Data inventory (from code)

| Data | Leaves device? | When | Where to | Identifiers | Evidence |
|---|---|---|---|---|---|
| Settings, favourites, history, search text | No | — | SharedPreferences | — | `settings_service.dart`, `history_service.dart`; search runs locally (`search_engine.dart`) |
| Downloaded hymns, audio, sheet music | No (stored) | — | Application Support | — | `edition_store.dart`, `local_media_cache_service.dart` |
| Content requests | Yes | every edition check/sync, media download | Vercel API; object storage via presigned URL | IP address (inherent); no app/device id, no user agent set by the app | `hymn_remote_data_source.dart`, `local_media_cache_service.dart` |
| Usage events: `SONG_VIEW` (song id, edition, source list/search/favourites), `CATEGORY_VIEW` (slug) | Yes | on open, **every release build**, no opt-out | API `/analytics/events` | none in payload | `analytics_service.dart:92, 105-125`; `main_navigation_page.dart:307`; `categories_page.dart:235` |
| Media download counts | Yes (server-side) | per download | API | — | backend `download-service.ts:146-153` |
| Bug/content reports: text, type, hymn ref, app version, platform, OS version, model, screen, app language, **optional email/phone** | Yes | user-initiated; queued encrypted offline | API | contact only if typed | `bug_report_queue_service.dart:60-90, 327-367`; `report_bug_page.dart:87-106` |
| Crash reports (error, stack, app version, device model) | Only builds with `WUDASE_SENTRY_DSN` | on error | Sentry | `sendDefaultPii=false`; user/request/serverName scrubbed; no screenshots or view hierarchy | `crash_reporting.dart` |
| Update check | Yes | once per run | API `/manifest` | — | `app_update_service.dart` |

No advertising SDK, no tracking across apps, no account, no location, no contacts, no camera or
microphone access was found.

## Findings

### STORE-01 — Store declarations must reflect the inventory · HIGH — see RELEASE-BLOCKERS.md
Indicative mapping (to be confirmed by the owner against each store's definitions):
- Google Play Data safety: **App activity → App interactions** (usage events; collected, not
  shared, not linked to identity); **Personal info → Email address / Phone number** (optional,
  user-provided in reports); **App info and performance → Diagnostics** (report diagnostics;
  crash logs only if Sentry ships); data encrypted in transit: yes; deletion request: by email
  (as the policy states).
- Apple App Privacy: **Usage Data → Product Interaction**; **Contact Info → Email Address / Phone
  Number** (optional); **Diagnostics → Other Diagnostic Data** (and Crash Data if Sentry ships);
  all "not linked to you", "not used for tracking".

### PRIV-01 — WITHDRAWN in the re-check: the policy is correct
A live media download (`GET …/songs/am-sda-2004-0002/audio/file`) answers `302` to
`https://<project>.supabase.co/…`, and the backend README states "Supabase Storage in
production". The R2 wording below came from a generic code comment. Original text kept for
the record:

#### (original) Policy's processor list likely does not match production storage · MEDIUM · LIKELY
The live policy (HTTP 200, effective 2026-09-28) says Supabase stores "audio and sheet-music
files" and lists Vercel, Supabase, Upstash and Sentry. The backend's storage driver in production
must be `s3` (`src/config/index.ts:289-317`) and its comments describe "presigned R2 URLs"
(`:379`) — i.e. Cloudflare R2 per the project brief. If media is on R2, Cloudflare is a processor
that sees readers' IP addresses and is not named. Direction: check the production
`STORAGE_*` settings and update the policy's provider table.

### PRIV-02 — Stored "data collection" switch is never read · LOW · CONFIRMED
`SettingsService.isDataCollectionEnabled()` / `setDataCollectionEnabled()` exist
(`settings_service.dart:312-322`, default `true`) but nothing calls them and no UI exposes them;
`AnalyticsService` ignores the flag. The policy does not promise an opt-out, so this is not a
misstatement — but it is dead code that looks like a control. Decide: wire it to a Settings
toggle and to `AnalyticsService`, or remove it.

### PRIV-03 — Report queue is encrypted at rest · INFO · CONFIRMED
`flutter_secure_storage` (Android EncryptedSharedPreferences / iOS Keychain); legacy plain queue
migrated and removed (`bug_report_queue_service.dart:41-52`). Web does not persist reports.

### PRIV-04 — Sheet music screenshot protection · INFO · CONFIRMED
Android `FLAG_SECURE` and an iOS privacy overlay on capture/backgrounding while sheet music is
visible (`MainActivity.kt`, `AppDelegate.swift`, `sheet_music_viewer_page.dart`). Matches the
policy's statement.

### PRIV-05 — Policy content vs code · INFO
All other policy statements checked against code agree: search not sent; usage counts carry no
device id; reports include the diagnostics listed; crash reports only in test builds; HTTPS only;
checksums verified. Retention periods (90 days, 12 months) are server-side and were not verified.

## Before submission (owner actions, not code)
1. Confirm production media host; update the policy's provider list if needed (PRIV-01).
2. Fill Play Data safety and App Store App Privacy from the table above.
3. Play Console: foreground-service declaration for `mediaPlayback` with a demo video.
4. Keep the policy URL identical in both store listings and in Settings.
