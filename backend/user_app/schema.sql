-- Wudase User/App Backend PostgreSQL schema
-- Owns user state, sync, reports, and app configuration.

create extension if not exists pgcrypto;

create table if not exists app_users (
  id uuid primary key default gen_random_uuid(),
  auth_provider text not null default 'anonymous',
  provider_subject text,
  display_name text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz,
  unique (auth_provider, provider_subject)
);

create table if not exists devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete cascade,
  install_id text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web', 'windows', 'macos', 'linux', 'unknown')),
  app_version text,
  locale text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_seen_at timestamptz
);

create table if not exists user_favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete cascade,
  content_entry_id uuid not null,
  content_work_id uuid,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, content_entry_id)
);

create table if not exists user_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references app_users(id) on delete cascade,
  content_entry_id uuid not null,
  content_work_id uuid,
  viewed_at timestamptz not null default now(),
  listen_position_seconds integer,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists user_settings (
  user_id uuid primary key references app_users(id) on delete cascade,
  selected_language_code text not null default 'am',
  selected_book_slug text,
  selected_edition_slug text,
  theme_mode text not null default 'system' check (theme_mode in ('system', 'light', 'dark')),
  font_scale numeric(4, 2) not null default 1.00,
  keep_screen_on boolean not null default false,
  background_image_enabled boolean not null default true,
  data_collection_enabled boolean not null default true,
  settings jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

create table if not exists lyric_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete set null,
  device_id uuid references devices(id) on delete set null,
  content_entry_id uuid,
  content_work_id uuid,
  reported_text text,
  suggested_text text,
  note text,
  status text not null default 'open' check (status in ('open', 'reviewing', 'accepted', 'rejected', 'duplicate')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists bug_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references app_users(id) on delete set null,
  device_id uuid references devices(id) on delete set null,
  title text not null,
  description text not null,
  severity text not null default 'normal' check (severity in ('low', 'normal', 'high', 'critical')),
  status text not null default 'open' check (status in ('open', 'reviewed', 'resolved')),
  app_version text,
  platform text,
  diagnostics jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

update bug_reports
set status = case
  when status in ('fixed', 'closed') then 'resolved'
  when status in ('reviewing', 'duplicate') then 'reviewed'
  when status in ('open', 'reviewed', 'resolved') then status
  else 'open'
end
where status not in ('open', 'reviewed', 'resolved');

alter table if exists bug_reports
  drop constraint if exists bug_reports_status_check;

alter table if exists bug_reports
  add constraint bug_reports_status_check
  check (status in ('open', 'reviewed', 'resolved'));

create table if not exists app_config (
  key text primary key,
  value jsonb not null,
  description text,
  updated_at timestamptz not null default now()
);

create index if not exists idx_devices_user on devices(user_id);
create index if not exists idx_user_favorites_user_sort on user_favorites(user_id, sort_order);
create index if not exists idx_user_history_user_viewed on user_history(user_id, viewed_at desc);
create index if not exists idx_lyric_reports_status on lyric_reports(status, created_at);
create index if not exists idx_bug_reports_status on bug_reports(status, created_at);
