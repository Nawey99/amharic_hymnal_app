# MASVS Control Matrix

Audit date: 2026-10-01. Framework: OWASP MASVS v2 control areas, verified with
MASTG-style source review, artifact inspection and live API probes.

Result values: PASS, FAIL, PARTIAL, NOT APPLICABLE, NOT TESTABLE. A PASS always
cites evidence. iOS rows based on source only are marked PARTIAL or NOT TESTABLE
rather than PASS. MASTG test identifiers are given where the mapping is natural;
they were assigned from memory and should be checked against the current
catalogue.

Summary:

| Area | PASS | PARTIAL | FAIL | N/A | NOT TESTABLE |
| --- | --- | --- | --- | --- | --- |
| STORAGE | 4 | 1 | 0 | 0 | 1 |
| CRYPTO | 2 | 0 | 0 | 2 | 0 |
| AUTH | 2 | 1 | 0 | 2 | 0 |
| NETWORK | 3 | 1 | 0 | 1 | 1 |
| PLATFORM | 5 | 2 | 0 | 0 | 1 |
| CODE | 3 | 3 | 0 | 0 | 0 |
| RESILIENCE | 2 | 1 | 0 | 2 | 0 |
| PRIVACY | 2 | 1 | 1 | 0 | 0 |

## MASVS-STORAGE

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| STORAGE-1 | Sensitive data is stored securely | Only personal data at rest is the unsent report queue, in EncryptedSharedPreferences / Keychain | Read every storage call site (MASTG-TEST-0001) | PASS | — | CONFIRMED | `bug_report_queue_service.dart:33-35` | — |
| STORAGE-1 | No credential or token stored on device | The app has none | grep for token, key and auth storage | PASS | — | CONFIRMED | `lib/` | — |
| STORAGE-2 | No sensitive data in logs | All `debugPrint` debug-gated or non-sensitive | Read each log call (MASTG-TEST-0003) | PASS | — | CONFIRMED | `lib/` | — |
| STORAGE-2 | No sensitive data in backups (Android) | `allowBackup=false` in built APK | `aapt2 dump xmltree` (MASTG-TEST-0009) | PASS | — | CONFIRMED | `AndroidManifest.xml:16-17` | — |
| STORAGE-2 | No sensitive data left after uninstall (iOS) | Keychain queue would persist | Source only | PARTIAL | INFO | POSSIBLE | F-21 | Clear the queue on first launch after install |
| STORAGE-2 | On-device contents as actually written | — | No device | NOT TESTABLE | — | — | — | REQUIRES PHYSICAL DEVICE |

## MASVS-CRYPTO

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CRYPTO-1 | Strong, standard cryptography | SHA-256 from `package:crypto` for download integrity; platform keystore for the queue. No custom algorithm | Source review | PASS | — | CONFIRMED | `local_media_cache_service.dart:189-218` | — |
| CRYPTO-1 | Hashing not misused as encryption or authentication | SHA-256 used for integrity and as a cache key only. The FNV hash in `_stableHash` is a file-name disambiguator, not a security function | Source review | PASS | — | CONFIRMED | `:299-306` | — |
| CRYPTO-2 | Key management | The app generates and stores no key; the OS manages the storage key | — | NOT APPLICABLE | — | — | — | — |
| CRYPTO-2 | Secure randomness | No `Random()` in `lib/`; no token is generated on the device. Temp-file suffixes and report ids are timestamps and need no secrecy | grep | NOT APPLICABLE | — | — | — | — |

Server side: JWT verification with `jose` (ES256/RS256, JWKS); cron secret
compared with `timingSafeEqual`; SigV4 presigning by the AWS SDK. No home-made
cryptography, static IV, hard-coded key or obsolete algorithm was found in
either codebase. Encryption of the public content at rest would add nothing and
is not recommended.

## MASVS-AUTH

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AUTH-1 | App authentication follows best practice | The app has no accounts or login | — | NOT APPLICABLE | — | — | — | — |
| AUTH-2 | Local authentication | None used | — | NOT APPLICABLE | — | — | — | — |
| AUTH-1 (backend) | Privileged API requires valid authentication | 11 admin routes return 401 without a token; forged and unsigned JWTs rejected | Live probes | PASS | — | CONFIRMED | `router.ts:240-507` | — |
| AUTH-1 (backend) | Authorization enforced server-side | Three gates on every admin route; role from `app_metadata` | Source review | PASS | — | CONFIRMED | `auth.ts`, `supabase-jwt-auth-service.ts` | — |
| AUTH-1 (backend) | Identity provider restricted to intended users | Public sign-up enabled; session not revoked on sign-out | `/auth/v1/settings`; source | PARTIAL | LOW | CONFIRMED | F-03, F-13 | Disable sign-ups; revoke on sign-out |

## MASVS-NETWORK

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| NETWORK-1 | All traffic encrypted (Android) | `usesCleartextTraffic=false` in release APK; HTTPS asserted in release config | `aapt2`; source (MASTG-TEST-0019) | PASS | — | CONFIRMED | `AndroidManifest.xml:18`, `content_api_config.dart:25` | — |
| NETWORK-1 | Certificate validation intact | No override; no network security config; user CAs not trusted at minSdk 24 | grep; manifest (MASTG-TEST-0021) | PASS | — | CONFIRMED | `lib/` | — |
| NETWORK-1 | Server enforces HTTPS | 308 redirect; HSTS one year | Live | PASS | — | CONFIRMED | — | — |
| NETWORK-1 | All traffic encrypted (iOS) | No ATS exception in `Info.plist` | Source only | PARTIAL | — | LIKELY | `Info.plist` | REQUIRES MAC |
| NETWORK-2 | Identity pinning | Not implemented | Threat-model assessment (MASTG-TEST-0022) | NOT APPLICABLE | — | — | NETWORK-TLS-AUDIT.md | Limited value; not recommended |
| NETWORK-1 | On-device traffic capture | — | No device or emulator session | NOT TESTABLE | — | — | — | NOT TESTABLE IN CURRENT ENVIRONMENT |

## MASVS-PLATFORM

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PLATFORM-1 | IPC used securely: no unintended exported component | Three exported test activities in the release APK | `aapt2 dump xmltree` (MASTG-TEST-0029) | PARTIAL | LOW | CONFIRMED | F-05 | Remove test plugins from release |
| PLATFORM-1 | Exported service guarded | Guarded by a permission name the platform does not define | Manifest | PARTIAL | INFO | POSSIBLE | F-19 | Confirm on device |
| PLATFORM-1 | Deep links and URL schemes validated | None exist on either platform | Manifest, `Info.plist` (MASTG-TEST-0028) | PASS | — | CONFIRMED | — | — |
| PLATFORM-1 | File sharing scoped | No file is shared; provider not exported | Manifest; source | PASS | — | CONFIRMED | `hymn_detail_page.dart:770` | — |
| PLATFORM-1 | Minimal permissions | No dangerous permission; one unneeded normal permission from the test dependency | `aapt2 dump badging` | PASS | — | CONFIRMED | F-05 covers `REORDER_TASKS` | — |
| PLATFORM-2 | WebViews configured securely | No WebView in app code | grep; manifest | PASS | — | CONFIRMED | — | — |
| PLATFORM-3 | UI does not leak sensitive data | Nothing confidential displayed; `FLAG_SECURE` on sheet music; clipboard write only on a disabled page | Source | PASS | — | CONFIRMED | `MainActivity.kt`, `donate_page.dart:307` | — |
| PLATFORM-1/3 | iOS platform behaviour | — | No build | NOT TESTABLE | — | — | — | REQUIRES MAC |

## MASVS-CODE

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| CODE-1 | Up-to-date platform target | targetSdk 36, minSdk 24 | `aapt2 dump badging` | PASS | — | CONFIRMED | `build.gradle:35-36` | — |
| CODE-2 | Enforced update mechanism | `minimumAppVersion` from `/manifest` prompts old builds | Source | PASS | — | CONFIRMED | `app_update_service.dart` | A prompt, not a hard block; adequate here |
| CODE-3 | No known-vulnerable components | Old Flutter engine; plugin majors behind; backend audit red | `pub outdated`, `npm audit` (MASTG-TEST-0042) | PARTIAL | LOW | LIKELY | F-09, F-10 | Planned upgrades |
| CODE-4 | Untrusted input validated | Server: strict zod schemas, bounded lengths and pagination; one input yields 500. Client: cache paths sanitised; JSON type-checked; no ceiling on size or pages | Live probes; source | PARTIAL | INFO | CONFIRMED | F-16, F-18 | Reject control characters; add ceilings |
| CODE-4 | No injection or dynamic code execution | No `Process`, FFI, `eval`-like or dynamic loading in `lib/`; backend SQL parameterised | grep; live SQL-injection strings returned no rows | PASS | — | CONFIRMED | — | — |
| CODE-4 | Release build free of debug and test code | Not debuggable; test scaffolding present | Manifest, dex strings (MASTG-TEST-0039) | PARTIAL | LOW | CONFIRMED | F-05 | — |

## MASVS-RESILIENCE

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RESILIENCE-1 | Platform integrity checks (root, jailbreak, emulator) | None | Threat-model assessment | NOT APPLICABLE | — | — | — | Unnecessary for this app |
| RESILIENCE-2 | App integrity: properly signed | v2 signature, RSA 2048, developer certificate, not the debug key | `apksigner verify` (MASTG-TEST-0038) | PASS | — | CONFIRMED | — | Confirm Play App Signing |
| RESILIENCE-2 | App integrity: tamper detection | None | Threat-model assessment | NOT APPLICABLE | — | — | — | Unnecessary |
| RESILIENCE-3 | Static analysis impeded | R8 on; Dart not obfuscated; symbols kept separately | `strings`, `mapping.txt` (MASTG-TEST-0051, 0040) | PARTIAL | INFO | CONFIRMED | F-20 | Optional `--obfuscate --split-debug-info` |
| RESILIENCE-3 | Nothing sensitive recoverable from the binary | Three public URLs, no key | `strings` on `libapp.so` | PASS | — | CONFIRMED | REVERSE-ENGINEERING-AUDIT.md | — |

RESILIENCE-4 (anti-dynamic-analysis) is not listed separately: no debugger or
instrumentation defence exists and none is needed.

## MASVS-PRIVACY

| Control | Requirement | Evidence | Test performed | Result | Sev | Confidence | Files | Remediation |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PRIVACY-1 | Data minimisation | No device, install or advertising identifier; reports carry only typed text and app context; server stores no IP with reports or events | Source (both sides) | PASS | — | CONFIRMED | `bug_report_queue_service.dart:323-375`, backend report repository | — |
| PRIVACY-2 | No unnecessary identifiers or linkability | Analytics events are unlinked counts | Source | PASS | — | CONFIRMED | `analytics_service.dart` | — |
| PRIVACY-3 | Transparency: behaviour matches the published policy | Policy promises 90-day deletion; the deleting job cannot authenticate. Reports have no retention. Uninstall does not clear the iOS Keychain | Live probe; source | **FAIL** | MEDIUM | CONFIRMED | F-01, F-06, F-21 | Fix the cron route; set report retention |
| PRIVACY-4 | User control | Reports are optional and deletable on request; analytics cannot be switched off although a setting key exists | Source | PARTIAL | INFO | CONFIRMED | F-24 | Wire the flag or remove it |
