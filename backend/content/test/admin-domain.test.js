import assert from 'node:assert/strict';
import test from 'node:test';

import {
  AdminError,
  cleanText,
  getCatalogDefinition,
  getVersionDefinition,
  optionalHttpUrl,
  positiveInteger,
  serializeWork,
  slugify,
  validateRelationType,
} from '../src/admin/domain.js';

test('catalog versions map to separate SDA editions', () => {
  const catalog = getCatalogDefinition('sda');
  assert.equal(
    getVersionDefinition(catalog, 'sda_new').editionSlug,
    'am-sda-hymnal-new',
  );
  assert.equal(
    getVersionDefinition(catalog, 'sda_old').editionSlug,
    'am-sda-hymnal-old',
  );
  assert.equal(
    getVersionDefinition(catalog, 'sda_1960').editionSlug,
    'am-sda-hymnal-1960',
  );
  assert.notEqual(
    getVersionDefinition(catalog, 'sda_new').editionSlug,
    getVersionDefinition(catalog, 'sda_old').editionSlug,
  );
});

test('invalid catalog and version values fail closed', () => {
  assert.throws(
    () => getCatalogDefinition('unknown'),
    (error) =>
      error instanceof AdminError &&
      error.status === 400 &&
      error.code === 'invalid_catalog',
  );
  assert.throws(
    () => getVersionDefinition(getCatalogDefinition('hagerigna'), 'sda_old'),
    (error) =>
      error instanceof AdminError && error.code === 'invalid_version',
  );
});

test('text and hymn numbers are bounded', () => {
  assert.equal(cleanText('  አምላካችን  ', 'title'), 'አምላካችን');
  assert.equal(positiveInteger('325', 'number'), 325);
  assert.throws(
    () => positiveInteger('0', 'number'),
    (error) => error instanceof AdminError && error.code === 'invalid_content',
  );
  assert.throws(
    () => cleanText('', 'title', { required: true }),
    (error) => error instanceof AdminError && error.code === 'invalid_content',
  );
});

test('media URLs and relationships are validated', () => {
  assert.equal(
    optionalHttpUrl('https://cdn.example.test/hymn-1.mp3'),
    'https://cdn.example.test/hymn-1.mp3',
  );
  assert.throws(
    () => optionalHttpUrl('file:///private/song.mp3'),
    (error) => error instanceof AdminError && error.code === 'invalid_content',
  );
  assert.equal(
    validateRelationType('sheet_music', 'primary_sheet_music'),
    'primary_sheet_music',
  );
  assert.throws(
    () => validateRelationType('audio', 'thumbnail'),
    (error) => error instanceof AdminError && error.code === 'invalid_media',
  );
});

test('canonical key slugs preserve Ethiopic letters and normalize spacing', () => {
  assert.equal(slugify('  ቅዱስ  ቅዱስ ቅዱስ  '), 'ቅዱስ-ቅዱስ-ቅዱስ');
  assert.equal(slugify('Praise God!'), 'praise-god');
});

test('serialized SDA memberships inherit one canonical song', () => {
  const now = new Date('2026-07-20T12:00:00.000Z');
  const catalog = getCatalogDefinition('sda');
  const work = serializeWork(
    {
      id: '00000000-0000-4000-8000-000000000001',
      canonicalKey: 'am-sda-test',
      defaultTitle: 'አምላካችን',
      defaultEnglishTitle: 'Praise God',
      canonicalLyrics: 'shared lyrics',
      normalizedTitle: 'አምላካችን',
      notes: null,
      createdAt: now,
      updatedAt: now,
      mediaLinks: [],
      entries: [
        {
          id: '00000000-0000-4000-8000-000000000002',
          entryNumber: 7,
          title: null,
          englishTitle: null,
          lyrics: null,
          metadata: {},
          isActive: true,
          updatedAt: now,
          mediaLinks: [],
          edition: {
            slug: 'am-sda-hymnal-old',
            versionKey: 'sda_old',
            title: '1974 Hymnal',
            nativeTitle: 'የ1974 ውዳሴ መዝሙር',
            publicationYear: 1974,
            status: 'published',
            sortOrder: 20,
            isActive: true,
          },
        },
        {
          id: '00000000-0000-4000-8000-000000000003',
          entryNumber: 1,
          title: null,
          englishTitle: null,
          lyrics: null,
          metadata: {},
          isActive: true,
          updatedAt: now,
          mediaLinks: [],
          edition: {
            slug: 'am-sda-hymnal-new',
            versionKey: 'sda_new',
            title: '2004 New Hymnal',
            nativeTitle: 'የ2004 ውዳሴ መዝሙር',
            publicationYear: 2004,
            status: 'published',
            sortOrder: 10,
            isActive: true,
          },
        },
      ],
    },
    catalog,
  );

  assert.equal(work.entries.length, 2);
  assert.equal(work.entries[0].version, 'sda_new');
  assert.equal(work.entries[0].entryNumber, 1);
  assert.equal(work.entries[1].version, 'sda_old');
  assert.equal(work.entries[1].entryNumber, 7);
  assert.equal(work.hasSharedLyrics, true);
  assert.equal(work.sharedLyrics, 'shared lyrics');
  assert.equal(work.canonicalLyrics, 'shared lyrics');
  assert.equal(work.entries[0].hasContentOverrides, false);
  assert.equal(work.entries[0].title, 'አምላካችን');
  assert.equal(work.entries[1].lyrics, 'shared lyrics');
});
