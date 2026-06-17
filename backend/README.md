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

## Current JSON Import

The current Flutter JSON files are column-based resource arrays. The exporter reads those named arrays and converts them into normalized relational rows.

Generated seed files:

- `backend/content/seed_sda_hymnal.sql`
- `backend/content/seed_hagerigna.sql`

Expected entry counts:

- SDA new hymnal: 325 book entries in the SDA database
- SDA old hymnal: 294 book entries in the SDA database
- Hagerigna: 121 book entries in the Hagerigna database

The exporter does not invent media rows. Sheet music and audio should be added as real `media_assets` and linked through `media_links`.

## Old/New SDA Hymnal Numbers

SDA old and new hymnal numbers are stored in the same SDA content database as version-specific `book_entries`.

For API/read convenience, `backend/content/schema.sql` also defines:

- `sda_hymnal_number_map`

That view exposes one row per reusable work with:

- `new_hymnal_number`
- `old_hymnal_number`
- `match_status`

The seed exporter also writes both numbers into SDA entry metadata when known.

Similar songs in the old and new SDA editions are reused through one shared `works` row. The importer matches them by normalized English title first, then normalized Amharic title when the English title differs or has source typos.

When a song exists in one SDA edition but cannot be matched to the other edition, the exporter writes a row to:

- `content_import_issues`

Those rows are review warnings, not fatal migration failures, because the current source data may legitimately contain songs that exist only in one edition.

Hagerigna uses its own content database. It does not share `works` rows with SDA unless a future import process explicitly links cross-book songs.
