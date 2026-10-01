# iOS Security Audit

Audit date: 2026-10-01.

## Verification status

**Nothing in this document was VERIFIED ON MAC.** The audit ran on Windows. Every
statement below comes from reading the files under `ios/` and the Dart sources.
No iOS build, archive, IPA, simulator or device was available. Items are marked:

- **VERIFIED ON WINDOWS**: a fact about a source file.
- **REQUIRES MAC**: needs Xcode, a build or a device.

The iOS project appears never to have been built on this machine: there is no
`ios/Podfile`, no `Podfile.lock`, no `Pods/`, no entitlements file and no
development team in the project file. Treat iOS as **not release-ready and not
assessed at runtime**.

## Info.plist (`ios/Runner/Info.plist`) — VERIFIED ON WINDOWS

| Key | Value | Assessment |
| --- | --- | --- |
| `NSAppTransportSecurity` | absent | ATS defaults apply: HTTPS with TLS 1.2+ required. No exception domain, no `NSAllowsArbitraryLoads`. |
| `CFBundleURLTypes` | absent | No custom URL scheme |
| Associated domains | none (no entitlements) | No universal links |
| `UIBackgroundModes` | `audio` | Needed for background playback; appropriate |
| Usage descriptions (`NS…UsageDescription`) | none | No camera, microphone, photos, location or tracking access requested |
| `LSApplicationQueriesSchemes` | absent | `url_launcher` opens `https` links, which needs no declaration |
| `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace` | absent | The app's files are not exposed in the Files app or Finder |
| `ITSAppUsesNonExemptEncryption` | absent | Export-compliance question will be asked at upload; the app uses only HTTPS and OS keychain crypto |

## Native code (`ios/Runner/AppDelegate.swift`, 99 lines) — VERIFIED ON WINDOWS

One method channel, `wudase/secure_screen`:

- `enable` / `disable` start or stop observing `UIScreen.capturedDidChangeNotification` and `UIApplication.userDidTakeScreenshotNotification`;
- `isCaptured` returns `UIScreen.main.isCaptured`.

It reads no pasteboard, file, URL or keychain item and takes no arguments. No
other Swift or Objective-C code exists besides the generated plugin registrant.

## URL schemes, universal links, inbound data

None declared. No `application(_:open:options:)` or `continue userActivity`
override. **No inbound link surface.** Crafted links cannot reach the app.

## Keychain — VERIFIED ON WINDOWS (code), REQUIRES MAC (behaviour)

| Question | Answer |
| --- | --- |
| What is stored | One item: `bug_report_queue` (unsent reports) |
| API | `flutter_secure_storage` 9.2.4 with default `IOSOptions` |
| Accessibility class | Package default, `kSecAttrAccessibleWhenUnlocked`; not overridden in code |
| Access group / sharing | None configured |
| iCloud Keychain sync | Not enabled (`synchronizable` default false) |
| Persistence | Keychain items survive app deletion. A queued report with a contact detail would reappear after reinstall and be sent at next launch. The privacy policy says uninstalling deletes everything on the phone (F-21). |
| Backup | Included in encrypted device backups only, as `WhenUnlocked` (not `ThisDeviceOnly`) |
| Deletion | Removed when the report is sent or refused |

The window is small (a report is queued only while offline), but the statement
in the policy is not strictly true on iOS.

## File protection — REQUIRES MAC

Catalogue JSON and media are written under Application Support with no explicit
`NSFileProtection` attribute, so the platform default
(`CompleteUntilFirstUserAuthentication`) applies. The content is public; no
stronger class is needed. Application Support is included in iCloud and local
backups by default; nothing there is sensitive, but several hundred megabytes of
downloaded media would be backed up unless excluded. That is a storage-quota
matter for users, not a security issue.

## Pasteboard — VERIFIED ON WINDOWS

One write (`Clipboard.setData` of a bank account number) on the donation page,
which is disabled (`SettingsPage.donationsReady = false`). No read. Nothing
sensitive reaches the pasteboard.

## Screenshots and app switcher

On iOS the app does not block capture; it observes capture state and shows a
privacy overlay on the sheet-music screen (`SecureScreenService.usesPrivacyOverlay`).
The app-switcher snapshot is not blanked. The app shows no confidential data, so
no control is required. REQUIRES MAC to confirm the overlay behaves as intended.

## WebView

No `WKWebView` in project code. `url_launcher` opens both links with
`LaunchMode.externalApplication` (Safari). **NO WEBVIEW ATTACK SURFACE FOUND.**

## Embedded frameworks — REQUIRES MAC

Expected from the plugin list: Flutter, App, Sentry (with its native SDK),
audio_service, audio_session, just_audio, flutter_secure_storage,
package_info_plus, path_provider_foundation, share_plus,
shared_preferences_foundation, sqflite_darwin, url_launcher_ios, wakelock_plus,
plus the dev-only `integration_test` and `patrol`. Versions are unpinned because
no `Podfile.lock` exists. Whether the test plugins are linked into a release IPA
(the iOS counterpart of F-05) needs a build to answer.

## Code signing — `ios/Runner.xcodeproj/project.pbxproj`

| Item | Value | Status |
| --- | --- | --- |
| Bundle identifier | `com.nawey99.wudase` | VERIFIED ON WINDOWS |
| Deployment target | iOS 12.0 | VERIFIED ON WINDOWS; `sentry_flutter` 9.x and other plugins may require a higher minimum, which a first `pod install` will report |
| `CODE_SIGN_IDENTITY` | `iPhone Developer` (Flutter template default) | VERIFIED ON WINDOWS |
| `CODE_SIGN_STYLE` | Automatic (test target) | VERIFIED ON WINDOWS |
| `DEVELOPMENT_TEAM` | Not set | VERIFIED ON WINDOWS |
| Entitlements | No file | VERIFIED ON WINDOWS |
| Capabilities | Background audio only (via Info.plist) | VERIFIED ON WINDOWS |
| Provisioning profile, distribution certificate, archive validity | — | **NOT VERIFIABLE FROM WINDOWS** |
| `.p8`, `.p12`, `.mobileprovision` in the repository or history | None | VERIFIED ON WINDOWS |
| `ENABLE_BITCODE` | NO | VERIFIED ON WINDOWS |

## Jailbreak, debugger, tamper detection

None present, and none needed for the same reasons given in
ANDROID-SECURITY-AUDIT.md.

## Items requiring a Mac

1. Build and archive a release; confirm it signs and which frameworks are embedded.
2. Confirm `patrol` and `integration_test` are absent from the release IPA.
3. Run `strings` on the `App.framework` binary and confirm the same three URLs and no DSN, as on Android.
4. Confirm ATS blocks an `http://` media URL.
5. Inspect the Keychain item's accessibility class and confirm persistence after uninstall.
6. Inspect the app container for file-protection classes and backup inclusion.
7. Confirm the privacy overlay and background-audio behaviour on a device.
8. Generate and commit `Podfile.lock` so dependency versions are pinned and auditable.
9. Produce the privacy manifest (`PrivacyInfo.xcprivacy`) Apple requires; none exists in `ios/Runner`.

## Findings from this area

F-21 (INFO, POSSIBLE). No iOS-specific vulnerability was identified from source,
but absence of findings here reflects absence of testing, not assurance.
