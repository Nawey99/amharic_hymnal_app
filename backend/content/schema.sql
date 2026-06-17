-- Wudase Content Backend PostgreSQL schema
-- Owns public worship content, reusable media metadata, and content releases.

create extension if not exists pgcrypto;
create extension if not exists unaccent;

create table if not exists languages (
  code text primary key,
  native_name text not null,
  english_name text not null,
  script_code text not null default 'Ethi',
  direction text not null default 'ltr' check (direction in ('ltr', 'rtl')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists books (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  language_code text not null references languages(code),
  title text not null,
  subtitle text,
  book_type text not null check (book_type in ('hymnal', 'songbook', 'collection')),
  source_note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists book_editions (
  id uuid primary key default gen_random_uuid(),
  book_id uuid not null references books(id) on delete cascade,
  slug text not null unique,
  title text not null,
  edition_type text not null default 'primary',
  sort_order integer not null default 0,
  source_note text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists categories (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  language_code text not null references languages(code),
  name text not null,
  english_name text,
  description text,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists works (
  id uuid primary key default gen_random_uuid(),
  canonical_key text not null unique,
  primary_language_code text not null references languages(code),
  default_title text not null,
  default_english_title text,
  normalized_title text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists book_entries (
  id uuid primary key default gen_random_uuid(),
  edition_id uuid not null references book_editions(id) on delete cascade,
  work_id uuid not null references works(id) on delete restrict,
  entry_number integer not null,
  title text not null,
  english_title text,
  lyrics text not null default '',
  category_id uuid references categories(id) on delete set null,
  source_key text not null,
  source_index integer not null,
  metadata jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (edition_id, entry_number),
  unique (edition_id, source_key, source_index)
);

create table if not exists media_assets (
  id uuid primary key default gen_random_uuid(),
  media_type text not null check (media_type in ('sheet_music', 'audio', 'image')),
  storage_provider text not null default 'external',
  storage_key text not null,
  public_url text,
  mime_type text not null,
  file_size_bytes bigint,
  checksum_sha256 text,
  page_label text,
  duration_seconds integer,
  width_px integer,
  height_px integer,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (storage_provider, storage_key)
);

create table if not exists media_links (
  id uuid primary key default gen_random_uuid(),
  media_asset_id uuid not null references media_assets(id) on delete cascade,
  work_id uuid references works(id) on delete cascade,
  book_entry_id uuid references book_entries(id) on delete cascade,
  relation_type text not null check (
    relation_type in (
      'primary_sheet_music',
      'alternate_sheet_music',
      'primary_audio',
      'alternate_audio',
      'thumbnail'
    )
  ),
  sort_order integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (
    (work_id is not null and book_entry_id is null)
    or
    (work_id is null and book_entry_id is not null)
  )
);

create table if not exists content_releases (
  id uuid primary key default gen_random_uuid(),
  release_key text not null unique,
  version_label text not null,
  description text,
  published_at timestamptz,
  is_current boolean not null default false,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_books_language on books(language_code);
create index if not exists idx_book_editions_book on book_editions(book_id);
create index if not exists idx_book_entries_edition_number on book_entries(edition_id, entry_number);
create index if not exists idx_book_entries_work on book_entries(work_id);
create index if not exists idx_book_entries_category on book_entries(category_id);
create index if not exists idx_works_language on works(primary_language_code);
create index if not exists idx_media_assets_type on media_assets(media_type);
create index if not exists idx_media_links_work on media_links(work_id);
create index if not exists idx_media_links_book_entry on media_links(book_entry_id);

create or replace view catalog_entries as
select
  l.code as language_code,
  b.slug as book_slug,
  b.title as book_title,
  be.slug as edition_slug,
  be.title as edition_title,
  e.id as entry_id,
  e.entry_number,
  e.title,
  e.english_title,
  e.lyrics,
  w.id as work_id,
  w.canonical_key,
  c.slug as category_slug,
  c.name as category_name
from book_entries e
join book_editions be on be.id = e.edition_id
join books b on b.id = be.book_id
join languages l on l.code = b.language_code
join works w on w.id = e.work_id
left join categories c on c.id = e.category_id;

