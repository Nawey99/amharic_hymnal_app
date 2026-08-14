const sdaVersions = Object.freeze({
  sda_new: Object.freeze({
    id: 'sda_new',
    label: '2004 New Hymnal',
    nativeLabel: 'የ2004 ውዳሴ መዝሙር',
    editionSlug: 'am-sda-hymnal-new',
    order: 1,
  }),
  sda_old: Object.freeze({
    id: 'sda_old',
    label: '1974 Hymnal',
    nativeLabel: 'የ1974 ውዳሴ መዝሙር',
    editionSlug: 'am-sda-hymnal-old',
    order: 2,
  }),
  sda_1960: Object.freeze({
    id: 'sda_1960',
    label: '1960 Hymnal',
    nativeLabel: 'የ1960 ውዳሴ መዝሙር',
    editionSlug: 'am-sda-hymnal-1960',
    order: 3,
  }),
});

const hagerignaVersions = Object.freeze({
  hagerigna: Object.freeze({
    id: 'hagerigna',
    label: 'Hagerigna Songs',
    nativeLabel: 'የሀገርኛ መዝሙር',
    editionSlug: 'am-hagerigna-primary',
    order: 1,
  }),
});

export const catalogDefinitions = Object.freeze({
  sda: Object.freeze({
    id: 'sda',
    label: 'SDA Hymnal',
    nativeLabel: 'ውዳሴ መዝሙር',
    bookSlug: 'am-sda-hymnal',
    canonicalPrefix: 'am-sda-admin',
    versions: sdaVersions,
    editionSlugs: Object.freeze(
      Object.values(sdaVersions).map((version) => version.editionSlug),
    ),
  }),
  hagerigna: Object.freeze({
    id: 'hagerigna',
    label: 'Hagerigna',
    nativeLabel: 'ሀገርኛ',
    bookSlug: 'am-hagerigna',
    canonicalPrefix: 'am-hagerigna-admin',
    versions: hagerignaVersions,
    editionSlugs: Object.freeze(
      Object.values(hagerignaVersions).map(
        (version) => version.editionSlug,
      ),
    ),
  }),
});

export const allowedMediaTypes = Object.freeze([
  'audio',
  'sheet_music',
  'image',
]);

export const allowedStorageProviders = Object.freeze([
  'external',
  's3',
  'cloudinary',
  'app_asset',
]);

export const allowedRelationTypes = Object.freeze([
  'primary_sheet_music',
  'alternate_sheet_music',
  'primary_audio',
  'alternate_audio',
  'thumbnail',
]);

export class AdminError extends Error {
  constructor(status, code, message, details = undefined) {
    super(message);
    this.name = 'AdminError';
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export const getCatalogDefinition = (value) => {
  const catalog = catalogDefinitions[String(value ?? '').trim()];
  if (!catalog) {
    throw new AdminError(
      400,
      'invalid_catalog',
      'Catalog must be either "sda" or "hagerigna".',
    );
  }
  return catalog;
};

export const getVersionDefinition = (catalog, value) => {
  const version = catalog.versions[String(value ?? '').trim()];
  if (!version) {
    throw new AdminError(
      400,
      'invalid_version',
      `Version is not valid for the ${catalog.id} catalog.`,
    );
  }
  return version;
};

export const versionForEditionSlug = (catalog, editionSlug) =>
  Object.values(catalog.versions).find(
    (version) => version.editionSlug === editionSlug,
  ) ?? null;

export const serializeEdition = (edition, catalog) => {
  const builtIn =
    catalog.versions[edition.versionKey] ??
    versionForEditionSlug(catalog, edition.slug);
  const versionKey = edition.versionKey ?? builtIn?.id ?? edition.slug;
  return {
    id: versionKey,
    versionKey,
    editionId: edition.id,
    editionSlug: edition.slug,
    label: edition.title,
    nativeLabel:
      edition.nativeTitle ?? builtIn?.nativeLabel ?? edition.title,
    publicationYear: edition.publicationYear ?? null,
    status: edition.status ?? (edition.isActive ? 'published' : 'archived'),
    order: edition.sortOrder ?? builtIn?.order ?? 999,
    isActive: edition.isActive !== false,
    sourceNote: edition.sourceNote ?? null,
    entryCount: edition._count?.entries,
  };
};

export const cleanText = (
  value,
  fieldName,
  {
    required = false,
    maxLength = 1000,
    preserveWhitespace = false,
  } = {},
) => {
  if (value === null || value === undefined) {
    if (required) {
      throw new AdminError(
        400,
        'invalid_content',
        `${fieldName} is required.`,
        { field: fieldName },
      );
    }
    return null;
  }

  const text = preserveWhitespace ? String(value) : String(value).trim();
  if (required && text.trim().length === 0) {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} is required.`,
      { field: fieldName },
    );
  }
  if (text.length > maxLength) {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} is longer than ${maxLength} characters.`,
      { field: fieldName, maxLength },
    );
  }
  return text;
};

export const positiveInteger = (
  value,
  fieldName,
  { required = true, max = 100000 } = {},
) => {
  if (value === null || value === undefined || value === '') {
    if (!required) return null;
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} is required.`,
      { field: fieldName },
    );
  }
  const number = Number(value);
  if (!Number.isInteger(number) || number < 1 || number > max) {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} must be a whole number between 1 and ${max}.`,
      { field: fieldName },
    );
  }
  return number;
};

export const boundedInteger = (
  value,
  fieldName,
  { min = 0, max = 100000, fallback = 0 } = {},
) => {
  if (value === null || value === undefined || value === '') return fallback;
  const number = Number(value);
  if (!Number.isInteger(number) || number < min || number > max) {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} must be a whole number between ${min} and ${max}.`,
      { field: fieldName },
    );
  }
  return number;
};

export const optionalHttpUrl = (value, fieldName = 'publicUrl') => {
  const text = cleanText(value, fieldName, { maxLength: 2048 });
  if (!text) return null;
  let url;
  try {
    url = new URL(text);
  } catch {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} must be a valid URL.`,
      { field: fieldName },
    );
  }
  if (!['http:', 'https:'].includes(url.protocol)) {
    throw new AdminError(
      400,
      'invalid_content',
      `${fieldName} must use HTTP or HTTPS.`,
      { field: fieldName },
    );
  }
  return url.toString();
};

export const slugify = (value) => {
  const slug = String(value ?? '')
    .normalize('NFKC')
    .toLocaleLowerCase('en')
    .replace(/[^\p{Letter}\p{Number}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
  return slug || 'song';
};

export const defaultRelationTypeFor = (mediaType) => {
  if (mediaType === 'audio') return 'primary_audio';
  if (mediaType === 'sheet_music') return 'primary_sheet_music';
  return 'thumbnail';
};

export const validateRelationType = (mediaType, relationType) => {
  const value = relationType || defaultRelationTypeFor(mediaType);
  if (!allowedRelationTypes.includes(value)) {
    throw new AdminError(
      400,
      'invalid_media',
      'The selected media relationship is not supported.',
    );
  }
  const valid =
    (mediaType === 'audio' && value.endsWith('_audio')) ||
    (mediaType === 'sheet_music' && value.endsWith('_sheet_music')) ||
    (mediaType === 'image' && value === 'thumbnail');
  if (!valid) {
    throw new AdminError(
      400,
      'invalid_media',
      `Relationship "${value}" cannot be used with ${mediaType}.`,
    );
  }
  return value;
};

const serializeAsset = (asset) => ({
  id: asset.id,
  mediaType: asset.mediaType,
  storageProvider: asset.storageProvider,
  storageKey: asset.storageKey,
  publicUrl: asset.publicUrl,
  mimeType: asset.mimeType,
  fileSizeBytes:
    asset.fileSizeBytes === null || asset.fileSizeBytes === undefined
      ? null
      : asset.fileSizeBytes.toString(),
  checksumSha256: asset.checksumSha256,
  pageLabel: asset.pageLabel,
  durationSeconds: asset.durationSeconds,
  widthPx: asset.widthPx,
  heightPx: asset.heightPx,
  metadata: asset.metadata ?? {},
  updatedAt: asset.updatedAt,
});

export const serializeMediaLink = (link, scope = 'work') => ({
  id: link.id,
  scope,
  relationType: link.relationType,
  sortOrder: link.sortOrder,
  notes: link.notes,
  asset: serializeAsset(link.mediaAsset),
});

export const serializeWork = (work, catalog) => {
  const canonicalLyrics =
    work.canonicalLyrics ??
    (work.entries ?? []).find((entry) => entry.lyrics)?.lyrics ??
    '';
  const entries = (work.entries ?? [])
    .map((entry) => {
      const version = serializeEdition(entry.edition, catalog);
      const titleOverride = entry.title ?? null;
      const englishTitleOverride = entry.englishTitle ?? null;
      const lyricsOverride = entry.lyrics ?? null;
      return {
        id: entry.id,
        version: version.id,
        versionLabel: version.label,
        nativeVersionLabel: version.nativeLabel,
        edition: version,
        entryNumber: entry.entryNumber,
        title: titleOverride ?? work.defaultTitle,
        englishTitle:
          englishTitleOverride ?? work.defaultEnglishTitle,
        lyrics: lyricsOverride ?? canonicalLyrics,
        titleOverride,
        englishTitleOverride,
        lyricsOverride,
        hasContentOverrides: Boolean(
          titleOverride || englishTitleOverride || lyricsOverride,
        ),
        metadata: entry.metadata ?? {},
        category: entry.category
          ? {
              id: entry.category.id,
              slug: entry.category.slug,
              name: entry.category.name,
              englishName: entry.category.englishName,
            }
          : null,
        categorySlug: entry.category?.slug ?? null,
        isActive: entry.isActive,
        updatedAt: entry.updatedAt,
        media: (entry.mediaLinks ?? []).map((link) =>
          serializeMediaLink(link, 'entry'),
        ),
        order: version.order,
      };
    })
    .sort(
      (left, right) =>
        left.order - right.order || left.entryNumber - right.entryNumber,
    )
    .map(({ order: _order, ...entry }) => entry);

  const hasSharedLyrics =
    entries.length > 0 &&
    entries.every((entry) => entry.lyrics === canonicalLyrics);

  return {
    id: work.id,
    catalog: catalog.id,
    canonicalKey: work.canonicalKey,
    defaultTitle: work.defaultTitle,
    defaultEnglishTitle: work.defaultEnglishTitle,
    canonicalLyrics,
    normalizedTitle: work.normalizedTitle,
    notes: work.notes,
    entries,
    media: (work.mediaLinks ?? []).map((link) =>
      serializeMediaLink(link, 'work'),
    ),
    hasSharedLyrics,
    sharedLyrics: canonicalLyrics,
    createdAt: work.createdAt,
    updatedAt: work.updatedAt,
  };
};

export const workAuditSnapshot = (work, catalog) => {
  const serialized = serializeWork(work, catalog);
  return {
    id: serialized.id,
    canonicalKey: serialized.canonicalKey,
    defaultTitle: serialized.defaultTitle,
    defaultEnglishTitle: serialized.defaultEnglishTitle,
    canonicalLyrics: serialized.canonicalLyrics,
    notes: serialized.notes,
    entries: serialized.entries.map((entry) => ({
      id: entry.id,
      version: entry.version,
      entryNumber: entry.entryNumber,
      titleOverride: entry.titleOverride,
      englishTitleOverride: entry.englishTitleOverride,
      lyricsOverride: entry.lyricsOverride,
      metadata: entry.metadata,
      isActive: entry.isActive,
    })),
    media: serialized.media,
  };
};
