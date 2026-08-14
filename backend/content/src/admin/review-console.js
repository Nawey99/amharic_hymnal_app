const byId = (id) => document.getElementById(id);

const elements = {
  authView: byId('auth-view'),
  authForm: byId('auth-form'),
  authError: byId('auth-error'),
  email: byId('review-email'),
  password: byId('review-password'),
  reviewView: byId('review-view'),
  reviewerChip: byId('reviewer-chip'),
  contentStudioLink: byId('content-studio-link'),
  accountButton: byId('account-button'),
  accountDialog: byId('account-dialog'),
  passwordForm: byId('password-form'),
  cancelAccount: byId('cancel-account'),
  signOut: byId('sign-out-button'),
  catalogFilter: byId('catalog-filter'),
  statusFilter: byId('status-filter'),
  refresh: byId('refresh-button'),
  pendingCount: byId('pending-count'),
  workspaceTabs: [...document.querySelectorAll('[data-workspace]')],
  reviewsWorkspace: byId('reviews-workspace'),
  mediaWorkspace: byId('media-workspace'),
  queueHeading: byId('queue-heading'),
  queueSummary: byId('queue-summary'),
  queueList: byId('queue-list'),
  workspace: byId('review-workspace'),
  detailPane: byId('detail-pane'),
  detailEmpty: byId('detail-empty'),
  detailContent: byId('detail-content'),
  approvalDialog: byId('approval-dialog'),
  confirmApproval: byId('confirm-approval'),
  mediaSearchForm: byId('media-search-form'),
  mediaCatalogFilter: byId('media-catalog-filter'),
  mediaSearchInput: byId('media-search-input'),
  mediaResultSummary: byId('media-result-summary'),
  mediaResultList: byId('media-result-list'),
  mediaDetailPane: byId('media-detail-pane'),
  mediaDetailEmpty: byId('media-detail-empty'),
  mediaDetailContent: byId('media-detail-content'),
  addMediaButton: byId('add-media-button'),
  mediaDialog: byId('media-dialog'),
  mediaDialogTitle: byId('media-dialog-title'),
  mediaForm: byId('media-form'),
  cancelMedia: byId('cancel-media'),
  removeMediaDialog: byId('remove-media-dialog'),
  toast: byId('toast'),
};

const state = {
  user: null,
  queue: [],
  selected: null,
  catalog: '',
  status: 'submitted',
  requestSequence: 0,
  workspace: 'reviews',
  media: {
    catalog: 'sda',
    query: '',
    works: [],
    total: 0,
    selected: null,
    editing: null,
    pendingRemove: null,
    loaded: false,
    requestSequence: 0,
  },
};

const csrfToken = () => {
  const cookie = document.cookie
    .split(';')
    .map((part) => part.trim())
    .find((part) =>
      part.split('=', 1)[0].endsWith('wudase_content_csrf'),
    );
  if (!cookie) return '';
  try {
    return decodeURIComponent(cookie.slice(cookie.indexOf('=') + 1));
  } catch {
    return '';
  }
};

const escapeHtml = (value) =>
  String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');

const formatDate = (value) => {
  if (!value) return 'Not recorded';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'Not recorded';
  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date);
};

const showToast = (message, isError = false) => {
  elements.toast.textContent = message;
  elements.toast.classList.toggle('error', isError);
  elements.toast.hidden = false;
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => {
    elements.toast.hidden = true;
  }, 4200);
};

const api = async (path, options = {}) => {
  const headers = new Headers(options.headers || {});
  if (options.body && !headers.has('content-type')) {
    headers.set('content-type', 'application/json');
  }
  if (!['GET', 'HEAD', 'OPTIONS'].includes(options.method || 'GET')) {
    const token = csrfToken();
    if (token) headers.set('x-wudase-csrf', token);
  }
  const response = await fetch(path, {
    ...options,
    headers,
    credentials: 'same-origin',
  });
  let body = null;
  try {
    body = await response.json();
  } catch {
    body = null;
  }
  if (!response.ok) {
    const error = new Error(
      body?.message || body?.error || `Request failed (${response.status})`,
    );
    error.status = response.status;
    error.code = body?.error;
    if (response.status === 401 && state.user) {
      queueMicrotask(() => signOut({ notifyServer: false }));
    }
    throw error;
  }
  return body;
};

const statusLabel = (status) =>
  ({
    submitted: 'Awaiting decision',
    changes_requested: 'Returned for changes',
    approved: 'Approved history',
  })[status] || status;

const catalogLabel = (catalog) =>
  catalog === 'sda' ? 'SDA Hymnal' : 'Hagerigna';

const stableJson = (value) => {
  if (Array.isArray(value)) return `[${value.map(stableJson).join(',')}]`;
  if (value && typeof value === 'object') {
    return `{${Object.keys(value)
      .sort()
      .map((key) => `${JSON.stringify(key)}:${stableJson(value[key])}`)
      .join(',')}}`;
  }
  return JSON.stringify(value ?? null);
};

const changed = (before, after) => stableJson(before) !== stableJson(after);

const snapshotOrCurrent = (snapshot, work) => {
  if (snapshot && Object.keys(snapshot).length > 0) return snapshot;
  return {
    id: work.id,
    canonicalKey: work.canonicalKey,
    defaultTitle: work.defaultTitle,
    defaultEnglishTitle: work.defaultEnglishTitle,
    canonicalLyrics: work.canonicalLyrics,
    notes: work.notes,
    entries: work.entries || [],
    media: work.media || [],
  };
};

const emptyBaseline = () => ({
  defaultTitle: '',
  defaultEnglishTitle: null,
  canonicalLyrics: '',
  notes: null,
  entries: [],
  media: [],
});

const fieldList = (snapshot) => `
  <dl class="field-list">
    <div><dt>Amharic title</dt><dd>${escapeHtml(snapshot.defaultTitle || 'Not present')}</dd></div>
    <div><dt>English title</dt><dd>${escapeHtml(snapshot.defaultEnglishTitle || 'Not present')}</dd></div>
    <div><dt>Internal notes</dt><dd>${escapeHtml(snapshot.notes || 'None')}</dd></div>
  </dl>
`;

const entryLabel = (entry) =>
  entry.versionLabel || entry.nativeVersionLabel || entry.version || 'Unknown hymnal';

const entryList = (entries) => {
  if (!Array.isArray(entries) || entries.length === 0) {
    return '<div class="empty-inline">No hymnal memberships.</div>';
  }
  return `<div class="item-list">${entries
    .map(
      (entry) => `
        <div class="item-row">
          <strong>${escapeHtml(entryLabel(entry))} · #${escapeHtml(entry.entryNumber)}</strong>
          <small>${escapeHtml(entry.categorySlug || 'No category')} · ${
            entry.isActive === false ? 'Unavailable' : 'Available'
          }</small>
          ${
            entry.titleOverride || entry.englishTitleOverride || entry.lyricsOverride
              ? '<small>Contains edition-specific content</small>'
              : '<small>Uses shared song content</small>'
          }
        </div>
      `,
    )
    .join('')}</div>`;
};

const mediaList = (media, entries = []) => {
  const allMedia = [
    ...(Array.isArray(media) ? media : []),
    ...(Array.isArray(entries)
      ? entries.flatMap((entry) =>
          (entry.media || []).map((item) => ({ ...item, entryLabel: entryLabel(entry) })),
        )
      : []),
  ];
  if (allMedia.length === 0) {
    return '<div class="empty-inline">No reusable media linked.</div>';
  }
  return `<div class="item-list">${allMedia
    .map(
      (item) => `
        <div class="item-row">
          <strong>${escapeHtml(item.asset?.mediaType || 'Media')} · ${escapeHtml(
            item.relationType || 'linked',
          )}</strong>
          <small>${escapeHtml(item.entryLabel || 'Shared song media')}</small>
          ${
            item.asset?.publicUrl
              ? `<a href="${escapeHtml(item.asset.publicUrl)}" target="_blank" rel="noopener noreferrer">Open media source</a>`
              : `<small>${escapeHtml(item.asset?.storageKey || 'No public URL')}</small>`
          }
        </div>
      `,
    )
    .join('')}</div>`;
};

const mediaTypeConfig = Object.freeze({
  audio: {
    label: 'Audio',
    relations: [
      ['primary_audio', 'Primary audio'],
      ['alternate_audio', 'Alternate audio'],
    ],
    mimeTypes: [
      ['audio/mpeg', 'MP3 audio'],
      ['audio/mp4', 'M4A / MP4 audio'],
      ['audio/ogg', 'Ogg audio'],
      ['audio/webm', 'WebM audio'],
      ['audio/wav', 'WAV audio'],
      ['audio/x-wav', 'WAV audio (legacy MIME)'],
    ],
  },
  sheet_music: {
    label: 'Sheet music',
    relations: [
      ['primary_sheet_music', 'Primary sheet music'],
      ['alternate_sheet_music', 'Alternate sheet music'],
    ],
    mimeTypes: [
      ['image/webp', 'WebP image'],
      ['image/avif', 'AVIF image'],
      ['image/jpeg', 'JPEG image'],
      ['image/png', 'PNG image'],
      ['application/pdf', 'PDF document'],
    ],
  },
  image: {
    label: 'Image',
    relations: [['thumbnail', 'Thumbnail']],
    mimeTypes: [
      ['image/webp', 'WebP image'],
      ['image/avif', 'AVIF image'],
      ['image/jpeg', 'JPEG image'],
      ['image/png', 'PNG image'],
    ],
  },
});

const flattenMedia = (work) => [
  ...(work?.media || []).map((item) => ({ ...item, entryLabel: null })),
  ...(work?.entries || []).flatMap((entry) =>
    (entry.media || []).map((item) => ({
      ...item,
      entryLabel: entryLabel(entry),
    })),
  ),
];

const formatBytes = (value) => {
  const bytes = Number(value);
  if (!Number.isFinite(bytes) || bytes < 0) return 'Size not recorded';
  if (bytes < 1024) return `${bytes} B`;
  const units = ['KB', 'MB', 'GB'];
  let size = bytes / 1024;
  let unit = units[0];
  for (let index = 1; index < units.length && size >= 1024; index += 1) {
    size /= 1024;
    unit = units[index];
  }
  return `${size.toFixed(size >= 10 ? 1 : 2)} ${unit}`;
};

const workNumberSummary = (work) =>
  (work.entries || [])
    .map((entry) => `${entryLabel(entry)} #${entry.entryNumber}`)
    .join(' · ') || 'No hymnal membership';

const renderMediaResults = () => {
  elements.mediaResultSummary.textContent = `${state.media.total} songs`;
  if (state.media.works.length === 0) {
    elements.mediaResultList.innerHTML = '<div class="empty-inline">No songs match this search.</div>';
    return;
  }
  elements.mediaResultList.innerHTML = state.media.works
    .map(
      (work) => `
        <button class="media-result-row" type="button" data-media-work="${escapeHtml(work.id)}" aria-current="${
          state.media.selected?.id === work.id ? 'true' : 'false'
        }">
          <strong>${escapeHtml(work.defaultTitle || 'Untitled song')}</strong>
          <small>${escapeHtml(work.defaultEnglishTitle || workNumberSummary(work))}</small>
          <span>${escapeHtml(workNumberSummary(work))}</span>
        </button>
      `,
    )
    .join('');
  elements.mediaResultList.querySelectorAll('[data-media-work]').forEach((button) => {
    button.addEventListener('click', () => selectMediaWork(button.dataset.mediaWork));
  });
};

const clearMediaDetail = () => {
  state.media.selected = null;
  state.media.editing = null;
  elements.addMediaButton.disabled = true;
  elements.mediaDetailContent.hidden = true;
  elements.mediaDetailContent.innerHTML = '';
  elements.mediaDetailEmpty.hidden = false;
  elements.mediaDetailPane.classList.remove('detail-open');
  renderMediaResults();
};

const liveMediaCard = (item) => {
  const asset = item.asset || {};
  const type = mediaTypeConfig[asset.mediaType]?.label || 'Media';
  const editable = item.scope === 'work';
  return `
    <article class="media-card">
      <div class="media-card-heading">
        <div>
          <strong>${escapeHtml(type)}</strong>
          <span>${escapeHtml(item.relationType || 'linked')}</span>
        </div>
        <span class="badge">${escapeHtml(item.entryLabel || 'Shared song asset')}</span>
      </div>
      <dl class="media-card-meta">
        <div><dt>File type</dt><dd>${escapeHtml(asset.mimeType || 'Not recorded')}</dd></div>
        <div><dt>File size</dt><dd>${escapeHtml(formatBytes(asset.fileSizeBytes))}</dd></div>
        <div><dt>Order</dt><dd>${escapeHtml(item.sortOrder ?? 0)}</dd></div>
        <div><dt>Page</dt><dd>${escapeHtml(asset.pageLabel || 'Not labeled')}</dd></div>
      </dl>
      ${
        asset.publicUrl
          ? `<a class="media-url" href="${escapeHtml(asset.publicUrl)}" target="_blank" rel="noopener noreferrer">${escapeHtml(asset.publicUrl)}</a>`
          : `<span class="media-url">${escapeHtml(asset.storageKey || 'No public URL')}</span>`
      }
      ${item.notes ? `<p>${escapeHtml(item.notes)}</p>` : ''}
      ${
        editable
          ? `<div class="media-card-actions">
              <button class="button button-quiet" type="button" data-edit-media="${escapeHtml(item.id)}">Edit</button>
              <button class="button button-danger" type="button" data-remove-media="${escapeHtml(item.id)}">Remove</button>
            </div>`
          : '<small class="media-readonly">Edition-specific connection · view only</small>'
      }
    </article>
  `;
};

const renderMediaDetail = (work) => {
  const media = flattenMedia(work);
  elements.mediaDetailEmpty.hidden = true;
  elements.mediaDetailContent.hidden = false;
  elements.mediaDetailPane.classList.add('detail-open');
  elements.addMediaButton.disabled = false;
  elements.mediaDetailContent.innerHTML = `
    <header class="media-detail-header">
      <button class="button button-quiet media-back-button" id="media-back" type="button">Back</button>
      <div>
        <h2>${escapeHtml(work.defaultTitle || 'Untitled song')}</h2>
        <p>${escapeHtml(work.defaultEnglishTitle || workNumberSummary(work))}</p>
        <span>${escapeHtml(workNumberSummary(work))}</span>
      </div>
    </header>
    <div class="media-detail-body">
      <div class="section-heading">
        <h3>Live media connections</h3>
        <span>${media.length} linked</span>
      </div>
      <div class="live-media-list">
        ${media.length > 0 ? media.map(liveMediaCard).join('') : '<div class="empty-inline">No audio or sheet music is connected to this song.</div>'}
      </div>
    </div>
  `;
  byId('media-back')?.addEventListener('click', () => {
    elements.mediaDetailPane.classList.remove('detail-open');
  });
  elements.mediaDetailContent.querySelectorAll('[data-edit-media]').forEach((button) => {
    button.addEventListener('click', () => {
      const item = media.find((candidate) => candidate.id === button.dataset.editMedia);
      if (item) openMediaDialog(item);
    });
  });
  elements.mediaDetailContent.querySelectorAll('[data-remove-media]').forEach((button) => {
    button.addEventListener('click', () => {
      const item = media.find((candidate) => candidate.id === button.dataset.removeMedia);
      if (!item) return;
      state.media.pendingRemove = item;
      elements.removeMediaDialog.returnValue = '';
      elements.removeMediaDialog.showModal();
    });
  });
};

const selectMediaWork = async (workId, { preserveScroll = false } = {}) => {
  const sequence = ++state.media.requestSequence;
  const scrollTop = preserveScroll ? elements.mediaDetailPane.scrollTop : 0;
  elements.mediaDetailEmpty.hidden = true;
  elements.mediaDetailContent.hidden = false;
  elements.mediaDetailContent.innerHTML = '<div class="loading-inline">Loading media connections...</div>';
  try {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(workId)}?catalog=${encodeURIComponent(state.media.catalog)}`,
    );
    if (sequence !== state.media.requestSequence) return;
    state.media.selected = response.data;
    renderMediaResults();
    renderMediaDetail(response.data);
    if (preserveScroll) elements.mediaDetailPane.scrollTop = scrollTop;
  } catch (error) {
    if (sequence !== state.media.requestSequence) return;
    elements.mediaDetailContent.innerHTML = `<div class="empty-inline">${escapeHtml(error.message)}</div>`;
    showToast(error.message, true);
  }
};

const loadMediaWorks = async ({ preserveSelection = false } = {}) => {
  const selectedId = preserveSelection ? state.media.selected?.id : null;
  elements.mediaResultList.innerHTML = '<div class="loading-inline">Loading songs...</div>';
  const params = new URLSearchParams({
    catalog: state.media.catalog,
    version: 'all',
    membership: 'all',
    q: state.media.query,
    page: '1',
    pageSize: '100',
  });
  try {
    const response = await api(`/api/admin/works?${params}`);
    state.media.works = response.data;
    state.media.total = response.pagination?.total ?? response.data.length;
    state.media.loaded = true;
    if (selectedId && response.data.some((work) => work.id === selectedId)) {
      await selectMediaWork(selectedId, { preserveScroll: true });
      return;
    }
    clearMediaDetail();
  } catch (error) {
    state.media.works = [];
    state.media.total = 0;
    elements.mediaResultList.innerHTML = `<div class="empty-inline">${escapeHtml(error.message)}</div>`;
    showToast(error.message, true);
  }
};

const syncMediaFormOptions = ({ relationType = null, mimeType = null } = {}) => {
  const form = elements.mediaForm;
  const config = mediaTypeConfig[form.elements.mediaType.value] || mediaTypeConfig.audio;
  form.elements.relationType.innerHTML = config.relations
    .map(([value, label]) => `<option value="${value}">${escapeHtml(label)}</option>`)
    .join('');
  form.elements.mimeType.innerHTML = config.mimeTypes
    .map(([value, label]) => `<option value="${value}">${escapeHtml(label)}</option>`)
    .join('');
  if (relationType && config.relations.some(([value]) => value === relationType)) {
    form.elements.relationType.value = relationType;
  }
  if (mimeType && config.mimeTypes.some(([value]) => value === mimeType)) {
    form.elements.mimeType.value = mimeType;
  }
};

const syncMediaUrlRequirement = () => {
  elements.mediaForm.elements.publicUrl.required =
    elements.mediaForm.elements.storageProvider.value !== 'app_asset';
};

const openMediaDialog = (item = null) => {
  const form = elements.mediaForm;
  form.reset();
  state.media.editing = item;
  elements.mediaDialogTitle.textContent = item ? 'Edit media connection' : 'Add media connection';
  form.elements.linkId.value = item?.id || '';
  form.elements.mediaType.value = item?.asset?.mediaType || 'audio';
  syncMediaFormOptions({
    relationType: item?.relationType,
    mimeType: item?.asset?.mimeType,
  });
  form.elements.storageProvider.value = item?.asset?.storageProvider || 'external';
  form.elements.publicUrl.value = item?.asset?.publicUrl || '';
  form.elements.storageKey.value = item?.asset?.storageKey || '';
  form.elements.sortOrder.value = item?.sortOrder ?? 0;
  form.elements.pageLabel.value = item?.asset?.pageLabel || '';
  form.elements.fileSizeBytes.value = item?.asset?.fileSizeBytes || '';
  form.elements.checksumSha256.value = item?.asset?.checksumSha256 || '';
  form.elements.notes.value = item?.notes || '';
  syncMediaUrlRequirement();
  elements.mediaDialog.showModal();
  form.elements.publicUrl.focus();
};

const comparisonSection = (title, before, after, renderer) => {
  const isChanged = changed(before, after);
  return `
    <section class="review-section">
      <div class="section-heading">
        <h3>${escapeHtml(title)}</h3>
        <span>${isChanged ? 'Changed in this revision' : 'No change'}</span>
      </div>
      <div class="comparison-grid">
        <div class="comparison-column ${isChanged ? 'changed' : ''}">
          <div class="comparison-label">Approved baseline</div>
          ${renderer(before)}
        </div>
        <div class="comparison-column ${isChanged ? 'changed' : ''}">
          <div class="comparison-label">Submitted revision</div>
          ${renderer(after)}
        </div>
      </div>
    </section>
  `;
};

const renderQueue = () => {
  elements.queueHeading.textContent = statusLabel(state.status);
  elements.queueSummary.textContent = `${state.queue.length.toLocaleString()} ${
    state.queue.length === 1 ? 'submission' : 'submissions'
  }`;
  elements.pendingCount.textContent = `${state.queue.length.toLocaleString()} ${
    state.status === 'submitted' ? 'pending' : state.status.replace('_', ' ')
  }`;
  if (state.queue.length === 0) {
    elements.queueList.innerHTML = `<div class="empty-inline">No ${escapeHtml(
      statusLabel(state.status).toLowerCase(),
    )} submissions.</div>`;
    return;
  }
  elements.queueList.innerHTML = state.queue
    .map(
      (item) => `
        <button class="queue-row" type="button" data-work-id="${escapeHtml(
          item.workId,
        )}" data-catalog="${escapeHtml(item.catalog)}" aria-current="${
          state.selected?.workId === item.workId &&
          state.selected?.catalog === item.catalog
        }">
          <span class="queue-row-heading">
            <strong>${escapeHtml(item.title || 'Untitled song')}</strong>
            <span class="badge ${escapeHtml(item.workflow.status)}">${escapeHtml(
              statusLabel(item.workflow.status),
            )}</span>
          </span>
          <small>${escapeHtml(item.englishTitle || catalogLabel(item.catalog))}</small>
          <span class="queue-row-meta">
            <span class="badge">${escapeHtml(catalogLabel(item.catalog))}</span>
            ${(item.entries || [])
              .map(
                (entry) =>
                  `<span class="badge">${escapeHtml(entry.version)} #${escapeHtml(
                    entry.entryNumber,
                  )}</span>`,
              )
              .join('')}
          </span>
          <small>Submitted ${escapeHtml(formatDate(item.workflow.submittedAt))}</small>
        </button>
      `,
    )
    .join('');
  elements.queueList.querySelectorAll('[data-work-id]').forEach((button) => {
    button.addEventListener('click', () =>
      selectSubmission(button.dataset.catalog, button.dataset.workId),
    );
  });
};

const clearDetail = () => {
  state.selected = null;
  elements.workspace.classList.remove('detail-open');
  elements.detailContent.hidden = true;
  elements.detailContent.innerHTML = '';
  elements.detailEmpty.hidden = false;
  renderQueue();
};

const renderComments = (comments) =>
  comments?.length
    ? comments
        .map(
          (comment) => `
            <article class="comment">
              <header><strong>${escapeHtml(
                comment.author?.displayName || 'Former team member',
              )}</strong><span>${escapeHtml(formatDate(comment.createdAt))}</span></header>
              <p>${escapeHtml(comment.body)}</p>
            </article>
          `,
        )
        .join('')
    : '<div class="empty-inline">No review discussion yet.</div>';

const changeBadges = (before, after) => {
  const areas = [
    ['Titles and notes', {
      title: before.defaultTitle,
      english: before.defaultEnglishTitle,
      notes: before.notes,
    }, {
      title: after.defaultTitle,
      english: after.defaultEnglishTitle,
      notes: after.notes,
    }],
    ['Lyrics', before.canonicalLyrics, after.canonicalLyrics],
    ['Hymnal memberships', before.entries || [], after.entries || []],
    ['Media', {
      media: before.media || [],
      entryMedia: (before.entries || []).flatMap((entry) => entry.media || []),
    }, {
      media: after.media || [],
      entryMedia: (after.entries || []).flatMap((entry) => entry.media || []),
    }],
  ];
  return areas
    .map(
      ([label, left, right]) =>
        `<span class="badge ${changed(left, right) ? 'changed' : 'unchanged'}">${escapeHtml(
          label,
        )}</span>`,
    )
    .join('');
};

const renderDecisionPanel = (work, workflow) => {
  if (workflow.status !== 'submitted') {
    const returned = workflow.status === 'changes_requested';
    return `
      <section class="decision-history ${returned ? 'returned' : ''}">
        <strong>${escapeHtml(statusLabel(workflow.status))}</strong>
        <span>${escapeHtml(workflow.reviewSummary || 'No decision note was recorded.')}</span>
        <span>${escapeHtml(
          workflow.reviewedBy?.displayName || 'Reviewer',
        )} · ${escapeHtml(formatDate(workflow.reviewedAt))}</span>
      </section>
    `;
  }
  const canReview = work.collaboration?.canReview === true;
  return `
    <section class="decision-panel">
      <div>
        <h3>Final editorial decision</h3>
        <p>${
          canReview
            ? 'Complete the checks before approving this exact revision.'
            : 'This revision must be decided by a different reviewer.'
        }</p>
      </div>
      <div class="review-checklist">
        <label><input type="checkbox" data-review-check ${canReview ? '' : 'disabled'}>Titles and lyrics are correct</label>
        <label><input type="checkbox" data-review-check ${canReview ? '' : 'disabled'}>Hymnal numbers and memberships are correct</label>
        <label><input type="checkbox" data-review-check ${canReview ? '' : 'disabled'}>Linked media was inspected</label>
        <label><input type="checkbox" data-review-check ${canReview ? '' : 'disabled'}>This revision is ready for an owner release</label>
      </div>
      <label class="decision-note">
        <span>Decision note</span>
        <textarea id="decision-note" maxlength="4000" ${
          canReview ? '' : 'disabled'
        } placeholder="Required when requesting changes; optional for approval"></textarea>
      </label>
      <div class="decision-actions">
        <button class="button button-danger" id="request-changes-button" type="button" ${
          canReview ? '' : 'disabled'
        }>Request changes</button>
        <button class="button button-primary" id="approve-button" type="button" disabled>Approve revision</button>
      </div>
    </section>
  `;
};

const bindDetailActions = (work) => {
  byId('review-back')?.addEventListener('click', () => {
    elements.workspace.classList.remove('detail-open');
  });

  byId('comment-form')?.addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      await api(
        `/api/admin/works/${encodeURIComponent(work.id)}/comments?catalog=${encodeURIComponent(
          work.catalog,
        )}`,
        {
          method: 'POST',
          body: JSON.stringify({ body: form.elements.body.value.trim() }),
        },
      );
      await selectSubmission(work.catalog, work.id, { preserveScroll: true });
      showToast('Review comment added.');
    } catch (error) {
      showToast(error.message, true);
      submit.disabled = false;
    }
  });

  const checks = [...elements.detailContent.querySelectorAll('[data-review-check]')];
  const approve = byId('approve-button');
  const syncApproval = () => {
    if (approve) approve.disabled = checks.length === 0 || !checks.every((item) => item.checked);
  };
  checks.forEach((check) => check.addEventListener('change', syncApproval));
  syncApproval();

  approve?.addEventListener('click', () => {
    elements.approvalDialog.returnValue = '';
    elements.approvalDialog.showModal();
  });
  byId('request-changes-button')?.addEventListener('click', async () => {
    const summary = byId('decision-note')?.value.trim();
    if (!summary) {
      showToast('Explain what the editor must change.', true);
      byId('decision-note')?.focus();
      return;
    }
    await decide(work, 'changes_requested', summary);
  });
};

const renderDetail = (work) => {
  const collaboration = work.collaboration || {};
  const workflow = collaboration.workflow || {};
  const before =
    workflow.baselineSnapshot && Object.keys(workflow.baselineSnapshot).length > 0
      ? workflow.baselineSnapshot
      : emptyBaseline();
  const after = snapshotOrCurrent(workflow.submittedSnapshot, work);
  elements.detailEmpty.hidden = true;
  elements.detailContent.hidden = false;
  elements.workspace.classList.add('detail-open');
  elements.detailContent.innerHTML = `
    <div class="detail-shell">
      <header class="detail-toolbar">
        <button class="button button-quiet back-button" id="review-back" type="button">Back</button>
        <div class="detail-heading">
          <span class="badge ${escapeHtml(workflow.status)}">${escapeHtml(
            statusLabel(workflow.status),
          )}</span>
          <h2>${escapeHtml(after.defaultTitle || work.defaultTitle || 'Untitled song')}</h2>
          <p>${escapeHtml(after.defaultEnglishTitle || catalogLabel(work.catalog))}</p>
        </div>
      </header>
      <div class="detail-body">
        <dl class="submission-meta">
          <div><dt>Catalog</dt><dd>${escapeHtml(catalogLabel(work.catalog))}</dd></div>
          <div><dt>Revision</dt><dd>${escapeHtml(workflow.revision)}</dd></div>
          <div><dt>Submitted by</dt><dd>${escapeHtml(
            workflow.submittedBy?.displayName || 'Unknown contributor',
          )}</dd></div>
          <div><dt>Submitted</dt><dd>${escapeHtml(formatDate(workflow.submittedAt))}</dd></div>
        </dl>

        <div class="change-summary">${changeBadges(before, after)}</div>

        ${comparisonSection('Titles and notes', before, after, fieldList)}
        ${comparisonSection(
          'Lyrics',
          before.canonicalLyrics || '',
          after.canonicalLyrics || '',
          (value) => `<pre class="review-text">${escapeHtml(value || 'No lyrics')}</pre>`,
        )}
        ${comparisonSection(
          'Hymnal memberships',
          before.entries || [],
          after.entries || [],
          entryList,
        )}
        ${comparisonSection(
          'Media review',
          { media: before.media || [], entries: before.entries || [] },
          { media: after.media || [], entries: after.entries || [] },
          (value) => mediaList(value.media, value.entries),
        )}

        <section class="review-section discussion">
          <div class="section-heading"><h3>Review discussion</h3><span>Visible to the contributor</span></div>
          <div class="comment-list">${renderComments(collaboration.comments)}</div>
          <form class="comment-form" id="comment-form">
            <textarea name="body" maxlength="4000" placeholder="Add a review comment" required></textarea>
            <button class="button button-quiet" type="submit">Add comment</button>
          </form>
        </section>

        ${renderDecisionPanel(work, workflow)}
      </div>
    </div>
  `;
  bindDetailActions(work);
};

const selectSubmission = async (
  catalog,
  workId,
  { preserveScroll = false } = {},
) => {
  const sequence = ++state.requestSequence;
  const scrollTop = preserveScroll ? elements.detailPane?.scrollTop : 0;
  elements.detailEmpty.hidden = true;
  elements.detailContent.hidden = false;
  elements.detailContent.innerHTML = '<div class="loading-inline">Loading submitted revision...</div>';
  elements.workspace.classList.add('detail-open');
  try {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(workId)}?catalog=${encodeURIComponent(catalog)}`,
    );
    if (sequence !== state.requestSequence) return;
    state.selected = { catalog, workId, work: response.data };
    renderQueue();
    renderDetail(response.data);
    if (preserveScroll && elements.detailPane) elements.detailPane.scrollTop = scrollTop;
  } catch (error) {
    if (sequence !== state.requestSequence) return;
    elements.detailContent.innerHTML = `<div class="empty-inline">${escapeHtml(error.message)}</div>`;
    showToast(error.message, true);
  }
};

const loadQueue = async ({ preserveSelection = false } = {}) => {
  const selected = preserveSelection ? state.selected : null;
  elements.queueList.innerHTML = '<div class="loading-inline">Loading review queue...</div>';
  const params = new URLSearchParams({ status: state.status });
  if (state.catalog) params.set('catalog', state.catalog);
  try {
    const response = await api(`/api/admin/review-queue?${params}`);
    state.queue = response.data;
    if (
      selected &&
      state.queue.some(
        (item) => item.catalog === selected.catalog && item.workId === selected.workId,
      )
    ) {
      state.selected = selected;
    } else {
      state.selected = null;
      elements.workspace.classList.remove('detail-open');
      elements.detailContent.hidden = true;
      elements.detailContent.innerHTML = '';
      elements.detailEmpty.hidden = false;
    }
    renderQueue();
  } catch (error) {
    elements.queueList.innerHTML = `<div class="empty-inline">${escapeHtml(error.message)}</div>`;
    showToast(error.message, true);
  }
};

const decide = async (work, decision, summary) => {
  const workflow = work.collaboration.workflow;
  const buttons = elements.detailContent.querySelectorAll('button');
  buttons.forEach((button) => { button.disabled = true; });
  try {
    await api(
      `/api/admin/works/${encodeURIComponent(work.id)}/review?catalog=${encodeURIComponent(
        work.catalog,
      )}`,
      {
        method: 'POST',
        body: JSON.stringify({
          decision,
          summary: summary || null,
          expectedRevision: workflow.revision,
          confirmed: decision === 'approved',
        }),
      },
    );
    clearDetail();
    await loadQueue();
    showToast(decision === 'approved' ? 'Revision approved.' : 'Changes requested.');
  } catch (error) {
    showToast(error.message, true);
    buttons.forEach((button) => { button.disabled = false; });
  }
};

const setWorkspace = async (workspace) => {
  if (!['reviews', 'media'].includes(workspace)) return;
  if (workspace === 'media' && state.user?.permissions?.manageMedia !== true) {
    showToast('This account cannot manage media connections.', true);
    return;
  }
  state.workspace = workspace;
  elements.reviewsWorkspace.hidden = workspace !== 'reviews';
  elements.mediaWorkspace.hidden = workspace !== 'media';
  elements.workspaceTabs.forEach((button) => {
    const active = button.dataset.workspace === workspace;
    button.classList.toggle('active', active);
    if (active) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  });
  if (workspace === 'media' && !state.media.loaded) {
    await loadMediaWorks();
  }
};

const enterReviewConsole = async () => {
  const response = await api('/api/admin/auth/me');
  if (!['owner', 'reviewer'].includes(response.data.role)) {
    throw new Error('A reviewer or owner account is required for this console.');
  }
  state.user = response.data;
  elements.authView.hidden = true;
  elements.reviewView.hidden = false;
  elements.reviewerChip.innerHTML = `<strong>${escapeHtml(
    state.user.displayName,
  )}</strong><small>${escapeHtml(state.user.role)}</small>`;
  elements.contentStudioLink.hidden = state.user.role !== 'owner';
  const mediaTab = elements.workspaceTabs.find(
    (button) => button.dataset.workspace === 'media',
  );
  if (mediaTab) mediaTab.hidden = state.user.permissions?.manageMedia !== true;
  byId('connection-label').textContent = window.location.host;
  await setWorkspace('reviews');
  await loadQueue();
  const deepLink = new URLSearchParams(window.location.search);
  const deepLinkedCatalog = deepLink.get('catalog');
  const deepLinkedWork = deepLink.get('work');
  if (
    deepLinkedWork &&
    ['sda', 'hagerigna'].includes(deepLinkedCatalog) &&
    state.queue.some(
      (item) =>
        item.catalog === deepLinkedCatalog && item.workId === deepLinkedWork,
    )
  ) {
    await selectSubmission(deepLinkedCatalog, deepLinkedWork);
  }
};

const signOut = async ({ notifyServer = true } = {}) => {
  if (notifyServer && state.user) {
    try {
      await api('/api/admin/auth/logout', { method: 'POST' });
    } catch {
      // Local sign-out still clears an expired session.
    }
  }
  state.user = null;
  state.queue = [];
  state.selected = null;
  state.media.loaded = false;
  state.media.works = [];
  state.media.selected = null;
  state.media.editing = null;
  elements.reviewView.hidden = true;
  elements.authView.hidden = false;
  elements.password.value = '';
  elements.email.focus();
};

elements.authForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const submit = event.currentTarget.querySelector('[type="submit"]');
  elements.authError.hidden = true;
  submit.disabled = true;
  try {
    const response = await api('/api/admin/auth/login', {
      method: 'POST',
      body: JSON.stringify({
        email: elements.email.value.trim(),
        password: elements.password.value,
      }),
    });
    state.user = response.data.user;
    if (!['owner', 'reviewer'].includes(response.data.user.role)) {
      await api('/api/admin/auth/logout', { method: 'POST' });
      state.user = null;
      throw new Error('A reviewer or owner account is required for this console.');
    }
    await enterReviewConsole();
  } catch (error) {
    elements.authError.textContent =
      error.status === 401 ? 'The email or password is incorrect.' : error.message;
    elements.authError.hidden = false;
  } finally {
    submit.disabled = false;
  }
});

elements.catalogFilter.addEventListener('change', () => {
  state.catalog = elements.catalogFilter.value;
  clearDetail();
  loadQueue();
});
elements.statusFilter.addEventListener('change', () => {
  state.status = elements.statusFilter.value;
  clearDetail();
  loadQueue();
});
elements.refresh.addEventListener('click', () => loadQueue({ preserveSelection: true }));
elements.workspaceTabs.forEach((button) => {
  button.addEventListener('click', () => setWorkspace(button.dataset.workspace));
});
elements.mediaSearchForm.addEventListener('submit', (event) => {
  event.preventDefault();
  state.media.query = elements.mediaSearchInput.value.trim();
  loadMediaWorks();
});
elements.mediaCatalogFilter.addEventListener('change', () => {
  state.media.catalog = elements.mediaCatalogFilter.value;
  state.media.query = elements.mediaSearchInput.value.trim();
  clearMediaDetail();
  loadMediaWorks();
});
elements.addMediaButton.addEventListener('click', () => {
  if (state.media.selected) openMediaDialog();
});
elements.cancelMedia.addEventListener('click', () => elements.mediaDialog.close());
elements.mediaForm.elements.mediaType.addEventListener('change', () => {
  syncMediaFormOptions();
});
elements.mediaForm.elements.storageProvider.addEventListener(
  'change',
  syncMediaUrlRequirement,
);
elements.mediaForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const work = state.media.selected;
  if (!work) return;
  const form = event.currentTarget;
  const submit = form.querySelector('[type="submit"]');
  const linkId = form.elements.linkId.value;
  const payload = {
    mediaType: form.elements.mediaType.value,
    relationType: form.elements.relationType.value,
    storageProvider: form.elements.storageProvider.value,
    publicUrl: form.elements.publicUrl.value.trim(),
    storageKey: form.elements.storageKey.value.trim(),
    mimeType: form.elements.mimeType.value,
    sortOrder: Number(form.elements.sortOrder.value),
    pageLabel: form.elements.pageLabel.value.trim(),
    fileSizeBytes: form.elements.fileSizeBytes.value.trim(),
    checksumSha256: form.elements.checksumSha256.value.trim(),
    notes: form.elements.notes.value.trim(),
  };
  submit.disabled = true;
  try {
    const basePath = `/api/admin/works/${encodeURIComponent(work.id)}/media`;
    await api(
      `${basePath}${linkId ? `/${encodeURIComponent(linkId)}` : ''}?catalog=${encodeURIComponent(
        state.media.catalog,
      )}`,
      {
        method: linkId ? 'PATCH' : 'POST',
        body: JSON.stringify(payload),
      },
    );
    elements.mediaDialog.close();
    await selectMediaWork(work.id, { preserveScroll: true });
    showToast(linkId ? 'Media connection updated.' : 'Media connection added.');
  } catch (error) {
    showToast(error.message, true);
  } finally {
    submit.disabled = false;
  }
});
elements.removeMediaDialog.addEventListener('close', async () => {
  const item = state.media.pendingRemove;
  state.media.pendingRemove = null;
  if (elements.removeMediaDialog.returnValue !== 'confirm' || !item) return;
  const work = state.media.selected;
  if (!work) return;
  try {
    await api(
      `/api/admin/works/${encodeURIComponent(work.id)}/media/${encodeURIComponent(
        item.id,
      )}?catalog=${encodeURIComponent(state.media.catalog)}`,
      { method: 'DELETE' },
    );
    await selectMediaWork(work.id, { preserveScroll: true });
    showToast('Media connection removed.');
  } catch (error) {
    showToast(error.message, true);
  }
});
elements.accountButton.addEventListener('click', () => {
  elements.passwordForm.reset();
  elements.accountDialog.showModal();
  elements.passwordForm.elements.currentPassword.focus();
});
elements.cancelAccount.addEventListener('click', () => elements.accountDialog.close());
elements.passwordForm.addEventListener('submit', async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const submit = form.querySelector('[type="submit"]');
  submit.disabled = true;
  try {
    await api('/api/admin/auth/change-password', {
      method: 'POST',
      body: JSON.stringify({
        currentPassword: form.elements.currentPassword.value,
        newPassword: form.elements.newPassword.value,
      }),
    });
    elements.accountDialog.close();
    form.reset();
    showToast('Password changed. Other sessions were signed out.');
  } catch (error) {
    showToast(error.message, true);
  } finally {
    submit.disabled = false;
  }
});
elements.signOut.addEventListener('click', () => signOut());
elements.approvalDialog.addEventListener('close', () => {
  if (elements.approvalDialog.returnValue !== 'confirm') return;
  const work = state.selected?.work;
  if (!work) return;
  decide(work, 'approved', byId('decision-note')?.value.trim() || null);
});

api('/api/admin/auth/session')
  .then((response) => {
    if (response.data.authenticated) return enterReviewConsole();
    return null;
  })
  .catch((error) => {
    state.user = null;
    elements.reviewView.hidden = true;
    elements.authView.hidden = false;
    elements.authError.textContent = error.message;
    elements.authError.hidden = false;
  });
