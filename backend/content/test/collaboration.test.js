import assert from 'node:assert/strict';
import test from 'node:test';

import {
  assignmentMatchesEntries,
  hashPassword,
  verifyPassword,
} from '../src/admin/collaboration.js';

test('password hashes are salted and verifiable', async () => {
  const first = await hashPassword('StrongPassword!2026');
  const second = await hashPassword('StrongPassword!2026');
  assert.notEqual(first, second);
  assert.equal(await verifyPassword('StrongPassword!2026', first), true);
  assert.equal(await verifyPassword('WrongPassword!2026', first), false);
});

test('assignment matching enforces version, category, and number range', () => {
  const assignment = {
    catalog: 'sda',
    versionKey: 'sda_new',
    categorySlug: 'marriage',
    startNumber: 276,
    endNumber: 277,
  };
  const categoryForEntry = (_catalog, entry) =>
    [276, 277].includes(Number(entry.entryNumber)) ? 'marriage' : 'children';
  assert.equal(
    assignmentMatchesEntries(
      assignment,
      [{ version: 'sda_new', entryNumber: 276 }],
      categoryForEntry,
    ),
    true,
  );
  assert.equal(
    assignmentMatchesEntries(
      assignment,
      [{ version: 'sda_old', entryNumber: 276 }],
      categoryForEntry,
    ),
    false,
  );
  assert.equal(
    assignmentMatchesEntries(
      assignment,
      [{ version: 'sda_new', entryNumber: 275 }],
      categoryForEntry,
    ),
    false,
  );
});
