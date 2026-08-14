import assert from 'node:assert/strict';
import test from 'node:test';

import { createZip, jsonFile, sha256 } from '../src/admin/release-files.js';

test('release JSON is canonical and stable across key order', () => {
  const left = jsonFile({ z: 1, a: { y: 2, b: 3 } });
  const right = jsonFile({ a: { b: 3, y: 2 }, z: 1 });
  assert.deepEqual(left, right);
  assert.equal(sha256(left), sha256(right));
});

test('release ZIP includes valid local and central directory records', () => {
  const zip = createZip(
    [
      { name: 'manifest.json', data: jsonFile({ schemaVersion: 1 }) },
      { name: 'api/versions.json', data: jsonFile({ data: [] }) },
    ],
    new Date('2026-08-13T00:00:00Z'),
  );
  assert.equal(zip.readUInt32LE(0), 0x04034b50);
  assert.notEqual(zip.indexOf(Buffer.from('manifest.json')), -1);
  assert.notEqual(zip.indexOf(Buffer.from('api/versions.json')), -1);
  assert.equal(zip.readUInt32LE(zip.length - 22), 0x06054b50);
  assert.equal(zip.readUInt16LE(zip.length - 14), 2);
});
