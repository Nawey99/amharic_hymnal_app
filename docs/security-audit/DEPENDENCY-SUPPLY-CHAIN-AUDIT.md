# Dependency and Supply-Chain Audit

Audit date: 2026-10-01. Nothing was upgraded, downgraded or installed.

## Tooling used

| Tool | Status |
| --- | --- |
| `flutter pub outdated` | Run (read-only; `pubspec.lock` checksum unchanged before and after) |
| `npm audit`, `npm audit --omit=dev` (backend) | Run |
| `flutter analyze` | Run: no issues |
| `tool/security_scan.mjs` | Run: no findings |
| `osv-scanner`, `gitleaks`, `trufflehog` locally | NOT AVAILABLE. OSV-Scanner and TruffleHog run in the app's CI; their latest results were not read |
| CocoaPods audit | NOT TESTABLE: no `Podfile.lock` exists |

Statements about known advisories for Dart packages are from knowledge, not from
a scan.

## Flutter application

### Toolchain

Flutter 3.27.2 stable, Dart 3.6.1 (released January 2025), pinned to the same
version in `.github/workflows/test.yml` and `nightly.yml`. About 21 months old at
the audit date (F-10).

### Package sources

All 164 hosted packages in `pubspec.lock` resolve to `https://pub.dev`. No git
dependency, no path dependency, no `dependency_overrides`. `publish_to: 'none'`
prevents accidental publication. **No dependency-confusion exposure**: there is
no private package name that a public registry could shadow.

### Direct runtime dependencies

| Package | Resolved | Latest seen | Native code | Note |
| --- | --- | --- | --- | --- |
| flutter_bloc | 9.1.1 | current | No | |
| equatable | 2.1.0 | 3.0.0 | No | |
| dartz | 0.10.1 | current | No | Low activity upstream; pure Dart |
| shared_preferences | 2.5.3 | 2.5.5 | Yes | |
| flutter_secure_storage | 9.2.4 | 11.x | Yes | Two majors behind; storage back-ends were reworked in 10.x, so an upgrade needs a migration test |
| crypto | 3.0.7 | current | No | SHA-256 for downloads |
| just_audio | 0.10.6 | not listed as outdated | Yes | ExoPlayer / AVPlayer |
| audio_service | 0.18.19 | not listed as outdated | Yes | Pulls in `flutter_cache_manager` and `sqflite` |
| audio_session | 0.2.4 | not listed as outdated | Yes | |
| path_provider | 2.1.5 | 2.1.6 | Yes | |
| url_launcher | 6.3.2 | current | Yes | |
| wakelock_plus | 1.3.3 | 1.8.1 | Yes | |
| share_plus | 10.1.4 | 13.x | Yes | Three majors behind |
| http | 1.6.0 | current | No | |
| package_info_plus | 8.3.1 | 10.x | Yes | Two majors behind |
| sentry_flutter | 9.30.0 | 9.30.1 | Yes | Bundles Sentry Android SDK and NDK |
| intl | 0.19.0 | 0.20.3 | No | Held by the SDK |
| get_it, path, characters, json_annotation, cupertino_icons | — | minor updates | No | |

Discontinued upstream: `js` 0.6.7 (transitive), `flutter_secure_storage_macos`
(transitive), and dev-only `build_resolvers`, `build_runner_core`.

### Unnecessary or surprising dependencies

| Item | Finding |
| --- | --- |
| `sqflite` (+ `sqflite_android`, `sqflite_darwin`) | Not used by `lib/`. Arrives through `audio_service` → `flutter_cache_manager`, which would cache remote notification artwork. The app passes a local file URI, so the database is dormant. |
| `dartz` | Used for `Either`; fine, but a second functional-types package alongside plain Dart records |
| `patrol`, `integration_test` | Dev dependencies whose native plugins are nevertheless linked into the release build (F-05) |
| `jni` | Transitive via `sentry_flutter`; ships `libdartjni.so` |
| Sentry native SDK | Linked into every build, active only with a DSN |

### Known-vulnerability status

No published advisory is known to me for any resolved Dart package version
above. The realistic exposure is the engine: Flutter 3.27.2's bundled Skia,
image decoders and BoringSSL have received no fixes since the release. The app
decodes WebP, PNG and JPEG it downloads; those bytes are SHA-256-checked against
the API's value first, which limits who can feed the decoder to someone who
controls the API.

### Android build chain

| Item | Value | Assessment |
| --- | --- | --- |
| Repositories | `google()`, `mavenCentral()`, `gradlePluginPortal()` (plugins only) | No JitPack, custom URL, `mavenLocal` or `flatDir` |
| Android Gradle Plugin | 8.9.1 | |
| Kotlin | 2.2.0 | |
| Gradle | 8.11.1 from `services.gradle.org` over HTTPS, `validateDistributionUrl=true` | No `distributionSha256Sum` (F-23) |
| `gradle-wrapper.jar`, `gradlew` | Git-ignored; CI uses what Flutter generates | The local jar was not compared with Gradle's published checksum |
| NDK | 27.0.12077973 | |
| Explicit dependency | `androidTestUtil androidx.test:orchestrator:1.5.1` | Test only |
| `android.enableJetifier=true` | Probably unneeded | Informational |
| `android/build.gradle:7` | A stray literal line `2` | Harmless Groovy expression; looks like an editing accident |
| `.github/modernize/java-upgrade/` | Git-ignored IDE-assistant hook scripts that append tool-call records to a local file; no network use | Local residue |

### iOS and macOS

No `Podfile` or `Podfile.lock` in `ios/` or `macos/`. CocoaPods versions are
unpinned and cannot be audited until a first `pod install` on a Mac.
REQUIRES MAC.

### Application CI (`.github/workflows/test.yml`, `nightly.yml`)

| Control | Status |
| --- | --- |
| Top-level `permissions: contents: read` | Yes |
| Actions pinned to commit SHA | Yes, all of them; TruffleHog image pinned by digest |
| `pull_request_target` | Not used; plain `pull_request` |
| Secrets referenced | None. No signing material in CI; the release bundle CI builds is unsigned |
| Secret scanning | `tool/security_scan.mjs` and TruffleHog over full history |
| Dependency scanning | `google/osv-scanner-action` v2.6.0, `fail-on-vuln: true` |
| Dependabot | Weekly for `github-actions` and `pub` |
| Artifacts | `coverage/lcov.info` only, 14 days |
| Provenance / attestation | None; releases are built and signed locally, not in CI |
| Mutable inputs | `flutter-version: 3.27.2` pinned; `subosito/flutter-action` SHA-pinned; `flutter pub get` honours `pubspec.lock` |

`tool/security_scan.mjs` has five content rules (PEM keys, Google, AWS, GitHub,
Stripe) plus a Postgres-URL rule and file-name rules. It would miss JWTs,
Supabase keys, Sentry DSNs and `storePassword=` lines. TruffleHog covers most of
that gap.

Release builds are produced on the developer workstation. The integrity of a
release therefore depends on that machine, which also holds the keystore and its
passwords (F-14).

## Backend

### Runtime and sources

Node 22 (`.nvmrc` and `engines` agree; CI reads `.nvmrc`). 562 packages in
`package-lock.json`, every one resolved from `https://registry.npmjs.org/`.
`postinstall` runs `prisma generate` only.

Main runtime packages: express 5.2.1, helmet 8.3.0, cors 2.8.6, jose 6.2.12,
zod 3.25.76, pino 9.14.0, express-rate-limit 8.6.0, Prisma, AWS SDK v3 S3
client and presigner. None is unmaintained.

### `npm audit` (F-09)

| Package | Severity | Path | Reachable from a request? |
| --- | --- | --- | --- |
| `brace-expansion` 2.1.4 | high (DoS) | `archiver` → `glob` → `minimatch` | No: `archiver` is used only by the operator CLI `scripts/import-media.ts` |
| `ip-address` 10.5.0 | moderate | `express-rate-limit` | Used for IPv6 key handling; the advisories concern address classification. Assessed as not affecting limiter keys; not tested |
| `vitest` and related | moderate | dev only | No |

Totals: all dependencies 0 critical, 1 high, 4 moderate; production tree 1 high,
1 moderate. `ci.yml:52` runs `npm audit --omit=dev` as a gate, so `verify` and
`deploy` currently fail.

### Backend CI (F-15)

| Control | Status |
| --- | --- |
| `permissions` | `ci.yml`: `contents: read`. `backup.yml`: none declared |
| Action pinning | By tag (`@v4`), not SHA |
| `pull_request_target` | Not used |
| Secret interpolation into `run:` | None; secrets pass through `env:` |
| Deploy gating | Push to `main`, a repository variable, and the `production` environment; serialised |
| Vercel CLI | Pinned to 59.23.2 |
| Migrations | CI checks `migrate status`; it never runs `migrate deploy` |
| Production database URL in the environment of `npm ci` | Yes (`ci.yml:110-128`) |
| Backup artifact | Unencrypted dump, 30 days (F-04) |
| `backup.yml:50` | Adds the PostgreSQL apt source over `http://`; packages are signature-verified with a key fetched over HTTPS |
| Vercel git auto-deploy | Disabled for `main` in `vercel.json` |
| `.vercelignore` | Excludes `.env*`, `.vercel/`, `.local/`, `media/`, `docs/`, `scripts/`, `test/` |

## Third-party services

| Service | Credential | Held by | Data sent | If it fails or is compromised |
| --- | --- | --- | --- | --- |
| Vercel | Deploy token (GitHub secret); environment variables | CI, Vercel | All API traffic | API down; app falls back to stored or bundled content. Compromise exposes every backend secret |
| Supabase PostgreSQL | Owner password | Vercel env, local env files, CI secret | Catalogue, reports, analytics | API errors; app serves stored content |
| Supabase Storage | S3 access key pair | Vercel env, local env files | Media | Downloads fail; cached media still plays |
| Supabase Auth | Anon key (public); JWKS (public) | Admin page | Operator email and password go from the browser straight to Supabase | Admin console unusable; public API unaffected |
| Upstash Redis | REST token | Vercel env, local env files | Hashed client keys and counters | Limits fail open (F-12) |
| Sentry | DSN (public-ish, build-time) | Beta builds only | Error, stack trace, device model; user, request and server name scrubbed (`crash_reporting.dart:59-64`); screenshots and view hierarchy off; `sendDefaultPii=false` | No effect on the app |
| GitHub | Repository secrets | GitHub | Source, CI artifacts including DB dumps | See F-04, F-15 |
| GitHub Pages | None | — | Privacy policy page | Link fails |
| pub.dev, npm, Maven Central, Google Maven, Gradle | None | — | Build-time downloads | Build fails; lockfiles pin versions |

Sentry events can still contain exception messages. `MediaIntegrityException`
includes the API download URL (not the signed storage URL), and
`HymnalApiException` includes the server's error message. Neither carries
personal data.

## Findings from this area

F-09, F-10, F-15 (LOW); F-23 (INFO). F-05 is caused by dependency packaging and
is listed under Android.
