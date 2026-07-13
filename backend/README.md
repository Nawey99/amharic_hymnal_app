# Wudase Backend

This folder contains the planned backend database foundation.

## Services

- `content/`: content catalog, lyrics, categories, reusable sheet music/audio metadata, and content releases.
- `user_app/`: accounts or anonymous users, favorites, history, settings sync, reports, and app configuration.

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

Useful checks:

```powershell
Invoke-RestMethod http://localhost:8787/health
Invoke-RestMethod 'http://localhost:8787/api/hymns?language=am&version=hymnal'
Invoke-RestMethod 'http://localhost:8787/api/hymns?language=am&version=hagerigna'
```

Flutter uses `http://localhost:8787` on desktop/web and `http://10.0.2.2:8787` on Android emulator. Override it with:

```powershell
flutter run -d windows --dart-define=WUDASE_CONTENT_API_URL=http://localhost:8787
```

The old local Drift content database migration is disabled by default because the content API is now the primary source. To test the local content database fallback explicitly, run Flutter with:

```powershell
flutter run -d windows --dart-define=WUDASE_ENABLE_LOCAL_CONTENT_DB=true
```

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
