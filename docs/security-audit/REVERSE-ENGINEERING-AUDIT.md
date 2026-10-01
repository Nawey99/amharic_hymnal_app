# Reverse-Engineering Audit

Audit date: 2026-10-01.

Question answered here: **what can an ordinary technically capable person
recover from the distributed Android app?** The answer is: the public API
address, the route names, the app's class structure, and the bundled hymn text.
No secret.

## Artifact and tools

| Item | Value |
| --- | --- |
| Artifact | `build/app/outputs/flutter-apk/app-release.apk`, built locally 2026-09-29 |
| Tools used | `unzip`, `strings` (MinGW), `aapt2` and `apksigner` (Android build-tools 36.0.0) |
| NOT AVAILABLE | jadx, apktool, MobSF, bundletool, Ghidra, apkanalyzer |
| iOS | No artifact. NOT VERIFIABLE FROM WINDOWS |

The Dart snapshot (`libapp.so`) was examined with `strings` only. A dedicated
Dart AOT decompiler would recover more control flow but not more constants;
string constants are stored in the snapshot and `strings` finds them.

## APK contents

| Path | What it is |
| --- | --- |
| `classes.dex` (4.3 MB) | Java/Kotlin: Flutter embedding, plugins, AndroidX, Sentry; R8-minified |
| `lib/<abi>/libapp.so` (8.4 MB arm64) | The whole Dart application, AOT-compiled |
| `lib/<abi>/libflutter.so` | Flutter engine |
| `lib/<abi>/libsentry*.so`, `libdartjni.so`, `libdatastore_shared_counter.so` | Plugin native code |
| `assets/flutter_assets/assets/data/database/SDA_Hymnal.json`, `HagerignaData.json` | Bundled hymn text (fallback content) |
| `assets/flutter_assets/assets/{fonts,images,onboarding}` | Fonts and artwork |
| `assets/flutter_assets/packages/wakelock_plus/assets/no_sleep.js` | Web helper shipped by the plugin; inert on Android |
| `junit/`, `LICENSE-junit.txt`, `custom.config.yaml`, `custom.config.conf`, `DebugProbesKt.bin`, `org/fusesource` | Leftovers from test and Kotlin tooling dependencies (F-05) |

Four ABIs are packed into this universal APK (arm64-v8a, armeabi-v7a, x86,
x86_64). The Play bundle delivers one per device.

## What was recovered

### URLs (complete list of non-framework URLs in `libapp.so`)

```
https://amharichymnalbackend.vercel.app/api/v1
https://nawey99.github.io/amharic_hymnal_app/privacy.html
https://github.com/Nawey99/amharic_hymnal_app
file:///D:/Church/App/amharic_hymnal_app/.dart_tool/flutter_build/dart_plugin_registrant.dart
```

The last one is a build-machine path embedded by the Flutter tool. It discloses
the developer's directory layout and nothing else.

### API routes

`/sync`, `/manifest`, `/reports`, `/categories`, `/songs/`, `/hymn-versions`,
`/hymn-versions/`, `/analytics/events`. All are public routes that are also
documented in the server's own public OpenAPI file.

### Configuration names

`WUDASE_CONTENT_API_URL` (in two error strings), `bug_report_queue`,
`content_cache`, `media_cache`, and the SharedPreferences key names. These are
storage labels, not secrets.

### Secret-shaped strings

Searched for JWTs (`eyJ…`), Sentry DSNs and tokens, Supabase keys
(`sb_secret_`, `sb_publishable_`, `service_role`), AWS/R2 key formats, Google
API keys, GitHub tokens, private-key headers, Postgres URLs and the words
`password`, `secret`, `api key`, `Bearer`, `Authorization`.

Result: **one match**, `, sentry_secret=`, which is a format string inside the
Sentry SDK. No value follows it. This build has no DSN compiled in, so crash
reporting is off.

### Code structure

Dart symbols are intact: 117 occurrences of `package:amharic_hymnal_app/…`
library paths, plus class names such as `HymnRemoteDataSource`,
`BugReportQueueService`, `LocalMediaCacheService`. The build did not use
`--obfuscate` (F-20). The Java side is R8-renamed
(`IsEnabledMessage -> a` in `mapping.txt`); manifest-referenced classes keep
their names as they must.

### Not present

| Looked for | Found |
| --- | --- |
| Hard-coded credentials or tokens | None |
| Supabase URL or key | None (the app never talks to Supabase directly) |
| Storage bucket name or key | None |
| Admin routes or admin UI | None; the app contains no administrative function |
| Staging or development endpoints | None; one base URL |
| Feature flags gating paid or restricted content | None exist |
| Test credentials, mock API, dummy audio | None |
| Developer sheet-music path `D:\Church\App\Amharic_Hymnal_Songs` (`constants.dart:59`) | Not in the binary; the unused constant was tree-shaken |
| Debug screens | None |

## What an attacker can do with what they recover

| Recovered | Use |
| --- | --- |
| API base URL and routes | Call the public API directly. This is already possible and intended; see the direct-access scenario in API-AUTHORIZATION-AUDIT.md. |
| Class structure | Understand or patch the client. No server decision depends on client behaviour. |
| Bundled hymn JSON | Copy public hymn text. |
| Signing certificate digest | Public by nature. |

There is no client-side secret to protect, so obfuscation would add resilience
against casual reading and nothing else. It is an optional measure.

## Symbols and mapping files

| File | Location | Handling |
| --- | --- | --- |
| R8 mapping | `build/app/outputs/mapping/release/mapping.txt` (39 MB) | Keep privately per release; upload to Play for de-obfuscated crash traces. Not in the APK. |
| Native debug symbols | `build/app/outputs/native-debug-symbols/release/native-debug-symbols.zip` | Same |
| Dart split debug info | Not produced (no `--split-debug-info`) | Would be required if `--obfuscate` is adopted |

`build/` is git-ignored, so none of these is committed.

## Tampering and instrumentation

The app has no integrity check, root detection, emulator detection or debugger
detection. For this application each is **unnecessary**:

| Mechanism | Verdict | Reason |
| --- | --- | --- |
| Code obfuscation (Dart) | Useful but optional | No secret; slows casual reading only |
| Integrity / anti-tamper | Unnecessary | A modified client gains no privilege |
| Runtime tamper or hook detection | Unnecessary | Same |
| Debugger detection | Unnecessary | Same |
| Root / jailbreak detection | Unnecessary | Would exclude legitimate users for no gain |
| Emulator detection | Unnecessary | Same |

Client-side checks that instrumentation can bypass, and the consequence:

| Check | Bypass consequence |
| --- | --- |
| `FLAG_SECURE` on sheet music | User can screenshot pages they can already download |
| Update prompt from `minimumAppVersion` | User stays on an old build |
| SHA-256 verification of downloads | User loads altered media into their own app |
| Release-only HTTPS assertion | Patched app could use HTTP against a server of the user's choosing |

None affects another user or the backend.

## Profile and debug builds

`app-profile.apk` (49 MB) and `app-debug.apk` (141 MB) are also in `build/`.
They permit cleartext traffic, and the debug build exposes the Dart VM service.
They are for local use only and must never be the file that is distributed.

## Findings from this area

F-05 (LOW), F-20 (INFO).
