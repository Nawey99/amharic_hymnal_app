-- Release payloads are immutable. Activation may change only is_current.
-- Apply to the SDA control database only.

begin;

create or replace function prevent_content_release_payload_update()
returns trigger
language plpgsql
as $$
begin
  if old.release_key is distinct from new.release_key
    or old.version_label is distinct from new.version_label
    or old.description is distinct from new.description
    or old.published_at is distinct from new.published_at
    or old.schema_version is distinct from new.schema_version
    or old.created_by_id is distinct from new.created_by_id
    or old.created_by_name is distinct from new.created_by_name
    or old.checksum_sha256 is distinct from new.checksum_sha256
    or old.manifest is distinct from new.manifest
    or old.bundle is distinct from new.bundle
    or old.metadata is distinct from new.metadata
    or old.created_at is distinct from new.created_at
  then
    raise exception 'Published release payloads are immutable.';
  end if;
  return new;
end;
$$;

drop trigger if exists content_release_payload_immutable on content_releases;
create trigger content_release_payload_immutable
before update on content_releases
for each row execute function prevent_content_release_payload_update();

commit;
