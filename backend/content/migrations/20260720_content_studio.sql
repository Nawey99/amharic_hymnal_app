-- Additive migration for the Wudase Content Studio.
-- Run this once against both the SDA and Hagerigna content databases.

begin;

create table if not exists content_audit_logs (
  id uuid primary key default gen_random_uuid(),
  catalog text not null check (catalog in ('sda', 'hagerigna')),
  action text not null check (
    action in (
      'create',
      'update',
      'merge',
      'media_add',
      'media_update',
      'media_remove'
    )
  ),
  entity_type text not null,
  entity_id uuid,
  work_id uuid,
  actor text not null,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_content_audit_logs_catalog_created
  on content_audit_logs(catalog, created_at desc);
create index if not exists idx_content_audit_logs_work_created
  on content_audit_logs(work_id, created_at desc);

commit;
