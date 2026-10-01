# Security Test Results

Audit date: 2026-10-01. Host: Windows 11. All live tests were read-only GET,
HEAD or OPTIONS requests, plus three writes that could not succeed: two admin
writes with no token (401) and one zero-byte `PUT` against a GET-signed URL
(403). No production row or object was created, changed or deleted. No valid
report or analytics event was posted. No account was created. Roughly 150
requests were sent in total, none in a burst large enough to reach a limit.

## Tools

| Tool | Status | Used for |
| --- | --- | --- |
| `flutter analyze` | Run | "No issues found" |
| `flutter pub outdated` | Run | Dependency lag |
| `npm audit` (backend) | Run | Advisory list |
| `tool/security_scan.mjs` | Run | "No … secrets matched" |
| `aapt2`, `apksigner` (build-tools 36.0.0) | Run | Manifest, permissions, signature |
| `unzip`, `strings` | Run | APK contents, Dart snapshot constants |
| `curl`, Python | Run | Live API and storage probes |
| `git log`, `git grep`, `gh repo view` | Run | History and repository visibility |
| jadx, apktool, MobSF, bundletool, apkanalyzer, Ghidra | NOT AVAILABLE | — |
| osv-scanner, gitleaks, trufflehog (local) | NOT AVAILABLE | — |
| sslscan / testssl | NOT AVAILABLE | — |
| Emulator or device session, proxy capture, Frida | Not run | — |
| Xcode, CocoaPods, any iOS tooling | NOT AVAILABLE (Windows) | — |

## Static tests

| # | Test | Result |
| --- | --- | --- |
| S1 | Secret patterns across the app working tree, including ignored files | Only `android/key.properties` (expected, untracked) |
| S2 | Secret patterns across full history of both repositories | No live credential |
| S3 | Storage call sites in `lib/` | Prefs, one secure-storage key, two cache directories; no credential stored |
| S4 | Log statements in `lib/` | Debug-gated or non-sensitive |
| S5 | Certificate overrides, custom trust | None |
| S6 | Process execution, FFI, dynamic loading | None |
| S7 | WebView use | None in app code |
| S8 | Clipboard | One write on a disabled page; no read |
| S9 | `Random()` in security context | None |
| S10 | Cache file-name construction for traversal | Not possible in either branch |
| S11 | Archive extraction code | None exists |
| S12 | Backend raw SQL | Parameterised throughout request code |
| S13 | Admin UI `innerHTML` sinks | All escape input; report text uses `textContent` |
| S14 | Backend production config guards | Refuses to boot without S3, pooler, Redis (or explicit waiver), cron secret, explicit CORS, public base URL; refuses `DEV_ADMIN_TOKEN` |
| S15 | Migrations for RLS, grants, definer functions | Lock-down present; two later tables lack RLS (F-07) |

## Artifact tests (release APK)

| # | Test | Result |
| --- | --- | --- |
| A1 | Signature | Verifies; v2; RSA 2048; developer certificate |
| A2 | `debuggable`, `testOnly` | Absent |
| A3 | `allowBackup`, `usesCleartextTraffic` | false, false |
| A4 | Exported components | Launcher, audio service, media-button receiver, profile receiver (DUMP), and **3 test activities** (F-05) |
| A5 | Permissions | 4 declared + `ACCESS_NETWORK_STATE`, **`REORDER_TASKS`** (F-05), 1 internal |
| A6 | URLs in `libapp.so` | API root, privacy page, GitHub page, one build path |
| A7 | Secret-shaped strings in `libapp.so` | None (one Sentry format string) |
| A8 | Sentry DSN | Absent |
| A9 | Dart symbol names | Present (F-20) |
| A10 | Test code in `classes.dex` | `pl/leancode/patrol`, `androidx/test/*` present (F-05) |
| A11 | Developer path constant | Absent from binary |

## Dynamic tests against the live API

### Authentication and authorization

| # | Request | Expected | Observed | Verdict |
| --- | --- | --- | --- | --- |
| D1 | 11 admin GET routes, no token | 401 | 401 `Authentication is required.` on all | PASS |
| D2 | `/admin/system`, `Bearer abc` | 401 | 401 `The access token is invalid or expired.` | PASS |
| D3 | `/admin/system`, JWT `alg: none`, role ADMIN | reject | 403 at the Vercel edge | PASS |
| D4 | `/admin/system`, JWT HS256 forged, role ADMIN | 401 | 401 | PASS |
| D5 | `/admin/system`, `Basic` credentials | 401 | 401 `The Authorization header is invalid.` | PASS |
| D6 | `PATCH /admin/songs/:id`, no token | 401 | 401 | PASS |
| D7 | `PUT /admin/minimum-app-version`, no token | 401 | 401 | PASS |
| D8 | `/internal/maintenance`, no header | 401 | 401 `A valid scheduler credential is required.` | PASS |
| D9 | `/internal/maintenance`, `Bearer not-the-secret` | 401 from the cron controller | 401 `The access token is invalid or expired.` (global JWT middleware) | **FAIL: F-01** |
| D10 | `POST /internal/maintenance` | 405 | 405 | PASS |
| D11 | Valid token with role USER against an admin route | 403 | NOT TESTED (would require creating an account) | — |
| D12 | Expired valid token | 401 | NOT TESTED (no token available) | — |

### Input validation

| # | Input | Observed | Verdict |
| --- | --- | --- | --- |
| D13 | `songs?limit=100000`, `limit=-1` | 400, unknown key `limit` | PASS |
| D14 | `songs?page=1e9` | 400, `page × pageSize must not exceed 10000` | PASS |
| D15 | `version=../../etc/passwd` | 400 | PASS |
| D16 | `songs/%2e%2e%2f%2e%2e%2fadmin` | 400, `songId` invalid | PASS |
| D17 | `songs/…%00` | 400 at the Vercel edge | PASS |
| D18 | Song number of 20 digits | 404 | PASS |
| D19 | Duplicate and array-style query keys | 400 | PASS |
| D20 | `search?q=' OR 1=1--` | 200, zero rows | PASS |
| D21 | `search?q=%%%_\` | 200, zero rows (wildcards escaped) | PASS |
| D22 | `search` with a 3000-character `q` | 400, maximum 200 | PASS |
| D23 | `search?q=` | 400, minimum 1 | PASS |
| D24 | `search?q=%00%0d%0aSet-Cookie:x=1` | **500 `DATABASE_ERROR`**; no header injected | **F-16** |
| D25 | `sync?limit=100000` | 400, maximum 500 | PASS |
| D26 | `sync?since=notadate` | 400 | PASS |
| D27 | `sync` with a forged cursor | 400 `INVALID_SYNC_CURSOR` | PASS |
| D28 | Oversized or malformed POST bodies to `/reports`, `/analytics/events` | NOT TESTED live (avoided writes); schema review shows strict bounds and a 100 KB body limit | — |

### Exposure and enumeration

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D29 | `/.env`, `/.git/config`, `/package.json`, `/src/app.ts`, `/.vercel/project.json`, `/debug`, `/metrics`, `/docs`, `/swagger` | 404 | PASS |
| D30 | `/health`, `/api/v1/health` | 200 with environment, uptime, memory | **F-11** |
| D31 | `/api/v1/openapi.json` | 200; 14 admin paths listed; cron route absent | F-26 (INFO) |
| D32 | Legacy `/api/*` | Read-only, `Deprecation: true`; no admin or sync route | PASS |
| D33 | `/admin`, `/admin/app.js` | 200; anon key and project URL present; `no-store`; strict CSP | As designed |
| D34 | Response fields | No storage key or bucket in public responses | PASS |

### Rate limiting

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D35 | Headers on search, sync, downloads, cron | `RateLimit` draft-8 present | PASS |
| D36 | Headers on catalogue routes and health | Absent | **F-12** |
| D37 | Four requests with different `X-Forwarded-For` (and `X-Real-IP`, `Forwarded`) | Counter continued 55, 54, 53, 52 in the same bucket | PASS |
| D38 | Exhausting a limit | NOT TESTED (no load testing) | — |
| D39 | Behaviour when Redis is unavailable | NOT TESTED; code says requests are allowed | F-12 |

### CORS

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D40 | GET with `Origin: https://evil.example` | 403, no `Access-Control-Allow-Origin` | PASS |
| D41 | Preflight for POST from that origin | 403 | PASS |

### Storage and signed URLs

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D42 | Download route | 302, `private` cache, checksum and size headers | PASS |
| D43 | Signed URL parameters | SigV4, `X-Amz-Expires=900`, `SignedHeaders=host`, `GetObject` | PASS |
| D44 | Signed GET, bytes 0-15 | 206 | PASS |
| D45 | Same object without a signature | 403 `AccessDenied` | PASS |
| D46 | Altered signature | 403 | PASS |
| D47 | Same signature, different key | 403 | PASS |
| D48 | `PUT` (empty body) and `HEAD` with the GET URL | 403, 403 | PASS |
| D49 | Bucket listing, unsigned | 404 | PASS |
| D50 | Public-object path for the bucket | `Bucket not found` | PASS |
| D51 | Expired signed URL | NOT TESTED | — |

### Supabase with the public anon key

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D52 | `/rest/v1/` | 401, service-role only | PASS |
| D53 | `/rest/v1/{songs,user_profiles,reports,audit_log}` | 404 `PGRST205` (`api_disabled` schema) | PASS |
| D54 | `/graphql/v1` | 404 | PASS |
| D55 | `/storage/v1/bucket` | 200 `[]` | PASS |
| D56 | Object read by path | Not found | PASS |
| D57 | `/auth/v1/settings` | `disable_signup: false` | **F-03** |

### Version isolation

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D58 | 2004 song, audio file and sheet page requested with `version=am-sda-1975` | 404 on all three | PASS |

### Transport

| # | Test | Observed | Verdict |
| --- | --- | --- | --- |
| D59 | Plain HTTP | 308 to HTTPS | PASS |
| D60 | Security headers | HSTS, nosniff, frame options, referrer policy, CSP, COOP, CORP | PASS |
| D61 | Cookies | None set | PASS |

## Unverifiable items

| Item | Classification |
| --- | --- |
| Flutter source, Android source, release APK, both git histories | VERIFIED ON WINDOWS |
| Live API behaviour without credentials | VERIFIED ON WINDOWS |
| Any iOS runtime property | **VERIFIED ON MAC: none** |
| iOS build, signing, embedded frameworks, ATS at runtime, Keychain class and persistence, file protection, privacy manifest | REQUIRES MAC |
| Behaviour of exported Android components against a hostile app; `FLAG_SECURE`; release logcat; on-device file contents; traffic capture | REQUIRES PHYSICAL DEVICE |
| Whether the old Supabase management token is revoked; Supabase "Enforce SSL"; Supabase Auth settings beyond the public endpoint; Vercel environment values; Vercel cron run history; Upstash configuration; Play App Signing enrolment | REQUIRES PRODUCTION CONFIGURATION |
| Live RLS and grant state of each table; whether the bucket holds unpublished objects; database roles | REQUIRES BACKEND ACCESS |
| Admin routes with a valid MODERATOR or USER token (role boundary at runtime); admin write behaviour | REQUIRES BACKEND ACCESS (a test account) |
| Rate-limit exhaustion, Redis-outage behaviour, load and DoS resilience, signed-URL expiry, TLS protocol and cipher inventory | NOT TESTABLE IN CURRENT ENVIRONMENT (excluded as destructive, or no tool) |
| The `.aab` in `build/` (older than the APK) | NOT TESTABLE IN CURRENT ENVIRONMENT (`bundletool` unavailable) |
| CI's latest OSV-Scanner and TruffleHog results | Not read |
