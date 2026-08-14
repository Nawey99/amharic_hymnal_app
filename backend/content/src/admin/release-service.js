import { randomUUID } from 'node:crypto';

import { AdminError, cleanText } from './domain.js';
import { createZip, jsonFile, sha256 } from './release-files.js';

const serializeRelease = (release) => ({
  id: release.id,
  releaseKey: release.releaseKey,
  versionLabel: release.versionLabel,
  description: release.description,
  publishedAt: release.publishedAt,
  isCurrent: release.isCurrent,
  schemaVersion: release.schemaVersion,
  createdById: release.createdById,
  createdByName: release.createdByName,
  checksumSha256: release.checksumSha256,
  manifest: release.manifest,
  metadata: release.metadata,
  createdAt: release.createdAt,
});

const fileRecord = (path, body, count = null) => {
  const buffer = jsonFile(body);
  return {
    path,
    body,
    bytes: buffer.length,
    checksumSha256: sha256(buffer),
    count,
  };
};

const releaseKeyFor = (label) => {
  const date = new Date().toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
  const slug = String(label ?? '')
    .normalize('NFKD')
    .replace(/[^a-zA-Z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .toLowerCase()
    .slice(0, 40);
  return `${date}-${slug || randomUUID().slice(0, 8)}`;
};

export const createReleaseService = ({
  controlDb,
  getVersions,
  getHymns,
  getCategories,
  getMediaManifest,
  recordActivity,
  withPublicationLock = (action) => action(),
}) => {
  const list = async () => {
    const releases = await controlDb.contentRelease.findMany({
      orderBy: { createdAt: 'desc' },
      take: 100,
    });
    return releases.map(serializeRelease);
  };

  const get = async (id) => {
    const release = await controlDb.contentRelease.findUnique({
      where: { id },
    });
    if (!release) {
      throw new AdminError(404, 'release_not_found', 'Release was not found.');
    }
    return release;
  };

  const buildUnlocked = async (actor, input) => {
    if (!actor?.permissions?.createReleases || !actor.id) {
      throw new AdminError(
        403,
        'forbidden',
        'Only an owner account can create releases.',
      );
    }
    const versionLabel = cleanText(input.versionLabel, 'versionLabel', {
      required: true,
      maxLength: 120,
    });
    const description = cleanText(input.description, 'description', {
      maxLength: 2000,
    });
    const [versions, blockedWorkflows] = await Promise.all([
      getVersions(),
      controlDb.contentWorkflow.findMany({
        where: { status: { not: 'approved' } },
        select: { catalog: true, workId: true, status: true },
      }),
    ]);
    if (blockedWorkflows.length > 0) {
      const counts = blockedWorkflows.reduce((result, workflow) => {
        result[workflow.status] = (result[workflow.status] ?? 0) + 1;
        return result;
      }, {});
      throw new AdminError(
        409,
        'unapproved_content',
        'Finish or approve every edited song before creating a release.',
        { counts, total: blockedWorkflows.length },
      );
    }
    const excluded = {
      sda: new Set(),
      hagerigna: new Set(),
    };
    for (const workflow of blockedWorkflows) {
      excluded[workflow.catalog]?.add(workflow.workId);
    }

    const files = [
      fileRecord('api/versions.json', { data: versions }, versions.length),
    ];
    const releaseCounts = {};
    for (const version of versions) {
      const catalog = version.catalog === 'hagerigna' ? 'hagerigna' : 'sda';
      const [hymns, categories] = await Promise.all([
        getHymns(version.id, excluded[catalog]),
        getCategories(version.id),
      ]);
      files.push(
        fileRecord(
          `api/hymns/${version.id}.json`,
          { data: hymns },
          hymns.length,
        ),
        fileRecord(
          `api/categories/${version.id}.json`,
          { data: categories },
          categories.length,
        ),
      );
      releaseCounts[version.id] = {
        hymns: hymns.length,
        categories: categories.length,
      };
    }
    const mediaManifest = await getMediaManifest(excluded);
    files.push(
      fileRecord(
        'media/manifest.json',
        { data: mediaManifest },
        mediaManifest.length,
      ),
    );
    releaseCounts.media = mediaManifest.length;

    const createdAt = new Date();
    const releaseKey = releaseKeyFor(versionLabel);
    const bundle = Object.fromEntries(
      files.map((file) => [file.path, file.body]),
    );
    const bundleChecksum = sha256(jsonFile(bundle));
    const manifest = {
      schemaVersion: 1,
      releaseKey,
      versionLabel,
      createdAt: createdAt.toISOString(),
      createdBy: {
        id: actor.id,
        displayName: actor.displayName,
        email: actor.email,
      },
      checksumSha256: bundleChecksum,
      counts: releaseCounts,
      excludedUnapprovedWorks: {
        sda: excluded.sda.size,
        hagerigna: excluded.hagerigna.size,
      },
      files: files.map(({ path, bytes, checksumSha256, count }) => ({
        path,
        bytes,
        checksumSha256,
        count,
      })),
    };
    const release = await controlDb.contentRelease.create({
      data: {
        releaseKey,
        versionLabel,
        description,
        publishedAt: createdAt,
        isCurrent: false,
        schemaVersion: 1,
        createdById: actor.id,
        createdByName: `${actor.displayName} <${actor.email}>`,
        checksumSha256: bundleChecksum,
        manifest,
        bundle,
        metadata: {
          immutable: true,
          format: 'wudase-content-release',
        },
      },
    });
    await recordActivity(
      actor,
      'release_create',
      'content_release',
      release.id,
      {
        releaseKey,
        checksumSha256: bundleChecksum,
        counts: releaseCounts,
      },
    );
    return serializeRelease(release);
  };

  const build = (actor, input) =>
    withPublicationLock(() => buildUnlocked(actor, input));

  const activate = async (actor, id) => {
    if (!actor?.permissions?.createReleases || !actor.id) {
      throw new AdminError(
        403,
        'forbidden',
        'Only an owner account can activate releases.',
      );
    }
    await get(id);
    const release = await controlDb.$transaction(async (tx) => {
      await tx.contentRelease.updateMany({
        where: { isCurrent: true },
        data: { isCurrent: false },
      });
      return tx.contentRelease.update({
        where: { id },
        data: { isCurrent: true },
      });
    });
    await recordActivity(
      actor,
      'release_activate',
      'content_release',
      release.id,
      { releaseKey: release.releaseKey },
    );
    return serializeRelease(release);
  };

  const current = async () => {
    const release = await controlDb.contentRelease.findFirst({
      where: { isCurrent: true },
    });
    return release;
  };

  const currentFile = async (path) => {
    const release = await current();
    if (!release) {
      throw new AdminError(
        503,
        'release_unavailable',
        'No approved content release is active.',
      );
    }
    const file = release.bundle?.[path];
    if (!file) {
      throw new AdminError(
        404,
        'release_file_not_found',
        'The requested content is not present in the active release.',
      );
    }
    return file;
  };

  const download = async (id) => {
    const release = await get(id);
    const manifest = release.manifest ?? {};
    const files = [
      { name: 'manifest.json', data: jsonFile(manifest) },
      ...Object.entries(release.bundle ?? {}).map(([name, body]) => ({
        name,
        data: jsonFile(body),
      })),
      {
        name: 'README.txt',
        data:
          'Wudase Content Release\r\n\r\n' +
          `Release: ${release.versionLabel}\r\n` +
          `Key: ${release.releaseKey}\r\n` +
          `SHA-256: ${release.checksumSha256}\r\n\r\n` +
          'The api/ directory mirrors the Flutter-facing content API. Keep manifest.json with these files so checksums can be verified before a build.\r\n',
      },
    ];
    return {
      filename: `wudase-content-${release.releaseKey}.zip`,
      buffer: createZip(files, release.createdAt),
    };
  };

  return { list, get, build, activate, current, currentFile, download };
};
