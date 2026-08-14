-- Keep PostgreSQL private behind the content API. The deploy-time owner applies
-- migrations; the application login is a member of this NOLOGIN capability role.

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'wudase_content_runtime') then
    create role wudase_content_runtime nologin nosuperuser nocreatedb nocreaterole inherit;
  end if;
  if not exists (select 1 from pg_roles where rolname = 'wudase_content_migrator') then
    create role wudase_content_migrator nologin nosuperuser nocreatedb nocreaterole inherit;
  end if;
end
$$;

grant wudase_content_migrator to current_user;

do $$
begin
  execute format(
    'revoke all privileges on database %I from public',
    current_database()
  );
  execute format(
    'grant connect on database %I to wudase_content_runtime',
    current_database()
  );
  execute format(
    'grant connect on database %I to wudase_content_migrator',
    current_database()
  );
end
$$;

revoke create on schema public from public;
revoke all on all tables in schema public from public;
revoke all on all sequences in schema public from public;

grant usage on schema public to wudase_content_runtime;
grant select, insert, update, delete on all tables in schema public to wudase_content_runtime;
grant usage, select on all sequences in schema public to wudase_content_runtime;
grant usage on schema public to wudase_content_migrator;
grant all privileges on all tables in schema public to wudase_content_migrator;
grant all privileges on all sequences in schema public to wudase_content_migrator;

alter default privileges in schema public
  grant select, insert, update, delete on tables to wudase_content_runtime;
alter default privileges in schema public
  grant usage, select on sequences to wudase_content_runtime;
alter default privileges in schema public
  grant all privileges on tables to wudase_content_migrator;
alter default privileges in schema public
  grant all privileges on sequences to wudase_content_migrator;

do $$
declare
  item record;
begin
  for item in
    select quote_ident(schemaname) as schema_name, quote_ident(tablename) as table_name
    from pg_tables
    where schemaname = 'public'
  loop
    execute format(
      'alter table %s.%s enable row level security',
      item.schema_name,
      item.table_name
    );
    execute format(
      'alter table %s.%s force row level security',
      item.schema_name,
      item.table_name
    );
    execute format(
      'drop policy if exists backend_runtime_only on %s.%s',
      item.schema_name,
      item.table_name
    );
    execute format(
      'create policy backend_runtime_only on %s.%s to wudase_content_runtime, wudase_content_migrator using (true) with check (true)',
      item.schema_name,
      item.table_name
    );
  end loop;
end
$$;
