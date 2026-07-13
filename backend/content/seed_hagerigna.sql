-- Generated from current Flutter JSON assets.
-- Hagerigna content database seed.
-- Run after backend/content/schema.sql.
begin;

insert into languages (code, native_name, english_name, script_code)
values ('am', 'አማርኛ', 'Amharic', 'Ethi')
on conflict (code) do update set
  native_name = excluded.native_name,
  english_name = excluded.english_name,
  script_code = excluded.script_code,
  updated_at = now();

insert into books (slug, language_code, title, book_type, source_note)
values ('am-hagerigna', 'am', 'Hagerigna Worship Songs', 'songbook', 'Imported from assets/data/database/HagerignaData.json')
on conflict (slug) do update set
  language_code = excluded.language_code,
  title = excluded.title,
  book_type = excluded.book_type,
  source_note = excluded.source_note,
  updated_at = now();
insert into book_editions (book_id, slug, title, edition_type, sort_order, source_note)
select id, 'am-hagerigna-primary', 'Hagerigna Worship Songs', 'primary', 30, 'song_title_text, song_text, and song_author_text arrays'
from books
where slug = 'am-hagerigna'
on conflict (slug) do update set
  title = excluded.title,
  edition_type = excluded.edition_type,
  sort_order = excluded.sort_order,
  source_note = excluded.source_note,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-001',
  'am',
  'እነሆ ክረምቱ ያልፋል',
  null,
  'እነሆ-ክረምቱ-ያልፋል',
  'Imported from Hagerigna row 1.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  1,
  'እነሆ ክረምቱ ያልፋል',
  null,
  '1. እነሆ ክረምቱ ያልፋልና                                                                          
ዝናቡም ጥሎ ይሄዳልና
የዜማ ጊዜያችን ደርሱዋልና
ስለዚህ በጌታ እጽናና

 በርቱ በርቱ ጌታ ሊጎበኘን ነው
 እንባችን ሊታበስልን ነው /2/

 2.የለቅሶ ወራትም ያልፋልና
ሀዘንም በደስታ ይተካልና
ጌታችን ሊመጣ ቀርቡዋልና
ደስታችን ፍጹም ሊሆን ነውና

-- በርቱ በርቱ --
 
 3.ወይናችን ሊያብብ ተቃርቡዋል
 ፍሪያችንን ልናጭድ ተዳረሱዋል
 በረከት በህይወታችን ያልፋል
 ጠብቀን እኛም እንከብራለን
 
 -- በርቱ በርቱ --

 4.የጭቀት የስቃይ ኑሩዋችን 
 ይነጉዳል ያልፋል ከህይወታችን
 ያጊዜ ሁሉን እንረሳለን
 በደስታ በፊቱ እንዘምራለን 
 
 -- በርቱ በርቱ --
',
  'hagerigna',
  0,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-001'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-002',
  'am',
  'ማራናታ',
  null,
  'ማራናታ',
  'Imported from Hagerigna row 2.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  2,
  'ማራናታ',
  null,
  'ማራናታ እባክህ ቶሎ ና የእኛ ጌታ 
ማራናታ እንዳናመነታ
ማራናታ እባክህ ቶሎና የኛ ጌታ 
ካንተ ዘንድ ነው የዘላለም ደስታ
አውጣን ከዚህ ጣጣ
እባክህ ቶሎና ውዱ የኛ አለኝታ

 1.ማራናታ -የምድራችን ኑሮ ይደንቃል ክፋቱ
ማራናታ -ስንወጣ ስንገባ ሰላም ማሳጣቱ
ማራናታ-ጊዜው እጅግ ከፍቱዋል እኛም ይኼው ዝለናል
ማራናታ-ትግስታችን አልቆ እንዳንወድቅ ፈርተናል/ማራናታ/
እባክህ ቶሎ ና ልናይ ጉዋግተናል፡፡

-- ማራናታ እባክህ ቶሎ ና --

2.ማራናታ - የዘመኑ ክፋት እጅግ ብሶበታል
 ማራናታ - ውስጣችን ሁሉ ትርጉም አጥቱዋል
 ማራናታ - የዘር መለያየት ሽኩቻዎች በዝቱዋል
 ማራናታ - ይህን ሁሉ እያየን መኖር ሰልችቶናል/ማራናታ/
 እባክህ ቶሎና እቤትህ ናፍቆናል፡፡ 
 
 -- ማራናታ እባክህ ቶሎ ና --
 
 3.ማራናታ - የዘላለም አምላክ ቸሩ እግዚያብሄር ሆይ
 ማራናታ - የምድራችን ክፋት የምታውቃት አይደለም ወይ
 ማራናታ - የሾህ አክሊል ደፍተህ ለኛ ተዋርደዋል
 ማራናታ - እኛም ለጆችህ ዛሬ ተጠልተናል /ማራናታ/
 እባክህ ቶሎና ካንተ ጋር ይሻለናል፡፡
 
 -- ማራናታ እባክህ ቶሎ ና --

 4. ማራናታ - ጌታችን ኢየሱስ ሆይ ቶሎ ድረሱልን
ማራናታ - መጨነቅ መጠበብ ይህ ሁሉ ይቅርብን
ማራናታ - ለስጋችን ድሎት ብለን እንሮጣለን                                                          2
ማራናታ - ምንም ቢያስደስተን እርካታን አይሰጠንም /ማራናታ/  
 እባክህ ቶሎ ና ከዚህ ኑሮ ለየን፡፡
 
 -- ማራናታ እባክህ ቶሎ ና --
',
  'hagerigna',
  1,
  '{"artist":"የአርሲ ነገሌ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-002'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-003',
  'am',
  'ሕይወት እንደተለመደ',
  null,
  'ሕይወት-እንደተለመደ',
  'Imported from Hagerigna row 3.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  3,
  'ሕይወት እንደተለመደ',
  null,
  'አ      ሕይወት እንደተለመደ ነው ሲሉ    
ዝ     ጊዜ አለንና ሠላም ነው እያሉ
ማ    ድንገት የእሳት ጎርፍ ምድርን ሳያጠፋ
ች   ኑ ቶሎ እንግባ በተሰጠን ተስፋ

1.በአንድነት ተነሱ በንጋት እንውጣ
ወዮ ነፍስ ቀረች ጽዋውን ልትጠጣ
መለከትን ንፉ ቀኑ መሽቷልና
የምህረቱ ደጅ ሊዘጋ ነውና

2.እኛም አንቀላፋን ነፍስም አልዳነችም
የምድሩም መከር አልተሰበሰበም
ነዶውን ሰብስቡ ተሰርቷል ጎተራው
የምርቱ ባለቤት የሱስ ሊመጣ ነው

3.ፍጻሜው ሲቃረብ ጨለማው ሲባባስ
እየከፋ ሲሄድ ፍቅር ሲፈራርስ
ውጤቱ ሊመዘን በጋው ደርሷልና
ምጻቱ ፈጠነ እነሆ ይኸውና

4.እንግዲህ እግዚአብሔር ያለማወቅን ዘመን
አሳልፎ አሁን በምህረቱ ሊገናኘን
በየሥፍራው ሆኖ ይጠራናልና
ነፍሳችሁን አድኗት ንሥሐ ግቡና
',
  'hagerigna',
  2,
  '{"artist":"ዘማሪ በየነ በዲቻ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-003'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-004',
  'am',
  'ወደ ማን እሄዳለሁ',
  null,
  'ወደ-ማን-እሄዳለሁ',
  'Imported from Hagerigna row 4.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  4,
  'ወደ ማን እሄዳለሁ',
  null,
  'ወደ ማን እሄዳለሁ እኔ/6/
ሌሊት በእሳት ዓምድ ስትመራኝ2x
ቀን በደመና ስትረዳኝ             
ጠላቴን ስታዋርደዉ ይህንን በዓይኔ አይቻለሁ

1. ከባህር አስከ ባህር ማዶ በጀልባ የተሳፈሩ
ሌሊቱን ሲለፉ ያደሩ የሱስን እየፈለጉ
ፈልገዉ ባገኙት ጊዜ ከፊቱ ተሰበሰቡ
እንደ ትናንትናም ዛሬ እንጀራ ይሰጠናል አሉ
የሱስ የልባቸዉን አዉቆ ሲሰጣቸዉ የቃል ፈተና
ማንም ሰዉ ካልበላ ሥጋዬን ማንም ሰዉ ካልጠጣ ደሜን
አይችልም መኖር ከእኔ ጋር እያለ ሲናገር ጌታ
በእርግጥም ተሰናከሉ ሆዳቸዉን አከበሩና

-- ወደ ማን እሄዳለሁ --

2. በኃጢአት አላንጋ እኔ ስገረፍ ከኖርኩበት
ከዚያ ከጨካኙ ንጉሥ ከጨካኙ ፈርዖን እጅ
ድል በድል እየመራኝ ኤርትራን ያሻገረኝ
ነፃነት ያወጀልኝ ባለዉለታ አይደለም ወይ
ታዲያ እንዴት ይህን አምላኬን ከእርሱ ጋር የገባሁትን 
ቃል ኪዳኔን አፈርሳለሁ ቃል ኪዳኔን አፈርሳለሁ
ይህንን የተዉኩትን አገር ወደ ኋላ ለምን አያለሁ
ዮርዳኖስን እሻገራለሁ ከነዓንን በድል እገባለሁ

-- ወደ ማን እሄዳለሁ --

3. የሠርጉን ነጭ ልብስ ለብሼ ልዘጋጅ እንጂ በጊዜ
ደርሶኛል ከመልዕክተኛ የተላከልኝ ደብዳቤ
በዉስጡ ያለዉን አንብቤ ሰዓቱን ጊዜዉን አዉቄ
ልዘጋጅ እንጂ አምላኬ የለኝም ምክንያት በልቤ
ከልጅነቱ ጀምሮ ዉለታ የበዛለት ሰዉ
እንደ እኔ የት አለና ነው ከፊትህ የምኮበልለዉ
እስካለሁ በሕይወት ዘመኔ መስቀልህን እሸከማለሁ
ፈቃድህን እፈጽማለሁ ቃል ኪዳኔን አጸናለሁ/አድሳለሁ፡፡

-- ወደ ማን እሄዳለሁ --
',
  'hagerigna',
  3,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-004'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-005',
  'am',
  'ለእግዚአብሄር ምን ልመልስ',
  null,
  'ለእግዚአብሄር-ምን-ልመልስ',
  'Imported from Hagerigna row 5.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  5,
  'ለእግዚአብሄር ምን ልመልስ',
  null,
  'ለእግዚአብሄር ምን ልመልስ ውለታው በዝቶአልና/2/
ከነገድ ከቋንቋ አንስቶ እዚህ ሰብስቦናልና/2/
ኃያል አምላክ ወዳጃችን ኢየሱስ ነው አምላካችን
ጉባኤው ሁሉ ያመስግነው ከፍ ይበል ንጉሣችን

1. የበጎች ጠባቂ እረኛ ይኸው ከእኛ ጋር አለና/2/
በተቀመጥንበት ሥፍራ መላዕክት ሰፍረዋልና/2/
ዓላማ የለሽ ህዝብ ሆነን መንፈሱን እንዳናሳዝን
በቅድስና ለመኖር ክብሩን እግዚአብሄር ያልብሰን

-- ለእግዚአብሄር ምን ልመልስ --

2.በሰዎች ፊት የተናቁ ወራዳዎች የሆኑትን/2/
በዓለም ውስጥ ዉዳቂ ወደ ዳር የተጣሉትን/2/
በክብር ሥፍራ ላይ ወስዶ እግዚአብሄር አስቀምጦናል
ወደሚደነቀው ብርሃን ጌታ ኢየሱስ ጠርቶናል

-- ለእግዚአብሄር ምን ልመልስ --
    
3. ቆም ብለህ አስብ እስቲ እግዚአብሄር ትልቅ ትልቅ ነው /2/
በፊቱ መሆን ይቅርና ስሙ እንኳን የሚፈራ ነው/2/
የሰውን ልጆች ሊመርጠን እኛ ለርሱ ምንድንነን
በክብር ሥፍራ ላይ ያለህ ኢየሱስ ሆይ ስምህ ይግነን

-- ለእግዚአብሄር ምን ልመልስ --
',
  'hagerigna',
  4,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-005'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-006',
  'am',
  'ኑ ወደ እግዚአብሔር',
  null,
  'ኑ-ወደ-እግዚአብሔር',
  'Imported from Hagerigna row 6.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  6,
  'ኑ ወደ እግዚአብሔር',
  null,
  'ኑ ወደ እግዚአብሔር እንመለስ 
ከኃጢታችንም ቶሎ እንናዘዝ
እንደ ምድጃ እሳት የሚያቃጥል ቀን ሳይመጣ
በቁጣዉ ነበልባል ሆኖ ጌታ ከዙፋን ሳይወጣ፡፡

-- ኑ ወደ እግዚአብሔር --

1.በእዉነት የእግዚአብሔር ቀን ቀርቧልና
የጭንቅ የመከራ ጊዜ መጥቷልና
ምህረቱ ቀርቦ ሳለ እንታረቅ ኑ
ወደ እርሱ እንመለስ እንቅረብ ካሁኑ

-- ኑ ወደ እግዚአብሔር --

2.ትዕቢተኞችና በአምላክ ላይ ለሚያፈዙ
በኃጢአታቸዉ ተጸጽተዉ ለማይናዘዙ
ይኼዉ ታላቁ የእግዚአብሔር ቀን መጥቷልና
ሥርና ቅርንጫፍ አይተዉም ያቃጥላልና፡፡

-- ኑ ወደ እግዚአብሔር --
               
3.ዛሬ የሚለምነዉን የእግዚአብሔርን ቃል
ሰምቶ የሚቀበል በሥራ ላይ የሚያዉል
እርሱ ነው ታማኙ ባሪያ በጥቂት የታመነው
ቤቱን በአለት ላይ አፅንቶ የገነባዉ፡፡

-- ኑ ወደ እግዚአብሔር --

4.ፀሐይና ጨረቃ የሚጨልሙበት ቀን 
ሰማይና ምድር የሚንቀጠቀጡበት ቀን
የፍጥረት መሠረት ሁሉ የሚናወጥበት ቀን
ይኼዉ ደርሷል እንመለስ ወደ አምላካችን፡፡

-- ኑ ወደ እግዚአብሔር --
',
  'hagerigna',
  5,
  '{"artist":"ዘማሪ ፓ/ር አበራ ማሴቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-006'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-007',
  'am',
  'አካሄዴ ተበላሽቶ',
  null,
  'አካሄዴ-ተበላሽቶ',
  'Imported from Hagerigna row 7.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  7,
  'አካሄዴ ተበላሽቶ',
  null,
  'አካሄዴ ተበላሽቶ እንደ መንገድህ ባልሄድም 
በአመፅ ክፋት ተሞልቼ ዘውትር ባሳዝንህም
ወደ ህይወት ስታመራኝ እኔ ግን ሞትን ብመርጥም
አመሰግንሃለሁ ጌታ (የሱስ) ከእጆችህ አልጣልከኝም

1.ከእጆችህ አልጣልከኝም ኃጢአቴን ሁሉ እያየህ
ለምህረት የምትቸኩል ነህ ለቁጣግን የዘገየህ
እስከ አሁን ድረስ መኖሬ በሥራዬ አይደለምና
ለፍጥረታት ሁሉ ጌታ ይድረስህ ታላቅ ምሥጋና

-- አካሄዴ ተበላሽቶ --

2.በዓይኖችህ የማያምር ብልሹ ነው አካሄዴ
ወደ ሥዖል የሚወስደው እጅግ ሰፊ ነው መንገዴ
የዘላለም የሞት ጉዞ ሆኖ ሳለ ጎዳናዬ
ነፍሴ በአንተ ከሞት ዳነች ተመስገንልኝ ጌታዬ

-- አካሄዴ ተበላሽቶ --

3.ምንም ተስፋ የሌለኝ ሰው የሞት የጥፋት ጓደኛ
በድቅድቅ ጨለማ ስኖር ያለአንዳች ምንም እረኛ
ኢየሱስ የሚባል ጌታ ይህን ዕዳ ከፈለልኝ
እኔ መሰቀል ሲገባኝ እርሱ ግን ተሰቀለልኝ

-- አካሄዴ ተበላሽቶ --

4.ዓለም ተስፋሽን ቁረጪ ከእንግዲህ የየሱስ ነኝ
ጌታ በፀጋው አድኖኝ በምህረቱ ወሰደኝ
በክንፎቹ ተማምኜ በአምላክ ጥላ ሥር ስላለሁ
ኃይልን በሚሰጠኝ ጌታ ሁሉን ነገር እችላለሁ

-- አካሄዴ ተበላሽቶ --
',
  'hagerigna',
  6,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-007'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-008',
  'am',
  'አንተ ግን አስቀድመህ',
  null,
  'አንተ-ግን-አስቀድመህ',
  'Imported from Hagerigna row 8.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  8,
  'አንተ ግን አስቀድመህ',
  null,
  '1.ስለ ልብስ ስለ ምግብ ዘውትር ሲጨነቁ         
ሰማያዊውን ረስተው ካንተ የራቁ
እጅግ ብዙ ናቸው ከመንገድ የሳቱ
ፅድቁንም መንግስቱን የተውቱ

አንተ ግን አስቀድመህ ጽድቁን መንግስቱን ፈልግ
ሌላው ሁሉ ይጨመርልሃል
ስለዚህ አስቀድመህ ጽድቁን መንግስቱን ፈልግ
ሌላው ሁሉ ይጨመርልሃል

2.ኋላ የሚያልፈውን ኋላ የሚጠፋውን
ዘላቂነት ከቶ የሌለውን
መርጠህ በመገስገስ ከሕይወት እንዳትወጣ
የዘላለምን ቤት እንዳታጣ

-- አንተ ግን አስቀድመህ --
             
3.ሆዴን ሊሙላ ብሎ በጊዜያዊ መብል
ብኩርናውን ኤሳው ሲያቃልል
ዳግመኛ በእምባ ተግቶ ቢፈልጋት
በፍጹም አልቻም ሊያገኛት

-- አንተ ግን አስቀድመህ --

4.ለጊዜው በኃጢአት የሚገኘዉ ደስታ
እምቢ ብሎ ሙሴ እንደወጣ
ተስፋውን በእምነት እንደተቀበለ
ጌታ ካንተም የሚሻው ይህንን ነው

-- አንተ ግን አስቀድመህ --
',
  'hagerigna',
  7,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-008'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-009',
  'am',
  'ዓለም ከእንግዲህ ተስፋሽን ቁረጪ',
  null,
  'ዓለም-ከእንግዲህ-ተስፋሽን-ቁረጪ',
  'Imported from Hagerigna row 9.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  9,
  'ዓለም ከእንግዲህ ተስፋሽን ቁረጪ',
  null,
  'አ    ዓለም ከእንግዲህ ተስፋሽን ቁረጪ
ዝ    አምላክ በፀጋው አዳነን
ማ    የመንግሥት ልጆች አረገን
ች    እንዲያው በነፃ ወደደን

1.ባለማወቃችን ጽዋሽን ቀምሰናል
አምላክ አዝኖ ሳለ አስደስተንሻል
ያ ታላቁ ዝናሽ በየሱስ ወደመ
ክብር ይሁንለት እንዳንሞት ቀደመ

2.ለሰው ልጆች ኃጢአት የቆመው ጠበቃ
የፍጥረታት ገዢ የሠላም አለቃ
ተሰቅሎ ሞተና ለዓለም ኃጢአተኞች
ከሞት አፋፍ ዳኑ ብዙ ህመምተኞች
           
3.ወንጀል ሳይኖርበት ለሰው ጥፋት ብሎ
በጠራራ ፀሐይ በቀራኒዮ ውሎ
ፍጥረትን ለማዳን ጥረቱን ቀጠለ
ራሱን ዝቅ አድርጎ ለሰው ተሰቀለ

4.ውርደታችንን በክብር ለውጦ
የማቅ ልብሳችንን በነጭ ልብስ አስጊጦ
ሳንፈልገው ወዶን የሱስ ተገናኘን
አሁንም ምሥጋና እንዲሁ ስላዳነን
                  
5.ምን ይከፈለዋል ለሠራዊት ጌታ
በነፃ ሊያድነን ለዋለው ውለታ
ግንበኞች የናቁት የማዕዘኑ ዓለት
በምድርም በሰማይ ክብር ይሁንለት 
',
  'hagerigna',
  8,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-009'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-010',
  'am',
  'ማንም የለም ጥበበኛ',
  null,
  'ማንም-የለም-ጥበበኛ',
  'Imported from Hagerigna row 10.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  10,
  'ማንም የለም ጥበበኛ',
  null,
  '1.ማንም የለም ጥበበኛ 
ካንተ የሚበልጥ ታምረኛ
ስለዚህ ና ተመላለስ
ጉባኤውን አንተ ቀድስ
             
አ   በአደራሹ ግባ ብለን
ዝ   ጉባኤውን ለአንተ ሰጥተን
ማ   አድርግልን የምትወደውን
ች    ከእግሮችህ ሥር ከፊትህ ነን

2.ከሰው አንዳች አንጠብቅም
ነፍሳችንን አይፈውስም
ብለን መጣን አንተንብቻ
የሌለህን ከቶ አቻ
            
3.የራሷን ቤት ሁሉ ጥላ
እንደ ማርያም አንተን ብላ
ተናገረኝ የምትልህ
ልቧ ረክቶ ታመስግንህ

4.ብዙ ሲሮጥ አጥቶ መላ
በጥያቄ የተሞላ
አሳርፈኝ ብሎ የሚልህ
መልስ አግንቶ ያመስግንህ 
',
  'hagerigna',
  9,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-010'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-011',
  'am',
  'እስከ መቼ ነው',
  null,
  'እስከ-መቼ-ነው',
  'Imported from Hagerigna row 11.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  11,
  'እስከ መቼ ነው',
  null,
  'አ   እስከ መቼ ነው በዚህ ምድር 
ዝ   የምንሰቃየው በሰው ሀገር
ማ   ጌታ ሆይ ናና ወደ ቤታችን
ች   ከፊታችን ምራን ወደ አገራችን

1.የባዕድ አገር ኑሮ አልተመቸንም
በሰው ሀገር መኖር አልተስማማንም
ምርኮአችንን ዛሬ መልሰውና
ወደ ጽዮን ምራን እባክህ ናና

2.በእንግድነት ሀገር እስከ መቼ ነው
ግራ ቀኝ እያየን የምንኖረው
አሁንስ ይብቃን እጅግ መርሮናል
ለእኛስ ቤታችን እጅግ ናፍቆናል

3.የዚህ ምድር ኑሮ አላዋጣንም
ክፋቱ እጅግ በዛ አልተሻለንም
እባክህ ጌታ ሆይ አንተ ራራልን
ወደ ቀድሞ ቤታችን ቶሎ ውሰደን

4.የዚህ ዓለም ታሪክ አሁንስ ከፋ
ጥላቻና ክፋት እጅግ ተስፋፋ
በክርስቲያኖች መሐል ፍቅር ጠፋ
ጌታ ዝም አትበለን በምድረበዳ
                
5. መነቃቀፍ በዛ በህዝብህ መሃል
አንዱ በአንዱ ላይ ሰይፍ ይመዝዛል
የዓለም ታሪክ ሁሉ መራራ ሆኗል
ጌታ ሆይ ገላግለን ቤትህ ይሻለናል
',
  'hagerigna',
  10,
  '{"artist":"ዘማሪ ፓ/ር አበራ ማሴቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-011'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-012',
  'am',
  'ምሳሌውን',
  null,
  'ምሳሌውን',
  'Imported from Hagerigna row 12.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  12,
  'ምሳሌውን',
  null,
  'ምሳሌውን ከበለስ ተማሩ
ሰዓቱ ደርሶ እንዳታማርሩ
ቅርንጫፎቿ ከለመለሙ
ቅጠሎቿ ካቆጠቆጡ
በዚያን ጊዜ በጋ ደረሰ
              
1. መንግሥት በመንግሥት ላይ ከተነሳ
ሥቃይ ሲበዛ ሁከት አበሳ
ረሃብ ቸነፈር መከራ ጭንቀት
ሠላም ሲታጣ ሁሌ ጦርነት
እሩቅ አይሆንም የየሱስ  ምፃት

-- ምሳሌውን --

2.ሐሰተኞች በዓለም ከበዙ
የሱስ እኔ ነኝ ብለው ካፌዙ
ሰይጣን በብርሃን መልክ ይመሰላል
ምርጦቹን እንኳን ሊያስት ይጥራል
በዚያን ጊዜ ሰዓቱ ደርሷል
               
-- ምሳሌውን --

3.ለተመረጡት ስደት ሲመጣ
ግፍ በደል ሲሆን የነሱ ዕጣ
ውሸት ተስፋፍቶ እውነት ሲከሳ
ከብዙ ሰዎች ፍቅር ሲጠፋ
በዚያን ጊዜ ቅርብ ነው ጌታ

-- ምሳሌውን --

4.የመንግሥት ወንጌል ከተሰበከ
ለፍጥረታቱ ከተዳረሰ
የጠላት ምሽግ ይፈራርሳል
ድንግል መሬቱ ሁሉ ይታረሳል
በዚያን ጊዜ ጌታ ይመጣል

-- ምሳሌውን --
',
  'hagerigna',
  11,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-012'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-013',
  'am',
  'አትሁን ወላዋይ',
  null,
  'አትሁን-ወላዋይ',
  'Imported from Hagerigna row 13.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  13,
  'አትሁን ወላዋይ',
  null,
  'አትሁን ወላዋይ መንታ ልብን ይዘህ
ወዲያ ወዲህ እያልክ ጌታህን ትተህ
ከሞትም ከሕይወትም በፍጹም ሳትሞላ
ጌታ ሊመጣ ነው እንዳይቆጭህ ኋላ

1.ላይጠቅምህ ላያዋጣህ ሁሉ እያማረህ
በአንዱም ሳትጸና ሁሉን እየመረጥህ
በሙሉ ልብህ ጌታን ሳታመልከው
በሩጫ እያለህ ጌታ ሊመጣ ነው

-- አትሁን ወላዋይ --

2.ወይ ቀዝቃዛ አይደለህ ፍጹም የበረድህ
ወይስ ሙቅ አይደለህ እጅግ የተኮስህ
ስማኝ ወገኔ ሆይ ለብ ብለሃልና
እንዳትተፋ ወደ ጌታህ ቶሎ ና

-- አትሁን ወላዋይ --
                  
3.የዚህ ዓለም ኑሮ አይጠቅምህምና
ጣፋጭ ብመስልህም መራራ ነውና
ሕይወት ያለው ሲመስልህ ውስጡ ሞት ናውና
ከዚህ ሁሉ ወንድም ወደ አምላክ ና

-- አትሁን ወላዋይ --
',
  'hagerigna',
  12,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-013'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-014',
  'am',
  'የኋለኛው ዝናብ',
  null,
  'የኋለኛው-ዝናብ',
  'Imported from Hagerigna row 14.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  14,
  'የኋለኛው ዝናብ',
  null,
  'የኋለኛው ዝናብ ለመዝነብ ተቃርቧል 
እርሻው ተቆፍሮ እሾክ ይወገዳል
ምድረበዳው ታርሶ ፍሬያማ ይሆናል
               
1.ተራራው አርኪ ምንጭ ያፈልቃል
ምድረበዳው ለምለም ሳር ያበቅላል
በኃያሉ አምላክ ተፈጥሮ ይለወጣል
በረሃው በሰማይ ጠል ፍሬውን ይሰጣል

-- የኋለኛው ዝናብ --

2.ብርሃን ከሰማይ ይወጣልናል
እግዚአብሄር ጨለማችንን ያበራል
የሠራዊት ጌታ እንደ ቃሉ ያደርጋል
በመንፈሱ ሙላት ሁሉን ይለውጣል

-- የኋለኛው ዝናብ --
               
3.ውኃ በማይገኝበት ሥፍራ
ድንጋይ ብቻ በሆነው ተራራ
ከበረሃ ሥፍራ ምንጭ ያፍለቀለቃል
ዓለቱን ሰንጥቆ ከጥማት ያድናል

-- የኋለኛው ዝናብ --

4.የዝማሬ ጊዜያችንም ደርሷል
እግዚአብሄር ከሰማይ ተመልክቷል
የኋለኛው ዝናብ ያጥለቀልቀናል
ባዶ መሆን ቀርቶ በኃይል ይሞላናል 

-- የኋለኛው ዝናብ --
',
  'hagerigna',
  13,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-014'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-015',
  'am',
  'ክብር የሚገባው',
  null,
  'ክብር-የሚገባው',
  'Imported from Hagerigna row 15.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  15,
  'ክብር የሚገባው',
  null,
  '1.ልክ እንደተፃፈው እንደ ቃሉ መጥቶ 
የሠይጣንን እራስ በመስቀል ቀጥቅጦ
የአዳምን ልጆች ከጥፋት ያዳነን
ይህ ታላቅ አዳኝ ይክበር እንላለን

ክብር የሚገባው አምላካችን የሱስ     
ለዘላለም ይክበር ለዘላለም ይንገሥ   2x
                  
2.ከመቃብር ወጥቶ ወደ ላይ ያረገው
ዳግም እመጣሁ ብሎ ቃል የገባው
እንደተናገረው መጥቶ ሊያሳርፈን
ይክበር ንጉሣችን ሊያከብረን የጠራን

-- ክብር የሚገባው --

3.ሺህ ዓመት ከርሱ ጋር በሰማይ ሊያነግሰን
ከዚያም በአዲስ ምድር ዘላላም ሊያኖረን
እንዲሁ ያከበረን አልፎም ያፀደቀን
ኢየሱስ ይባረክ እንዲህ የወደደን

-- ክብር የሚገባው --
                   
4.ኃጢአንን በክብሩ መትቶ ሲጥላቸው
ፃድቃንን ወደርሱ ሲሰበስባቸው
በአየር ሊነጠቁ ወዳለሙት አገር
እናምናለን እኛም ልናይ ያቺን ምድር

-- ክብር የሚገባው --

5.የአባቴ ብሩካን ኑ ግቡ ሲባሉ
መንግሥትን ሊወርሱ ንፁሃን ሊከብሩ
ክብር በተሞላው በጌታ የሱስ ፊት
ንቁ ይባላሉ ካንቀላፉትም እንቅልፍ

-- ክብር የሚገባው -- 
',
  'hagerigna',
  14,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-015'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-016',
  'am',
  'አስመሳይ ክርስቲያን',
  null,
  'አስመሳይ-ክርስቲያን',
  'Imported from Hagerigna row 16.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  16,
  'አስመሳይ ክርስቲያን',
  null,
  'አ   አስመሳይ ክርስቲያን የበግ ለምድ ለብሶ 
ዝ   እንክርዳዱ ከፍሬው ጋራ ተደባልቆ
ማ   በርቀት ሲያዩት ብርትኳን ይመስላል
ች   ተቆርጦ ሲቀመስ ጥርስን ይጠርሳል
              
1.በመልኩ ክርስቲያን በልቡ ደሊላ
በንጹህ ወንድሙ ላይ የሚጥል አሽክላ
ጻድቁን ለመክሰስ ማንም አይቀድመውም
ቃየል ነው ሲነሳ ምንም አይገደውም

2.ለፃዲቃኖች ግን ከለላ አላቸው
ጦሩ ቢወረወር ፈጽሞ አይወጋቸው
ማዕበሉ ተነስቶ በኃይል ቢወነጨፍ
እግዚአብሔር ይችላል መርከቧን ሊያሳልፍ
              
3.የበለዓም ወዳጅ የኤልዛቤል ጓደኛ
እውነትን ረጋሚ ሞልቷል ከዳተኛ
በሆዱ ጦረኛ ጣኦት ተሳላሚ
ክርስቲያንን መስሎ እውነት ተቃዋሚ

4.የኢዮብ ጓደኞች ተስፋ የሚያስቆርጡ
የቆመውን ወዳጅ የሚያንገዳግዱ
ሞልተዋል በየቦታዉ የእውነት አሳሳቾች
በግምት የሚፈርዱ ወገን አሳዳጆች
',
  'hagerigna',
  15,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-016'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-017',
  'am',
  'አቤቱ ጌታችን',
  null,
  'አቤቱ-ጌታችን',
  'Imported from Hagerigna row 17.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  17,
  'አቤቱ ጌታችን',
  null,
  'አቤቱ ጌታችን አቤቱ ጌታችን
የተመካንብህ ኢየሱስ ተስፋችን
መቼ ነው የምትመጣው የክብር እንግዳችን
ተስፋችን የሱስ ሆይ መቼ ነው የምትመጣው
                
1.በዚህች ዓለም መኖር ምንም አይጠቅመንም
ከኃጢአት በስተቀር ምንም አይተርፈንም
ይህንን እያየህ ለምን ትቆያለህ
ተስፋችን የሱስ ሆይ ስለምን ዘገየህ

-- አቤቱ ጌታችን --

2.ጠላታችን ዲያብሎስ የሚሸነፍበት
ተስፋውን ቆርጦ ስኦል የሚወርድበት
እኛ በመንግሥትህ የምንነግስበት
አቤቱ መቼ ይሁን አብረን የምንሆንበት

-- አቤቱ ጌታችን --

3.የመንፈስ ዓይናችን በሙሉ ተከፍቶ
ድካም ድንዛዜ ከውስጣችን ጠፍቶ
ጉድለታችንን አይተን እንድንስተካከል
በመንፈስህ ንካን ድካም ይወገዳል 

-- አቤቱ ጌታችን --
',
  'hagerigna',
  16,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-017'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-018',
  'am',
  'ያለኝ ንብረት',
  null,
  'ያለኝ-ንብረት',
  'Imported from Hagerigna row 18.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  18,
  'ያለኝ ንብረት',
  null,
  'ያለኝ ንብረት ብርም ቢሆን የእርሱ ነውና
የእኔ የሆነው ነገር አንድም የለምና
እስኪ ምን ልሸሽግ ወዴት ልደብቀው
የንብረቱን ጌታ ምን ብዬ ላታልለው
         
1.እስከ መቼ ድረስ እራስ ወዳድነት
ለማይጠግብ ሥጋ ለእኔ ለእኔ ማለት
መስጠት ብናውቅ ኖሮ መቀበል ይቻላል
ባለመስጠታችን ሌላው ቀርቶብናል

-- ያለኝ ንብረት --

2.አሸዋና ጠጠር ያልፈሰሰባት
ቅድስቲቱ ሀገር በወርቅ የተሰራች
ለሀብቱ ወሰን የለውም ይኼ ነው አይባልም
ስንቱን ልንገራችሁ ባወራው አያልቅም

-- ያለኝ ንብረት --
           
3.አልማዝ እና እምነ-በረድ የተሰወረው
ወርቅም እንቁም ሌላ ሌላም የተደበቀው
የፍጥረት ፈጣሪ ግዙፍ ሀብት እያለው
ጥቂቱን ብቻ ነው በዓይናችን ያየነው 

-- ያለኝ ንብረት --
',
  'hagerigna',
  17,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-018'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-019',
  'am',
  'ስሙ የማይንደው ተራራ',
  null,
  'ስሙ-የማይንደው-ተራራ',
  'Imported from Hagerigna row 19.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  19,
  'ስሙ የማይንደው ተራራ',
  null,
  'ስሙ የማይንደው ተራራ 
በርሱ የማይታለፍ መከራ
የለምና እኛም በእምነት ስሙን እንጥራ/2*/ አዎን
              
1.አሁን በዙሪያችን የከበበን
የማይታለፍ መስሎ የሚታየን
ስሙን ስንጠራ ሁሉ ይፈርሳል
እንደ አመድ ሆኖ በኖ ይጠፋል /2*/

-- ስሙ የማይንደው ተራራ --

2.የሚገዳደረን ብርቱ ሆኖ
ለዓይናችን የታየን እጅግ ገኖ
ረዳታችን ከላይ ሲደርስልን
ጠላት የካበብን ተናደልን /2*/

-- ስሙ የማይንደው ተራራ --
               
3.ደመና ከሰማይ አይታይም
ምልክት የሚሆን ነፋስ የለም
ግን ሸለቆ ሁሉ ውኃ ሞልቷል
ስሙ ያደርገው ዘንድ ተችሎታል /2*/

-- ስሙ የማይንደው ተራራ --

4.ተራራ ሆኖብን የጋረደን
አሻግረን እንዳናይ የከለለን
ታምረኛ ስሙን ስንጠራ
ይወዳደቅ ጀመር በየተራ /2*/ 

-- ስሙ የማይንደው ተራራ --
',
  'hagerigna',
  18,
  '{"artist":"የሀዋሳ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-019'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-020',
  'am',
  'ከእንግዲህስ ወዲህ ምጻቱን እሰብካለሁ',
  null,
  'ከእንግዲህስ-ወዲህ-ምጻቱን-እሰብካለሁ',
  'Imported from Hagerigna row 20.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  20,
  'ከእንግዲህስ ወዲህ ምጻቱን እሰብካለሁ',
  null,
  'ከእንግዲህስ ወዲህ ምጻቱን እሰብካለሁ
ሰማያዊ አምላክ ይመጣል አውቃለሁ
የመከሩ ጌታ ማጭዱን ይሰድዳል
የጎመራውን እሸት ወደ ጎተራው ይከትተዋል
             
1.ከፀሐይ መውጫ ለሚመጣዉ
ለንጉሥሽ መንገዱን ጥረጊ
እባክሽን ጽዮን ሆይ
ተነሺና አብሪ

-- ከእንግዲህስ ወዲህ --

2.በደመና ላይ ተቀምጦ
በደማቅ ብርሃን አሸብርቆ
የወርቅ አክሊል ደፍቶ
ንጉሥሽ ይመጣል

-- ከእንግዲህስ ወዲህ --
            
3.ወደ በጉ ሠርግ ለመግባት
ታላቁን ድግስ ለመብላት
ልብሳቸውን የሚያጥቡት
ብጹአን ቅዱሳን ናቸው

-- ከእንግዲህስ ወዲህ --

4.ሃሌ-ሃሌ ሃሌሉያ
እልል እልል እንላለን
በአዲሲቱ ምድር
ምሥጋና እንሰዋለን

-- ከእንግዲህስ ወዲህ -- 
',
  'hagerigna',
  19,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-020'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-021',
  'am',
  'የመለወጥ ጊዜ',
  null,
  'የመለወጥ-ጊዜ',
  'Imported from Hagerigna row 21.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  21,
  'የመለወጥ ጊዜ',
  null,
  '1. ንጹህ ዘር ተመርጦ በቤትህ ይዘራ
ልብም ተዘጋጅቶ ለመንፈስ ማደሪያ
በቤትህ ዉስጥ ያለዉ ፍጹም ተቀድሶ
በመንፈስህ ይሞላ ሥጋችን ታድሶ

አ   የመለወጥ ጊዜ ይሁንልን ጌታ 
ዝ   የመንፈስህ ሙላት የክብርህ ገፅታ
ማ   ቀርበናል ልጆችህበመሰዊያዉ ቦታ
ች    ላክልን ዘይትህን ረክተን እንድንወጣ

2. ዛሬ በማደሪያህ ኃጢአት እጅግ ሰፍቶ
ዓለም እያየለ በዕዉቀት ተስፋፍቶ
በሃይማኖት መልኩ ሰዎችን አታልሎ
መላቅጡ ጠፍቷል እዉነትህ ተረግጦ
                   
3. በልብ ጓዳችን ጣኦትን አፍርተን
አንተን ማምለክ ትተን ሌላ እያመለክን
እንዳንገኝ ዛሬ አንተን አሳዝነን
ከድፍረት ኃጢአት ጌታ ሆይ ጠብቀን

4.ታላቅ የሆነዉን ጌታችንንበመፍራት
ልባችንን ቀድሰን ለእርሱ በመስጠት
በእዉነተኛ ቃል ላይ እንድንኖር ፀንተን
እግዚአብሔር አምላክ በፀጋህ አግዘን
',
  'hagerigna',
  20,
  '{"artist":"ዘማሪ ፓ/ር አበራ ማሴቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-021'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-022',
  'am',
  'ሁሉም ነገር ሊሆን',
  null,
  'ሁሉም-ነገር-ሊሆን',
  'Imported from Hagerigna row 22.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  22,
  'ሁሉም ነገር ሊሆን',
  null,
  'ሁሉም ነገር ሊሆን ሲቸኩል ለፍፃሜ
አንተስ የቱ ጋ ነህ ወዴት ነህ ወንድሜ
የምትተኛ ንቃ ከሙታን ተነሳ
የእምነትህን ተጋድሎ ጋሻ ጦርህን አንሳ
ዛሬ ካልተነሳህ ጊዜው ይቀድምሃል
እደርሳለሁ ስትል ጨለማ ይውጥሃል
               
1.አምናም አለፈ ተክቶ ዘንድሮን
ዘንድሮም ነጎደ ጨርሶ ወራትን
ይህ የጊዜ ሩጫ ለምን ይመስልሃል
የእምነትህስ ጉዞ እንዴት ይታይሃል

-- ሁሉም ነገር ሊሆን --

2.እንደ ሌባ ድንገት እመጣለሁ እያለን
እንድንበረታ በደንብ አስጠንቅቆን
እንድንድን ፈቃዱ ሆኖ እያለ
ታዲያ የእኛ መጽናት በእምነት የት አለ

-- ሁሉም ነገር ሊሆን --
                
3.የጊዜውን መልዕክት በደንብ አስተውለን
በእምነት እንጋደል በፀጋው ታጅበን
ይህ የዛሬ ጉዞ በእንዲህ አይቀጥልም
የኖህ ዘመን ታሪክ በኛ እንዳይደገም 

-- ሁሉም ነገር ሊሆን --
',
  'hagerigna',
  21,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-022'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-023',
  'am',
  'ዓይኖቼን ምራ',
  null,
  'ዓይኖቼን-ምራ',
  'Imported from Hagerigna row 23.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  23,
  'ዓይኖቼን ምራ',
  null,
  'ዓይኖቼን ምራ ኢየሱስ አምላኬ መስቀልህ ጋ
በስባሹን ሥጋ እያየሁ እንዳልጥል የአንተን ፀጋ
በሐዘኔም በደስታ ልማጸነው ደጅህን
ባንተው ቀን እስከማየው መልካሙን ፈቃድህን
         
1. የታረድከው በግ የሱስ የእኔ ልዩ ፍቅረኛ
ሲጨንቀኝ የማዋይህ ማታዳላ እረኛ
ዘወትር ስትሰጠኝ ሳለ የሚያስፈልገኝን
በቅጽበት አነሳሁኝ ከመስቀልህ ዓይኖቼን

-- ዓይኖቼን ምራ --

2. በሰው ልጅ ከመታን በእግዚአብሔር መታመን
እጅግም ደስ ያሰኛል ይመልሳል ልብን
በስባሹን ሥጋ ማየት ያመጣል ትዕቢትን
ትዕቢትም ትቀድማለች ሳይታወቅ ውድቀትን

-- ዓይኖቼን ምራ --
       
3. ዳግም ማረኝ እላለሁ ጌታ ሆይ ጥፋቴን
ሟችና ጠፊውን ገላ አትኩሬ ማየቴን
ወደ ሞት እንዳይነዳኝ ጠላት መረቡን ጥሎ
አንተን ማየት አይሳነኝ ሰው መስቀልህን ከልሎ

-- ዓይኖቼን ምራ --

4. ለካስ ሰው ሁሉ ሰው ነው እንደ እኔ ኃጢአተኛ
ሚዛኑ የሚያዳላ ፊት አይቶ ፈራጅ ዳኛ
ከአንተ እንዳይለየኝ የሱስ ዓይኔ ሰዎችን ለምዶ
መስቀልህን ያለማምደኝ መንፈስ ቅዱስህ ወርዶ 

-- ዓይኖቼን ምራ --
',
  'hagerigna',
  22,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-023'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-024',
  'am',
  'እሥራኤላውያንን ከግብፅ ያወጣቸው',
  null,
  'እሥራኤላውያንን-ከግብፅ-ያወጣቸው',
  'Imported from Hagerigna row 24.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  24,
  'እሥራኤላውያንን ከግብፅ ያወጣቸው',
  null,
  'እሥራኤላውያንን ከግብፅ ያወጣቸው/2*/
በድል አድራጊነት የመራቸው/2*/
ዛሬም ከኛ ጋር ነው የኛ ጌታ
እስቲ እናመስግነው በእልልታ

-- እሥራኤላውያንን ከግብፅ --
               
1. ሳንቆጥብ እንዘምርለት
የምሥጋና ነዶ እናቀርብለት
ለኢየሱስ ለጌቶቹ ጌታ
ነፍሴ ታመስግነው በእልልታ

-- እሥራኤላውያንን ከግብፅ --

2. ጠላታችንን በእግሩ ረጋግጦ
በድል ሜዳ ላወጣን አስፍቶ
ክብራችን ነው እንዘምርለት ለርሱ
ሁሉን ቻይለሆነው ለንጉሡ

-- እሥራኤላውያንን ከግብፅ --
                
3. ቀንበራችንን ካንገት ሰባብሮ
የላላውን ጉልበት አጠንክሮ
እንዘምርለት ጠዋት ማታ
ዲያብሎስን ረትቶታል የኛ ጌታ

-- እሥራኤላውያንን ከግብፅ --
',
  'hagerigna',
  23,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-024'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-025',
  'am',
  'በዚህ ጉባኤ',
  null,
  'በዚህ-ጉባኤ',
  'Imported from Hagerigna row 25.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  25,
  'በዚህ ጉባኤ',
  null,
  'በዚህ ጉባኤ ጌታ የሱስ /2/ 
ይፍሰስልን ቅዱስ መንፈስ
ህይወታችን በአንተ ይታደስ
           
1.ጌታ ሆይ ጉባኤውን ባርክ ቀድስ
የተጠራው ህዝብህ በቃልህ ይታደስ
ህዝቡ ይባረክ በክብር ይሞላ
አሁን ሰዓት አይፈልግ ካንተ ክብር ሌላ

-- በዚህ ጉባኤ ጌታ --

2.ሊባረክ የመጣው ተባርኮ ይመለስ
በታላቅነትህ ሁሉም ሰው ይታደስ
ክብርህን ይወቀው ይመለስ ከክፉ
ጌታ አንተ ተገኝ አጋንንት ከዚህ ይጥፉ

-- በዚህ ጉባኤ ጌታ --
            
3.ሥጋና ደም ፀጥ ይበሉ ስላንተ ያስቡ
በአንተ ክብር ውስጥ ይጠቀለል ህዝቡ
ስለክብርህ ያውራ ሰዓቱ ያንተ ነው
የሚዘነጋውን አእምሮ ወዳንተ መልሰው

-- በዚህ ጉባኤ ጌታ --

4.የተሰበሰቡት አንተን ሊሰሙህ
ባርካቸው ጌታ በታላቅ ሙላትህ
ይባረክ ይቀደስ ቅዱስ ስምህ
ከፍ ከፍ በል በታላቅነትህ

-- በዚህ ጉባኤ ጌታ --
             
5.ጉባኤው የአንተ ነው ተገኝ በዚህ ቦታ
ሁሉም እንዲያገኝ የመንፈስ እርካታ
እኛ ዝም እንበል አንተ ተናገረን
ይኸው መጥተናል ጌታ ተቀበለን 

-- በዚህ ጉባኤ ጌታ --
',
  'hagerigna',
  24,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-025'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-026',
  'am',
  'ለአገልግሎት የመረጥከኝ',
  null,
  'ለአገልግሎት-የመረጥከኝ',
  'Imported from Hagerigna row 26.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  26,
  'ለአገልግሎት የመረጥከኝ',
  null,
  'ለአገልግሎት የመረጥከኝ በጉብዝናዬ ወራት
ፈጣሪህን አስብ ያልከኝ ዛሬ በጎልማሳነቴ
ትጉ ባርያ አድርገኝና ታማኝ በአገልግሎቴ
እፎይ ተመስገን ልበልህ ሆኜ በሰማዩ ቤቴ
             
1.የአሁኑ ብርታት ጉብዝና በድንዛዜ ሳይተካ
የመነቃቃት ኑሮዬ የእሳት ግለቱ ሳይጠፋ
እርዳኝ በአገልግሎቴ ሁሌ ተግቼ እንድሰራ
ዛሬ እምነትን ጨምርልኝ ኢየሱሴ ሆይ አደራ

-- ለአገልግሎት የመረጥከኝ --

2. አንተው በሰጠኸኝ ፀጋ ሌሎችን አገልግዬ
ስሜ በሰው ሁሉ ታውቆ ክርስቲያን ነው ተብዬ
ነገር ግን በተሰወረ በማይታወቅ ኃጢአት ዝዬ
ወድቄ እንዳልገኝ እርዳኝ እኔ ግን ከውጭ ተጥዬ

-- ለአገልግሎት የመረጥከኝ --
               
3. ዛሬ ዓይኔ የሚያየውና ልቤ የሚመኘው በሙሉ
በዓለም ዙሪያ የሚገኘው ብልጭልጩ ነገር ሁሉ
እምነቴን እየሰረቀ እያበላሸኝ ነውና
አምላክ ፀጋህን አብዛልኝ አሁንም አሁንም እንደገና

-- ለአገልግሎት የመረጥከኝ --

4. ልጅነቴ ያላለቀ ብላቴና ነኝና
ወተት ብቻ መጋት ትቼ ምግብ አልለመድኩምና
ጠላት አታልሎ እንዳይወስደኝ ወደ ዘላለሙ ጥፋት
በማስተዋል እንድራመድ ስጠኝ የመንፈስህን እሳት 

-- ለአገልግሎት የመረጥከኝ --
',
  'hagerigna',
  25,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-026'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-027',
  'am',
  'በስም ክርስትና',
  null,
  'በስም-ክርስትና',
  'Imported from Hagerigna row 27.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  27,
  'በስም ክርስትና',
  null,
  '1. በስም ክርስትና በመግባት በመውጣት
ጌታን በማገልገል ሳይቀደስ ህይወት
አይገኝም በእውነት የሰማይ መንግሥት
ቀኑ ሳለ ተመለስ እንዳትጠፋ በእሳት
          
ክፋት በምድር ላይ ሲስፋፋ እያየህ
የሰይፍ የጦር ወሬ ዘውትር እየሰማህ
ተነሳ ወንድሜ ከእንቅልፍህ ንቃ
በምድር ላይ መንከራተቱ ቶሎ እንዲያበቃ

2. ጠላት ተሰልፎ በዙሪያህ ሲያገሳ
ከምድር ላይ ሊያጠፋህ በቁጣ ሲነሳ
እንዴት ዝም ትላለህ ጋሻ ጦርህን አንሳ
ጌታ ከጎንህ ነውና አትፍራ ተነሳ

-- ክፋት በምድር ላይ --
          
3. በክፉ ጠላት ዛቻ ሁሌ የሚጨነቁ
በችግር በመከራ ሌትተቀን የሚሳቀቁ
ጌታን ተቀብለው ወደጉያው እንዲገቡ
አዋጁን አሰማ ለእውነት እንዲታዘዙ

-- ክፋት በምድር ላይ --

4. መንገዱ ጠባብ ነው ጉዞውም ጠመዝማዛ
ችግር ሥቃይ መከራ እጅግም የበዛ
ቢሆንም ይዘለቃል ይገፋል ያ ሁሉ
እርሱ ይደግፍሃል በማይደክም ኃይሉ 

-- ክፋት በምድር ላይ --
',
  'hagerigna',
  26,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-027'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-028',
  'am',
  'ዓይኔ ማዳኑን አይታለችና',
  null,
  'ዓይኔ-ማዳኑን-አይታለችና',
  'Imported from Hagerigna row 28.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  28,
  'ዓይኔ ማዳኑን አይታለችና',
  null,
  '1.አዳኙን ለማየት ስናፍቅ ሳል
ጌታዬን ለማየት ስጨነቅ ሳል
ይኸው ታዲያ ዛሬ ጊዜው ሲደርስ
አየሁት አዳኜን ጌታ የሱስ
            
ዓይኔ ማዳኑን አይታለችና
ይመስገን እላለሁ ይመስገን እላለሁ

2.ለብዙ ጊዜያት ስጠባበቅ
የአዳኙን ማንነት በመናፈቅ
ዛሬ ግን በጊዜው ተገናኘኝ
ማንነቱን ለኔ ገለጸልኝ

-- ዓይኔ ማዳኑን --
           
3.መሻቴን አውቆልኝ ናፍቆቴንም
ላየው የነበረኝ ጥማቴንም
ይኸው ዛሬ ዓይኖቼን ከፍቶልኝ
ማንነቱን እንዳውቅ አደረገኝ

-- ዓይኔ ማዳኑን --

4.ነፍሴ ናፍቃ ነበር ልትረካ
ጌታዋን ተረድታ ልትመካ
ይኸው ዛሬ ልታውቀው በቅታለች
በዚህ ታላቅ ጌታ ትመካለች 

-- ዓይኔ ማዳኑን --
',
  'hagerigna',
  27,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-028'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-029',
  'am',
  'የንጉሥ ልጆች ነን',
  null,
  'የንጉሥ-ልጆች-ነን',
  'Imported from Hagerigna row 29.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  29,
  'የንጉሥ ልጆች ነን',
  null,
  '1.ለሰው ብንመስል ተንከራታች
ምስኪን ደሀ አመድ አፋሽ
ብንመስላቸው ሁሉ የሌለን
በየሱስ ስም ሀብታሞች ነን
        
የንጉሥ ልጆች ነን ምንም አላጣንም
ሁሉ በእጃችን ነው አንድም አይጎድለንም
ከእርሱ የተነሳ ባለጠጋዎች ነን
እግዚአብሔር ይመስገን

-- የንጉሥ ልጆች ነን --

2. ሞቱ ሲባል ህያዋን ነን
ድሆች ስንሆን ሁሉም አለን
ከኛ አልፎ ሞልቶ ተርፎ
ሌሎችን ሀብታም እናደርጋለን

-- የንጉሥ ልጆች ነን --
           
3. ከሀብት የሚበልጥ ሰላም አለን
ለምድር ኑሮ አንጨነቅም
የሚያስጨንቀንን ለእርሱ ትተን
እንኖራለን ተደስተን 

-- የንጉሥ ልጆች ነን --
',
  'hagerigna',
  28,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-029'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-030',
  'am',
  'የፅዮኑ ጉዞ ረጅም ሆኖ',
  null,
  'የፅዮኑ-ጉዞ-ረጅም-ሆኖ',
  'Imported from Hagerigna row 30.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  30,
  'የፅዮኑ ጉዞ ረጅም ሆኖ',
  null,
  '1.የእምነቴን ማነስ ጠላት አይቶ
በክፉ ዓይኖቹ ተመልክቶ
እንዳይወስደኝ ጌታ ጠብቀኝ
እንዳይወስደኝ የሱስ አግዘኝ
             
አ   የፅዮኑ ጉዞ ረጅም ሆኖ
ዝ   እምነቴ በድካም ተሸፍኖ
ማ    እንዳልወድቅ ጌታ ጠብቀኝ
ች    እንዳልወድቅ የሱስ አግዘኝ

2.ስደት መከራውን ሁሉ አልፌ
ክፉ ጠላቶቼን አሸንፌ
ከሞት ወዲያ ያለውን አክሊሌን
የኔ ጌታ እንድወርስ እርዳኝ
           
3.ከእለታት አንድ ቀን ስትመጣ
ስትገለጥ በአስፈሪው ግርማ
ባስቀመጥከኝ ቦታ እንድቆይህ
ፀጋህን አብዛልኝ ጌታ እባክህ

4.ውሸትን እውነት አስመስሎ
በጨለማ ዓይኔን ጋርዶ አታሎ
አባብሎ እንዳይወስደኝ ይህ ጠላቴ
ፀጋህን አብዛልኝ በሕይወቴ
             
5.ክርስቲያኖች ሁሉ ያመናችሁ
በጌታ የሱስ ደም የነፃችሁ
ተስፋችን ኢየሱስ ሲመጣልን
ለመንግሥቱ ያብቃን ሁላችንን 
',
  'hagerigna',
  29,
  '{"artist":"ዘማሪ ፓ/ር አበራ ማሴቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-030'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-031',
  'am',
  'በምሥጋና የተፈራህ',
  null,
  'በምሥጋና-የተፈራህ',
  'Imported from Hagerigna row 31.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  31,
  'በምሥጋና የተፈራህ',
  null,
  'በምሥጋና የተፈራህ ድንቅ ሥራህ በእጅህ ነው
በቅድስና የከበረ እንደ አንተ ያለ አምላክ ማን ነው
        
1.ባህር ደርቆ በፊታቸው ህዝብህ በየብስ ሲሻገሩ
ፋርዖን ሲያድን በሰረገላው ሊያስቀራቸው በሀገሩ
ድንቅን ሥራ በማድረግህ በአህዛብ ዘንድ የከበርህ
የሚሳንህ ምንም የለም ብሩክ ይሁን ቅዱስ ስምህ

-- በምሥጋና የተፈራህ --

2.ድንቅ ማድረግ ልማድህ ነው አምላክ ዘላለም ህያው ነህ
ከዲያብሎስ እጅ የታደግከን እግዚአብሄር ተዋጊ ነህ
ተራራውን በሥልጣንህ በቃልህ ኃይል ትንዳለህ
ለዘላለም እዘምራለሁ ኃይሌ ዝማሬዬም እግዚአብሔር ነህ

-- በምሥጋና የተፈራህ --
      
3.ለደካማው ድጋፍ ምርኩዝ መታመኛው ትሆናለህ
መካኒቱን በልጅ ባርከህ አፍዋን በሳቅ ትሞላለህ
ፍጥረታትን የምትመግብ በጎነትን የተሞላህ
አምላኬ ሆይ ላመስግንህ መድኃኒት ነህ ለተጠጋህ

-- በምሥጋና የተፈራህ --

4.በድርቅ ዓመት አለት አዘህ ውኃን ለህዝብህ የምታጠጣ
ምድር ሰማይ በእጅህ ነው አንድም የለም የሚታጣ
የኔ ጌታ አከብርሃለሁ እንዳንተ ያለውን አላየሁም
ፍጥረት ሁሉ ያመስግኑህ ከፍ ከፍ በል ለዘላለም 

-- በምሥጋና የተፈራህ --
',
  'hagerigna',
  30,
  '{"artist":"ዘማሪ ማሞ ጴጥሮስ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-031'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-032',
  'am',
  'የእኔ ቤት ፈርሶ',
  null,
  'የእኔ-ቤት-ፈርሶ',
  'Imported from Hagerigna row 32.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  32,
  'የእኔ ቤት ፈርሶ',
  null,
  'የእኔ ቤት ፈርሶ ወድቆ ሳለ
እናንተ ግን በተሸለመው ቤት
ልትኖሩ ይህ ጊዜው ነውን
ይላል የሠራዊት ጌታ እግዚአብሄር
          
1.ቤቴ ፈርሶ ለጠላት መቃለጃ ሆኗል
ከነበረበት ቦታ ፍጹም ጠፍቷል
የእናንተ ቤት ግን በጌጥ ተሸልሟል
ስለዚህ በእናንተ ልቤ እጅግ አዝኗል

-- የእኔ ቤት --

2.ማንነው ከእናንተ ለቤቴ የሚቀና
ቀንና ሌሊት ፈጽሞ የማይተኛ
ለቤቴ መፍረስ የሚያዝን ማንም የለም
ልባችሁ ተጠምዷል በዓለም ምኞች

-- የእኔ ቤት --
            
3.እናንተ ልበ ደንዳኖች ቃሌን አድምጡ
ወደ ተራራ ሂዱ እንጨትን አምጡ
የወደቀውን ቤቴን አንሱ
መቅደሴን መልሳችሁ እንደገና አዲሱ

-- የእኔ ቤት --

4.እናንተ ለእኔ ከታዘዛችሁ
የፈረሰውን ቤቴን ከጠገናችሁ
ልቤ በእናንተ እጅግ ደስ ይለዋል
ቃል ኪዳኔም በእናንተ ይፈጸማል 

-- የእኔ ቤት --
',
  'hagerigna',
  31,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-032'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-033',
  'am',
  'እንዲህ ያለ አምላክ',
  null,
  'እንዲህ-ያለ-አምላክ',
  'Imported from Hagerigna row 33.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  33,
  'እንዲህ ያለ አምላክ',
  null,
  '1.ይውረድ /3/ በኛ ላይ የጌታ መንፈስ
ዲያብሎስ ይፈር ምሽጉ ይፍረስ
በጌታችን ስም አሸናፊዎች ነን
የድል ዝማሬ ዛሬም እናዜማለን

አ   እንዲህ ያለ አምላክ ከየት ይገኛል
ዝ   እንዲህ ያለ ጌታ ከየት ይገኛል
ማ   ዲያብሎስን ረትቶት/2/
ች   አሸናፊዎች አረገን ሞታችንን ሞቶ
           
2.በኃይል በኃይል በክብር ከፍ ብለን እንታያለን
ጠላታችንን በእግራችን ረግጠን
በኮረብቶች ላይ በሥልጣን ቆመን
ምድርን በሙሉ አሜን እናበራለን

3.አየን አየን የጌታችን ኃይል በኛ ሲሠራ
ዘንዶን ቆራረጥን በየሱስ ካራ
ቃሉ ሠይፍ ነው የሚነድ እሳት
ለብልቦ የሚፋጅ የሠይጣንን አናት
          
4.ይምጣ ይምጣ ይምጣ መንፈስህ ሰማይን ዘልቆ
ደመናው ይታይ መቅደስህን ሞልቶ
መንፈስህን አፍስስ ላለው ተጠምቶ
ህዝብህ ይፈንድቅ አሜን በሐሴት ተሞልቶ 
',
  'hagerigna',
  32,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-033'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-034',
  'am',
  'ለረዳን ለእግዚአብሔር',
  null,
  'ለረዳን-ለእግዚአብሔር',
  'Imported from Hagerigna row 34.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  34,
  'ለረዳን ለእግዚአብሔር',
  null,
  'ለረዳን ለእግዚአብሔር ለስሙ እንዘምራለን
ተመስገንልን እያልን እንቀኝለታለን
ክብር እንሰጣለን
               
1.አምላካችን ባይረዳን ባይጠነቀቅልን
ጠላታችን ዲያብሎስ ፈጥኖ ባጠፋን ነበር
ዙሪያችን የሚዞረው ጠላት ከእርሱ ሊለየን
የሱስ ጌታ ነውና ለዛሬ ደርሰናል

-- ለረዳን ለእግዚአብሔር --

2.በድካማችን ብዛት እግራችን ሲብረከረክ
መፍገምገም በርትቶብን ለመውደቅ ስንቃረብ
እግዚአብሔር ግን እጅጉን አበርትቶን
ከምርኮ መልሶን በፊቱ መቆም ቻልን

-- ለረዳን ለእግዚአብሔር --
               
3.ለሚያስፈልገን ሁሉ ከእኛ ጋራ ሆኖ
በበረከቱ ሞልቶ ነፍሳችንን አርክቶ
አንድም ሳያጓድል እስከ ዛሬ መርቶናል
የእርዳታ እጆቹ ከእኛ ጋር ሆነዋል 

-- ለረዳን ለእግዚአብሔር --
',
  'hagerigna',
  33,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-034'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-035',
  'am',
  'እንዴት ወደድከኝ',
  null,
  'እንዴት-ወደድከኝ',
  'Imported from Hagerigna row 35.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  35,
  'እንዴት ወደድከኝ',
  null,
  'እንዴት ወደድከኝ ጌታ እንዴት ወደድከኝ
ዓሣ አጥማጁን ሰው እንዴት አሰብከኝ
እጅግ ገርሞኛል ጌታ አመራረጥህ
ለኔም ደረሰ ይህ ድንቅ ማዳንህ
             
1.እኔማ አውቃለሁ ኃጢአተኛ ነኝ
እንደ ሥራዬ ቢሆን ሞት የሚገባኝ
በደማስቆ መንገድ ድንገት አገኘኸኝ
ዓይኔን አበራህ ጌታ ሃናንያን ልከህ

-- እንዴት ወደድከኝ --

2.እጅግ የተማሩ አውቀናል የሚሉ
በዓለም ዙሪያ በዝተዋል አልጠፉም አሉ
ከደሳሳ ጎጆ እኔን መምረጥህ
ለእኔ ደነቀኝ ጌታ አደራረግህ

-- እንዴት ወደድከኝ --
              
3.በኃይል በጉልበት አላስገደድከኝ
በፍቅር ብቻ ጌታ እኔን ማረክከኝ
እኔም ተሸነፍኩና ተከተልኩህ
ከትላንት ይልቅ ዛሬ እጅግ ወደድኩህ

-- እንዴት ወደድከኝ --

4.ማዳን ቸርነትህ ለእኔ ብዙ ነው
ስንቱን እቆጥራለሁ እጅግ ድንቅ ነው
ከትቢያ አንስተህ ታስደንቃለህ
ምንስ እለሃለሁ አንተ ልዩ ነህ

-- እንዴት ወደድከኝ --
',
  'hagerigna',
  34,
  '{"artist":"ዘማሪ ዳታን ደምሴ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-035'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-036',
  'am',
  'ለተጠማ ሁሉ የሚዳረስ',
  null,
  'ለተጠማ-ሁሉ-የሚዳረስ',
  'Imported from Hagerigna row 36.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  36,
  'ለተጠማ ሁሉ የሚዳረስ',
  null,
  '1.ለተጠማ ሁሉ የሚዳረስ 
የሚያረካ የህይወት ምንጭ የሱስ
ኑና በነፃ ጠጡ ይላል
ለፈለገ ሁሉ ያዳርሳል
         
አ   የህይወት ዉሃ የጠማችሁ
ዝ   የህይወት ምግብ የራባችሁ 
ማ   ለዘላለም የሚያረከዉን 
ች   ኑና ቅመሱት ኢየሱስን

2 ለተራበ ሁሉ የሚዳረስ
የህይወት እንጀራ ኢየሱስ
ኑና በነፃ ብሉ ይላል
ሰይለያይ ለሁሉም ያዳርሳል
          
3.ለነፍሳችሁ ለጨነቃችሁ
በመንፈስም ለደረቃችሁ
ልምላሜዉን ሊሰጣችሁ
ኑና እረፉ ይላል ጌታችሁ

4.መዳናችሁን ፈልጋችሁ
የምትጨነቁ ለነፍሳችሁ
መዳን በሌላ የለምና
ኑ እረፉ በጌታ እመኑና 
',
  'hagerigna',
  35,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-036'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-037',
  'am',
  'ጌታ እባክህን ፈውሰኝ',
  null,
  'ጌታ-እባክህን-ፈውሰኝ',
  'Imported from Hagerigna row 37.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  37,
  'ጌታ እባክህን ፈውሰኝ',
  null,
  'ጌታ እባክህን ፈውሰኝ የሱስ አደራ ለውጠኝ 
አባት ለክብርህ አድሰኝ
የሌላውን ቁስል እንድፈውስ ጸጋህን ስጠኝ
               
1.ስንቱ ተማረረ በእኔ ህይወት
በሸካራ ቃሌ በሐሜት ትዕቢት
ስንቱን አደማሁት አቆሰልኩት
በምህረትህ እየኝ አባ አባት

-- ጌታ እባክህን ፈውሰኝ --

2.ለሚገባ ሁሉ እንቅፋት ነኝ
የሚወጣውን በክፉ እገፋለሁ
በዚህ ዓይነት እስከየት እጓዛለሁ
ለውጠኝ ጌታ ሆይ በእጅህ አለሁ

-- ጌታ እባክህን ፈውሰኝ --
               
3.ባለማስተዋሌ ስንቱን ጎዳሁ
በምላሴ ባልጩት ስንቱን ወጋሁ
አዲስ ህይወት ፈጥረህ ለውጠኝ
ከዚህ ከረከሰው ሥጋ ለየኝ

-- ጌታ እባክህን ፈውሰኝ --

4. ወንድምህ ወዴት ነው ብሎ ቢለኝ
ድንገት እንደ ቃየል ቢጠይቀኝ
ምን እመልሳለሁ ምን እላለሁ
እስኪ አሁን ልፈልገው እሄዳለሁ

-- ጌታ እባክህን ፈውሰኝ --
              
5. ብዙዎች ከአንተ የራቁት ስለ እኔ ነው
በማይመች ኑሮዬ በአመጼ ነው
ያለፈውን ሁሉ ይቅር በለኝ
የሱስ አዲስ ምዕራፍ አስጀምረኝ 

-- ጌታ እባክህን ፈውሰኝ --
',
  'hagerigna',
  36,
  '{"artist":"ዘማሪ ማሞ ጴጥሮስ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-037'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-038',
  'am',
  'አንተ የፍጥረታት ጌታ',
  null,
  'አንተ-የፍጥረታት-ጌታ',
  'Imported from Hagerigna row 38.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  38,
  'አንተ የፍጥረታት ጌታ',
  null,
  'አንተ የፍጥረታት ጌታ መቼ ነው የምትመጣው
አንተ የበለሷ ጌታ መቼ ነው የምትመጣው
የመከሩ ጌታ መቼ ነው የምትመጣው
          
1.ድንጋይ በድንጋይ ላይ መፍረሱ አይቀርም
ይህን አታድንቁ ብለህ ተናግረሃል
ንገረን መቼ ይሁን የአንተ መምጫ
ፍጹም የሚያበቃው የምድሩ እሩጫ

-- አንተ የፍጥረታት ጌታ --

2.እምነታችን ደክሞ በእንቅልፍ እያለን
መገለጥህ ቢሆን እኛ እንጠፋለን
ይህን ታላቅ ምስጢር ግለጥልን ጌታ
ንገረን መቼ ይሁን አሜን ማራናታ

-- አንተ የፍጥረታት ጌታ --
         
3.መለከት ተነፍቶ ሙታን የሚነቁ
ሞትን ያልቀመሱ በክብር የሚደምቁ
በደመና ሆነን ከአንተ ጋራ
የምንሰበሰብ በፅዮን ተራራ

-- አንተ የፍጥረታት ጌታ --

4.መከራ ችግሩ ሁሉ የሚጠፋው
የኃጢአት ሥር ተነቅሎ የሚቃጠለው
መቼ ይፈፀማል ይህ ታላቅ ተስፋ
የፅድቅ ፀሐይ ወጥቶ ከቶ የማይጠፋ 

-- አንተ የፍጥረታት ጌታ --
',
  'hagerigna',
  37,
  '{"artist":"ዘማሪ በየነ በዲቻ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-038'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-039',
  'am',
  'አሠራርህ ባይገባኝ',
  null,
  'አሠራርህ-ባይገባኝ',
  'Imported from Hagerigna row 39.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  39,
  'አሠራርህ ባይገባኝ',
  null,
  'አ   አሠራርህ ባይገባኝ
ዝ   ያልከዉ ባይመቸኝ
ማ   ግን አንድ ነገር አዉቃለሁ
ች   ሀሳብህ ለኔ መልካም ነዉ
             
1.መርከቡ ዉስጥ ግባ ካልከኝ ጌታ
ቢኖርም እንኳ የአራዊት መንጋ
አንተ ከኔ ጋር ነህ አልፈዋለሁ
ከጥፋትም ድኜ አከብርሃለሁ

2.የያዝኩት በሙሉ ከእጄ ጠፍቶ
ልቤ በጨለማ በሀዘን ተዉጦ
አንተም የረሳኸኝ ቢመስለኝም
ሀሳብህ መልካም ነዉ አትጥለኝም
             
3.ካለሁበት ሀገር እንድወጣ
ትዕዛዝህ ቢመጣ ከላይ ጌታ
ርስቴንም ትቼ እሄዳለሁ
አንተ ያልከዉ ይበልጣል እሰማለሁ

4.ተሰድጄ እንድኖር በሰዉ ሀገር
ፈቃድህ ካደረግከዉ እግዚአብሔር
ኑሮዬ በሙሉ ቢጨልምም
አንተ ከኔ ጋር ነህ ከቶ አልሞትም 
',
  'hagerigna',
  38,
  '{"artist":"የገርጂ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-039'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-040',
  'am',
  'በክብር ላይ ክብር ይሁን',
  null,
  'በክብር-ላይ-ክብር-ይሁን',
  'Imported from Hagerigna row 40.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  40,
  'በክብር ላይ ክብር ይሁን',
  null,
  'በክብር ላይ ክብር ይሁን ለአምላኬ
በክብር ላይ ክብር ይሁን ለመሠረቴ
በክብር ላይ ክብር ይሁን ለአለቴ
መድኃኒት ተገኘላት ለሕይወቴ
              
1.የትም ስባዝን ስዞር ከርሜ
በመውጣት በመግባት እንዲሁ ደክሜ
ባለቀ ሰዓት አሁን ደርሼ
ከሞት አመለጥኩ ፍቅሩን ቀምሼ

-- በክብር ላይ ክብር --

2.እጅግ ስጨነቅ ለመሰረቴ
ጣዕም እንዲኖረው ለሕይወቴ
ለካስ ኢየሱስ ሽታዉ ጣዕም ነው
እውነተኛ ወይን የሚጣፍጠው

-- በክብር ላይ ክብር --
            
3.የሱስ ጌታ ነው ሲሉ ሰምቼ
ዝናውንና ሥራውን አይቼ
እኔም ተጠጋሁኝ በደስታ
እንዳሉኝም ነው እውነትም ጌታ

-- በክብር ላይ ክብር --

4.ኑሮን ስታወርዱ ስታወጡ
ከሚያዳልጠው ጭቃና ድጡ
ለምን የሱስን አታማክሩም
ታላቅ ወንድም ነው በምክሩም ግሩም 

-- በክብር ላይ ክብር --
',
  'hagerigna',
  39,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-040'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-041',
  'am',
  'በመከራም ቢሆን ምሥጋና',
  null,
  'በመከራም-ቢሆን-ምሥጋና',
  'Imported from Hagerigna row 41.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  41,
  'በመከራም ቢሆን ምሥጋና',
  null,
  'በመከራም ቢሆን ምሥጋና
በፈተናም ቢሆን ምሥጋና
የከንፈሬ ፍሬ ለኢየሱስ ይገበዋልና
                
1.እንዳልሆነ ሆኖ ኑሮ ብታይህም
እግዚአብሄር የተወህ መስሎ ቢሰማህም
ማመስገን አትርሳ በፈተና ጊዜ
ክብር ለእርሱ ስትሰጥ ይጠፋል ትካዜ

-- በመከራም ቢሆን --

2.መላ ሁሉ ጠፍቶህ ግራ ስትጋባ
ዘመድ ወዳጅ ርቆህ ሆነህ ረዳት አልባ
ተስፋህን አትቁረጥ ወንድሜ አትስጋ
በምሥጋና መንፈስ ቅረብ ኢየሱስ ጋ

-- በመከራም ቢሆን --
            
3.ለሁሉም ጊዜ አለው ሁሉምነገር ያልፋል
ደስታም ቢሆን ሀዘን ቀንም ይለወጣል
ሀብትና ሞገስም አንድ ቀን ይመጣል
ጊዜና ዕድል ግን ከአንዱ ያገናኘናል

-- በመከራም ቢሆን --

4.በመከራ ጊዜ ማመስገን እንድችል
ዓለምን በእምነት አሸንፌ በድል
በሚጣፍጥ ሆነ በሚመረው ነገር
አመስጋኝ እንድሆን እርዳኝ እግዚአብሄር

-- በመከራም ቢሆን --
',
  'hagerigna',
  40,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-041'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-042',
  'am',
  'ስንቱ ይወራ',
  null,
  'ስንቱ-ይወራ',
  'Imported from Hagerigna row 42.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  42,
  'ስንቱ ይወራ',
  null,
  'ስንቱ ይወራ ለኛ ያረገዉ/2x/
ከአእምሮ በላይ ነው የጌታ ዉለታዉ/2x/
ሊገመት ሊለካ የማይቻል ነው ፍቅሩ/2x/
ምሥጋናን እናቅርብ ሁል ጊዜ ለክብሩ 
ሁሌም ለክብሩ

1.በችግራችንም ወዲያዉ ከተፍ የሚልልን
ከእናትም ከአባትም በላይ ለኛ የሚያስብልን
በጠራንም ጊዜ ምላሽ ሰጥቶ የሚያረካን
ዉዱ የኛ ጌታ ረዳታችን ይክበርልን

-- ስንቱ ይወራ --
         
2. ሳንወለድ በፊት በስማችን ጠርቶ ያወቀን
በልጅነታችን ወዶ ቀንበር ያሸከመን
ለክብር መንግሥቱ በከበረዉ ደሙ የዋጀን
ዉዱ የኛ ጌታ ከፍ ይበል ይባረክልን

-- ስንቱ ይወራ --

3.በበረታብን ጦር በጠላት ላይ የሚበረታ
አስጨናቂዉን ሁሉ በኃያል ክንዱ የሚመታ
በማንም ለማንም አንዴም ከቶ የማይረታ
ከጧት እስከ ማታ ምሥጋናችን ለዚህ ጌታ

-- ስንቱ ይወራ --
            
4.ዓለምም ምኞቱም ሁሉም ነገር ቶሎ ያልፋል
ለኛስ ለልጆቹ ጌታ የሱስ ይበጀናል
ብለን ተጠጋነዉ ሳያሳፍር ተቀበለን
ስለዚህ በቤቱ ለዘላለም እንኖራልን

-- ስንቱ ይወራ --
',
  'hagerigna',
  41,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-042'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-043',
  'am',
  'ሦስት መላዕክት አየሁ',
  null,
  'ሦስት-መላዕክት-አየሁ',
  'Imported from Hagerigna row 43.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  43,
  'ሦስት መላዕክት አየሁ',
  null,
  'ሦስት መላዕክት አየሁ በሰማይ ሲበሩ
የዘላለምን ወንጌል ይዘው እያበሰሩ
ለነገድ ለቋንቋ ለሕዝብም በሙሉ
የፍርዱ ሰዓት ደርሷል ንቁ ንቁ እያሉ
                     
1.በሰማይ መኻከል ይበር የነበረው
አንደኛዉ መልዓክ እንዲህ ነበር ያለው
የፍርዱ ሰዓት ደርሷል እግዚአብሔርን ፍሩ
የሰማይና የምድር ፈጣሪን አክብሩ

-- ሦስት መላዕክት --

2.የሁለተኛዉ መልዓክ ከፍ ያለው አዋጅ
አህዛብን ሁሉ ስታ ያሳሳተች
የዝሙትዋን ቁጣ ወይን ጠጅ ያጠጣች
ታላቂቱ ባቢሎን ወደቀች ወደቀች

-- ሦስት መላዕክት --
                   
3. ሦስተኛዉም መልዓክ ደግሞ ተከተለው
ከፍ ባለው አዋጅ እንዲህ እያለ
የአውሬውን ምልክት የሚቀበል ሁሉ
በሌትም ሆነ ቀን ዕረፍት የላቸውም

-- ሦስት መላዕክት --

4.ዳግመኛ ምጻቱን ከሚጠቁት ጋር
መስቀልህ ሥር ይሁን የእኔ መቃብር
በድል እንድነሳ በትንሳኤ ማግሥት
እድሌን አድርገው ፀንተው ከሚኖሩት 

-- ሦስት መላዕክት --
',
  'hagerigna',
  42,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-043'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-044',
  'am',
  'ሰዉ ዓለምን ቢያተርፍ',
  null,
  'ሰዉ-ዓለምን-ቢያተርፍ',
  'Imported from Hagerigna row 44.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  44,
  'ሰዉ ዓለምን ቢያተርፍ',
  null,
  '1. በብርና በወርቅ እጅግ ቢታወቁ 
ከኃያሉ ጌታ ከፀጋዉ ከራቁ
የገንዘብ ክምችት ብርም ሆነ ወርቅም 
ከእግዚአብሔር ቁጣ ቀን ሊያድነን አይችልም
           
ሰዉ ዓለምን ቢያተርፍ ነፍሱን ግን ቢያጎድል
እፎይታ ከሌለዉ የነፃነት እድል
ያለ የሱስ ኑሮ ካለ አምላክ እገዛ
ምንስ ይረባዋል ዓለምን ቢገዛ

2.ከጌታ ቁጣ ቀን ድንገተኛ ጥፋት
ለዘለዓለሙ ከሚነደዉ እሳት
የማምለጫ ዘዴ እቅድ መንገዳችን 
ገንዘባችን ሳይሆን የሱስ ነዉ ጌታችን

-- ሰዉ ዓለምን ቢያተርፍ --
                
3.ይህን ስፍራ ትቼ ወደዚያ እሄዳለሁ
ነግጄም አትርፌ ነፍሴን አረካለሁ
እያልን በከንቱ ሀሳብ ከመደርደር
በኑሯችን ሁሉ ይቅደም እግዚአብሔር

-- ሰዉ ዓለምን ቢያተርፍ --

4.በዚህች ዓለም ፍቅር የተሳሰራችሁ
ከባርነት ቀንበር ያልተላቀቃችሁ
ሸክም ከብዶባችሁ መሄድ ያቃታችሁ
ኑ ወደ እኔ ይላችኋል የሚያሳርፋችሁ 

-- ሰዉ ዓለምን ቢያተርፍ --
',
  'hagerigna',
  43,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-044'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-045',
  'am',
  'ንጹህ ምንጭ አለን',
  null,
  'ንጹህ-ምንጭ-አለን',
  'Imported from Hagerigna row 45.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  45,
  'ንጹህ ምንጭ አለን',
  null,
  'ንጹህ ምንጭ አለን የምንጠጣዉ 
ከተራራ አለት ላይ የሚወጣዉ
አንሯሯጥም ወዲያ ወዲህ
ግብፅ ይበቃናል ከእንግዲህ
           
1.ድንጋይ ኮረቱን አንከባልሎ
ግንዳ ግንዱን ፈነቃቅሎ
በአሸናፊነት ሁሉን ታግሎ
የወጣ ምንጭ አለን ተስተካክሎ

-- ንጹህ ምንጭ አለን --

2. እሾክ አሜከላን መነጣጥሮ
አፈሩን ቦርቡሮ አንሸርሽሮ
ከርቀት መጥቶ የመነጨ
የአምላክ ብሩክ ቃል ተሰራጨ

-- ንጹህ ምንጭ አለን --
         
3. እጅግ የሚያስደንቅ የጠለለ
ጠላትን የሚዋጋ የተሳለ
በሽታን የሚያድን የሚፈውስ
ሕይወትን ሚለውጥ የሚያድስ

-- ንጹህ ምንጭ አለን --

4. ምድራዊውን መቅደስ የሚያነፃ
ለሰማዩ ርስት የሚያበቃ
ከምንም ከምንም የተሻለ
ንፁህ ምንጭ አለ የጠለለ

-- ንጹህ ምንጭ አለን --
',
  'hagerigna',
  44,
  '{"artist":"ዘማሪ ፓ/ር ደገፌ ትርካሶ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-045'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-046',
  'am',
  'ይህን ታላቅ ምስጢር',
  null,
  'ይህን-ታላቅ-ምስጢር',
  'Imported from Hagerigna row 46.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  46,
  'ይህን ታላቅ ምስጢር',
  null,
  'ይህን ታላቅ ምስጢር መናፍቃን
አታላይ ሟርተኞች ኮከብ ቆጣሪያን
ሊያዉቁት አይችሉም ምስጢርህን
ለኛ ለልጆችህ ያረከዉን
          
1.ሞራ ገላጭ ጠንቋይ ሟርተኛ
ምንም ነገር አያዉቅ መተተኛ
ነገር ግን ምስጢሩን የሚገልፀዉ
ታላቅ አምላክ ያለዉ በሰማይ ነዉ

-- ይህን ታላቅ ምስጢር --

2. የሚሆነዉን ነገር ለልጆቹ
ሰዉሮ አያዉቅም ለታማኞቹ
በሰማያት ያለዉ የኛ አምላክ
ምስጢር የሚገልፀዉ ጌታ ይባረክ

-- ይህን ታላቅ ምስጢር --
            
3.የኤልያስ አምላክ ወዴት ነዉ
የብኤልን ነቢያት ያሳፈረዉ
ብንጠራዉ ጌታ አይዘገይም
ረጂያችን እግዚአብሔር ነዉ አይተወንም

-- ይህን ታላቅ ምስጢር --

4.የቅርባችን አምላክ ኃያል ጌታ
ከእኛ ጋራ ያለዉ የማይረታ
የሎዶቅያ ወዳጅ አይረሳንም 
የሞተልን አምላክ አይተወንም 

-- ይህን ታላቅ ምስጢር --
',
  'hagerigna',
  45,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-046'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-047',
  'am',
  'ከተበተንንበት የሱስ ሰብስቦናል',
  null,
  'ከተበተንንበት-የሱስ-ሰብስቦናል',
  'Imported from Hagerigna row 47.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  47,
  'ከተበተንንበት የሱስ ሰብስቦናል',
  null,
  'ከተበተንንበት የሱስ ሰብስቦናል
ጠላታችን አፍሮ ለኛ ድል ሰጥቶናል
ዳግም አገናኘን በሠላም በጤና
ምሥጋና እንሰዋለን ለአምላክ እንደገና
                 
1.ጠላት ሊበትነን እጅግ ተማከረ
በየጎዳናችን ሲያስፈራራን ዞረ
ጌታም ለሕዝቦቹ ምህረቱን ጨመረ
ጠፉ ያለን ጠላት እንዲያው ዋሽቶ ቀረ

-- ከተበተንንበት --

2.ከእንግዲህ ወዲህ ከቶ አንገናኝም
እንደ ወትሮው ሆነን ሁሌ አንተያይም
እንዲህ ብለን ሳለን ተስፋ ሁሉ ቆርጠን
ክብር ለእግዚአብሄር ዳግም አገናኘን

-- ከተበተንንበት --
                  
3.አምላክ ለህዝቦቹ ብርታትን ሚሰጠው
ልጆቹን ከውድቀት ፈጥኖ የሚያነሳው
ለጠላት ቢሆንም የጥፋት ዋዜማ
እኛ ግን ተሞላን በምሥጋና ዜማ

-- ከተበተንንበት --

4.ብንወድቅም ለጌታ ብንነሳም ለጌታ
ብንሞት ለጌታ ብንኖርም ለጌታ
ታዲያ ለምንድንነው የጠላት ድንፋታ
የሱስ ከኛ ጋር ነው የሠላም እርካታ

-- ከተበተንንበት --
',
  'hagerigna',
  46,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-047'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-048',
  'am',
  'እስኪ ዞር ብዬ',
  null,
  'እስኪ-ዞር-ብዬ',
  'Imported from Hagerigna row 48.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  48,
  'እስኪ ዞር ብዬ',
  null,
  'እስኪ ዞር ብዬ ልመልከት ጌታ ያረገልኝን
ያኔ እጆቼን ይዞ እየመራ ያሻገረኝን
       
1.ከረግረግ ጭቃ ያወጣኝን
ያኔ ከሥቃይ ያዳነኝን
እኔን በጫንቃዉ ተሸክሞ
ያሻገረኝን ባህሩን ከፍሎ

እስኪ ዞር ብዬ ልመልከት ጌታ ያረገልኝን
ያኔ እጆቼን ይዞ እየመራ ያሻገረኝን
               
2.ማዕበል ገፍትሮ አስደንግጦኝ
ተደናግሬ ግራ ገብቶኝ
ባህሩን እንደ የብስ በእግሩ ረግጦ
ከሞት አዳነኝ የሱስ መጥቶ

እስኪ ዞር ብዬ ልመልከት ጌታ ያረገልኝን
ያኔ እጆቼን ይዞ እየመራ ያሻገረኝን

3.ያሳለፈኝን መንገድ ሳስብ
ተራራ ቁልቁል ባህር ሽቅብ
ዛሬን ማየቴ ይገርመኛል
ዉለታዉ እጅግ በዝቶብኛል

እስኪ ዞር ብዬ ልመልከት ጌታ ያረገልኝን
ያኔ እጆቼን ይዞ እየመራ ያሻገረኝን
                 
4.ስቃይ ሲበዛ መከራዬ
ሁሉም ሜዳ ላይ ጥሎኝ ሸሸ
ኢየሱስ ግን ቀርቦ አፅናናኝ
ከወደቅኩበት ረድቶ አስነሳኝ

እስኪ ዞር ብዬ ልመልከት ጌታ ያረገልኝን
ያኔ እጆቼን ይዞ እየመራ ያሻገረኝን
',
  'hagerigna',
  47,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-048'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-049',
  'am',
  'የሱስ ይጠራሃል',
  null,
  'የሱስ-ይጠራሃል',
  'Imported from Hagerigna row 49.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  49,
  'የሱስ ይጠራሃል',
  null,
  'የሱስ ይጠራሃል አስብ ቆም ብለህ
ያለህበትን ለይ ጥሪውን እየሰማህ
ደካማ ጎንህን ማጠንከር እንድትችል
አስገባው ጌታህን ደጅህን ያንኳኳል
           
1.ዓይኖቹ ከአንተ ላይ ጭራሽ ሳይዞሩብህ
የጥበቃውም እጅ ሳይታጠፍብህ
እንደ ሥራህ ለመክፈል ፈጥኖ ሳይመጣብህ
እልሁን ተወውና ና ወደ አምላክህ

-- የሱስ ይጠራሃል --

2.ታግደው እያሉ አራቱ ነፋሳት
ሥፍራቸውን ሳይለቁ ቅዱሳን መላዕክት
ሌሊቱ ሳይመጣ ቀኑ ሳይመሽብህ
የፀባኦቱን ድምጽ አስብ ቆም ብለህ

-- የሱስ ይጠራሃል --
            
3.ንሥሐ ገብተህ አስብ የወደቅክበትን
ሰዓቱን አታውቅም የሚመጣበትን
አክሊልህን ለመውሰድ ጠብቅ የያዝከውን
ቆም ብለህ አስብ ከአርያም ድምጹን

-- የሱስ ይጠራሃል --

4.በራድ ወይም ትኩስ ከሁለቱ ወጥተህ
ከአፉ እንዳትተፋ ለብ ያልህ ሆነህ
ሀፍረትህ እንዳይገለጥ ነጩን ልብስ ልበሰው
መንፈስ ቅዱስ ይላል ይስማ ጆሮ ያለው

-- የሱስ ይጠራሃል --
                 
5.ጎስቋላ እንደሆንክ በፍጹም አታውቅም
ምስኪንና ደኃ ዕውር እራቁትም
ባለጠጋ ልትሆን ናና ተመከር
ምህረትን ልታገኝ ከአምላክህ ከእግዚአብሔር 

-- የሱስ ይጠራሃል --
',
  'hagerigna',
  48,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-049'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-050',
  'am',
  'ተገናኘን ጌታ ሆይ ተገናኘን',
  null,
  'ተገናኘን-ጌታ-ሆይ-ተገናኘን',
  'Imported from Hagerigna row 50.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  50,
  'ተገናኘን ጌታ ሆይ ተገናኘን',
  null,
  'ተገናኘን ጌታ ሆይ ተገናኘን
ተገናኘን የሱስ ሆይ ተገናኘን
ተገናኘን መንፈስ ሆይ ተገናኘን
ባዶ ማድጋዎች ነን ዘይት የሌለን
                 
1.እስከ አሁን በደረቅ ኑሮ ኖረናል
ዝናብ ያስፈልገናል ጠውልገናል
ድካም እንዳያገኘን በጉዞአችን
የአንተው መንፈስ ይሥራ በዘመናችን

-- ተገናኘን ጌታ ሆይ --

2.በቤትህ እጅግ ዓመት ቆይተናል
ዕድሜን በመቁጠር ብቻ አርጅተናል
ኧረ ማረን ብለናል እባክህ
በኛ ውስጥ ይደር ይዋል መንፈስህ

-- ተገናኘን ጌታ ሆይ --
                    
3.የጥንቱን እምነትና ፍቅር ስጠን
መኻሪ ነህና በምህረት እየን
ይህን ያህል ቆይተን እንዳንጠፋ
በሙላት ተገናኘን የእኛ ተስፋ

-- ተገናኘን ጌታ ሆይ --

4. ባዶ ማድጋዎች ነን ዘይት የሌለን
ቀላል ነፋስ ቢመጣ የሚጥለን
የናዝሬቱ ኢየሱስ ሆይ አቤቱ
እንደገና መስርተን በዓለቱ 

-- ተገናኘን ጌታ ሆይ --
',
  'hagerigna',
  49,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-050'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-051',
  'am',
  'ለወደደን ለእግዚአብሔር',
  null,
  'ለወደደን-ለእግዚአብሔር',
  'Imported from Hagerigna row 51.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  51,
  'ለወደደን ለእግዚአብሔር',
  null,
  '1. ለወደደን ለእግዚአብሔር ምስጋና
ለመሐሪዉ አምላካችን ምስጋና
ለሚረዳን ለእግዚአብሔር ምስጋና
ለታዳጊዉ አምላካችን ምስጋና
            
አሜን ምስጋና ይሁን ለጌታ
በታላቅ ኃይሉ ሁሉን ለረታ
ኤልሻዳይ ጌታ

2. ለታጋሹ አምላካችን ምስጋና
ምህረቱን ላበዛልን ምስጋና
ከወደቅንበት ላነሳን ምስጋና
በፀጋዉ አቅፎ ላቆመን ምስጋና

-- አሜን ምስጋና --
             
3. ወጽመዱን ለሰበረልን ምስጋና
ከጠላት ኃይል ለታደገን ምስጋና
መከታችን ለሆነልን ምስጋና
አሳልፎ ለማይሰጠን ምስጋና፡፡

-- አሜን ምስጋና --

4. ችግረኛዉን ለሚያስበዉ ምስጋና
ከትቢያ ላይ ለሚያነሳዉ ምስጋና
በከፍታ ለሚያኖረዉ ምስጋና
እንሰዋለን ለእግዚአብሔር ምስጋና፡፡

-- አሜን ምስጋና --
',
  'hagerigna',
  50,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-051'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-052',
  'am',
  'ከረግረግ ውስጥ ያወጣኸኝ',
  null,
  'ከረግረግ-ውስጥ-ያወጣኸኝ',
  'Imported from Hagerigna row 52.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  52,
  'ከረግረግ ውስጥ ያወጣኸኝ',
  null,
  '1. ግራ ቀኙ ጨልሞብኝ በሸለቆ ሆኜ ሳነባ
ተስፋ ሁሉ ከኔ ርቆ እንዲያው ወጥቼ ስገባ
ጠላቴም ይህንን ሰምቶ እያስፈራራኝ ሲያገሳ
ረድኤት ይዞልኝ ከተፍ አለ ድንገት የይሁዳ አንበሳ
            
ከረግረግ ውስጥ ያወጣኸኝ
ከውድቀቴም ያነሳኸኝ
ወደ እረፍት ውኃ የመራኸኝ
ተመስገንልኝ ኢየሱሴ እስከ ዛሬ የረዳኸኝ

2.ቀይ ባሕር ከፊት ለፊቴ ፈርኦን ደግሞ ከኃላ
ጦርነቱ እጅግ በዝቶ ቢጠፋብኝ እንኳን አንድም መላ
የሰውን ልጆች ከልቡ ፈጽሞ አያስጨንቅምና
እንደ ምህረቱ መጠን ራራልኝ ይድረሰው ታላቅ ምሥጋና

-- ከረግረግ ውስጥ --
            
3.ጦርና ጋሻን አንግቦ ጎልያድም እንኳ ቢመጣ
እጅግ ኃያል ብርቱ ሆኖ እያስፈራራኝ ቢወጣ
የችግረኞችን ጩኸት ሰሚ ከቶ አያንቀላፋምና
በአንዲት ድንጋይ ብቻ ጣልኩት ይክበር አምላክ እንደገና

-- ከረግረግ ውስጥ --

4.ወደ ፊትም ቸርነትህ ምህረትህ ይከተሉኛል
በትርህና ምርኩዝህ እነርሱ ያጽናኑኛል
ክፉ ነገር እኔ አልፈራም አንተ ከኔ ጋራ አለህና
የሱስ ታማኙ እረኛዬ ውዴ ከፍ በል በምሥጋና 

-- ከረግረግ ውስጥ --
',
  'hagerigna',
  51,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-052'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-053',
  'am',
  'ችግሬን በሱ ላይ ጥዬበት',
  null,
  'ችግሬን-በሱ-ላይ-ጥዬበት',
  'Imported from Hagerigna row 53.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  53,
  'ችግሬን በሱ ላይ ጥዬበት',
  null,
  '1.ችግሬን በሱ ላይ ጥዬበት
አገኘሁ በየሱስ ዕረፍት/2/
ሸክሜን በሱ ላይ ጥዬበት
አገኘሁ በጌታ ነፃነት/2/

ገና ገና ካጎበጠኝ ሸክም
ገና ገና ያደርገኛል ቀና
ገና ገና ፀሎቴ ተሰምቶ
ገና ገና አያለሁ ተመልሶ

2.ሰዉ ሁሉ ተገርሟል ጌታ በሠራልኝ ሥራ
እስቲ ልናገረዉ ባልጨርሰዉም ላዉራ
ሁሌ እንዳስደነቀኝ ሁሌ እንዳስገረመኝ
ተስፋ የቆረጥኩበትን ሕይወቴን አለመለመ
            
ገና ገና ታሪኬ ይለወጣል
ገና ገና ቀን ይወጣልኛል
ገና ገና ሌሊቱ ይነጋልኛል
ገና ገና የጨለመብኝ ይበራል

3. ድሮ የምታወቀዉ እንደዚህ አይደለም
ዛሬ ግን ተለወጥኩ በሱ ለዘላለም
ከሞት መንደር ወጥቻለሁ በየሱስ
ማንንም አላየሁም ካለሱ ሕይወቴን ሲያድስ
            
ገና ገና ወጥቼ ሄዳለሁ
ገና ገና ሰዉን አስገርማለሁ
ገና ገና ሥራዉን አወራለሁ
ገና ገና ስሙን አስከብራለሁ 
',
  'hagerigna',
  52,
  '{"artist":"የሀዋሳ ታቦር ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-053'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-054',
  'am',
  'ወዳጄ ሆይ በርታ',
  null,
  'ወዳጄ-ሆይ-በርታ',
  'Imported from Hagerigna row 54.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  54,
  'ወዳጄ ሆይ በርታ',
  null,
  'ወዳጄ ሆይ በርታ ጊዜው አልቋልና
የየሱስ መምጫ ሰዓቱ ደርሷልና
የምህረቱ በር ሊዘጋ ነውና
የሚነገርህ ቃል ቀልድ አይደለምና
            
1.የምህረቱ በር ከተዘጋ ወዲያ
ጊዜው ካለፈ መሮጥ ኢየሱስ ጋ
ወዮ /3/ ብለን ብንጮህ
ምህረት ከየት ይምጣ ወድቀን ብናለቅስ

-- ወዳጄ ሆይ በርታ --

2.ለክፋት ድርድር ገንዘብ ስናባርር
ልባችን በምኞት ደንዝዞ ስንዞር
የምህረቱ በር በድንገት ሲዘጋ
ንሥሐመግባት የለም ወዳጅ አትዘንጋ

-- ወዳጄ ሆይ በርታ --
            
3.በነገ አትመካ ነገ የአንተ አይደለም
ለምህረት ጊዜ አለው አይኖርም ዘላለም
ከቅድስተ ቅዱሳን ጌታችን ይወጣል
የዚህ ዓለም አምላክ ብቻውን ይቀራል

-- ወዳጄ ሆይ በርታ --

4.ማህተሙን አታሚ ሊያትም ህዝቦቹን
ለጌታ የተገቡ ቅዱስ ወገኞቹን
ከሚድኑቱ ጋር ታትመን ለመዳን
በሰማያት ያለዉ እግዚአብሄር ይርዳን

-- ወዳጄ ሆይ በርታ -- 
',
  'hagerigna',
  53,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-054'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-055',
  'am',
  'በክብርም ይገለፃል',
  null,
  'በክብርም-ይገለፃል',
  'Imported from Hagerigna row 55.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  55,
  'በክብርም ይገለፃል',
  null,
  '1. ጽድቅ የሚኖርባትን አዲስ ምድር ሊያወርሰን
እንደ ተስፋ ቃሉ ወደ ክብሩ ሊያገባን
ይመጣል/3/ በእርግጥም ይመጣል
በደመና ይመለሳል
            
በክብርም ይገለፃል
የወጉትም ያዩታል
ጌታ አይቀርም ይመጣል/2x/

2. የተስፋ ቃል የሰጠን እግዚአብሔር ታማኝ ነዉ
ሊፈጽመዉ ይችላል በትዕግሥት እንጠብቀዉ
በቃሉ በተስፋ እንቁም መገለፁ አይቀርም

-- በክብርም ይገለፃል --
            
3.ለብዙዎች መዳን እያለ ቢዘገይም
የተናገረዉን ቃል በፍፁም አያጥፈዉም
ይመጣል አይቀርም ይመጣል አይዋሽም ይመጣል

-- በክብርም ይገለፃል --

4.በአእላፋት ቅዱሳን መላዕክት ታጅቦ
በደመና ተከብቦበክብር አክሊል ተዉቦ
ከሰማይ በድንቅ ይገለጣል ዳር እስከ ዳር ይታያል

-- በክብርም ይገለፃል --
              
5.መጨረሻዉ ተቃርቧል ጌታ የሱስ ይመጣል
ብለን ለሁሉ እናዉጅ ይህን የምስራች ቃል
ይመጣል ይመጣል እያልን እንናገር ምፃቱን 

-- በክብርም ይገለፃል --
',
  'hagerigna',
  54,
  '{"artist":"የገርጂ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-055'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-056',
  'am',
  'ተስፋችን መንምኖ',
  null,
  'ተስፋችን-መንምኖ',
  'Imported from Hagerigna row 56.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  56,
  'ተስፋችን መንምኖ',
  null,
  '1.ተስፋችን መንምኖ የመንገዳችን አቅጣጫዉ ጠፍቶ
በህይወታችን የስቃይ ሐረግ ተንዛዝቶ በዝቶ
ለብዙ ዘመን ተሳቅቀን ኖረን በጠላት ወሬ
ዛሬ ግን ድልን እናቀርባለን ለአምላክ ዝማሬ
              
የጠላታችን ሥልጣን ማዕረጉ ክብሩ ተገፍፎ
በየሱስ ደምና በእርሱ ትንሳኤ ይኻው ተገርፎ
እኛ ግን ዛሬ እንደ ፀዳል ደምቀን እናበራለን
ለእግዚአብሄር ክብር የእልልታን መዝሙር እንዘምራለን

-- ተስፋችን መንምኖ --

2.ከኔ በቀር ሌላ ወዴት አለ ብሎ ፎከረ
በትዕቢትና በዓመጽ ፍላጻ ብዛት ሰከረ
የእግዚአብሄርን ሕዝብ እየከሰሰ ለጨቀጨቀው
ከእሴይ ግንድ በትር ወጣና ራሱን ቀጠቀጠው

-- ተስፋችን መንምኖ --
           
3.መግቢያና መውጫ አሳጥቶን ነበር ሁሌ እያጓራ
ከጭፍራዎቹና ከክፋት ሰራዊቶቹ ጋራ
አንበሳን መስሎ ቢያስፈራራንም ሲጮህ ሲያገሳ
ታላቅ ወንድማችን የሱስ ደረሰልን የይሁዳ አንበሳ

-- ተስፋችን መንምኖ --

4.እግዚአብሄር ይመስገን ለጠላት ታወጀ መፈታታችን
ለክብሩ እንዲሆን በገና ይደርደር ለዝማሬያችን
አምላክ የፈታውን ማንም ዳግም ሊያስር አይችልምና
አሁንም ቢሆን ለየሱስ ይሁን ክብር ምሥጋና

-- ተስፋችን መንምኖ --
             
5.ተስፋችንታደሰ የጠላት ወጽመድ ተሰባበረ
ፈቃዱ ሊሞላ በተናቁት ላይ የሱስ ከበረ
ስለዚህ ዳግም ጌታን መባረክ እንጀምራለን
በፀጋው ተፈተን በሐሴት በእልልታ እንዘምራለን

-- ተስፋችን መንምኖ --
',
  'hagerigna',
  55,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-056'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-057',
  'am',
  'ወደ ሀገራችን እንሄዳለን',
  null,
  'ወደ-ሀገራችን-እንሄዳለን',
  'Imported from Hagerigna row 57.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  57,
  'ወደ ሀገራችን እንሄዳለን',
  null,
  'ወደ ሀገራችን እንሄዳለን
ከእንግድነት ሀገር እንላቀቃለን
አዲሲቷን ኢየሩሳሌም እንወርሳለን
በዚያም ለዘላለም እንኖራለን
            
1.ከዚህ ከድካም ዓለም እንሄዳለን 
ከፃድቃን ጋር በሰማይ እናርፋለን
የጭንቃችንን ዘመን እንረሳለን
ሁሌ እንዘምራለን ክብር ይሁን እያልን

-- ወደ ሀገራችን --

2.በዓይነ ቅፅበት ከምድር እንነሳና
የቀድሞ ተፈጥሯችን ይለወጥና
ጌታን በአየር ላይ ተገናኝተን
ወደ ፅዮን ቤታችን እንሄዳለን

-- ወደ ሀገራችን --
            
3.ከፃድቃን ማህበር ጋር እንቀላቀልና
ከቅዱሳን መላዕክት ጋር እንጎዳኝና
ለዘላለም የምሥጋና ድምፅ እያሰማን
በዚያ እንኖራለን ሃሌሉያ እያልን

-- ወደ ሀገራችን --

4.በወርና በሰንበት በፊቱ እየቀረብን
ክብር እንሰጣለን ሁሌ እየሰገድን
በረከትና ጥበብ ይሁን ለአምላካችን
እያልን እንዘምራለን በሰማይ ቤታችን 

-- ወደ ሀገራችን --
',
  'hagerigna',
  56,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-057'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-058',
  'am',
  'ስለማይነገር ሥጦታው',
  null,
  'ስለማይነገር-ሥጦታው',
  'Imported from Hagerigna row 58.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  58,
  'ስለማይነገር ሥጦታው',
  null,
  'ስለማይነገር ሥጦታው እግዚአብሄር ይመስገን
ስለማይቆጠር ውለታው እግዚአብሄር ይመስገን
ሥራችንን ሰርቶልናል ታላቅነቱን አየነው
ለካስ ካንጀቱ ወዶናል ጌታ የሱስ ፍቅር ነው

1.በምንም አይረቡም አነዚህ ተብለን
በወራዳ ሥፍራ ተጥለን ወድቀን
ወዮ ጠፋን ስንል ሲናፍቀን ፊትህ
በጆሮአችን ገባ አጽናኙ ድምፅህ

-- ስለማይነገር ሥጦታው --
            
2.ሰው ለዘመዱ ሲል ፊት አይቶ ያዳላል
የተማመኑበት በአንድ ቀን ይክዳል
እግዚአብሄር ግን ልብን ያያል የሁሉን ሰው
ለምስኪኖች ዓለት ምሥጋና ይድረሰው

-- ስለማይነገር ሥጦታው --

3.እጅግ ደስ ብሎናል ከውድቀት ሲያነሳን
ሰው ጥሎ የረሳንን እርሱ ግን ሳይረሳን
ምርኮን ማረከና ሥጦታንም ሰጠን
ውለታው ብዙ ነው ኢየሱስ ይመስገን

-- ስለማይነገር ሥጦታው --
            
4.ከአንጀቱ ወዶናል ምንም አላስቀረም
ከዚህ የሚበልጥ ፍቅር ከቶ የለም
ለወገኑ መዳን በመስቀል ደቀቀ
ሥራችንን ሰርቶ ራሱ አጠናቀቀ 

-- ስለማይነገር ሥጦታው --
',
  'hagerigna',
  57,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-058'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-059',
  'am',
  'እንደ የሱስ ያለ ማን ነዉ?',
  null,
  'እንደ-የሱስ-ያለ-ማን-ነዉ',
  'Imported from Hagerigna row 59.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  59,
  'እንደ የሱስ ያለ ማን ነዉ?',
  null,
  'እንደ የሱስ ያለ ማን ነዉ? እንደ የሱስ/2x/
እንደ የሱስ ያለ ማን ነዉ? እንደ ጌታ
የምስኪኖችን ቋጠሮ የሚፈታ/2x/
አልተገኘም ከርሱ ሌላ የሚበረታ

1.ተስፋ ቆርጦ ለባዘነዉ ፈጥኖ ደራሽ\t
በሸለቆ ለሚያነባ ዕንባን አባሽ
እስከ ዛሬ አልተገኘም ከእርሱ ሌላ
የኛ ጌታ ያኮራናል መልካም ጥላ

-- እንደ የሱስ --

2.ከትቢያ ላይ ያነሳችሁ ይህን ጌታ
አመስግኑት በዝማሬ በዕልልታ
ምህረቱ ቸርነቱ ያዘምራል
ፍቅሩን ያየ ማንም ቢኖር መች ይችላል

-- እንደ የሱስ --

3.ወላጅ አልባ የሆነዉን ያሳድጋል
ወደ ምስኪኖቹ ጎጆ ወዶ ይገባል
የሰቆቃ ዘመኑንም ይሽርና
በምሥጋና ይሞላዋል እንደገና

-- እንደ የሱስ --
              
4. በደል ኃጢአት ሣይኖርበት ለኛ ሞቶ
አድኖናል የሱሳችን ፍቅሩ በዝቶ
የምህረቱ ስፋቱና ጥልቀቱ
አይታወቅም ብዙ ነዉና ቸርነቱ 

-- እንደ የሱስ --
',
  'hagerigna',
  58,
  '{"artist":"ዘማሪ ዳታን ደምሴ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-059'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-060',
  'am',
  'እንደ በግ ሆኖ',
  null,
  'እንደ-በግ-ሆኖ',
  'Imported from Hagerigna row 60.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  60,
  'እንደ በግ ሆኖ',
  null,
  '1.ትውስ ይለናል ዛሬም ጎልጎታ
የሞት የሽረት የትግል ቦታ
የእግዚአብሄር ልጅ የተሰዋበት
ነፍሱን ስለ እኛ ያሳለፈበት
             
እንደ በግ ሆኖ እንደ በግ ታርዶ
የጌቶች ጌታ ራሱን አዋርዶ
እንደ ወንጀለኛ ራሱን ቀጣ
ወንጀለኞችን ነፃ አወጣ

2.ቀይ አለበሱት እንደ ቀማኛ
ነፍስ እንዳጠፋ እንደ ደመኛ
በሰው ልጆች ጦር እየተወጋ
እኛን አፈራ የደሙን ዋጋ

-- እንደ በግ ሆኖ --
            
3.የኃጢአትን ዕዳ ከኛ አርቆ
ከአባቱ ጋራ ሕዝቡን አስታርቆ
ሥጦታን ሰጥቶ ምርኮ ማረከ
የታሰሩትን ፈትቶ ባረከ

-- እንደ በግ ሆኖ --

4.ወደ ገዛ ወገኖቹ መጣ
ጠላትን እንጂ ዘመድን አጣ
ለተቀበሉት ሥልጣን ሰጣቸው
የእግዚአብሄር ልጆች አደረጋቸው

-- እንደ በግ ሆኖ -- 
',
  'hagerigna',
  59,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-060'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-061',
  'am',
  'አንተ ይሁን ካልከዉ',
  null,
  'አንተ-ይሁን-ካልከዉ',
  'Imported from Hagerigna row 61.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  61,
  'አንተ ይሁን ካልከዉ',
  null,
  'አንተ ይሁን ካልከዉ /2x/ 
ሁሉም ይሠምራል በጊዜዉ/2x/

1.አንዳንዴ ከኔ የራቅህ ሲመስለኝ
መንገዱ ሲጨልምብኝ
በሰዓቱ ፈጥነህ ትመጣና
ጨለማዉን በብርሃን ትለዉጥና
አመስግኜ አልፋለሁ/4x/

-- አንተ ይሁን ካልከዉ--
         
2.በሰዉ ዘንድ የማይቻለዉ 
ለአንተ እጅግ ቀላል ነው
ጊዜ የማይወስንህ ጌታ
ትገኛለህ አንተ በሁሉም ቦታ
ሁሉን ቻይ ነህ ጌታዬ/4x/

-- አንተ ይሁን ካልከዉ--

3.የደረቀ ሕይወቴን ዳስሰህ
በመንፈስህ አለምልመህ
ሥራህን ስትሠራ አይቻለሁ
የሚያቅትህ የለም እመሰክራለሁ
ሥራህ እጅግ ድንቅ ነው/4x/

-- አንተ ይሁን ካልከዉ--
             
4.እኔ ስጠኝ ብዬ ስልህ
ዝምታ ቢሆንም መልስህ
የሚጠቅመኝን አትነሣኝም
ካንተጋር ሆኜ አልተጎዳሁኝም
አንተ ያልከዉ መልካም ነዉ/4x/ 

-- አንተ ይሁን ካልከዉ--
',
  'hagerigna',
  60,
  '{"artist":"የገርጂ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-061'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-062',
  'am',
  'እግዚአብሔር ስለእኛ ይዋጋል',
  null,
  'እግዚአብሔር-ስለእኛ-ይዋጋል',
  'Imported from Hagerigna row 62.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  62,
  'እግዚአብሔር ስለእኛ ይዋጋል',
  null,
  'አ   እግዚአብሔር ስለእኛ ይዋጋል
ዝ   ማን ከፊታችን ሊከሰን ይቆማል
ማ   ከማለዳ ወገግታም ይልቅ
ች   አምላካችን ያበራል ከሩቅ
         
1. የጠላት ጦር ያላግዳል
ጎልያድን መሪው አድርጓል
ልባችንን ሊያቀልጥ ሊያደክመን ይሻል
አምላካችን ግን ለእኛ ይዋጋል

2. በሥጋ ክንድ የታመኑ
ሰረገሎች ያሰለፉ
በጦር ብዛት ቢተማመኑም
አምላካችን ግን ከቶ አይተወንም
            
3. የአምላክ ቅጥር እንዳይፀና
እነ ጦቢያ ቢነሱና
ቢጣጣሩ ቅጥሩን ለመጣል
አምላካችን ግን ለኛ ይዋጋል

4. እንደ ባህር ዳር አሸዋ
በፊታችን ቢከማቹ
ከኛ ጋራ ግን ዙሪያችን ያለው
የሚበልጠው የአምላክ ሰራዊት ነው
               
5.ሰናክሬም ዛሬ ይፎክራል
ላትድኑ አትልፉ ይላል
ደብዳቤ ይልካል ያስፈራራናል
አምላካችን ግን ለኛ ይዋጋል

6. የፈርኦን ጦር ጥርሱን ነክሷል
በሰረገሎች ሆኖ ይከንፋል
ዳግም ባሮቹ ሊያደርገን ይሻል
አምላካችን ግን ለኛ ይዋጋል 
',
  'hagerigna',
  61,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-062'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-063',
  'am',
  'እንሂድ ተነሱ',
  null,
  'እንሂድ-ተነሱ',
  'Imported from Hagerigna row 63.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  63,
  'እንሂድ ተነሱ',
  null,
  'እንሂድ ተነሱ እንሂድ /2x/
ወደ ጽዮን ሀገር እንሂድ
በጠባቧ መንገድ እንሂድ
        
1.እባብና ግንጡን ረጋግጠን
ኢየሱስ በአንተ ኃይል ድል አድርገን
የተስፋይቱን ምድር ጽዮንን
በሠላም በጤና አድርሰን

-- እንሂድ ተነሱ --

2.ዓለምን በእምነት ድል አድርገን
የሞትንም ባህር ተሻግረን
ዙሪያ ጥምጥም ጉዞ ተጉዘን
በድል እንድንገባ አግዘን

-- እንሂድ ተነሱ --
           
3.እስካሁን የረዳን በጉዞ
ሳይሰለቸን ቀርቦ አግዞ
ደግመህ ደግመህ ንገሥ ልበለው
ዙፋኑን ምሥጋና ይክበበው

-- እንሂድ ተነሱ --

4.ከእንግድነት ሀገር ለመውጣት
ወደ ከተማÃቱ ለመግባት
በላባዎቹ ውስጥ እርሱ አቅፎ
ኢየሱስ ያድርሰን ደግፎ 

-- እንሂድ ተነሱ --
',
  'hagerigna',
  62,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-063'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-064',
  'am',
  'ሊቀ-ካህናችን',
  null,
  'ሊቀ-ካህናችን',
  'Imported from Hagerigna row 64.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  64,
  'ሊቀ-ካህናችን',
  null,
  '1.ጻድቁም ይፅደቅ እርኩሱም ይርከስ
የሚባልበት ሰዓቱ ሳይደርስ
ቀን ሳለ ዛሬ ፈቃዱን እናድርግ
በንሥሐ ሕይወት ወደ እርሱ እንደግ
                     
አ  ሊቀ-ካህናችን ከመቅደስ ሳይወጣ
ዝ  የምህረት ደጅም ፈጥኖ ሳይዘጋ
ማ  ራሳችንን አስጨንቀን በንሥሐ እየተዋረድን
ች   ልንጠብቀው ይገባናል

2.ጌታ ጌታ ሆይ ብቻ እያልን
ፈቃዱን ማድረግ ጭራሽ ተስኖን
በለብታ ህይወት ተዘፍቀን ሳለን
ቀኑ ደርሶብን ጌታ እንዳይተፋን
               
3.ቸልተኝነት እኛን አጥቅቶን
ለኃጢአታቸን ንስሐን ረስተን
የጽድቅን ኑሮ ሳንለማመድ
እንዳይቋረጥ የእርሱ ማማለድ

4.እንደተራቆትን ዛሬ ተረድተን
አልብሰን ብለን ጌታን ተማጽነን
በጽዮን መንገድ በእምነት ተጉዘን
ከሚድኑቱ ሆነን እንድንገኝ
                
5.ኩራዛችንን በዘይት ሞልተን
መብራታችንን ዘውትር አብርተን
ከልባሞቹ ጋር ተደምረን
በሠርጉ እንገኝ ሳይዘጋብን 
',
  'hagerigna',
  63,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-064'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-065',
  'am',
  'አዋጅ እናውጃለን',
  null,
  'አዋጅ-እናውጃለን',
  'Imported from Hagerigna row 65.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  65,
  'አዋጅ እናውጃለን',
  null,
  'አዋጅ እናውጃለን የሚሰማ ሰው ካለ/2x/   
አዋጁንም ስሙ የምጻቱ ነውና
አልሰማንም ማለት ኋላ የለምና
እንዳንክድ ቃሉ ምሥክር ነውና
በእዉነት እንራመድ እንጠንቀቅና
             
1.አዋጅ እናውጃለን የሚሰማ ሰው ካለ/2x/
አዋጅ ምናውጀው የጌታ ምጻት ነው
ወደኛ እጅግ ቀርቧል በደጃችን ላይ ነው
ምንነው ዘነጋነው አበዛን ቸልታ
ድንገት ሊገለጽ ነው የሠራዊት ጌታ

-- አዋጅ እናውጃለን --

2.አዋጅ እናውጃለን የሚሰማ ሰው ካለ/2x/
ፀንተን እንጠብቅ እኛ ዘንግተናል
ምን ነው ወገኖቼ ለምን ተኝተናል
ዛሬውኑ እንበርታ ከአሁኑ ጠንክረን
የዚህን ዓለም ምኞት ቀሪውንም ትተን

-- አዋጅ እናውጃለን --
             
3.አዋጅ እናውጃለን የሚሰማ ሰው ካለ/2x/
ይህን የምሥራች ወገኖች አስተውሉ
ጌታችን ተናግሯል ለሚሰማ ሁሉ
ቀድሞውኑ ብሏል ተናግሯል በቃሉ
ይህን የትንቢት ቃል ዛሬውኑ አስተውሉ
አዋጅ እናውጃለን የሚሰማ ሰው ካለ/4x/ 

-- አዋጅ እናውጃለን --
',
  'hagerigna',
  64,
  '{"artist":"የአርሲ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-065'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-066',
  'am',
  'የዘላለም አምላክ',
  null,
  'የዘላለም-አምላክ',
  'Imported from Hagerigna row 66.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  66,
  'የዘላለም አምላክ',
  null,
  'የዘላለም አምላክ የኛ ጌታ
ሙሽራው ኢየሱስ የድል ጌታ
ሊመጣ ቀርቧል ሊወስደን
የዘላለምን መንግሥትሊያወርሰን
ሊያሳርፈን አሜን ሊያሳርፈን
                
1.እንደ ኖህም ዘመን ስንጠጣ ስንበላ
ጌታ ኢየሱስ ድንገት እንዳይመጣብን ኋላ
ተራሮችንም ሁሉ ሰውሩን እንዳንል
አሁኑኑ እንቁም ለክብሩ በመዋል

-- የዘላለም አምላክ --

2.አይመጣብንምና እንዳሻን እንሁን እያልን
ዓለምን ስንቃኛት ድንገት ብቅ እንዳይል
ለምድራዊዉ መዝገብ ስንራወጥ ሳለን
ጌታ እንዳይመጣብን እንጓዝ አስተውለን

-- የዘላለም አምላክ --
                 
3.ክብርን ተጎናጽፈን በአዲስ ተለውጠን
የሚሞተውን ትተን የማይሞተውን ለብሰን
ወደ ቅድስት ከተማ ልንገባ ነውና
ወገኖቼ ዛሬም በጌታ እንጽናና 

-- የዘላለም አምላክ --
',
  'hagerigna',
  65,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-066'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-067',
  'am',
  'ኦ ልናርፍ ነው',
  null,
  'ኦ-ልናርፍ-ነው',
  'Imported from Hagerigna row 67.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  67,
  'ኦ ልናርፍ ነው',
  null,
  '1.በገናችንን ይዘን የወርቅ አክሊል ደፍተን
በአዲሱ ዓለም በፅዮን ሆነን
በእልፍአእላፋት መላዕክት ፊት
ጊዜው ደርሷልና ልናዜምለት
            
ኦ ልናርፍ ነው ከዚህ ዓለም ጣጣ
ሰዓቱ ደርሶ የሱስ ሊመጣ
አሜን ደስ ይበለን እጅግ ደስ ይበለን
የሺው ዓመት መንግሥት ጊዜው ደረሰልን

2.አሁን የሚያለፈው ምድራዊ ኑሮአችን
ይቀራል አናይም በአዲሱ ዓለማችን                    
ስድስት ሺህ የምድር የሥራ ጊዜያችን
አልቆ ልንገባ ነው ወደ ሰንበታችን

-- ኦ ልናርፍ ነው --
             
3.ሙሽራውን ተቀበሉ ውሰዱ ስንባል
ታጅቦ ሲመጣ በእሳት ነበልባል
በብርሃኑ ጮራ ኃጢአን ሲቀልጡ
እኛም እንሄዳለን ፃዲቃን ሲወጡ 

-- ኦ ልናርፍ ነው --
',
  'hagerigna',
  66,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-067'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-068',
  'am',
  'አቤት የቀልድ ዘመን',
  null,
  'አቤት-የቀልድ-ዘመን',
  'Imported from Hagerigna row 68.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  68,
  'አቤት የቀልድ ዘመን',
  null,
  'አቤት የቀልድ ዘመን አቤት የፌዝ ዓመታት
የሰው ልጅ ህይወቱን እንደ ቀልድ የሚመለከትበት
ህይወት የሚገኝበትን ትምህርት የማይታገሡበት
ምን ዓይነት ጊዜ ይሆን የከንቱ ዓመታት/2
           
1.የምህረት ጥሪ ቀርቦ ለወገኖች በፍጥነት
ላለመቀበል ፈለጉ ህይወት የሚገኝበትን ትምህርት
ዛሬም ድምፅ ያስተጋባል ህይወት ሊሰጥ ለወገኞች
የሰው ልጆች ዞር አሉ ወደ ተረታ ተረት

-- አቤት የቀልድ ዘመን --

2.ተው የሰው ልጅ ሆይ የአምላክህን ድምፅ ስማ
የነገውን አታውቅም የአንተ አይደለምና
ኃጢአትን ተውና ወደ አምላክህ እሮሮህን አሰማ
ይህ ድምፅ ካለፈ ዳግም አይመለስምና

-- አቤት የቀልድ ዘመን --
           
3.ህይወትህን መርምር በውስጥህ ምን እንዳለ
መዳን አታገኝም መርዝ በህይወትህ ሞልቶ እያለ
እባክህ ወደ ህይወት ቃል ተመለስ በቶሎ
መዝለቅ አይቻልም ውሸት ይዞ አስመስሎ

-- አቤት የቀልድ ዘመን --

4.ጊዜው አልቋል ሲባል የቀልድ አይደለም
ህይወትህን በማሰብ ለምን አትመለከትም
የተሰጠህ ዘመን የቀልድ አይደለምና
አስተውል ስለራስህ ከእንግዲህ ጊዜ የለምና 

-- አቤት የቀልድ ዘመን --
',
  'hagerigna',
  67,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-068'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-069',
  'am',
  'ሁሉም እጅ አንስቶ',
  null,
  'ሁሉም-እጅ-አንስቶ',
  'Imported from Hagerigna row 69.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  69,
  'ሁሉም እጅ አንስቶ',
  null,
  'ሁሉም እጅ አንስቶ ኃጢአቱን ወደ ጌታ የሱስ ቢናዘዝ
ከዚህ ክፉ ዓለም ከጣኦት ከርኩሰት ቶሎ ቢመለስ
እንደ ተስፋ ቃሉ ጌታችን እስከ አሁን ባልዘገየ ነበር
እኛም በዚህ ምድር በድካም ባልተንከራተትን ነበር
          
1.ሁሉም የየራሱን ከተማ ደጃፎቹን ቢያጸዳ
ሊመጣ ያለውን ሙሽራ ሊቀበል ቢዘጋጅ ቢሰናዳ
አቤት እንዴት ያለ ግሩም ነው በእንዲህ ዓይነትማ ዝግጅት
የሱስም ይመጣል በፍጥነት አይዘገይምና በእውነት

-- ሁሉም እጅ አንስቶ --

2.ምድራችን በኃጢአት አለንጋ ስትገረፍ ኖራለች
መድኃኒት በሌለው በሽታ ስትማቅቅ ቆይታለች
ማረን ተለመነን የሱስ ሆይ በዚህ በቀሪው ዕድሜአችን
ብለን ብንማጸን ሁላችን ምነው ባሳረፈን ጌታችን

-- ሁሉም እጅ አንስቶ --
         
3.ሁሉም በአምላኩቢታመን ከሕይወቱ እርሞችን ቢያስወግድ
በፍቅር ሰንሰለት ተሳስሮ ሰፈር ጎረቤትም ቢዋደድ
ታናሽ ታላቁን ቢያከብር እንደ ሕጉ መሠረት ቢታዘዝ
የሱስም ይመጣል አይቆይም ሁሉም በየቤቱ ቢቀደስ

-- ሁሉም እጅ አንስቶ --

4.ስለዚህ ወገኔ ምንድንነው ለእኔና ለአንተ የሚበጀው
ኃጢአትን በጊዜ ተናዝዞ ማምለጥማ ነበር የሚሻለው
ታዲያ በዚህ ምድር ምንድንነው ዋስትና በሌለው መታገል
እባክህ ወንድሜ ተመለስ ዋስትናህ የሱስ ነው ተቀበል 

-- ሁሉም እጅ አንስቶ --
',
  'hagerigna',
  68,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-069'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-070',
  'am',
  'ለዚህ መድረሴ',
  null,
  'ለዚህ-መድረሴ',
  'Imported from Hagerigna row 70.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  70,
  'ለዚህ መድረሴ',
  null,
  'ለዚህ መድረሴ ማገልገሌ ለኔስ ተዓምር ነው
እንደ ኃጢአቴ መተላለፌ ቢሆን ዕድሌ ሌላ ነው
ለዚህ አምላክ ብዘምር ብሰግድለትም ውለታው አያልቅም
             
1.ፍቅሩን ለመግለጽ የሚችል ማን ነው
እንደ እርሱ ታጋሽ ይቅር የሚል ማን ነው
ከማንም በላይ የዋለልኝን ሳስብ
ምሥጋና አለኝ ዘውትር የማቀርብ

-- ለዚህ መድረሴ --

2.ቃሉን አንብቤ እንደ ማንም ሰው
ኃጢአትን እንደማይወድ ልቤ እያወቀ
አምና በድዬው ትላንትም በድዬው
ዛሬም በፊቱ አቆመኝ ሸፍኖኝ በፀጋው

-- ለዚህ መድረሴ --
            
3.እርሱ እንደ ሰው ቢሆን አንድ ቀን አላድርም
አምላኬ ሩህሩህ ነው በደልን አይቆጥርም
ዛሬም የምህረት እጁን ዳግም ዘረጋልኝ
በምን ዓይነት ፍቅር ነዉ እኔን የወደደኝ

-- ለዚህ መድረሴ --

4.ቀን ቢሆን ማታ ልቤ የሚናፍቃት
የፃድቃን ሀገር ኢየሩሳሌም ናት
የዘመናት ምኞት የነገሥታት ንጉሥ
ፈጥነህ ቶሎ ናልኝ ዉዴ ጌታ የሱስ 

-- ለዚህ መድረሴ --
',
  'hagerigna',
  69,
  '{"artist":"ዘማሪ ዳታን ደምሴ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-070'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-071',
  'am',
  'አይረሳም',
  null,
  'አይረሳም',
  'Imported from Hagerigna row 71.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  71,
  'አይረሳም',
  null,
  '1.ድንቁን ሥራ አይቻለሁ እኔም በዓይኖቼ
እመሰክራለሁ ዘውትር በህዝብህ ፊት ቆሜ
የአምላኬ ውለታ ብዙ እጅግ ብዙ ነው
ምሥጋና ዙፋኑን ይሙላ እርሱ ኃያል ነው
                   
አይረሳም/2*/ የእርሱ ውለታ
በሰማይ በምድርም ከፍ ይበል ጌታ
ምርኮዬንም መለሰልኝ ለርሱ ይሁን ምሥጋና
ዘዉትር እቀኝለታለሁ ባማረዉ ዜማ

2. ስሙን ጠርቼ አላፈርኩም በሁሉም ነገር
አምላኬ ብዬ አላፈርኩም ለርሱ ይሁን ክብር
ሐዘኔ ይኸው ተለውጦ ዛሬ በደስታ
ለዘላለም ከፍ ይበል የጌቶች ጌታ

-- አይረሳም --
         
3. ቀን ጨልሞ ግራ ገብቶኝ ሳጉረመርም
አምላኬ ብዬ አላፈርኩም ለርሱ ይሁን ክብር
የምስኪኖች ጌታ እንደ ሰው ቆሞ አላየኝም
ለእኔም የፅድቅ ፀሐይ ወጣ ይንገሥ ዘላለም

-- አይረሳም --

4. እንደ እያርኮ ገደል ሆኖ ከፊት ለፊቴ
እጅግ በጣም ያሰቃየኝ ሁሌ ጭንቀቴ
በአምላኬ ኃይል ተደረመሰ ቅጥሩ ፈረሰ
ምን ተስኖት የእኔ አምላክ ሁሉን ድል ነሳ 

-- አይረሳም --
',
  'hagerigna',
  70,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-071'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-072',
  'am',
  'ለዛሬ መድረሴ ይገርመኛል',
  null,
  'ለዛሬ-መድረሴ-ይገርመኛል',
  'Imported from Hagerigna row 72.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  72,
  'ለዛሬ መድረሴ ይገርመኛል',
  null,
  'አ   ለዛሬ መድረሴ ይገርመኛል
ዝ   ይህን ቀን ማየቴ ይደንቀኛል
ማ   የማይቻል በሙሉ በርሱ ተችሎ
ች  በአሸናፊዉ ጌታ አምሮ ደምቆ
       
1.እንባዬ ታበሰ ከዓይኔ ላይ
ጌታ አሰበኝ ከሰማይ
እንዴት እችላለሁ ዝም ማለት
ክብሬን ሁሉ ጥዬ ልስገድለት

2.እስከዚህ ያደረስከኝ እኔ ማን ነኝ
አውቃለሁ እኔማ ደካማ ነኝ
ከአንተ የተነሳ ሰው ሆንኩኝ
በጠላቶቼ ፊት መች አፈርኩኝ
        
3.ስንቱን አሳለፍከኝ የኔ ጌታ
የጠላቴ ቁጣ ሲበረታ
በዓይኖችህ አይተህ ደረስክና
በምሥጋና ሞላህ እንደገና

4.ደመና ባይታይ ነፋስ ባይኖር
ኤልሻዳዩ ጌታ ስሙ ይክበር
ምን ተስኖት ያውቃል ድንቅ ይሠራል
ሰቆቃዬን ሽሮ ያስደስታል 
     
5.ለዋወጠው ጌታ ታሪኬን
ምን እላለሁ ታዲያ ይመስገን
ምስኪኑን ሚያከብር የኔ ጌታ
ስሙ ይክበር ዘውትር ጠዋት ማታ 
',
  'hagerigna',
  71,
  '{"artist":"ዘማሪ ኪዳኔ ኪታቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-072'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-073',
  'am',
  'ኃይል ያለው በጉልበት ላይ ነው',
  null,
  'ኃይል-ያለው-በጉልበት-ላይ-ነው',
  'Imported from Hagerigna row 73.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  73,
  'ኃይል ያለው በጉልበት ላይ ነው',
  null,
  'ኃይል ያለው በጉልበት ላይ ነው /2*/
መንበርከክ መፀለይ ካለ
ሁሉም ነገር በእጃችን አለ
     
1.ሙሴ በኮሬብ ተራራ እግዚአብሄርን ያናገረው
በደመና ውስጥ ተከብቦ ክብሩን ማየት የቻለው
አርባ ቀንና አርባ ሌሊት በመፆም በመፀለይ ነው

-- ኃይል ያለው --

2.ሐና ለረጅም ዓመታት በምላስ ዱላ ተመትታ
ጣውንቷ ስታስጨንቃት ሁል ጊዜ ጧትና ማታ
ለአምላኳ ነግራ አልቅሳ ሳሙኤልን ሰጣት ጌታ

-- ኃይል ያለው --
     
3. ኤልያስ ሦስት ዓመት ሙሉ ዝናብ እንዳይወርድ የዘጋው
በእምነት በፀሎት ኃይል ነው አመፀኛውን ሕዝብ የቀጣው
ለነገሥታትና ለአህዛብ የአምላኩን ክንድ የገለጸው

-- ኃይል ያለው --

4.በአንበሳ ጉድጓድ ውስጥ አድሮ ዳርዮስ ጠርቶ የጠየቀው
ዳንኤል አሳደረህ ወይ አምላክህ የምታመልከው
አዎን ድኜ አድሬአለሁ አምላኬን አከብረዋለሁ 

-- ኃይል ያለው --
',
  'hagerigna',
  72,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-073'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-074',
  'am',
  'በእኔ ላይ የተጠራው',
  null,
  'በእኔ-ላይ-የተጠራው',
  'Imported from Hagerigna row 74.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  74,
  'በእኔ ላይ የተጠራው',
  null,
  'በእኔ ላይ የተጠራው ይህ ቅዱስ ስምህ ከሚሰደብ
ግሩም ድንቅ የሆነውን ማደሪያህን ከማስወቅስ
አንደበቴ ሳይዋሽ ክህደት ሳልናገር
እንደ አባቶቼ መሞት እመኛለሁ ለአንተ ክብር

1.ዛሬ መስክሬህ የሱስ ነገ ከምክድህ
ለስምህ ዘምሬ ዳግም ከማዋርድህ
ከፀጋህ ርቄ ውሸት ከማናፍስ በየመንደር
ከእጅህ ሳልወጣ ዛሬ ትዋጠኝ መቃብር

2.ከፍቶኝ እንደሆን እንዲደላኝ ከማታልል
ደልቶኝም እንደሆን እስኪከፋኝ ከማስመስል
እስካሁን የመራኸኝን ጌታ ነገ ከምክድህ
መኖሬ አይጠቅምም የሱስ አሳርፈኝ በፈቃድህ
     
3.ብርሃን እንድሆን በዓለም ላይ ስታኖረኝ
ወደ ትልቅ ሥፍራ ለክብርህ ስትመራኝ
በሰጠኸኝ እውቀት ዳግም አንተን ከምዋጋ
በእውነት ማስተዋል ለክብርህ ያቁመኝ የአንተ ፀጋ

4.እስካሁን የመራኸንን እንዳንክድህ በፈተና
በዓለም ውጥረት በእሥራት ጉስቁልና
በግርፋት በሞት ማስከበር የሚያስችለንን
የመንፈስ ቅዱስን ፀጋ አልብሰን ለሁላችን 
',
  'hagerigna',
  73,
  '{"artist":"ዘማሪ ማሞ ጴጥሮስ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-074'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-075',
  'am',
  'እንደጓጓሁ አልቀርም',
  null,
  'እንደጓጓሁ-አልቀርም',
  'Imported from Hagerigna row 75.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  75,
  'እንደጓጓሁ አልቀርም',
  null,
  'አ   እንደጓጓሁ አልቀርም በምድር ላይ
ዝ   አየዋለሁ ንጉሤን ሲገለጥ ከሰማይ
ማ   እንደጓጓሁ አልቀርም በምድር ላይ
ች   አየዋለሁ ጌታዬን ሲገለጥ ከሰማይ
    
1.እናንተ የአባቴ ብሩካን
ኑ ግቡ ዉረሱ መንግሥቴን
ብሎ ሲናገር ኢየሱሴ
ለመስማት እጅግ ጓጓች ነፍሴ

2.ሞት ሆይ ድል መንሳትህ የት አለ
ስኦልስ መውጊያህ የት ተጣለ
የሚባልበትን ቀን ሳላይ
ጓግቼ አልቀርም በምድር ላይ
    
3.ጠላትና ጭፍሮቹ ጠፍተው
ጻድቃኖች ከጌታ ጋር ነግሠው
ለመሄድ እጅግ ናፍቂያለሁ
ንጉሤን ፊት ለፊት እስካየው

4.አበቃ የዚህ ዓለም ጣጣ
ተመልሶ ዳግም ላይመጣ
ብለን እንደ ታሪክ አልፈነው
አዲስን ኑሮ ልንጀምር ነው 
',
  'hagerigna',
  74,
  '{"artist":"የገርጂ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-075'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-076',
  'am',
  'የክርስቲያን ተስፋ',
  null,
  'የክርስቲያን-ተስፋ',
  'Imported from Hagerigna row 76.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  76,
  'የክርስቲያን ተስፋ',
  null,
  'የክርስቲያን ተስፋ አይደለም ቅዠት
እርግጠኛ እንጂ የየሱስ ምፃት
እንደ ተስፋ ቃሉ ጌታ ይገለጣል
የልጆቹን እንባ ከዓይናቸው ያብሳል
      
1.በነቢያት ትንቢት በመላዕክት በሐዋሪያት
የተረጋገጠው በየሱስ አንደበት
የክርስቲያን ተስፋ በእርግጥም እውነት ነው
ጌታችን አይዋሽም በቃሉ ታማኝ ነው

-- የክርስቲያን ተስፋ --

2.ሞት ተውጦ ሙታን ከስዖል ሲወጡ
በህይወት ያሉት በቅጽበት ሲለወጡ
እናያለን ገና የፃድቃንን ደስታ
ሃሌ-ሉያ እያሉ ሲያዜሙ በእልልታ

-- የክርስቲያን ተስፋ --
    
3.በዚህ ዓለም ኑሮ እየተሰቃዩ
በትዕግሥት ተስፋቸውን ጠብቀው የቆዩ
ሰማይ ሊወስዳቸው ጌታቸው ሲመጣ
ይገላገላሉ ከዚህ ዓለም ጣጣ

-- የክርስቲያን ተስፋ --

4.ለአንዳንዶች ይህ እውነት ውሸት ቢመስላቸው
የሱስ የማይመጣ መስሎ ቢታያቸው
አንድ ቀን አይቀርም በክብር መምጣቱ
እንደ መብረቅ ለዓለም ሁሉ መታየቱ

-- የክርስቲያን ተስፋ -- 
',
  'hagerigna',
  75,
  '{"artist":"ዘማሪ ሰላሙ ታገሠ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-076'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-077',
  'am',
  'በክፉ ቀን ደራሽ',
  null,
  'በክፉ-ቀን-ደራሽ',
  'Imported from Hagerigna row 77.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  77,
  'በክፉ ቀን ደራሽ',
  null,
  'በክፉ ቀን ደራሽ መከታ ጋሻዬ 
የምታመንበት ያለኝ መመኪያዬ
ከጎኔ የማይጠፋ መተማመኛዬ
በሀሩሩ ፀሐይ ማረፊያ ጥላዬ
ኢየሱስ ጌታዬ /3*/
       
1.ጨለማው ተገፎ ብርሃን በርቶልኛል/3*/
የዘመመው ቤቴ ቀና ብሎልኛል/3*/
ባዶ ሸለቆዬን በውኃ ሞልቶታል/3*/
በየዋሁ ጌታ ታሪኬ ታድሷል/3*/

-- በክፉ ቀን ደራሽ --

2.ነፍሴ በአንተ አርፋ አገኘች እፎይታ/3*/
በጠላቴ ዛቻ ትጥቄም አይፈታም/3*/
አልፈራም በፍጹም አልነዋወጥም/3*/
የታመንኩት ጌታ ሽንፈትን አያውቅም/3*/

-- በክፉ ቀን ደራሽ --
       
3.እግዚአብሔር ዛሬም ከእኔ ጋራ ነው/3*/
የሚያስደነግጠኝ የሚያስፈራኝ ማን ነው/3*/
ልቤ አይሸበር በከንቱ አሉቧልታ/3*/
ቅጥር ሆኖልኛል የሠራዊት ጌታ/3*/ 

-- በክፉ ቀን ደራሽ --
',
  'hagerigna',
  76,
  '{"artist":"የሀዋሳ ታቦር ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-077'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-078',
  'am',
  'ኦ መንፈስ ቅዱስ',
  null,
  'ኦ-መንፈስ-ቅዱስ',
  'Imported from Hagerigna row 78.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  78,
  'ኦ መንፈስ ቅዱስ',
  null,
  'ኦ መንፈስ ቅዱስ /2/
ወደ ልቤ ና ሥራ አለህ
ማደሪያህንም ታጸዳለህ
የማይመችህን ትዘልፋለህ

1.ወደ የሩሳሌም ቤተመቅደስ ገብተህ
እንዳባረርካቸው ነጋዴዎችን ገርፈህ
ዛሬም የኔ ጌታ ወደ ልቤ መጥተህ
አባርርልኝ እስቲ ክፋቴን ነቃቅለህ

-- ኦ መንፈስ ቅዱስ --
  
2.ቤቴ የጸሎት ቤት ይሆናል እንዳልከው
ልቤን የአንተ መቅደስ ማደርያህ አድርገው
ድንጋዩን ለውጠህ በሥጋ ለብጠው
ቆሻሻውን ጠርገህ የነጻ አድርገው

-- ኦ መንፈስ ቅዱስ --

3.ብዙ ነጋዴዎች ቦታውን ይዘዋል
ሸቀጦችን ዘርግተው ሥፍራ አሳጥተዋል
ያን የቀድሞ ጅራፍ አሁን ይዘህ መጥተህ
መንፈስ ቅዱስ አፅዳው ወደ ልቤ ገብተህ

-- ኦ መንፈስ ቅዱስ --

4.አንተ ስትገባ ሁሉም ይወጣሉ
ከነሸቀጣቸው ፈጥነው ይጠፋሉ
ያኔ በልቤ ውስጥ አድረህ ትውላለህ
አንተ እንደወደድከው በዚያ ትሠራለህ 

-- ኦ መንፈስ ቅዱስ --
',
  'hagerigna',
  77,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-078'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-079',
  'am',
  'ቀን ሳለ በጊዜያቱ',
  null,
  'ቀን-ሳለ-በጊዜያቱ',
  'Imported from Hagerigna row 79.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  79,
  'ቀን ሳለ በጊዜያቱ',
  null,
  'ቀን ሳለ በጊዜያቱ ሳይዘጋ በሩ በወቅቱ  
ቶሎ ና ና ና ና
መመለስ ይሻላልና
    
1.ሐሩሩ ያጠቃህ ግለቱ
መድከምና መዛል ጥማቱ
የባከንከዉ ወንድሜ ና
ጊዜው ዛሬ ነውና

-- ቀን ሳለ በጊዜያቱ --

2.ጨለማውን ብርሃን አስመስሎ
እውነቱን ከዓይኑ ከልሎ
መራራውን ጣፋጭ እያለው
ወንድሜን አታለለው

-- ቀን ሳለ በጊዜያቱ --

3.ማንም ሊሠራ የማይችልበት
ድቅድቅ ጨለማ የሚመጣበት
ከፊታችን ነውና
በብርሃን እንሥራ ና

-- ቀን ሳለ በጊዜያቱ --

4.እረኛ እንደሌለው ሆነህ
በተራራ ላይ ለብቻህ
የተቅበዘበዝከው ና
ትልቅ ዕረፍት አለህና

-- ቀን ሳለ በጊዜያቱ -- 
',
  'hagerigna',
  78,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-079'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-080',
  'am',
  'የእግዚአብሄርን ሀብት',
  null,
  'የእግዚአብሄርን-ሀብት',
  'Imported from Hagerigna row 80.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  80,
  'የእግዚአብሄርን ሀብት',
  null,
  '1.የሰናኦር ካባ እጅግ የሚያምረውን
ሌላም በመጨመር ብሩንና ወርቁን
በዓይኔ አይቼ ስለተመኘሁት
ከድንኳኔ በታች ወስጄ ቀበርኩት
    
የእግዚአብሄርን ሀብት ለራስህ አርገህ
የተቀመጥከውተደላድለህ
መልስ ይልሃል የዘረፍከውን
ከጌታ እግዚአብሔር የሰረቅከውን /2/

2. ሐናንያና ሚስቱ ጌታን አታለሉ
የኃጢአትን ዋጋ እዚያው ተቀበሉ
ወዲያው ከመቅጽበት ወድቀው መሞታቸው
ላልበሉት እንጀራ ምንም ላይጠቅማቸው

-- የእግዚአብሄርን ሀብት --
     
3. ጌታ እግዚአብሔር ሥራችንን ያያል
ዝም ሲል ሲዘገይ የረሳ ይመስላል
እኔ በበኩሌ ኃጢአቴን አውቃለሁ
ይቅር በለኝ የሱስ እጅግ በድያለሁ 

-- የእግዚአብሄርን ሀብት --
',
  'hagerigna',
  79,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-080'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-081',
  'am',
  'የእምነትን መልካም ጦርነት ተዋጋ',
  null,
  'የእምነትን-መልካም-ጦርነት-ተዋጋ',
  'Imported from Hagerigna row 81.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  81,
  'የእምነትን መልካም ጦርነት ተዋጋ',
  null,
  'አ   የእምነትን መልካም ጦርነት ተዋጋ
ዝ   በከንቱ አይደለም አለህና ዋጋ
ማ   አንተን ይረዱህ ዘንድ መላዕክቱን ያዛል
ች   ድሉ የጌታ ነው ሁሉ ይቻለዋል
 
1.ማንም ሊቀርብ በማይችል ብርሃን ውስጥ ይኖራል
ፈጽሞ አይዘገይም ጌታችን ይመጣል
ውጊያው የመንፈስ ነው ወንድሜ አትዘንጋ
ብርታትህ ጌታ ነው በርታና ተዋጋ

2.ጋሻውን አንግቦ ጠላት ቢመጣብህ
ውጊያው በርትቶብህ የማታልፍ ቢመስልህ
ሰልፉን ለርሱ ተወው የሱስ ያሸንፋል
እንዳልነበረአድርጎ ድል በድል ያደርጋል

3.ዘመኑ አስፈሪ ነው ወንድሜ አስተውል
ጌታን ተማፀነው ረድኤትህ ይመጣል
መንገዱ ረጅም ነው እንቅፋት ብዙ ነው
ፈቃድህን ለርሱ ተወው ድሉ የጌታ ነው 
',
  'hagerigna',
  80,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-081'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-082',
  'am',
  'አቤቱ እግዚአብሔር ሆይ',
  null,
  'አቤቱ-እግዚአብሔር-ሆይ',
  'Imported from Hagerigna row 82.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  82,
  'አቤቱ እግዚአብሔር ሆይ',
  null,
  '1. የጥንት አባቶቻችን 
መንግሥታትን ድል ያደረጉት
ጽድቅን ሁሉ የፈፀሙት
በእምነት ነው የተሻገሩት
እኛም እንሻለን በእምነት ልንሻገር/2/
   
አ   አቤቱ እግዚአብሔር ሆይ 
ዝ   እምነትን አብዛልን
ማ   እኛም እንደ ሐዋሪያት እንላለን
ች   እምነትን አብዛልን

2.ከግብፅ ሀብት ሁሉ ይልቅ 
ስለ አምላኩ መነቀፍን
የመረጠው መሰደድን 
በእምነት ነው አይቶ ተስፋውን
እኛም እንደ ሙሴ 
በእምነት እንድንወጣ/2/
  
3. ከግብፅ የወጡት ህዝብህ 
በደረቅ ምድርእንደሚያልፉት
ቀይ ባህር ውስጥም ያለፉት 
በእምነት ነው ሞገድ ያሰሩት
እኛም እንደ ህዝብህ በእምነት 
እንድንሻገር ባህሩን እንድንከፍል/2/

4.ሦስቱ ጀግኖች ወጣቶች 
የእሳትን ኃይል ያጠፉት
ከወላፈኑም የዳኑት 
ከእሥራት የተፈቱት
በእምነት ነው የቆሙት 
በእሳት የተራመዱት/2/
             
5. የሚበልጠውን ሀገር 
ሰማያዊውን በመናፈቅ
ምድራዊውንም በመናቅ
በእምነት ነው መስዋዕት የሆኑት
እኛም አገራችንን 
ሰማይን ብለን ልንል/2/ 
',
  'hagerigna',
  81,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-082'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-083',
  'am',
  'በተስፋ እንጠብቀው ጌታን',
  null,
  'በተስፋ-እንጠብቀው-ጌታን',
  'Imported from Hagerigna row 83.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  83,
  'በተስፋ እንጠብቀው ጌታን',
  null,
  'አ   በተስፋ እንጠብቀው ጌታን
ዝ   በመከራም ስላለ አብሮን
ማ   ካሁን ቀደምም ስለረዳን
ች   ተስፋ አለን
           
1.በርሱ የሚያምኑ አይወድቁምና
አፍረውም ከቶ አይመለሱምና
እኛ የምንመካዉ ቸር ነውና
አይጥለንምና

2.ጓደኛም ቢሆን ምስጥር ያወጣል
የደበቁትን ይዘረዝራል
ኢየሱስ ግን ገመና ሸፋኝ ነው
ምስጢረኛ ነው
     
3.የተለያየ ብሶት ያላችሁ
ለኑሮአችሁ ዋስትና ያጣችሁ
ሕይወትና መንገድ ኢየሱስ ነው
የተሰቀለው

4.ዛሬ እንኳ ባናገኝ ምንም ነገር
በችግር ሰቆቃም ብንታጠር
እንከብራለን ኢየሱስ ሲመጣ
ከፍ ይበል ጌታ
    
5.ካሁን ቀደምም ብዙ ረድቶናል
ከጭንቀት ማዕበል አሳልፎናል
ለዛሬው ጥያቄያችንም ሁሉ
ኢየሱስ መልስ ነው 
',
  'hagerigna',
  82,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-083'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-084',
  'am',
  'የሰማዩ አምላክ',
  null,
  'የሰማዩ-አምላክ',
  'Imported from Hagerigna row 84.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  84,
  'የሰማዩ አምላክ',
  null,
  'የሰማዩ አምላክ ያከናውንልናል
እኛም ባሮቹ ነን ተነስተን እንሰራለን

1.የኢየሩሳሌም ቅጥር ፈርሷል አሉኝና
ለአያሌ ቀን አለቀስኩኝ ራሴን አዋረድኩኝና
ከሰማይ ሆኖ ሀዘኔን አየና ቅጥሩ ተሰራ ጌታ ረዳኝና

የሰማዩ አምላክ ያከናውንልናል
እኛም ባሮቹ ነን ተነስተን እንሰራለን

2.ዛሬም ሥራችንን የሚንቅ አሽሟጣጭ ቢኖርም
ጦቢያና ሰንባላጥ ንቀው ቢስቁብንም
ለእኛ ግን የሰማዩ አምላክ ያከናውንልናል

የሰማዩ አምላክ ያከናውንልናል
እኛም ባሮቹ ነን ተነስተን እንሰራለን

3.እንደ ነህምያ ታጥቀን በእንባ ፀልየን
ብንወጣ ለሩጫ ጌታን አስቀድመን
ለእኛ ግን የሰማዩ አምላክ ያከናዉንልናል

የሰማዩ አምላክ ያከናውንልናል
እኛም ባሮቹ ነን ተነስተን እንሰራለን

4.ሁሉም በመክሊቱ ሥራውን በፍጥነት ቢያካሂድ
ሰይጣንን ጠላቱን በቃሉ ቢጋፈጥ
ለእኛ ግን የሰማዩ አምላክ ያከናውንልናል 

የሰማዩ አምላክ ያከናውንልናል
እኛም ባሮቹ ነን ተነስተን እንሰራለን
',
  'hagerigna',
  83,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-084'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-085',
  'am',
  'እግዚአብሄርን ወደድኩት',
  null,
  'እግዚአብሄርን-ወደድኩት',
  'Imported from Hagerigna row 85.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  85,
  'እግዚአብሄርን ወደድኩት',
  null,
  'እግዚአብሄርን ወደድኩት ጩኸቴን ስለሰማ
የደረቀችውን ሕይወቴን በመንፈሱ ስላለማ
ከጠላት ጋርዶኛልና አርነቴን ከሚቀማ
ምሥጋና እሰዋለታለሁ ለአምላኬ ባማረ ዜማ
  
1.የሞት ጥላ ዙሪያዬን በከበበኝ ጊዜ ሁሉ
የደህንነት ዋስትናዬ ከሕይወቴ ጠፍቶ በሙሉ
አምላኬ አምላኬ ብዬ በጭንቀት ጠራሁትና
እርሱም ወዲያው ዘምበል አለኝ ይድረሰው ታላቅ ምሥጋና

-- እግዚአብሄርን ወደድኩት --

2.በጨለማ ለሚኖሩ ታላቅ ብርሃን በራላቸው
በእግዚአብሄር ፊት ተሰምቷል የምስኪኖች ጩኸታቸው
ቃል ኪዳኑንም አስተውለው በፊቱ ለቀረቡ
ስሙ ለዘላለም ይባረክ ምህረቱን ከኛ ያላራቀ

-- እግዚአብሄርን ወደድኩት --
    
3.እግዚአብሄር መኃሪና በልቡም ጻድቅ ቸር ነው
ለዱር አራዊትም ሁሉ ምግባቸውን የሚሰጠው
በጨለማ ለተዋጡ መፍትሄ ነው ለደሀ ሰው
በልጁ በክርስቶስ ስም ክብር ምስጋና ይድረሰው

-- እግዚአብሄርን ወደድኩት --

4.የምሥጋናዬን መስዋዕት ሁሌ አቀርብለታለሁ
በሕዝቡ ጉባኤ መኻል እዘምርለታለሁ
እግዚአብሄር ለውለታው ምንን እመልሳለሁ
ስሙ ከፍ ከፍ ብሎ ይታይ በሰማይ በምድር ሁሉ ካለው 

-- እግዚአብሄርን ወደድኩት --
',
  'hagerigna',
  84,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-085'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-086',
  'am',
  'እነሆ እነሆ እነሆ',
  null,
  'እነሆ-እነሆ-እነሆ',
  'Imported from Hagerigna row 86.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  86,
  'እነሆ እነሆ እነሆ',
  null,
  'እነሆ እነሆ እነሆ ዘር ሊዘራ ወጣ
አንዱ በድንጋይ ሌላው በእሾህ ቀረ ያለ ተስፋ
ከዚያ ሁሉ አንዱ ነው እንደተፈለገው
በመልካም አፈር ላይ ወድቆ የተረፈው
ከወፎች ከፀሐይ አልፎ የፀደቀው
ፍሬውንም በጊዜው አሟልቶ የሰጠው
     
1.የዘሪው ምሳሌ የአምላክ መንግሥት ቃል ነው
በመንገድ ዳር ወድቆ በወፍ የተበላው
በትጋት በደስታ እየሰሙ ሳሉ
በጠላት ተታልለው አውጥተው ወዲያው ጣሉ

-- እነሆ እነሆ እነሆ --

2.አንዳንዶች በእምነት ዳር ዳር ይሮጣሉ
አንድም ሳያስተውሉ ሁሌ ይሰማሉ
ሥር ስላልሰደዱ ፈጥነውይደርቃሉ
ነፋስ ከነፈሰ በቀላል ይወድቃሉ

-- እነሆ እነሆ እነሆ --
   
3.ዛሬም በእኛ ዘመን ብዙዎች ይሰማሉ
አንዳንዶች ሲተጉ ሌሎች ይዝላሉ
ወዲያው ፈጥነው ታይተው ይጠወልጋሉ
መስማትንስ ሳይተው ያለፍሬ ይቀራሉ

-- እነሆ እነሆ እነሆ --

4.መስማትን ሁልጊዜ እኛም እንሰማለን
ግን ወደ እውነት እውቀት መቼ እንደርሳለን
እስካሁንም ገና ያለ ማስተዋል ነን
ሰሚ ብቻ ሳንሆን አድራጊዎች አድርገን 

-- እነሆ እነሆ እነሆ --
',
  'hagerigna',
  85,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-086'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-087',
  'am',
  'ፀልየው ምን አጡ',
  null,
  'ፀልየው-ምን-አጡ',
  'Imported from Hagerigna row 87.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  87,
  'ፀልየው ምን አጡ',
  null,
  'ፀልየው ምን አጡ /2*/
ዛሬም እንደ ጥንቱ
አቤትቸርነቱ

1.መዝጊያውን ለሚያንኳኩ ሲከፈትላቸው
የሚጠይቁትም ሲመለስላቸው
የምሥጋና ነዶ በእጃቸው ይዘው
ይመጣሉ እንጂ ወደ አምላካቸው

-- ፀልየው ምን አጡ --
   
2.መርደክዮስ የሞትን አዋጅ ያስቀየረው
ዳንኤል የንጉሡን ህልም መፍታት የቻለው
መካኒቱ ሃና ወልዳ ያቀፈችው
በፀሎት ኃይል ነው ተዓምር የተሠራው

-- ፀልየው ምን አጡ --

3.ኢያሱ በገባዖን ፀሐይ እንዲትቆም
ጨረቃም እንዳትሄድ የገታት በዔሎን
አይደለም በኃይሉ በእምነት በፀሎት ነው
የኢያርኮንም ግንብ የደረማመሰው

-- ፀልየው ምን አጡ --
    
4.እኔም በዘመኔ ለአምላኬ ነግሬ
ያልተመለሰልኝ የለም ተማፅኜ
ገና ከዚህ የሚበልጥ እንደሚያደርግልኝ
ጌታን አምነዋለሁ እንደማይሰለቸኝ

-- ፀልየው ምን አጡ --

5.ትላንት የነበረው ዛሬም ደግሞ ያለው
የምስኪኑን ጩኸት ሰምቶ የማያልፈው
የተቋጠረውን ቋጠሮ የሚፈታ
ይክበር ለዘላለም ኤልሻዳዩ ጌታ 

-- ፀልየው ምን አጡ --
',
  'hagerigna',
  86,
  '{"artist":"ዘማሪ ሰላሙ ታገሠ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-087'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-088',
  'am',
  'ወርቃማው መንግሥትህ መጥቶ',
  null,
  'ወርቃማው-መንግሥትህ-መጥቶ',
  'Imported from Hagerigna row 88.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  88,
  'ወርቃማው መንግሥትህ መጥቶ',
  null,
  '1. ትካዜ በሐሴት ተውጦ
ድካማችን ተለውጦ
በብርታት አንተን ለማየት 
ፊት ለፊት ለመገናኘት
መልካም ፈቃድህ ይፈጸም የፅዮን አለት

ወርቃማው መንግሥትህ መጥቶ
አስመሳይ ምስሎችን ፈጭቶ
ግዛትህ በምድር ላይ ሰፍቶ
እንደ ፀዳል ደምቆ በርቶ
መቼ ነው የምናየው ጌታ ተስፋችን ሞልቶ
    
2.አንተ አባታችን ሆነህ እኛም ሆነን ልጆችህ
የአፍህን ቃል እንድንመገብ
በአንድነት ተሰብስበን
የቀራኒዮ ወዳጃችን የሱስ እርዳን

-- ወርቃማው መንግሥትህ መጥቶ --

3.ሁሉን የምትችል ጌታ ያለህና የነበርህ
ታላቁን የተስፋ መንግሥት በእጅህ ስላደረግህ
ስለነገሥህም ተመስገን ከፍ በል እንድንልህ
ሁላችንን አትመን የሱስ በመንፈስህ

-- ወርቃማው መንግሥትህ መጥቶ --
   
4.ማዳንና ኃይል መንግሥትህ ሁሉም ነገር ያንተ ሆኖ
ሥልጣን ግዛትህ ተስፋፍቶ በዓለም ላይ ስምህ ገኖ
የወንድሞቻችን ከሳሽ በጥልቁ ጉድጓድ ተጥሎ
የተራራው ድንጋይ ይምጣልን ተፈንቅሎ 

-- ወርቃማው መንግሥትህ መጥቶ --
',
  'hagerigna',
  87,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-088'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-089',
  'am',
  'የሱስን የሚከተል ይፈወሳል',
  null,
  'የሱስን-የሚከተል-ይፈወሳል',
  'Imported from Hagerigna row 89.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  89,
  'የሱስን የሚከተል ይፈወሳል',
  null,
  'የሱስን የሚከተል ይፈወሳል
ጌታን የሚከተል ይፈወሳል
ለነፍስም ሆነ ለሥጋውጤናን ያገኛል
    
1.ኑሮ ያንከራተተው ሰው ተስፋ የቆረጠ
በሰው ዘንድ ተንቆ ጥግ የወደቀ
የሱስን ቢከተል አንድ ቀን ይፈወሳል
እርሱን ጠርቶ ባዶ እጁን ማን ይመለሳል/ 3*/

-- የሱስን የሚከተል ይፈወሳል --

2.አሥራ ሁለት ዓመት ሙሉ ደም የሚፈሳት ሴት
ገንዘቧን ሁሉ ጨርሳ በመድኃኒት ቤት
የመድሃኒታችንን ልብስ በእምነት ሲትነካ
ደሟ ወዲያውኑ ቆመ ፈወሳት ጌታ/3/

-- የሱስን የሚከተል ይፈወሳል --

3.የልብን ቁስል የሚደርስ ጠጋኝ ወጌሻ
በቃሉ ብቻ የሚያዲን ሳያስር ፋሻ
ተስፋ ለቆረጡት የሚደርስ ባለቀው ሰዓት
በሰማይ በምድር ይባረክ አባ የኛ አባት/3*/

-- የሱስን የሚከተል ይፈወሳል --

4.ወደርሱ ስንገሰግስ ሆነን ከርታታ
የሚያስፈልገንን ሳይሰጥ አይሸኝም ጌታ
ማንም ሰው መጥቶ ቢያለቅስ እፊቱ ወድቆ
እጁን ይዞ ያነሳዋል እምባውን ጠርጎ/3*/ 

-- የሱስን የሚከተል ይፈወሳል --
',
  'hagerigna',
  88,
  '{"artist":"ዘማሪ ተፈራ ወ/ማርያም"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-089'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-090',
  'am',
  'አምላካችን ሆይ እናመሰግንሃለን',
  null,
  'አምላካችን-ሆይ-እናመሰግንሃለን',
  'Imported from Hagerigna row 90.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  90,
  'አምላካችን ሆይ እናመሰግንሃለን',
  null,
  'አ   አምላካችን ሆይ እናመሰግንሃለን
ዝ   ለስምህም ምሥጋና እናቀርባለን
ማ   ታላቅነትህን   እናውጃለን
ች   ስላደረግከው ድንቅ ሥራህ እናወራለን
   
1.ባዶነታችንን ሁሉ አይተህ
በመንፈስህ ሙላት ሞላኸን
ህይወታችንን ሁሉ ጌታ ለወጥከዉ
የምንሰጥህ ነገር የለንም
እንበል ተመስገን

2.ለሞት የጥፋት ሆነን ነበርን
ፍፁም መጠጊያ የሌለን ሆነን
ነገር ግን ጌታ እኛን መረጥከን
ዘላለማዊ ህይወት ሰጠኸን
ክበር ተመስገን
     
3.ደንቆሮዎች ነበርን መስማት የማንችል
እውሮች ነበርን ማየት የማንችል
መስማት እንድንችል ከፈትክልንና
ከፍ በል የሱስ ስመ ገናና
ይኸው ምሥጋና

4.ሳንፈልግህ እኛን ፈለግከን
በቤትህ እንድንኖር ወንበር ሰጥተኸን
ረከዓለም መከራ እኛን መረጥከን
ከፍ በል አምላክ ስለወደድከን
ስለ ወደድከን 
',
  'hagerigna',
  89,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-090'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-091',
  'am',
  'ይህን ሥፍራ',
  null,
  'ይህን-ሥፍራ',
  'Imported from Hagerigna row 91.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  91,
  'ይህን ሥፍራ',
  null,
  'ይህን ሥፍራ/3x/ ጌታ ጴንኤል አድርግልን /2x/
ከእግዚአብሔር ጋር የመታገል 
በረከትን የመቀበል
የአታላይነት ስም የሚቀይርበት 
ስፍራ ጴንኤል አድርግልን
       
1.የእግዚአብሔር መልአክ ከላይ ወርደዉ
በረከትን ይዘዉ መጥተዉ
በመካከላችን ተገኝተዉ
ባርከዉን ይመለሱ ተሸንፈዉ

-- ይህን ሥፍራ --

2.ካልባረክከን አንለቅህም
ባልተቀየረ ስም አንጓዝም
ከፊት ለፊታችን ጠላት አለንና
የለአንተ አቅም የለንምና

-- ይህን ሥፍራ --
   
3.እግዚአብሐርን ፊት ለፊት አይተን
ድና ቀርታ ሰዉነታችን 
ሊነጋ በተቀረበ ሰዓት ጉዞአችንን
ልንጀምር እንፈልጋለን ተለዉጠን

-- ይህን ሥፍራ --

4.ስሙ ድንቅ የሆነ ታጋይ መልአክ
የህዝቡን ልብ የሚመረምር
ዛሬ ይምጣና ይጎብኘን 
የአታላይነትን ስም ይቀይርልን 

-- ይህን ሥፍራ --
',
  'hagerigna',
  90,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-091'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-092',
  'am',
  'እርሻው ይታረስ',
  null,
  'እርሻው-ይታረስ',
  'Imported from Hagerigna row 92.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  92,
  'እርሻው ይታረስ',
  null,
  'እርሻው ይታረስ በመጀመሪያው ዝናብ
ለኋለኛው ዝናብ እንዲዘጋጅ በደንብ
ነገ አርሳለሁ ማለት ስንፍና አይደለም ወይ
ከአሁኑ ይዘጋጅ ምርታማ እንዲሆን
ውጤቱ ኋላ ሲታይ
  
1. እሾክ አሜኬላ ይውጣ ከመቅደሱ
የኃጢአት ልብስ ከእኛ ይወገድ ቀሚሱ
ለየሱስ የሚሆን ዛሬ ማነው ምርጥ ዘር
ከቤቱ ሳይተኛ ወንጌል የሚዘራ በማሳው የሚዞር

-- እርሻው ይታረስ --

2. ዛሬ በእያንዳንዱ ቤት ብጥብጥ የሚነሳው
ለዓለም ምኞት ሳይሆን ለሰማይ በሚባለው
ቀን ማታ ሳይባል ሥራው የሚሠራው
መከሩ የሚወቃው ገለባው ተለይቶ ጤፍ እንዲወጣ ነው

-- እርሻው ይታረስ --

3. በትር ከላይ መጥቶ እየለካ ያለው
የእግዚአብሄርን መቅደስ ይኸውም ሰብዓዊ ሰው
ገጣሚ ሚሆነው ለሰማዩ አባት
ተለክተሃል ወይ ተስማሚ ሆንክ ወይ ለዘላለሙ መንግሥት

-- እርሻው ይታረስ --

4. ለረጅም ዘመናት ሲታወጅ የቆየው
ጊዜው አሁን ደረሰ የነገሮች ድምዳሜው
ትንሽ ጥቁር ደመና በሰማያት ታይታ
ወደ ምድር ስትወርድ ከመላዕክት በደስታ
ንጉሡን አጅበው አሜን ማራናታ

-- እርሻው ይታረስ -- 
',
  'hagerigna',
  91,
  '{"artist":"ዘማሪ ኪዳኔ ኪታቦ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-092'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-093',
  'am',
  'የወንድሞች በሕብረት መቀመጥ',
  null,
  'የወንድሞች-በሕብረት-መቀመጥ',
  'Imported from Hagerigna row 93.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  93,
  'የወንድሞች በሕብረት መቀመጥ',
  null,
  'የወንድሞች በሕብረት መቀመጥ
እንዴት ያማረ ነው በእዉነት
ለሚሻለዉ ነገር ሕይወት ላለዉ ጉዳይ
በእግዚአብሔር ፊት መሰብሰብ/መገኘት

1.ዓለም ተጨንቃለች ሠላም ዕረፍትን አጥታ
የሱስ ክርስቶስን ከመማፀን ዘንግታ
ታዲያ ምን ይበጃል መፍትኼዉስ የት ይገኛል/2/
መንበርከኩ ይሻላል/2/

-- የወንድሞች በሕብረት መቀመጥ --
   
2.አቤት የዚህ ዘመን የሰዉ ልጆች ጭንቀቱ
ከእግር ጣት እስከ ራስ የሚታየዉ ሥጋቱ
እምነት ለሌላቸዉ የሱስ ለሌላቸዉ/2/
በእርግጥም አስጊ ነው/2/

-- የወንድሞች በሕብረት መቀመጥ --

3.እኛስ የብርሃን ልጆች በክርስቶስ እየሱስ
ከድቅድቅ ጨለማ ከወጥመድ ያመለጥን
መሰብሰባችንን ከቀድሞ እናብዛ/2/
ዘመኑን እየዋጀን/2/

-- የወንድሞች በሕብረት መቀመጥ --

4.ጌታን ለማገልገል ቃል-ክዳን እየገባን
በፆም ፀሎት ዛሬ ራስን እየቀደስን
ዘወትር ሳይሰለቸን ቃሉን እያጠናን/2/
ማስተዋል እንድኖረን/2/

-- የወንድሞች በሕብረት መቀመጥ --

5.በእርግጥ ያለንበት ዘመን እጅግ ክፉ ነው
ሁሉም በጭንቅ ሀሳብ ተይዞ ነዉ ምናየዉ
የሱስ እባክህን የዳግም ምፃትህን/2/
ዘመኑ ይፍጠንልን/2/ 

-- የወንድሞች በሕብረት መቀመጥ --
',
  'hagerigna',
  92,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-093'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-094',
  'am',
  'ኦ ጌታ ማደግ ያስፈልገናል',
  null,
  'ኦ-ጌታ-ማደግ-ያስፈልገናል',
  'Imported from Hagerigna row 94.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  94,
  'ኦ ጌታ ማደግ ያስፈልገናል',
  null,
  '1. ጊዜው ትዝ ይለናል በድፍረት ሆነን 
መልዕክት ለዓለም ያበሰርንበት
ታላቁ ፀጋህ ከእኛ ጋር ሆኖ 
ተራራ ወጥተን የወረድንበት
ዛሬ ግን ድካም ስምጥ አድርጎናል 
መመስከር ቀርቶ እኛም ዝለናል
ድካም ድንዛዜን ከእኛ ቁረጠው 
ኸረ ታረቀን ማረን ብለናል

ኦ ጌታ ማደግ ያስፈልገናል
ኦ የሱስ መበርታት ያስፈልገናል
ኦ ጌታ መለወጥ ያስፈልገናል
ኦ የሱስ መንቃት ያስፈልገናል
ካመንንበት ጊዜ ይልቅ መዳናችን እጅግ ቀርቧል

2.ለሁላችን የአምልኮት መልክ አለን 
ኃይልህን ግን ፈጽሞ ክደናል
ለሥጋ ምኞት ምቾት ተገዝተን 
የቀደመውን ፍቅር ትተናል
ቶሎ ንሥሐ እንድንገባ 
በፊትህ ተደፍተን ተንቀጥቅጠን
ያኔ ሲሰራ የነበረውን 
የቀድሞ ፍቅር ዛሬም ና ስጠን

-- ኦ ጌታ --

3.ዛሬም አሁንም ወተትን ብቻ 
መጋት ሆኗል ሁል ጊዜ ሥራችን
አላዋቂነት እያጠቃን ነው 
የህጻን ምግብ ነው ሁሌ ምግባችን
ጠንካራ ምግብም እንለማመድ 
የሱስ ሊመጣ ነዉ ወገን እንበርታ
ታላቅ እምነትና አጽናኙን ፀጋ 
እርሱ እንዲሰጠን ከአሪያም ጌታ

-- ኦ ጌታ --

4.በቅድስና ህይወት ለመኖር 
ከዓለም ምኞት ምቾት ሁሉ ርቀን
የሚመጣውን ንጉሥ ለመገናኘት 
ስንፍና ሳይዘን ተጠንቅቀን
የእምነት ጥሩር ለብሰን እንድናሸንፍ 
ያን ክፉ ጠላት የቀደመዉን
የክርስቶስ ፀጋና የእግዚአብሄር ፍቅር 
እስከ ዘላለም ከኛ ጋር ይሁን

-- ኦ ጌታ -- 
',
  'hagerigna',
  93,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-094'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-095',
  'am',
  'በአዲስ ዓመት',
  null,
  'በአዲስ-ዓመት',
  'Imported from Hagerigna row 95.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  95,
  'በአዲስ ዓመት',
  null,
  '1.ከአምናዉ ወደ ዘንድሮ
በኃይሉ ብርታት አሻግሮ 
ይኼዉ ለዛሬ አደረሰን
ጌታ አምላካችን ይመስገን

አ   በአዲስ ዓመት አዲስ ምሥጋና
ዝ   ለጌታ የሱስ እንደ ገና
ማ   እስከ ዛሬ ረድቶናልና
ች   በምህረቱ ኖረናልና
         
2.እንደ ምህረቱ ባይሆን ኖሮ
እዚህ ባልተገኘን ዘንድሮ
ነገር ግን ፈጽሞ ያልጠፋነው
ከምህረቱ የተነሳ ነው

3.ከየቦታዉ ጠላት ሲያጓራ
ከጥፋት ሠራዊቱ ጋራ
ቢያበዛብን ዛቻ ድንፋታ
ድል አገኘን የማታ ማታ
   
4.ኃይልን በሚሰጠን በእርሱ ዘንድ
ያለፈዉን እንደ ታሪክ ትተን
ለመጓዝ እርዳን አቤንኤዘር
ሊቀ-ካህናችን የሱስ ይክበር 
',
  'hagerigna',
  94,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-095'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-096',
  'am',
  'እስከ ፍጻሜ ጽና',
  null,
  'እስከ-ፍጻሜ-ጽና',
  'Imported from Hagerigna row 96.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  96,
  'እስከ ፍጻሜ ጽና',
  null,
  'እስከ ፍጻሜ ጽና በእምነትህ
እንዳትወድቅ ተጠንቀቅ ሰውን እያየህ
ቆራጥ ሁን በጉዞህ ከቶ አታመንታ
በያዝከው እውነት ጽና ጌታ እስኪመጣ

1.ወላዋይ እምነት አይኑር በህይወትህ
መሠረትህን አጠንክር ገንባ በአምላክህ
የሰነፎች ምክር እንዳይማርክህ
ተጠንቀቅ እንዳትወድቅ ከጽናትህ

-- እስከ ፍጻሜ ጽና --

2.ልብህን አጽና ወገብህን ታጠቅ
ክፉ ጊዜ ነው ዘመኑን እወቅ
አስመሳይ እምነት በጉዞህ አይኑር
በያዝከው እውነት ጽና ጉልበትህ ይጠንክር

-- እስከ ፍጻሜ ጽና --

3.ከእንግዲህስ እኔ ተዘጋጅቻለሁ
እስከ ሞትም ቢሆን ጌታዬን እከተላለሁ
እያልክ እንደ ጴጥሮስ በሞኝነት ያለህ
ሰው ሆይ ራስህን መርምር በሩ ሳይዘጋብህ

-- እስከ ፍጻሜ ጽና --

4.ጽኑ አቋምህን ካሁኑ አስተካክል
የምነገርህን ቃል ሰው ሆይ አስተውል
ዕለት ተዕለት ጽና በእምነት ጉዞህ
አክሊል እስክትሸለም ከአዳኝህ 

-- እስከ ፍጻሜ ጽና --
',
  'hagerigna',
  95,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-096'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-097',
  'am',
  'ለኔ የሚሆነኝ',
  null,
  'ለኔ-የሚሆነኝ',
  'Imported from Hagerigna row 97.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  97,
  'ለኔ የሚሆነኝ',
  null,
  'ለኔ የሚሆነኝ እንዳንት አላየሁም
አመልህ እንደ ሰው አይለዋወጥም
በተግባርህ ፅኑ በቃልህም ታማኝ
ወዳንተ ተጠጋሁ ፍቅርህም ማረከኝ

1. ምድራዊ ጓደኛ ከቶ አልፈልግም
አንተው ትበቃለህ ሌላም አያሻኝም
ቢኖረኝ ባይኖረኝ ሲቸግረኝ ሳጣም\t
ካንተ ሌላ ወዳጅ ከቶ አልመኝም

-- ለኔ የሚሆነኝ --

2. ወዳባትህ ስትሄድ ቃልህን ነግረኸኝ
የሚያፅናና ወዳጅ መንፈስህን ላክህልኝ
አንተ ልማድህ ነው መኖር እንደ ቃልህ
እንደ ሰው አይደለህ መቼ ትዋሻለህ

-- ለኔ የሚሆነኝ --

3. በጣምም ሲጨንቀኝ ምርር ብሎኝ ሳለቅስ
ልጄ አይዞህ ብለህ እንባዬን ስታብስ
ወዳጅ ባጣሁበት ወዳጅ ስለሆንከኝ
ስላንተ አወራለሁ ባይኔ ስላየሁኝ

-- ለኔ የሚሆነኝ --

4. አንደበቴን ስከፍት ሥራህን ሳወራ
ምስጋናን ስዘምር ስምህን ስጠራ
ልቤን ደስ ይለዋል ሐሴትን ይሞላል
ኸረ አይጠገብም ሥራህ መቼ ያልቃል

-- ለኔ የሚሆነኝ --
',
  'hagerigna',
  96,
  '{"artist":"የሌሰፔራንስ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-097'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-098',
  'am',
  'አንድ ቀን',
  null,
  'አንድ-ቀን',
  'Imported from Hagerigna row 98.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  98,
  'አንድ ቀን',
  null,
  '1. አንድ ቀን ይመጣል ልብ የማይዝልበት
ጨለማ እና ስቃይ እምባም የሌለበት
በወርቃማው ሐገር ሁሉም ሰላም ሆኖ
ምን ዓይነት ግሩም ቀን ይሆናል

ምን ዓይነት ግሩም ቀን ይሆን ጌታዬን ሳይ
ፊቱን ስመለከት በፀጋው ያዳነኝን
በእጁ ይዞኝ ሲሄድ ወደ ተስፋው ሐገር
ምን ዓይነት ግሩም ቀን ይሆናል

2. በዚያ ሀዘን የለም ችግር ጭንቀት አይኖርም
መከራ እና ስቃይ መለያየት አይኖርም
ለዘላለም ከጌታ ጋር እኖራለን
ምን ዓይነት ግሩም ቀን ይሆናል

-- ምን ዓይነት ግሩም ቀን --

3. የትንሣኤን ተስፋ ካገኘሁ ጀምሮ
ተፅናናሁ ተባረክሁ ተስፋም አገኘሁኝ
ሞት ሆነ ሐዘን ችግር ከቶ ምን ያስፈራኛል
ምን ዓይነት ግሩም ቀን ይሆናል

-- ምን ዓይነት ግሩም ቀን --
',
  'hagerigna',
  97,
  '{"artist":"የፍልውሀ  ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-098'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-099',
  'am',
  'ስመለከት',
  null,
  'ስመለከት',
  'Imported from Hagerigna row 99.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  99,
  'ስመለከት',
  null,
  '1. ስመለከት ሰማዩን ጉም እንደ ጥጥ ሲፈተል
በጋው አልፎ ሳይ ክረምቱን ወጀብ ንፋስ ማዕበሉን
ይደንቀኛል የሱ ስራ የቱን ትቼ የቱን ላውራ
ይገርመኛል የእርሱ ስራ የቱን ትቼ የቱን ላውራ

ሃሌሉያ ክብር ላምላካችን
ሃሌሉያ ስግደት ላምላካችን
ሰማይና ና ምድር ዘምሩ በደስታ
ሁሉን በቃል ሰርቷል ምና መልከው ጌታ /2X/

2. የአበቦቹ መዓዛ የአራዊቶቹ ፍንጠዛ
ሜዳው ጋራው ተራራው ልምላሜ ሸለቆውም
ይደንቀኛል የእርሱ ሥራ የቱን ትቼ የቱን ላውራ
ይገርመኛል የእርሱ ሥራ የቱን ትቼ የቱን ላውራ

-- ሃሌሉያ ክብር ላምላካችን --

3. በባህር ዳር በውቅያኖስ የአሣዎች የደስ ደስ
በብር ቀለም አሸብርቀው አዕዋፍ ሲዘምሩ ማልደው
ይደንቀኛል የእርሱ ሥራ የቱን ትቼ የቱን ላውራ
ይገርመኛል የእርሱ ሥራ የቱን ትቼ የቱን ላውራ

-- ሃሌሉያ ክብር ላምላካችን --
',
  'hagerigna',
  98,
  '{"artist":"የገርጂ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-099'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-100',
  'am',
  'ተስፋ አለኝ',
  null,
  'ተስፋ-አለኝ',
  'Imported from Hagerigna row 100.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  100,
  'ተስፋ አለኝ',
  null,
  'አ   ተስፋ አለኝ/ / 2X/
ዝ   የጠራኝ ጌታ ላይተወኝ
ማ   ቃል የገባውን ፈፅሞልኝ
ች   አያለሁ ተስፋ አለኝ

1. እወስድሃለሁ ያለኝ ሥፍራን ያዘጋጀልኝ
አንድ ቀን ቃሉን ሞልቶ ባይኔ እንደሚያሳየኝ
አምናለሁ/4X/ መጥቶ እንደሚወስደኝ

2. ትለወጪያለሽ ያለኝ ትነጠቂያለሽ ያለኝ
ከዚህ ምድር ስቃይም ፍፁም ታርፊያለሽ ያለኝ
አምናለሁ/4X/ መጥቶ እንደሚያሳርፈኝ

3. በውሃ ውስጥ ታልፋለህ በእሳቱም ታልፋለህ
እኔ ካንተ ጋራ ነኝ አልለይህም ያለኝ
አምናለሁ/4X/ እንደሚያሻግረኝ

4. በብርጭቆ ባህር ላይ ትቆማላችሁ ያለን
ባዲስ ቅኔ ዝማሬ ታቀርባላችሁ ያለን
እናምናለን/4X/ እንደሚፈፅምልን
',
  'hagerigna',
  99,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-100'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-101',
  'am',
  'እንግዳ ነኝ እኔ',
  null,
  'እንግዳ-ነኝ-እኔ',
  'Imported from Hagerigna row 101.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  101,
  'እንግዳ ነኝ እኔ',
  null,
  '1. እንግዳ ነኝ እኔ ስኖር በዚች ዓለም
ሐብቴም በሰማይ ነው ከዚህ ምንም የለኝ
መላዕክት ይጠሩኛል ከሰማይ በር ከፍተው
ከእንግዲህ ይህ ዓለም ፍፁም ቤቴ አይደለም

ታማኝ ወዳጅ እንዳንተ እንደሌለኝ
ጌታ ሆይ ታውቃለህ እኔን የሚያፅናናኝ
መላዕክት ይጠሩኛል ከሰማይ በር ከፍተው
ከእንግዲህ ይህ ዓለም ፍፁም ቤቴ አይደለም

2. ወደ ፊት ልራመድ ይጠባበቁኛል
የሱስ ይቅር ብሎ በሩን ከፍቶልኛል
ምንም ድሀ ብሆን እኔን አይተወኝም
ከእንግዲህ ይህ ዓለም ፍፁም ቤቴ አይደለም

-- ታማኝ ወዳጅ --

3. አፍቃሪ አዳኝ አለኝ በላይኛው ሐገር
ናፍቆቴን አልተውም ፊቱን እስካይ ድረስ
በሰማይ ደጅ ቆሞ ይጠባበቀኛል
ከእንግዲህ ይህ ዓለም ምንም አይረባኝም

-- ታማኝ ወዳጅ --
',
  'hagerigna',
  100,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-101'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-102',
  'am',
  'እስኪ ድምፄ ላሰማ',
  null,
  'እስኪ-ድምፄ-ላሰማ',
  'Imported from Hagerigna row 102.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  102,
  'እስኪ ድምፄ ላሰማ',
  null,
  'እስኪ ድምፄ ላሰማ መቅደስህ ገብቼ
በገናዬን ላንሳ ማልጄ ማልጄ 

1. ቅርቅር ይለኛል ሳላመልክ ብወጣ
ለተገባው ጌታ ምስጋናዬን ላብዛ
ድምፄ ፄን ን አልቆጥብም ሰ ሰጥ ጥ ቶኛል አንደበት
ዝቅ ዝቅ ብዬ ክ ክ ብሬን ልጣልለት/2X/

-- እስኪ ድምፄ ላሰማ --

2. እንዴት ያስችለኛል ዝም ብሎ መሔድ
ለውለታው ምላሽ ጥቂትም ሳላደርግ
ሳልቀንስ ሳልቆጥብ ልሰዋ ለውዴ
እንዲህ ተደርጎልኝ አላስቻለኝ እኔ/2X/

ኧረ ማነው እንዳንተ ለእኔ የደረሰው
ኧረ ማነው እንዳንተ ልቤን ያሳረፈው/4X/
',
  'hagerigna',
  101,
  '{"artist":"የሀዋሳ ታቦር ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-102'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-103',
  'am',
  'አዋጁ ተነግሮ',
  null,
  'አዋጁ-ተነግሮ',
  'Imported from Hagerigna row 103.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  103,
  'አዋጁ ተነግሮ',
  null,
  '1. ስለ ሰዎች በደልና ኃጢያት ብሎ
ወደ ምድር የወረደው ክብሩን ጥሎ
ተሰቃይቶ ተቸግሮ የተገፋው
ከእንግዲህ ግን በድል ከብሮ ነው የሚመጣው

አ   አዋጁ ተነግሮ በምድር ላይ
ዝ   መለከት ሲነፋ ከሰማይ
ማ   በክብር ሲመጣ ጌታችን
ች   እንዘምራለን ሁላችን

2. ድል አድርጎ ጠላታችን ያሳፈረው
ከብሮ ሊነግስ ከሞት በድንቅ የተነሳው
በሰማያት የከበረው ሊቀ ካህን
የመንግስትን ዘውድ ይጭናል ሲመጣልን

3. ሰማያዊ መቅደስ በጧፍ ይሞላና
የማማለድ የፍርድ ሥራ ያበቃና
ተፈፀመ የሚለው ድምፅ ይነገራል
የነገስታት ንጉስ የሱስ ይገለጣል

4. ካመንበት ጊዜ ይልቅ ይኸው ዛሬ
መዳናችን እጅግ ቀርቧል እኛም ልንነግስ
በሰማያት የከበረው ሊቀ-ካህን
የመንግስትን ዘውድ ይጭናል ሲመጣልን
',
  'hagerigna',
  102,
  '{"artist":"የጅማ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-103'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-104',
  'am',
  'በሥጋ አይን ለሚያዩኝ',
  null,
  'በሥጋ-አይን-ለሚያዩኝ',
  'Imported from Hagerigna row 104.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  104,
  'በሥጋ አይን ለሚያዩኝ',
  null,
  'በሥጋ አይን ለሚያዩኝ ምስኪን እመስላለሁ
ብር ወርቅ እንደሌለኝም አውቃለሁ
ግን ከእኔ ጋር ያለው ከሁሉም ይበልጣል
ሁሉን ያሸንፋል /2X/

1.  ከሩቁ ለሚያዩኝ አካሄዴ
በብልፅግና ያለማደጌ
ምናልባት ምስኪን ሰው እመስላለሁ
ግን እንደኔ ማነው ንብረት ያለው

-- በሥጋ አይን ለሚያዩኝ --

2. ብር ወርቅ እንደሌለኝም አውቃለሁ
ምስኪን ድሐም ነኝ ይህን አምናለሁ
ነገር ግን በፀጋው ራሴን ሳየው
ከሁሉም ይበልጣል በኔ ያለው

-- በሥጋ አይን ለሚያዩኝ --

3. ስራቆት ልብሴ ነው ስታመምም ፈዋሽ
ኃይሌ ጉልበቴም ነው የእንባዬ አባሽ
ታዲያ ምን ጎደለኝ ጌታ የሱስ ካለኝ
ገንዘብ ባይኖረኝም እጅግ ሐብታም ሰው ነኝ

-- በሥጋ አይን ለሚያዩኝ --

4. እየሱስ ያላችሁ ሁሉም ነገር አላችሁ
ገንዘብን በመውደድ ያልተነደፋችሁ
በችግር መስቀሉን የተሸከማችሁ
ትከሻችሁ ይስፋ ፀጋውን ያብዛላችሁ

-- በሥጋ አይን ለሚያዩኝ --
',
  'hagerigna',
  103,
  '{"artist":"ዘማሪ ኢያሱ ረጋሳ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-104'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-105',
  'am',
  'ወቅታዊ መልዕክትን',
  null,
  'ወቅታዊ-መልዕክትን',
  'Imported from Hagerigna row 105.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  105,
  'ወቅታዊ መልዕክትን',
  null,
  'ወቅታዊ መልዕክትን ስበኩ ብለሃል\t
ለኛ ለደካሞች እውነትን ሰጥተሃል
እኛስ ተቀብለን በእምነት ተናግረናል
ወይስ አጉረምርመን ይዘን ተኝተናል

1. ኧረ አትመቻቹ ወገኖች ተነሱ
ወንጌልን እናብራ የተኙት ይነሱ
ሐገር ከዚህ የለም ሐገራችን ላይ ናት
ወንጌልን እናዳርስ ወደዚያች ለመግባት

-- ወቅታዊ መልዕክትን --

2. ዓለም መጥፋቷ ነው በርኩሰት በኃጢያት
ወንድሞች ተነሱ ነፍሳትን ለመጥራት
ለእኛ የተሰጠንን ይህን ታላቅ መልዕክት
እንናገር ዛሬ እውነት ላላወቁት

-- ወቅታዊ መልዕክትን --

3. ሰይጣን በሽፍንፍን ስራውን ይሰራል
የበግ ለምድ ለብሶ ያታልላቸዋል
አንዳንዴም ጌታ ነኝ እያለ ይመጣል
ሕዝቦች አላወቁም ያስተናግዱታል

-- ወቅታዊ መልዕክትን --

4. ይህ ሥራ የማነው ብለን አንጠይቅ
ሥራ ሁሉ የኛ ነው ወገብ እንታጠቅ
አምላክን እንየው ከወደፊታችን
ፀንተን እንከተል ድል እንነሳለን

-- ወቅታዊ መልዕክትን --
',
  'hagerigna',
  104,
  '{"artist":"የሌስፔራንስ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-105'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-106',
  'am',
  'ይህ ቤት',
  null,
  'ይህ-ቤት',
  'Imported from Hagerigna row 106.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  106,
  'ይህ ቤት',
  null,
  'ይህ ቤት የእግዚያብሔር ነው/2X/
በረከት ይብዛላ ችሁ/ /2X/
ጌታ ምላሽ ይስጣችሁ

1. በሐዘንሽ ብዛት መፅናናት ያቃጠሽ
እርዳታን ፈልገሽ ሚረዳሽን ያጣሽ
ወደ አምላክሽ ቅረቢ እርሱ ይረዳሻል
ከሐዘንሽ ፈጥኖ ጌታ ያወጣሻል

-- ይህ ቤት --

2. ወገንና ዘመድ ሁሉ የረሳህ
አለኝ የምትለው ሁሉ የራቀህ
ከዘመድ የሚበልጥ እየሱስ ጌታ ነው
ብቸኛ ስትሆን ሁሌ ሚያፅናናህ ነው

-- ይህ ቤት --

3.የዓለምን ሥራ ሁሉንም አይተናል
ምንም አይጠቅመንም የሱስ ያዋጣናል
ዛሬ የምናየው ሁሉ ኃላፊ ነው
በአምላካችን ቤት መኖሩ መልካም ነው

-- ይህ ቤት --
',
  'hagerigna',
  105,
  '{"artist":"የናዝሬት ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-106'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-107',
  'am',
  'ዋጋ ያለው ነው',
  null,
  'ዋጋ-ያለው-ነው',
  'Imported from Hagerigna row 107.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  107,
  'ዋጋ ያለው ነው',
  null,
  'ዋጋ ያለው ነው ድካማችን
በምድር ያለው ልፋታ ችን
እንበርታ ወደፊት እንሂድ
እንድንደርስ ወደ ፂዮን ሃገር

 1. ጠባብ ሆኖ መንገዱ ቢያስቸግር
አብሮን አለ ባህር የሚያሻግር
መሪ መለያችን መስቀሉ ነው
ፍቅሩ በዝቶ ነው እጅ የሰጠነው

-- ዋጋ ያለው ነው --

2. ተስፋ አንቆርጥም እንገሰግሳለን
ወደፊት ነው የኛ መመሪያችን
አንዞርም የኋላውን ረስተናል
ግባችንን ለመምታት ጓግተናል

-- ዋጋ ያለው ነው --

3. ሞት አንፍራ ከቶ አናቅማማ
ሲመጣልን ትንሣኤ አለንና
የድሉ ባለቤት አምላካችን
ያሸንፋል በመሪነት ውጊያውን

-- ዋጋ ያለው ነው --

4. ስጦታ አለን ለእያንዳንዳችን
አትርፉበት ተብሎ የተሰጠን
እንስራበት ወስደን አንቅበረው
ሲመጣልን ዋጋችን ታላቅ ነው

-- ዋጋ ያለው ነው --
',
  'hagerigna',
  106,
  '{"artist":"የሌስፔራንስ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-107'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-108',
  'am',
  'መፈጠሬን ሳስብ',
  null,
  'መፈጠሬን-ሳስብ',
  'Imported from Hagerigna row 108.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  108,
  'መፈጠሬን ሳስብ',
  null,
  '1. ነበርኩኝ ኑሮዬ የታከተኝ
ብዬ ብዬ የሰለቸኝ
ለመግፋት ያቃተኝ እድሜዬን
እንደ ውሃ ሚጠማኝ ሰላምን

አ   መፈጠሬን ሳስብ ሳለሁ
ዝ   እጅግ በጣም እደነቃለሁ
ማ   እጅግ በጣም ይወደኛል ጌታዬ
ች   ለኔ ሲል የሞተው አምባዬ

2. በዚች ዓለም ኑሮዬ ውስጥ
ጌታ የልቤን ሳይለውጥ
ነበርኩኝ ምሻ ልሆን ገናና
ለሚያልፈው ምድር ገና ለገና

3. ለኃጢያት ቢባል አንደኛ ነበርኩ
ለጥፋት ተንኮል ወደር የሌለኝ
ከመልካም ሥራ እጅ የታገደው
ቢባል ሰው ነበርኩኝ አንደኛው

4. በዚህ ዓይነት የዓለም ኑሮዬ
አልተወኝም ውዱ ጌታዬ
መረጠኝ ለእርሱ ልጁ ሊያደርገኝ
ከእርሱ ጋር ዘላለም ሊያኖረኝ
',
  'hagerigna',
  107,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-108'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-109',
  'am',
  'ከጌታ ድምፁን ሰምቻለሁ',
  null,
  'ከጌታ-ድምፁን-ሰምቻለሁ',
  'Imported from Hagerigna row 109.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  109,
  'ከጌታ ድምፁን ሰምቻለሁ',
  null,
  'አ   ከጌታ ድምፁን ሰምቻለሁ
ዝ   የክብር ልጄ ተብያለሁ
ማ   በሰጠኝ ተስፋ ተደስቼ
ች   አለሁኝ እርካታን አግኝቼ

1. በዙሪያዬ ላለው ለጠላት ድንፋታ
እኔ አልሰጥም ልቤን ፍፁም ለአንዳፍታ
አይኖቼን አንስቼ ወደ ጌታ እያየሁ
ፍፃሜ ላይ ልደርስ እገሰግሳለሁ

2. ልቀበል ያለውን የከበረ ተስፋ
ሳላስተውል እኔ በከንቱ እንዳልጠፋ
ጠላት ተግቶ ቢጥር ከዚያ ሊያስቀረኝ
አውቃለሁ አምላኬ እንደማይተወኝ

3. ዛሬ ታይቶ ነገ በኖ ለሚጠፋ
ሰው በሞኝነቱ ቀን ከሌት ሲለፋ
እኔ ግን ሳልደክም የነፃ ሥጦታ
ተቀብያለሁኝ ከሰማዩ ጌታ

4. ግራ ቀኝ አይቼ ወደ ኋላ እንዳልሄድ
እኔ ነኝ ብሎኛል እውነተኛው መንገድ
ጨለማዬን ገፎ ብርሃንን ላሳየኝ
ለዘላለም ጌታ እገዛለሁኝ
',
  'hagerigna',
  108,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-109'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-110',
  'am',
  'የበጉን መዝሙር',
  null,
  'የበጉን-መዝሙር',
  'Imported from Hagerigna row 110.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  110,
  'የበጉን መዝሙር',
  null,
  'የበጉን መዝሙር በደስታ እየዘመርን
አዲስ ቅኔ እየተቀኘን ላምላካችን
የድል ዘንባባን ይዘን ባንድ ላይ
ታላቅ ደስታ ይሆናል በሰማይ

1. እኛ የሰራነው ምድራዊ ጎጇችን
ድንኳን የሆነው ጊዜያዊ ቤታችን
ይፈርሳል አንድ ቀን ፍፃሜ ሲመጣ
ይለወጣል ሁሉም የሱስ አንተ ስትመጣ

-- የበጉን መዝሙር --

2. አምላክ ለልጆቹ ቦታን አዘጋጅቷል
ባሪያ ጨዋ ሳይል ሁላችን ሊያኖረን
የተናቅን ሳለን ከፍ ከፍ ሊያደርገን
ፀጋው በዝቶልናል ክበር ጌታ እንላለን

-- የበጉን መዝሙር --

3. ዛሬ የምናየው በስባሹ ስጋችን
በትንሣኤ ጠዋት አንተ ስትጠራን
የማይሞት ይሆናል የሚኖር ዘላለም
ረኃብ ርዛትም ቢሆን ከዚያ የለም

-- የበጉን መዝሙር --

4. ባዲሲቷ ምድር በውቧ ኤደን ገነት
ቸሩ አባታችን ስናይህ ፊት ለፊት
አንበሳና በሬ ባንድ ላይ ይሰማራሉ
ዛሬ ጠላት ናቸው ያኔ ይስማማሉ

-- የበጉን መዝሙር --
',
  'hagerigna',
  109,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-110'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-111',
  'am',
  'ከመልካም ስምና ዝና',
  null,
  'ከመልካም-ስምና-ዝና',
  'Imported from Hagerigna row 111.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  111,
  'ከመልካም ስምና ዝና',
  null,
  'ከመልካም ስምና ዝና 
በኃጢያት ከሚገኝ
ይሻላል ከእግዚአብሔር ሕዝብ ጋር 
መከራን መቀበል

1.  እኔም እንደ ሙሴ መልካሙን ምርጫ ልምረጥ
ብድራቴን አተኩሬ ባሻገር ልመልከት
በዓለም ያለውን ክብር ደስታ ትቼ
ጌታዬ ልመልከት ተስፋህን በእምነት ተሞልቼ

-- ከመልካም ስምና ዝና --

2. ከእግዚአብሔር ሕዝብ ጋር መኖር ይሻለኛል
ከፈርዖን ጮማ ይልቅ መና ይጥመኛል
የዚህ ዓለም ኑሮ ጣዕም የሌለው ነው
ስለዚህ ጌታዬ ምርጫዬን ካሁኑ አድሰው

-- ከመልካም ስምና ዝና --

3. እንደ ጥንት አባቶች ባንተ እንዳለፉት
እኔም አንተን አስከብሬ ማለፍ ስለምፈልግ
እንደ ሙሴ ቀባኝ እኔንም አስነሳኝ
ለአንተ የታመንሁ እንድሆን ካሁኑ አድሰኝ

-- ከመልካም ስምና ዝና --

4. ሊጠፋ ያለውን ከንቱ ደስታ ትቼ
መልካሙን የሕይወትን ጉዞ ለመጓዝ ተግቼ
እንድደርስ እሻለሁ ከዘላለም ቤቴ
እባክህ ይህንን አግዘኝ አባቴ

-- ከመልካም ስምና ዝና --
',
  'hagerigna',
  110,
  '{"artist":"የቀበና ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-111'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-112',
  'am',
  'በፍቅር አይኑ',
  null,
  'በፍቅር-አይኑ',
  'Imported from Hagerigna row 112.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  112,
  'በፍቅር አይኑ',
  null,
  '1. በሞት ትቀጣ ትወገር ብለው    
የሱስ ጋር መጡ አንዲት ሴት ይዘው
ዙሪያዋን ከበው ክስ አቀረቡ
ኃጢያት ሰርታለች ማርያም እያሉ

በፍቅር አይኑ ተመለከታት
ፍቅር አይጨክን ልቡ እራራላት
ምህረት የእርሱ ሱ ነው ምህረት ይወዳል
መች እንደ ሰው ነው ጊዜ ይሰጣል

2. በንቀት ቢያይዋት አልደነቃትም
ወሬ ሽምጥጫው አላስፈራትም
ስለርሷ ኃጢያት ቢያወሩ ሰዎች
አንገቷን ደፍታ ወደ ውስጥ ገባች

-- በፍቅር አይኑ --

3. ዕድሜ ዘመኗን የለፋችበትን
ለየሱስ ልትሰጥ አልሰሰተችም
ውድ የሆነውን ሽቶ ገዝታለች
ከሞት ላዳናት ይሁን ብላለች

-- በፍቅር አይኑ --

4. ለልቧ ወዳጅ ሽቶ አፈሰሰች
በአይኖቿ እምባ እግሩን አራሰች
ክብሯ ፀጉሯ ነው አዋረደችው
ፍቅሯን ለመግለፅ ከእግሩ ጣለችው

-- በፍቅር አይኑ --
',
  'hagerigna',
  111,
  '{"artist":"ዘማሪ መታደል ሞላ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-112'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-113',
  'am',
  'አስጨናቂው ዘመን',
  null,
  'አስጨናቂው-ዘመን',
  'Imported from Hagerigna row 113.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  113,
  'አስጨናቂው ዘመን',
  null,
  'አስጨናቂው ዘመን ቀርቧልና
የጌታችን መምጫው ደርሷልና
የመዘጋጀት ጊዜ ነውና/ / 4X/

1. ጊዜው አልቆ እኛ ተኝተናል
የወንጌልን ጉዳይ ዘንግተናል
ንቁ እያለ ጌታ ይጠራናል
ወዮ ለኛ በዘመን ፍፃሜ ቸል ብለናል

-- አስጨናቂው ዘመን --

2. በለብታ መኖር አያሻንም
እንዲሁ መመላለስ አይጠቅመንም
ሳንተፍ ከአፉ ጊዜው ሳይደርስ
ንቁዎች ሆነን ወደ ጌታ ቶሎ እንመለስ

-- አስጨናቂው ዘመን --

3. ፍቅር ይኑረን በህይወታችን
ዲያቢሎስ ብቻ ነው ጠላታችን
ያለ ፍቅር ሁሉ ከንቱ ነው
ጌታን ማመን ትርጉም የሚሰጠው በፍቅር ነው

-- አስጨናቂው ዘመን --
',
  'hagerigna',
  112,
  '{"artist":"የሻሸመኔ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-113'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-114',
  'am',
  'ሰማይ ነው ሐገራችን',
  null,
  'ሰማይ-ነው-ሐገራችን',
  'Imported from Hagerigna row 114.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  114,
  'ሰማይ ነው ሐገራችን',
  null,
  '1. ጣጣው ቢበዛ ይህ ዓለም\t
ለጌታ ልጆች አይገርምም
ጊዜያዊ ድንኳን ነውና
መፍረሱ አይቀርምና

አ   ሰማይ ነው ሐገራችን
ዝ   ይመጣል ንጉሳችን ይመጣል
ማ   እንጠብቃለን በተስፋ
ች   ዘመኑም እንኳን ቢከፋ /2X/

2. የሚደርስብን መከራ
ቢሆንም ግዙፍ ተራራ
ከክብሩ ጋር ሲነፃፀር
አይገባም ፍፁም ከቁጥር

3. የምድር ኑሮ ቢያስከፋም
የምንጓዘው በተስፋ
በማፅናናቱ ደስ ይለናል
በየሱስ ልባችን አርፏል

4. የተስፋ ቃሉን አያጥፍም
ንጉሱ የሱስ አይቀርም
በቅርብ ይመጣል ሊወስደን
ሰማይ ቤት እንሄዳለን

5. ሁላችን ዛሬ እንበርታ
ተግተን ለመስራት ለጌታ
እናትርፍ ሰውን በሙሉ
በቂ ነው ሰማይ ለሁሉ
',
  'hagerigna',
  113,
  '{"artist":"የአዲስ አበባ ዲስትሪክት መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-114'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-115',
  'am',
  'በማጣት ይሁን በማግኘት',
  null,
  'በማጣት-ይሁን-በማግኘት',
  'Imported from Hagerigna row 115.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  115,
  'በማጣት ይሁን በማግኘት',
  null,
  '1. በማጣት ይሁን በማግኘት
በሙላት ይሁን በጉድለት
ጌታ በቤትህ መሆኑ
ያዋጣል ባንተ መፅናቱ

በሕይወቴ ዘመን በሙሉ
በቤትህ ብኖር መልካም ነው
አንተን ደስ የሚያሰኘውን ማየቱ ለኔ ሚሻል ነው
ስለዚህ ጌታዬ እማፀንሃለሁ በቤትህ ልኑር እላለሁ

2. በድካም ይሁን በብርታት
ልኑር ጌታዬ ባንተ ቤት
አለዚያማ ሁሉም ከንቱ
አይረባኝም በእውነቱ

-- በሕይወቴ ዘመን በሙሉ --

3. ቢደላኝም ባይደላኝም
ቢኖረኝም ባይኖረኝም
ካንተ ጋር መሆን ሰላም ነው
ለእኔም እጅግ ማትረፊያ ነው

-- በሕይወቴ ዘመን በሙሉ --

4. የሕይወትን መንገድ ለቅቄ
እንዳልሄድ ከፊትህ ርቄ
ዘመኔን አንተው ቀድሰው
ሞቴን ደጃፍህ አድርገው

-- በሕይወቴ ዘመን በሙሉ --

5. በቤትህ እንደተተከልኩ
እንደ ሊባኖስ ዛፍ እያደኩ
እንዳለፉት አባቶቼ
ልለፍ አንተን አስደስቼ

-- በሕይወቴ ዘመን በሙሉ --
',
  'hagerigna',
  114,
  '{"artist":"ዘማሪ ፓ/ር ተስፋዬ ሽብሩ"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-115'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-116',
  'am',
  'ካንተ ወደ ማን እንሄዳለን',
  null,
  'ካንተ-ወደ-ማን-እንሄዳለን',
  'Imported from Hagerigna row 116.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  116,
  'ካንተ ወደ ማን እንሄዳለን',
  null,
  'ካንተ ወደ ማን እንሄዳለን ጌታዬ
እንዳንተ ማንን እናገኛለን አንተ ተ ኮ ኮ
የህ ህ ይወት ቃል አለህ የህይወት ውሃ ነህ
የህይወቴም ጌታ ነህ እየሱስ

1. ከወርቅ ከእንቁ ይልቅ ውድ ነህ
ከታላላቆች በላይ ታላቅ ነህ
ከሰዎች ይልቅ ውበትህ ያምራል
ሞገስ ከከንፈሮችህ ይፈሳል እየሱስ

-- ካንተ ወደ ማን --

2. ሰማይ ብወጣ አንተ በዚያ ነህ
ምድር ብወርድም ደግሞ በዚያ ነህ
ከመንፈስህ ወዴት እሸሻለሁ
ጌታ ከፊትህ ወደ ማን እሔዳለሁ እየሱስ

-- ካንተ ወደ ማን --

3. ለደካማው ኃይል ታስታጥቃለህ
በከፍታ ላይ ታስኬደዋለህ
እጆቹንም ሰልፍ ታስተምራለህ
ለደህንነቱ መታመኛ ነህ እየሱስ

-- ካንተ ወደ ማን --
',
  'hagerigna',
  115,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-116'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-117',
  'am',
  'ክርስቲያን ሆይ',
  null,
  'ክርስቲያን-ሆይ',
  'Imported from Hagerigna row 117.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  117,
  'ክርስቲያን ሆይ',
  null,
  'ክርስቲያን ሆይ እስከ መቼ ትተኛለህ
ከእንቅልፍህስ መቼ ትነቃለህ
የጌታ መመለስ ቀርቧል በደጅህ
ምን ስንቅ አለህ ያስቀመጥከው ለሕይወትህ

1. መተኛትህን ያየ ጠላት በህይወትህ
ችግርና መከራን ሊያመጣብህ
ሰላም ነስቶ በምድር ላይ ሊያሰቃይህ
መነሳቱን አትዘንጋ እወቅ ተግተህ

-- ክርስቲያን ሆይ --

2. ሳትዘጋጅ ጌታህም እንዳይመጣብህ
ሳትገባ ደጁም እንዳይዘጋብህ
ከበጎቹ ጋር አንተም አብረህ ለመሆን
በጌታ ፊት ፅና በርታ በእምነትህ

-- ክርስቲያን ሆይ --

3. ቢጣጣርም እንኳን ሰይጣን ሊጥለን
ቢዝትብንም ተስፋ ሊያስቆርጠን
በእኛ ዘንድ ያለው እርሱ ከሁሉ ይበልጣል
ድል እንድናደርገው ሙሉ ተስፋውን ሰጥቶናል

-- ክርስቲያን ሆይ --

4. ያ ቀን እንደ ወጥመድ እንዳይደርስባችሁ
በመጠን ኑሩ ሰይጣን እንዳያጠምዳችሁ
ጌታ የሱስ ብሏል ጠብቁ ነቅታችሁ
ሲመጣ በክብሩ እንዲወስዳችሁ

-- ክርስቲያን ሆይ --
',
  'hagerigna',
  116,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-117'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-118',
  'am',
  'እኔ መናኝ',
  null,
  'እኔ-መናኝ',
  'Imported from Hagerigna row 118.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  118,
  'እኔ መናኝ',
  null,
  '1. እኔ መናኝ መፃተኛ ነኝ
ስመላለስ በዚች ዓለም
ግን ከዚያ ላይ ከምሔድበት
ሀዘን ችግር ሁሉ የለም

አ   እሔዳለሁ አባቴን ላየው
ዝ   እሔዳለሁ ልገናኘው
ማ   ዮርዳኖስን እሻገራለሁ
ች   ወደ ቤቴም እገባለሁ

2. መንገዱ እንኳን ቢጨልምብኝ
እንቅፋትም ቢያስቸግረኝ
ጌታ በእጁ ይደግፈኛል
ኃይልም ይጨምርልኛ

3. የወርቅ አክሊል እቀዳጃለሁ
የሚያስፈራኝም አይኖርም
ስለ መዳን እዘምራለሁ
ከዳኑት ጋር ለዘላለም
',
  'hagerigna',
  117,
  '{"artist":"Unknown"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-118'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-119',
  'am',
  'ሰላም ደስታ',
  null,
  'ሰላም-ደስታ',
  'Imported from Hagerigna row 119.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  119,
  'ሰላም ደስታ',
  null,
  '1. በዚያ ከቶ ኃዘን የለም
መርገም ችግርም አይኖርም
በደስታ እየዘለልን
ለዘላለም  እንኖራለን/2X/

አ   ሰላም ደስታ በሰፈነበት
ዝ   ለዘላለም በምን ን ኖርበት
ማ   ከዚያ ቦታ ለመገኘት
ች   እንሁን ለጌታ ታማኞች

2. ኃጢያትን በምድር ትተን
ችግርንም  ሁሉ ረስተን
ክብርን ለጌታ እየሰጠን
በዙፋን ሥር  እንሰግዳለን/2X/

3. በተቀደሰችው ሐገር
አንዳች አንሆን አንቸገር
ከብረን ገነን እንኖራለን
ሞትን ከቶ  እንረሳለን/2X/
',
  'hagerigna',
  118,
  '{"artist":"የሌስፔራንስ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-119'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-120',
  'am',
  'መሞት ሲገባኝ',
  null,
  'መሞት-ሲገባኝ',
  'Imported from Hagerigna row 120.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  120,
  'መሞት ሲገባኝ',
  null,
  '1. መሞት ሲገባኝ እኔ ልጅህ
ልታድነኝ መጣህ በምህረትህ
ምን ዓይነት አምላክ ነህ እሩህሩህ
ፍቅርህ ሁልጊዜ ማያልቅብህ/ /2X/

አ   መልካም እረኛ የኔ ጌታ
ዝ   ከሰማይ ወርደህ ሞትክ በኔ ፈንታ
ማ   በሰጠኝ ፍቅር አስተውዬ
ች   እንዳገለግል እርዳኝ ጌታዬ

2. ለኔ ስትል ወርደህ ከላይ
እኔ ግን ሰቀልኩህ በመስቀል ላይ
አሁንም ቢሆን ሳትሰለቸኝ
ካባትህ ጋር አስታረቅከኝ/2X/

3. ዘመኑ እጅግ አስፈሪ ነው
ያላንተ እርዳታ አስቸጋሪ ነው
በህይወቴ ፈተና አለና
የሰላም አለቃ ቶሎ ና ና/ /2X/

4. የሰው ድካም ለምንድነው
ለፍርድ ወይስ ለፅድቅ ነው
በፍፁም ያለ ኃጢያት ሚቆየው
እርሱ ነው ጌታን ሚገናኘው/2X/
',
  'hagerigna',
  119,
  '{"artist":"የሌስፔራንስ ቤ/ክ መዘምራን"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-120'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();
insert into works (
  canonical_key,
  primary_language_code,
  default_title,
  default_english_title,
  normalized_title,
  notes
)
values (
  'am-hagerigna-121',
  'am',
  'የመዝሙር ርዕስ',
  null,
  'የመዝሙር-ርዕስ',
  'Imported from Hagerigna row 121.'
)
on conflict (canonical_key) do update set
  default_title = coalesce(nullif(works.default_title, ''), excluded.default_title),
  default_english_title = coalesce(works.default_english_title, excluded.default_english_title),
  normalized_title = coalesce(works.normalized_title, excluded.normalized_title),
  updated_at = now();
insert into book_entries (
  edition_id,
  work_id,
  entry_number,
  title,
  english_title,
  lyrics,
  source_key,
  source_index,
  metadata
)
select
  be.id,
  w.id,
  121,
  'የመዝሙር ርዕስ',
  null,
  'መዝሙር 1 መዝሙር 2
መዝሙር 3 መዝሙር 4',
  'hagerigna',
  120,
  '{"artist":"ሙከራ መዝሙር"}'::jsonb
from book_editions be
join works w on w.canonical_key = 'am-hagerigna-121'
where be.slug = 'am-hagerigna-primary'
on conflict (edition_id, source_key, source_index) do update set
  work_id = excluded.work_id,
  entry_number = excluded.entry_number,
  title = excluded.title,
  english_title = excluded.english_title,
  lyrics = excluded.lyrics,
  metadata = excluded.metadata,
  updated_at = now();

commit;
