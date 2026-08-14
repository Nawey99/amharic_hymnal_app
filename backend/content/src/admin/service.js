import { randomUUID } from 'node:crypto';

import {
  AdminError,
  allowedMediaTypes,
  allowedStorageProviders,
  boundedInteger,
  cleanText,
  defaultRelationTypeFor,
  getCatalogDefinition,
  optionalHttpUrl,
  positiveInteger,
  serializeEdition,
  serializeMediaLink,
  serializeWork,
  slugify,
  validateRelationType,
  workAuditSnapshot,
} from './domain.js';

const editionBelongsTo = (catalog) => ({
  book: { slug: catalog.bookSlug },
});

const workInclude = (catalog) => ({
  entries: {
    where: {
      edition: editionBelongsTo(catalog),
    },
    include: {
      edition: true,
      category: true,
      mediaLinks: {
        include: { mediaAsset: true },
        orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
      },
    },
    orderBy: [{ entryNumber: 'asc' }],
  },
  mediaLinks: {
    include: { mediaAsset: true },
    orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
  },
});

const editionScope = (catalog) => ({
  entries: {
    some: {
      edition: editionBelongsTo(catalog),
    },
  },
});

const normalizeActor = (actor) =>
  cleanText(actor, 'actor', { maxLength: 120 }) || 'content-admin';

const sanitizeMetadata = (value, depth = 0) => {
  if (value === null || typeof value === 'boolean' || typeof value === 'number') {
    return value;
  }
  if (typeof value === 'string') return value.slice(0, 2000);
  if (depth >= 5) return null;
  if (Array.isArray(value)) {
    return value.slice(0, 100).map((item) => sanitizeMetadata(item, depth + 1));
  }
  if (!value || typeof value !== 'object') return null;
  return Object.fromEntries(
    Object.entries(value)
      .filter(
        ([key]) =>
          !['__proto__', 'prototype', 'constructor'].includes(key) &&
          key.length <= 120,
      )
      .slice(0, 100)
      .map(([key, item]) => [key, sanitizeMetadata(item, depth + 1)]),
  );
};

const plainMetadata = (value) => {
  const metadata =
    value && typeof value === 'object' && !Array.isArray(value)
      ? sanitizeMetadata(value)
      : {};
  if (Buffer.byteLength(JSON.stringify(metadata), 'utf8') > 16 * 1024) {
    throw new AdminError(
      400,
      'invalid_metadata',
      'Metadata must be 16 KB or smaller.',
    );
  }
  return metadata;
};

const allowedMimeTypes = Object.freeze({
  audio: new Set([
    'audio/mpeg',
    'audio/mp4',
    'audio/ogg',
    'audio/webm',
    'audio/wav',
    'audio/x-wav',
  ]),
  sheet_music: new Set([
    'image/avif',
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  ]),
  image: new Set(['image/avif', 'image/jpeg', 'image/png', 'image/webp']),
});

const maxMediaBytes = Object.freeze({
  audio: 100n * 1024n * 1024n,
  sheet_music: 25n * 1024n * 1024n,
  image: 10n * 1024n * 1024n,
});

const normalizedVersionKey = (catalog, value) => {
  const key = String(value ?? '').trim();
  if (catalog.id === 'sda' && key === 'hymnal') return 'sda_new';
  return key;
};

const findEdition = async (
  db,
  catalog,
  value,
  { required = true } = {},
) => {
  const versionKey = normalizedVersionKey(catalog, value);
  if (!versionKey || versionKey === 'all') {
    if (!required) return null;
    throw new AdminError(
      400,
      'invalid_version',
      'Choose a hymnal edition.',
    );
  }
  const edition = await db.bookEdition.findFirst({
    where: {
      versionKey,
      book: { slug: catalog.bookSlug },
    },
  });
  if (!edition && required) {
    throw new AdminError(
      400,
      'invalid_version',
      `Hymnal edition "${versionKey}" does not exist in this catalog.`,
    );
  }
  return edition;
};

const membershipFilters = async (
  db,
  catalog,
  version,
  membership = 'included',
) => {
  if (!version || version === 'all') {
    if (!membership || membership === 'all') return [];
    throw new AdminError(
      400,
      'invalid_membership_filter',
      'Choose an edition before filtering its membership.',
    );
  }
  const edition = await findEdition(db, catalog, version);
  const hasEdition = {
    entries: { some: { editionId: edition.id } },
  };
  if (!membership || ['included', 'in'].includes(membership)) {
    return [hasEdition];
  }
  if (membership === 'not_in') {
    return [{ NOT: hasEdition }];
  }
  if (membership === 'all') return [];
  throw new AdminError(
    400,
    'invalid_membership_filter',
    'Membership filter must be included, not_in, or all.',
  );
};

const searchFilter = (catalog, query) => {
  const q = String(query ?? '').trim();
  if (!q) return null;
  const entryFields = [
    { title: { contains: q, mode: 'insensitive' } },
    { englishTitle: { contains: q, mode: 'insensitive' } },
    { lyrics: { contains: q, mode: 'insensitive' } },
  ];
  const number = Number(q);
  if (Number.isInteger(number) && number > 0) {
    entryFields.unshift({ entryNumber: number });
  }
  return {
    OR: [
      { defaultTitle: { contains: q, mode: 'insensitive' } },
      { defaultEnglishTitle: { contains: q, mode: 'insensitive' } },
      { canonicalLyrics: { contains: q, mode: 'insensitive' } },
      { canonicalKey: { contains: q, mode: 'insensitive' } },
      {
        entries: {
          some: {
            edition: editionBelongsTo(catalog),
            OR: entryFields,
          },
        },
      },
    ],
  };
};

const buildWorkWhere = async (
  db,
  catalog,
  { version, membership, query, compatibleWith },
) => {
  const clauses = [editionScope(catalog)];
  clauses.push(
    ...(await membershipFilters(db, catalog, version, membership)),
  );

  const search = searchFilter(catalog, query);
  if (search) clauses.push(search);

  if (compatibleWith) {
    if (catalog.id !== 'sda') {
      throw new AdminError(
        400,
        'merge_not_supported',
        'Edition linking is available only for the SDA catalog.',
      );
    }
    const current = await db.work.findFirst({
      where: {
        id: compatibleWith,
        ...editionScope(catalog),
      },
      include: {
        entries: {
          where: {
            edition: editionBelongsTo(catalog),
          },
          include: { edition: true },
        },
      },
    });
    if (!current) {
      throw new AdminError(404, 'work_not_found', 'Song was not found.');
    }
    const occupiedEditionIds = current.entries.map(
      (entry) => entry.editionId,
    );
    clauses.push({ id: { not: current.id } });
    clauses.push({
      NOT: {
        entries: {
          some: { editionId: { in: occupiedEditionIds } },
        },
      },
    });
  }

  return { AND: clauses };
};

const createAudit = async (
  db,
  {
    catalog,
    action,
    entityType,
    entityId = null,
    workId = null,
    actor,
    before = {},
    after = {},
  },
) =>
  db.contentAuditLog.create({
    data: {
      catalog: catalog.id,
      action,
      entityType,
      entityId,
      workId,
      actor: normalizeActor(actor),
      before,
      after,
    },
  });

const findWork = async (db, catalog, workId) => {
  const work = await db.work.findFirst({
    where: {
      id: workId,
      ...editionScope(catalog),
    },
    include: workInclude(catalog),
  });
  if (!work) {
    throw new AdminError(404, 'work_not_found', 'Song was not found.');
  }
  return work;
};

const checkExpectedUpdate = (work, expectedUpdatedAt) => {
  if (!expectedUpdatedAt) return;
  const expected = new Date(expectedUpdatedAt);
  if (
    Number.isNaN(expected.getTime()) ||
    expected.getTime() !== work.updatedAt.getTime()
  ) {
    throw new AdminError(
      409,
      'content_changed',
      'This song changed after it was opened. Reload it before saving.',
      { updatedAt: work.updatedAt },
    );
  }
};

const normalizeOverride = (
  value,
  canonicalValue,
  fieldName,
  {
    maxLength,
    preserveWhitespace = false,
  },
) => {
  const cleaned = cleanText(value, fieldName, {
    maxLength,
    preserveWhitespace,
  });
  if (cleaned === null || cleaned === canonicalValue) return null;
  if (!preserveWhitespace && cleaned.length === 0) return null;
  return cleaned;
};

const validateEntryInput = (input, index, canonical) => {
  const version = cleanText(input.version, `entries[${index}].version`, {
    required: true,
    maxLength: 80,
  });
  const titleValue = input.titleOverride ?? input.title;
  const englishTitleValue =
    input.englishTitleOverride ?? input.englishTitle;
  const lyricsValue = input.lyricsOverride ?? input.lyrics;
  const useOverrides =
    input.useOverrides === true ||
    (titleValue !== undefined &&
      cleanText(titleValue, `entries[${index}].title`, {
        maxLength: 300,
      }) !== canonical.defaultTitle) ||
    (englishTitleValue !== undefined &&
      cleanText(englishTitleValue, `entries[${index}].englishTitle`, {
        maxLength: 300,
      }) !== canonical.defaultEnglishTitle) ||
    (lyricsValue !== undefined &&
      cleanText(lyricsValue, `entries[${index}].lyrics`, {
        maxLength: 1000000,
        preserveWhitespace: true,
      }) !== canonical.canonicalLyrics);
  return {
    id: cleanText(input.id, `entries[${index}].id`, { maxLength: 80 }),
    version,
    entryNumber: positiveInteger(
      input.entryNumber,
      `entries[${index}].entryNumber`,
    ),
    titleOverride: useOverrides
      ? normalizeOverride(
          titleValue,
          canonical.defaultTitle,
          `entries[${index}].titleOverride`,
          { maxLength: 300 },
        )
      : null,
    englishTitleOverride: useOverrides
      ? normalizeOverride(
          englishTitleValue,
          canonical.defaultEnglishTitle,
          `entries[${index}].englishTitleOverride`,
          { maxLength: 300 },
        )
      : null,
    lyricsOverride: useOverrides
      ? normalizeOverride(
          lyricsValue,
          canonical.canonicalLyrics,
          `entries[${index}].lyricsOverride`,
          { maxLength: 1000000, preserveWhitespace: true },
        )
      : null,
    artist: cleanText(input.artist, `entries[${index}].artist`, {
      maxLength: 300,
    }),
    isActive: input.isActive !== false,
  };
};

const validateEntries = (inputEntries, canonical) => {
  if (!Array.isArray(inputEntries) || inputEntries.length === 0) {
    throw new AdminError(
      400,
      'invalid_content',
      'At least one hymnal entry is required.',
    );
  }
  const entries = inputEntries.map((entry, index) =>
    validateEntryInput(entry, index, canonical),
  );
  const versions = new Set();
  for (const entry of entries) {
    if (versions.has(entry.version)) {
      throw new AdminError(
        400,
        'duplicate_version',
        `Only one membership can be linked for edition "${entry.version}".`,
      );
    }
    versions.add(entry.version);
  }
  return entries;
};

const mediaInput = (input, current = null) => {
  const mediaType = String(input.mediaType ?? current?.mediaType ?? '').trim();
  if (!allowedMediaTypes.includes(mediaType)) {
    throw new AdminError(
      400,
      'invalid_media',
      'Media type must be audio, sheet_music, or image.',
    );
  }
  const storageProvider = String(
    input.storageProvider ?? current?.storageProvider ?? 'external',
  ).trim();
  if (!allowedStorageProviders.includes(storageProvider)) {
    throw new AdminError(
      400,
      'invalid_media',
      'The selected storage provider is not supported.',
    );
  }
  const publicUrl = optionalHttpUrl(
    input.publicUrl ?? current?.publicUrl,
    'publicUrl',
  );
  if (storageProvider !== 'app_asset' && !publicUrl) {
    throw new AdminError(
      400,
      'invalid_media',
      'Remote media requires a public HTTP or HTTPS URL.',
    );
  }
  if (process.env.NODE_ENV === 'production' && publicUrl?.startsWith('http:')) {
    throw new AdminError(
      400,
      'invalid_media',
      'Remote media must use HTTPS in production.',
    );
  }

  const storageKey =
    cleanText(input.storageKey ?? current?.storageKey, 'storageKey', {
      maxLength: 500,
    }) || `admin/${mediaType}/${randomUUID()}`;
  if (
    storageKey.includes('..') ||
    storageKey.startsWith('/') ||
    !/^[A-Za-z0-9_./@+-]+$/.test(storageKey)
  ) {
    throw new AdminError(
      400,
      'invalid_media',
      'Storage keys may contain only safe path characters.',
    );
  }
  const mimeType = cleanText(
    input.mimeType ?? current?.mimeType,
    'mimeType',
    { required: true, maxLength: 120 },
  );
  if (!allowedMimeTypes[mediaType].has(mimeType.toLowerCase())) {
    throw new AdminError(
      400,
      'invalid_media',
      `The MIME type is not allowed for ${mediaType}.`,
    );
  }
  const relationType = validateRelationType(
    mediaType,
    input.relationType ??
      current?.relationType ??
      defaultRelationTypeFor(mediaType),
  );
  const fileSizeValue = input.fileSizeBytes ?? current?.fileSizeBytes;
  let fileSizeBytes = null;
  if (
    fileSizeValue !== null &&
    fileSizeValue !== undefined &&
    fileSizeValue !== ''
  ) {
    try {
      fileSizeBytes = BigInt(fileSizeValue);
    } catch {
      throw new AdminError(
        400,
        'invalid_media',
        'File size must be a whole number of bytes.',
      );
    }
    if (fileSizeBytes < 0n || fileSizeBytes > maxMediaBytes[mediaType]) {
      throw new AdminError(
        400,
        'invalid_media',
        `File size is outside the allowed range for ${mediaType}.`,
      );
    }
  }

  const checksumSha256 = cleanText(
    input.checksumSha256 ?? current?.checksumSha256,
    'checksumSha256',
    { maxLength: 64 },
  );
  if (checksumSha256 && !/^[a-f0-9]{64}$/i.test(checksumSha256)) {
    throw new AdminError(
      400,
      'invalid_media',
      'SHA-256 checksums must contain exactly 64 hexadecimal characters.',
    );
  }

  return {
    mediaType,
    storageProvider,
    storageKey,
    publicUrl,
    mimeType,
    fileSizeBytes,
    checksumSha256: checksumSha256?.toLowerCase() ?? null,
    pageLabel: cleanText(input.pageLabel ?? current?.pageLabel, 'pageLabel', {
      maxLength: 80,
    }),
    durationSeconds: positiveInteger(
      input.durationSeconds ?? current?.durationSeconds,
      'durationSeconds',
      { required: false, max: 86400 },
    ),
    widthPx: positiveInteger(input.widthPx ?? current?.widthPx, 'widthPx', {
      required: false,
      max: 100000,
    }),
    heightPx: positiveInteger(
      input.heightPx ?? current?.heightPx,
      'heightPx',
      { required: false, max: 100000 },
    ),
    metadata: plainMetadata(input.metadata ?? current?.metadata),
    relationType,
    sortOrder: boundedInteger(
      input.sortOrder ?? current?.sortOrder,
      'sortOrder',
      { min: 0, max: 10000, fallback: 0 },
    ),
    notes: cleanText(input.notes ?? current?.notes, 'notes', {
      maxLength: 1000,
    }),
  };
};

const serializeAudit = (record) => ({
  id: record.id,
  catalog: record.catalog,
  action: record.action,
  entityType: record.entityType,
  entityId: record.entityId,
  workId: record.workId,
  actor: record.actor,
  before: record.before,
  after: record.after,
  createdAt: record.createdAt,
});

const validateVersionKey = (value) => {
  const versionKey = cleanText(value, 'versionKey', {
    required: true,
    maxLength: 50,
  });
  if (!/^[a-z][a-z0-9_]{2,49}$/.test(versionKey)) {
    throw new AdminError(
      400,
      'invalid_version_key',
      'API key must start with a letter and use lowercase letters, numbers, or underscores.',
    );
  }
  return versionKey;
};

const validateEditionStatus = (value) => {
  const status = String(value ?? 'draft').trim();
  if (!['draft', 'published', 'archived'].includes(status)) {
    throw new AdminError(
      400,
      'invalid_edition_status',
      'Hymnal status must be draft, published, or archived.',
    );
  }
  return status;
};

export const createContentAdminService = ({ sdaDb, hagerignaDb }) => {
  const databaseFor = (catalog) =>
    catalog.id === 'sda' ? sdaDb : hagerignaDb;

  const getBook = async (db, catalog) => {
    const book = await db.book.findUnique({
      where: { slug: catalog.bookSlug },
    });
    if (!book) {
      throw new AdminError(
        409,
        'catalog_not_initialized',
        `${catalog.label} is not initialized in this database.`,
      );
    }
    return book;
  };

  const listEditions = async (catalogId) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const editions = await db.bookEdition.findMany({
      where: { book: { slug: catalog.bookSlug } },
      include: { _count: { select: { entries: true } } },
      orderBy: [{ sortOrder: 'asc' }, { createdAt: 'asc' }],
    });
    return editions.map((edition) => serializeEdition(edition, catalog));
  };

  const getSummary = async (catalogId) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const base = editionScope(catalog);
    const entryWhere = {
      edition: editionBelongsTo(catalog),
    };
    const [workCount, entryCount, mediaCount, versions] = await Promise.all([
      db.work.count({ where: base }),
      db.bookEntry.count({ where: entryWhere }),
      db.mediaLink.count({
        where: {
          workId: { not: null },
          work: base,
        },
      }),
      listEditions(catalog.id),
    ]);

    return {
      id: catalog.id,
      label: catalog.label,
      nativeLabel: catalog.nativeLabel,
      available: true,
      workCount,
      entryCount,
      mediaCount,
      editionCount: versions.length,
      draftEditionCount: versions.filter(
        (version) => version.status === 'draft',
      ).length,
      versions,
    };
  };

  const dashboard = async () => {
    const results = await Promise.allSettled([
      getSummary('sda'),
      getSummary('hagerigna'),
    ]);
    return {
      catalogs: results.map((result, index) => {
        if (result.status === 'fulfilled') return result.value;
        const catalog = getCatalogDefinition(
          index === 0 ? 'sda' : 'hagerigna',
        );
        return {
          id: catalog.id,
          label: catalog.label,
          nativeLabel: catalog.nativeLabel,
          available: false,
          error: result.reason?.message ?? String(result.reason),
          versions: [],
        };
      }),
      publicApi: {
        sdaNew: '/api/hymns?language=am&version=sda_new',
        sdaOld: '/api/hymns?language=am&version=sda_old',
        sda1960: '/api/hymns?language=am&version=sda_1960',
        hagerigna: '/api/hymns?language=am&version=hagerigna',
      },
    };
  };

  const createEdition = async (catalogId, input, actor) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const book = await getBook(db, catalog);
    const versionKey = validateVersionKey(input.versionKey);
    const title = cleanText(input.title, 'title', {
      required: true,
      maxLength: 300,
    });
    const nativeTitle = cleanText(input.nativeTitle, 'nativeTitle', {
      required: true,
      maxLength: 300,
    });
    const publicationYear = positiveInteger(
      input.publicationYear,
      'publicationYear',
      { required: false, max: 9999 },
    );
    const status = validateEditionStatus(input.status);
    const sourceNote = cleanText(input.sourceNote, 'sourceNote', {
      maxLength: 2000,
    });
    const copyFromVersion = cleanText(
      input.copyFromVersion,
      'copyFromVersion',
      { maxLength: 50 },
    );
    const sourceEdition = copyFromVersion
      ? await findEdition(db, catalog, copyFromVersion)
      : null;
    const lastEdition = await db.bookEdition.findFirst({
      where: { bookId: book.id },
      orderBy: { sortOrder: 'desc' },
    });
    const sortOrder = boundedInteger(input.sortOrder, 'sortOrder', {
      min: 0,
      max: 10000,
      fallback: (lastEdition?.sortOrder ?? 0) + 10,
    });
    const slug = `${catalog.bookSlug}-${versionKey.replaceAll('_', '-')}`;

    const edition = await db.$transaction(async (tx) => {
      const created = await tx.bookEdition.create({
        data: {
          bookId: book.id,
          slug,
          versionKey,
          title,
          nativeTitle,
          publicationYear,
          status,
          editionType: 'edition',
          sortOrder,
          sourceNote,
          isActive: status !== 'archived',
        },
      });

      if (sourceEdition) {
        const sourceEntries = await tx.bookEntry.findMany({
          where: { editionId: sourceEdition.id, isActive: true },
          orderBy: { entryNumber: 'asc' },
        });
        if (sourceEntries.length > 0) {
          await tx.bookEntry.createMany({
            data: sourceEntries.map((entry, index) => ({
              editionId: created.id,
              workId: entry.workId,
              entryNumber: entry.entryNumber,
              title: null,
              englishTitle: null,
              lyrics: null,
              categoryId: entry.categoryId,
              sourceKey: `edition-copy-${created.id}`,
              sourceIndex: index,
              metadata: {
                ...plainMetadata(entry.metadata),
                managed_by: 'content_studio',
                copied_from: sourceEdition.versionKey,
              },
              isActive: true,
            })),
          });
        }
      }

      const after = await tx.bookEdition.findUnique({
        where: { id: created.id },
        include: { _count: { select: { entries: true } } },
      });
      await createAudit(tx, {
        catalog,
        action: 'edition_create',
        entityType: 'book_edition',
        entityId: created.id,
        actor,
        after: serializeEdition(after, catalog),
      });
      return after;
    });
    return serializeEdition(edition, catalog);
  };

  const updateEdition = async (
    catalogId,
    editionId,
    input,
    actor,
  ) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const current = await db.bookEdition.findFirst({
      where: {
        id: editionId,
        book: { slug: catalog.bookSlug },
      },
      include: { _count: { select: { entries: true } } },
    });
    if (!current) {
      throw new AdminError(404, 'edition_not_found', 'Hymnal was not found.');
    }
    const title = cleanText(input.title ?? current.title, 'title', {
      required: true,
      maxLength: 300,
    });
    const nativeTitle = cleanText(
      input.nativeTitle ?? current.nativeTitle,
      'nativeTitle',
      { required: true, maxLength: 300 },
    );
    const publicationYear = positiveInteger(
      input.publicationYear ?? current.publicationYear,
      'publicationYear',
      { required: false, max: 9999 },
    );
    const status = validateEditionStatus(input.status ?? current.status);
    const sortOrder = boundedInteger(
      input.sortOrder ?? current.sortOrder,
      'sortOrder',
      { min: 0, max: 10000, fallback: current.sortOrder },
    );
    const sourceNote = cleanText(
      input.sourceNote ?? current.sourceNote,
      'sourceNote',
      { maxLength: 2000 },
    );
    const updated = await db.$transaction(async (tx) => {
      const result = await tx.bookEdition.update({
        where: { id: current.id },
        data: {
          title,
          nativeTitle,
          publicationYear,
          status,
          sortOrder,
          sourceNote,
          isActive:
            input.isActive === undefined
              ? status !== 'archived'
              : input.isActive === true,
        },
        include: { _count: { select: { entries: true } } },
      });
      await createAudit(tx, {
        catalog,
        action: 'edition_update',
        entityType: 'book_edition',
        entityId: result.id,
        actor,
        before: serializeEdition(current, catalog),
        after: serializeEdition(result, catalog),
      });
      return result;
    });
    return serializeEdition(updated, catalog);
  };

  const listWorks = async ({
    catalog: catalogId,
    version = 'all',
    membership = version === 'all' ? 'all' : 'included',
    query = '',
    page = 1,
    pageSize = 40,
    compatibleWith = null,
  }) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const safePage = positiveInteger(page, 'page', {
      required: false,
      max: 100000,
    }) ?? 1;
    const safePageSize = Math.min(
      positiveInteger(pageSize, 'pageSize', {
        required: false,
        max: 100,
      }) ?? 40,
      100,
    );
    const where = await buildWorkWhere(db, catalog, {
      version,
      membership,
      query,
      compatibleWith,
    });
    const [total, works] = await Promise.all([
      db.work.count({ where }),
      db.work.findMany({
        where,
        include: workInclude(catalog),
        orderBy: [
          { defaultTitle: 'asc' },
          { defaultEnglishTitle: 'asc' },
        ],
        skip: (safePage - 1) * safePageSize,
        take: safePageSize,
      }),
    ]);
    return {
      data: works.map((work) => serializeWork(work, catalog)),
      pagination: {
        page: safePage,
        pageSize: safePageSize,
        total,
        totalPages: Math.max(1, Math.ceil(total / safePageSize)),
      },
    };
  };

  const getWork = async (catalogId, workId) => {
    const catalog = getCatalogDefinition(catalogId);
    const work = await findWork(databaseFor(catalog), catalog, workId);
    return serializeWork(work, catalog);
  };

  const createWork = async (catalogId, input, actor, reservedWorkId = null) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const defaultTitle = cleanText(input.defaultTitle, 'defaultTitle', {
      required: true,
      maxLength: 300,
    });
    const defaultEnglishTitle = cleanText(
      input.defaultEnglishTitle,
      'defaultEnglishTitle',
      { maxLength: 300 },
    );
    const canonicalLyrics = cleanText(
      input.canonicalLyrics ??
        input.sharedLyrics ??
        input.entries?.[0]?.lyrics ??
        input.entries?.[0]?.lyricsOverride,
      'canonicalLyrics',
      {
        required: true,
        maxLength: 1000000,
        preserveWhitespace: true,
      },
    );
    const notes = cleanText(input.notes, 'notes', { maxLength: 4000 });
    const canonical = {
      defaultTitle,
      defaultEnglishTitle,
      canonicalLyrics,
    };
    const entries = validateEntries(input.entries, canonical);
    const requestedKey = cleanText(input.canonicalKey, 'canonicalKey', {
      maxLength: 160,
    });
    const canonicalKey =
      requestedKey ||
      `${catalog.canonicalPrefix}-${slugify(
        defaultEnglishTitle || defaultTitle,
      )}-${randomUUID().slice(0, 8)}`;

    const work = await db.$transaction(async (tx) => {
      const created = await tx.work.create({
        data: {
          ...(reservedWorkId ? { id: reservedWorkId } : {}),
          canonicalKey,
          primaryLanguageCode: 'am',
          defaultTitle,
          defaultEnglishTitle,
          canonicalLyrics,
          normalizedTitle: slugify(defaultTitle),
          notes,
        },
      });

      for (const entry of entries) {
        const edition = await findEdition(tx, catalog, entry.version);
        await tx.bookEntry.create({
          data: {
            editionId: edition.id,
            workId: created.id,
            entryNumber: entry.entryNumber,
            title: entry.titleOverride,
            englishTitle: entry.englishTitleOverride,
            lyrics: entry.lyricsOverride,
            sourceKey: `admin-${randomUUID()}`,
            sourceIndex: 0,
            metadata: {
              managed_by: 'content_studio',
              ...(entry.artist ? { artist: entry.artist } : {}),
            },
            isActive: entry.isActive,
          },
        });
      }

      const after = await tx.work.findUnique({
        where: { id: created.id },
        include: workInclude(catalog),
      });
      await createAudit(tx, {
        catalog,
        action: 'create',
        entityType: 'work',
        entityId: created.id,
        workId: created.id,
        actor,
        after: workAuditSnapshot(after, catalog),
      });
      return after;
    });
    return serializeWork(work, catalog);
  };

  const updateWork = async (catalogId, workId, input, actor) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const defaultTitle = cleanText(input.defaultTitle, 'defaultTitle', {
      required: true,
      maxLength: 300,
    });
    const defaultEnglishTitle = cleanText(
      input.defaultEnglishTitle,
      'defaultEnglishTitle',
      { maxLength: 300 },
    );
    const canonicalLyrics = cleanText(
      input.canonicalLyrics ?? input.sharedLyrics,
      'canonicalLyrics',
      {
        required: true,
        maxLength: 1000000,
        preserveWhitespace: true,
      },
    );
    const notes = cleanText(input.notes, 'notes', { maxLength: 4000 });
    const canonical = {
      defaultTitle,
      defaultEnglishTitle,
      canonicalLyrics,
    };
    const entries = validateEntries(input.entries, canonical);

    const updated = await db.$transaction(async (tx) => {
      const current = await findWork(tx, catalog, workId);
      checkExpectedUpdate(current, input.expectedUpdatedAt);
      const before = workAuditSnapshot(current, catalog);
      const currentById = new Map(
        current.entries.map((entry) => [entry.id, entry]),
      );
      const currentByVersion = new Map(
        current.entries.map((entry) => [
          entry.edition.versionKey,
          entry,
        ]),
      );

      await tx.work.update({
        where: { id: workId },
        data: {
          defaultTitle,
          defaultEnglishTitle,
          canonicalLyrics,
          normalizedTitle: slugify(defaultTitle),
          notes,
        },
      });

      for (const entry of entries) {
        const existing = entry.id ? currentById.get(entry.id) : null;
        const edition = await findEdition(tx, catalog, entry.version);
        if (entry.id && !existing) {
          throw new AdminError(
            400,
            'entry_not_linked',
            'One of the edited entries does not belong to this song.',
          );
        }
        if (
          existing &&
          existing.editionId !== edition.id
        ) {
          throw new AdminError(
            400,
            'version_cannot_change',
            'An existing entry cannot be moved to another edition.',
          );
        }
        if (
          !existing &&
          currentByVersion.has(edition.versionKey)
        ) {
          throw new AdminError(
            409,
            'version_already_linked',
            `${edition.title} is already linked to this song.`,
          );
        }

        const metadata = {
          ...plainMetadata(existing?.metadata),
          managed_by: 'content_studio',
        };
        if (entry.artist) metadata.artist = entry.artist;
        else if (catalog.id === 'hagerigna') delete metadata.artist;

        if (existing) {
          await tx.bookEntry.update({
            where: { id: existing.id },
            data: {
              entryNumber: entry.entryNumber,
              title: entry.titleOverride,
              englishTitle: entry.englishTitleOverride,
              lyrics: entry.lyricsOverride,
              metadata,
              isActive: entry.isActive,
            },
          });
        } else {
          await tx.bookEntry.create({
            data: {
              editionId: edition.id,
              workId,
              entryNumber: entry.entryNumber,
              title: entry.titleOverride,
              englishTitle: entry.englishTitleOverride,
              lyrics: entry.lyricsOverride,
              sourceKey: `admin-${randomUUID()}`,
              sourceIndex: 0,
              metadata,
              isActive: entry.isActive,
            },
          });
        }
      }

      const after = await tx.work.findUnique({
        where: { id: workId },
        include: workInclude(catalog),
      });
      await createAudit(tx, {
        catalog,
        action: 'update',
        entityType: 'work',
        entityId: workId,
        workId,
        actor,
        before,
        after: workAuditSnapshot(after, catalog),
      });
      return after;
    });
    return serializeWork(updated, catalog);
  };

  const mergeWorks = async (
    catalogId,
    survivorWorkId,
    sourceWorkId,
    expectedUpdatedAt,
    actor,
  ) => {
    const catalog = getCatalogDefinition(catalogId);
    if (catalog.id !== 'sda') {
      throw new AdminError(
        400,
        'merge_not_supported',
        'Duplicate linking is available only in the SDA song library.',
      );
    }
    if (!sourceWorkId || sourceWorkId === survivorWorkId) {
      throw new AdminError(
        400,
        'invalid_merge',
        'Choose a different song to connect.',
      );
    }
    const db = databaseFor(catalog);
    const merged = await db.$transaction(async (tx) => {
      const survivor = await findWork(tx, catalog, survivorWorkId);
      const source = await findWork(tx, catalog, sourceWorkId);
      checkExpectedUpdate(survivor, expectedUpdatedAt);

      const survivorEditionIds = new Set(
        survivor.entries.map((entry) => entry.editionId),
      );
      const conflicts = source.entries
        .filter((entry) => survivorEditionIds.has(entry.editionId))
        .map((entry) => entry.edition.versionKey);
      if (conflicts.length > 0) {
        throw new AdminError(
          409,
          'edition_conflict',
          'These records both belong to the same hymnal. Resolve that duplicate membership before merging.',
          { versionKeys: conflicts },
        );
      }

      const before = {
        survivor: workAuditSnapshot(survivor, catalog),
        source: workAuditSnapshot(source, catalog),
      };

      for (const link of source.mediaLinks) {
        const existing = await tx.mediaLink.findFirst({
          where: {
            mediaAssetId: link.mediaAssetId,
            workId: survivor.id,
            relationType: link.relationType,
          },
        });
        if (existing) {
          await tx.mediaLink.delete({ where: { id: link.id } });
        } else {
          await tx.mediaLink.update({
            where: { id: link.id },
            data: { workId: survivor.id },
          });
        }
      }

      await tx.bookEntry.updateMany({
        where: { workId: source.id },
        data: { workId: survivor.id },
      });
      await tx.work.update({
        where: { id: survivor.id },
        data: { updatedAt: new Date() },
      });
      await tx.work.delete({ where: { id: source.id } });

      const after = await tx.work.findUnique({
        where: { id: survivor.id },
        include: workInclude(catalog),
      });
      await createAudit(tx, {
        catalog,
        action: 'merge',
        entityType: 'work',
        entityId: survivor.id,
        workId: survivor.id,
        actor,
        before,
        after: workAuditSnapshot(after, catalog),
      });
      return after;
    });
    return serializeWork(merged, catalog);
  };

  const removeMembership = async (
    catalogId,
    workId,
    entryId,
    expectedUpdatedAt,
    actor,
  ) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const updated = await db.$transaction(async (tx) => {
      const current = await findWork(tx, catalog, workId);
      checkExpectedUpdate(current, expectedUpdatedAt);
      const entry = current.entries.find((item) => item.id === entryId);
      if (!entry) {
        throw new AdminError(
          404,
          'membership_not_found',
          'This song is not part of that hymnal.',
        );
      }
      if (current.entries.length <= 1) {
        throw new AdminError(
          409,
          'last_membership',
          'A song must remain in at least one hymnal. Add it to another hymnal before removing this membership.',
        );
      }

      const before = {
        version: entry.edition.versionKey,
        entryNumber: entry.entryNumber,
        work: workAuditSnapshot(current, catalog),
      };
      const entryAssetIds = entry.mediaLinks.map(
        (link) => link.mediaAssetId,
      );
      await tx.bookEntry.delete({ where: { id: entry.id } });
      for (const mediaAssetId of entryAssetIds) {
        const remaining = await tx.mediaLink.count({
          where: { mediaAssetId },
        });
        if (remaining === 0) {
          await tx.mediaAsset.delete({ where: { id: mediaAssetId } });
        }
      }
      await tx.work.update({
        where: { id: current.id },
        data: { updatedAt: new Date() },
      });
      const after = await tx.work.findUnique({
        where: { id: current.id },
        include: workInclude(catalog),
      });
      await createAudit(tx, {
        catalog,
        action: 'membership_remove',
        entityType: 'book_entry',
        entityId: entry.id,
        workId: current.id,
        actor,
        before,
        after: workAuditSnapshot(after, catalog),
      });
      return after;
    });
    return serializeWork(updated, catalog);
  };

  const addMedia = async (catalogId, workId, input, actor) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const data = mediaInput(input);
    const result = await db.$transaction(async (tx) => {
      await findWork(tx, catalog, workId);
      const asset = await tx.mediaAsset.upsert({
        where: {
          storageProvider_storageKey: {
            storageProvider: data.storageProvider,
            storageKey: data.storageKey,
          },
        },
        create: {
          mediaType: data.mediaType,
          storageProvider: data.storageProvider,
          storageKey: data.storageKey,
          publicUrl: data.publicUrl,
          mimeType: data.mimeType,
          fileSizeBytes: data.fileSizeBytes,
          checksumSha256: data.checksumSha256,
          pageLabel: data.pageLabel,
          durationSeconds: data.durationSeconds,
          widthPx: data.widthPx,
          heightPx: data.heightPx,
          metadata: data.metadata,
        },
        update: {
          mediaType: data.mediaType,
          publicUrl: data.publicUrl,
          mimeType: data.mimeType,
          fileSizeBytes: data.fileSizeBytes,
          checksumSha256: data.checksumSha256,
          pageLabel: data.pageLabel,
          durationSeconds: data.durationSeconds,
          widthPx: data.widthPx,
          heightPx: data.heightPx,
          metadata: data.metadata,
        },
      });
      let link = await tx.mediaLink.findFirst({
        where: {
          mediaAssetId: asset.id,
          workId,
          relationType: data.relationType,
        },
        include: { mediaAsset: true },
      });
      if (link) {
        link = await tx.mediaLink.update({
          where: { id: link.id },
          data: { sortOrder: data.sortOrder, notes: data.notes },
          include: { mediaAsset: true },
        });
      } else {
        link = await tx.mediaLink.create({
          data: {
            mediaAssetId: asset.id,
            workId,
            relationType: data.relationType,
            sortOrder: data.sortOrder,
            notes: data.notes,
          },
          include: { mediaAsset: true },
        });
      }
      await createAudit(tx, {
        catalog,
        action: 'media_add',
        entityType: 'media_link',
        entityId: link.id,
        workId,
        actor,
        after: serializeMediaLink(link),
      });
      return link;
    });
    return serializeMediaLink(result);
  };

  const updateMedia = async (
    catalogId,
    workId,
    linkId,
    input,
    actor,
  ) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const updated = await db.$transaction(async (tx) => {
      await findWork(tx, catalog, workId);
      const current = await tx.mediaLink.findFirst({
        where: { id: linkId, workId },
        include: { mediaAsset: true },
      });
      if (!current) {
        throw new AdminError(
          404,
          'media_not_found',
          'Media link was not found.',
        );
      }
      const data = mediaInput(input, {
        ...current.mediaAsset,
        relationType: current.relationType,
        sortOrder: current.sortOrder,
        notes: current.notes,
      });
      const before = serializeMediaLink(current);
      const asset = await tx.mediaAsset.update({
        where: { id: current.mediaAssetId },
        data: {
          mediaType: data.mediaType,
          storageProvider: data.storageProvider,
          storageKey: data.storageKey,
          publicUrl: data.publicUrl,
          mimeType: data.mimeType,
          fileSizeBytes: data.fileSizeBytes,
          checksumSha256: data.checksumSha256,
          pageLabel: data.pageLabel,
          durationSeconds: data.durationSeconds,
          widthPx: data.widthPx,
          heightPx: data.heightPx,
          metadata: data.metadata,
        },
      });
      const link = await tx.mediaLink.update({
        where: { id: current.id },
        data: {
          relationType: data.relationType,
          sortOrder: data.sortOrder,
          notes: data.notes,
        },
        include: { mediaAsset: true },
      });
      await createAudit(tx, {
        catalog,
        action: 'media_update',
        entityType: 'media_link',
        entityId: link.id,
        workId,
        actor,
        before,
        after: serializeMediaLink({ ...link, mediaAsset: asset }),
      });
      return { ...link, mediaAsset: asset };
    });
    return serializeMediaLink(updated);
  };

  const removeMedia = async (catalogId, workId, linkId, actor) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    await db.$transaction(async (tx) => {
      await findWork(tx, catalog, workId);
      const link = await tx.mediaLink.findFirst({
        where: { id: linkId, workId },
        include: { mediaAsset: true },
      });
      if (!link) {
        throw new AdminError(
          404,
          'media_not_found',
          'Media link was not found.',
        );
      }
      const before = serializeMediaLink(link);
      await tx.mediaLink.delete({ where: { id: link.id } });
      const remainingLinks = await tx.mediaLink.count({
        where: { mediaAssetId: link.mediaAssetId },
      });
      if (remainingLinks === 0) {
        await tx.mediaAsset.delete({ where: { id: link.mediaAssetId } });
      }
      await createAudit(tx, {
        catalog,
        action: 'media_remove',
        entityType: 'media_link',
        entityId: link.id,
        workId,
        actor,
        before,
      });
    });
    return { removed: true };
  };

  const getAudit = async (
    catalogId,
    { workId = null, pageSize = 50 } = {},
  ) => {
    const catalog = getCatalogDefinition(catalogId);
    const db = databaseFor(catalog);
    const take = Math.min(
      positiveInteger(pageSize, 'pageSize', {
        required: false,
        max: 100,
      }) ?? 50,
      100,
    );
    const records = await db.contentAuditLog.findMany({
      where: {
        catalog: catalog.id,
        ...(workId ? { workId } : {}),
      },
      orderBy: { createdAt: 'desc' },
      take,
    });
    return records.map(serializeAudit);
  };

  return {
    dashboard,
    getSummary,
    listEditions,
    createEdition,
    updateEdition,
    listWorks,
    getWork,
    createWork,
    updateWork,
    mergeWorks,
    removeMembership,
    addMedia,
    updateMedia,
    removeMedia,
    getAudit,
  };
};
