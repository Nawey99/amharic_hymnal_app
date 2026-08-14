-- Operational audit trail for collaboration and release management.
-- Apply to the SDA control database only.

begin;

create table if not exists content_activity_logs (
  id uuid primary key default gen_random_uuid(),
  action text not null,
  actor_user_id uuid references content_users(id) on delete set null,
  actor_name text not null,
  entity_type text not null,
  entity_id text,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_content_activity_created
  on content_activity_logs(created_at desc);
create index if not exists idx_content_activity_actor
  on content_activity_logs(actor_user_id, created_at desc);
create index if not exists idx_content_activity_entity
  on content_activity_logs(entity_type, entity_id, created_at desc);

commit;
