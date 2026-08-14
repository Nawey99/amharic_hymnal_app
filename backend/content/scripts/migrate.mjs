import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';

import pg from 'pg';

const { Client } = pg;
const root = path.resolve(import.meta.dirname, '..');
const migrationsDirectory = path.join(root, 'migrations');
const sharedMigration = (name) =>
  !name.includes('add_1960') &&
  !name.includes('collaboration_') &&
  !name.includes('review_console');
const migrationOrder = new Map([
  ['20260720_content_studio.sql', 10],
  ['20260720_canonical_song_library.sql', 20],
  ['20260812_add_1960_hymnal.sql', 30],
  ['20260813_collaboration_workflow.sql', 40],
  ['20260813_collaboration_activity.sql', 50],
  ['20260813_collaboration_immutable_releases.sql', 60],
  ['20260813_review_console.sql', 70],
  ['20260814_backend_rls.sql', 80],
]);
const repeatableMigrations = new Set(['20260814_backend_rls.sql']);

const migrate = async (label, connectionString, include) => {
  if (!connectionString) {
    throw new Error(`${label} database URL is not configured.`);
  }
  const client = new Client({ connectionString });
  await client.connect();
  try {
    await client.query(
      "select pg_advisory_lock(hashtext('wudase_content_migrations'))",
    );
    const schemaResult = await client.query(
      "select to_regclass('public.languages') as table_name",
    );
    if (!schemaResult.rows[0]?.table_name) {
      const baseSchema = await readFile(path.join(root, 'schema.sql'), 'utf8');
      await client.query(baseSchema);
      console.log(`[${label}] applied schema.sql`);
    }
    await client.query(`
      create table if not exists content_schema_migrations (
        name text primary key,
        applied_at timestamptz not null default now()
      )
    `);
    const appliedResult = await client.query(
      'select name from content_schema_migrations',
    );
    const applied = new Set(appliedResult.rows.map((row) => row.name));
    const files = (await readdir(migrationsDirectory))
      .filter((name) => name.endsWith('.sql') && include(name))
      .sort(
        (left, right) =>
          (migrationOrder.get(left) ?? 999) -
            (migrationOrder.get(right) ?? 999) || left.localeCompare(right),
      );
    for (const name of files) {
      const wasApplied = applied.has(name);
      if (wasApplied && !repeatableMigrations.has(name)) continue;
      const sql = await readFile(path.join(migrationsDirectory, name), 'utf8');
      await client.query(sql);
      await client.query(
        'insert into content_schema_migrations(name) values ($1) on conflict do nothing',
        [name],
      );
      console.log(`[${label}] ${wasApplied ? 'reapplied' : 'applied'} ${name}`);
    }
  } finally {
    await client
      .query("select pg_advisory_unlock(hashtext('wudase_content_migrations'))")
      .catch(() => {});
    await client.end();
  }
};

const isProduction = process.env.NODE_ENV === 'production';
const sdaMigrationUrl = process.env.SDA_HYMNAL_MIGRATION_DATABASE_URL;
const hagerignaMigrationUrl = process.env.HAGERIGNA_MIGRATION_DATABASE_URL;
const sdaRuntimeUrl =
  process.env.SDA_HYMNAL_DATABASE_URL ?? process.env.CONTENT_DATABASE_URL;
const hagerignaRuntimeUrl = process.env.HAGERIGNA_DATABASE_URL;

if (isProduction && (!sdaMigrationUrl || !hagerignaMigrationUrl)) {
  throw new Error(
    'Production migrations require both privileged migration database URLs.',
  );
}
if (
  isProduction &&
  (sdaMigrationUrl === sdaRuntimeUrl ||
    hagerignaMigrationUrl === hagerignaRuntimeUrl)
) {
  throw new Error(
    'Production migration and runtime database credentials must be different.',
  );
}

const sdaUrl = sdaMigrationUrl ?? sdaRuntimeUrl;
const hagerignaUrl = hagerignaMigrationUrl ?? hagerignaRuntimeUrl;

await migrate('sda', sdaUrl, () => true);
await migrate('hagerigna', hagerignaUrl, sharedMigration);
