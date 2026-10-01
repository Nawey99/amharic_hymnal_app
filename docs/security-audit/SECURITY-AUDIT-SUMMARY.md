# Security Audit Summary

Audit date: 2026-10-01. Read-only: no source, configuration, dependency,
credential or production data was changed. The only files created are the
fifteen documents in this directory.

## Conclusion

The application and its backend have **no critical or high-severity weakness
and no security release blocker**. The app holds no secret, the admin API
rejects every unauthenticated and forged request tried, the database is not
reachable with the public key, and media needs a signed URL.

Two medium findings should be dealt with around release:

1. **F-01**: the scheduled job that deletes analytics after 90 days cannot authenticate, so the retention the privacy policy promises is not being enforced by the scheduler.
2. **F-02**: production credentials, an old Supabase management token and two database dumps sit in plaintext on the development workstation.

iOS was not tested at all. This audit gives no assurance about the iOS build.

| Severity | Count |
| --- | --- |
| CRITICAL | 0 |
| HIGH | 0 |
| MEDIUM | 2 |
| LOW | 13 |
| INFO | 12 |

Confirmed 22, likely 3, possible 2. Release blockers: 0.

## Scope

| In scope | Revision or location |
| --- | --- |
| Flutter app | `D:\Church\App\amharic_hymnal_app`, branch `reading-experience`, commit `b4d78a0` |
| Backend | `D:\Church\App\amharic_hymnal_backend`, commit `ab3ed4f` |
| Release artifact | `app-release.apk` built 2026-09-29 |
| Live API | `https://amharichymnalbackend.vercel.app` |
| Supabase (database, storage, auth) | As reachable with the public anon key and through signed URLs |
| CI | `.github/workflows` in both repositories |
| Workstation files | Names only, for `keys\`, `backups\`, env files |

Not in scope or not reachable: Vercel, Supabase, Upstash, Play Console and Apple
dashboards; any iOS build; a device or emulator session.

## Architecture

```text
Flutter app --HTTPS, no credentials--> Hymnal API (Vercel, Express)
                                          |-- PostgreSQL (Supabase)
                                          |-- private media bucket (Supabase Storage, S3 API)
                                          |-- rate-limit counters (Upstash Redis)
App <-- 302 --> 15-minute signed URL --> Supabase Storage
Operator browser --> /admin --> Supabase Auth --> /api/v1/admin/*
```

Media is in **Supabase Storage**, not Cloudflare R2 as the brief assumed.
Cloudflare is only Supabase's CDN.

## Trust boundaries

Device to API; device to storage; other apps to this app; operator browser to
API; API to its data stores; scheduler to API; CI to production; and the
developer workstation. Detail in THREAT-MODEL.md.

## Threat model in brief

The content is public, the app has no accounts, and nothing is sold or
restricted. So the things worth protecting are: the integrity of the catalogue
(only operators may change it), the few personal details users type into bug
reports, the backend's credentials, and service availability and cost. A user
who decompiles, patches or roots gains nothing over an ordinary user.

## Attack surface

- **App:** launcher activity, media service and receiver. No deep link, URL scheme, WebView or inbound share.
- **API:** 21 anonymous read routes, 2 anonymous write routes (reports, analytics), health, OpenAPI, a legacy read-only mirror, 24 admin route patterns, 1 cron route.
- **Storage:** signed GET only.
- **Operations:** two GitHub repositories, one workstation.

## Controls already in place

- No credential of any kind in the app; verified in the release binary.
- HTTPS only: cleartext disabled in the release manifest, release build refuses a non-HTTPS API URL, server sends HSTS.
- No certificate override; user CAs not trusted.
- Admin API: JWKS-verified JWT with pinned issuer, audience and algorithms; role from server-controlled metadata; three gates on every route; audit log on writes.
- Database: Data API pointed at an empty schema, grants revoked, RLS enabled on the original tables.
- Storage: private bucket, object-scoped 15-minute signed GET, verified resistant to tampering.
- Input validation: strict schemas, bounded lengths and pagination, parameterised SQL, escaped LIKE wildcards.
- Rate limits on search, sync, downloads, reports, analytics and admin writes, with a shared store and no header spoofing.
- Download integrity: size and SHA-256 checked before a file is accepted; atomic writes; traversal-proof file names.
- Bug-report queue in OS-backed secure storage; Android backups off.
- Production boot guards that refuse unsafe configuration, including a static admin token.
- Security headers and strict CSP; CSRF not applicable (no cookies).
- App CI: SHA-pinned actions, read-only permissions, secret scanning over full history, OSV scanning, Dependabot.
- Release build: R8, not debuggable, properly signed.

## Findings by severity

### Critical

None.

### High

None.

### Medium

| ID | Title |
| --- | --- |
| F-01 | Scheduled maintenance is rejected by the global JWT check, so analytics retention never runs |
| F-02 | Production credentials, a Supabase management token and database dumps in plaintext on the workstation |

### Low

| ID | Title |
| --- | --- |
| F-03 | Public sign-up enabled on the Supabase project that issues admin tokens |
| F-04 | Daily production database dumps uploaded as unencrypted GitHub artifacts |
| F-05 | Test instrumentation ships in the release APK (3 exported activities, 1 permission) |
| F-06 | Bug reports with contact details are kept forever |
| F-07 | Two tables created after the lock-down have no RLS |
| F-08 | Production database URL has no `sslmode` |
| F-09 | Backend `npm audit` fails; CI gate is red |
| F-10 | Flutter 3.27.2 and several plugins are well behind |
| F-11 | Health endpoint discloses runtime detail |
| F-12 | Catalogue routes have no limiter; limiters fail open |
| F-13 | Admin tokens in web storage; sign-out does not revoke |
| F-14 | Upload-keystore passwords in plaintext beside the keystore |
| F-15 | Backend CI: actions pinned by tag; production database URL present during `npm ci` |

### Informational

F-16 NUL byte in search returns 500. F-17 client accepts any media host and any
audio scheme. F-18 no size or page ceiling on the client. F-19 audio service
guarded by an undefined permission name. F-20 Dart not obfuscated. F-21 iOS
unbuilt; Keychain persistence. F-22 disclosures in the public repository. F-23
Gradle wrapper without checksum. F-24 unused opt-out flag. F-25 broad runtime
credentials. F-26 public OpenAPI lists admin routes. F-27 web CSP.

## Release blockers

None. Three findings carry a condition that would make them blockers; see
SECURITY-RELEASE-BLOCKERS.md.

## Status by area

| Area | Status |
| --- | --- |
| **Android** | Sound. Correct flags, minimal permissions, no deep links, no WebView, signed release. One clean-up: test scaffolding in the release APK (F-05). Device-level behaviour not tested. |
| **iOS** | **Unassessed.** Source shows no ATS exception, no URL scheme and no risky native code, but the project has never been built here: no Podfile, no team, no entitlements, no privacy manifest. REQUIRES MAC. |
| **Backend** | Well defended. Authentication, authorization, validation and error handling held under test. Weak points are operational: the broken cron (F-01), open sign-up (F-03), unlimited read routes (F-12), over-detailed health (F-11). |
| **Storage and media** | Sound. Private bucket and short signed URLs match the product's needs. No archive handling exists. |
| **Database** | Not reachable from outside the API. Two later tables miss RLS (F-07); TLS not required in the connection string (F-08); reports never expire (F-06). |
| **Local device storage** | Sound. No credential stored; the one personal item is in secure storage. |
| **Network / TLS** | Sound. Pinning assessed as not applicable. |
| **Reverse engineering** | Nothing sensitive recoverable. |
| **Dependencies** | No known exploitable issue. Flutter SDK is old (F-10); backend audit gate is red (F-09). |
| **Secrets** | Clean in the app and in both histories. Local plaintext is the issue (F-02, F-14). |

## Areas not testable

See the table at the end of SECURITY-TEST-RESULTS.md. In short: everything iOS
(REQUIRES MAC); on-device Android behaviour (REQUIRES PHYSICAL DEVICE);
dashboard settings and whether the old token is revoked (REQUIRES PRODUCTION
CONFIGURATION); live RLS state and role-boundary tests with a real token
(REQUIRES BACKEND ACCESS); load, limit exhaustion and URL expiry (NOT TESTABLE
IN CURRENT ENVIRONMENT).

## Answers to the two central questions

**What security decisions are incorrectly trusted to the mobile client?** None.
The client decides only cosmetic things (update prompt, screenshot block,
contribution link). Every decision that matters is made on the server.

**What can someone do by calling the API directly, without the app?** Exactly
what the app can: read the public catalogue, obtain short-lived download URLs,
and post reports and view counts within rate limits. They cannot reach any
administrative function, the database or the bucket.

## Recommended remediation sequence

### Immediate security release blockers

None.

### Next remediation (before or with the first public release)

1. **F-01** Make the cron route reachable with its secret and confirm a successful run, so retention matches the privacy policy.
2. **F-02** Revoke the old Supabase management token; remove the backup env file; move dumps and env files to encrypted storage.
3. **F-03** Disable public sign-up on the Supabase project.
4. **F-05** Keep test plugins out of the release build and re-check the merged manifest.
5. **F-14** Confirm Play App Signing enrolment and make an encrypted offline copy of the upload keystore.
6. **F-04** Encrypt database dumps before they become CI artifacts.
7. **F-09** Clear the two production advisories so the CI gate, and the deploy path it protects, works again.

### Hardening

8. **F-06** Retention for resolved reports.
9. **F-07** Enable RLS on the two later tables; add a CI check for future tables.
10. **F-08** Require TLS in the database URL.
11. **F-12**, **F-11** General limiter on read routes; trim anonymous health output.
12. **F-13** Revoke the Supabase session on sign-out.
13. **F-15**, **F-23** Pin backend actions by SHA; placeholder database URL for `npm ci`; Gradle wrapper checksum.
14. **F-10** Plan the Flutter and plugin upgrade as a separate, tested change.
15. **F-16**, **F-18** Reject control characters in search; add client ceilings.

### Optional / threat-model dependent

16. **F-20** Dart obfuscation with split debug info.
17. **F-17** Restrict media URLs to HTTPS and known hosts.
18. **F-19** Confirm the audio-service permission on a device.
19. **F-24** Wire or remove the data-collection flag.
20. **F-25** Narrower database role and storage key, if Supabase offers them.
21. **F-22**, **F-26**, **F-27** Tidy public-repository details; decide whether the OpenAPI file should list admin routes; tighten web headers if the web build ships.
22. Certificate pinning, root detection, anti-debugging and tamper detection: **not recommended** for this application.

### Before any iOS release

Run the nine checks listed in IOS-SECURITY-AUDIT.md on a Mac.

## Document index

| File | Contents |
| --- | --- |
| SECURITY-FINDINGS.md | Master table and full detail for all 27 findings |
| SECURITY-RELEASE-BLOCKERS.md | Blocker assessment |
| THREAT-MODEL.md | System, boundaries, assets, actors |
| MASVS-CONTROL-MATRIX.md | Control-by-control results |
| SECRET-EXPOSURE-AUDIT.md | Secrets in binary, tree, history and local files |
| API-AUTHORIZATION-AUDIT.md | Authentication, authorization, route inventory, CORS, limits |
| STORAGE-DATABASE-AUDIT.md | Device storage and database |
| NETWORK-TLS-AUDIT.md | Transport, caching, pinning decision |
| ANDROID-SECURITY-AUDIT.md | Manifest, components, permissions, signing |
| IOS-SECURITY-AUDIT.md | Source-only review and Mac checklist |
| MEDIA-DOWNLOAD-SECURITY-AUDIT.md | Storage, signed URLs, download pipeline |
| REVERSE-ENGINEERING-AUDIT.md | What the APK reveals |
| DEPENDENCY-SUPPLY-CHAIN-AUDIT.md | Packages, build chain, CI, third parties |
| SECURITY-TEST-RESULTS.md | Every test run, and what could not be tested |
