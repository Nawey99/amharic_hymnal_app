# Storage and Database Audit

Audit date: 2026-10-01.

## Part 1: on-device storage

### Inventory

| Mechanism | Location | Contents | Sensitivity | Protection |
| --- | --- | --- | --- | --- |
| SharedPreferences | App-private prefs | Language, edition, sort, font size, theme, keep-screen-on, onboarding flag, favourites per edition, history, offline-media choices, `contribution_unlocked`, `data_collection_enabled`, cached category lists (`edition_categories_<code>`) | Low: preferences and reading history | Plaintext, app sandbox |
| `flutter_secure_storage` | Android: EncryptedSharedPreferences. iOS: Keychain | `bug_report_queue`: unsent reports (title, description, optional contact, app context) | Personal while queued | Encrypted with an OS-held key |
| Files | `<app support>/content_cache/*.json` | Synced catalogue exactly as the API sent it | Public | Plaintext, app sandbox |
| Files | `<app support>/media_cache/audio`, `/sheet_music` | Downloaded tracks and pages | Public | Plaintext, app sandbox |
| Files | `<app support>/wudase_media_artwork.png` | Notification artwork copied from assets | Public | — |
| SQLite | `flutter_cache_manager` database (pulled in by `audio_service`) | Would cache remote artwork; the app only supplies a local file URI | None in practice | Dormant |
| Bundled assets | `assets/data/database/*.json` | Fallback hymn text | Public | In the APK |
| Web | No queue; reports are sent directly | — | — | `bug_report_queue_service.dart:67-69` |

There is **no token, credential, account identifier, device identifier or
analytics identifier** stored anywhere on the device. Confirmed by reading every
storage call site (`SharedPreferences`, `FlutterSecureStorage`, `File(`) in `lib/`.

### Classification of what is and is not encrypted

- Encrypted with a platform key: the bug-report queue only.
- Plaintext in the sandbox: everything else. None of it needs encryption: it is public content plus personal preferences that the sandbox already isolates from other apps.
- Nothing is merely encoded and presented as protected.

### `flutter_secure_storage` review

| Question | Answer |
| --- | --- |
| What is stored | One key, `bug_report_queue`, a JSON list |
| Why | A report may contain an email or phone number the user typed |
| Android implementation | `AndroidOptions(encryptedSharedPreferences: true)`; AES key in Android Keystore; minSdk 24 supports it |
| iOS implementation | Keychain, default accessibility (`unlocked`), no access group configured |
| Lifecycle | Written on failed send; flushed at startup (`main.dart:85`); removed when sent or permanently refused |
| Backup | Android: `allowBackup="false"` excludes it. iOS: Keychain items are in encrypted device backups and survive app deletion (F-21) |
| Migration | A legacy plaintext queue in SharedPreferences is moved into secure storage and deleted (`:41-53`) |
| Failure behaviour | Read errors return an empty list; write errors report "not queued" to the UI. A Keystore failure loses the queue rather than exposing it |
| Sensitive data elsewhere by mistake | None found |

### Extraction on a rooted or debug device

On a rooted Android phone, an emulator, or a jailbroken iPhone, the prefs, the
catalogue JSON and the media files can be copied out. That yields the user's own
favourites and history plus public content. The secure-storage key is in the
hardware-backed keystore where available. This is a resilience observation, not
a vulnerability: there is nothing on the device worth extracting.

### Android backup

`android:allowBackup="false"` and `android:fullBackupContent="false"` are set
and are present in the built release manifest. No `dataExtractionRules` is
declared; with `allowBackup="false"` cloud backup and device-to-device transfer
are off on Android 12+. Consequence: favourites and history do **not** move to a
new phone. That is a product trade-off, not a security defect.

### Logging

Every `debugPrint` in `lib/` is inside `if (kDebugMode)` except two that print
only an error object or a count (`main_navigation_page.dart:196`,
`hymns_state.dart:67`). The single `print` (`frame_stats_probe.dart:37`) runs
only when built with `WUDASE_FRAME_STATS=true`. No log statement prints a token,
header, signed URL, report body or contact detail in a release build.

### Clipboard, screenshots, sharing

- **Clipboard:** one write, the donation account number (`donate_page.dart:307`), on a page that is switched off (`donationsReady = false`). No clipboard read.
- **Screenshots:** `FLAG_SECURE` is applied while the sheet-music viewer is open and cleared afterwards (`MainActivity.kt:41-55`). On iOS the app only observes capture and screenshot notifications. Nothing the app displays is confidential, so this is content courtesy, not a security control, and bypass on a rooted device is not a finding.
- **Share:** hymn title and lyrics as plain text through the system sheet (`hymn_detail_page.dart:770-772`). No file is shared, so the `ShareFileProvider` that `share_plus` registers (not exported, `grantUriPermissions=true`) is never given a URI by this app.

## Part 2: database (Supabase PostgreSQL)

### Access paths

| Path | Reachable by an unauthenticated client? | Evidence |
| --- | --- | --- |
| Through the API | Yes, as designed | Section "Route inventory" in API-AUTHORIZATION-AUDIT.md |
| Supabase Data API (PostgREST) with the public anon key | No | `/rest/v1/songs`, `user_profiles`, `reports`, `audit_log` each answer `PGRST205 Could not find the table 'api_disabled.<name>'`. `/rest/v1/` root requires the service-role key. |
| Supabase GraphQL | No | `PGRST202`, function not found in `api_disabled` |
| Direct Postgres | No without the password | Connection strings exist only in Vercel and local env files |

The mobile app does not initialise a Supabase client and holds no Supabase key.
The anon key appears only in the admin page's script, where its sole use is the
password sign-in call.

### Lock-down state

Migration `20260918150000_lock_down_data_api`:

1. `REVOKE ALL` on every `public` table from `anon` and `authenticated`.
2. `ENABLE ROW LEVEL SECURITY` on every table, with no policies.
3. `ALTER DEFAULT PRIVILEGES … REVOKE` for future tables and sequences.
4. Points PostgREST at an empty schema, `api_disabled`.

| Tables | RLS | Policies | API-role grants |
| --- | --- | --- | --- |
| 20 tables existing at the lock-down (songs, media, releases, categories, user_profiles, favorites, reports, analytics_events, admin_audit_logs, works, bundles, …) | Enabled | None | Revoked |
| `work_relations`, `link_suggestions` (created four days later) | **Not enabled** | None | Expected to be absent via default privileges; not verified live (F-07) |

No `SECURITY DEFINER` function, view, trigger or policy exists in any of the 13
migrations. The only extension is `pg_trgm`.

Live verification of RLS and grants needs a catalogue query
(`pg_class.relrowsecurity`, `information_schema.role_table_grants`):
REQUIRES BACKEND ACCESS.

### Query safety

| Area | Finding |
| --- | --- |
| ORM | Prisma for almost everything |
| Raw SQL in `src/` | Tagged `$queryRaw` and `Prisma.sql` only; values are bound parameters. No `$queryRawUnsafe` or `$executeRawUnsafe` in request-serving code |
| Search | `\`, `%`, `_` escaped before `LIKE`; input 1–200 characters. Live: `' OR 1=1--` and `%%%_\` both returned zero rows |
| Dynamic identifiers | None built from input |
| Operator scripts | One `$queryRawUnsafe` with a static string and a positional parameter (`scripts/link-shared-audio.ts`) |
| Error leakage | Database errors become `DATABASE_ERROR` with a generic message |

### Roles and credentials

The API connects as the table owner, which bypasses RLS by design; RLS exists to
neutralise the Supabase API roles, not to constrain the API. Combined with a
storage key that is not bucket- or read-scoped, a compromise of the function or
its environment is a full compromise (F-25). No such compromise path was found.

The production connection string has no `sslmode` (F-08).

### What an anonymous party can cause to be stored

| Table | Via | Limit | Content |
| --- | --- | --- | --- |
| `reports` | `POST /reports` | 20/hour per address | Free text ≤ 4000, contact ≤ 200, small context object. No IP, no user agent. Kept indefinitely (F-06). |
| `analytics_events` | `POST /analytics/events`, and server-side on search and download | 1000/hour per address | Event type, optional song id, metadata; search text truncated to 100 characters. Retention job not running (F-01). |

Report text is attacker-controlled and is later shown in the admin console. The
console renders the message with `textContent` and escapes the preview, contact
and context values; no XSS sink was found (reviewed every `innerHTML`
assignment in `src/admin-ui/`).

### Backups

- GitHub Actions takes a daily `pg_dump` and stores it unencrypted as a 30-day artifact (F-04).
- Two manual dumps sit unencrypted in `D:\Church\App\backups\` (F-02).
- Supabase free tier takes no automatic backups (stated in the workflow comment).

## Findings from this area

F-01, F-02, F-04, F-06, F-07, F-08, F-21, F-24, F-25.
