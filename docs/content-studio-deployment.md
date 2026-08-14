# Content Studio Deployment

This is the deployment target for the current editorial phase. It hosts the
Content Studio, Review Console, and content API only. Flutter and the user/bug
service remain local until the catalog and media library are approved.

## Architecture

```text
Editors -> /admin/content ----\
                                Wudase content service -> SDA PostgreSQL
Reviewers -> /admin/review ---/                       -> Hagerigna PostgreSQL
Owner -> review + immutable release
```

Use one hosted content service, one SDA database, and one Hagerigna database.
The admin browser never receives a database URL. Audio and sheet-music objects
stay in object storage; the database stores validated HTTPS links and metadata.

## Roles and final authority

- Editors can change only songs covered by an active assignment and submit them.
- Reviewers cannot change lyrics or hymnal memberships. They compare revisions,
  request changes or approve, and manage reusable media connections.
- The owner creates accounts and assignments, inspects the completed catalog,
  then creates and activates the immutable final release.
- A contributor cannot approve a lyrics revision that they edited or submitted.
- Only an owner can publish, download, activate, or roll back a release.

## Accounts needed now

1. A GitHub account containing this private repository.
2. A managed PostgreSQL provider account with two databases or projects.
3. A Render account for one Docker web service created from `render.yaml`.
4. A password manager for database credentials and the initial owner password.
5. Optional object storage for audio and sheet music. Cloudflare R2 is suitable;
   uploading can also be deferred while reviewers paste existing HTTPS URLs.

No Flutter signing key, Play Console account, Apple account, Flutter web host,
user database, Turnstile key, or mobile API configuration is needed in this
phase.

### Current free-tier limits

Verified against provider documentation on 2026-08-14:

- Neon Free currently includes 0.5 GB storage and 100 CU-hours per project. Two
  projects keep SDA and Hagerigna isolated and within separate allowances.
- Render Free supplies 750 service hours per workspace each month. One service
  fits that allowance, but it sleeps after 15 idle minutes and can take about a
  minute to wake. Its filesystem is ephemeral, which is why no database or
  uploaded media is stored inside the container.
- Cloudflare R2 Standard currently includes 10 GB-month storage, one million
  Class A operations, ten million Class B operations, and free egress monthly.
  R2 still requires enabling an R2 subscription and usage beyond the allowance
  can be billed.

Provider terms can change. Recheck the official [Neon pricing](https://neon.com/pricing),
[Render Free documentation](https://render.com/docs/free), and
[Cloudflare R2 pricing](https://developers.cloudflare.com/r2/pricing/) before
creating the hosted resources.

## Database preparation

Create separate privileged migration and least-privileged runtime logins for
each database. Never put a migration URL in Render.

On a trusted maintainer machine, configure temporary environment variables:

```powershell
$env:NODE_ENV='production'
$env:SDA_HYMNAL_MIGRATION_DATABASE_URL='<SDA owner URL>'
$env:HAGERIGNA_MIGRATION_DATABASE_URL='<Hagerigna owner URL>'
$env:SDA_HYMNAL_DATABASE_URL='<SDA runtime URL>'
$env:HAGERIGNA_DATABASE_URL='<Hagerigna runtime URL>'
$env:CONTENT_BOOTSTRAP_OWNER_EMAIL='<owner email>'
$env:CONTENT_BOOTSTRAP_OWNER_PASSWORD='<unique password of at least 12 characters>'
$env:CONTENT_BOOTSTRAP_OWNER_NAME='<owner display name>'

Set-Location D:\Church\App\amharic_hymnal_app\backend\content
npm.cmd ci
npm.cmd run db:deploy
npm.cmd run bootstrap:owner
```

Owner bootstrap prefers the least-privileged SDA runtime URL. The migration URL
is accepted only as a maintainer fallback and is never configured in Render.

The migration creates the `wudase_content_runtime` capability role, revokes
`PUBLIC` access, and forces row-level security. Grant that capability role to
each provider-created runtime login before using its URL in Render:

```sql
grant wudase_content_runtime to "YOUR_RUNTIME_LOGIN" with inherit true;
grant wudase_content_runtime to "YOUR_RUNTIME_LOGIN" with set false;
grant wudase_content_runtime to "YOUR_RUNTIME_LOGIN" with admin false;
```

The explicit PostgreSQL 18 membership options let the login inherit only the
runtime privileges while preventing `SET ROLE` and delegated membership grants.

Clear privileged values after migration and store them only in the password
manager:

```powershell
Remove-Item Env:SDA_HYMNAL_MIGRATION_DATABASE_URL
Remove-Item Env:HAGERIGNA_MIGRATION_DATABASE_URL
Remove-Item Env:CONTENT_BOOTSTRAP_OWNER_PASSWORD
```

When moving the existing local catalog, first run `scripts/backup-content.ps1`,
restore both dumps with `scripts/restore-content.ps1` using privileged hosted
URLs, and then rerun `npm.cmd run db:deploy`. The RLS migration is repeatable by
design, so every deployment restores the runtime grants and policies omitted by
the privilege-free database archives.

## Render service

Create the Blueprint from the repository's `render.yaml`. Configure only:

```text
SDA_HYMNAL_DATABASE_URL=<least-privileged SDA runtime URL>
HAGERIGNA_DATABASE_URL=<least-privileged Hagerigna runtime URL>
CONTENT_ALLOWED_ORIGINS=https://YOUR-RENDER-SERVICE.onrender.com
```

The tracked Blueprint already fixes production mode, release-only public data,
HTTPS enforcement, proxy trust, disabled legacy tokens, and the health check.
Do not add bootstrap passwords or migration URLs to the service.

After deployment, verify:

```text
https://YOUR-RENDER-SERVICE.onrender.com/health
https://YOUR-RENDER-SERVICE.onrender.com/admin/content
https://YOUR-RENDER-SERVICE.onrender.com/admin/review
```

## Team workflow

1. Sign in as owner and immediately change the bootstrap password.
2. Create one account per colleague. Never share accounts.
3. Create narrow assignments by catalog, edition, category, and number range.
4. Editors save drafts and submit exact revisions.
5. Reviewers compare, comment, return, or approve each revision.
6. Reviewers use **Media connections** to link shared audio and sheet music once
   to the canonical song. Old, current, and future hymnal memberships reuse it.
7. The owner checks the review queue, media links, counts, and audit activity.
8. The owner creates and downloads a release ZIP as an off-platform backup.
9. The owner activates the release only when the editorial project is complete.
10. Flutter deployment begins later using that active immutable release.

## Media rules

- Prefer HTTPS object URLs with non-guessable write credentials kept server-side.
- Never put object-storage write keys in Flutter or in a public URL.
- Prefer WebP/AVIF for sheet-music images and compressed accompaniment audio.
- Record MIME type, byte size, SHA-256 checksum, page label, and ordering.
- The backend accepts links and metadata, not arbitrary browser file uploads.
  This removes executable upload and disk-exhaustion risk from the free service.
- Editors cannot add or alter media. Reviewer and owner actions are audited.

## Backups and completion

Take database dumps before bulk imports, merges, and final release activation.
Keep the release ZIP outside the hosting provider. The editing phase is complete
only when every changed song is approved, all media links open successfully, the
owner has downloaded the final release, and the active release API passes its
smoke checks.
