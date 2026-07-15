import http from 'node:http';

import { PrismaClient } from '@prisma/client';

const port = Number(process.env.PORT ?? 8787);
const host = process.env.HOST ?? '127.0.0.1';

const sdaDatabaseUrl =
  process.env.SDA_HYMNAL_DATABASE_URL ??
  process.env.CONTENT_DATABASE_URL ??
  'postgresql://postgres@localhost:55432/wudase_sda_dev';
const hagerignaDatabaseUrl =
  process.env.HAGERIGNA_DATABASE_URL ??
  'postgresql://postgres@localhost:55432/wudase_hagerigna_dev';

const sdaDb = new PrismaClient({
  datasources: { db: { url: sdaDatabaseUrl } },
});
const hagerignaDb = new PrismaClient({
  datasources: { db: { url: hagerignaDatabaseUrl } },
});

const versions = {
  sdaNew: 'sda_new',
  sdaOld: 'sda_old',
  hagerigna: 'hagerigna',
  legacyHymnal: 'hymnal',
};

const normalizeVersion = (version) => {
  if (version === versions.legacyHymnal || !version) return versions.sdaNew;
  if ([versions.sdaNew, versions.sdaOld, versions.hagerigna].includes(version)) {
    return version;
  }
  return versions.sdaNew;
};

const sdaCategories = [
  ['praise', 'ምስጋና', 1, 24],
  ['worship', 'ስግደት', 25, 42],
  ['awakening', 'መነቃቃት', 43, 44],
  ['repentance', 'ንሥሐ', 45, 58],
  ['prayer', 'ጸሎት', 59, 84],
  ['christian_life', 'የክርስቲያን ኑሮ', 85, 116],
  ['self_sacrifice', 'ራስን ቀድሶ መስጠት', 117, 118],
  ['work', 'ሥራ', 119, 121],
  ['people', 'ሕዝብ', 122, 122],
  ['faithfulness', 'ታማኝነት', 123, 128],
  ['hope', 'ተስፋ', 129, 134],
  ['joy', 'ደስታ', 135, 140],
  ['peace', 'ሰላም', 141, 146],
  ['love', 'ፍቅር', 147, 159],
  ['salvation', 'መድህን', 160, 178],
  ['cross', 'መስቀል', 179, 193],
  ['sabbath', 'ሰንበት', 194, 197],
  ['word_of_god', 'የእግዚአብሔር ቃል', 198, 203],
  ['christian_struggle', 'የክርስቲያን ተጋድሎ', 204, 206],
  ['judgment', 'ፍርድ', 207, 208],
  ['second_coming', 'ዳግም ምፅአት', 209, 220],
  ['heaven', 'የሰማይ ቤት', 221, 241],
  ['youth', 'ወጣቶች', 242, 264],
  ['nature', 'ተፈጥሮ', 265, 266],
  ['children', 'የልጆች መዝሙር', 267, 275],
  ['marriage', 'ጋብቻ', 276, 277],
  ['birth', 'ልደት', 278, 292],
  ['trust', 'መታመን', 293, 310],
  ['offering', 'ቁርባን', 311, 314],
  ['resurrection', 'ትንሣኤ', 315, 320],
  ['funeral', 'መሰናበቻ', 321, 325],
].map(([id, name, startNumber, endNumber], index) => ({
  id,
  name,
  name_amharic: name,
  start_number: startNumber,
  end_number: endNumber,
  sort_order: index + 1,
}));

const getCategoryForNumber = (number) =>
  sdaCategories.find(
    (category) =>
      Number.isFinite(number) &&
      number >= category.start_number &&
      number <= category.end_number,
  ) ?? null;

const sendJson = (response, statusCode, body) => {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, OPTIONS',
    'access-control-allow-headers': 'content-type',
    'cache-control': 'no-store',
  });
  response.end(JSON.stringify(body));
};

const toIntOrNull = (value) =>
  value === null || value === undefined ? null : Number(value);

const downloadableMediaUrls = (values) => {
  if (!Array.isArray(values)) return [];
  return values.filter((value) => {
    if (typeof value !== 'string') return false;
    try {
      const url = new URL(value);
      return url.protocol === 'http:' || url.protocol === 'https:';
    } catch {
      return false;
    }
  });
};

const getSdaHymns = async (version) => {
  const normalizedVersion = normalizeVersion(version);
  const isOld = normalizedVersion === versions.sdaOld;
  const rows = await sdaDb.$queryRaw`
    select
      s.work_id::text as id,
      s.new_hymnal_number,
      s.old_hymnal_number,
      new_e.title as new_hymnal_title,
      old_e.title as old_hymnal_title,
      s.english_title,
      new_e.lyrics as new_hymnal_lyrics,
      old_e.lyrics as old_hymnal_lyrics,
      coalesce(
        jsonb_agg(sm.asset_path order by sm.sort_order, sm.storage_key)
          filter (where sm.asset_path is not null),
        '[]'::jsonb
      ) as sheet_music
    from sda_hymnal_songs s
    left join book_entries new_e on new_e.id = s.new_entry_id
    left join book_entries old_e on old_e.id = s.old_entry_id
    left join sda_hymnal_sheet_music sm on sm.work_id = s.work_id
    group by
      s.work_id,
      s.new_hymnal_number,
      s.old_hymnal_number,
      s.title,
      s.english_title,
      new_e.title,
      old_e.title,
      new_e.lyrics,
      old_e.lyrics
    order by coalesce(s.new_hymnal_number, s.old_hymnal_number);
  `;

  return rows
    .map((row) => {
      const number = toIntOrNull(
        isOld ? row.old_hymnal_number : row.new_hymnal_number,
      );
      const title = isOld
        ? row.old_hymnal_title ?? row.new_hymnal_title ?? ''
        : row.new_hymnal_title ?? row.old_hymnal_title ?? '';
      const lyrics = isOld
        ? row.old_hymnal_lyrics ?? row.new_hymnal_lyrics ?? ''
        : row.new_hymnal_lyrics ?? row.old_hymnal_lyrics ?? '';
      const category = getCategoryForNumber(number);

      if (number === null) {
        return null;
      }

      return {
        id: row.id,
        number,
        version: normalizedVersion,
        title,
        lyrics,
        category: category?.name ?? null,
        category_id: category?.id ?? null,
        audio_url: null,
        audio: null,
        // TODO: Resolve media storage keys through the future media backend.
        // Only already-downloadable URLs are safe to expose to clients today.
        sheet_music: downloadableMediaUrls(row.sheet_music),
        new_hymnal_title: row.new_hymnal_title,
        old_hymnal_title: row.old_hymnal_title,
        new_hymnal_lyrics: row.new_hymnal_lyrics,
        old_hymnal_lyrics: row.old_hymnal_lyrics,
        english_title_old: row.english_title,
        newHymnalTitle: row.new_hymnal_title,
        oldHymnalTitle: row.old_hymnal_title,
        newHymnalLyrics: row.new_hymnal_lyrics,
        oldHymnalLyrics: row.old_hymnal_lyrics,
        englishTitleOld: row.english_title,
        new_hymnal_number: toIntOrNull(row.new_hymnal_number),
        old_hymnal_number: toIntOrNull(row.old_hymnal_number),
        isFavorite: false,
      };
    })
    .filter(Boolean)
    .sort((a, b) => a.number - b.number);
};

const getHagerignaSongs = async () => {
  const rows = await hagerignaDb.$queryRaw`
    select
      e.id::text as id,
      e.entry_number as number,
      e.title,
      e.lyrics,
      e.metadata ->> 'artist' as artist
    from book_entries e
    join book_editions be on be.id = e.edition_id
    where be.slug = 'am-hagerigna-primary'
    order by e.entry_number;
  `;

  return rows.map((row) => ({
    id: row.id,
    number: toIntOrNull(row.number),
    title: row.title,
    lyrics: row.lyrics ?? '',
    song: row.lyrics ?? '',
    artist: row.artist,
    category: null,
    audio_url: null,
    audio: null,
    sheet_music: [],
    isFavorite: false,
  }));
};

const server = http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);

  try {
    if (request.method === 'GET' && url.pathname === '/health') {
      await sdaDb.$queryRaw`select 1`;
      await hagerignaDb.$queryRaw`select 1`;
      sendJson(response, 200, { ok: true });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/hymns') {
      const version = normalizeVersion(url.searchParams.get('version'));
      const data =
        version === versions.hagerigna
          ? await getHagerignaSongs()
          : await getSdaHymns(version);
      sendJson(response, 200, { data });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/categories') {
      const version = normalizeVersion(url.searchParams.get('version'));
      const data = [versions.sdaNew, versions.sdaOld].includes(version)
        ? sdaCategories
        : [];
      sendJson(response, 200, { data });
      return;
    }

    sendJson(response, 404, { error: 'not_found' });
  } catch (error) {
    console.error(error);
    sendJson(response, 500, {
      error: 'internal_server_error',
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, host, () => {
  console.log(`Wudase content API listening on http://${host}:${port}`);
});

const shutdown = async () => {
  server.close();
  await Promise.all([sdaDb.$disconnect(), hagerignaDb.$disconnect()]);
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
