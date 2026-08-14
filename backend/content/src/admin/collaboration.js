import {
  createHash,
  randomBytes,
  scrypt as scryptCallback,
  timingSafeEqual,
} from 'node:crypto';
import { promisify } from 'node:util';

import { AdminError, cleanText, getCatalogDefinition } from './domain.js';

const scrypt = promisify(scryptCallback);
const roles = new Set(['owner', 'reviewer', 'editor']);
const assignmentStatuses = new Set(['active', 'completed', 'cancelled']);
const workflowStatuses = new Set([
  'draft',
  'submitted',
  'changes_requested',
  'approved',
]);
const sessionPrefix = 'wcs_';
const dummyPasswordHash =
  'scrypt$1786d901302368268f45b60176ca5e0d$' +
  '17945b02f64886f72d0f866a79c174658b2f1cc1bb59096f777a7a37c298881f' +
  '74b331587ee665599f5cfb92bdaefcb37db964279332b6c9e0a8f50ccab4b055';

const sha256 = (value) =>
  createHash('sha256').update(String(value)).digest('hex');

const secureTextEquals = (left, right) => {
  if (!left || !right) return false;
  const leftDigest = createHash('sha256').update(String(left)).digest();
  const rightDigest = createHash('sha256').update(String(right)).digest();
  return timingSafeEqual(leftDigest, rightDigest);
};

const normalizedEmail = (value) => {
  const email = String(value ?? '').trim().toLowerCase();
  if (
    email.length > 254 ||
    !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
  ) {
    throw new AdminError(
      400,
      'invalid_email',
      'Enter a valid email address.',
    );
  }
  return email;
};

const checkedPassword = (value) => {
  const password = String(value ?? '');
  if (password.length < 12 || password.length > 200) {
    throw new AdminError(
      400,
      'weak_password',
      'Passwords must be between 12 and 200 characters.',
    );
  }
  return password;
};

export const hashPassword = async (value) => {
  const password = checkedPassword(value);
  const salt = randomBytes(16).toString('hex');
  const derived = await scrypt(password, salt, 64);
  return `scrypt$${salt}$${Buffer.from(derived).toString('hex')}`;
};

export const verifyPassword = async (value, encoded) => {
  const [scheme, salt, digest] = String(encoded ?? '').split('$');
  if (scheme !== 'scrypt' || !salt || !/^[a-f0-9]{128}$/.test(digest ?? '')) {
    return false;
  }
  const derived = Buffer.from(await scrypt(String(value ?? ''), salt, 64));
  return timingSafeEqual(derived, Buffer.from(digest, 'hex'));
};

const serializeUser = (user) => ({
  id: user.id,
  email: user.email,
  displayName: user.displayName,
  role: user.role,
  isActive: user.isActive,
  lastLoginAt: user.lastLoginAt,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const permissionsFor = (role, legacy = false) => ({
  manageUsers: role === 'owner' && !legacy,
  manageAssignments: role === 'owner' && !legacy,
  review: ['owner', 'reviewer'].includes(role),
  manageMedia: role === 'owner' || (role === 'reviewer' && !legacy),
  manageEditions: role === 'owner',
  createReleases: role === 'owner' && !legacy,
  editAllContent: role === 'owner',
});

const publicActor = (user, legacy = false) => ({
  ...serializeUser(user),
  legacy,
  permissions: permissionsFor(user.role, legacy),
});

const assertRole = (actor, allowed, message) => {
  if (!actor || !allowed.includes(actor.role)) {
    throw new AdminError(403, 'forbidden', message);
  }
};

const assertIndividualAccount = (actor) => {
  if (!actor?.id || actor.legacy) {
    throw new AdminError(
      403,
      'individual_account_required',
      'Sign in with an individual account to use collaboration controls.',
    );
  }
};

const optionalDate = (value, fieldName) => {
  if (value === null || value === undefined || value === '') return null;
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    throw new AdminError(400, 'invalid_date', `${fieldName} is not valid.`);
  }
  return date;
};

const optionalNumber = (value, fieldName) => {
  if (value === null || value === undefined || value === '') return null;
  const number = Number(value);
  if (!Number.isInteger(number) || number <= 0 || number > 1000000) {
    throw new AdminError(
      400,
      'invalid_number',
      `${fieldName} must be a positive whole number.`,
    );
  }
  return number;
};

const serializeAssignment = (assignment, users = new Map()) => ({
  id: assignment.id,
  title: assignment.title,
  instructions: assignment.instructions,
  catalog: assignment.catalog,
  versionKey: assignment.versionKey,
  categorySlug: assignment.categorySlug,
  startNumber: assignment.startNumber,
  endNumber: assignment.endNumber,
  assignee: users.has(assignment.assigneeId)
    ? serializeUser(users.get(assignment.assigneeId))
    : { id: assignment.assigneeId },
  createdBy: users.has(assignment.createdById)
    ? serializeUser(users.get(assignment.createdById))
    : { id: assignment.createdById },
  status: assignment.status,
  dueAt: assignment.dueAt,
  completedAt: assignment.completedAt,
  createdAt: assignment.createdAt,
  updatedAt: assignment.updatedAt,
});

export const assignmentMatchesEntries = (
  assignment,
  entries = [],
  categoryForEntry = () => null,
) => {
  const matchingVersion = assignment.versionKey
    ? entries.filter((entry) => entry.version === assignment.versionKey)
    : entries;
  if (matchingVersion.length === 0) return false;
  const matchingCategory = assignment.categorySlug
    ? matchingVersion.filter(
        (entry) =>
          (entry.categorySlug ||
            categoryForEntry(assignment.catalog, entry)) ===
          assignment.categorySlug,
      )
    : matchingVersion;
  if (matchingCategory.length === 0) return false;
  if (assignment.startNumber === null && assignment.endNumber === null) {
    return true;
  }
  return matchingCategory.some((entry) => {
    const number = Number(entry.entryNumber);
    return (
      Number.isInteger(number) &&
      (assignment.startNumber === null || number >= assignment.startNumber) &&
      (assignment.endNumber === null || number <= assignment.endNumber)
    );
  });
};

const serializeWorkflow = (
  workflow,
  users = new Map(),
  { includeSnapshots = false } = {},
) => {
  if (!workflow) {
    return {
      managed: false,
      status: 'approved',
      revision: 0,
      approvedRevision: 0,
      reviewSummary: null,
      ...(includeSnapshots
        ? { baselineSnapshot: {}, submittedSnapshot: {} }
        : {}),
      updatedAt: null,
    };
  }
  const namedUser = (id) =>
    id && users.has(id) ? serializeUser(users.get(id)) : null;
  return {
    managed: true,
    status: workflow.status,
    revision: workflow.revision,
    approvedRevision: workflow.approvedRevision,
    updatedBy: namedUser(workflow.updatedById),
    submittedBy: namedUser(workflow.submittedById),
    submittedAt: workflow.submittedAt,
    reviewedBy: namedUser(workflow.reviewedById),
    reviewedAt: workflow.reviewedAt,
    reviewSummary: workflow.reviewSummary,
    ...(includeSnapshots
      ? {
          baselineSnapshot: workflow.baselineSnapshot ?? {},
          submittedSnapshot: workflow.submittedSnapshot ?? {},
        }
      : {}),
    createdAt: workflow.createdAt,
    updatedAt: workflow.updatedAt,
  };
};

const reviewSnapshot = (work) =>
  JSON.parse(
    JSON.stringify({
      id: work?.id ?? null,
      canonicalKey: work?.canonicalKey ?? null,
      defaultTitle: work?.defaultTitle ?? '',
      defaultEnglishTitle: work?.defaultEnglishTitle ?? null,
      canonicalLyrics: work?.canonicalLyrics ?? '',
      notes: work?.notes ?? null,
      entries: Array.isArray(work?.entries)
        ? work.entries.map((entry) => ({
            id: entry.id ?? null,
            version: entry.version,
            versionLabel: entry.versionLabel ?? entry.edition?.nativeLabel ?? null,
            entryNumber: entry.entryNumber,
            titleOverride: entry.titleOverride ?? null,
            englishTitleOverride: entry.englishTitleOverride ?? null,
            lyricsOverride: entry.lyricsOverride ?? null,
            metadata: entry.metadata ?? {},
            categorySlug: entry.categorySlug ?? entry.category?.slug ?? null,
            isActive: entry.isActive !== false,
            media: entry.media ?? [],
          }))
        : [],
      media: Array.isArray(work?.media) ? work.media : [],
    }),
  );

const actorLabel = (actor) =>
  actor?.email
    ? `${actor.displayName} <${actor.email}>`
    : actor?.displayName || 'content-admin';

const comparableText = (value, { preserveWhitespace = false } = {}) => {
  if (value === null || value === undefined) return null;
  const text = String(value);
  if (preserveWhitespace) return text.replace(/\r\n?/g, '\n');
  const trimmed = text.trim();
  return trimmed || null;
};

const proposedMembershipSnapshot = (entry) => {
  const usesOverrides = entry.useOverrides === true;
  const implicitOverrides = entry.useOverrides === undefined;
  const override = (primary, alias, options) =>
    usesOverrides || implicitOverrides
      ? comparableText(entry[primary] ?? entry[alias], options)
      : null;
  return {
    version: String(entry.version ?? '').trim(),
    entryNumber: Number(entry.entryNumber),
    titleOverride: override('titleOverride', 'title'),
    englishTitleOverride: override(
      'englishTitleOverride',
      'englishTitle',
    ),
    lyricsOverride: override('lyricsOverride', 'lyrics', {
      preserveWhitespace: true,
    }),
    artist: comparableText(entry.artist),
    isActive: entry.isActive !== false,
  };
};

const currentMembershipSnapshot = (entry) => ({
  version: entry.version,
  entryNumber: Number(entry.entryNumber),
  titleOverride: entry.titleOverride ?? null,
  englishTitleOverride: entry.englishTitleOverride ?? null,
  lyricsOverride: comparableText(entry.lyricsOverride, {
    preserveWhitespace: true,
  }),
  artist: comparableText(entry.metadata?.artist),
  isActive: entry.isActive !== false,
});

const sameMembership = (current, proposed) => {
  const left = currentMembershipSnapshot(current);
  const right = proposedMembershipSnapshot(proposed);
  return Object.keys(left).every((key) => left[key] === right[key]);
};

export const createCollaborationService = ({
  controlDb,
  legacyAdminToken = '',
  allowLegacyAdmin = false,
  sessionHours = 12,
  categoryForEntry = () => null,
  validateAssignmentScope = async () => {},
}) => {
  const withPublicationLock = (action) =>
    controlDb.$transaction(
      async (transaction) => {
        await transaction.$queryRaw`
          select pg_advisory_xact_lock(
            hashtext('wudase_content_publication')
          )::text as lock_result
        `;
        return action();
      },
      { maxWait: 10000, timeout: 120000 },
    );

  const recordActivity = async (
    actor,
    action,
    entityType,
    entityId = null,
    details = {},
  ) =>
    controlDb.contentActivityLog.create({
      data: {
        action,
        actorUserId: actor?.id ?? null,
        actorName: actorLabel(actor),
        entityType,
        entityId: entityId ? String(entityId) : null,
        details,
      },
    });

  const loadUsers = async (ids) => {
    const uniqueIds = [...new Set(ids.filter(Boolean))];
    if (uniqueIds.length === 0) return new Map();
    const users = await controlDb.contentUser.findMany({
      where: { id: { in: uniqueIds } },
    });
    return new Map(users.map((user) => [user.id, user]));
  };

  const ensureBootstrapOwner = async ({ email, password, displayName }) => {
    const userCount = await controlDb.contentUser.count();
    if (userCount > 0) return null;
    if (!email || !password) {
      if (process.env.NODE_ENV === 'production') {
        throw new Error(
          'No Content Studio owner exists. Set CONTENT_BOOTSTRAP_OWNER_EMAIL and CONTENT_BOOTSTRAP_OWNER_PASSWORD for the first start.',
        );
      }
      return null;
    }
    const owner = await controlDb.contentUser.create({
      data: {
        email: normalizedEmail(email),
        displayName: cleanText(displayName || 'Wudase Owner', 'displayName', {
          required: true,
          maxLength: 120,
        }),
        role: 'owner',
        passwordHash: await hashPassword(password),
      },
    });
    return serializeUser(owner);
  };

  const login = async ({ email, password, userAgent, ipAddress }) => {
    let normalized;
    try {
      normalized = normalizedEmail(email);
    } catch {
      normalized = String(email ?? '').trim().toLowerCase().slice(0, 254);
    }
    const user = await controlDb.contentUser.findUnique({
      where: { email: normalized },
    });
    const passwordMatches = await verifyPassword(
      password,
      user?.passwordHash ?? dummyPasswordHash,
    );
    if (!user || !user.isActive || !passwordMatches) {
      throw new AdminError(
        401,
        'invalid_credentials',
        'The email or password is incorrect.',
      );
    }
    const token = `${sessionPrefix}${randomBytes(32).toString('base64url')}`;
    const expiresAt = new Date(Date.now() + sessionHours * 60 * 60 * 1000);
    await controlDb.$transaction([
      controlDb.contentSession.create({
        data: {
          userId: user.id,
          tokenHash: sha256(token),
          expiresAt,
          userAgent: cleanText(userAgent, 'userAgent', { maxLength: 500 }),
          ipAddress: cleanText(ipAddress, 'ipAddress', { maxLength: 100 }),
        },
      }),
      controlDb.contentUser.update({
        where: { id: user.id },
        data: { lastLoginAt: new Date() },
      }),
      controlDb.contentSession.deleteMany({
        where: {
          OR: [{ expiresAt: { lt: new Date() } }, { revokedAt: { not: null } }],
        },
      }),
      controlDb.contentActivityLog.create({
        data: {
          action: 'auth_login',
          actorUserId: user.id,
          actorName: `${user.displayName} <${user.email}>`,
          entityType: 'session',
          details: { ipAddress: cleanText(ipAddress, 'ipAddress', { maxLength: 100 }) },
        },
      }),
    ]);
    return { token, expiresAt, user: publicActor(user) };
  };

  const authenticate = async ({ token, legacyName = 'Local administrator' }) => {
    if (!token) return null;
    if (
      allowLegacyAdmin &&
      legacyAdminToken &&
      secureTextEquals(token, legacyAdminToken)
    ) {
      return publicActor(
        {
          id: null,
          email: null,
          displayName: cleanText(legacyName, 'legacyName', {
            maxLength: 120,
          }) || 'Local administrator',
          role: 'owner',
          isActive: true,
          lastLoginAt: null,
          createdAt: null,
          updatedAt: null,
        },
        true,
      );
    }
    if (!String(token).startsWith(sessionPrefix)) return null;
    const session = await controlDb.contentSession.findUnique({
      where: { tokenHash: sha256(token) },
    });
    if (
      !session ||
      session.revokedAt ||
      session.expiresAt.getTime() <= Date.now()
    ) {
      return null;
    }
    const user = await controlDb.contentUser.findUnique({
      where: { id: session.userId },
    });
    if (!user?.isActive) return null;
    if (Date.now() - session.lastSeenAt.getTime() > 15 * 60 * 1000) {
      await controlDb.contentSession.update({
        where: { id: session.id },
        data: { lastSeenAt: new Date() },
      });
    }
    return publicActor(user);
  };

  const logout = async (token) => {
    if (String(token ?? '').startsWith(sessionPrefix)) {
      await controlDb.contentSession.updateMany({
        where: { tokenHash: sha256(token), revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    return { signedOut: true };
  };

  const changePassword = async (actor, token, input) => {
    assertIndividualAccount(actor);
    const user = await controlDb.contentUser.findUnique({
      where: { id: actor.id },
    });
    if (
      !user ||
      !(await verifyPassword(input.currentPassword, user.passwordHash))
    ) {
      throw new AdminError(
        401,
        'invalid_current_password',
        'The current password is incorrect.',
      );
    }
    const passwordHash = await hashPassword(input.newPassword);
    const tokenHash = sha256(token);
    await controlDb.$transaction([
      controlDb.contentUser.update({
        where: { id: actor.id },
        data: { passwordHash },
      }),
      controlDb.contentActivityLog.create({
        data: {
          action: 'password_change',
          actorUserId: actor.id,
          actorName: actorLabel(actor),
          entityType: 'content_user',
          entityId: actor.id,
        },
      }),
      controlDb.contentSession.updateMany({
        where: {
          userId: actor.id,
          tokenHash: { not: tokenHash },
          revokedAt: null,
        },
        data: { revokedAt: new Date() },
      }),
    ]);
    return { changed: true };
  };

  const listUsers = async (actor) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner'],
      'Only an owner can view team accounts.',
    );
    const users = await controlDb.contentUser.findMany({
      orderBy: [{ isActive: 'desc' }, { displayName: 'asc' }],
    });
    return users.map(serializeUser);
  };

  const createUser = async (actor, input) => {
    assertIndividualAccount(actor);
    assertRole(actor, ['owner'], 'Only an owner can create team accounts.');
    const role = String(input.role ?? 'editor').trim();
    if (!roles.has(role)) {
      throw new AdminError(400, 'invalid_role', 'Choose a valid team role.');
    }
    const user = await controlDb.contentUser.create({
      data: {
        email: normalizedEmail(input.email),
        displayName: cleanText(input.displayName, 'displayName', {
          required: true,
          maxLength: 120,
        }),
        role,
        passwordHash: await hashPassword(input.password),
      },
    });
    await recordActivity(actor, 'user_create', 'content_user', user.id, {
      email: user.email,
      role: user.role,
    });
    return serializeUser(user);
  };

  const updateUser = async (actor, userId, input) => {
    assertIndividualAccount(actor);
    assertRole(actor, ['owner'], 'Only an owner can update team accounts.');
    const current = await controlDb.contentUser.findUnique({
      where: { id: userId },
    });
    if (!current) {
      throw new AdminError(404, 'user_not_found', 'Team member was not found.');
    }
    const role = input.role === undefined ? current.role : String(input.role);
    if (!roles.has(role)) {
      throw new AdminError(400, 'invalid_role', 'Choose a valid team role.');
    }
    const isActive =
      input.isActive === undefined ? current.isActive : input.isActive === true;
    if (current.role === 'owner' && (!isActive || role !== 'owner')) {
      const activeOwners = await controlDb.contentUser.count({
        where: { role: 'owner', isActive: true },
      });
      if (activeOwners <= 1) {
        throw new AdminError(
          409,
          'last_owner',
          'The final active owner cannot be disabled or demoted.',
        );
      }
    }
    const updated = await controlDb.contentUser.update({
      where: { id: userId },
      data: {
        ...(input.email === undefined
          ? {}
          : { email: normalizedEmail(input.email) }),
        ...(input.displayName === undefined
          ? {}
          : {
              displayName: cleanText(input.displayName, 'displayName', {
                required: true,
                maxLength: 120,
              }),
            }),
        role,
        isActive,
        ...(input.password
          ? { passwordHash: await hashPassword(input.password) }
          : {}),
      },
    });
    if (!isActive || input.password) {
      await controlDb.contentSession.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: new Date() },
      });
    }
    await recordActivity(actor, 'user_update', 'content_user', updated.id, {
      email: updated.email,
      role: updated.role,
      isActive: updated.isActive,
      passwordReset: Boolean(input.password),
    });
    return serializeUser(updated);
  };

  const listAssignments = async (actor, filters = {}) => {
    assertIndividualAccount(actor);
    const assignments = await controlDb.contentAssignment.findMany({
      where: {
        ...(actor.role === 'editor' ? { assigneeId: actor.id } : {}),
        ...(filters.catalog ? { catalog: getCatalogDefinition(filters.catalog).id } : {}),
        ...(filters.status ? { status: String(filters.status) } : {}),
        ...(filters.assigneeId && actor.role !== 'editor'
          ? { assigneeId: String(filters.assigneeId) }
          : {}),
      },
      orderBy: [{ status: 'asc' }, { dueAt: 'asc' }, { createdAt: 'desc' }],
    });
    const users = await loadUsers(
      assignments.flatMap((item) => [item.assigneeId, item.createdById]),
    );
    return assignments.map((item) => serializeAssignment(item, users));
  };

  const assignmentData = (input) => {
    const catalog = getCatalogDefinition(input.catalog).id;
    const status = String(input.status ?? 'active').trim();
    if (!assignmentStatuses.has(status)) {
      throw new AdminError(
        400,
        'invalid_assignment_status',
        'Choose a valid assignment status.',
      );
    }
    const startNumber = optionalNumber(input.startNumber, 'startNumber');
    const endNumber = optionalNumber(input.endNumber, 'endNumber');
    if (
      startNumber !== null &&
      endNumber !== null &&
      startNumber > endNumber
    ) {
      throw new AdminError(
        400,
        'invalid_assignment_range',
        'The first number cannot be greater than the last number.',
      );
    }
    return {
      title: cleanText(input.title, 'title', {
        required: true,
        maxLength: 180,
      }),
      instructions: cleanText(input.instructions, 'instructions', {
        maxLength: 4000,
      }),
      catalog,
      versionKey:
        cleanText(input.versionKey, 'versionKey', { maxLength: 80 }) || null,
      categorySlug:
        cleanText(input.categorySlug, 'categorySlug', { maxLength: 100 }) ||
        null,
      startNumber,
      endNumber,
      status,
      dueAt: optionalDate(input.dueAt, 'dueAt'),
    };
  };

  const createAssignment = async (actor, input) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner'],
      'Only an owner can create assignments.',
    );
    const assigneeId = String(input.assigneeId ?? '');
    const assignee = await controlDb.contentUser.findUnique({
      where: { id: assigneeId },
    });
    if (!assignee?.isActive) {
      throw new AdminError(
        400,
        'invalid_assignee',
        'Choose an active team member.',
      );
    }
    if (assignee.role !== 'editor') {
      throw new AdminError(
        400,
        'invalid_assignee_role',
        'Assignments can be given only to editor accounts.',
      );
    }
    const data = assignmentData(input);
    await validateAssignmentScope(data);
    const assignment = await controlDb.contentAssignment.create({
      data: {
        ...data,
        assigneeId,
        createdById: actor.id,
      },
    });
    await recordActivity(
      actor,
      'assignment_create',
      'content_assignment',
      assignment.id,
      {
        assigneeId,
        catalog: assignment.catalog,
        versionKey: assignment.versionKey,
        startNumber: assignment.startNumber,
        endNumber: assignment.endNumber,
      },
    );
    const users = await loadUsers([assigneeId, actor.id]);
    return serializeAssignment(assignment, users);
  };

  const updateAssignment = async (actor, assignmentId, input) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner'],
      'Only an owner can update assignments.',
    );
    const current = await controlDb.contentAssignment.findUnique({
      where: { id: assignmentId },
    });
    if (!current) {
      throw new AdminError(
        404,
        'assignment_not_found',
        'Assignment was not found.',
      );
    }
    const merged = { ...current, ...input };
    const assigneeId = String(merged.assigneeId);
    const assignee = await controlDb.contentUser.findUnique({
      where: { id: assigneeId },
    });
    if (!assignee?.isActive) {
      throw new AdminError(
        400,
        'invalid_assignee',
        'Choose an active team member.',
      );
    }
    if (assignee.role !== 'editor') {
      throw new AdminError(
        400,
        'invalid_assignee_role',
        'Assignments can be given only to editor accounts.',
      );
    }
    const data = assignmentData(merged);
    await validateAssignmentScope(data);
    const assignment = await controlDb.contentAssignment.update({
      where: { id: assignmentId },
      data: {
        ...data,
        assigneeId,
        completedAt:
          data.status === 'completed'
            ? current.completedAt ?? new Date()
            : null,
      },
    });
    await recordActivity(
      actor,
      'assignment_update',
      'content_assignment',
      assignment.id,
      { status: assignment.status, assigneeId: assignment.assigneeId },
    );
    const users = await loadUsers([assigneeId, assignment.createdById]);
    return serializeAssignment(assignment, users);
  };

  const matchingAssignments = async (actor, catalog, entries) => {
    if (!actor?.id || actor.role !== 'editor') return [];
    const assignments = await controlDb.contentAssignment.findMany({
      where: { assigneeId: actor.id, catalog, status: 'active' },
    });
    return assignments.filter((assignment) =>
      assignmentMatchesEntries(assignment, entries, categoryForEntry),
    );
  };

  const canEditWork = async (actor, catalogValue, entries) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    if (actor?.role === 'owner') return true;
    if (actor?.role !== 'editor') return false;
    return (await matchingAssignments(actor, catalog, entries)).length > 0;
  };

  const assertCanEditWork = async (actor, catalog, entries) => {
    if (!(await canEditWork(actor, catalog, entries))) {
      throw new AdminError(
        403,
        'outside_assignment',
        'This song is outside your active assignments.',
      );
    }
  };

  const assertCanCreateWork = async (actor, catalogValue, entries) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    if (actor?.role === 'owner') return;
    if (actor?.role !== 'editor' || !Array.isArray(entries) || entries.length === 0) {
      throw new AdminError(
        403,
        'outside_assignment',
        'Choose at least one hymnal membership inside an active assignment.',
      );
    }
    const assignments = await controlDb.contentAssignment.findMany({
      where: { assigneeId: actor.id, catalog, status: 'active' },
    });
    const allInScope = entries.every((entry) =>
      assignments.some((assignment) =>
        assignmentMatchesEntries(
          assignment,
          [entry],
          categoryForEntry,
        ),
      ),
    );
    if (!allInScope) {
      throw new AdminError(
        403,
        'outside_assignment',
        'Every new hymnal membership must be inside your active assignments.',
      );
    }
  };

  const assertCanUpdateWork = async (
    actor,
    catalogValue,
    currentEntries,
    proposedEntries,
  ) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    await assertCanEditWork(actor, catalog, currentEntries);
    if (actor?.role !== 'editor') return;
    const assignments = await controlDb.contentAssignment.findMany({
      where: { assigneeId: actor.id, catalog, status: 'active' },
    });
    const inScope = (entry) =>
      assignments.some((assignment) =>
        assignmentMatchesEntries(
          assignment,
          [entry],
          categoryForEntry,
        ),
      );
    const next = Array.isArray(proposedEntries) ? proposedEntries : [];
    const nextIds = new Set(next.map((entry) => entry.id).filter(Boolean));
    for (const entry of next) {
      const current = currentEntries.find(
        (item) =>
          (entry.id && item.id === entry.id) ||
          (!entry.id && item.version === entry.version),
      );
      const scopeChanged =
        !current ||
        current.version !== entry.version ||
        Number(current.entryNumber) !== Number(entry.entryNumber);
      if (scopeChanged && !inScope(entry)) {
        throw new AdminError(
          403,
          'outside_assignment',
          'A hymnal membership or number change is outside your active assignments.',
        );
      }
      if (current && !inScope(current) && !sameMembership(current, entry)) {
        throw new AdminError(
          403,
          'outside_assignment',
          'You cannot change version-specific fields outside your active assignments.',
        );
      }
    }
    for (const current of currentEntries) {
      if (!nextIds.has(current.id) && !inScope(current)) {
        throw new AdminError(
          403,
          'outside_assignment',
          'You cannot remove a hymnal membership outside your active assignments.',
        );
      }
    }
  };

  const assertWorkflowEditable = async (catalogValue, workId) => {
    const workflow = await workflowForWork(catalogValue, workId);
    if (workflow?.status === 'submitted') {
      throw new AdminError(
        409,
        'work_under_review',
        'This song is submitted for review. Return it for changes before editing.',
      );
    }
  };

  const markDraft = async (
    actor,
    catalogValue,
    workId,
    baselineWork = null,
  ) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    const now = new Date();
    const current = await workflowForWork(catalog, workId);
    const baselineSnapshot =
      current?.status === 'approved'
        ? reviewSnapshot(baselineWork)
        : current
          ? (current.baselineSnapshot ?? {})
          : baselineWork
            ? reviewSnapshot(baselineWork)
            : {};
    return controlDb.contentWorkflow.upsert({
      where: { catalog_workId: { catalog, workId } },
      create: {
        catalog,
        workId,
        status: 'draft',
        revision: 1,
        updatedById: actor?.id ?? null,
        baselineSnapshot,
      },
      update: {
        status: 'draft',
        revision: { increment: 1 },
        updatedById: actor?.id ?? null,
        submittedById: null,
        submittedAt: null,
        reviewedById: null,
        reviewedAt: null,
        reviewSummary: null,
        approvedRevision: null,
        baselineSnapshot,
        submittedSnapshot: {},
        updatedAt: now,
      },
    });
  };

  const removeProvisionalWorkflow = async (catalogValue, workId) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    await controlDb.contentWorkflow.deleteMany({
      where: { catalog, workId, status: 'draft', revision: 1 },
    });
  };

  const workflowForWork = async (catalogValue, workId) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    return controlDb.contentWorkflow.findUnique({
      where: { catalog_workId: { catalog, workId } },
    });
  };

  const describeWork = async (actor, catalogValue, work) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    const [workflow, assignments, comments] = await Promise.all([
      workflowForWork(catalog, work.id),
      actor?.id
        ? controlDb.contentAssignment.findMany({
            where: {
              catalog,
              status: 'active',
              ...(actor.role === 'editor' ? { assigneeId: actor.id } : {}),
            },
          })
        : [],
      controlDb.contentComment.findMany({
        where: { catalog, workId: work.id },
        orderBy: { createdAt: 'asc' },
      }),
    ]);
    const matching = assignments.filter((assignment) =>
      assignmentMatchesEntries(
        assignment,
        work.entries,
        categoryForEntry,
      ),
    );
    const editableEntryIds =
      actor?.role === 'editor'
        ? work.entries
            .filter((entry) =>
              assignments.some((assignment) =>
                assignmentMatchesEntries(
                  assignment,
                  [entry],
                  categoryForEntry,
                ),
              ),
            )
            .map((entry) => entry.id)
        : work.entries.map((entry) => entry.id);
    const editableVersionKeys =
      actor?.role === 'editor'
        ? [
            ...new Set(
              assignments.flatMap((assignment) =>
                assignment.versionKey ? [assignment.versionKey] : ['*'],
              ),
            ),
          ]
        : ['*'];
    const users = await loadUsers([
      workflow?.updatedById,
      workflow?.submittedById,
      workflow?.reviewedById,
      ...matching.flatMap((item) => [item.assigneeId, item.createdById]),
      ...comments.map((comment) => comment.userId),
    ]);
    return {
      workflow: serializeWorkflow(workflow, users, { includeSnapshots: true }),
      canEdit: await canEditWork(actor, catalog, work.entries),
      canSubmit:
        Boolean(actor?.id) &&
        ['draft', 'changes_requested'].includes(workflow?.status) &&
        (await canEditWork(actor, catalog, work.entries)),
      canReview:
        actor?.permissions?.review === true &&
        workflow?.status === 'submitted' &&
        actor.id !== workflow.updatedById &&
        actor.id !== workflow.submittedById,
      canManageMedia: actor?.permissions?.manageMedia === true,
      editableEntryIds,
      editableVersionKeys,
      assignments: matching.map((item) => serializeAssignment(item, users)),
      comments: comments.map((comment) => ({
        id: comment.id,
        body: comment.body,
        author: users.has(comment.userId)
          ? serializeUser(users.get(comment.userId))
          : { id: comment.userId, displayName: 'Former team member' },
        createdAt: comment.createdAt,
        updatedAt: comment.updatedAt,
      })),
    };
  };

  const decorateWorks = async (actor, catalogValue, works) => {
    if (works.length === 0) return works;
    const catalog = getCatalogDefinition(catalogValue).id;
    const [workflows, assignments] = await Promise.all([
      controlDb.contentWorkflow.findMany({
        where: { catalog, workId: { in: works.map((work) => work.id) } },
      }),
      actor?.role === 'editor' && actor.id
        ? controlDb.contentAssignment.findMany({
            where: { assigneeId: actor.id, catalog, status: 'active' },
          })
        : [],
    ]);
    const workflowMap = new Map(workflows.map((item) => [item.workId, item]));
    const users = await loadUsers(
      workflows.flatMap((item) => [
        item.updatedById,
        item.submittedById,
        item.reviewedById,
      ]),
    );
    return works.map((work) => ({
        ...work,
        collaboration: {
          workflow: serializeWorkflow(workflowMap.get(work.id), users),
          canEdit:
            actor?.role === 'owner' ||
            assignments.some((assignment) =>
              assignmentMatchesEntries(
                assignment,
                work.entries,
                categoryForEntry,
              ),
            ),
        },
      }));
  };

  const submitWork = async (actor, catalogValue, work) => {
    assertIndividualAccount(actor);
    const catalog = getCatalogDefinition(catalogValue).id;
    await assertCanEditWork(actor, catalog, work.entries);
    const workflow = await workflowForWork(catalog, work.id);
    if (!workflow || !['draft', 'changes_requested'].includes(workflow.status)) {
      throw new AdminError(
        409,
        'invalid_workflow_transition',
        'Only a draft or requested revision can be submitted.',
      );
    }
    const updated = await controlDb.contentWorkflow.update({
      where: { id: workflow.id },
      data: {
        status: 'submitted',
        submittedById: actor.id,
        submittedAt: new Date(),
        reviewedById: null,
        reviewedAt: null,
        reviewSummary: null,
        submittedSnapshot: reviewSnapshot(work),
      },
    });
    await recordActivity(actor, 'workflow_submit', 'work', work.id, {
      catalog,
      revision: updated.revision,
    });
    return updated;
  };

  const reviewWork = async (actor, catalogValue, workId, input) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner', 'reviewer'],
      'Only an owner or reviewer can review submissions.',
    );
    const catalog = getCatalogDefinition(catalogValue).id;
    const workflow = await workflowForWork(catalog, workId);
    if (workflow?.status !== 'submitted') {
      throw new AdminError(
        409,
        'invalid_workflow_transition',
        'Only a submitted song can be reviewed.',
      );
    }
    if (
      actor.id === workflow.updatedById ||
      actor.id === workflow.submittedById
    ) {
      throw new AdminError(
        409,
        'self_review_not_allowed',
        'A different owner or reviewer must approve this submission.',
      );
    }
    const decision = String(input.decision ?? '').trim();
    if (!['approved', 'changes_requested'].includes(decision)) {
      throw new AdminError(
        400,
        'invalid_review_decision',
        'Decision must be approved or changes_requested.',
      );
    }
    const expectedRevision = Number(input.expectedRevision);
    if (!Number.isInteger(expectedRevision) || expectedRevision < 1) {
      throw new AdminError(
        400,
        'expected_revision_required',
        'Confirm the exact revision being reviewed.',
      );
    }
    if (expectedRevision !== workflow.revision) {
      throw new AdminError(
        409,
        'stale_review',
        'This submission changed after it was opened. Reload it before deciding.',
      );
    }
    if (decision === 'approved' && input.confirmed !== true) {
      throw new AdminError(
        400,
        'approval_confirmation_required',
        'Confirm that you reviewed the submitted revision before approval.',
      );
    }
    const summary = cleanText(input.summary, 'summary', { maxLength: 4000 });
    if (decision === 'changes_requested' && !summary) {
      throw new AdminError(
        400,
        'review_summary_required',
        'Explain what must change before returning the song.',
      );
    }
    const updated = await controlDb.$transaction(async (tx) => {
      const updated = await tx.contentWorkflow.update({
        where: { id: workflow.id },
        data: {
          status: decision,
          reviewedById: actor.id,
          reviewedAt: new Date(),
          reviewSummary: summary,
          approvedRevision:
            decision === 'approved' ? workflow.revision : null,
        },
      });
      if (decision === 'changes_requested') {
        await tx.contentComment.create({
          data: {
            catalog,
            workId,
            userId: actor.id,
            body: `Changes requested: ${summary}`,
          },
        });
      }
      return updated;
    });
    await recordActivity(actor, 'workflow_review', 'work', workId, {
      catalog,
      decision,
      revision: updated.revision,
    });
    return updated;
  };

  const addComment = async (actor, catalogValue, work, input) => {
    assertIndividualAccount(actor);
    const catalog = getCatalogDefinition(catalogValue).id;
    if (
      actor.role === 'editor' &&
      !(await canEditWork(actor, catalog, work.entries))
    ) {
      throw new AdminError(
        403,
        'outside_assignment',
        'This song is outside your active assignments.',
      );
    }
    const comment = await controlDb.contentComment.create({
      data: {
        catalog,
        workId: work.id,
        userId: actor.id,
        body: cleanText(input.body, 'body', {
          required: true,
          maxLength: 4000,
          preserveWhitespace: true,
        }),
      },
    });
    await recordActivity(actor, 'comment_create', 'work', work.id, {
      catalog,
      commentId: comment.id,
    });
    return {
      id: comment.id,
      body: comment.body,
      author: actor,
      createdAt: comment.createdAt,
      updatedAt: comment.updatedAt,
    };
  };

  const workflowSummary = async () => {
    const groups = await controlDb.contentWorkflow.groupBy({
      by: ['catalog', 'status'],
      _count: { _all: true },
    });
    const result = {
      sda: { draft: 0, submitted: 0, changes_requested: 0, approved: 0 },
      hagerigna: {
        draft: 0,
        submitted: 0,
        changes_requested: 0,
        approved: 0,
      },
    };
    for (const group of groups) {
      if (result[group.catalog] && workflowStatuses.has(group.status)) {
        result[group.catalog][group.status] = group._count._all;
      }
    }
    return result;
  };

  const consolidateWork = async (actor, catalogValue, targetWorkId, sourceWorkId) => {
    const catalog = getCatalogDefinition(catalogValue).id;
    await controlDb.$transaction(async (tx) => {
      await tx.contentComment.updateMany({
        where: { catalog, workId: sourceWorkId },
        data: { workId: targetWorkId },
      });
      await tx.contentWorkflow.deleteMany({
        where: { catalog, workId: sourceWorkId },
      });
      await tx.contentWorkflow.upsert({
        where: { catalog_workId: { catalog, workId: targetWorkId } },
        create: {
          catalog,
          workId: targetWorkId,
          status: 'draft',
          revision: 1,
          updatedById: actor?.id ?? null,
        },
        update: {
          status: 'draft',
          updatedById: actor?.id ?? null,
          submittedById: null,
          submittedAt: null,
          reviewedById: null,
          reviewedAt: null,
          reviewSummary: null,
          approvedRevision: null,
        },
      });
    });
  };

  const listReviewQueue = async (actor, { catalog, status = 'submitted' }) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner', 'reviewer'],
      'Only an owner or reviewer can view the review queue.',
    );
    const statuses = String(status)
      .split(',')
      .map((item) => item.trim())
      .filter((item) => workflowStatuses.has(item));
    const normalizedCatalog = catalog
      ? getCatalogDefinition(catalog).id
      : undefined;
    const workflows = await controlDb.contentWorkflow.findMany({
      where: {
        ...(normalizedCatalog ? { catalog: normalizedCatalog } : {}),
        ...(statuses.length > 0 ? { status: { in: statuses } } : {}),
      },
      orderBy: { updatedAt: 'desc' },
      take: 200,
    });
    const users = await loadUsers(
      workflows.flatMap((item) => [
        item.updatedById,
        item.submittedById,
        item.reviewedById,
      ]),
    );
    return workflows.map((workflow) => ({
      catalog: workflow.catalog,
      workId: workflow.workId,
      workflow: serializeWorkflow(workflow, users),
    }));
  };

  const listActivity = async (actor, pageSize = 100) => {
    assertIndividualAccount(actor);
    assertRole(
      actor,
      ['owner', 'reviewer'],
      'Only an owner or reviewer can view team activity.',
    );
    const take = Math.max(1, Math.min(200, Number(pageSize) || 100));
    return controlDb.contentActivityLog.findMany({
      orderBy: { createdAt: 'desc' },
      take,
    });
  };

  return {
    actorLabel,
    withPublicationLock,
    ensureBootstrapOwner,
    login,
    authenticate,
    logout,
    changePassword,
    listUsers,
    createUser,
    updateUser,
    listAssignments,
    createAssignment,
    updateAssignment,
    canEditWork,
    assertCanEditWork,
    assertCanCreateWork,
    assertCanUpdateWork,
    assertWorkflowEditable,
    markDraft,
    removeProvisionalWorkflow,
    describeWork,
    decorateWorks,
    submitWork,
    reviewWork,
    addComment,
    consolidateWork,
    workflowSummary,
    listReviewQueue,
    listActivity,
    recordActivity,
  };
};
