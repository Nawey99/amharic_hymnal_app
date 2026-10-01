# iOS Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only, from Windows.

**Nothing in this report is VERIFIED ON MAC.** Items are CONFIRMED only where the evidence is a
committed file. Everything that needs Xcode, CocoaPods, signing or a device is marked
NOT VERIFIABLE FROM WINDOWS. iOS readiness is **not** claimed.

## Configuration (from committed files)

| Item | Value | Evidence |
|---|---|---|
| Bundle id | `com.nawey99.wudase` (tests `.RunnerTests`) | `project.pbxproj:371,550,572` |
| Deployment target | **12.0** | `project.pbxproj:349,475,526`; `AppFrameworkInfo.plist` |
| Device family | iPhone + iPad (`1,2`) | `project.pbxproj:353` |
| Signing | Automatic; no team id committed | `project.pbxproj` |
| Swift | 5.0 | same |
| Podfile | **not committed** | `git ls-files ios` |
| Display name | `ውዳሴ` | `Info.plist` |
| Background modes | `audio` | `Info.plist` |
| Orientations | iPhone: portrait + both landscape; iPad: all four | `Info.plist` |
| Localisations | `CFBundleDevelopmentRegion=$(DEVELOPMENT_LANGUAGE)`; **no `CFBundleLocalizations`** | `Info.plist` |
| Export compliance key | **absent** (`ITSAppUsesNonExemptEncryption`) | `Info.plist` |
| Privacy manifest | **no app-level `PrivacyInfo.xcprivacy`** | `ls ios/Runner` |
| Entitlements | none | — |
| Native code | `AppDelegate.swift`: secure-screen channel (capture/screenshot notifications) | — |

## Store requirements (verified 2026-10-01, https://developer.apple.com/news/upcoming-requirements/)

| Requirement | Effective | Project status |
|---|---|---|
| Built with Xcode 26 / iOS 26 SDK | 2026-04-28 | NOT VERIFIABLE FROM WINDOWS — see IOS-02 |
| Target iOS 13 or later | 2026-09-09 | **NOT MET** — 12.0 (IOS-01) |
| Age-rating questionnaire answered (new system) | 2026-01-31 | App Store Connect; NOT VERIFIABLE FROM WINDOWS |
| Privacy manifest with approved reasons for required-reason APIs (incl. third-party SDKs) | 2024-05-01 | NOT VERIFIABLE FROM WINDOWS — IOS-04 |
| Privacy policy link in app and in App Store Connect (Guideline 5.1.1(i)) | ongoing | In app: MET (`settings_page.dart:40`); ASC: unknown |
| Disclose size and prompt before downloading resources needed on first launch (4.2.3(ii)) | ongoing | Media is optional and the offer shows sizes (`offline_download_flow.dart`); first-launch content sync is small metadata. Likely MET — confirm wording on device |
| UIScene lifecycle | Apple: required for apps built with the SDK *after* iOS 26 | INFO — will matter when Xcode 27 becomes mandatory; Flutter 3.38+ includes the migration |

## Findings

- **IOS-01** CRITICAL · CONFIRMED — deployment target 12.0 (details in RELEASE-BLOCKERS.md).
- **IOS-02** CRITICAL · NOT VERIFIABLE FROM WINDOWS — Xcode 26 vs Flutter 3.27.2 (RELEASE-BLOCKERS.md).
- **IOS-03** HIGH · LIKELY — media in Application Support without backup exclusion (RELEASE-BLOCKERS.md).

### IOS-04 — No app-level privacy manifest · MEDIUM · NOT VERIFIABLE FROM WINDOWS
The app's own Swift code uses no required-reason API that I could see (`AppDelegate.swift`
uses `UIScreen.isCaptured` and notifications only). Plugins that touch `UserDefaults`
(`shared_preferences`), file timestamps (`path_provider`), or system boot time ship their own
manifests in recent versions; several dependencies here are not the latest
(`DEPENDENCY-AUDIT.md`). Sentry Cocoa is linked even when no DSN is set. Direction: on the Mac,
generate Xcode's privacy report from an archive and confirm every required-reason API is
covered; add an app manifest if not.

### IOS-05 — Amharic not declared as a supported localisation · LOW · CONFIRMED
Without `CFBundleLocalizations` (Flutter's documented step for iOS), iOS does not list the app
as supporting Amharic: the per-app language setting will not offer it and system-supplied
strings follow the development region. Direction: declare `am` and `en`.

### IOS-06 — Export compliance key absent · LOW · CONFIRMED
Every upload will ask the encryption question in App Store Connect. The app uses only HTTPS via
the OS, which is exempt. Direction: add `ITSAppUsesNonExemptEncryption = false` after confirming
no other encryption is used (flutter_secure_storage uses the Keychain, OS-provided).

### IOS-07 — Podfile not committed · LOW · CONFIRMED
`flutter build ios` generates one, but the Pods deployment target and any post-install settings
are then not reproducible across machines. Direction: commit the generated Podfile with the
platform line set.

### IOS-08 — iPad is a supported device · INFO · CONFIRMED
`TARGETED_DEVICE_FAMILY = "1,2"` means App Review tests on iPad and the listing needs iPad
screenshots. Landscape and split view must work (the layouts were not audited on iPad sizes).

## Behaviour that needs a device (all NOT VERIFIABLE FROM WINDOWS)

| Area | What to check on the Mac/device |
|---|---|
| Build | `flutter build ipa --release` with Xcode 26; upload to TestFlight; processing passes |
| Audio session | background playback with screen locked; Control Center / lock-screen controls (only play/pause/stop and seek bar by design); phone-call interruption and resume; AirPods removal pauses; route change to Bluetooth |
| Background | bulk download behaviour when the app is backgrounded (expected: suspends — DL-03) |
| Secure screen | privacy overlay appears on screen recording and app switcher over sheet music |
| Storage | iCloud backup size after "keep offline" (Settings → iCloud → Manage Storage) — confirms IOS-03 |
| Launch | first launch offline; 1961 edition offline shows the connection message |
| Accessibility | VoiceOver across tabs, hymn page, player, sheet viewer |
| Privacy | Xcode privacy report from the archive |

Note from earlier in this project: the app has been run on an iPhone from the QA Mac, so the
project does build there with *some* Xcode; which Xcode/Flutter combination was used is not
recorded in the repository.
