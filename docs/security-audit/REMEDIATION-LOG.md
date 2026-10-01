# Remediation Log

Date: 2026-10-01. Follows the audit in this directory.

Nothing here has been committed, pushed, deployed or applied to production.
Backend changes are on a new local branch `security-audit-fixes` in
`amharic_hymnal_backend`; app changes are in the working tree of
`reading-experience`.

## Status of each finding

| ID | Sev | Status | What was done |
| --- | --- | --- | --- |
| F-01 | MEDIUM | Fixed in code, not deployed | The cron route is exempt from the global JWT check and compares `CRON_SECRET` itself (`src/app.ts`). New tests call it with authentication enabled. |
| F-02 | MEDIUM | **Needs you** | Nothing changed on disk. See "Only you can do". |
| F-03 | LOW | **Needs you** | Supabase dashboard setting. |
| F-04 | LOW | Fixed in code; **needs a secret** | `backup.yml` encrypts the dump with GPG (AES-256) and uploads only the encrypted file. Without `BACKUP_PASSPHRASE` the run fails and uploads nothing. |
| F-05 | LOW | Fixed | `android/app/src/release/AndroidManifest.xml` removes the three test activities, `REORDER_TASKS` and the test package queries from release builds. |
| F-06 | LOW | Fixed in code, not deployed | The maintenance job blanks the contact on resolved and dismissed reports untouched for `REPORT_CONTACT_RETENTION_DAYS` (default 180). The report text is kept. |
| F-07 | LOW | Fixed in code; **migration not applied** | Migration `20261001120000_rls_on_every_table` enables RLS on every `public` table. `test/migrations-rls.test.ts` fails if a later migration creates a table without it. |
| F-08 | LOW | Fixed in code, not deployed | In production the client adds `sslmode=require` when the URL names no `sslmode` (`src/database/prisma.ts`). |
| F-09 | LOW | Fixed | `brace-expansion` 2.1.7 and `ip-address` 10.7.2. `npm audit --omit=dev`: 0 vulnerabilities. |
| F-10 | LOW | Not done | A Flutter SDK upgrade changes the toolchain for every build and needs its own regression pass. Left as a separate change. |
| F-11 | LOW | Fixed in code, not deployed | Health returns status, service, version, timestamp and per-dependency status only. |
| F-12 | LOW | Fixed in code, not deployed | New `read` limiter (`READ_RATE_LIMIT_PER_MINUTE`, default 600) on catalogue routes in both routers. Limiters still fail open if Redis is down; that is a deliberate availability choice and was left. |
| F-13 | LOW | Fixed in code, not deployed | Sign-out calls Supabase's logout endpoint before clearing the local session. |
| F-14 | LOW | **Needs you** | Keystore handling and Play App Signing. |
| F-15 | LOW | Fixed | Backend actions pinned to commit SHAs; `backup.yml` has `permissions: contents: read`; the deploy job gives `npm ci` a placeholder database URL; apt source uses HTTPS. |
| F-16 | INFO | Fixed in code, not deployed | Search text, report message, contact and context reject a NUL character with 400. |
| F-17 | INFO | Partly fixed | Remote audio must be `http` or `https` with a host. Media hosts are not restricted to a list: the download URL and its redirect target are both chosen by the API. |
| F-18 | INFO | Fixed | A download stops once it exceeds its promised size (or 200 MB when none was given); a sync stops after 200 pages. |
| F-19 | INFO | Not done | Needs a device to see whether removing or changing the permission breaks Bluetooth or Android Auto browsing. |
| F-20 | INFO | Documented by the other session | `docs/RELEASE.md` now gives the `--split-debug-info` build command and marks `--obfuscate` optional. |
| F-21 | INFO | Fixed in code; unverified on iOS | On the first launch of an install that has not finished onboarding, the secure-storage queue is cleared. |
| F-22 | INFO | Partly fixed | Device serial replaced with `<device-serial>` in three docs. History was not rewritten. |
| F-23 | INFO | Fixed | `distributionSha256Sum` added; value fetched from `services.gradle.org`. |
| F-24 | INFO | Already fixed by the other session | `AnalyticsService` now asks `SettingsService.isDataCollectionEnabled` before sending. |
| F-25 | INFO | Not done | Supabase offers no bucket-scoped S3 key; a restricted database role is a larger change. |
| F-26 | INFO | Not done | Whether the public OpenAPI file should list admin routes is a product choice. |
| F-27 | INFO | Fixed | `web/_headers`: `connect-src` limited to the API, Supabase and Sentry; `form-action 'self'`; HSTS added. |

## Only you can do

1. **F-02** In the Supabase dashboard (Account, Access Tokens), revoke the token that was in the old env file. Then delete `D:\Church\App\backups\.env.production.before-token-removal` and move the two `.dump` files and the env files into encrypted storage.
2. **F-03** Supabase dashboard, Authentication, Sign In / Providers: turn off "Allow new users to sign up".
3. **F-04** Add the repository secret `BACKUP_PASSPHRASE` to the backend repository and keep a copy of it somewhere safe. Until it exists the nightly backup fails rather than uploading plaintext.
4. **F-07** Apply the new migration to production (`npm run db:deploy` with the direct URL). The deploy gate refuses to ship until it is applied.
5. **F-14** Confirm Play App Signing in Play Console and keep an encrypted copy of `wudase-upload.jks` off this machine.
6. Review, commit and deploy the backend branch. After the first scheduled run, check the Vercel cron log for a 200 from `/api/v1/internal/maintenance`.

## Behaviour changes to be aware of

- **Health output is smaller.** Anything reading `environment`, `uptimeSeconds`, `memory` or `responseTimeMs` from `/health` will no longer find them. The smoke test and the app do not.
- **Report contacts expire.** 180 days after a report is resolved or dismissed its contact detail is removed. Set `REPORT_CONTACT_RETENTION_DAYS` to change that.
- **One more Redis call per catalogue request**, for the new limiter.
- **The database connection now insists on TLS** in production. Supabase supports it on both the pooler and the direct port.

## Verification

### Re-check

| Check | Result |
| --- | --- |
| Backend `eslint`, `tsc --noEmit` | Clean |
| Backend unit tests | 233 passed in 18 files (224 before; 9 added for the cron route with authentication on, NUL input, the read limiter, health output, TLS, RLS in migrations, contact retention) |
| Backend `npm audit --omit=dev` | 0 vulnerabilities (3 moderate remain in dev-only `vitest`, which needs a major upgrade) |
| Backend build and OpenAPI export | Succeeded; `docs/openapi.json` regenerated |
| Backend integration tests and the new migration against PostgreSQL | **Not run**: Docker was not running. CI runs both. |
| App `flutter analyze lib test` | No issues |
| App `flutter test` (full run) | 847 passed, 1 skipped, 0 failed. An earlier run showed 11 "did not complete" in `test/core/search_full_catalogue_test.dart`; that was the machine running out of memory, and the file passes 14 of 14 on its own. |
| Release APK rebuilt to confirm F-05 | Verified with `aapt2`: no `androidx.test` activity or query and no `REORDER_TASKS`. Exported components are now the launcher activity, the audio service, the media-button receiver and the AndroidX profile receiver. Not debuggable. |
| Live API | Unchanged, because nothing was deployed. F-01, F-11, F-12 and F-16 will still reproduce against production until the branch ships. |

Still open on the verification side: the backend integration tests and the new
migration have not been run against PostgreSQL locally. CI does both on the
first push of the branch.
