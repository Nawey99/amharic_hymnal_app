# Security Findings

Audit date: 2026-10-01. Read-only assessment; nothing was fixed.

| Assessed | Revision |
| --- | --- |
| Flutter app `amharic_hymnal_app` | branch `reading-experience`, commit `b4d78a0` |
| Backend `amharic_hymnal_backend` | commit `ab3ed4f` |
| Release artifact | `build/app/outputs/flutter-apk/app-release.apk`, built 2026-09-29 (may predate the current commit) |
| Live API | `https://amharichymnalbackend.vercel.app` |

Counts: **CRITICAL 0, HIGH 0, MEDIUM 2, LOW 13, INFO 12** (27 total).
Confidence: CONFIRMED 22, LIKELY 3, POSSIBLE 2.

MASWE and MASTG identifiers were assigned from memory of the OWASP catalogue and
only where the mapping is natural; a dash means no mapping was forced. Backend
and operational findings mostly have no mobile mapping. Check identifiers
against the current catalogue before quoting them externally.

## Master table

| ID | Sev | Confidence | MASVS | MASWE | Platform | Component | Title | Evidence | Impact | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| F-01 | MEDIUM | CONFIRMED | PRIVACY | — | Backend | cron route, `src/app.ts:96` | Scheduled maintenance is rejected by the global JWT check, so retention never runs | Live: bearer on `/internal/maintenance` answers "access token is invalid or expired" | 90-day analytics deletion promised in the privacy policy is not enforced | Open |
| F-02 | MEDIUM | CONFIRMED | — | — | Backend / CI | `D:\Church\App\backups\`, `.env.production`, `.vercel/` | Production credentials, a Supabase management token and two DB dumps in plaintext on the workstation | Variable names listed; values not read | One disk or backup compromise yields the whole backend | Open |
| F-03 | LOW | CONFIRMED | AUTH | — | Backend | Supabase Auth | Public sign-up is enabled on the project that issues admin tokens | `/auth/v1/settings`: `disable_signup: false` | Anyone can obtain a valid API token (role USER); admin gate rests on one claim | Open |
| F-04 | LOW | CONFIRMED | PRIVACY | — | CI/CD | backend `backup.yml:88-100` | Daily production DB dumps uploaded as unencrypted GitHub artifacts | Workflow text; repo is PRIVATE | Report contact details readable by anyone with repo read access | Open |
| F-05 | LOW | CONFIRMED | PLATFORM / CODE | — | Android | release APK manifest | Test instrumentation ships in the release APK | 3 exported `androidx.test` activities, `REORDER_TASKS`, Patrol classes | Needless exported components and permission | Open |
| F-06 | LOW | CONFIRMED | PRIVACY | — | Backend / Database | `reports` table | Bug reports with optional contact details are kept forever | `maintenance-job.ts:29-31` deletes analytics only | Personal data accumulates and is copied into every dump | Open |
| F-07 | LOW | LIKELY | — | — | Database | migration `20260922100000_song_links` | Two tables created after the lock-down have no RLS | `CREATE TABLE` without `ENABLE ROW LEVEL SECURITY` | One of two defences missing for those tables | Open |
| F-08 | LOW | LIKELY | NETWORK | — | Backend / Database | `DATABASE_URL` | Production database URL has no `sslmode` | Parameter absent (names only inspected) | TLS to Postgres is preferred, not required or verified | Open |
| F-09 | LOW | CONFIRMED | CODE | MASWE-0076 | Backend | `package-lock.json` | `npm audit --omit=dev` reports 1 high, 1 moderate; CI gate is red | Audit output (sub-review) | Deploys must bypass CI while the gate fails | Open |
| F-10 | LOW | LIKELY | CODE | MASWE-0076 | Flutter | `pubspec.lock`, CI | Flutter 3.27.2 (Jan 2025) pinned; several plugins majors behind | `flutter --version`, `pub outdated` | Engine native libraries carry no fixes since then | Open |
| F-11 | LOW | CONFIRMED | — | — | Backend | `/health`, `/api/v1/health` | Health endpoint discloses environment, uptime, memory and dependency latency, unlimited | Live response | Reconnaissance; each uncached call costs a DB and storage round trip | Open |
| F-12 | LOW | CONFIRMED | — | — | Backend | `router.ts:170-180`, `rate-limits.ts:103` | Catalogue routes have no limiter; limiters fail open | Live: no `RateLimit` header on 9 routes | Unbounded anonymous database reads | Open |
| F-13 | LOW | CONFIRMED | AUTH | — | Backend | `src/admin-ui/sign-in.ts` | Admin tokens kept in web storage; sign-out does not revoke the session | `sign-in.ts:79-81, 171-177` | A copied refresh token outlives sign-out | Open |
| F-14 | LOW | CONFIRMED | — | — | Android / CI | `android/key.properties` | Upload-keystore passwords in plaintext beside the keystore | Key names and path only | Disk compromise yields the Play upload key | Open |
| F-15 | LOW | CONFIRMED | — | — | CI/CD | backend `ci.yml`, `backup.yml` | Actions pinned by tag; production DB URL present during `npm ci` | `ci.yml:110-128` | A compromised dependency or action sees the owner connection string | Open |
| F-16 | INFO | CONFIRMED | — | — | Backend | `/search` | A NUL byte in `q` returns HTTP 500 | Live: `q=%00…` gives `DATABASE_ERROR` | Anonymous caller can generate 500s; no data leak | Open |
| F-17 | INFO | CONFIRMED | NETWORK | — | Flutter | `media_reference.dart`, `hymnal_audio_handler.dart:130` | Media URLs from the API are accepted for any host; audio for any scheme | Code | Only matters if the API itself is compromised | Open |
| F-18 | INFO | CONFIRMED | CODE | — | Flutter | `local_media_cache_service.dart:193`, `hymn_remote_data_source.dart:271` | No size ceiling on a download or page ceiling on sync | Code | A hostile server could fill storage | Open |
| F-19 | INFO | POSSIBLE | PLATFORM | — | Android | `AndroidManifest.xml:36` | AudioService is guarded by a permission name Android does not define | Manifest | Another app could define and hold that name | Open |
| F-20 | INFO | CONFIRMED | RESILIENCE | MASWE-0089 | Flutter | `libapp.so` | Dart code is not obfuscated | 117 `package:amharic_hymnal_app` strings recovered | Structure readable; no secret is exposed by it | Open |
| F-21 | INFO | POSSIBLE | STORAGE | — | iOS | Keychain, `ios/` | iOS has never been built here; queued reports would outlive uninstall | No `Podfile`; no team ID | Policy says uninstall deletes everything | Open |
| F-22 | INFO | CONFIRMED | — | — | Source control | public app repo | Device serial, personal email and retired admin-server source in a public repo | `docs/*.md`, history | Minor disclosure | Open |
| F-23 | INFO | CONFIRMED | — | — | Android / CI | `gradle-wrapper.properties` | Gradle wrapper has no `distributionSha256Sum` | File | Download not checksum-verified | Open |
| F-24 | INFO | CONFIRMED | PRIVACY | — | Flutter | `settings_service.dart:313` | `data_collection_enabled` is stored but nothing reads it | grep | No way to switch analytics off | Open |
| F-25 | INFO | CONFIRMED | — | — | Backend | runtime credentials | Function runs as database owner with an all-bucket storage key | lock-down migration comment; storage config | Any backend compromise is total | Open |
| F-26 | INFO | CONFIRMED | — | — | Backend | `/api/v1/openapi.json` | Public OpenAPI document maps the admin surface | Live: 14 admin paths | Reconnaissance only; routes are gated | Open |
| F-27 | INFO | CONFIRMED | — | — | Flutter web | `web/_headers` | Web CSP allows `connect-src https:`; headers ignored on GitHub Pages | File | Web build only | Open |

---

## F-01 Scheduled maintenance is rejected by the global JWT check

- **Severity:** MEDIUM. **Confidence:** CONFIRMED (mechanism, live).
- **MASVS:** MASVS-PRIVACY. **MASWE / MASTG:** —
- **Platform:** Backend.
- **Component:** `src/app.ts:96` (`app.use(optionalAuthentication(...))`), `src/middleware/auth.ts:20-39`, `src/controllers/maintenance-controller.ts:49-70`, `vercel.json` cron `/api/v1/internal/maintenance`.
- **Evidence:** `optionalAuthentication` is mounted for every route and tries to verify any `Authorization: Bearer …` value as a Supabase JWT, answering 401 on failure. The maintenance controller expects the same header to carry `CRON_SECRET`. Live test with a non-JWT bearer value:
  - no header: `401 "A valid scheduler credential is required."` (the controller answered)
  - `Authorization: Bearer not-the-secret`: `401 "The access token is invalid or expired."` (the global middleware answered; the controller was never reached)
  
  Vercel Cron sends `Authorization: Bearer <CRON_SECRET>`, which is not a JWT, so it takes the second path. No test in `test/` covers the cron route with authentication enabled.
- **Precondition:** none; this is the normal scheduled call.
- **Attack surface:** none. This is a failing control, not an attack.
- **Impact:** `MaintenanceJob` (analytics retention, orphan report) does not run from the scheduler. `docs/privacy-policy.md:15,45-46` states usage counts and search text are deleted after 90 days. Stored search text (up to 100 characters per query) therefore outlives the published retention period.
- **Exploitability:** not applicable.
- **Mitigating controls:** analytics rows hold no IP, user or device identifier. `npm run maintenance` can be run by hand.
- **Not verified:** whether the cron has ever succeeded (Vercel cron logs), and whether retention is being run manually. REQUIRES BACKEND ACCESS.
- **Remediation direction:** let the cron route authenticate before, or outside, the JWT middleware; add a test that calls it with authentication enabled; confirm in Vercel logs that the next run returns 200.

## F-02 Production credentials, a management token and database dumps in plaintext on the workstation

- **Severity:** MEDIUM. **Confidence:** CONFIRMED (presence; values were not read).
- **MASVS / MASWE / MASTG:** —
- **Platform:** Backend / CI.
- **Component and evidence (variable names only):**
  - `amharic_hymnal_backend/.env.production` (git-ignored): `DATABASE_URL`, `DIRECT_DATABASE_URL`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `RATE_LIMIT_REDIS_TOKEN`, `CRON_SECRET`.
  - `amharic_hymnal_backend/.vercel/.env.production.local` (git-ignored): the same, plus a Vercel OIDC token.
  - `D:\Church\App\backups\.env.production.before-token-removal` (outside any repository): the same set **plus `SUPABASE_ACCESS_TOKEN`**.
  - `D:\Church\App\backups\hymnal-20260921.dump`, `hymnal-20260922-before-song-links.dump`: unencrypted production dumps.
- **Precondition:** access to the workstation, its backups, or a synced or shared copy of `D:\Church\App`.
- **Impact:** database owner password, storage keys, cron secret and, if still valid, a Supabase account-level management token. The dumps contain bug-report messages and contact details.
- **Exploitability:** local only. None of these files is tracked, and full history of both repositories is clean.
- **Mitigating controls:** `.gitignore` covers `.env*`; TruffleHog and `tool/security_scan.mjs` run in CI.
- **Not verified:** whether the management token was revoked when it was removed from the live file. It was deliberately not tested. REQUIRES PRODUCTION CONFIGURATION.
- **Remediation direction:** revoke the old management token in the Supabase dashboard; delete the backup env file; keep dumps and env files in encrypted storage. This becomes a release blocker only if any of it has left the machine.

## F-03 Public sign-up is enabled on the Supabase project that issues admin tokens

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **MASVS:** MASVS-AUTH. **MASWE / MASTG:** —
- **Platform:** Backend (Supabase Auth).
- **Evidence:** the anon key and project URL are served to anyone in `/admin/app.js`. `GET /auth/v1/settings` with that key returned `disable_signup: false`, `mailer_autoconfirm: false`, email provider enabled. No sign-up was attempted.
- **Precondition:** an email address.
- **Attack surface:** Supabase Auth sign-up endpoint.
- **Impact:** any visitor can create an account and receive a JWT the API accepts as authenticated with role `USER` (`supabase-jwt-auth-service.ts:15-30`). Today that grants nothing: every admin route requires `MODERATOR` or `ADMIN` read from `app_metadata.role`, which users cannot set. The exposure is that the admin boundary rests on a single claim, plus account spam and use of the project's email quota.
- **Mitigating controls:** role checks on every admin route (verified live: all 11 probed admin routes answer 401 without a token); `app_metadata` is server-controlled; email confirmation is required.
- **Remediation direction:** disable sign-ups for this project, since only operators need accounts.

## F-04 Daily production database dumps uploaded as unencrypted GitHub artifacts

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **MASVS:** MASVS-PRIVACY. **Platform:** CI/CD.
- **Evidence:** backend `.github/workflows/backup.yml:88-100` runs `pg_dump --format=custom` daily and uploads with `actions/upload-artifact@v4`, `retention-days: 30`, no encryption step. `gh repo view` reports the backend repository as PRIVATE.
- **Impact:** each artifact holds `reports` (message and optional contact), `admin_audit_logs` and `user_profiles`. Readable by anyone with read access to the repository.
- **Mitigating controls:** private repository with one owner.
- **Remediation direction:** encrypt the dump before upload, or send it to private storage. Would rise to HIGH if the repository were made public.

## F-05 Test instrumentation ships in the release APK

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **MASVS:** MASVS-PLATFORM, MASVS-CODE. **MASTG:** MASTG-TEST-0029 (exposed IPC components).
- **Platform:** Android.
- **Evidence (`aapt2 dump xmltree` of the release APK):**
  - `androidx.test.core.app.InstrumentationActivityInvoker$BootstrapActivity`, `$EmptyActivity`, `$EmptyFloatingActivity`, all `exported=true`.
  - `uses-permission android.permission.REORDER_TASKS`, and `<queries>` for `androidx.test.orchestrator` and `androidx.test.services`.
  - `classes.dex` contains `pl/leancode/patrol` and `androidx/test/*`; the APK root holds `junit/`, `LICENSE-junit.txt` and `custom.config.yaml` (`ktor … port : 4244`).
  
  Source: `patrol` and `integration_test` are dev dependencies, but Flutter 3.27 registers their plugins in every build mode.
- **Impact:** three inert exported activities and one unneeded permission. The activities display nothing and read no input, so no data is exposed. The Patrol server starts only under instrumentation.
- **Exploitability:** low; another app can launch an empty activity in this app's task.
- **Mitigating controls:** R8 removed most of the test code.
- **Remediation direction:** keep test-only plugins out of release builds and re-inspect the merged manifest.

## F-06 Bug reports with contact details are kept forever

- **Severity:** LOW. **Confidence:** CONFIRMED (code).
- **MASVS:** MASVS-PRIVACY. **Platform:** Backend / Database.
- **Evidence:** backend `src/jobs/maintenance-job.ts:29-31` deletes analytics events only. `prisma/schema.prisma:745-773` defines `Report.contact`, `message`, `context` with no expiry.
- **Impact:** optional email or phone numbers accumulate without limit and are included in every dump (F-02, F-04). The privacy policy offers deletion on request by email.
- **Remediation direction:** decide a retention period for resolved and dismissed reports and enforce it in the maintenance job.

## F-07 Two tables created after the lock-down have no row-level security

- **Severity:** LOW. **Confidence:** LIKELY (confirmed in migrations; live catalogue not inspected).
- **Platform:** Database.
- **Evidence:** `prisma/migrations/20260922100000_song_links/migration.sql:7,22` creates `work_relations` and `link_suggestions` with no `ENABLE ROW LEVEL SECURITY`. The lock-down loop in `20260918150000_lock_down_data_api` only covered tables existing four days earlier.
- **Impact:** for these two tables only the grant revocation remains, not the second defence the lock-down describes. The data is hymn-link metadata, not personal.
- **Mitigating controls:** verified live that the Data API exposes nothing: with the anon key, `/rest/v1/<table>` answers `PGRST205 … 'api_disabled.<table>'` for `songs`, `user_profiles`, `reports`, `audit_log`.
- **Remediation direction:** a follow-up migration enabling RLS, and a CI check that every `public` table has it. REQUIRES BACKEND ACCESS to confirm the live state.

## F-08 Production database URL has no `sslmode`

- **Severity:** LOW. **Confidence:** LIKELY.
- **MASVS:** MASVS-NETWORK (server side). **Platform:** Backend / Database.
- **Evidence:** the only query parameters in the production `DATABASE_URL` are `pgbouncer` and `connection_limit` (names inspected, value not read). `src/config/index.ts` does not require `sslmode`.
- **Impact:** the Prisma default prefers TLS without requiring it or verifying the certificate. Encryption then depends on Supabase enforcing SSL.
- **Not verified:** the project's "Enforce SSL" setting. REQUIRES PRODUCTION CONFIGURATION.
- **Remediation direction:** require TLS in the connection string and reject a production URL without it.

## F-09 Backend dependency audit fails

- **Severity:** LOW. **Confidence:** CONFIRMED (audit output from the backend sub-review; not re-run).
- **MASVS:** MASVS-CODE. **MASWE:** MASWE-0076. **Platform:** Backend.
- **Evidence:** `npm audit --omit=dev`: `brace-expansion` 2.1.4 (high, DoS) via `archiver`, and `ip-address` 10.5.0 (moderate) via `express-rate-limit`. All lockfile entries resolve to `registry.npmjs.org`.
- **Impact:** `archiver` is used only by the operator CLI `scripts/import-media.ts`, so it is not reachable from a request. The practical effect is operational: `ci.yml:52` runs the audit as a gate, so `verify` and `deploy` fail and a deploy must go around CI.
- **Remediation direction:** update the two packages so the gate is green again.

## F-10 Flutter SDK and several plugins are well behind

- **Severity:** LOW. **Confidence:** LIKELY (lag confirmed; no specific advisory confirmed).
- **MASVS:** MASVS-CODE. **MASWE:** MASWE-0076. **MASTG:** MASTG-TEST-0042.
- **Platform:** Flutter.
- **Evidence:** Flutter 3.27.2 / Dart 3.6.1 (January 2025), also pinned in `.github/workflows/*.yml`. `flutter_secure_storage` 9.2.4 (latest 11.x), `share_plus` 10.1.4 (13.x), `package_info_plus` 8.3.1 (10.x). All 164 hosted packages resolve to pub.dev; no git or path sources.
- **Impact:** the engine's bundled libraries (Skia, image codecs, BoringSSL) have had no fixes for about 21 months. The app decodes WebP, PNG and JPEG it downloads, so codec fixes are the relevant part.
- **Mitigating controls:** downloaded images are checked against a SHA-256 from the API before use; OSV-Scanner runs in CI with `fail-on-vuln: true`.
- **Not verified:** `osv-scanner` is NOT AVAILABLE locally; the last CI result was not read.
- **Remediation direction:** plan a Flutter upgrade as its own change with a full regression pass.

## F-11 Health endpoint discloses runtime detail

- **Severity:** LOW. **Confidence:** CONFIRMED (live).
- **Platform:** Backend.
- **Evidence:** `GET /health` and `GET /api/v1/health` return `environment`, `version`, `uptimeSeconds`, database and storage status with latency, and `memory.rssBytes/heapUsedBytes/heapTotalBytes`. No `RateLimit` header.
- **Impact:** reconnaissance, and an unlimited route that triggers a database query and a storage `HeadBucket`.
- **Remediation direction:** return status only to anonymous callers; keep detail for the admin system view.

## F-12 Catalogue routes have no rate limiter, and limiters fail open

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **Platform:** Backend.
- **Evidence:** live responses for `/manifest`, `/categories`, `/songs` (56 KB), `/songs/:id`, `/songs/:id/audio`, `/hymn-versions`, `/hymn-versions/:code`, `/openapi.json` (116 KB) and `/health` carry no `RateLimit` header (`router.ts:152-180`). `rate-limits.ts:103` sets `passOnStoreError: true`.
- **Impact:** an anonymous script can issue unlimited database-backed reads. Cost and availability, not confidentiality.
- **Mitigating controls:** responses are `public, max-age=60`; search, sync, downloads, reports and analytics are limited; a spoofed `X-Forwarded-For` did not change the limiter bucket (tested, 14 requests).
- **Remediation direction:** a generous general limiter on read routes.

## F-13 Admin session handling

- **Severity:** LOW. **Confidence:** CONFIRMED (code, sub-review).
- **MASVS:** MASVS-AUTH. **Platform:** Backend (admin console).
- **Evidence:** `src/admin-ui/sign-in.ts:79-81` stores the access and refresh tokens in `sessionStorage`; `sign-in.ts:171-177` clears them on sign-out without calling Supabase's logout endpoint. The served script also references `localStorage`.
- **Impact:** a refresh token copied before sign-out stays usable until it rotates or expires.
- **Mitigating controls:** `script-src 'self'`, `script-src-attr 'none'`; every `innerHTML` sink reviewed escapes its input; anonymous report text is rendered with `textContent`; bearer header rather than cookies, so CSRF does not apply.
- **Remediation direction:** call the logout endpoint on sign-out.

## F-14 Upload-keystore passwords in plaintext beside the keystore

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **MASTG:** MASTG-TEST-0038 (signing). **Platform:** Android / CI.
- **Evidence:** `android/key.properties` (git-ignored, never committed) holds `storePassword`, `keyPassword`, `keyAlias`, `storeFile=D:/Church/App/keys/wudase-upload.jks`.
- **Impact:** the same disk compromise as F-02 yields the upload key. If Play App Signing is enrolled, an upload key can be reset; if this key is the app signing key, its loss is permanent.
- **Not verified:** Play App Signing enrolment. NOT VERIFIABLE without Play Console access.
- **Remediation direction:** confirm Play App Signing; keep an encrypted offline copy of the keystore.

## F-15 Backend CI supply-chain exposure

- **Severity:** LOW. **Confidence:** CONFIRMED.
- **Platform:** CI/CD.
- **Evidence:** backend workflows use `actions/checkout@v4`, `actions/setup-node@v4`, `actions/upload-artifact@v4` (tags, not commit SHAs); `backup.yml` has no `permissions:` block; `ci.yml:110-112` sets job-level `DATABASE_URL: ${{ secrets.DIRECT_DATABASE_URL }}` and `ci.yml:128` runs `npm ci`, which executes install scripts.
- **Contrast:** the app repository pins every action to a commit SHA and sets `permissions: contents: read`.
- **Remediation direction:** pin by SHA; give `npm ci` a placeholder URL.

## F-16 NUL byte in a search query returns HTTP 500

- **Severity:** INFO. **Confidence:** CONFIRMED (live).
- **Evidence:** `GET /api/v1/search?…&q=%00%0d%0aSet-Cookie:x=1` returned `500 {"code":"DATABASE_ERROR","message":"A database operation failed."}`. No header was injected and no detail leaked. Other malformed inputs returned 400 or empty results (see SECURITY-TEST-RESULTS.md).
- **Remediation direction:** reject control characters in `q` at validation.

## F-17 Client accepts any host for media URLs and any scheme for audio

- **Severity:** INFO. **Confidence:** CONFIRMED (code).
- **MASVS:** MASVS-NETWORK. **Platform:** Flutter.
- **Evidence:** `MediaReference._isRemoteUri` (`media_reference.dart:75-77`) accepts any `http`/`https` authority; `HymnalAudioHandler._validatedUri` (`hymnal_audio_handler.dart:130-136`) only requires a scheme; redirects are followed (`local_media_cache_service.dart:181-183`).
- **Impact:** none unless the API response is attacker-controlled, in which case the app could be pointed at another host. Cleartext is still blocked on Android release, and files with a checksum are verified.
- **Remediation direction:** optional: restrict media to `https` and to the API origin.

## F-18 No ceiling on download size or sync pages

- **Severity:** INFO. **Confidence:** CONFIRMED (code).
- **Evidence:** `LocalMediaCacheService.download` streams until the response ends (`:193-198`); when the API gives no `sizeBytes` and no `Content-Length`, nothing bounds it. `_pull` loops while `hasMore` is true (`hymn_remote_data_source.dart:271-306`).
- **Impact:** only a hostile or faulty server could fill device storage.

## F-19 AudioService guarded by an undefined permission name

- **Severity:** INFO. **Confidence:** POSSIBLE.
- **MASVS:** MASVS-PLATFORM. **MASTG:** MASTG-TEST-0029.
- **Evidence:** `android/app/src/main/AndroidManifest.xml:31-41`: `com.ryanheise.audioservice.AudioService`, `exported="true"`, `android:permission="android.permission.BIND_MEDIA_BROWSER_SERVICE"`. To my knowledge Android defines no permission of that name.
- **Impact:** if so, ordinary apps cannot bind (good), but an app that declares that permission name itself could, and would be able to browse and control hymn playback. It may also stop Android Auto or Bluetooth media browsing.
- **Not verified:** REQUIRES PHYSICAL DEVICE with a second test app.

## F-20 Dart code is not obfuscated

- **Severity:** INFO. **Confidence:** CONFIRMED.
- **MASVS:** MASVS-RESILIENCE. **MASWE:** MASWE-0089. **MASTG:** MASTG-TEST-0051.
- **Evidence:** `strings` on `lib/arm64-v8a/libapp.so` returns 117 `package:amharic_hymnal_app/...` paths and class names. R8 is enabled for the Java side (`minifyEnabled true`).
- **Impact:** an analyst can read the app's structure. Nothing sensitive depends on that: the only URLs in the binary are the public API root, the privacy page and the GitHub page. See REVERSE-ENGINEERING-AUDIT.md.

## F-21 iOS has not been built; Keychain items outlive uninstall

- **Severity:** INFO. **Confidence:** POSSIBLE.
- **MASVS:** MASVS-STORAGE. **Platform:** iOS.
- **Evidence:** no `ios/Podfile` or `Podfile.lock`; no `DEVELOPMENT_TEAM` in `project.pbxproj`; no entitlements file. `BugReportQueueService` stores queued reports with `flutter_secure_storage`, which on iOS uses the Keychain, and Keychain items survive app deletion. `docs/privacy-policy.md:30,110` says uninstalling deletes everything on the phone.
- **Not verified:** REQUIRES MAC.

## F-22 Disclosures in the public app repository

- **Severity:** INFO. **Confidence:** CONFIRMED.
- **Evidence:** the app repository is PUBLIC. Tracked docs contain an Android device serial (`docs/ANDROID_DEVICE_TROUBLESHOOTING.md:52,82` and two others) and the maintainer's email. History (commits `8522f8b`, `6d46245`, `fe6f6b9` and others) keeps the full source of the retired `backend/` servers, including a hard-coded non-production fallback admin token for a service that no longer exists. No live credential was found in any ref.

## F-23 Gradle wrapper has no checksum

- **Severity:** INFO. **Evidence:** `android/gradle/wrapper/gradle-wrapper.properties` has `validateDistributionUrl=true` and an HTTPS `services.gradle.org` URL but no `distributionSha256Sum`.

## F-24 Stored opt-out flag is never read

- **Severity:** INFO. **MASVS:** MASVS-PRIVACY.
- **Evidence:** `SettingsService.isDataCollectionEnabled` (`settings_service.dart:313-321`) has no caller; `AnalyticsService` sends whenever the build is not a debug build (`analytics_service.dart:27`). The policy describes the counts as automatic, so this is consistent, but there is no opt-out.

## F-25 Runtime credentials are broader than the runtime needs

- **Severity:** INFO.
- **Evidence:** the application connects as the table owner, which bypasses RLS by design (lock-down migration, lines 25-27). The storage key is a Supabase Storage S3 access key, which is not scoped to one bucket or to read-only, while the request path only signs `GetObject`.
- **Impact:** no injection or key leak was found; this describes blast radius.

## F-26 Public OpenAPI document maps the admin surface

- **Severity:** INFO. **Evidence:** `GET /api/v1/openapi.json` (116 KB, public) lists 14 `/admin` paths and the bearer scheme. The cron route is not listed. All admin routes answered 401 without a token.

## F-27 Web build headers

- **Severity:** INFO. **Evidence:** `web/_headers` sets a CSP with `connect-src 'self' https:` and no HSTS; the file format is honoured by Netlify and Cloudflare Pages, not GitHub Pages. Relevant only if the web build is deployed.
