-- Exact review snapshots and database-level independent approval protection.
-- Apply to the SDA control database only.

begin;

alter table content_workflows
  add column if not exists baseline_snapshot jsonb not null default '{}'::jsonb,
  add column if not exists submitted_snapshot jsonb not null default '{}'::jsonb;

create or replace function prevent_content_workflow_self_review()
returns trigger
language plpgsql
as $$
begin
  if new.status in ('approved', 'changes_requested')
    and new.reviewed_by_id is not null
    and (
      new.reviewed_by_id is not distinct from new.updated_by_id
      or new.reviewed_by_id is not distinct from new.submitted_by_id
    )
  then
    raise exception 'A contributor cannot review their own content revision.';
  end if;
  return new;
end;
$$;

drop trigger if exists content_workflow_independent_review on content_workflows;
create trigger content_workflow_independent_review
before insert or update on content_workflows
for each row execute function prevent_content_workflow_self_review();

commit;
