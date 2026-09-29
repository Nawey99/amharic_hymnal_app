# Security and Deployment

Last updated: 2026-09-21

The app has one backend: the hymnal API (`amharic_hymnal_backend`, deployed at
`https://amharichymnalbackend.vercel.app/api/v1`). Its own repository documents
its security, deployment and admin console. The old in-repo servers
(`backend/content` and `backend/user_app`, with their Render and Railway
files) were removed on 2026-09-21; nothing in the app called them any more.

## Trust boundaries

```text
Flutter / Flutter web
  |-- hymns, media, sync ----> Hymnal API (/api/v1) --> PostgreSQL, storage
  |-- bug reports -----------> Hymnal API (/api/v1/reports)

Administrators
  |-- Supabase sign-in ------> Hymnal API admin console (/admin)
```

The app never connects to PostgreSQL or to storage with credentials. Media
downloads follow short-lived signed URLs the API issues, and every file is
checked against its SHA-256 before use.

## What the app holds

Safe to build into the app:

- `WUDASE_CONTENT_API_URL` (optional; defaults to the production API)

Never commit or place in the app:

- database URLs or passwords, storage keys, Supabase service keys
- Android `.jks` files or `android/key.properties`
- Apple `.p8`, certificates, or provisioning profiles

## Controls in the app

| Area | Implementation |
| --- | --- |
| HTTPS | Release builds reject a non-HTTPS API URL. Android release forbids cleartext traffic. |
| Offline reports | Queued in OS-backed secure storage (not on web) and retried at startup. |
| Report contents | Only what the user typed (title, description, optional contact) plus app version, platform and language. Nothing is read from the device account. |
| Sheet music | Android `FLAG_SECURE` while visible. |
| Media integrity | Every download is checked against the API's SHA-256 and size. |
| Update gate | The app reads `release.minimumAppVersion` from `/manifest` and asks older builds to update. |
| Secret scanning | `tool/security_scan.mjs` and TruffleHog scan tracked files and full history in CI. |

## Local development

```powershell
flutter pub get
flutter run -d windows
```

To use a local copy of the hymnal API, add
`--dart-define=WUDASE_CONTENT_API_URL=http://127.0.0.1:8787/api/v1`. Use
`10.0.2.2` instead of `127.0.0.1` for an Android emulator. Flutter web must be
served from an origin listed in the API's `CORS_ORIGINS`.

## Beta build with crash reporting

Crash reports go to Sentry only when the build supplies a DSN. Public
Play Store / App Store builds are built without the DSN and send nothing.
See `lib/core/services/crash_reporting.dart` for the exact fields that
are reported and the PII scrub.

### One-time Sentry setup

1. Sign in at [sentry.io](https://sentry.io/) and create (or join) an
   organisation.
2. **New project** → platform **Flutter** → project name **wudase-beta**.
3. Open **Settings → Projects → wudase-beta → Client Keys (DSN)** and
   copy the DSN. It looks like
   `https://<32-char-key>@o<orgid>.ingest.us.sentry.io/<projid>`.
4. Set **Retention → 90 days** on the project to match the privacy policy.
5. Keep the DSN out of the repository. Store it in a shell env var
   (`WUDASE_SENTRY_DSN`) or in a local `.env` file that is git-ignored.

### Beta build commands

Android app bundle:

```powershell
flutter build appbundle --release `
  --dart-define=WUDASE_SENTRY_DSN=$env:WUDASE_SENTRY_DSN `
  --dart-define=WUDASE_SENTRY_ENVIRONMENT=beta
```

iOS IPA (run on macOS):

```powershell
flutter build ipa --release `
  --dart-define=WUDASE_SENTRY_DSN=$env:WUDASE_SENTRY_DSN `
  --dart-define=WUDASE_SENTRY_ENVIRONMENT=beta
```

Leaving `WUDASE_SENTRY_DSN` unset disables reporting entirely — this is
how public store releases are built. `WUDASE_SENTRY_ENVIRONMENT`
defaults to `beta` when the DSN is set.

### Verifying the wiring

- After installing a beta build, open Settings → **Report bug** and
  submit a "smoke" report. That path does not use Sentry, but confirms
  the app is running the beta build.
- To force a real crash-report path, wrap an intentional throw in
  `CrashReporting.recordError(Exception('sentry-smoke'), StackTrace.current)`
  from a temporary tap handler, then check the Sentry project's Issues
  page. Remove the temporary code before releasing.
- Reports never include: user identity, IP address, screenshots, or the
  Flutter widget tree. `CrashReporting.scrub` clears the last three
  before the event leaves the device.

## Store release

Before a public release: the final application ID, Android and iOS signing,
a privacy policy URL, and the current Play Store target API level. Public
Android distribution needs a one-time Google fee; the App Store needs an
annual Apple membership unless the organization qualifies for a waiver.
