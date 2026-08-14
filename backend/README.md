# Wudase Backend

This folder contains the planned backend database foundation.

## Services

- `content/`: content catalog, lyrics, categories, reusable sheet music/audio metadata, and content releases.
- `user_app/`: accounts or anonymous users, favorites, history, settings sync, reports, and app configuration.

For security boundaries, secrets, RLS role setup, free preview hosting, and the
production checklist, see `docs/security-deployment.md`.

## ORM

Use Prisma ORM for both backend services:

- `backend/content/prisma/schema.prisma`
- `backend/user_app/prisma/schema.prisma`

Each service has its own Prisma client and database URL so it can be deployed separately.

## PostgreSQL Setup Order

Run the content backend schema once per content database.

For the SDA Hymnal content database:

```powershell
cd backend/content
npm install
npm run db:generate
cd ../..
psql $env:SDA_HYMNAL_DATABASE_URL -f backend/content/schema.sql
dart tool/export_postgres_seed.dart
psql $env:SDA_HYMNAL_DATABASE_URL -f backend/content/seed_sda_hymnal.sql
```

For the Hagerigna content database:

```powershell
psql $env:HAGERIGNA_DATABASE_URL -f backend/content/schema.sql
dart tool/export_postgres_seed.dart
psql $env:HAGERIGNA_DATABASE_URL -f backend/content/seed_hagerigna.sql
```

For the user/app backend:

```powershell
cd backend/user_app
npm install
npm run db:generate
cd ../..
psql $env:USER_APP_DATABASE_URL -f backend/user_app/schema.sql
```

The raw SQL files remain useful for PostgreSQL-specific constraints, extensions, views, and first database bootstrap. Prisma is the application access layer.

## Content API

The Flutter app connects to PostgreSQL through the content API, not directly to the database.

For local development, start PostgreSQL and load the content seeds, then run:

```powershell
$env:SDA_HYMNAL_DATABASE_URL='postgresql://postgres@localhost:55432/wudase_sda_dev'
$env:HAGERIGNA_DATABASE_URL='postgresql://postgres@localhost:55432/wudase_hagerigna_dev'
cd backend/content
npm run dev
```

The API listens on `http://127.0.0.1:8787` by default.

## Wudase Content Studio

The content backend includes a collaborative staging editor for every SDA
hymnal and the separate Hagerigna database:

```powershell
$env:SDA_HYMNAL_DATABASE_URL='postgresql://postgres@localhost:55432/wudase_sda_dev'
$env:HAGERIGNA_DATABASE_URL='postgresql://postgres@localhost:55432/wudase_hagerigna_dev'
$env:CONTENT_BOOTSTRAP_OWNER_EMAIL='owner@wudase.local'
$env:CONTENT_BOOTSTRAP_OWNER_PASSWORD='choose-a-unique-strong-password'
$env:CONTENT_BOOTSTRAP_OWNER_NAME='Wudase Owner'
cd backend/content
npm run db:generate
npm.cmd run db:deploy
npm.cmd run dev
```

Open `http://127.0.0.1:8787/admin/content` and sign in with the owner email and
password. The bootstrap variables create the first owner only when no account
exists; changing them later does not reset an existing password. Use **Team
workspace > My account** to change your password.

The old shared `CONTENT_ADMIN_TOKEN` is available only for explicit local
recovery when `ALLOW_LEGACY_CONTENT_ADMIN=true`. Production startup rejects this
mode because shared tokens cannot produce trustworthy per-person audit history.

The studio manages:

- one canonical song (`works`) containing the shared title and lyrics;
- lightweight hymnal memberships (`book_entries`) containing the number and
  availability, with optional overrides only when an edition truly differs;
- any number of database-defined SDA hymnals, including the 1960, 1974, and 2004 books;
- Hagerigna songs in the separate Hagerigna database;
- reusable audio and sheet-music metadata attached once to the canonical song;
- creation of a future hymnal either empty or with reusable memberships copied
  from an existing edition;
- included/not-included filters for composing a new hymnal and removing songs
  without deleting their canonical content;
- safe merging of complementary duplicate records;
- an audit trail of content and media changes.

### Collaboration and review

Use one account per contributor:

- **Owner** manages hymnals, accounts, assignments, reviews, and releases.
- **Reviewer** independently inspects submissions, comments, approves or returns
  work, and manages reusable audio and sheet-music connections.
- **Editor** edits only songs covered by an active assignment.

Reviewers use the separate `/admin/review` console and cannot edit titles,
lyrics, notes, or hymnal memberships. A person who edited or submitted a
revision cannot approve that same revision. This preserves an independent
editorial decision before the owner creates and activates a production release.

Media is intentionally absent from Content Studio. Reviewer and owner accounts
search the canonical song library and add, edit, inspect, or remove shared audio,
sheet-music, and image URLs from the Review Console's **Media connections**
workspace. Editors cannot call the media mutation endpoints. Every media change
is audited and remains independent from the exact submitted lyrics revision.

The operating flow is:

1. The owner creates individual Editor and Reviewer accounts in **Team > Team accounts**.
2. The owner assigns each editor a catalog, hymnal, category, and/or number range.
3. The editor saves a draft and submits it from the song's **Workflow** tab.
4. The reviewer signs in at `/admin/review`, compares the approved baseline with
   the exact submitted revision, adds comments, then approves it or requests changes.
5. The reviewer connects reusable audio and sheet music to the canonical song in
   **Media connections**; one link is reused by every hymnal membership.
6. After every changed song is approved and media is checked, the owner creates,
   downloads, and activates an immutable release. Only that release reaches
   Flutter in production mode.

The Review Console's **Account** action lets reviewers change their own password;
the owner does not need to share or retain contributor passwords.

Assignments can target a catalog, hymnal API key, SDA category, hymn-number
range, or a combination of those fields. Every edited song moves through:

`Draft -> Submitted -> Approved`

A reviewer can return a submission to `Changes requested`; the reason is kept
with the song discussion. Submitted songs are locked. Existing imported songs
are treated as approved baseline content until their first edit. Optimistic
timestamps still reject a stale browser with HTTP 409.

The browser never receives PostgreSQL credentials. It talks only to validated
admin endpoints, and audit identities come from the authenticated server
session rather than a name supplied by the browser.

### Releases and Flutter

In local development, `CONTENT_PUBLIC_MODE=live` keeps the current fast preview
behavior. For a deployed service, set `CONTENT_PUBLIC_MODE=release`. The public
Flutter endpoints then read only the active immutable release, so collaborator
drafts cannot leak into the app.

An owner creates a release in **Team workspace > Releases**. Release creation
is blocked while any edited song is not approved. Each downloadable ZIP has:

- `manifest.json` with SHA-256 checksums and record counts;
- API-shaped version, hymn, and category JSON files;
- `media/manifest.json` with reusable audio/sheet-music keys and metadata;
- a short release README.

Activate a release to publish it. Activating an older immutable release is a
safe rollback. The deployed API URL reaches Flutter through:

```powershell
flutter build apk --dart-define=WUDASE_CONTENT_API_URL=https://content.example.org
flutter build web --dart-define=WUDASE_CONTENT_API_URL=https://content.example.org
```

To download a release from a terminal, obtain your current session token from a
trusted API client and run:

```powershell
npm run release:download -- https://content.example.org RELEASE_ID SESSION_TOKEN .\release.zip
```

Prefer the browser's **Download ZIP** action; it avoids putting a session token
in shell history.

Production release mode deliberately returns HTTP 503 from the public content
endpoints until an owner creates and activates the first release. After the
initial database restore, sign in, confirm that the review queue has no drafts,
create the first release, download its ZIP as an off-platform copy, and activate
it before pointing a Flutter build at the hosted URL.

### Remote deployment

The repository includes Render and Railway configuration plus a non-root Node 22
Docker image. `render.yaml` deploys only the collaborative editing platform for
the current phase. Create one content web service plus two PostgreSQL databases.
The Flutter app and user/bug service can be deployed later without changing this
editorial workflow. Configure only least-privileged runtime variables on the web
service:

```text
NODE_ENV=production
SDA_HYMNAL_DATABASE_URL=<private SDA PostgreSQL URL>
HAGERIGNA_DATABASE_URL=<private Hagerigna PostgreSQL URL>
CONTENT_PUBLIC_MODE=release
ALLOW_LEGACY_CONTENT_ADMIN=false
CONTENT_ALLOWED_ORIGINS=https://content.example.org
CONTENT_TRUST_PROXY=true
CONTENT_FORCE_HTTPS=true
```

Keep both database services private. Production startup deliberately does not
run migrations and never receives a privileged database owner URL. From a
trusted maintainer machine, set both `*_MIGRATION_DATABASE_URL` values, run
`npm.cmd run db:deploy`, then run `npm.cmd run bootstrap:owner`. Remove those
privileged URLs from the shell afterward. For an existing catalog, use
`scripts/backup-content.ps1` and `scripts/restore-content.ps1` to move both
databases to their hosted copies. Take a provider snapshot before every restore
and before large editorial imports.

Run one web-service replica unless login throttling is moved to a shared store.
The database enforces roles, assignments, review state, audit history, and
release immutability across replicas, while the lightweight failed-login limit
is intentionally kept in one process. Configure an additional login rate limit
at the hosting firewall or identity proxy before inviting contributors.
Set `CONTENT_TRUST_PROXY=true` only when the service is behind a trusted hosting
proxy that replaces `X-Forwarded-For`, `X-Forwarded-Host`, and
`X-Forwarded-Proto`; leave it false for direct local or public connections.

For another defense layer, protect `/admin/*` and `/api/admin/*` with an
identity-aware proxy such as Cloudflare Access while leaving `/api/hymns`,
`/api/versions`, `/api/categories`, and `/health` public.

The recommended future-hymnal workflow is:

1. Open **Manage hymnals** and create a draft API key such as `sda_2019`.
2. Start empty, or reuse the 2004 membership list as a working baseline.
3. Filter that hymnal by **Included** or **Not in hymnal**.
4. Change numbers, remove omitted songs, reuse existing songs, and create
   canonical records only for genuinely new songs.
5. Change the hymnal status to **Published** when it is ready.

`GET /api/versions` lists published editions. Any database-defined SDA API key
also works with `GET /api/hymns?language=am&version=<version_key>`. The legacy
`hymnal` alias continues to resolve to `sda_new`.

The editor never connects from a browser directly to PostgreSQL. Its protected
admin API performs validated Prisma transactions. In release mode, public
Flutter API responses change only after an owner activates an approved release.

Flutter fetches the public content API on launch, hymnal changes, and whenever
the app returns to the foreground. If the content service is unavailable, the
app keeps working from its bundled fallback, so local editing must run the
content service on the URL supplied through `WUDASE_CONTENT_API_URL`.

The Settings version selector also reads `GET /api/versions`. A newly created
hymnal appears automatically after it is published in Content Studio and the
app is reopened or resumed. Database-only editions intentionally have no
unrelated local fallback: if their API is unavailable, the app reports that
content is unavailable instead of displaying songs from another hymnal.

Apply all additive Content Studio migrations to existing databases through the
tracked migration runner:

```powershell
cd backend/content
npm.cmd run db:deploy
```

The runner uses a PostgreSQL advisory lock, records each applied file, sends
shared catalog migrations to both databases, and keeps collaboration control
tables in the SDA database only.

For a fresh database, apply `schema.sql`, load the seed, then run
`20260720_canonical_song_library.sql` once to collapse identical imported
edition text into canonical inheritance.

Useful checks:

```powershell
Invoke-RestMethod http://localhost:8787/health
Invoke-RestMethod 'http://localhost:8787/api/hymns?language=am&version=hymnal'
Invoke-RestMethod 'http://localhost:8787/api/hymns?language=am&version=sda_1960'
Invoke-RestMethod 'http://localhost:8787/api/hymns?language=am&version=hagerigna'
Invoke-RestMethod 'http://localhost:8787/api/versions'
```

Flutter uses `http://localhost:8787` on desktop/web and `http://10.0.2.2:8787` on Android emulator. Override it with:

```powershell
flutter run -d windows --dart-define=WUDASE_CONTENT_API_URL=http://localhost:8787
```

The old local Drift content database migration is disabled by default because the content API is now the primary source. To test the local content database fallback explicitly, run Flutter with:

```powershell
flutter run -d windows --dart-define=WUDASE_ENABLE_LOCAL_CONTENT_DB=true
```

## User App and Bug Reports

The user backend accepts public bug reports and exposes a separate protected
review console at `/admin/bug-reports`. It uses individual administrator
accounts, HttpOnly cookie sessions, CSRF protection, rate limits, bounded public
payloads, encrypted contact emails, and an audited status workflow.

For local development, configure `backend/user_app/.env`, then run:

```powershell
cd backend/user_app
npm.cmd ci
npm.cmd run db:generate
npm.cmd run db:deploy:env
npm.cmd run dev:env
```

Set Flutter's release endpoint with
`--dart-define=WUDASE_USER_APP_API_URL=https://user.example.org`. Do not put a
database URL, encryption key, or administrator credential in Flutter.

## Current JSON Import

The current Flutter JSON files are column-based resource arrays. The exporter reads those named arrays and converts them into normalized relational rows.

Generated seed files:

- `backend/content/seed_sda_hymnal.sql`
- `backend/content/seed_hagerigna.sql`

Expected entry counts:

- SDA new hymnal: 325 book entries in the SDA database
- SDA old hymnal: 294 book entries in the SDA database
- Hagerigna: 121 book entries in the Hagerigna database

The SDA exporter also imports sheet music from `assets/sheet_music` into `media_assets` and links it to reusable SDA works through `media_links`.

Sheet music naming rules:

- `number.webp` means one sheet-music image for that new hymnal number.
- `number_L.webp` and `number_R.webp` mean left/right sheet-music pages for that new hymnal number.
- `number1,number2_L.webp` links the same sheet-music asset to both hymn works.

The backend stores professional asset keys such as `sda-hymnal/sheet-music/8/left.webp` while preserving the original app asset path in metadata.

## Old/New SDA Hymnal Numbers

SDA old and new hymnal numbers are stored in the same SDA content database as version-specific `book_entries`.

For API/read convenience, `backend/content/schema.sql` also defines:

- `sda_hymnal_number_map`
- `sda_hymnal_songs`
- `sda_hymnal_sheet_music`

Those views expose one row per reusable work with:

- `new_hymnal_number`
- `old_hymnal_number`
- `match_status`
- old/new entry IDs and lyrics in `sda_hymnal_songs`
- sheet-music asset paths and storage metadata in `sda_hymnal_sheet_music`

The seed exporter also writes both numbers into SDA entry metadata when known.

Similar songs in the old and new SDA editions are reused through one shared `works` row. The importer first matches by normalized English title plus normalized lyrics. If that is not available, it matches by title only when the title is unique in both editions.

When a song exists in one SDA edition but cannot be matched to the other edition, the exporter writes a row to:

- `content_import_issues`

Those rows are review warnings, not fatal migration failures, because the current source data may legitimately contain songs that exist only in one edition.

In Prisma Studio, inspect `SdaHymnalSong` for the unique merged SDA song list and `SdaHymnalSheetMusic` for sheet music. `BookEntry` intentionally contains separate old/new edition rows, so its count is higher.

Hagerigna uses its own content database. It does not share `works` rows with SDA unless a future import process explicitly links cross-book songs.
