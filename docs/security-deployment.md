# Security and Deployment Runbook

Last audited: 2026-08-14

## Readiness decision

The repository is ready for a controlled remote preview after provider secrets,
database runtime roles, and the first approved content release are configured.
It is not ready for a public store release until the final application ID,
Android/iOS signing, production URLs, privacy policy, and provider backups are
owned and verified. The current Android bundle targets API 35; new Play Store
submissions must target API 36 starting August 31, 2026, so upgrade and retest
the Flutter/Android toolchain before that deadline if the first submission will
not happen earlier. See Google's current
[target API policy](https://developer.android.com/google/play/requirements/target-sdk).

The browser and Flutter app never connect directly to PostgreSQL. They receive
only HTTPS API URLs. There is no safe "public database key" for this design and
none should be added to Flutter.

## Trust boundaries

```text
Flutter / Flutter web
  |-- public reads ----------> Content API ----> SDA PostgreSQL
  |                                |-----------> Hagerigna PostgreSQL
  |-- public bug reports ----> User API -------> User PostgreSQL

Content Studio / Review Console
  |-- Secure HttpOnly cookie + CSRF -----------> Content API

Bug report administrator
  |-- Secure HttpOnly cookie + CSRF -----------> User API
```

PostgreSQL must accept traffic only from the backends or the provider's trusted
administration path. Content editors and reviewers receive application accounts,
never database accounts.

## Implemented controls

| Requirement | Implementation |
| --- | --- |
| Hide API keys | `.env`, signing keys, and provider credentials are ignored by Git and Docker. Flutter contains only public API base URLs. |
| Purge Git secrets | The repository-specific scanner checks tracked and untracked commit candidates while pinned TruffleHog scans full Git history. Both current scans are clean, so no destructive history rewrite was needed. |
| Public DB key | Not used. Only separate server-side runtime and migration PostgreSQL URLs exist. |
| Row-level security | Every current backend table has forced RLS and a backend-capability policy. `PUBLIC` has no table privileges. |
| Encrypt sensitive data | Optional bug-report contact email uses AES-256-GCM in PostgreSQL. Native offline reports use OS-backed secure storage. Session tokens are stored only as SHA-256 hashes. |
| Server-side auth | Every admin operation resolves its actor from a server session. Browser-supplied identity or role values are not trusted. |
| Record access | Content role, assignment, review, media, and release rules are checked server-side and inside Prisma transactions. Hidden media mutations are owner-only, and reviewer self-approval is blocked. |
| Field tampering | Public bug-report fields and diagnostics are allowlisted; status updates reject extra fields; public status/user IDs are ignored. Content input is normalized by domain services. |
| Secure cookies | Production uses `__Host-` cookies with `Secure`, `HttpOnly` for sessions, `SameSite=Strict`, no `Domain`, and `Path=/`. Mutations require a CSRF header. |
| Password hashing | Individual admin passwords use salted Node.js `scrypt`; no recoverable password is stored. Minimum length is 12 characters. |
| Login limiting | Per-IP and per-IP/account limits apply for 15-minute windows. Deploy one replica until limits move to shared storage or an edge rate limiter. |
| Bot protection | Public reports have minute/hour limits and a honeypot. Optional Cloudflare Turnstile verification is implemented server-side. Do not enable its secret until the client sends a challenge token. |
| Parameterized queries | Application data uses Prisma. Migration runners use parameterized `pg` calls where values are supplied. Static migration SQL is repository-controlled. |
| Validate input | JSON type, body size, text length, enum, email, UUID, URL, metadata, and diagnostics checks fail closed. Compressed API bodies are rejected. |
| Escape content | Admin UI database values are escaped before generated HTML; the bug console renders report text with `textContent`. Strict CSP blocks inline script. |
| Restrict uploads | No public binary upload endpoint exists. Media administration accepts bounded metadata and production HTTPS URLs only. |
| Trim API responses | Public report creation returns only ID, status, and creation time. Production health endpoints expose no database details. |
| Security headers | APIs/admin pages send CSP where applicable, HSTS, `nosniff`, frame denial, no-referrer, COOP, permissions policy, and no-store. Flutter web includes `web/_headers`. |
| Force HTTPS | Production APIs reject non-health HTTP requests with 426. Flutter release builds reject non-HTTPS API URLs. Android release forbids cleartext traffic. |
| Dependency scanning | CI runs npm audit, OSV source and container scans, Flutter analysis/tests, two full-history secret scans, and Dependabot for Actions, npm, and pub. |

RLS protects the databases from untrusted database roles. Collaborator-level row
access remains a server authorization rule because PostgreSQL sees one backend
runtime identity, not the editor's browser identity.

## Secret classification

Safe to publish in Flutter or web:

- `WUDASE_CONTENT_API_URL`
- `WUDASE_USER_APP_API_URL`
- a future Turnstile site key
- public media URLs

Server-only values:

- all runtime `*_DATABASE_URL` values
- all `*_MIGRATION_DATABASE_URL` values, used only in a trusted one-off
  migration process and never configured on a long-running web service
- `USER_APP_DATA_ENCRYPTION_KEY`
- one-off bootstrap emails and passwords; never keep them on a running service
- `USER_APP_TURNSTILE_SECRET_KEY`
- future object-storage write keys

Never commit or place in Flutter:

- PostgreSQL passwords
- Android `.jks` files or `android/key.properties`
- Apple `.p8`, certificates, or provisioning profiles
- encryption keys, session tokens, or admin passwords

Store production values in the host secret manager. Do not paste secrets into
issues, chat, build arguments, screenshots, or committed deployment files.

## Free local development

Required software:

- Flutter `3.27.2` for exact current reproducibility
- Node.js `22`; use `22.11+` before upgrading Prisma to v6
- PostgreSQL 16 or Docker Desktop
- Java 17 and Android Studio for Android
- Xcode on macOS for iOS builds

All are free for local development. Copy the templates to ignored files:

```powershell
Copy-Item backend/content/.env.example backend/content/.env
Copy-Item backend/user_app/.env.example backend/user_app/.env
node -e "console.log(require('node:crypto').randomBytes(32).toString('base64url'))"
```

Put the generated value in `USER_APP_DATA_ENCRYPTION_KEY`. Keep the same value
between restarts; losing it makes previously encrypted contact emails unreadable.
Configure these local databases on port `55432`:

- `wudase_sda_dev`
- `wudase_hagerigna_dev`
- `wudase_user_app_dev`

For the existing populated development databases:

```powershell
cd backend/content
npm.cmd ci
npm.cmd run db:generate
npm.cmd run db:deploy:env
npm.cmd run dev:env
```

In a second terminal:

```powershell
cd backend/user_app
npm.cmd ci
npm.cmd run db:generate
npm.cmd run db:deploy:env
npm.cmd run dev:env
```

Using `npm.cmd` avoids PowerShell's `npm.ps1` execution-policy problem. Local
URLs are `http://127.0.0.1:8787/admin/content`, `/admin/review`, and
`http://127.0.0.1:8790/admin/bug-reports`.

Run Flutter locally with explicit API URLs when needed:

```powershell
flutter run -d windows `
  --dart-define=WUDASE_CONTENT_API_URL=http://127.0.0.1:8787 `
  --dart-define=WUDASE_USER_APP_API_URL=http://127.0.0.1:8790
```

Use `10.0.2.2` instead of `127.0.0.1` for an Android emulator. A physical
device needs the computer's LAN address and firewall access during development.

## PostgreSQL runtime roles

Use a privileged provider/owner URL only for migrations. After migrations create
the capability roles, create separate login roles in the provider dashboard and
grant only the matching capability:

```sql
grant wudase_content_runtime to your_content_runtime_login;
grant wudase_user_runtime to your_user_runtime_login;
```

Use the content runtime login in both content runtime URLs if the databases are
in separate projects, or create one runtime login in each project and grant the
same capability there. Use the provider owner/migrator URL only in migration
variables. Never use the owner URL as an application runtime URL or store it in
the Render/Railway web-service environment. The tracked `start` commands run
only the servers; they cannot automatically migrate with runtime credentials.

Validate each database after migration:

```sql
select count(*) from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public' and c.relkind = 'r'
  and c.relrowsecurity and c.relforcerowsecurity;
```

Future migrations that add tables must also enable forced RLS and grant the
runtime role. Re-running the tracked security migration covers current tables,
but new migration files should include their own grants and policies.

## Content Studio remote preview

The current deployment phase is the collaborative editing platform only. See
`docs/content-studio-deployment.md` for the exact operating runbook.

Recommended preview stack:

1. GitHub hosts the repository and CI.
2. Two Neon Free projects hold SDA and Hagerigna data separately.
3. Render deploys the single content Docker service using `render.yaml`.
4. Cloudflare R2 is optional for audio and sheet-music objects.

The Flutter client, user/bug service, Cloudflare Pages, Turnstile, mobile signing,
and store accounts are intentionally deferred until the content release is final.

The repository's Railway files remain a supported alternative, but Railway's
current free plan becomes `$1/month` after its initial trial. Render's free web
services spin down and share a monthly hour allowance, so this stack is for
editing, testing, and stakeholder preview, not a reliable always-on production
service. A custom domain is optional; provider domains include managed HTTPS.

Render Blueprint setup:

1. Restore the content databases from a known backup before inviting editors.
2. From a trusted terminal, set the migration URLs temporarily and run
   `npm.cmd run db:deploy` in `backend/content` with `NODE_ENV=production`. Then
   run `npm.cmd run bootstrap:owner`. Clear the migration and bootstrap variables
   immediately.
3. Create runtime login roles, grant only their capability roles, and test the
   grants.
4. Connect the repository as a Render Blueprint using `render.yaml`.
5. Enter every `sync: false` runtime value in the dashboard. They are
   intentionally not present in Git.
6. Set allowed origins to exact HTTPS web origins, comma-separated. Never use `*`
   for credentialed admin traffic.
7. Start with one content-service replica.
8. Sign in and change the one-off bootstrap password. No bootstrap credential
   belongs in the Render service environment.
9. Create, download, and activate the first approved content release before
   building a production Flutter client.

Flutter web, Android, and iOS deployment steps remain valid for the later app
release, but they are not prerequisites for inviting the editorial team.

## Media policy

Binary uploads are currently disabled. This is safer than accepting arbitrary
files before storage validation exists. When remote media is enabled, use signed
server-side uploads with random object names, MIME sniffing, a strict audio/image
allowlist, size and pixel limits, malware scanning, and private write credentials.
Store only a public HTTPS read URL in content records.

Cloudflare R2's current free allowance is suitable for a small preview library,
but monitor operation counts and storage. Do not put R2 write keys in Flutter.

## Backups and incident response

- Back up both content databases before migrations, restores, large imports, or
  release activation.
- Download every activated immutable content release off-platform.
- Review admin audit events and failed-login/rate-limit logs.
- Rotate a leaked secret immediately before repairing Git history.
- If the repository scanner ever finds a real historical secret, coordinate a
  `git filter-repo` rewrite and force-push only after rotation and contributor
  notice. The current repository scan found no matching secret, so rewriting
  history now would create risk without a security benefit.

## Inputs still required for the editing platform

1. The GitHub repository available to Render.
2. Two hosted PostgreSQL databases with separate migration and runtime logins.
3. The final Render HTTPS service URL for the exact allowed origin.
4. The owner email, display name, and a unique one-off bootstrap password.
5. A decision on the HTTPS object host for audio and sheet music, if those files
   will be connected during this phase.

Flutter signing, user-data encryption, store accounts, privacy-policy URLs, and
mobile target updates are deferred until the catalog owner approves the final
content release.

Local development and web preview can be free. Public full-distribution Android
currently requires a one-time Google fee, and App Store distribution requires an
annual Apple membership unless the organization qualifies for a waiver.
