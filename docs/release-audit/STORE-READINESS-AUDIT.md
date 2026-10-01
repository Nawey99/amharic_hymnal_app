# Store Readiness Audit — Phase 1

Audit date and source verification date: **2026-10-01**. Every time-sensitive requirement below
was read from the cited official page on that date.

## Google Play

| Requirement | Source | Status | Evidence | Risk if unmet |
|---|---|---|---|---|
| Target API 36 for new apps/updates from 2026-08-31 (extension to 2026-11-01) | https://developer.android.com/google/play/requirements/target-sdk | **MET** | `targetSdk = 36` | upload rejected |
| 64-bit native code | https://support.google.com/googleplay/android-developer/answer/17492799 | **MET** | arm64-v8a, x86_64 in AAB | rejected |
| 16 KB memory page size for native code | same; https://developer.android.com/guide/practices/page-sizes | **MET** | ELF alignment ≥ 0x4000 for all 64-bit `.so` (ANDROID-AUDIT.md) | rejected |
| Foreground service type in manifest + Play Console declaration (description, demo video) | https://support.google.com/googleplay/android-developer/answer/13392821 | Manifest **MET**; Console **UNKNOWN** | `foregroundServiceType="mediaPlayback"` | review rejection |
| Data safety form | Play Console policy | **UNKNOWN** | PRIVACY-AUDIT.md | rejection / removal |
| Privacy policy URL | Play policy | **MET in app**; listing UNKNOWN | `settings_page.dart:40`, URL returns 200 | rejection |
| New personal accounts (after 2023-11-13): closed test ≥ 12 testers, 14 consecutive days | https://support.google.com/googleplay/android-developer/answer/14151465 | **UNKNOWN** | account type not in repo | cannot apply for production |
| Content rating questionnaire, target audience, ads declaration (none) | Play Console | **UNKNOWN** | no ads SDK in code | blocked submission |
| Upcoming Feb 2027: memory bad-behaviour + code-optimisation thresholds | answer/17492799 | INFO | — | future updates |

## Apple App Store

| Requirement | Source | Status | Evidence | Risk if unmet |
|---|---|---|---|---|
| Built with Xcode 26 / iOS 26 SDK (since 2026-04-28) | https://developer.apple.com/news/upcoming-requirements/ | **NOT VERIFIABLE FROM WINDOWS** — Flutter 3.27.2 predates Flutter's Xcode 26 support (3.38) | IOS-02 | cannot upload |
| Minimum target iOS 13 (since 2026-09-09) | same | **NOT MET** | deployment target 12.0 (IOS-01) | cannot upload |
| Age-rating questionnaire (new system, since 2026-01-31) | same | **UNKNOWN** | App Store Connect | blocked submission |
| Privacy manifest / approved reasons for required-reason APIs (since 2024-05-01) | same | **NOT VERIFIABLE FROM WINDOWS** | IOS-04 | upload rejected |
| Privacy policy in app and in metadata (5.1.1(i)) | https://developer.apple.com/app-store/review/guidelines/ | In app **MET**; ASC UNKNOWN | `settings_page.dart:40` | rejection |
| App Privacy ("nutrition label") | App Store Connect | **UNKNOWN** | PRIVACY-AUDIT.md | rejection |
| Disclose size and ask before downloading resources needed at first launch (4.2.3(ii)) | guidelines | **LIKELY MET** — media optional, sizes shown | `offline_download_flow.dart` | rejection |
| Re-downloadable data out of iCloud backup (Apple data-storage guidance) | https://developer.apple.com/documentation/foundation/optimizing_your_app_s_data_for_icloud_backup | **LIKELY NOT MET** (page content could not be retrieved by the fetch tool; requirement stated from Apple's referenced guidance) | IOS-03 | rejection |
| iPad screenshots and iPad functionality (device family includes iPad) | App Store Connect | **UNKNOWN** | `TARGETED_DEVICE_FAMILY = "1,2"` | rejection |
| Export compliance | App Store Connect | answer manually each upload (IOS-06) | — | delay |
| EU DSA trader status (if distributing in EU) | upcoming-requirements page | **UNKNOWN** | — | EU removal |

## Content and rights (INFO, owner judgement)
The app shows lyrics, sheet-music scans and audio. Sheet music is screenshot-protected "to
respect the rights of its publishers" (privacy policy). Both stores may ask for proof of rights
to distribute hymn texts/scans/recordings; the repository contains no licence documentation.
The untracked `docs/churchofjesuschrist_*` files are third-party data and correctly not committed.

## Status
- **Android:** technically ready on every requirement that is checkable from the repository;
  remaining items are Play Console declarations and the account's testing requirement.
- **iOS:** **not ready** — one confirmed upload blocker (IOS-01), one unverified mandatory
  toolchain requirement (IOS-02), plus privacy manifest and backup-storage items to verify on a Mac.
