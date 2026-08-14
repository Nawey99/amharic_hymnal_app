import {
  existsSync,
  readFileSync,
  unlinkSync,
} from 'node:fs';
import path from 'node:path';
import {
  spawn,
  spawnSync,
} from 'node:child_process';
import { createServer } from 'node:net';
import { setTimeout as delay } from 'node:timers/promises';

import { PrismaClient } from '@prisma/client';

import { hashPassword } from '../src/admin/collaboration.js';

const root = path.resolve(import.meta.dirname, '..', '..', '..');
const postgresBin =
  process.env.POSTGRES_BIN ??
  path.join(
    process.env.ProgramFiles ?? 'C:\\Program Files',
    'PostgreSQL',
    '16',
    'bin',
  );
const postgres = path.join(postgresBin, 'postgres.exe');
const pgIsReady = path.join(postgresBin, 'pg_isready.exe');
const pgCtl = path.join(postgresBin, 'pg_ctl.exe');
const psql = path.join(postgresBin, 'psql.exe');
const pgData = path.join(root, '.tmp_pg_wudase_content');
const pidFile = path.join(pgData, 'postmaster.pid');
const adminToken = 'content-studio-integration-secret';
const sdaWorkIds = new Set();
const hagerignaWorkIds = new Set();
const sdaEditionIds = new Set();
const collaborationUserIds = new Set();
const collaborationAssignmentIds = new Set();
const collaborationReleaseIds = new Set();
let postgresProcess;
let ownsPostgres = false;
let apiProcess;
let postgresOutput = '';
let apiOutput = '';
let apiPort;
let apiOrigin;
let controlDb;
let qaOwnerCredentials;

const run = (file, args, options = {}) => {
  const result = spawnSync(file, args, {
    cwd: root,
    encoding: 'utf8',
    windowsHide: true,
    ...options,
  });
  if (result.status !== 0) {
    throw new Error(
      `${path.basename(file)} failed (${result.status}).\n${
        result.stderr || result.stdout
      }`,
    );
  }
  return result.stdout.trim();
};

const processExists = (pid) => {
  try {
    process.kill(pid, 0);
    return true;
  } catch {
    return false;
  }
};

const clearStalePostmasterPid = () => {
  if (!existsSync(pidFile)) return;
  const pid = Number(readFileSync(pidFile, 'utf8').split(/\r?\n/, 1)[0]);
  if (Number.isInteger(pid) && processExists(pid)) {
    throw new Error(`PostgreSQL is already using ${pgData} (PID ${pid}).`);
  }
  unlinkSync(pidFile);
};

const waitForPostgres = async () => {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    const result = spawnSync(
      pgIsReady,
      ['-h', '127.0.0.1', '-p', '55432', '-d', 'postgres', '-q'],
      { windowsHide: true },
    );
    if (result.status === 0) return;
    if (postgresProcess.exitCode !== null) break;
    await delay(250);
  }
  throw new Error(`Local PostgreSQL did not become ready.\n${postgresOutput}`);
};

const waitForApi = async () => {
  for (let attempt = 0; attempt < 40; attempt += 1) {
    try {
      const response = await fetch(`${apiOrigin}/health`);
      const body = await response.json();
      if (response.ok && body.ok) return;
    } catch {
      // The server is still starting.
    }
    if (apiProcess.exitCode !== null) break;
    await delay(250);
  }
  throw new Error(`Content API did not become ready.\n${apiOutput}`);
};

const availablePort = () =>
  new Promise((resolve, reject) => {
    const probe = createServer();
    probe.once('error', reject);
    probe.listen(0, '127.0.0.1', () => {
      const address = probe.address();
      const port = typeof address === 'object' && address ? address.port : null;
      probe.close((error) => {
        if (error) reject(error);
        else if (!port) reject(new Error('Could not allocate an API port.'));
        else resolve(port);
      });
    });
  });

const api = async (
  pathname,
  { method = 'GET', body, auth = true, token = null } = {},
) => {
  const headers = {};
  if (auth) {
    if (token) {
      headers.authorization = `Bearer ${token}`;
    } else {
      headers['x-admin-token'] = adminToken;
      headers['x-admin-name'] = 'Automated integration test';
    }
  }
  if (body !== undefined) headers['content-type'] = 'application/json';
  const response = await fetch(`${apiOrigin}${pathname}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const payload = await response.json();
  if (!response.ok) {
    const error = new Error(
      `${method} ${pathname} failed (${response.status}): ${
        payload.message ?? payload.error
      }`,
    );
    error.status = response.status;
    throw error;
  }
  return payload;
};

const assert = (condition, message) => {
  if (!condition) throw new Error(message);
};

const startPostgres = async () => {
  if (existsSync(pidFile)) {
    const pid = Number(readFileSync(pidFile, 'utf8').split(/\r?\n/, 1)[0]);
    if (Number.isInteger(pid) && processExists(pid)) {
      const ready = spawnSync(
        pgIsReady,
        ['-h', '127.0.0.1', '-p', '55432', '-d', 'postgres', '-q'],
        { windowsHide: true },
      );
      if (ready.status === 0) return;
      throw new Error(
        `PostgreSQL owns ${pgData} (PID ${pid}) but is not accepting connections.`,
      );
    }
  }

  clearStalePostmasterPid();
  postgresProcess = spawn(
    postgres,
    [
      '-D',
      pgData,
      '-c',
      'shared_buffers=32MB',
      '-c',
      'max_connections=20',
    ],
    {
      cwd: root,
      windowsHide: true,
      stdio: ['ignore', 'pipe', 'pipe'],
    },
  );
  ownsPostgres = true;
  postgresProcess.stdout.on('data', (chunk) => {
    postgresOutput += chunk.toString();
  });
  postgresProcess.stderr.on('data', (chunk) => {
    postgresOutput += chunk.toString();
  });
  await waitForPostgres();
};

const migrateDatabases = () => {
  const databaseNames = run(psql, [
    '-h',
    '127.0.0.1',
    '-p',
    '55432',
    '-U',
    'postgres',
    '-d',
    'postgres',
    '-Atc',
    'select datname from pg_database order by datname',
  ])
    .split(/\r?\n/)
    .filter(Boolean);
  for (const database of ['wudase_sda_dev', 'wudase_hagerigna_dev']) {
    assert(
      databaseNames.includes(database),
      `Expected database ${database} was not found.`,
    );
  }
  run(
    process.execPath,
    [path.join(root, 'backend', 'content', 'scripts', 'migrate.mjs')],
    {
      env: {
        ...process.env,
        SDA_HYMNAL_DATABASE_URL:
          'postgresql://postgres@127.0.0.1:55432/wudase_sda_dev',
        HAGERIGNA_DATABASE_URL:
          'postgresql://postgres@127.0.0.1:55432/wudase_hagerigna_dev',
      },
    },
  );
  return databaseNames;
};

const seedCollaborationOwner = async () => {
  controlDb = new PrismaClient({
    datasources: {
      db: {
        url: 'postgresql://postgres@127.0.0.1:55432/wudase_sda_dev',
      },
    },
  });
  await controlDb.$connect();
  const suffix = `${Date.now()}-${process.pid}`;
  qaOwnerCredentials = {
    email: `qa-owner-${suffix}@example.test`,
    password: `QaOwner-${suffix}-Password!`,
  };
  const owner = await controlDb.contentUser.create({
    data: {
      email: qaOwnerCredentials.email,
      displayName: 'QA Workflow Owner',
      role: 'owner',
      passwordHash: await hashPassword(qaOwnerCredentials.password),
    },
  });
  collaborationUserIds.add(owner.id);
};

const startApi = async () => {
  apiPort = await availablePort();
  apiOrigin = `http://127.0.0.1:${apiPort}`;
  apiProcess = spawn(process.execPath, ['src/server.js'], {
    cwd: path.join(root, 'backend', 'content'),
    windowsHide: true,
    env: {
      ...process.env,
      HOST: '127.0.0.1',
      PORT: String(apiPort),
      CONTENT_ADMIN_TOKEN: adminToken,
      ALLOW_LEGACY_CONTENT_ADMIN: 'true',
      SDA_HYMNAL_DATABASE_URL:
        'postgresql://postgres@127.0.0.1:55432/wudase_sda_dev',
      HAGERIGNA_DATABASE_URL:
        'postgresql://postgres@127.0.0.1:55432/wudase_hagerigna_dev',
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  apiProcess.stdout.on('data', (chunk) => {
    apiOutput += chunk.toString();
  });
  apiProcess.stderr.on('data', (chunk) => {
    apiOutput += chunk.toString();
  });
  await waitForApi();
};

const createSdaEntry = async (version, entryNumber, title) => {
  const response = await api('/api/admin/works?catalog=sda', {
    method: 'POST',
    body: {
      defaultTitle: title,
      defaultEnglishTitle: 'QA Integration Shared Song',
      canonicalLyrics: 'Temporary shared lyrics.',
      notes: 'Temporary automated test record.',
      entries: [
        {
          version,
          entryNumber,
          isActive: true,
        },
      ],
    },
  });
  sdaWorkIds.add(response.data.id);
  return response.data;
};

const exerciseCollaborationWorkflow = async () => {
  const suffix = `${Date.now()}-${process.pid}`;
  const login = await api('/api/admin/auth/login', {
    method: 'POST',
    auth: false,
    body: qaOwnerCredentials,
  });
  const ownerToken = login.data.token;
  assert(
    login.data.user.role === 'owner' && ownerToken.startsWith('wcs_'),
    'An individual owner must receive a scoped Content Studio session.',
  );

  const editorPassword = `QaEditor-${suffix}-Password!`;
  const reviewerPassword = `QaReviewer-${suffix}-Password!`;
  const editor = await api('/api/admin/users', {
    method: 'POST',
    token: ownerToken,
    body: {
      email: `qa-editor-${suffix}@example.test`,
      displayName: 'QA Workflow Editor',
      role: 'editor',
      password: editorPassword,
    },
  });
  const reviewer = await api('/api/admin/users', {
    method: 'POST',
    token: ownerToken,
    body: {
      email: `qa-reviewer-${suffix}@example.test`,
      displayName: 'QA Workflow Reviewer',
      role: 'reviewer',
      password: reviewerPassword,
    },
  });
  collaborationUserIds.add(editor.data.id);
  collaborationUserIds.add(reviewer.data.id);

  const editorLogin = await api('/api/admin/auth/login', {
    method: 'POST',
    auth: false,
    body: { email: editor.data.email, password: editorPassword },
  });
  const reviewerLogin = await api('/api/admin/auth/login', {
    method: 'POST',
    auth: false,
    body: { email: reviewer.data.email, password: reviewerPassword },
  });
  let editorToken = editorLogin.data.token;
  const reviewerToken = reviewerLogin.data.token;

  const resetPassword = `QaEditorReset-${suffix}-Password!`;
  await api(`/api/admin/users/${editor.data.id}`, {
    method: 'PATCH',
    token: ownerToken,
    body: { password: resetPassword },
  });
  let revokedSessionStatus = null;
  try {
    await api('/api/admin/dashboard', { token: editorToken });
  } catch (error) {
    revokedSessionStatus = error.status;
  }
  assert(
    revokedSessionStatus === 401,
    'Resetting a contributor password must revoke every existing session.',
  );
  const resetLogin = await api('/api/admin/auth/login', {
    method: 'POST',
    auth: false,
    body: { email: editor.data.email, password: resetPassword },
  });
  editorToken = resetLogin.data.token;

  const assignedNumber = 99980;
  const assignment = await api('/api/admin/assignments', {
    method: 'POST',
    token: ownerToken,
    body: {
      title: 'QA one-song assignment',
      instructions: 'Create and submit the assigned test song.',
      catalog: 'sda',
      versionKey: 'sda_new',
      startNumber: assignedNumber,
      endNumber: assignedNumber,
      assigneeId: editor.data.id,
    },
  });
  collaborationAssignmentIds.add(assignment.data.id);

  let outOfScopeStatus = null;
  try {
    await api('/api/admin/works?catalog=sda', {
      method: 'POST',
      token: editorToken,
      body: {
        defaultTitle: 'QA Out of Scope Song',
        canonicalLyrics: 'This record must never be created.',
        entries: [
          {
            version: 'sda_new',
            entryNumber: assignedNumber + 1,
            isActive: true,
          },
        ],
      },
    });
  } catch (error) {
    outOfScopeStatus = error.status;
  }
  assert(
    outOfScopeStatus === 403,
    'An editor must not create content outside the assigned scope.',
  );

  let invalidAssignmentStatus = null;
  try {
    await api('/api/admin/assignments', {
      method: 'POST',
      token: ownerToken,
      body: {
        title: 'QA invalid catalog assignment',
        catalog: 'hagerigna',
        versionKey: 'sda_new',
        categorySlug: 'marriage',
        assigneeId: editor.data.id,
      },
    });
  } catch (error) {
    invalidAssignmentStatus = error.status;
  }
  assert(
    invalidAssignmentStatus === 400,
    'Assignment versions and categories must belong to their selected catalog.',
  );

  let invalidAssigneeStatus = null;
  try {
    await api('/api/admin/assignments', {
      method: 'POST',
      token: ownerToken,
      body: {
        title: 'QA invalid reviewer assignment',
        catalog: 'sda',
        assigneeId: reviewer.data.id,
      },
    });
  } catch (error) {
    invalidAssigneeStatus = error.status;
  }
  assert(
    invalidAssigneeStatus === 400,
    'Scoped assignments must be given only to editor accounts.',
  );

  const created = await api('/api/admin/works?catalog=sda', {
    method: 'POST',
    token: editorToken,
    body: {
      defaultTitle: 'QA Reviewed Song',
      defaultEnglishTitle: 'QA Reviewed Song',
      canonicalLyrics: 'Temporary reviewed lyrics.',
      notes: 'Temporary collaboration workflow record.',
      entries: [
        {
          version: 'sda_new',
          entryNumber: assignedNumber,
          isActive: true,
        },
      ],
    },
  });
  sdaWorkIds.add(created.data.id);
  assert(
    created.data.collaboration.workflow.status === 'draft',
    'New assigned work must begin as a draft.',
  );

  const linked = await api(`/api/admin/works/${created.data.id}?catalog=sda`, {
    method: 'PATCH',
    token: ownerToken,
    body: {
      defaultTitle: created.data.defaultTitle,
      defaultEnglishTitle: created.data.defaultEnglishTitle,
      canonicalLyrics: created.data.canonicalLyrics,
      notes: created.data.notes,
      expectedUpdatedAt: created.data.updatedAt,
      entries: [
        ...created.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: false,
          isActive: entry.isActive,
        })),
        {
          version: 'sda_old',
          entryNumber: assignedNumber - 1,
          useOverrides: false,
          isActive: true,
        },
      ],
    },
  });
  const sharedEdit = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    {
      method: 'PATCH',
      token: editorToken,
      body: {
        defaultTitle: 'QA Reviewed Shared Song',
        defaultEnglishTitle: linked.data.defaultEnglishTitle,
        canonicalLyrics: 'Temporary reviewed lyrics updated by the editor.',
        notes: linked.data.notes,
        expectedUpdatedAt: linked.data.updatedAt,
        entries: linked.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: entry.hasContentOverrides,
          titleOverride: entry.titleOverride,
          englishTitleOverride: entry.englishTitleOverride,
          lyricsOverride: entry.lyricsOverride,
          artist: entry.metadata?.artist ?? null,
          isActive: entry.isActive,
        })),
      },
    },
  );
  assert(
    sharedEdit.data.defaultTitle === 'QA Reviewed Shared Song',
    'An assigned editor must be able to update shared canonical song content.',
  );

  let linkedMembershipStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}?catalog=sda`, {
      method: 'PATCH',
      token: editorToken,
      body: {
        defaultTitle: sharedEdit.data.defaultTitle,
        defaultEnglishTitle: sharedEdit.data.defaultEnglishTitle,
        canonicalLyrics: sharedEdit.data.canonicalLyrics,
        notes: sharedEdit.data.notes,
        expectedUpdatedAt: sharedEdit.data.updatedAt,
        entries: sharedEdit.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: entry.version === 'sda_old',
          titleOverride:
            entry.version === 'sda_old'
              ? 'This out-of-scope override must never win'
              : entry.titleOverride,
          englishTitleOverride: entry.englishTitleOverride,
          lyricsOverride: entry.lyricsOverride,
          artist: entry.metadata?.artist ?? null,
          isActive: entry.isActive,
        })),
      },
    });
  } catch (error) {
    linkedMembershipStatus = error.status;
  }
  assert(
    linkedMembershipStatus === 403,
    'An editor must not alter a linked hymnal membership outside the assignment.',
  );

  const submitted = await api(
    `/api/admin/works/${created.data.id}/submit?catalog=sda`,
    { method: 'POST', token: editorToken },
  );
  assert(
    submitted.data.collaboration.workflow.status === 'submitted',
    'An editor must be able to submit assigned work for review.',
  );

  let submittedLockStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}?catalog=sda`, {
      method: 'PATCH',
      token: editorToken,
      body: {
        defaultTitle: 'This submitted edit must never win',
        canonicalLyrics: 'Locked.',
        expectedUpdatedAt: sharedEdit.data.updatedAt,
        entries: sharedEdit.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: entry.hasContentOverrides,
          titleOverride: entry.titleOverride,
          englishTitleOverride: entry.englishTitleOverride,
          lyricsOverride: entry.lyricsOverride,
          artist: entry.metadata?.artist ?? null,
          isActive: entry.isActive,
        })),
      },
    });
  } catch (error) {
    submittedLockStatus = error.status;
  }
  assert(
    submittedLockStatus === 409,
    'Submitted content must remain locked until a reviewer acts.',
  );

  let editorReviewQueueStatus = null;
  try {
    await api('/api/admin/review-queue?catalog=sda&status=submitted', {
      token: editorToken,
    });
  } catch (error) {
    editorReviewQueueStatus = error.status;
  }
  assert(
    editorReviewQueueStatus === 403,
    'An editor must not be able to inspect the independent review queue.',
  );

  let reviewerEditStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}?catalog=sda`, {
      method: 'PATCH',
      token: reviewerToken,
      body: {
        defaultTitle: 'A reviewer must never write content',
        canonicalLyrics: sharedEdit.data.canonicalLyrics,
        expectedUpdatedAt: sharedEdit.data.updatedAt,
        entries: sharedEdit.data.entries,
      },
    });
  } catch (error) {
    reviewerEditStatus = error.status;
  }
  assert(
    reviewerEditStatus === 403,
    'A reviewer must be unable to edit song content.',
  );

  let editorMediaStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}/media?catalog=sda`, {
      method: 'POST',
      token: editorToken,
      body: {
        mediaType: 'audio',
        relationType: 'primary_audio',
        storageProvider: 'external',
        storageKey: `qa/forbidden/${created.data.id}.mp3`,
        publicUrl: 'https://example.test/forbidden-editor-media.mp3',
        mimeType: 'audio/mpeg',
        sortOrder: 0,
      },
    });
  } catch (error) {
    editorMediaStatus = error.status;
  }
  assert(
    editorMediaStatus === 403,
    'An editor must not mutate hidden reusable-media endpoints.',
  );

  const reviewerMedia = await api(
    `/api/admin/works/${created.data.id}/media?catalog=sda`,
    {
      method: 'POST',
      token: reviewerToken,
      body: {
        mediaType: 'sheet_music',
        relationType: 'primary_sheet_music',
        storageProvider: 'external',
        storageKey: `qa/reviewer/${created.data.id}.webp`,
        publicUrl: 'https://example.test/reviewer-sheet-music.webp',
        mimeType: 'image/webp',
        sortOrder: 0,
      },
    },
  );
  assert(
    reviewerMedia.data.relationType === 'primary_sheet_music',
    'A reviewer must be able to manage reusable media without editing song text.',
  );
  const reviewerMediaDetail = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    { token: reviewerToken },
  );
  assert(
    reviewerMediaDetail.data.media.some(
      (item) => item.id === reviewerMedia.data.id,
    ) &&
      reviewerMediaDetail.data.collaboration.workflow.status === 'submitted' &&
      reviewerMediaDetail.data.collaboration.workflow.revision ===
        submitted.data.collaboration.workflow.revision,
    'Reviewer media changes must be visible without mutating the submitted content revision.',
  );
  await api(
    `/api/admin/works/${created.data.id}/media/${reviewerMedia.data.id}?catalog=sda`,
    { method: 'DELETE', token: reviewerToken },
  );

  const reviewQueue = await api(
    '/api/admin/review-queue?catalog=sda&status=submitted',
    { token: reviewerToken },
  );
  assert(
    reviewQueue.data.some((item) => item.workId === created.data.id),
    'The dedicated reviewer queue must include the submitted song.',
  );

  const submittedDetail = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    { token: reviewerToken },
  );
  assert(
    Object.keys(
      submittedDetail.data.collaboration.workflow.baselineSnapshot,
    ).length === 0 &&
      submittedDetail.data.collaboration.workflow.submittedSnapshot
        .defaultTitle === sharedEdit.data.defaultTitle,
    'A new submission must expose an empty baseline and an exact submitted snapshot.',
  );

  let staleReviewStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}/review?catalog=sda`, {
      method: 'POST',
      token: reviewerToken,
      body: {
        decision: 'approved',
        expectedRevision:
          submitted.data.collaboration.workflow.revision + 1,
        confirmed: true,
      },
    });
  } catch (error) {
    staleReviewStatus = error.status;
  }
  assert(
    staleReviewStatus === 409,
    'A reviewer must not approve a revision other than the one displayed.',
  );

  let unconfirmedReviewStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}/review?catalog=sda`, {
      method: 'POST',
      token: reviewerToken,
      body: {
        decision: 'approved',
        expectedRevision: submitted.data.collaboration.workflow.revision,
      },
    });
  } catch (error) {
    unconfirmedReviewStatus = error.status;
  }
  assert(
    unconfirmedReviewStatus === 400,
    'Approval must require an explicit confirmation for the displayed revision.',
  );

  const initialApproval = await api(
    `/api/admin/works/${created.data.id}/review?catalog=sda`,
    {
      method: 'POST',
      token: reviewerToken,
      body: {
        decision: 'approved',
        summary: 'QA approval.',
        expectedRevision: submitted.data.collaboration.workflow.revision,
        confirmed: true,
      },
    },
  );
  assert(
    initialApproval.data.collaboration.workflow.status === 'approved',
    'A reviewer must be able to approve submitted work.',
  );

  const approvedDetail = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    { token: ownerToken },
  );
  assert(
    approvedDetail.data.collaboration.workflow.submittedSnapshot.defaultTitle ===
      sharedEdit.data.defaultTitle,
    'Approval history must preserve the exact submitted snapshot.',
  );

  const secondRevision = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    {
      method: 'PATCH',
      token: ownerToken,
      body: {
        defaultTitle: 'QA Reviewed Shared Song Revision Two',
        defaultEnglishTitle: approvedDetail.data.defaultEnglishTitle,
        canonicalLyrics: `${approvedDetail.data.canonicalLyrics}\nSecond approved revision.`,
        notes: approvedDetail.data.notes,
        expectedUpdatedAt: approvedDetail.data.updatedAt,
        entries: approvedDetail.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: entry.hasContentOverrides,
          titleOverride: entry.titleOverride,
          englishTitleOverride: entry.englishTitleOverride,
          lyricsOverride: entry.lyricsOverride,
          artist: entry.metadata?.artist ?? null,
          isActive: entry.isActive,
        })),
      },
    },
  );
  const ownerSubmission = await api(
    `/api/admin/works/${created.data.id}/submit?catalog=sda`,
    { method: 'POST', token: ownerToken },
  );

  let selfReviewStatus = null;
  try {
    await api(`/api/admin/works/${created.data.id}/review?catalog=sda`, {
      method: 'POST',
      token: ownerToken,
      body: {
        decision: 'approved',
        expectedRevision:
          ownerSubmission.data.collaboration.workflow.revision,
        confirmed: true,
      },
    });
  } catch (error) {
    selfReviewStatus = error.status;
  }
  assert(
    selfReviewStatus === 409,
    'An owner must not approve a revision they edited or submitted.',
  );

  const approved = await api(
    `/api/admin/works/${created.data.id}/review?catalog=sda`,
    {
      method: 'POST',
      token: reviewerToken,
      body: {
        decision: 'approved',
        summary: 'QA second-revision approval.',
        expectedRevision:
          ownerSubmission.data.collaboration.workflow.revision,
        confirmed: true,
      },
    },
  );
  const finalDetail = await api(
    `/api/admin/works/${created.data.id}?catalog=sda`,
    { token: reviewerToken },
  );
  assert(
    finalDetail.data.collaboration.workflow.baselineSnapshot.defaultTitle ===
      sharedEdit.data.defaultTitle &&
      finalDetail.data.collaboration.workflow.submittedSnapshot.defaultTitle ===
        secondRevision.data.defaultTitle,
    'Approved history must retain distinct baseline and submitted snapshots.',
  );

  const release = await api('/api/admin/releases', {
    method: 'POST',
    token: ownerToken,
    body: {
      versionLabel: `QA collaboration ${suffix}`,
      description: 'Temporary immutable release integration test.',
    },
  });
  collaborationReleaseIds.add(release.data.id);

  let editorReleaseListStatus = null;
  try {
    await api('/api/admin/releases', { token: editorToken });
  } catch (error) {
    editorReleaseListStatus = error.status;
  }
  assert(
    editorReleaseListStatus === 403,
    'An editor must not be able to list release archives.',
  );

  let reviewerReleaseDownloadStatus = null;
  try {
    await api(`/api/admin/releases/${release.data.id}/download`, {
      token: reviewerToken,
    });
  } catch (error) {
    reviewerReleaseDownloadStatus = error.status;
  }
  assert(
    reviewerReleaseDownloadStatus === 403,
    'A reviewer must not be able to download release archives.',
  );

  const activated = await api(
    `/api/admin/releases/${release.data.id}/activate`,
    { method: 'POST', token: ownerToken },
  );
  assert(activated.data.isCurrent, 'An owner must be able to activate a release.');

  const download = await fetch(
    `${apiOrigin}/api/admin/releases/${release.data.id}/download`,
    { headers: { authorization: `Bearer ${ownerToken}` } },
  );
  const archive = Buffer.from(await download.arrayBuffer());
  assert(
    download.ok &&
      download.headers.get('content-type') === 'application/zip' &&
      archive.subarray(0, 4).equals(Buffer.from([0x50, 0x4b, 0x03, 0x04])),
    'Release download must be a valid ZIP archive.',
  );

  let immutableStatus = null;
  try {
    await controlDb.contentRelease.update({
      where: { id: release.data.id },
      data: { description: 'This immutable edit must fail.' },
    });
  } catch (error) {
    immutableStatus = error.code ?? 'database_error';
  }
  assert(
    immutableStatus !== null,
    'The database must reject changes to an immutable release payload.',
  );

  return {
    individualSessions: true,
    revokedSessionStatus,
    invalidAssignmentStatus,
    invalidAssigneeStatus,
    outOfScopeStatus,
    linkedMembershipStatus,
    submittedLockStatus,
    editorReviewQueueStatus,
    reviewerEditStatus,
    staleReviewStatus,
    unconfirmedReviewStatus,
    selfReviewStatus,
    approvedStatus: approved.data.collaboration.workflow.status,
    editorReleaseListStatus,
    reviewerReleaseDownloadStatus,
    releaseBytes: archive.length,
    releaseChecksum: release.data.checksumSha256,
    immutableRelease: true,
  };
};

const exerciseContentStudio = async () => {
  const editorPage = await fetch(`${apiOrigin}/admin/content`);
  const editorHtml = await editorPage.text();
  assert(
    editorPage.ok &&
      editorHtml.includes('id="auth-form"') &&
      editorHtml.includes('/admin/assets/content-studio.css') &&
      editorHtml.includes('/admin/assets/content-studio.js'),
    'Content Studio HTML must load its authentication form and static assets.',
  );
  for (const [assetPath, contentType] of [
    ['/admin/assets/content-studio.css', 'text/css'],
    ['/admin/assets/content-studio.js', 'text/javascript'],
    ['/admin/assets/NotoSansEthiopic-Regular.ttf', 'font/ttf'],
  ]) {
    const asset = await fetch(`${apiOrigin}${assetPath}`);
    assert(
      asset.ok && asset.headers.get('content-type')?.startsWith(contentType),
      `Content Studio asset ${assetPath} must load with ${contentType}.`,
    );
  }

  const reviewPage = await fetch(`${apiOrigin}/admin/review`);
  const reviewHtml = await reviewPage.text();
  assert(
    reviewPage.ok &&
      reviewHtml.includes('id="auth-form"') &&
      reviewHtml.includes('id="review-workspace"') &&
      reviewHtml.includes('/admin/assets/review-console.css') &&
      reviewHtml.includes('/admin/assets/review-console.js'),
    'Review Console HTML must load its authentication and review workspace.',
  );
  for (const [assetPath, contentType] of [
    ['/admin/assets/review-console.css', 'text/css'],
    ['/admin/assets/review-console.js', 'text/javascript'],
  ]) {
    const asset = await fetch(`${apiOrigin}${assetPath}`);
    assert(
      asset.ok && asset.headers.get('content-type')?.startsWith(contentType),
      `Review Console asset ${assetPath} must load with ${contentType}.`,
    );
  }
  const reviewJavascript = await (
    await fetch(`${apiOrigin}/admin/assets/review-console.js`)
  ).text();
  const contentJavascript = await (
    await fetch(`${apiOrigin}/admin/assets/content-studio.js`)
  ).text();
  assert(
    reviewJavascript.includes("'Media review'") &&
      reviewJavascript.includes('manageMedia') &&
      reviewHtml.includes('data-workspace="media"') &&
      !contentJavascript.includes('data-tab="media"') &&
      !contentJavascript.includes('Reusable media'),
    'Media management must stay in the Review Console and out of Content Studio.',
  );

  const unauthorized = await fetch(`${apiOrigin}/api/admin/dashboard`);
  assert(
    unauthorized.status === 401,
    'Admin dashboard must reject requests without a token.',
  );

  const hostileOrigin = await fetch(`${apiOrigin}/api/admin/dashboard`, {
    headers: {
      origin: 'https://hostile.example.test',
      'x-admin-token': adminToken,
    },
  });
  assert(
    hostileOrigin.status === 403,
    'Admin requests from an untrusted browser origin must be rejected.',
  );

  let loginRateLimitStatus = null;
  for (let attempt = 0; attempt < 10; attempt += 1) {
    const failedLogin = await fetch(`${apiOrigin}/api/admin/auth/login`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({
        email: 'unknown-user@example.test',
        password: 'IncorrectPassword!2026',
      }),
    });
    if (failedLogin.status === 429) {
      loginRateLimitStatus = 429;
      break;
    }
  }
  assert(
    loginRateLimitStatus === 429,
    'Repeated failed logins must be throttled.',
  );

  const dashboard = await api('/api/admin/dashboard');
  assert(
    dashboard.data.catalogs.length === 2,
    'Dashboard must return both catalogs.',
  );
  assert(
    dashboard.data.catalogs.every((catalog) => catalog.available),
    'Both local content databases must be available.',
  );

  const publicVersions = await api('/api/versions', { auth: false });
  const edition1974 = publicVersions.data.find(
    (version) => version.id === 'sda_old',
  );
  assert(
    edition1974?.publication_year === 1974,
    'The corrected SDA old edition must be published as 1974.',
  );
  assert(
    publicVersions.data.some((version) => version.id === 'sda_1960'),
    'The 1960 SDA edition must be discoverable by the app.',
  );
  const public1960 = await api(
    '/api/hymns?language=am&version=sda_1960',
    { auth: false },
  );
  assert(
    Array.isArray(public1960.data) &&
      public1960.data.every(
        (hymn) => hymn.title !== 'የሙከራ መዝሙር',
      ),
    'The 1960 SDA edition must not expose the legacy placeholder song.',
  );

  const edition1960Work = await createSdaEntry(
    'sda_1960',
    99993,
    'QA Integration 1960 Entry',
  );
  const public1960AfterCreate = await api(
    '/api/hymns?language=am&version=sda_1960',
    { auth: false },
  );
  assert(
    public1960AfterCreate.data.some(
      (hymn) =>
        hymn.id === edition1960Work.id &&
        hymn.number === 99993 &&
        hymn.title === 'QA Integration 1960 Entry',
    ),
    'A song added to the 1960 edition must immediately reach the Flutter API.',
  );

  const newWork = await createSdaEntry(
    'sda_new',
    99991,
    'QA Integration New Entry',
  );
  const oldWork = await createSdaEntry(
    'sda_old',
    99992,
    'QA Integration Old Entry',
  );
  const merged = await api(`/api/admin/works/${newWork.id}/merge?catalog=sda`, {
    method: 'POST',
    body: {
      sourceWorkId: oldWork.id,
      expectedUpdatedAt: newWork.updatedAt,
    },
  });
  assert(
    merged.data.entries.length === 2,
    'SDA merge must produce two linked edition entries.',
  );

  const updated = await api(`/api/admin/works/${newWork.id}?catalog=sda`, {
    method: 'PATCH',
    body: {
      defaultTitle: 'QA Integration Linked Song',
      defaultEnglishTitle: 'QA Integration Shared Song',
      canonicalLyrics: 'Synchronized QA lyrics.',
      notes: 'Temporary automated test record after merge.',
      expectedUpdatedAt: merged.data.updatedAt,
      entries: merged.data.entries.map((entry) => ({
        id: entry.id,
        version: entry.version,
        entryNumber: entry.entryNumber,
        useOverrides: false,
        isActive: true,
      })),
    },
  });
  assert(
    updated.data.hasSharedLyrics,
    'Shared SDA lyrics must remain synchronized.',
  );
  assert(
    updated.data.entries.every((entry) => !entry.hasContentOverrides),
    'Reused SDA memberships must not duplicate canonical content.',
  );

  let staleEditRejected = false;
  try {
    await api(`/api/admin/works/${newWork.id}?catalog=sda`, {
      method: 'PATCH',
      body: {
        defaultTitle: 'This stale edit must never win',
        defaultEnglishTitle: 'Stale edit',
        canonicalLyrics: 'Stale lyrics.',
        notes: 'Stale automated request.',
        expectedUpdatedAt: merged.data.updatedAt,
        entries: updated.data.entries.map((entry) => ({
          id: entry.id,
          version: entry.version,
          entryNumber: entry.entryNumber,
          useOverrides: false,
          isActive: true,
        })),
      },
    });
  } catch (error) {
    staleEditRejected = error.status === 409;
  }
  assert(
    staleEditRejected,
    'A stale editor must receive a conflict instead of overwriting newer content.',
  );

  const [publicNewAfterEdit, publicOldAfterEdit] = await Promise.all([
    api('/api/hymns?language=am&version=sda_new', { auth: false }),
    api('/api/hymns?language=am&version=sda_old', { auth: false }),
  ]);
  const editedNewSong = publicNewAfterEdit.data.find(
    (song) => song.number === 99991,
  );
  const editedOldSong = publicOldAfterEdit.data.find(
    (song) => song.number === 99992,
  );
  assert(
    editedNewSong?.title === 'QA Integration Linked Song' &&
      editedOldSong?.title === 'QA Integration Linked Song',
    'Admin title edits must immediately reach every linked Flutter edition.',
  );
  assert(
    editedNewSong?.lyrics === 'Synchronized QA lyrics.' &&
      editedOldSong?.lyrics === 'Synchronized QA lyrics.',
    'Admin lyric edits must immediately reach the Flutter content API.',
  );
  assert(
    editedNewSong?.id === editedOldSong?.id &&
      editedNewSong?.new_hymnal_number === 99991 &&
      editedNewSong?.old_hymnal_number === 99992,
    'Linked editions must expose one reusable song with both hymn numbers.',
  );

  const futureVersionKey = `sda_qa_${Date.now()}`;
  const futureEdition = await api('/api/admin/editions?catalog=sda', {
    method: 'POST',
    body: {
      versionKey: futureVersionKey,
      title: 'QA Future SDA Hymnal',
      nativeTitle: 'የQA ወደፊት ውዳሴ መዝሙር',
      publicationYear: 2019,
      status: 'draft',
      copyFromVersion: 'sda_new',
    },
  });
  sdaEditionIds.add(futureEdition.data.editionId);
  assert(
    futureEdition.data.entryCount >= 1,
    'A future hymnal must be able to reuse memberships from an existing edition.',
  );
  const futureWork = await api(
    `/api/admin/works/${newWork.id}?catalog=sda`,
  );
  const futureMembership = futureWork.data.entries.find(
    (entry) => entry.version === futureVersionKey,
  );
  assert(
    futureMembership && !futureMembership.hasContentOverrides,
    'Copied future membership must inherit canonical song content.',
  );
  const versionsBeforePublish = await api('/api/versions', {
    auth: false,
  });
  assert(
    !versionsBeforePublish.data.some(
      (version) => version.id === futureVersionKey,
    ),
    'Draft hymnals must not be advertised to the public app.',
  );
  const draftResponse = await fetch(
    `${apiOrigin}/api/hymns?language=am&version=${futureVersionKey}`,
  );
  assert(
    draftResponse.status === 400,
    'Draft hymnal content must remain unavailable from the public API.',
  );
  await api(
    `/api/admin/editions/${futureEdition.data.editionId}?catalog=sda`,
    {
      method: 'PATCH',
      body: {
        title: 'QA Future SDA Hymnal',
        nativeTitle: 'የQA ወደፊት ውዳሴ መዝሙር',
        publicationYear: 2019,
        status: 'published',
      },
    },
  );
  const versionsAfterPublish = await api('/api/versions', {
    auth: false,
  });
  assert(
    versionsAfterPublish.data.some(
      (version) => version.id === futureVersionKey,
    ),
    'Published future hymnal must be discoverable by the app.',
  );
  const futurePublic = await api(
    `/api/hymns?language=am&version=${futureVersionKey}`,
    { auth: false },
  );
  assert(
    futurePublic.data.some((song) => song.number === 99991),
    'A dynamically created hymnal must work through the public content API.',
  );
  const afterRemoval = await api(
    `/api/admin/works/${newWork.id}/memberships/${futureMembership.id}?catalog=sda`,
    {
      method: 'DELETE',
      body: { expectedUpdatedAt: futureWork.data.updatedAt },
    },
  );
  assert(
    !afterRemoval.data.entries.some(
      (entry) => entry.version === futureVersionKey,
    ),
    'Removing a future membership must not remove the canonical song.',
  );

  await api(`/api/admin/works/${newWork.id}/media?catalog=sda`, {
    method: 'POST',
    body: {
      mediaType: 'audio',
      relationType: 'primary_audio',
      storageProvider: 'external',
      storageKey: `qa/audio/${newWork.id}.mp3`,
      publicUrl: 'https://example.test/wudase-qa.mp3',
      mimeType: 'audio/mpeg',
      sortOrder: 0,
    },
  });
  const publicSda = await api(
    '/api/hymns?language=am&version=sda_new',
    { auth: false },
  );
  const publicSdaSong = publicSda.data.find((song) => song.number === 99991);
  assert(
    publicSdaSong?.audio === 'https://example.test/wudase-qa.mp3',
    'Public SDA API must expose managed audio.',
  );

  const hagerigna = await api('/api/admin/works?catalog=hagerigna', {
    method: 'POST',
    body: {
      defaultTitle: 'QA Hagerigna Song',
      canonicalLyrics: 'Temporary Hagerigna lyrics.',
      notes: 'Temporary automated test record.',
      entries: [
        {
          version: 'hagerigna',
          entryNumber: 99991,
          artist: 'QA Artist',
          isActive: true,
        },
      ],
    },
  });
  hagerignaWorkIds.add(hagerigna.data.id);
  const publicHagerigna = await api(
    '/api/hymns?language=am&version=hagerigna',
    { auth: false },
  );
  const publicHagerignaSong = publicHagerigna.data.find(
    (song) => song.number === 99991,
  );
  assert(
    publicHagerignaSong?.artist === 'QA Artist',
    'Public Hagerigna API must expose managed artist metadata.',
  );

  const audit = await api(
    `/api/admin/audit?catalog=sda&workId=${newWork.id}`,
  );
  assert(
    audit.data.length >= 4,
    'SDA changes must produce create, merge, update, and media audit records.',
  );

  return {
    editorAssets: true,
    reviewConsoleAssets: true,
    unauthorizedAdminRejected: true,
    hostileOriginRejected: true,
    loginRateLimitStatus,
    staleEditRejected,
    dashboardCatalogs: dashboard.data.catalogs.length,
    linkedSdaEntries: updated.data.entries.length,
    sharedLyrics: updated.data.hasSharedLyrics,
    flutterFacingEdit: editedNewSong.title,
    futureEditionReusedSongs: futureEdition.data.entryCount,
    futureEditionPublished: true,
    futureMembershipRemoved: true,
    publicAudio: publicSdaSong.audio,
    hagerignaArtist: publicHagerignaSong.artist,
    auditRecords: audit.data.length,
  };
};

const cleanupEditions = (database, editionIds) => {
  if (editionIds.size === 0) return;
  const ids = [...editionIds]
    .map((id) => `'${id}'::uuid`)
    .join(', ');
  run(psql, [
    '-v',
    'ON_ERROR_STOP=1',
    '-h',
    '127.0.0.1',
    '-p',
    '55432',
    '-U',
    'postgres',
    '-d',
    database,
    '-c',
    `
      begin;
      delete from content_audit_logs where entity_id in (${ids});
      delete from book_editions where id in (${ids});
      commit;
    `,
  ]);
};

const cleanupDatabase = (database, workIds) => {
  if (workIds.size === 0) return;
  const ids = [...workIds]
    .map((id) => `'${id}'::uuid`)
    .join(', ');
  const sql = `
    begin;
    delete from content_audit_logs where work_id in (${ids});
    delete from media_links where work_id in (${ids});
    delete from media_assets
      where storage_key like 'qa/audio/%'
        and not exists (
          select 1 from media_links where media_asset_id = media_assets.id
        );
    delete from book_entries where work_id in (${ids});
    delete from works where id in (${ids});
    commit;
  `;
  run(psql, [
    '-v',
    'ON_ERROR_STOP=1',
    '-h',
    '127.0.0.1',
    '-p',
    '55432',
    '-U',
    'postgres',
    '-d',
    database,
    '-c',
    sql,
  ]);
};

const cleanupControlMetadata = () => {
  const workIds = [...new Set([...sdaWorkIds, ...hagerignaWorkIds])];
  if (workIds.length === 0) return;
  const uuidIds = workIds.map((id) => `'${id}'::uuid`).join(', ');
  const textIds = workIds.map((id) => `'${id}'`).join(', ');
  run(psql, [
    '-v',
    'ON_ERROR_STOP=1',
    '-h',
    '127.0.0.1',
    '-p',
    '55432',
    '-U',
    'postgres',
    '-d',
    'wudase_sda_dev',
    '-c',
    `
      begin;
      delete from content_comments where work_id in (${uuidIds});
      delete from content_workflows where work_id in (${uuidIds});
      delete from content_activity_logs
        where entity_type = 'work' and entity_id in (${textIds});
      commit;
    `,
  ]);
};

const cleanupCollaborationFixtures = async () => {
  if (!controlDb) return;
  const userIds = [...collaborationUserIds];
  const assignmentIds = [...collaborationAssignmentIds];
  const releaseIds = [...collaborationReleaseIds];
  const workIds = [...new Set([...sdaWorkIds, ...hagerignaWorkIds])];
  await controlDb.$transaction(async (tx) => {
    if (releaseIds.length > 0) {
      await tx.contentRelease.deleteMany({ where: { id: { in: releaseIds } } });
    }
    if (assignmentIds.length > 0) {
      await tx.contentAssignment.deleteMany({
        where: { id: { in: assignmentIds } },
      });
    }
    const entityIds = [
      ...userIds,
      ...assignmentIds,
      ...releaseIds,
      ...workIds,
    ];
    if (entityIds.length > 0 || userIds.length > 0) {
      await tx.contentActivityLog.deleteMany({
        where: {
          OR: [
            ...(entityIds.length > 0 ? [{ entityId: { in: entityIds } }] : []),
            ...(userIds.length > 0
              ? [{ actorUserId: { in: userIds } }]
              : []),
          ],
        },
      });
    }
    if (userIds.length > 0) {
      await tx.contentUser.deleteMany({ where: { id: { in: userIds } } });
    }
  });
};

const stopProcesses = () => {
  if (apiProcess?.exitCode === null) apiProcess.kill();
  if (ownsPostgres && existsSync(pidFile)) {
    const stopped = spawnSync(
      pgCtl,
      ['stop', '-D', pgData, '-m', 'fast', '-w'],
      { windowsHide: true, encoding: 'utf8' },
    );
    if (stopped.status !== 0 && postgresProcess?.exitCode === null) {
      postgresProcess.kill();
    }
  }
  ownsPostgres = false;
};

try {
  await startPostgres();
  const databaseNames = migrateDatabases();
  await seedCollaborationOwner();
  await startApi();
  const collaborationResult = await exerciseCollaborationWorkflow();
  const result = await exerciseContentStudio();
  console.log(
    JSON.stringify(
      {
        databases: databaseNames.filter((name) => name.startsWith('wudase_')),
        collaboration: collaborationResult,
        ...result,
      },
      null,
      2,
    ),
  );
} finally {
  try {
    cleanupControlMetadata();
    cleanupDatabase('wudase_sda_dev', sdaWorkIds);
    cleanupDatabase('wudase_hagerigna_dev', hagerignaWorkIds);
    cleanupEditions('wudase_sda_dev', sdaEditionIds);
    await cleanupCollaborationFixtures();
  } finally {
    await controlDb?.$disconnect().catch(() => {});
    stopProcesses();
  }
}
