# Dependency Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only (`flutter pub outdated`, no upgrade).
SDK constraint `^3.6.1`; Flutter 3.27.2 (CI-pinned).

## Direct dependencies

| Package | Resolved | Latest | Used in | Native? | Notes |
|---|---|---|---|---|---|
| flutter_bloc | ^9.1.1 | — | 11 files | no | Default event concurrency is concurrent → STATE-01 |
| equatable | 2.1.0 | 3.0.0 | 5 | no | major available; no need |
| dartz | ^0.10.1 | — | 7 | no | unmaintained functional lib; only `Either` used |
| shared_preferences | 2.5.3 | 2.5.5 | 4 | yes | ships `libdatastore_shared_counter.so` (16 KB OK) |
| flutter_secure_storage | 9.2.4 | 11.2.0 (10.3.4 resolvable) | 1 | yes | `encryptedSharedPreferences` option deprecated in 10.x; v10 changes Android storage — upgrade needs a migration test for queued reports |
| cupertino_icons | 1.0.8 | 2.0.0 | **0 files** | font | unused; ships `CupertinoIcons.ttf` (258 KB) in the bundle |
| intl | 0.19.0 | 0.20.3 | 1 | no | pinned by `flutter_localizations` on 3.27; do not bump (an earlier branch did) |
| characters | 1.3.0 | 1.4.1 | 1 | no | |
| crypto | ^3.0.7 | — | 1 | no | SHA-256 verification |
| json_annotation | 4.9.0 | 4.12.0 | 1 | no | with build_runner/json_serializable (1 generated file) |
| just_audio | ^0.10.6 | — | 1 | yes (ExoPlayer/AVPlayer) | |
| audio_service | ^0.18.19 | — | 3 | yes | brings `flutter_cache_manager` transitively |
| audio_session | ^0.2.4 | — | 1 | yes | |
| path_provider | 2.1.5 | 2.1.6 | 3 | yes | |
| get_it | 9.2.1 | 9.3.0 | 1 | no | |
| path | 1.9.0 | 1.9.1 | 2 | no | |
| url_launcher | ^6.3.1 | — | 1 | yes | |
| wakelock_plus | 1.3.3 | 1.8.1 | 1 | yes | |
| share_plus | 10.1.4 | 13.3.0 (12.0.2 resolvable) | 1 | yes | |
| http | ^1.2.2 | — | 10 | no | no idle timeout on streams (DL-01) |
| package_info_plus | 8.3.1 | 10.2.1 (9.0.1 resolvable) | 4 | yes | |
| sentry_flutter | 9.30.0 | 9.30.1 | 1 | **yes** | native libs (`libsentry.so` ~0.85 MB per ABI) and Sentry Cocoa ship in every build even when no DSN is configured |

Transitive notes: `jni 0.14.2` (`libdartjni.so`), `js` (discontinued), `flutter_secure_storage_macos` (discontinued, irrelevant to mobile).

## Dev dependencies
`flutter_test`, `integration_test`, `flutter_driver` (perf test only), `build_runner`,
`json_serializable`, `flutter_lints ^5`, `mocktail`, `bloc_test`, `fake_async`,
`json_schema` (API contract validator in `test/contract`), `patrol ^3.15.2` (native flows;
pubspec notes `patrol_cli 3.6`). Patrol's Android runner is wired in `build.gradle`
(`PatrolJUnitRunner`, orchestrator).

## Findings

### DEP-01 — Flutter 3.27.2 is the binding constraint · HIGH (via IOS-02) · CONFIRMED
Most "resolvable" ceilings above exist because of the Flutter/Dart version. The iOS Xcode 26
requirement (IOS-02) may force a Flutter upgrade, which would move most plugins at once. Plan
dependency upgrades together with that decision rather than piecemeal.

### DEP-02 — Unused dependency · LOW · CONFIRMED
`cupertino_icons` has no import in `lib/` and adds a 258 KB font to the bundle.

### DEP-03 — Crash-reporting SDK always linked · INFO · CONFIRMED
Store builds without a DSN send nothing (`crash_reporting.dart:28-36`) but still carry Sentry's
native code. Fine if intended; it also means App Store privacy review sees the SDK.

### DEP-04 — `dartz` · INFO
Unmaintained but stable and pure Dart; no release risk.

No dependency with a known security advisory was identified in this phase; the CI job
"Scan Dependency Advisories" (`test.yml`) exists but its results were not inspected.
