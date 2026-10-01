# Network and TLS Audit

Audit date: 2026-10-01.

## Endpoints the app contacts

| Host | Purpose | Scheme | Credentials sent | Source |
| --- | --- | --- | --- | --- |
| `amharichymnalbackend.vercel.app` | Catalogue, sync, reports, analytics, update check, download redirects | HTTPS | None | `content_api_config.dart:7-8` |
| `<project>.supabase.co` | Media bytes, reached only by following a 302 | HTTPS | Signature in the URL query, issued per request | Server-side |
| `nawey99.github.io`, `github.com` | Privacy policy and project page, opened in the external browser | HTTPS | None | `settings_page.dart:41, 54` |
| Sentry ingest | Crash reports, only if the build passes `WUDASE_SENTRY_DSN` | HTTPS | DSN | `crash_reporting.dart` |

The inspected release APK contains exactly three application URLs (the API root
and the two web pages) and no Sentry DSN, so that build sends nothing to Sentry.

## Transport configuration

| Control | Android | iOS | Evidence |
| --- | --- | --- | --- |
| Cleartext blocked in release | Yes | Yes (ATS default) | `android:usesCleartextTraffic="false"` in source and in the built APK; `Info.plist` has no `NSAppTransportSecurity` key |
| Debug-only cleartext | Yes, debug and profile manifests only | n/a | `src/debug/AndroidManifest.xml`, `src/profile/AndroidManifest.xml` set `usesCleartextTraffic="true"` with `tools:replace` |
| Network security config | None declared; platform defaults (system CAs only on API 24+) | n/a | No `res/xml`, no `networkSecurityConfig` attribute in the built manifest |
| User-installed CAs trusted | No (default since API 24; minSdk is 24) | No | — |
| Custom certificate handling | None | None | grep for `badCertificateCallback`, `HttpOverrides`, `SecurityContext` in `lib/`: no match |
| Custom native HTTP code | None | None | `MainActivity.kt` and `AppDelegate.swift` contain only the screen-capture channel |
| HTTPS enforced in config | Release build throws if `WUDASE_CONTENT_API_URL` is not HTTPS | same | `content_api_config.dart:25-28` |
| Proxy behaviour | `dart:io` default: does not use the system proxy unless configured; no proxy code in the app | same | — |

iOS rows are from source inspection only. **VERIFIED ON WINDOWS** (source);
runtime ATS behaviour **REQUIRES MAC**.

### Profile build caveat

`app-profile.apk` and `app-debug.apk` in `build/` allow cleartext. They must not
be distributed. The release APK was checked separately and does not.

## Server side (live)

| Check | Result |
| --- | --- |
| HTTP to HTTPS | `http://…/api/v1/health` returns 308 to HTTPS |
| HSTS | `max-age=31536000; includeSubDomains` |
| Certificate | Validated by curl with the system store (`ssl_verify_result=0`) |
| TLS protocol versions and cipher list | NOT TESTED (no `sslscan`/`testssl` available; Vercel and Supabase terminate TLS) |
| Server disclosure | `Server: Vercel`; no `X-Powered-By` |
| Cookies | None set by any response |

## Redirect handling

`package:http` follows redirects (default, up to five). The download route
returns `302` with `Cache-Control: private, max-age=0, must-revalidate`. The app
does not record the target. A redirect to plain HTTP would be refused on Android
release and by ATS.

## Traffic content

Derived from the request builders in `lib/` and from live responses. A proxy
capture on a device was not performed: NOT TESTABLE IN CURRENT ENVIRONMENT (no
emulator session was run and user-installed CAs are not trusted by a release
build).

| Item | Finding |
| --- | --- |
| Authorization headers | None sent by the app |
| Cookies | None |
| Custom headers | `If-None-Match` on metadata routes; `content-type` on POST |
| Credentials in URLs | None from the app. The storage redirect carries a signature in the query, which is how presigned URLs work; lifetime 15 minutes |
| Query parameters | `language`, `version`, `since`, `limit`, `cursor`; hymn id in the path |
| Identifiers | No device, install or advertising identifier. The only stable identifier the server sees is the IP address, which it uses for rate limiting and does not store with reports or events |
| Report body | What the user typed, app version, platform, screen, locale |
| Analytics body | Event type, hymn id or category slug, open source |
| Response data | Public catalogue; UUIDs for edition, book and category; `createdAt`/`updatedAt`; no storage key or bucket name |
| Error bodies | Stable code and short message |

## HTTP caching and information leakage

| Response | Cache-Control | Assessment |
| --- | --- | --- |
| Catalogue routes | `public, max-age=60` (song detail 300) | Public data; correct |
| Search | `public, max-age=30`; served from the Vercel edge on repeat | Public data |
| Sync | `private, no-store` | Correct |
| Download redirect | `private, max-age=0, must-revalidate` | Signed URL not shared-cached |
| Admin page and script | `no-store` | Correct |
| Errors | `public, max-age=0, must-revalidate` | Harmless |
| Health | `no-store` | Content is over-detailed (F-11) |

No authenticated response is cacheable by a shared cache. The app keeps ETag
responses in memory only (`HymnalApiClient._byEtag`).

The client honours `429`/`503` back-off from `RateLimit` or `Retry-After`,
capped at five minutes (`hymnal_api_client.dart:14-16, 61-73`), so a hostile
header cannot lock the app out for long.

## Certificate pinning

**Status: NOT IMPLEMENTED. Classification: NOT APPLICABLE / LIMITED VALUE.**

| Question | Answer |
| --- | --- |
| Does the app carry authenticated or secret communication? | No. It sends no token and receives public content. |
| What would an attacker with a rogue CA gain? | They could alter hymn text or media shown to one user, or read that user's bug report in transit. Installing a CA requires control of the device, and release builds on Android 7+ ignore user CAs anyway. |
| Does the architecture rely on pinning? | No. |
| Operational risk of adding it | High. The API is on `*.vercel.app` and media on `*.supabase.co`; neither certificate chain is under the project's control. A rotation would break every installed app until a store update, and the app's only remote kill-switch (`minimumAppVersion`) is delivered over the same connection. |

Pinning is not recommended for this application. Revisit only if the app gains
accounts or payments.

## Findings from this area

F-08 (server to database), F-17 (INFO). No finding of LOW or above concerns the
app's transport security.
