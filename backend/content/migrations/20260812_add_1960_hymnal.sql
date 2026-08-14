-- Correct the legacy SDA edition year and add an empty 1960 edition.
-- Songs are added and linked through Wudase Content Studio.

begin;

update book_editions as edition
set
  title = 'Amharic SDA Hymnal 1974 Edition',
  native_title = 'የ1974 ውዳሴ መዝሙር',
  publication_year = 1974,
  updated_at = now()
from books as book
where edition.book_id = book.id
  and book.slug = 'am-sda-hymnal'
  and edition.version_key = 'sda_old';

insert into book_editions (
  book_id,
  slug,
  version_key,
  title,
  native_title,
  publication_year,
  status,
  edition_type,
  sort_order,
  source_note
)
select
  id,
  'am-sda-hymnal-1960',
  'sda_1960',
  'Amharic SDA Hymnal 1960 Edition',
  'የ1960 ውዳሴ መዝሙር',
  1960,
  'published',
  'edition',
  30,
  'Managed through Wudase Content Studio.'
from books
where slug = 'am-sda-hymnal'
on conflict (version_key) do update set
  title = excluded.title,
  native_title = excluded.native_title,
  publication_year = excluded.publication_year,
  status = excluded.status,
  edition_type = excluded.edition_type,
  sort_order = excluded.sort_order,
  source_note = excluded.source_note,
  is_active = true,
  updated_at = now();

-- Remove the legacy placeholder if this migration is rerun on an existing DB.
delete from content_audit_logs
where work_id in (
    select id from works
    where canonical_key = 'am-sda-1960-temporary-song-1'
  )
  or entity_id in (
    select id from works
    where canonical_key = 'am-sda-1960-temporary-song-1'
  )
  or entity_id in (
    select entry.id
    from book_entries as entry
    join works as work on work.id = entry.work_id
    where work.canonical_key = 'am-sda-1960-temporary-song-1'
  );

delete from media_links
where work_id in (
    select id from works
    where canonical_key = 'am-sda-1960-temporary-song-1'
  )
  or book_entry_id in (
    select entry.id
    from book_entries as entry
    join works as work on work.id = entry.work_id
    where work.canonical_key = 'am-sda-1960-temporary-song-1'
  );

delete from book_entries
where work_id in (
  select id from works
  where canonical_key = 'am-sda-1960-temporary-song-1'
);

delete from works
where canonical_key = 'am-sda-1960-temporary-song-1';

commit;
