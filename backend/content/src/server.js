import http from 'node:http';
import {
  createHash,
  randomBytes,
  randomUUID,
  timingSafeEqual,
} from 'node:crypto';
import { readFileSync } from 'node:fs';

import { PrismaClient } from '@prisma/client';

import { AdminError } from './admin/domain.js';
import { createCollaborationService } from './admin/collaboration.js';
import { createReleaseService } from './admin/release-service.js';
import { createContentAdminService } from './admin/service.js';

const port = Number(process.env.PORT ?? 8787);
const isProduction = process.env.NODE_ENV === 'production';
const host = process.env.HOST ?? (isProduction ? '0.0.0.0' : '127.0.0.1');

const configuredSdaDatabaseUrl =
  process.env.SDA_HYMNAL_DATABASE_URL ??
  process.env.CONTENT_DATABASE_URL;
const configuredHagerignaDatabaseUrl =
  process.env.HAGERIGNA_DATABASE_URL;
const sdaDatabaseUrl = configuredSdaDatabaseUrl ||
  (isProduction ? '' : 'postgresql://postgres@localhost:55432/wudase_sda_dev');
const hagerignaDatabaseUrl = configuredHagerignaDatabaseUrl ||
  (isProduction
    ? ''
    : 'postgresql://postgres@localhost:55432/wudase_hagerigna_dev');
const adminToken =
  process.env.CONTENT_ADMIN_TOKEN ?? '';
const allowLegacyAdmin =
  process.env.ALLOW_LEGACY_CONTENT_ADMIN === 'true' && Boolean(adminToken);
const publicContentMode =
  process.env.CONTENT_PUBLIC_MODE ?? (isProduction ? 'release' : 'live');
const trustProxy = process.env.CONTENT_TRUST_PROXY === 'true';
const forceHttps =
  process.env.CONTENT_FORCE_HTTPS === undefined
    ? isProduction
    : process.env.CONTENT_FORCE_HTTPS === 'true';
const sessionHours = Number(process.env.CONTENT_SESSION_HOURS ?? 12);
if (isProduction && (!sdaDatabaseUrl || !hagerignaDatabaseUrl)) {
  throw new Error(
    'SDA_HYMNAL_DATABASE_URL and HAGERIGNA_DATABASE_URL are required in production.',
  );
}
if (isProduction && allowLegacyAdmin) {
  throw new Error('Legacy shared-token administration is forbidden in production.');
}
if (!Number.isFinite(sessionHours) || sessionHours < 1 || sessionHours > 168) {
  throw new Error('CONTENT_SESSION_HOURS must be between 1 and 168.');
}
if (!['live', 'release'].includes(publicContentMode)) {
  throw new Error('CONTENT_PUBLIC_MODE must be either "live" or "release".');
}

const sdaDb = new PrismaClient({
  datasources: { db: { url: sdaDatabaseUrl } },
});
const hagerignaDb = new PrismaClient({
  datasources: { db: { url: hagerignaDatabaseUrl } },
});
const contentAdmin = createContentAdminService({ sdaDb, hagerignaDb });
const collaboration = createCollaborationService({
  controlDb: sdaDb,
  legacyAdminToken: adminToken,
  allowLegacyAdmin,
  sessionHours,
  categoryForEntry: (catalog, entry) =>
    catalog === 'sda'
      ? getCategoryForNumber(Number(entry.entryNumber))?.id ?? null
      : null,
  validateAssignmentScope: async (assignment) => {
    if (assignment.categorySlug) {
      const category = sdaCategories.find(
        (candidate) => candidate.id === assignment.categorySlug,
      );
      if (
        assignment.catalog !== 'sda' ||
        !category
      ) {
        throw new AdminError(
          400,
          'invalid_assignment_category',
          'Choose a valid SDA category, or leave the category empty.',
        );
      }
      const rangeStart = assignment.startNumber ?? category.start_number;
      const rangeEnd = assignment.endNumber ?? category.end_number;
      if (
        rangeEnd < category.start_number ||
        rangeStart > category.end_number
      ) {
        throw new AdminError(
          400,
          'assignment_scope_empty',
          'The number range must overlap the selected category.',
        );
      }
    }
    if (!assignment.versionKey) return;
    const db = assignment.catalog === 'sda' ? sdaDb : hagerignaDb;
    const bookSlug =
      assignment.catalog === 'sda' ? 'am-sda-hymnal' : 'am-hagerigna';
    const edition = await db.bookEdition.findFirst({
      where: {
        versionKey: assignment.versionKey,
        book: { slug: bookSlug },
      },
      select: { id: true },
    });
    if (!edition) {
      throw new AdminError(
        400,
        'invalid_assignment_version',
        'Choose a hymnal version that belongs to the selected catalog.',
      );
    }
  },
});

const adminFiles = {
  html: readFileSync(new URL('./admin/index.html', import.meta.url)),
  css: readFileSync(
    new URL('./admin/content-studio.css', import.meta.url),
  ),
  javascript: readFileSync(
    new URL('./admin/content-studio.js', import.meta.url),
  ),
  reviewHtml: readFileSync(
    new URL('./admin/review-console.html', import.meta.url),
  ),
  reviewCss: readFileSync(
    new URL('./admin/review-console.css', import.meta.url),
  ),
  reviewJavascript: readFileSync(
    new URL('./admin/review-console.js', import.meta.url),
  ),
  font: readFileSync(
    new URL('../../../assets/fonts/NotoSansEthiopic-Regular.ttf', import.meta.url),
  ),
};

const versions = {
  sdaNew: 'sda_new',
  sdaOld: 'sda_old',
  sda1960: 'sda_1960',
  hagerigna: 'hagerigna',
  legacyHymnal: 'hymnal',
};

const normalizeVersion = (version) => {
  if (version === versions.legacyHymnal || !version) return versions.sdaNew;
  return String(version).trim();
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

const jsonReplacer = (_key, value) =>
  typeof value === 'bigint' ? value.toString() : value;

const securityHeaders = () => ({
  'x-content-type-options': 'nosniff',
  'x-frame-options': 'DENY',
  'x-permitted-cross-domain-policies': 'none',
  'cross-origin-opener-policy': 'same-origin',
  'referrer-policy': 'no-referrer',
  'permissions-policy': 'camera=(), microphone=(), geolocation=()',
  ...(isProduction
    ? { 'strict-transport-security': 'max-age=31536000; includeSubDomains' }
    : {}),
});

const commonHeaders = {
  ...securityHeaders(),
  'access-control-allow-methods': 'GET, POST, PATCH, DELETE, OPTIONS',
  'access-control-allow-headers':
    'content-type, authorization, x-admin-token, x-admin-name, x-wudase-csrf',
  'cache-control': 'no-store',
};

const allowedOrigins = new Set(
  String(process.env.CONTENT_ALLOWED_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
);

const corsHeaders = (request) => {
  const origin = firstHeader(request.headers.origin);
  if (!origin) return {};
  const isPublicRead =
    request.method === 'GET' &&
    ['/api/hymns', '/api/versions', '/api/categories', '/health'].some(
      (path) => (request.url ?? '').startsWith(path),
    );
  if (isPublicRead) return { 'access-control-allow-origin': '*' };
  if (allowedOrigins.has(origin)) {
    return {
      'access-control-allow-origin': origin,
      'access-control-allow-credentials': 'true',
      vary: 'Origin',
    };
  }
  return {};
};

const requestOrigin = (request) => {
  const forwardedProtocol = trustProxy
    ? firstHeader(request.headers['x-forwarded-proto'])?.split(',')[0].trim()
    : null;
  const forwardedHost = trustProxy
    ? firstHeader(request.headers['x-forwarded-host'])?.split(',')[0].trim()
    : null;
  const protocol =
    forwardedProtocol || (request.socket.encrypted ? 'https' : 'http');
  const host = forwardedHost || firstHeader(request.headers.host);
  return host ? `${protocol}://${host}` : null;
};

const isAdminOriginAllowed = (request) => {
  const origin = firstHeader(request.headers.origin);
  return (
    !origin ||
    origin === requestOrigin(request) ||
    allowedOrigins.has(origin)
  );
};

const requestIsHttps = (request) => {
  if (request.socket.encrypted) return true;
  if (!trustProxy) return false;
  return firstHeader(request.headers['x-forwarded-proto'])
    ?.split(',')[0]
    .trim()
    .toLowerCase() === 'https';
};

const sendJson = (
  response,
  statusCode,
  body,
  request = null,
  extraHeaders = {},
) => {
  const sourceRequest = request ?? response.req;
  response.writeHead(statusCode, {
    ...commonHeaders,
    ...(sourceRequest ? corsHeaders(sourceRequest) : {}),
    'content-type': 'application/json; charset=utf-8',
    ...extraHeaders,
  });
  response.end(JSON.stringify(body, jsonReplacer));
};

const sendFile = (response, statusCode, body, contentType, extra = {}) => {
  response.writeHead(statusCode, {
    ...securityHeaders(),
    'content-type': contentType,
    'cache-control': 'no-store',
    ...extra,
  });
  response.end(body);
};

const sendAdminPage = (response) =>
  sendFile(
    response,
    200,
    adminFiles.html,
    'text/html; charset=utf-8',
    {
      'content-security-policy':
        `default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'${isProduction ? '; upgrade-insecure-requests' : ''}`,
      'referrer-policy': 'no-referrer',
      'cross-origin-resource-policy': 'same-origin',
    },
  );

const readJson = async (request, maxBytes = 2 * 1024 * 1024) => {
  const contentType = String(firstHeader(request.headers['content-type']) ?? '')
    .split(';')[0]
    .trim()
    .toLowerCase();
  if (contentType !== 'application/json') {
    throw new AdminError(
      415,
      'unsupported_media_type',
      'Send an application/json request body.',
    );
  }
  if (
    request.headers['content-encoding'] &&
    firstHeader(request.headers['content-encoding']) !== 'identity'
  ) {
    throw new AdminError(
      415,
      'unsupported_content_encoding',
      'Compressed request bodies are not accepted.',
    );
  }
  const declaredLength = Number(firstHeader(request.headers['content-length']));
  if (Number.isFinite(declaredLength) && declaredLength > maxBytes) {
    throw new AdminError(
      413,
      'request_too_large',
      'The request is larger than 2 MB.',
    );
  }
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxBytes) {
      throw new AdminError(
        413,
        'request_too_large',
        'The request is larger than 2 MB.',
      );
    }
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  try {
    const body = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    if (!body || typeof body !== 'object' || Array.isArray(body)) {
      throw new AdminError(
        400,
        'invalid_json',
        'The request body must be a JSON object.',
      );
    }
    return body;
  } catch {
    throw new AdminError(
      400,
      'invalid_json',
      'The request body is not valid JSON.',
    );
  }
};

const firstHeader = (header) =>
  Array.isArray(header) ? header[0] : header;

const sessionCookieName = isProduction
  ? '__Host-wudase_content_session'
  : 'wudase_content_session';
const csrfCookieName = isProduction
  ? '__Host-wudase_content_csrf'
  : 'wudase_content_csrf';

const parseCookies = (request) => {
  const result = {};
  for (const part of String(firstHeader(request.headers.cookie) ?? '').split(';')) {
    const separator = part.indexOf('=');
    if (separator < 1) continue;
    const name = part.slice(0, separator).trim();
    const value = part.slice(separator + 1).trim();
    try {
      result[name] = decodeURIComponent(value);
    } catch {
      result[name] = value;
    }
  }
  return result;
};

const cookieHeader = (name, value, { httpOnly = false, maxAge = 0 } = {}) =>
  [
    `${name}=${encodeURIComponent(value)}`,
    'Path=/',
    `Max-Age=${Math.max(0, Math.floor(maxAge))}`,
    'SameSite=Strict',
    ...(httpOnly ? ['HttpOnly'] : []),
    ...(isProduction ? ['Secure'] : []),
  ].join('; ');

const clearSessionCookies = () => [
  cookieHeader(sessionCookieName, '', { httpOnly: true }),
  cookieHeader(csrfCookieName, ''),
];

const browserSessionResponse = (request) =>
  Boolean(
    firstHeader(request.headers.origin) ||
      firstHeader(request.headers['sec-fetch-site']),
  );

const secureTextEquals = (left, right) => {
  if (!left || !right) return false;
  const leftDigest = createHash('sha256').update(String(left)).digest();
  const rightDigest = createHash('sha256').update(String(right)).digest();
  return timingSafeEqual(leftDigest, rightDigest);
};

const assertAdminCsrf = (request) => {
  if (['GET', 'HEAD', 'OPTIONS'].includes(request.method ?? '')) return;
  const bearer = firstHeader(request.headers.authorization)?.replace(
    /^Bearer\s+/i,
    '',
  );
  const headerToken = firstHeader(request.headers['x-admin-token']);
  const cookies = parseCookies(request);
  if (!cookies[sessionCookieName] || bearer || headerToken) return;
  if (
    !secureTextEquals(
      firstHeader(request.headers['x-wudase-csrf']),
      cookies[csrfCookieName],
    )
  ) {
    throw new AdminError(
      403,
      'csrf_validation_failed',
      'Reload Content Studio and try again.',
    );
  }
};

const requestToken = (request) => {
  const bearer = firstHeader(request.headers.authorization)?.replace(
    /^Bearer\s+/i,
    '',
  );
  const headerToken = firstHeader(request.headers['x-admin-token']);
  return bearer || headerToken || parseCookies(request)[sessionCookieName] || '';
};

const legacyActorName = (request) =>
  String(firstHeader(request.headers['x-admin-name']) ?? 'content-admin')
    .trim()
    .slice(0, 120);

const clientIp = (request) => {
  const forwarded = trustProxy
    ? firstHeader(request.headers['x-forwarded-for'])
    : null;
  return String(forwarded?.split(',')[0] ?? request.socket.remoteAddress ?? '')
    .trim()
    .slice(0, 100);
};

const loginAttempts = new Map();
const loginWindowMs = 15 * 60 * 1000;
let lastLoginAttemptPrune = 0;
const consumeLoginAttempt = (key, limit, now) => {
  const existing = loginAttempts.get(key);
  if (!existing || now - existing.startedAt > loginWindowMs) {
    loginAttempts.set(key, { startedAt: now, attempts: 1 });
    return;
  }
  if (existing.attempts >= limit) {
    throw new AdminError(
      429,
      'too_many_login_attempts',
      'Too many sign-in attempts. Try again in 15 minutes.',
      { retryAfterSeconds: Math.ceil((loginWindowMs - (now - existing.startedAt)) / 1000) },
    );
  }
  existing.attempts += 1;
};

const enforceLoginRateLimit = (request, email) => {
  const now = Date.now();
  if (now - lastLoginAttemptPrune > loginWindowMs) {
    for (const [key, attempt] of loginAttempts) {
      if (now - attempt.startedAt > loginWindowMs) loginAttempts.delete(key);
    }
    lastLoginAttemptPrune = now;
  }
  const ip = clientIp(request);
  const identity = String(email ?? '').trim().toLowerCase().slice(0, 254);
  consumeLoginAttempt(`ip:${ip}`, 24, now);
  consumeLoginAttempt(`identity:${ip}:${identity}`, 8, now);
};

const clearLoginRateLimit = (request, email) => {
  loginAttempts.delete(`ip:${clientIp(request)}`);
  loginAttempts.delete(
    `identity:${clientIp(request)}:${String(email ?? '')
      .trim()
      .toLowerCase()
      .slice(0, 254)}`,
  );
};

const mediaUrl = (asset) => {
  if (!asset?.publicUrl) return null;
  try {
    const url = new URL(asset.publicUrl);
    const allowed = isProduction
      ? url.protocol === 'https:'
      : ['http:', 'https:'].includes(url.protocol);
    return allowed ? url.toString() : null;
  } catch {
    return null;
  }
};

const publicMedia = (work) => {
  const links = [...(work.mediaLinks ?? [])].sort(
    (left, right) =>
      left.sortOrder - right.sortOrder ||
      left.createdAt.getTime() - right.createdAt.getTime(),
  );
  const sheetMusic = [];
  const seenSheetMusic = new Set();
  let audio = null;
  let hasPrimaryAudio = false;

  for (const link of links) {
    const url = mediaUrl(link.mediaAsset);
    if (!url) continue;
    if (
      link.mediaAsset.mediaType === 'sheet_music' &&
      !seenSheetMusic.has(url)
    ) {
      sheetMusic.push(url);
      seenSheetMusic.add(url);
    }
    if (
      link.mediaAsset.mediaType === 'audio' &&
      (!audio ||
        (link.relationType === 'primary_audio' && !hasPrimaryAudio))
    ) {
      audio = url;
      hasPrimaryAudio = link.relationType === 'primary_audio';
    }
  }
  return { audio, sheetMusic };
};

const publicWorkInclude = (bookSlug) => ({
  entries: {
    where: {
      edition: { book: { slug: bookSlug } },
      isActive: true,
    },
    include: { edition: true },
  },
  mediaLinks: {
    include: { mediaAsset: true },
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
  },
});

const getSdaHymns = async (version, excludedWorkIds = new Set()) => {
  const normalizedVersion = normalizeVersion(version);
  const selectedEdition = await sdaDb.bookEdition.findFirst({
    where: {
      versionKey: normalizedVersion,
      book: { slug: 'am-sda-hymnal' },
      isActive: true,
      status: 'published',
    },
  });
  if (!selectedEdition) {
    throw new AdminError(
      400,
      'invalid_version',
      `SDA hymnal version "${normalizedVersion}" is not available.`,
    );
  }
  const rows = await sdaDb.bookEntry.findMany({
    where: {
      editionId: selectedEdition.id,
      isActive: true,
    },
    include: {
      work: {
        include: publicWorkInclude('am-sda-hymnal'),
      },
    },
    orderBy: { entryNumber: 'asc' },
  });

  return rows
    .filter((selectedEntry) => !excludedWorkIds.has(selectedEntry.workId))
    .map((selectedEntry) => {
    const work = selectedEntry.work;
    const newEntry = work.entries.find(
      (entry) => entry.edition.versionKey === versions.sdaNew,
    );
    const oldEntry = work.entries.find(
      (entry) => entry.edition.versionKey === versions.sdaOld,
    );
    const category = getCategoryForNumber(selectedEntry.entryNumber);
    const media = publicMedia(work);
    const englishTitle =
      selectedEntry.englishTitle ??
      newEntry?.englishTitle ??
      oldEntry?.englishTitle ??
      work.defaultEnglishTitle;
    const effectiveTitle = selectedEntry.title ?? work.defaultTitle;
    const effectiveLyrics =
      selectedEntry.lyrics ?? work.canonicalLyrics ?? '';

      return {
        id: work.id,
        number: selectedEntry.entryNumber,
        version: normalizedVersion,
        title: effectiveTitle,
        lyrics: effectiveLyrics,
        category: category?.name ?? null,
        category_id: category?.id ?? null,
        audio_url: media.audio,
        audio: media.audio,
        sheet_music: media.sheetMusic,
        new_hymnal_title: newEntry
          ? newEntry.title ?? work.defaultTitle
          : null,
        old_hymnal_title: oldEntry
          ? oldEntry.title ?? work.defaultTitle
          : null,
        new_hymnal_lyrics: newEntry
          ? newEntry.lyrics ?? work.canonicalLyrics
          : null,
        old_hymnal_lyrics: oldEntry
          ? oldEntry.lyrics ?? work.canonicalLyrics
          : null,
        english_title_old: englishTitle,
        newHymnalTitle: newEntry
          ? newEntry.title ?? work.defaultTitle
          : null,
        oldHymnalTitle: oldEntry
          ? oldEntry.title ?? work.defaultTitle
          : null,
        newHymnalLyrics: newEntry
          ? newEntry.lyrics ?? work.canonicalLyrics
          : null,
        oldHymnalLyrics: oldEntry
          ? oldEntry.lyrics ?? work.canonicalLyrics
          : null,
        englishTitleOld: englishTitle,
        new_hymnal_number: newEntry?.entryNumber ?? null,
        old_hymnal_number: oldEntry?.entryNumber ?? null,
        isFavorite: false,
      };
    });
};

const getHagerignaSongs = async (excludedWorkIds = new Set()) => {
  const edition = await hagerignaDb.bookEdition.findFirst({
    where: {
      versionKey: versions.hagerigna,
      book: { slug: 'am-hagerigna' },
      isActive: true,
      status: 'published',
    },
  });
  if (!edition) {
    throw new AdminError(
      400,
      'invalid_version',
      'Hagerigna is not available.',
    );
  }
  const rows = await hagerignaDb.bookEntry.findMany({
    where: {
      editionId: edition.id,
      isActive: true,
    },
    include: {
      work: {
        include: publicWorkInclude('am-hagerigna'),
      },
    },
    orderBy: { entryNumber: 'asc' },
  });

  return rows
    .filter((entry) => !excludedWorkIds.has(entry.workId))
    .map((entry) => {
    const media = publicMedia(entry.work);
    const metadata =
      entry.metadata &&
      typeof entry.metadata === 'object' &&
      !Array.isArray(entry.metadata)
        ? entry.metadata
        : {};
      return {
        id: entry.id,
        number: entry.entryNumber,
        title: entry.title ?? entry.work.defaultTitle,
        lyrics: entry.lyrics ?? entry.work.canonicalLyrics ?? '',
        song: entry.lyrics ?? entry.work.canonicalLyrics ?? '',
        artist: metadata.artist ?? null,
        category: null,
        audio_url: media.audio,
        audio: media.audio,
        sheet_music: media.sheetMusic,
        isFavorite: false,
      };
    });
};

const getPublicVersions = async () => {
  const [sda, hagerigna] = await Promise.all([
    sdaDb.bookEdition.findMany({
      where: {
        book: { slug: 'am-sda-hymnal' },
        isActive: true,
        status: 'published',
      },
      orderBy: { sortOrder: 'asc' },
    }),
    hagerignaDb.bookEdition.findMany({
      where: {
        book: { slug: 'am-hagerigna' },
        isActive: true,
        status: 'published',
      },
      orderBy: { sortOrder: 'asc' },
    }),
  ]);
  return [
    ...sda.map((edition) => ({
      id: edition.versionKey,
      catalog: 'sda',
      title: edition.title,
      native_title: edition.nativeTitle ?? edition.title,
      publication_year: edition.publicationYear,
    })),
    ...hagerigna.map((edition) => ({
      id: edition.versionKey,
      catalog: 'hagerigna',
      title: edition.title,
      native_title: edition.nativeTitle ?? edition.title,
      publication_year: edition.publicationYear,
    })),
  ];
};

const getCatalogMediaManifest = async (
  db,
  catalog,
  bookSlug,
  excludedWorkIds = new Set(),
) => {
  const links = await db.mediaLink.findMany({
    where: {
      OR: [
        {
          work: {
            entries: {
              some: { edition: { book: { slug: bookSlug } } },
            },
          },
        },
        { bookEntry: { edition: { book: { slug: bookSlug } } } },
      ],
    },
    include: {
      mediaAsset: true,
      bookEntry: { include: { edition: true } },
    },
    orderBy: [{ mediaAssetId: 'asc' }, { sortOrder: 'asc' }],
  });
  const assets = new Map();
  for (const link of links) {
    const workId = link.workId ?? link.bookEntry?.workId;
    if (!workId || excludedWorkIds.has(workId)) continue;
    if (!assets.has(link.mediaAssetId)) {
      const asset = link.mediaAsset;
      assets.set(link.mediaAssetId, {
        id: asset.id,
        catalog,
        media_type: asset.mediaType,
        storage_provider: asset.storageProvider,
        storage_key: asset.storageKey,
        public_url: asset.publicUrl,
        mime_type: asset.mimeType,
        file_size_bytes:
          asset.fileSizeBytes === null ? null : asset.fileSizeBytes.toString(),
        checksum_sha256: asset.checksumSha256,
        page_label: asset.pageLabel,
        duration_seconds: asset.durationSeconds,
        width_px: asset.widthPx,
        height_px: asset.heightPx,
        metadata: asset.metadata ?? {},
        targets: [],
      });
    }
    assets.get(link.mediaAssetId).targets.push({
      work_id: workId,
      entry_id: link.bookEntryId,
      version: link.bookEntry?.edition?.versionKey ?? null,
      number: link.bookEntry?.entryNumber ?? null,
      relation_type: link.relationType,
      sort_order: link.sortOrder,
    });
  }
  return [...assets.values()];
};

const getPublicMediaManifest = async (excluded) => {
  const [sda, hagerigna] = await Promise.all([
    getCatalogMediaManifest(
      sdaDb,
      'sda',
      'am-sda-hymnal',
      excluded.sda,
    ),
    getCatalogMediaManifest(
      hagerignaDb,
      'hagerigna',
      'am-hagerigna',
      excluded.hagerigna,
    ),
  ]);
  return [...sda, ...hagerigna];
};

const getPublicCategories = async (version) => {
  const normalizedVersion = normalizeVersion(version);
  if (normalizedVersion === versions.hagerigna) return [];
  const edition = await sdaDb.bookEdition.findFirst({
    where: {
      versionKey: normalizedVersion,
      book: { slug: 'am-sda-hymnal' },
      isActive: true,
      status: 'published',
    },
    select: { id: true },
  });
  return edition ? sdaCategories : [];
};

const releaseService = createReleaseService({
  controlDb: sdaDb,
  getVersions: getPublicVersions,
  getHymns: async (version, excludedWorkIds) =>
    version === versions.hagerigna
      ? getHagerignaSongs(excludedWorkIds)
      : getSdaHymns(version, excludedWorkIds),
  getCategories: getPublicCategories,
  getMediaManifest: getPublicMediaManifest,
  recordActivity: collaboration.recordActivity,
  withPublicationLock: collaboration.withPublicationLock,
});

const handleAdminApi = async (request, response, url) => {
  if (request.method === 'GET' && url.pathname === '/api/admin/auth/session') {
    const actor = await collaboration.authenticate({
      token: requestToken(request),
      legacyName: legacyActorName(request),
    });
    sendJson(response, 200, {
      data: { authenticated: Boolean(actor), user: actor },
    });
    return true;
  }

  if (request.method === 'POST' && url.pathname === '/api/admin/auth/login') {
    const body = await readJson(request);
    enforceLoginRateLimit(request, body.email);
    const data = await collaboration.login({
      email: body.email,
      password: body.password,
      userAgent: firstHeader(request.headers['user-agent']),
      ipAddress: clientIp(request),
    });
    clearLoginRateLimit(request, body.email);
    if (browserSessionResponse(request)) {
      const csrfToken = randomBytes(32).toString('base64url');
      const maxAge = Math.max(
        1,
        Math.floor((new Date(data.expiresAt).getTime() - Date.now()) / 1000),
      );
      sendJson(
        response,
        200,
        { data: { expiresAt: data.expiresAt, user: data.user } },
        request,
        {
          'set-cookie': [
            cookieHeader(sessionCookieName, data.token, {
              httpOnly: true,
              maxAge,
            }),
            cookieHeader(csrfCookieName, csrfToken, { maxAge }),
          ],
        },
      );
    } else {
      sendJson(response, 200, { data });
    }
    return true;
  }

  assertAdminCsrf(request);
  const token = requestToken(request);
  const actor = await collaboration.authenticate({
    token,
    legacyName: legacyActorName(request),
  });
  if (!actor) {
    sendJson(
      response,
      401,
      {
        error: 'unauthorized',
        message: 'Sign in with a valid Content Studio account.',
      },
      request,
      parseCookies(request)[sessionCookieName]
        ? { 'set-cookie': clearSessionCookies() }
        : {},
    );
    return true;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/auth/me') {
    sendJson(response, 200, { data: actor });
    return true;
  }
  if (request.method === 'POST' && url.pathname === '/api/admin/auth/logout') {
    sendJson(
      response,
      200,
      { data: await collaboration.logout(token) },
      request,
      { 'set-cookie': clearSessionCookies() },
    );
    return true;
  }
  if (
    request.method === 'POST' &&
    url.pathname === '/api/admin/auth/change-password'
  ) {
    sendJson(response, 200, {
      data: await collaboration.changePassword(
        actor,
        token,
        await readJson(request),
      ),
    });
    return true;
  }

  const actorName = collaboration.actorLabel(actor);
  const catalog = url.searchParams.get('catalog');
  const decorateWork = async (work, catalogValue = catalog) => ({
    ...work,
    collaboration: await collaboration.describeWork(
      actor,
      catalogValue,
      work,
    ),
  });
  const requirePermission = (permission, message) => {
    if (actor.permissions?.[permission] !== true) {
      throw new AdminError(403, 'forbidden', message);
    }
  };
  const editableWork = async (workId) => {
    const work = await contentAdmin.getWork(catalog, workId);
    await collaboration.assertCanEditWork(actor, catalog, work.entries);
    await collaboration.assertWorkflowEditable(catalog, workId);
    return work;
  };
  const withPublicationLock = collaboration.withPublicationLock;

  if (request.method === 'GET' && url.pathname === '/api/admin/dashboard') {
    const [dashboard, workflow, assignments] = await Promise.all([
      contentAdmin.dashboard(),
      collaboration.workflowSummary(),
      actor.legacy ? [] : collaboration.listAssignments(actor),
    ]);
    sendJson(response, 200, {
      data: {
        ...dashboard,
        collaboration: { user: actor, workflow, assignments },
      },
    });
    return true;
  }

  if (url.pathname === '/api/admin/users') {
    if (request.method === 'GET') {
      sendJson(response, 200, {
        data: await collaboration.listUsers(actor),
      });
      return true;
    }
    if (request.method === 'POST') {
      sendJson(response, 201, {
        data: await collaboration.createUser(actor, await readJson(request)),
      });
      return true;
    }
  }

  const userMatch = url.pathname.match(/^\/api\/admin\/users\/([^/]+)$/);
  if (request.method === 'PATCH' && userMatch) {
    sendJson(response, 200, {
      data: await collaboration.updateUser(
        actor,
        decodeURIComponent(userMatch[1]),
        await readJson(request),
      ),
    });
    return true;
  }

  if (url.pathname === '/api/admin/assignments') {
    if (request.method === 'GET') {
      sendJson(response, 200, {
        data: await collaboration.listAssignments(actor, {
          catalog,
          status: url.searchParams.get('status'),
          assigneeId: url.searchParams.get('assigneeId'),
        }),
      });
      return true;
    }
    if (request.method === 'POST') {
      sendJson(response, 201, {
        data: await collaboration.createAssignment(
          actor,
          await readJson(request),
        ),
      });
      return true;
    }
  }

  const assignmentMatch = url.pathname.match(
    /^\/api\/admin\/assignments\/([^/]+)$/,
  );
  if (request.method === 'PATCH' && assignmentMatch) {
    sendJson(response, 200, {
      data: await collaboration.updateAssignment(
        actor,
        decodeURIComponent(assignmentMatch[1]),
        await readJson(request),
      ),
    });
    return true;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/review-queue') {
    const queue = await collaboration.listReviewQueue(actor, {
      catalog,
      status: url.searchParams.get('status') ?? 'submitted',
    });
    const data = await Promise.all(
      queue.map(async (item) => {
        try {
          const work = await contentAdmin.getWork(item.catalog, item.workId);
          if (
            actor.role === 'editor' &&
            !(await collaboration.canEditWork(
              actor,
              item.catalog,
              work.entries,
            ))
          ) {
            return null;
          }
          return {
            ...item,
            title: work.defaultTitle,
            englishTitle: work.defaultEnglishTitle,
            entries: work.entries.map((entry) => ({
              version: entry.version,
              entryNumber: entry.entryNumber,
            })),
          };
        } catch (error) {
          if (error instanceof AdminError && error.status === 404) return null;
          throw error;
        }
      }),
    );
    sendJson(response, 200, { data: data.filter(Boolean) });
    return true;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/categories') {
    const normalizedCatalog = String(catalog ?? '').trim();
    if (!['sda', 'hagerigna'].includes(normalizedCatalog)) {
      throw new AdminError(
        400,
        'invalid_catalog',
        'Catalog must be either "sda" or "hagerigna".',
      );
    }
    sendJson(response, 200, {
      data: normalizedCatalog === 'sda' ? sdaCategories : [],
    });
    return true;
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/activity') {
    sendJson(response, 200, {
      data: await collaboration.listActivity(
        actor,
        url.searchParams.get('pageSize') ?? 100,
      ),
    });
    return true;
  }

  if (url.pathname === '/api/admin/releases') {
    if (request.method === 'GET') {
      requirePermission(
        'createReleases',
        'Only an owner can view content releases.',
      );
      sendJson(response, 200, { data: await releaseService.list() });
      return true;
    }
    if (request.method === 'POST') {
      sendJson(response, 201, {
        data: await releaseService.build(actor, await readJson(request)),
      });
      return true;
    }
  }

  const releaseActivateMatch = url.pathname.match(
    /^\/api\/admin\/releases\/([^/]+)\/activate$/,
  );
  if (request.method === 'POST' && releaseActivateMatch) {
    sendJson(response, 200, {
      data: await releaseService.activate(
        actor,
        decodeURIComponent(releaseActivateMatch[1]),
      ),
    });
    return true;
  }

  const releaseDownloadMatch = url.pathname.match(
    /^\/api\/admin\/releases\/([^/]+)\/download$/,
  );
  if (request.method === 'GET' && releaseDownloadMatch) {
    requirePermission(
      'createReleases',
      'Only an owner can download content releases.',
    );
    const archive = await releaseService.download(
      decodeURIComponent(releaseDownloadMatch[1]),
    );
    sendFile(response, 200, archive.buffer, 'application/zip', {
      'content-disposition': `attachment; filename="${archive.filename}"`,
      'content-length': String(archive.buffer.length),
    });
    return true;
  }

  if (url.pathname === '/api/admin/editions') {
    if (request.method === 'GET') {
      const data = await contentAdmin.listEditions(catalog);
      sendJson(response, 200, { data });
      return true;
    }
    if (request.method === 'POST') {
      requirePermission(
        'manageEditions',
        'Only an owner can create hymnal editions.',
      );
      const body = await readJson(request);
      const data = await withPublicationLock(() =>
        contentAdmin.createEdition(catalog, body, actorName),
      );
      sendJson(response, 201, { data });
      return true;
    }
  }

  const editionMatch = url.pathname.match(
    /^\/api\/admin\/editions\/([^/]+)$/,
  );
  if (request.method === 'PATCH' && editionMatch) {
    requirePermission(
      'manageEditions',
      'Only an owner can update hymnal editions.',
    );
    const body = await readJson(request);
    const data = await withPublicationLock(() =>
      contentAdmin.updateEdition(
        catalog,
        decodeURIComponent(editionMatch[1]),
        body,
        actorName,
      ),
    );
    sendJson(response, 200, { data });
    return true;
  }

  if (url.pathname === '/api/admin/works') {
    if (request.method === 'GET') {
      const result = await contentAdmin.listWorks({
        catalog,
        version: url.searchParams.get('version') ?? 'all',
        membership:
          url.searchParams.get('membership') ??
          (url.searchParams.get('version') ? 'included' : 'all'),
        query: url.searchParams.get('q') ?? '',
        page: url.searchParams.get('page') ?? 1,
        pageSize: url.searchParams.get('pageSize') ?? 40,
        compatibleWith: url.searchParams.get('compatibleWith'),
      });
      result.data = await collaboration.decorateWorks(
        actor,
        catalog,
        result.data,
      );
      sendJson(response, 200, result);
      return true;
    }
    if (request.method === 'POST') {
      const body = await readJson(request);
      await collaboration.assertCanCreateWork(
        actor,
        catalog,
        Array.isArray(body.entries) ? body.entries : [],
      );
      const reservedWorkId = randomUUID();
      await collaboration.markDraft(actor, catalog, reservedWorkId);
      let work;
      try {
        work = await withPublicationLock(() =>
          contentAdmin.createWork(
            catalog,
            body,
            actorName,
            reservedWorkId,
          ),
        );
      } catch (error) {
        await collaboration.removeProvisionalWorkflow(
          catalog,
          reservedWorkId,
        );
        throw error;
      }
      sendJson(response, 201, { data: await decorateWork(work) });
      return true;
    }
  }

  if (request.method === 'GET' && url.pathname === '/api/admin/audit') {
    const data = await contentAdmin.getAudit(catalog, {
      workId: url.searchParams.get('workId'),
      pageSize: url.searchParams.get('pageSize') ?? 50,
    });
    sendJson(response, 200, { data });
    return true;
  }

  const mediaMatch = url.pathname.match(
    /^\/api\/admin\/works\/([^/]+)\/media\/([^/]+)$/,
  );
  if (mediaMatch) {
    requirePermission(
      'manageMedia',
      'Only a reviewer or owner can change reusable song media.',
    );
    const workId = decodeURIComponent(mediaMatch[1]);
    const linkId = decodeURIComponent(mediaMatch[2]);
    if (request.method === 'PATCH') {
      await contentAdmin.getWork(catalog, workId);
      const body = await readJson(request);
      const data = await withPublicationLock(() =>
        contentAdmin.updateMedia(catalog, workId, linkId, body, actorName),
      );
      await collaboration.recordActivity(actor, 'media_update', 'work', workId, {
        catalog,
        linkId,
      });
      sendJson(response, 200, { data });
      return true;
    }
    if (request.method === 'DELETE') {
      await contentAdmin.getWork(catalog, workId);
      const data = await withPublicationLock(() =>
        contentAdmin.removeMedia(catalog, workId, linkId, actorName),
      );
      await collaboration.recordActivity(actor, 'media_remove', 'work', workId, {
        catalog,
        linkId,
      });
      sendJson(response, 200, { data });
      return true;
    }
  }

  const addMediaMatch = url.pathname.match(
    /^\/api\/admin\/works\/([^/]+)\/media$/,
  );
  if (request.method === 'POST' && addMediaMatch) {
    requirePermission(
      'manageMedia',
      'Only a reviewer or owner can change reusable song media.',
    );
    const workId = decodeURIComponent(addMediaMatch[1]);
    await contentAdmin.getWork(catalog, workId);
    const body = await readJson(request);
    const data = await withPublicationLock(() =>
      contentAdmin.addMedia(catalog, workId, body, actorName),
    );
    await collaboration.recordActivity(actor, 'media_add', 'work', workId, {
      catalog,
      linkId: data.id,
    });
    sendJson(response, 201, { data });
    return true;
  }

  const mergeMatch = url.pathname.match(
    /^\/api\/admin\/works\/([^/]+)\/merge$/,
  );
  if (request.method === 'POST' && mergeMatch) {
    requirePermission(
      'editAllContent',
      'Only an owner can merge canonical song records.',
    );
    const workId = decodeURIComponent(mergeMatch[1]);
    const body = await readJson(request);
    const current = await editableWork(workId);
    await editableWork(String(body.sourceWorkId ?? ''));
    await collaboration.markDraft(actor, catalog, workId, current);
    const data = await withPublicationLock(() =>
      contentAdmin.mergeWorks(
        catalog,
        workId,
        String(body.sourceWorkId ?? ''),
        body.expectedUpdatedAt,
        actorName,
      ),
    );
    await collaboration.consolidateWork(
      actor,
      catalog,
      workId,
      String(body.sourceWorkId ?? ''),
    );
    sendJson(response, 200, { data: await decorateWork(data) });
    return true;
  }

  const membershipMatch = url.pathname.match(
    /^\/api\/admin\/works\/([^/]+)\/memberships\/([^/]+)$/,
  );
  if (request.method === 'DELETE' && membershipMatch) {
    const body = await readJson(request);
    const workId = decodeURIComponent(membershipMatch[1]);
    const current = await editableWork(workId);
    await collaboration.assertCanUpdateWork(
      actor,
      catalog,
      current.entries,
      current.entries.filter(
        (entry) => entry.id !== decodeURIComponent(membershipMatch[2]),
      ),
    );
    await collaboration.markDraft(actor, catalog, workId, current);
    const data = await withPublicationLock(() =>
      contentAdmin.removeMembership(
        catalog,
        workId,
        decodeURIComponent(membershipMatch[2]),
        body.expectedUpdatedAt,
        actorName,
      ),
    );
    sendJson(response, 200, { data: await decorateWork(data) });
    return true;
  }

  const workflowActionMatch = url.pathname.match(
    /^\/api\/admin\/works\/([^/]+)\/(submit|review|comments)$/,
  );
  if (workflowActionMatch) {
    const workId = decodeURIComponent(workflowActionMatch[1]);
    const action = workflowActionMatch[2];
    const work = await contentAdmin.getWork(catalog, workId);
    if (request.method === 'POST' && action === 'submit') {
      await collaboration.submitWork(actor, catalog, work);
      sendJson(response, 200, { data: await decorateWork(work) });
      return true;
    }
    if (request.method === 'POST' && action === 'review') {
      const body = await readJson(request);
      await withPublicationLock(() =>
        collaboration.reviewWork(actor, catalog, workId, body),
      );
      sendJson(response, 200, { data: await decorateWork(work) });
      return true;
    }
    if (request.method === 'POST' && action === 'comments') {
      const data = await collaboration.addComment(
        actor,
        catalog,
        work,
        await readJson(request),
      );
      sendJson(response, 201, { data });
      return true;
    }
  }

  const workMatch = url.pathname.match(/^\/api\/admin\/works\/([^/]+)$/);
  if (workMatch) {
    const workId = decodeURIComponent(workMatch[1]);
    if (request.method === 'GET') {
      const data = await contentAdmin.getWork(catalog, workId);
      sendJson(response, 200, { data: await decorateWork(data) });
      return true;
    }
    if (request.method === 'PATCH') {
      const current = await editableWork(workId);
      const body = await readJson(request);
      await collaboration.assertCanUpdateWork(
        actor,
        catalog,
        current.entries,
        body.entries,
      );
      await collaboration.markDraft(actor, catalog, workId, current);
      const data = await withPublicationLock(() =>
        contentAdmin.updateWork(catalog, workId, body, actorName),
      );
      sendJson(response, 200, { data: await decorateWork(data) });
      return true;
    }
  }

  return false;
};

const prismaErrorResponse = (error) => {
  if (error?.code === 'P2002') {
    return {
      status: 409,
      body: {
        error: 'duplicate_content',
        message:
          'That hymnal number, canonical key, or storage key is already in use.',
      },
    };
  }
  if (error?.code === 'P2025') {
    return {
      status: 404,
      body: {
        error: 'record_not_found',
        message: 'The requested database record was not found.',
      },
    };
  }
  if (error?.code === 'P2003') {
    return {
      status: 409,
      body: {
        error: 'content_in_use',
        message: 'This record is still connected to other content.',
      },
    };
  }
  return null;
};

const server = http.createServer(async (request, response) => {
  if (
    forceHttps &&
    !requestIsHttps(request) &&
    (request.url ?? '').split('?')[0] !== '/health'
  ) {
    sendJson(response, 426, {
      error: 'https_required',
      message: 'Use the HTTPS endpoint for this service.',
    });
    return;
  }

  if (request.method === 'OPTIONS') {
    const origin = firstHeader(request.headers.origin);
    const isAdminRequest = (request.url ?? '').startsWith('/api/admin/');
    const isAllowed =
      !origin ||
      allowedOrigins.has(origin) ||
      (isAdminRequest && origin === requestOrigin(request));
    if (!isAllowed && isAdminRequest) {
      sendJson(response, 403, { error: 'origin_not_allowed' }, request);
      return;
    }
    sendJson(response, 204, {}, request);
    return;
  }

  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);

  try {
    if (request.method === 'GET' && url.pathname === '/favicon.ico') {
      response.writeHead(204, securityHeaders());
      response.end();
      return;
    }
    if (
      request.method === 'GET' &&
      (url.pathname === '/admin' || url.pathname === '/admin/content')
    ) {
      sendAdminPage(response);
      return;
    }
    if (request.method === 'GET' && url.pathname === '/admin/review') {
      sendFile(
        response,
        200,
        adminFiles.reviewHtml,
        'text/html; charset=utf-8',
        {
          'content-security-policy':
            `default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; form-action 'self'; frame-ancestors 'none'${isProduction ? '; upgrade-insecure-requests' : ''}`,
          'referrer-policy': 'no-referrer',
          'cross-origin-resource-policy': 'same-origin',
        },
      );
      return;
    }
    if (
      request.method === 'GET' &&
      url.pathname === '/admin/assets/review-console.css'
    ) {
      sendFile(
        response,
        200,
        adminFiles.reviewCss,
        'text/css; charset=utf-8',
      );
      return;
    }
    if (
      request.method === 'GET' &&
      url.pathname === '/admin/assets/review-console.js'
    ) {
      sendFile(
        response,
        200,
        adminFiles.reviewJavascript,
        'text/javascript; charset=utf-8',
      );
      return;
    }
    if (
      request.method === 'GET' &&
      url.pathname === '/admin/assets/content-studio.css'
    ) {
      sendFile(
        response,
        200,
        adminFiles.css,
        'text/css; charset=utf-8',
      );
      return;
    }
    if (
      request.method === 'GET' &&
      url.pathname === '/admin/assets/content-studio.js'
    ) {
      sendFile(
        response,
        200,
        adminFiles.javascript,
        'text/javascript; charset=utf-8',
      );
      return;
    }
    if (
      request.method === 'GET' &&
      url.pathname === '/admin/assets/NotoSansEthiopic-Regular.ttf'
    ) {
      sendFile(
        response,
        200,
        adminFiles.font,
        'font/ttf',
        { 'cache-control': 'public, max-age=86400' },
      );
      return;
    }

    if (url.pathname.startsWith('/api/admin/')) {
      if (!isAdminOriginAllowed(request)) {
        sendJson(
          response,
          403,
          {
            error: 'origin_not_allowed',
            message: 'This browser origin is not allowed to use Content Studio.',
          },
          request,
        );
        return;
      }
      if (await handleAdminApi(request, response, url)) return;
      sendJson(response, 404, {
        error: 'not_found',
        message: 'Admin endpoint was not found.',
      });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/health') {
      await Promise.all([
        sdaDb.$queryRaw`select 1`,
        hagerignaDb.$queryRaw`select 1`,
      ]);
      sendJson(response, 200, {
        ok: true,
        ...(isProduction
          ? {}
          : { databases: { sda: 'connected', hagerigna: 'connected' } }),
      });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/hymns') {
      const version = normalizeVersion(url.searchParams.get('version'));
      const data = publicContentMode === 'release'
        ? (await releaseService.currentFile(`api/hymns/${version}.json`)).data
        : version === versions.hagerigna
          ? await getHagerignaSongs()
          : await getSdaHymns(version);
      sendJson(response, 200, { data });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/versions') {
      const data = publicContentMode === 'release'
        ? (await releaseService.currentFile('api/versions.json')).data
        : await getPublicVersions();
      sendJson(response, 200, { data });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/categories') {
      const version = normalizeVersion(url.searchParams.get('version'));
      const data = publicContentMode === 'release'
        ? (await releaseService.currentFile(
            `api/categories/${version}.json`,
          )).data
        : await getPublicCategories(version);
      sendJson(response, 200, { data });
      return;
    }

    sendJson(response, 404, { error: 'not_found' });
  } catch (error) {
    const prismaResponse = prismaErrorResponse(error);
    if (error instanceof AdminError) {
      sendJson(response, error.status, {
        error: error.code,
        message: error.message,
        details: error.details,
      });
      return;
    }
    if (prismaResponse) {
      sendJson(response, prismaResponse.status, prismaResponse.body);
      return;
    }
    console.error(error);
    sendJson(response, 500, {
      error: 'internal_server_error',
      message:
        process.env.NODE_ENV === 'production'
          ? 'The content service could not complete the request.'
          : error instanceof Error
            ? error.message
            : String(error),
    });
  }
});

const start = async () => {
  await Promise.all([sdaDb.$connect(), hagerignaDb.$connect()]);
  const bootstrapOwner = await collaboration.ensureBootstrapOwner({
    email:
      process.env.CONTENT_BOOTSTRAP_OWNER_EMAIL ?? '',
    password:
      process.env.CONTENT_BOOTSTRAP_OWNER_PASSWORD ?? '',
    displayName:
      process.env.CONTENT_BOOTSTRAP_OWNER_NAME ?? 'Wudase Owner',
  });
  if (bootstrapOwner && !isProduction) {
    console.warn(
      `Created the local Content Studio owner ${bootstrapOwner.email}.`,
    );
  }
  server.listen(port, host, () => {
    console.log(`Wudase content API listening on http://${host}:${port}`);
    console.log(`Content Studio: http://${host}:${port}/admin/content`);
    if (allowLegacyAdmin && adminToken) {
      console.warn(
        'Legacy CONTENT_ADMIN_TOKEN access is enabled. Disable it in production.',
      );
    }
  });
};

const shutdown = async () => {
  server.close();
  await Promise.all([sdaDb.$disconnect(), hagerignaDb.$disconnect()]);
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);

start().catch(async (error) => {
  console.error('Content API failed to start.', error);
  await Promise.allSettled([sdaDb.$disconnect(), hagerignaDb.$disconnect()]);
  process.exit(1);
});
