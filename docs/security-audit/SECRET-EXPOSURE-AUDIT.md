# Secret and Credential Exposure Audit

Audit date: 2026-10-01. **No secret value appears in this document.** Where a
sensitive value was found, only its file, variable name and rough shape are
given. Nothing was rotated or revoked.

## Headline

- **In the shipped app:** no secret.
- **In either git repository, on any ref, at any point in history:** no live credential.
- **On the developer workstation, untracked:** the full set of production backend credentials in three files, one old Supabase management token, two database dumps and the Android upload keystore with its passwords (F-02, F-14).

## What the mobile binary contains

| Value | Where | Class | Reason |
| --- | --- | --- | --- |
| `https://amharichymnalbackend.vercel.app/api/v1` | `content_api_config.dart:7-8`, in `libapp.so` | PUBLIC | An address, not a credential |
| Privacy-policy and GitHub URLs | `settings_page.dart:41, 54` | PUBLIC | |
| `WUDASE_SENTRY_DSN` | `--dart-define`, absent from the inspected APK | PUBLIC / NON-SENSITIVE when present | A DSN only permits submitting events |
| `WUDASE_SENTRY_ENVIRONMENT`, `WUDASE_ANALYTICS`, `WUDASE_FRAME_STATS`, `WUDASE_FORCE_ONBOARDING`, `WUDASE_CONTENT_API_URL` | `--dart-define` | PUBLIC | Build switches |

No `.env`, dotenv package, flavour file, generated config or service-locator
constant carries a key. **The mobile client holds no privileged backend
credential and no Supabase key of any kind.** There is nothing in the app whose
protection depends on obfuscation, encoding or string splitting.

Confirmed on the release APK: see REVERSE-ENGINEERING-AUDIT.md.

## What the admin web page serves to anyone

| Value | Class | Reason |
| --- | --- | --- |
| Supabase project URL | PUBLIC | Needed by the sign-in form |
| Supabase anon key (JWT, `role: anon`) | PUBLIC by design | Verified live: reads no table, no bucket. It does allow account sign-up because sign-ups are enabled (F-03) |

## Environment variable names in use

### Application (`--dart-define`)

`WUDASE_CONTENT_API_URL`, `WUDASE_SENTRY_DSN`, `WUDASE_SENTRY_ENVIRONMENT`,
`WUDASE_ANALYTICS`, `WUDASE_FRAME_STATS`, `WUDASE_FORCE_ONBOARDING`.

### Backend (`src/config/index.ts`)

| Name | Sensitivity |
| --- | --- |
| `DATABASE_URL`, `DIRECT_DATABASE_URL` | PRIVILEGED (owner password) |
| `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY` | PRIVILEGED (all buckets, read and write) |
| `RATE_LIMIT_REDIS_TOKEN` | PRIVILEGED (limited blast radius: counters) |
| `CRON_SECRET` | PRIVILEGED (triggers retention delete) |
| `DEV_ADMIN_TOKEN` | PRIVILEGED; rejected at boot in production |
| `ADMIN_UI_SUPABASE_ANON_KEY`, `ADMIN_UI_SUPABASE_URL`, `AUTH_JWKS_URL`, `AUTH_ISSUER`, `AUTH_AUDIENCE` | PUBLIC |
| `S3_ENDPOINT`, `S3_REGION`, `STORAGE_BUCKET`, `PUBLIC_BASE_URL`, `CORS_ORIGINS`, `RATE_LIMIT_REDIS_URL` | Non-secret configuration |
| Rate-limit, TTL, logging and feature switches | Non-secret |

No Supabase **service-role** key is used by the backend or present in any file
examined. The backend reaches the database with a Postgres password and storage
with an S3 key pair.

### CI secrets referenced

App repository: none. Backend repository: `DIRECT_DATABASE_URL`, Vercel deploy
credentials, each passed through `env:` and never interpolated into a script.

## Local files holding sensitive values (names only)

| File | Tracked? | Sensitive variable names | Exposure |
| --- | --- | --- | --- |
| `amharic_hymnal_backend/.env.production` | No (ignored) | `DATABASE_URL`, `DIRECT_DATABASE_URL`, `S3_ACCESS_KEY_ID`, `S3_SECRET_ACCESS_KEY`, `RATE_LIMIT_REDIS_TOKEN`, `CRON_SECRET` | Local |
| `amharic_hymnal_backend/.vercel/.env.production.local` | No (ignored) | Same six, plus `VERCEL_OIDC_TOKEN` (short-lived) | Local |
| `D:\Church\App\backups\.env.production.before-token-removal` | Not in any repository | Same six, plus **`SUPABASE_ACCESS_TOKEN`** | Local; privileged account-level token if still valid |
| `amharic_hymnal_backend/.env` | No (ignored) | Localhost database URL, `DEV_ADMIN_TOKEN` | Development only |
| `amharic_hymnal_app/android/key.properties` | No (ignored, never committed) | `storePassword`, `keyPassword`, `keyAlias`, `storeFile` | Local; privileged |
| `D:\Church\App\keys\wudase-upload.jks` | Not in any repository | Android upload keystore | Local; privileged |
| `D:\Church\App\backups\hymnal-20260921.dump`, `hymnal-20260922-before-song-links.dump` | Not in any repository | Production data including report contact details | Local |

Why it matters: these sit unencrypted under one directory tree. A stolen laptop,
a cloud-sync client pointed at `D:\Church`, or a shared backup of that folder
would hand over the database, storage, cron endpoint and upload key together.

The file name `…before-token-removal` shows the management token was taken out
of the live env file. Nothing in the files shows it was also revoked. That was
not tested. REQUIRES PRODUCTION CONFIGURATION.

## Working-tree search (application repository)

Scope: every tracked, untracked and ignored text file except `build/`,
`.dart_tool/`, `coverage/` and binary media. Languages and formats covered:
Dart, Kotlin, Java, Swift, Objective-C, XML, YAML, JSON, plist, Gradle, shell,
PowerShell, JavaScript, Markdown, CSV, logs.

Patterns: JWT, Sentry token and DSN, Postgres URL, Supabase key formats,
`service_role`, R2/AWS key formats, private-key headers, `storePassword`,
`keyPassword`, generic `password=`, GitHub tokens, Google API keys, Stripe keys,
bearer literals.

| Location | Result |
| --- | --- |
| `lib/`, `test/`, `test_live/`, `integration_test/`, `tool/` | Clean |
| `android/` | Only `key.properties` (above). `build.gradle` reads it and has no literal. `key.properties.example` holds placeholders. `local.properties` holds SDK paths |
| `ios/`, `macos/`, `windows/`, `linux/`, `web/` | Clean. No `google-services.json`, `GoogleService-Info.plist`, `.p8`, `.p12`, `.pem` |
| `.github/` | Clean; no secret referenced |
| `docs/` | Placeholders only (`your-api-key`, `cdn.example.com` in a stale `REMOTE_ASSETS_SETUP.md`). Personal data: see F-22 |
| `.codex/`, `.codex-run-logs/`, `.artifacts/`, `.idea/`, `.vscode/` (mostly ignored) | Run logs with loopback URLs; a local Postgres log with SQL and no credentials; a warning that names a retired token variable without its value |
| Donation page | "Coming soon" text; no account number anywhere |

## Git history (application repository, PUBLIC)

201 commits across all refs, plus 79 unreachable local commits.

| Check | Result |
| --- | --- |
| Sensitive file types ever added (`.env`, keystores, `.p8`, `.p12`, `.pem`, dumps, databases) | None, apart from `backend/content/.env.example` with empty or placeholder values |
| `android/key.properties` | Never committed |
| Postgres URLs | Only `localhost` / `127.0.0.1`, mostly without a password; three placeholder passwords |
| Removed `backend/` servers (deleted 2026-09-21, still in history) | Source, migrations, `render.yaml` with `sync: false` database URLs. `backend/user_app/src/server.js` had a hard-coded fallback admin token used only outside production, for a service that no longer exists (F-22) |
| A `scrypt$…` constant | A dummy hash used to equalise timing, not a user hash |
| Real Supabase project ref, bucket, Render or Railway URL | None |
| Unreachable blobs | Scanned; no hit |

## Git history (backend repository, PRIVATE)

61 commits. Only `.env.example` was ever added. Pattern matches were limited to
documentation text mentioning `service_role`, a 27-character dummy JWT in a
test, and a placeholder connection string in an old deployment doc. No real
project ref, Redis host or token. `dist/`, `coverage/`, local logs and the
Postman environment (empty `adminToken`, `cronSecret`) are clean.

## Secrets in logs and reports

| Channel | Finding |
| --- | --- |
| App release logs | No secret exists to log; statements are debug-gated |
| Sentry | `beforeSend` clears user, request and server name; no DSN in the inspected build |
| Backend request log | Method and path without query string; no headers. Signed URLs and bearer tokens are not logged |
| Backend error log | Full error object with stack for 5xx; server-side only |
| CI logs | Secrets pass through `env:` and are masked by GitHub; the backup job prints only a file listing |

## Scanner coverage

`tool/security_scan.mjs` ran clean. Its rules would not have caught the two real
local exposures (`key.properties` passwords and the env files) because both are
git-ignored, which is by design. It also has no rule for JWTs, Supabase keys or
Sentry DSNs; TruffleHog in CI covers those.

## Findings from this area

F-02 (MEDIUM), F-14 (LOW), F-22 (INFO).
