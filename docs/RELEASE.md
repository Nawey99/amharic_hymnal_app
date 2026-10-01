# Releasing ውዳሴ

How a version goes from this repository to Google Play and the App Store, and
how to back out of one. Requirements were checked against the stores'
official pages on 2026-10-01; recheck them before each release
(`docs/release-audit/STORE-READINESS-AUDIT.md` lists the sources).

Items marked **(confirm)** depend on accounts or plans this repository cannot
see.

## 1. Before every release

1. `flutter analyze lib test`, `dart format --set-exit-if-changed .` and
   `flutter test` pass (CI does the same on every push).
2. CI's **Build iOS (unsigned, Xcode 26)** job is green.
3. Bump `version:` in `pubspec.yaml`. The part after `+` is the Android
   `versionCode` and iOS `CFBundleVersion`; it must be higher than any build
   ever uploaded to either store, even rejected ones.
4. Read the English strings that changed (`lib/core/l10n/app_localizations.dart`).
5. Check content on the API: no placeholder or test songs active
   (`GET /sync?version=<code>` and look at `isActive`).
6. The Donate page still shows placeholder bank details ("To be added
   later") and "PayPal coming soon": replace them with the real details, or
   hide the page, before the first public release.
7. On a physical Android phone, confirm screenshots are blocked while sheet
   music is open (the emulator does not prove `FLAG_SECURE`).

## 2. Build

Symbols: build with `--split-debug-info` and keep the folder. Without it, a
stack trace from a store build cannot be read later, and the symbols cannot
be regenerated after the fact. Obfuscation (`--obfuscate`) is optional; if
used, the same folder is needed to read traces.

```sh
VERSION=1.0.0+1   # as in pubspec.yaml
flutter build appbundle --release \
  --split-debug-info=build/symbols/$VERSION/android
flutter build ipa --release \
  --split-debug-info=build/symbols/$VERSION/ios      # on the Mac, Xcode 26
```

Archive `build/symbols/$VERSION/` somewhere outside the repository (it is
git-ignored) together with the uploaded `.aab` / `.ipa`.

Crash reporting stays off in store builds unless `WUDASE_SENTRY_DSN` is
passed; that is the documented, intended state (privacy policy §4).

### Android signing
The upload key is `wudase-upload.jks` (alias `upload`), described by the
git-ignored `android/key.properties` (see `android/key.properties.example`).
Without that file Gradle warns and produces an **unsigned** bundle, which
Play rejects. Never commit the key or its passwords. Losing the upload key is
recoverable through Play Console (upload key reset) only because Play App
Signing holds the app signing key **(confirm Play App Signing is enabled)**.

### iOS signing
Automatic signing with the team selected in Xcode on the release Mac. The
deployment target is iOS 14.0, which background downloads need (`ios/Podfile`, `project.pbxproj`,
`AppFrameworkInfo.plist` must agree).

## 3. Upload

### Google Play
- Upload the `.aab` to **Internal testing** first, install from Play on a real
  phone, then promote.
- New personal developer accounts (created after 2023-11-13) must run a
  closed test with at least 12 testers opted in for 14 consecutive days
  before production **(confirm account type)**.
- App content declarations, kept in step with the code:
  - **Data safety** — see `docs/release-audit/PRIVACY-AUDIT.md` (usage counts,
    optional email/phone in reports, report diagnostics; no sharing; deletion
    by email).
  - **Foreground service** — `mediaPlayback`, with a short screen recording of
    a hymn playing with the screen off and the notification controls.
  - Content rating, target audience, ads (none), privacy policy URL
    `https://nawey99.github.io/amharic_hymnal_app/privacy.html`.
- Release to production as a **staged rollout** (e.g. 10 % → 50 % → 100 %).

### App Store
- `flutter build ipa` on the Mac, upload with Xcode Organizer or Transporter,
  test through TestFlight, then submit.
- App Privacy answers follow `ios/Runner/PrivacyInfo.xcprivacy` and
  `PRIVACY-AUDIT.md`. After archiving, generate Xcode's privacy report
  (Organizer → archive → *Generate Privacy Report*) and check it.
- Export compliance is answered by `ITSAppUsesNonExemptEncryption = false`.
- The app supports iPad: provide iPad screenshots.
- Use **phased release** for production.

## 4. Backing out of a release

Neither store can reinstall an older build on phones that already updated.
Backing out means stopping the spread, then shipping a fix with a higher
build number.

| Where | What to do |
|---|---|
| Google Play | Play Console → the release → **Halt rollout**. Users who already updated keep the build; build and upload a fixed version with a higher `versionCode`. |
| App Store | **Pause phased release**, or remove the version from sale. Submit a fixed build (expedited review can be requested). |
| Hymnal API (Vercel) | Vercel dashboard → Deployments → previous deployment → **Instant Rollback**. |
| Content | Content changes are data, not code: correct or deactivate the song in the admin console; the app picks it up on the next sync (delta, or the weekly full refresh). |
| Content requiring a newer app | Set `release.minimumAppVersion` on `/manifest`; older apps tell the reader to update (`AppUpdateService`). |

## 5. Backup and recovery

| What | Where it lives | Backup **(confirm)** |
|---|---|---|
| Hymn content, categories, reports, usage counts | Supabase Postgres | Supabase's daily backups depend on the plan; point-in-time recovery is a paid add-on. Take a `pg_dump` before every bulk content change. |
| Audio and sheet-music files | Supabase Storage bucket | Not covered by database backups. Keep the original files (or a periodic copy of the bucket) outside Supabase. |
| API code and configuration | GitHub + Vercel project settings | Code in git; record Vercel environment variable *names* (not values) in the backend docs. |
| App signing keys | Upload keystore (`D:\Church\App\keys`), Play App Signing; Apple certificates in the team account | Keep an offline copy of the keystore and its passwords in a password manager. |

What readers have on their phones (favourites, history, settings) is not
backed up by the app (`allowBackup="false"` on Android, matching the privacy
policy's "never leave your device"); on iOS it is part of the normal device
backup. Downloaded media is deliberately excluded from iOS backups and is
re-downloaded when needed.

## 6. After release
- Watch Play Console *Android vitals* and App Store Connect *Crashes*.
- Check the API's error rate in Vercel and the reports inbox.
