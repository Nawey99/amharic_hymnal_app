-- Collaboration control plane for Wudase Content Studio.
-- Apply this migration to the SDA database only. Song content remains split
-- between the SDA and Hagerigna databases; this database stores shared users,
-- assignments, review state, comments, and immutable release snapshots.

begin;

create table if not exists content_users (
  id uuid primary key default gen_random_uuid(),
  email text not null unique,
  display_name text not null,
  role text not null default 'editor'
    check (role in ('owner', 'reviewer', 'editor')),
  password_hash text not null,
  is_active boolean not null default true,
  last_login_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_content_users_role_active
  on content_users(role, is_active);

create table if not exists content_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references content_users(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  last_seen_at timestamptz not null default now(),
  revoked_at timestamptz,
  user_agent text,
  ip_address text,
  created_at timestamptz not null default now()
);

create index if not exists idx_content_sessions_user_expiry
  on content_sessions(user_id, expires_at);
create index if not exists idx_content_sessions_expiry_revoked
  on content_sessions(expires_at, revoked_at);

create table if not exists content_assignments (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  instructions text,
  catalog text not null check (catalog in ('sda', 'hagerigna')),
  version_key text,
  category_slug text,
  start_number integer,
  end_number integer,
  assignee_id uuid not null references content_users(id) on delete restrict,
  created_by_id uuid not null references content_users(id) on delete restrict,
  status text not null default 'active'
    check (status in ('active', 'completed', 'cancelled')),
  due_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (start_number is null or start_number > 0),
  check (end_number is null or end_number > 0),
  check (
    start_number is null
    or end_number is null
    or start_number <= end_number
  )
);

create index if not exists idx_content_assignments_assignee_status
  on content_assignments(assignee_id, status);
create index if not exists idx_content_assignments_scope
  on content_assignments(catalog, version_key, status);

create table if not exists content_workflows (
  id uuid primary key default gen_random_uuid(),
  catalog text not null check (catalog in ('sda', 'hagerigna')),
  work_id uuid not null,
  status text not null default 'draft'
    check (status in ('draft', 'submitted', 'changes_requested', 'approved')),
  revision integer not null default 1 check (revision > 0),
  updated_by_id uuid references content_users(id) on delete set null,
  submitted_by_id uuid references content_users(id) on delete set null,
  submitted_at timestamptz,
  reviewed_by_id uuid references content_users(id) on delete set null,
  reviewed_at timestamptz,
  review_summary text,
  approved_revision integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (catalog, work_id)
);

create index if not exists idx_content_workflows_queue
  on content_workflows(catalog, status, updated_at desc);

create table if not exists content_comments (
  id uuid primary key default gen_random_uuid(),
  catalog text not null check (catalog in ('sda', 'hagerigna')),
  work_id uuid not null,
  user_id uuid not null references content_users(id) on delete restrict,
  body text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_content_comments_work
  on content_comments(catalog, work_id, created_at);

alter table content_releases
  add column if not exists schema_version integer not null default 1,
  add column if not exists created_by_id uuid references content_users(id) on delete set null,
  add column if not exists created_by_name text not null default 'system',
  add column if not exists checksum_sha256 text,
  add column if not exists manifest jsonb not null default '{}'::jsonb,
  add column if not exists bundle jsonb not null default '{}'::jsonb;

create unique index if not exists idx_content_releases_current
  on content_releases(is_current)
  where is_current;

commit;
