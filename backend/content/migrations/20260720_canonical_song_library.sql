-- Convert content storage to one canonical song with reusable hymnal memberships.
-- Run this after 20260720_content_studio.sql in both content databases.

begin;

alter table book_editions
  add column if not exists version_key text,
  add column if not exists native_title text,
  add column if not exists publication_year integer,
  add column if not exists status text not null default 'draft';

update book_editions
set
  version_key = case slug
    when 'am-sda-hymnal-new' then 'sda_new'
    when 'am-sda-hymnal-old' then 'sda_old'
    when 'am-hagerigna-primary' then 'hagerigna'
    else regexp_replace(lower(slug), '[^a-z0-9]+', '_', 'g')
  end,
  native_title = case slug
    when 'am-sda-hymnal-new' then 'የ2004 ውዳሴ መዝሙር'
    when 'am-sda-hymnal-old' then 'የ1974 ውዳሴ መዝሙር'
    when 'am-hagerigna-primary' then 'የሀገርኛ መዝሙር'
    else coalesce(native_title, title)
  end,
  publication_year = case slug
    when 'am-sda-hymnal-new' then 2004
    when 'am-sda-hymnal-old' then 1974
    else publication_year
  end,
  status = case
    when slug in (
      'am-sda-hymnal-new',
      'am-sda-hymnal-old',
      'am-hagerigna-primary'
    ) then 'published'
    else status
  end
where version_key is null
   or native_title is null
   or status = 'draft';

alter table book_editions
  alter column version_key set not null;

create unique index if not exists idx_book_editions_version_key
  on book_editions(version_key);

alter table book_editions
  drop constraint if exists book_editions_status_check;
alter table book_editions
  add constraint book_editions_status_check
  check (status in ('draft', 'published', 'archived'));

alter table works
  add column if not exists canonical_lyrics text not null default '';

update works w
set canonical_lyrics = coalesce(
  (
    select e.lyrics
    from book_entries e
    join book_editions be on be.id = e.edition_id
    where e.work_id = w.id
      and nullif(e.lyrics, '') is not null
    order by
      case be.version_key
        when 'sda_new' then 0
        when 'hagerigna' then 0
        when 'sda_old' then 1
        else 2
      end,
      be.sort_order,
      e.entry_number
    limit 1
  ),
  w.canonical_lyrics,
  ''
)
where w.canonical_lyrics = '';

alter table book_entries
  alter column title drop not null,
  alter column lyrics drop not null,
  alter column lyrics drop default;

update book_entries e
set
  title = case
    when e.title is not distinct from w.default_title then null
    else e.title
  end,
  english_title = case
    when e.english_title is not distinct from w.default_english_title then null
    else e.english_title
  end,
  lyrics = case
    when e.lyrics is not distinct from w.canonical_lyrics then null
    else e.lyrics
  end
from works w
where w.id = e.work_id;

alter table content_audit_logs
  drop constraint if exists content_audit_logs_action_check;
alter table content_audit_logs
  add constraint content_audit_logs_action_check
  check (
    action in (
      'create',
      'update',
      'merge',
      'edition_create',
      'edition_update',
      'membership_remove',
      'media_add',
      'media_update',
      'media_remove'
    )
  );

drop view if exists catalog_entries;
create view catalog_entries as
select
  l.code as language_code,
  b.slug as book_slug,
  b.title as book_title,
  be.slug as edition_slug,
  be.version_key,
  be.title as edition_title,
  e.id as entry_id,
  e.entry_number,
  coalesce(e.title, w.default_title) as title,
  coalesce(e.english_title, w.default_english_title) as english_title,
  coalesce(e.lyrics, w.canonical_lyrics) as lyrics,
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

create or replace view sda_hymnal_songs as
select
  w.id as work_id,
  w.canonical_key,
  coalesce(
    max(e.title) filter (where be.version_key = 'sda_new'),
    max(e.title) filter (where be.version_key = 'sda_old'),
    w.default_title
  ) as title,
  coalesce(
    max(e.english_title) filter (where be.version_key = 'sda_new'),
    max(e.english_title) filter (where be.version_key = 'sda_old'),
    w.default_english_title
  ) as english_title,
  (
    max(e.id::text) filter (where be.version_key = 'sda_new')
  )::uuid as new_entry_id,
  max(e.entry_number)
    filter (where be.version_key = 'sda_new') as new_hymnal_number,
  coalesce(
    max(e.lyrics) filter (where be.version_key = 'sda_new'),
    w.canonical_lyrics
  ) as new_lyrics,
  (
    max(e.id::text) filter (where be.version_key = 'sda_old')
  )::uuid as old_entry_id,
  max(e.entry_number)
    filter (where be.version_key = 'sda_old') as old_hymnal_number,
  coalesce(
    max(e.lyrics) filter (where be.version_key = 'sda_old'),
    w.canonical_lyrics
  ) as old_lyrics,
  case
    when max(e.id::text)
      filter (where be.version_key = 'sda_new') is null then 'missing_new'
    when max(e.id::text)
      filter (where be.version_key = 'sda_old') is null then 'missing_old'
    else 'matched'
  end as match_status
from works w
join book_entries e on e.work_id = w.id
join book_editions be on be.id = e.edition_id
where be.version_key in ('sda_new', 'sda_old')
group by
  w.id,
  w.canonical_key,
  w.default_title,
  w.default_english_title,
  w.canonical_lyrics;

commit;
