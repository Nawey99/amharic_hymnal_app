# Wudase Backend

This folder contains the planned backend database foundation.

## Services

- `content/`: content catalog, lyrics, categories, reusable sheet music/audio metadata, and content releases.
- `user_app/`: accounts or anonymous users, favorites, history, settings sync, reports, and app configuration.

## PostgreSQL Setup Order

Run the content backend files in this order:

```powershell
psql $env:DATABASE_URL -f backend/content/schema.sql
dart tool/export_postgres_seed.dart
psql $env:DATABASE_URL -f backend/content/seed_from_current_json.sql
```

Run the user/app backend schema separately against the user/app database:

```powershell
psql $env:USER_APP_DATABASE_URL -f backend/user_app/schema.sql
```

## Current JSON Import

The current Flutter JSON files are column-based resource arrays. The exporter reads those named arrays and converts them into normalized relational rows:

- SDA new hymnal: 325 book entries
- SDA old hymnal: 294 book entries
- Hagerigna: 121 book entries

The exporter does not invent media rows. Sheet music and audio should be added as real `media_assets` and linked through `media_links`.

