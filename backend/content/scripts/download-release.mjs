import { createWriteStream } from 'node:fs';
import { mkdir } from 'node:fs/promises';
import path from 'node:path';
import { pipeline } from 'node:stream/promises';
import { Readable } from 'node:stream';

const [originValue, releaseId, tokenValue, destinationValue] =
  process.argv.slice(2);
const origin = String(originValue ?? '').replace(/\/$/, '');
const token = tokenValue || process.env.CONTENT_ADMIN_SESSION_TOKEN;
if (!origin || !releaseId || !token) {
  throw new Error(
    'Usage: node scripts/download-release.mjs <origin> <release-id> <session-token> [destination]',
  );
}
const destination = path.resolve(
  destinationValue ?? `wudase-content-release-${releaseId}.zip`,
);
await mkdir(path.dirname(destination), { recursive: true });
const response = await fetch(
  `${origin}/api/admin/releases/${encodeURIComponent(releaseId)}/download`,
  { headers: { authorization: `Bearer ${token}` } },
);
if (!response.ok) {
  const body = await response.text();
  throw new Error(`Download failed (${response.status}): ${body}`);
}
await pipeline(
  Readable.fromWeb(response.body),
  createWriteStream(destination, { flags: 'wx' }),
);
console.log(destination);
