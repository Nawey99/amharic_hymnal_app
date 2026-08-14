const byId = (id) => document.getElementById(id);

const elements = {
  authView: byId('auth-view'),
  authForm: byId('auth-form'),
  authError: byId('auth-error'),
  email: byId('admin-email'),
  password: byId('admin-password'),
  studioView: byId('studio-view'),
  connectionLabel: byId('connection-label'),
  editorChip: byId('team-workspace-button'),
  teamWorkspace: byId('team-workspace-button'),
  reviewQueue: byId('review-queue-button'),
  signOut: byId('sign-out-button'),
  catalogNav: byId('catalog-nav'),
  catalogTitle: byId('catalog-title'),
  catalogNativeTitle: byId('catalog-native-title'),
  stats: byId('stats-strip'),
  search: byId('song-search'),
  versionFilter: byId('version-filter'),
  membershipFilter: byId('membership-filter'),
  membershipFilterWrap: byId('membership-filter-wrap'),
  manageEditions: byId('manage-editions-button'),
  refresh: byId('refresh-button'),
  newSong: byId('new-song-button'),
  resultCount: byId('result-count'),
  pageLabel: byId('page-label'),
  songList: byId('song-list'),
  previousPage: byId('previous-page'),
  nextPage: byId('next-page'),
  mainContent: document.querySelector('.main-content'),
  workspace: document.querySelector('.content-workspace'),
  editorEmpty: byId('editor-empty'),
  editorContent: byId('editor-content'),
  editionDialog: byId('edition-dialog'),
  closeEditionDialog: byId('close-edition-dialog'),
  editionManagerList: byId('edition-manager-list'),
  editionForm: byId('edition-form'),
  editionFormTitle: byId('edition-form-title'),
  editionFormCaption: byId('edition-form-caption'),
  editionId: byId('edition-id'),
  copyEditionField: byId('copy-edition-field'),
  copyFromVersion: byId('copy-from-version'),
  newEditionForm: byId('new-edition-form'),
  saveEdition: byId('save-edition'),
  mergeDialog: byId('merge-dialog'),
  mergeSearch: byId('merge-search'),
  mergeCandidates: byId('merge-candidates'),
  confirmDialog: byId('confirm-dialog'),
  confirmTitle: byId('confirm-title'),
  confirmMessage: byId('confirm-message'),
  confirmCancel: byId('confirm-cancel'),
  confirmAccept: byId('confirm-accept'),
  toast: byId('toast'),
  collaborationDialog: byId('collaboration-dialog'),
  closeCollaborationDialog: byId('close-collaboration-dialog'),
  workspaceTabs: byId('workspace-tabs'),
  workspacePanel: byId('workspace-panel'),
  apiStatus: byId('api-status'),
  apiPath: byId('api-path'),
  apiStatusDot: byId('api-status-dot'),
};

const state = {
  user: null,
  dashboard: null,
  catalog: 'sda',
  version: 'all',
  membership: 'all',
  query: '',
  page: 1,
  pageSize: 40,
  totalPages: 1,
  works: [],
  selectedWork: null,
  activeTab: 'content',
  activeContentView: 'shared',
  editingEdition: null,
  editorDirty: false,
  requestSequence: 0,
  workspaceTab: 'assignments',
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
  if (!value) return '';
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return '';
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
    error.details = body?.details;
    if (response.status === 401 && state.user) {
      queueMicrotask(() => signOut({ notifyServer: false }));
    }
    throw error;
  }
  return body;
};

const catalogSummary = (catalogId = state.catalog) =>
  state.dashboard?.catalogs.find((catalog) => catalog.id === catalogId);

const catalogVersions = () => catalogSummary()?.versions || [];

const editionBadge = (entry) => {
  const shortLabel =
    entry.edition?.publicationYear ||
    entry.nativeVersionLabel ||
    entry.versionLabel ||
    entry.version;
  return `<span class="badge green">${escapeHtml(shortLabel)} #${escapeHtml(
    entry.entryNumber,
  )}</span>`;
};

const workflowLabel = (status) =>
  ({
    draft: 'Draft',
    submitted: 'In review',
    changes_requested: 'Changes requested',
    approved: 'Approved',
  })[status] || 'Approved';

const workflowBadge = (work) => {
  const status = work.collaboration?.workflow?.status || 'approved';
  const tone =
    status === 'approved'
      ? 'green'
      : status === 'changes_requested'
        ? 'red'
        : 'amber';
  return `<span class="badge ${tone}">${escapeHtml(
    workflowLabel(status),
  )}</span>`;
};

const setConnectionStatus = (available, label = 'Connected') => {
  elements.apiStatus.textContent = label;
  elements.apiStatusDot.classList.toggle('error', !available);
};

const enterStudio = async () => {
  const me = await api('/api/admin/auth/me');
  if (me.data.role === 'reviewer') {
    window.location.replace('/admin/review');
    return;
  }
  const dashboard = await api('/api/admin/dashboard');
  state.user = me.data;
  state.dashboard = dashboard.data;
  const availableCatalog =
    state.dashboard.catalogs.find(
      (catalog) => catalog.id === state.catalog && catalog.available,
    ) || state.dashboard.catalogs.find((catalog) => catalog.available);
  if (!availableCatalog) {
    throw new Error('Neither content database is available.');
  }
  state.catalog = availableCatalog.id;
  elements.authView.hidden = true;
  elements.studioView.hidden = false;
  elements.editorChip.innerHTML = `<strong>${escapeHtml(
    state.user.displayName,
  )}</strong><small>${escapeHtml(state.user.role)}</small>`;
  elements.manageEditions.hidden = !state.user.permissions.manageEditions;
  elements.reviewQueue.hidden = state.user.permissions.review !== true;
  elements.newSong.hidden =
    state.user.role === 'editor' &&
    !(state.dashboard.collaboration.assignments || []).some(
      (assignment) => assignment.status === 'active',
    );
  elements.connectionLabel.textContent = window.location.host;
  renderCatalogNavigation();
  setCatalog(state.catalog, { reload: false });
  await loadWorks();
};

const signOut = async ({ notifyServer = true } = {}) => {
  if (notifyServer && state.user) {
    try {
      await api('/api/admin/auth/logout', { method: 'POST' });
    } catch {
      // A local sign-out still clears an expired or unreachable session.
    }
  }
  state.user = null;
  state.dashboard = null;
  clearEditor();
  elements.studioView.hidden = true;
  elements.authView.hidden = false;
  elements.password.value = '';
  elements.email.focus();
};

const renderCatalogNavigation = () => {
  elements.catalogNav.innerHTML = state.dashboard.catalogs
    .map(
      (catalog) => `
        <button
          class="catalog-button"
          type="button"
          data-catalog="${escapeHtml(catalog.id)}"
          aria-current="${catalog.id === state.catalog ? 'page' : 'false'}"
          ${catalog.available ? '' : 'disabled'}
        >
          <span class="catalog-icon" aria-hidden="true">${
            catalog.id === 'sda' ? 'S' : 'H'
          }</span>
          <span>
            <strong>${escapeHtml(catalog.label)}</strong>
            <small>${
              catalog.available
                ? escapeHtml(catalog.nativeLabel)
                : 'Database unavailable'
            }</small>
          </span>
        </button>
      `,
    )
    .join('');

  elements.catalogNav
    .querySelectorAll('[data-catalog]')
    .forEach((button) => {
      button.addEventListener('click', () => setCatalog(button.dataset.catalog));
    });
};

const renderStats = () => {
  const summary = catalogSummary();
  const stats = [
    ['Canonical songs', summary.workCount],
    ['Hymnal memberships', summary.entryCount],
    ['Hymnals', summary.editionCount],
    ['Draft hymnals', summary.draftEditionCount],
  ];
  elements.stats.innerHTML = stats
    .map(
      ([label, value]) => `
        <div class="stat">
          <strong>${Number(value || 0).toLocaleString()}</strong>
          <span>${escapeHtml(label)}</span>
        </div>
      `,
    )
    .join('');
};

const renderFilters = () => {
  const versions = catalogVersions();
  elements.versionFilter.innerHTML = [
    '<option value="all">All editions</option>',
    ...versions.map(
      (version) =>
        `<option value="${escapeHtml(version.id)}">${escapeHtml(
          version.nativeLabel,
        )}${version.status === 'draft' ? ' · Draft' : ''}</option>`,
    ),
  ].join('');
  elements.versionFilter.value = state.version;
  if (state.version === 'all') state.membership = 'all';
  elements.membershipFilter.disabled = state.version === 'all';
  elements.membershipFilter.value = state.membership;
};

const renderEditionManagerList = () => {
  const versions = catalogVersions();
  elements.editionManagerList.innerHTML = versions
    .map(
      (version) => `
        <button
          class="edition-manager-row"
          type="button"
          data-edit-edition="${escapeHtml(version.editionId)}"
          aria-current="${
            state.editingEdition?.editionId === version.editionId
              ? 'true'
              : 'false'
          }"
        >
          <span>
            <strong>${escapeHtml(version.nativeLabel)}</strong>
            <small>${escapeHtml(version.id)} · ${Number(
              version.entryCount || 0,
            ).toLocaleString()} songs</small>
          </span>
          <span class="badge ${
            version.status === 'published' ? 'green' : 'amber'
          }">${escapeHtml(version.status)}</span>
        </button>
      `,
    )
    .join('');
  elements.editionManagerList
    .querySelectorAll('[data-edit-edition]')
    .forEach((button) => {
      button.addEventListener('click', () => {
        const edition = versions.find(
          (item) => item.editionId === button.dataset.editEdition,
        );
        if (edition) editEditionForm(edition);
      });
    });
};

const populateCopyOptions = () => {
  elements.copyFromVersion.innerHTML = [
    '<option value="">Start with an empty song list</option>',
    ...catalogVersions().map(
      (version) =>
        `<option value="${escapeHtml(version.id)}">Reuse ${escapeHtml(
          version.nativeLabel,
        )} song list</option>`,
    ),
  ].join('');
};

const resetEditionForm = () => {
  state.editingEdition = null;
  elements.editionForm.reset();
  elements.editionId.value = '';
  elements.editionForm.elements.versionKey.disabled = false;
  elements.editionForm.elements.status.value = 'draft';
  elements.copyEditionField.hidden = false;
  elements.editionFormTitle.textContent = 'Create hymnal';
  elements.editionFormCaption.textContent =
    'Start empty or reuse memberships from an existing hymnal.';
  elements.saveEdition.textContent = 'Create hymnal';
  populateCopyOptions();
  renderEditionManagerList();
};

const editEditionForm = (edition) => {
  state.editingEdition = edition;
  const form = elements.editionForm;
  elements.editionId.value = edition.editionId;
  form.elements.nativeTitle.value = edition.nativeLabel;
  form.elements.title.value = edition.label;
  form.elements.versionKey.value = edition.id;
  form.elements.versionKey.disabled = true;
  form.elements.publicationYear.value = edition.publicationYear || '';
  form.elements.status.value = edition.status;
  form.elements.sourceNote.value = edition.sourceNote || '';
  elements.copyEditionField.hidden = true;
  elements.editionFormTitle.textContent = 'Edit hymnal';
  elements.editionFormCaption.textContent =
    'The API key remains stable after a hymnal is created.';
  elements.saveEdition.textContent = 'Save hymnal';
  renderEditionManagerList();
};

const openEditionManager = () => {
  resetEditionForm();
  elements.editionDialog.showModal();
};

const saveEdition = async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const editing = state.editingEdition;
  const payload = {
    title: form.elements.title.value,
    nativeTitle: form.elements.nativeTitle.value,
    publicationYear: form.elements.publicationYear.value,
    status: form.elements.status.value,
    sourceNote: form.elements.sourceNote.value,
    ...(editing
      ? {}
      : {
          versionKey: form.elements.versionKey.value,
          copyFromVersion: form.elements.copyFromVersion.value || null,
        }),
  };
  elements.saveEdition.disabled = true;
  try {
    const response = await api(
      editing
        ? `/api/admin/editions/${encodeURIComponent(
            editing.editionId,
          )}?catalog=${encodeURIComponent(state.catalog)}`
        : `/api/admin/editions?catalog=${encodeURIComponent(state.catalog)}`,
      {
        method: editing ? 'PATCH' : 'POST',
        body: JSON.stringify(payload),
      },
    );
    await refreshDashboard();
    state.version = response.data.id;
    state.membership = 'included';
    state.page = 1;
    renderFilters();
    elements.editionDialog.close();
    showToast(editing ? 'Hymnal updated.' : 'Hymnal created with shared songs.');
    await loadWorks();
  } catch (error) {
    showToast(error.message, true);
  } finally {
    elements.saveEdition.disabled = false;
  }
};

const setCatalog = async (catalogId, { reload = true } = {}) => {
  const summary = catalogSummary(catalogId);
  if (!summary?.available) return;
  state.catalog = catalogId;
  state.version = 'all';
  state.membership = 'all';
  state.query = '';
  state.page = 1;
  state.selectedWork = null;
  state.activeTab = 'content';
  state.activeContentView = 'shared';
  elements.search.value = '';
  elements.catalogTitle.textContent = summary.label;
  elements.catalogNativeTitle.textContent = summary.nativeLabel;
  elements.apiPath.textContent =
    state.dashboard.publicApi[
      catalogId === 'sda' ? 'sdaNew' : 'hagerigna'
    ];
  setConnectionStatus(true);
  renderCatalogNavigation();
  renderStats();
  renderFilters();
  clearEditor();
  if (reload) await loadWorks();
};

const listLoading = () => {
  elements.songList.innerHTML =
    '<div class="loading-inline">Loading songs...</div>';
};

const loadWorks = async () => {
  const sequence = ++state.requestSequence;
  listLoading();
  const params = new URLSearchParams({
    catalog: state.catalog,
    version: state.version,
    membership: state.membership,
    q: state.query,
    page: String(state.page),
    pageSize: String(state.pageSize),
  });
  try {
    const response = await api(`/api/admin/works?${params}`);
    if (sequence !== state.requestSequence) return;
    state.works = response.data;
    state.totalPages = response.pagination.totalPages;
    state.page = response.pagination.page;
    renderWorkList(response.pagination);
    setConnectionStatus(true);
  } catch (error) {
    if (sequence !== state.requestSequence) return;
    elements.songList.innerHTML = `<div class="empty-inline">${escapeHtml(
      error.message,
    )}</div>`;
    setConnectionStatus(false, 'Database unavailable');
    showToast(error.message, true);
  }
};

const renderWorkList = (pagination) => {
  elements.resultCount.textContent = `${pagination.total.toLocaleString()} ${
    pagination.total === 1 ? 'song' : 'songs'
  }`;
  elements.pageLabel.textContent = `Page ${pagination.page} of ${pagination.totalPages}`;
  elements.previousPage.disabled = pagination.page <= 1;
  elements.nextPage.disabled = pagination.page >= pagination.totalPages;
  if (state.works.length === 0) {
    elements.songList.innerHTML =
      '<div class="empty-inline">No songs match these filters.</div>';
    return;
  }
  elements.songList.innerHTML = state.works
    .map(
      (work) => `
        <button
          class="song-row"
          type="button"
          data-work-id="${escapeHtml(work.id)}"
          aria-current="${state.selectedWork?.id === work.id ? 'true' : 'false'}"
        >
          <span class="song-row-main">
            <strong>${escapeHtml(work.defaultTitle)}</strong>
            <small>${escapeHtml(work.defaultEnglishTitle || work.canonicalKey)}</small>
            <span class="entry-badges">
              ${work.entries.map(editionBadge).join('')}
              ${workflowBadge(work)}
            </span>
          </span>
          <span class="row-chevron" aria-hidden="true">›</span>
        </button>
      `,
    )
    .join('');
  elements.songList.querySelectorAll('[data-work-id]').forEach((button) => {
    button.addEventListener('click', () => selectWork(button.dataset.workId));
  });
};

const clearEditor = () => {
  elements.studioView.classList.remove('focus-editor-mode');
  elements.mainContent.classList.remove('editor-mode');
  elements.workspace.classList.remove('editor-open');
  elements.editorEmpty.hidden = false;
  elements.editorContent.hidden = true;
  elements.editorContent.innerHTML = '';
  state.selectedWork = null;
  state.activeTab = 'content';
  state.activeContentView = 'shared';
  state.editorDirty = false;
  elements.songList
    .querySelectorAll('[data-work-id]')
    .forEach((button) => button.setAttribute('aria-current', 'false'));
};

const selectWork = async (workId) => {
  elements.studioView.classList.add('focus-editor-mode');
  elements.mainContent.classList.add('editor-mode');
  elements.workspace.classList.add('editor-open');
  elements.editorEmpty.hidden = true;
  elements.editorContent.hidden = false;
  elements.editorContent.innerHTML =
    '<div class="loading-inline">Loading song...</div>';
  try {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(workId)}?catalog=${encodeURIComponent(
        state.catalog,
      )}`,
    );
    state.selectedWork = response.data;
    state.activeTab = 'content';
    state.activeContentView = 'shared';
    state.editorDirty = false;
    renderEditor();
    renderWorkList({
      total: Number(
        elements.resultCount.textContent.replace(/[^\d]/g, '') || 0,
      ),
      page: state.page,
      totalPages: state.totalPages,
    });
  } catch (error) {
    clearEditor();
    showToast(error.message, true);
  }
};

const showCreateEditor = () => {
  const versions = catalogVersions();
  const preferredVersion =
    state.version !== 'all'
      ? state.version
      : versions.find(
          (version) =>
            version.isActive && version.status !== 'archived',
        )?.id;
  state.selectedWork = {
    id: null,
    catalog: state.catalog,
    canonicalKey: '',
    defaultTitle: '',
    defaultEnglishTitle: '',
    canonicalLyrics: '',
    notes: '',
    entries: versions.map((version) => ({
      id: null,
      version: version.id,
      versionLabel: version.label,
      nativeVersionLabel: version.nativeLabel,
      edition: version,
      entryNumber: '',
      titleOverride: null,
      englishTitleOverride: null,
      lyricsOverride: null,
      hasContentOverrides: false,
      metadata: {},
      isActive: true,
      included: version.id === preferredVersion,
    })),
    media: [],
    updatedAt: null,
    isDraft: true,
  };
  state.activeTab = 'content';
  state.activeContentView = 'shared';
  state.editorDirty = false;
  elements.studioView.classList.add('focus-editor-mode');
  elements.mainContent.classList.add('editor-mode');
  elements.workspace.classList.add('editor-open');
  elements.editorEmpty.hidden = true;
  elements.editorContent.hidden = false;
  renderEditor();
};

const editorBackButton = () => `
  <button class="button button-quiet editor-back" id="editor-back" type="button">
    <span aria-hidden="true">&#8592;</span>
    <span class="editor-back-label">Songs</span>
  </button>
`;

const requestEditorClose = async () => {
  if (
    state.editorDirty &&
    !(await askConfirmation(
      'Discard unsaved changes?',
      'Your title, lyrics, or hymnal changes have not been saved.',
      'Discard changes',
    ))
  ) {
    return;
  }
  clearEditor();
};

const requestEditorTab = async (tab) => {
  if (tab === state.activeTab) return;
  if (
    state.activeTab === 'content' &&
    state.editorDirty &&
    !(await askConfirmation(
      'Discard unsaved changes?',
      'Save the song before moving to another section, or discard the current edits.',
      'Discard changes',
    ))
  ) {
    return;
  }
  state.editorDirty = false;
  state.activeTab = tab;
  renderEditor();
};

const markEditorDirty = () => {
  if (state.editorDirty) return;
  state.editorDirty = true;
  const status = byId('editor-status');
  if (status) {
    status.textContent = 'Unsaved changes';
    status.classList.add('is-dirty');
  }
};

const renderEditor = () => {
  const work = state.selectedWork;
  if (!work) return clearEditor();
  const canMerge =
    !work.isDraft &&
    state.catalog === 'sda' &&
    work.entries.length < catalogVersions().length &&
    state.user?.permissions.editAllContent === true;
  const workflowStatus = work.isDraft
    ? 'draft'
    : work.collaboration?.workflow?.status || 'approved';
  const canEdit =
    (work.isDraft || work.collaboration?.canEdit !== false) &&
    workflowStatus !== 'submitted';
  elements.editorContent.innerHTML = `
    <div class="editor-shell editor-tab-${escapeHtml(state.activeTab)}">
      <div class="editor-toolbar">
        <header class="editor-header">
          <div class="editor-header-main">
            ${editorBackButton()}
            <div class="editor-heading-text">
              <span class="editor-context" id="editor-status">${escapeHtml(
                work.isDraft ? 'New song' : workflowLabel(workflowStatus),
              )}</span>
              <h2>${escapeHtml(work.defaultTitle || 'Untitled song')}</h2>
              <p>${escapeHtml(work.defaultEnglishTitle || work.canonicalKey || 'Not saved yet')}</p>
            </div>
          </div>
          <div class="editor-header-actions">
            ${
              state.activeTab === 'content'
                ? `<button class="button button-primary" id="save-song-button" type="submit" form="content-form" ${
                    canEdit ? '' : 'disabled'
                  }>
                    ${work.isDraft ? 'Create song' : 'Save changes'}
                  </button>`
                : ''
            }
          </div>
        </header>
        <div class="editor-tabs" role="tablist">
          <button class="tab-button" type="button" data-tab="content" role="tab">
            Song
          </button>
          <button class="tab-button" type="button" data-tab="history" role="tab" ${
            work.isDraft ? 'disabled' : ''
          }>
            History
          </button>
          <button class="tab-button" type="button" data-tab="workflow" role="tab" ${
            work.isDraft ? 'disabled' : ''
          }>
            Review
          </button>
        </div>
      </div>
      <div class="editor-body" id="editor-tab-body"></div>
    </div>
  `;

  byId('editor-back')?.addEventListener('click', requestEditorClose);
  elements.editorContent.querySelectorAll('[data-tab]').forEach((button) => {
    button.setAttribute(
      'aria-selected',
      button.dataset.tab === state.activeTab ? 'true' : 'false',
    );
    button.addEventListener('click', () => requestEditorTab(button.dataset.tab));
  });

  if (state.activeTab === 'history') renderHistoryTab();
  else if (state.activeTab === 'workflow') renderWorkflowTab();
  else renderContentTab(canMerge && canEdit, canEdit);
};

const membershipTabMeta = (entry) => {
  const included = Boolean(entry?.id || entry?.included);
  if (!included) return 'Not included';
  if (!entry?.entryNumber) return 'Number needed';
  return `#${entry.entryNumber} · ${
    entry?.hasContentOverrides ? 'Custom content' : 'Shared content'
  }`;
};

const contentViewTab = (version, entry, active) => `
  <button
    class="content-view-tab ${entry?.id || entry?.included ? 'is-included' : ''}"
    id="content-tab-${escapeHtml(version.id)}"
    type="button"
    role="tab"
    data-content-view="${escapeHtml(version.id)}"
    aria-controls="content-panel-${escapeHtml(version.id)}"
    aria-selected="${active}"
    tabindex="${active ? '0' : '-1'}"
  >
    <span>${escapeHtml(version.nativeLabel)}</span>
    <small data-version-tab-meta>${escapeHtml(membershipTabMeta(entry))}</small>
  </button>
`;

const sharedContentReference = (work) => `
  <aside class="shared-reference" aria-label="Shared song reference">
    <div class="shared-reference-heading">
      <span>
        <strong>Shared source</strong>
        <small>Used by every hymnal unless this version has an override.</small>
      </span>
      <span class="reference-badge">Read only</span>
    </div>
    <dl class="shared-reference-titles">
      <div>
        <dt>Amharic title</dt>
        <dd data-shared-title>${escapeHtml(work.defaultTitle || 'Not entered yet')}</dd>
      </div>
      <div>
        <dt>English title</dt>
        <dd data-shared-english-title>${escapeHtml(
          work.defaultEnglishTitle || 'Not entered yet',
        )}</dd>
      </div>
    </dl>
    <div class="shared-reference-lyrics" data-shared-lyrics>${escapeHtml(
      work.canonicalLyrics || 'Lyrics have not been entered yet.',
    )}</div>
  </aside>
`;

const entrySection = (
  version,
  entry,
  work,
  active,
  canEditMembership = true,
) => {
  const existing = Boolean(entry?.id);
  const included = existing || entry?.included === true;
  const usesOverrides = entry?.hasContentOverrides === true;
  const artist = entry?.metadata?.artist || '';
  const archived = version.status === 'archived';
  const cannotRemove =
    !canEditMembership || (existing && work.entries.length <= 1);
  const membershipDisabled = !canEditMembership || !included;
  return `
    <section
      class="content-view-panel edition-section ${
        included ? 'entry-included' : 'entry-inactive'
      }"
      id="content-panel-${escapeHtml(version.id)}"
      role="tabpanel"
      aria-labelledby="content-tab-${escapeHtml(version.id)}"
      data-content-panel="${escapeHtml(version.id)}"
      data-entry
      data-entry-id="${escapeHtml(entry?.id || '')}"
      data-version="${escapeHtml(version.id)}"
      data-existing="${existing}"
      data-membership-editable="${canEditMembership}"
      ${active ? '' : 'hidden'}
    >
      <header class="edition-heading">
        <div class="edition-heading-copy">
          <span class="eyebrow">Hymnal version</span>
          <div class="edition-title-line">
            <h3>${escapeHtml(version.nativeLabel)}</h3>
            <span class="membership-status" data-membership-status>
              ${canEditMembership ? (included ? 'Included' : 'Not included') : 'Read only'}
            </span>
          </div>
          <p>${escapeHtml(version.label)} · ${escapeHtml(
            version.status || 'draft',
          )}</p>
        </div>
        <div class="membership-actions">
          ${
            existing
              ? `
                <button
                  class="text-button danger"
                  type="button"
                  data-remove-membership="${escapeHtml(entry.id)}"
                  ${cannotRemove ? 'disabled' : ''}
                  title="${
                    cannotRemove
                      ? !canEditMembership
                        ? 'This hymnal is outside your assignment.'
                        : 'A song must remain in at least one hymnal.'
                      : 'Remove only from this hymnal'
                  }"
                >
                  Remove from hymnal
                </button>
                <input type="checkbox" data-field="included" checked disabled hidden>
              `
              : `
                <label class="include-toggle">
                  <input
                    type="checkbox"
                    data-field="included"
                    ${included ? 'checked' : ''}
                    ${archived || !canEditMembership ? 'disabled' : ''}
                  >
                  ${archived ? 'Archived' : 'Include in this hymnal'}
                </label>
              `
          }
        </div>
      </header>

      <div class="edition-not-included" data-not-included ${included ? 'hidden' : ''}>
        <strong>This song is not part of ${escapeHtml(version.nativeLabel)}.</strong>
        <p>Include it above to assign a hymn number. The shared title and lyrics will be reused.</p>
      </div>

      <div class="entry-fields" ${included ? '' : 'hidden'}>
        <section class="edition-membership-fields">
          <div class="section-heading compact-section-heading">
            <span>
              <strong>Version details</strong>
              <span>Only the hymn number and availability belong to this edition.</span>
            </span>
          </div>
          <div class="edition-basics-grid">
            <label>
              <span>Hymn number</span>
              <input
                type="number"
                min="1"
                max="100000"
                data-field="entryNumber"
                value="${escapeHtml(entry?.entryNumber || '')}"
                ${membershipDisabled ? 'disabled' : ''}
                required
              >
            </label>
            ${
              state.catalog === 'hagerigna'
                ? `
                  <label class="entry-artist">
                    <span>Artist</span>
                    <input
                      type="text"
                      maxlength="300"
                      data-field="artist"
                      value="${escapeHtml(artist)}"
                      ${membershipDisabled ? 'disabled' : ''}
                    >
                  </label>
                `
                : ''
            }
            <label class="entry-active toggle-line">
              <input
                type="checkbox"
                data-field="isActive"
                ${entry?.isActive !== false ? 'checked' : ''}
                ${membershipDisabled ? 'disabled' : ''}
              >
              Available in the app
            </label>
          </div>
        </section>

        <section class="edition-copy-editor">
          <div class="edition-copy-heading">
            <span>
              <strong>Title and lyrics</strong>
              <small>Keep the shared source unless this printed hymnal is different.</small>
            </span>
            <label class="override-toggle toggle-line">
              <input
                type="checkbox"
                data-field="useOverrides"
                ${usesOverrides ? 'checked' : ''}
                ${membershipDisabled ? 'disabled' : ''}
              >
              Use different content for this hymnal
            </label>
          </div>
          <div class="version-content-grid ${usesOverrides ? 'has-overrides' : ''}" data-version-content-grid>
            ${sharedContentReference(work)}
            <div class="override-fields" data-override-fields ${
              usesOverrides ? '' : 'hidden'
            }>
              <div class="override-heading">
                <strong>This version</strong>
                <small>Edit only what differs from the shared source.</small>
              </div>
              <label>
                <span>Amharic title</span>
                <input
                  type="text"
                  maxlength="300"
                  data-field="titleOverride"
                  value="${escapeHtml(entry?.titleOverride || '')}"
                  ${canEditMembership && included && usesOverrides ? '' : 'disabled'}
                  placeholder="${escapeHtml(work.defaultTitle || '')}"
                >
              </label>
              <label>
                <span>English title</span>
                <input
                  type="text"
                  maxlength="300"
                  data-field="englishTitleOverride"
                  value="${escapeHtml(entry?.englishTitleOverride || '')}"
                  ${canEditMembership && included && usesOverrides ? '' : 'disabled'}
                  placeholder="${escapeHtml(work.defaultEnglishTitle || '')}"
                >
              </label>
              <label class="override-lyrics-field">
                <span>Lyrics</span>
                <textarea
                  class="lyrics-textarea"
                  data-field="lyricsOverride"
                  spellcheck="true"
                  ${canEditMembership && included && usesOverrides ? '' : 'disabled'}
                  placeholder="Enter the lyrics printed in this hymnal"
                >${escapeHtml(entry?.lyricsOverride || '')}</textarea>
              </label>
            </div>
          </div>
        </section>
      </div>
    </section>
  `;
};

const renderContentTab = (canMerge, canEdit = true) => {
  const work = state.selectedWork;
  const editableEntryIds = new Set(
    work.collaboration?.editableEntryIds || work.entries.map((entry) => entry.id),
  );
  const editableVersionKeys = new Set(
    work.collaboration?.editableVersionKeys || ['*'],
  );
  const canEditVersion = (version, entry) =>
    canEdit &&
    (editableVersionKeys.has('*') ||
      (entry?.id
        ? editableEntryIds.has(entry.id)
        : editableVersionKeys.has(version.id)));
  const versions = catalogVersions();
  const entriesByVersion = new Map(
    work.entries.map((entry) => [entry.version, entry]),
  );
  const validViews = new Set(['shared', ...versions.map((version) => version.id)]);
  if (!validViews.has(state.activeContentView)) {
    state.activeContentView = 'shared';
  }
  const includedCount = versions.filter((version) => {
    const entry = entriesByVersion.get(version.id);
    return Boolean(entry?.id || entry?.included);
  }).length;
  const sharedActive = state.activeContentView === 'shared';

  byId('editor-tab-body').innerHTML = `
    <form id="content-form" class="content-form">
      <nav class="content-view-tabs" role="tablist" aria-label="Song and hymnal versions">
        <button
          class="content-view-tab shared-view-tab is-included"
          id="content-tab-shared"
          type="button"
          role="tab"
          data-content-view="shared"
          aria-controls="content-panel-shared"
          aria-selected="${sharedActive}"
          tabindex="${sharedActive ? '0' : '-1'}"
        >
          <span>Shared song</span>
          <small id="shared-membership-meta">${includedCount} ${
            includedCount === 1 ? 'hymnal' : 'hymnals'
          }</small>
        </button>
        ${versions
          .map((version) =>
            contentViewTab(
              version,
              entriesByVersion.get(version.id),
              state.activeContentView === version.id,
            ),
          )
          .join('')}
      </nav>

      <div class="content-view-panels">
        <section
          class="content-view-panel canonical-editor"
          id="content-panel-shared"
          role="tabpanel"
          aria-labelledby="content-tab-shared"
          data-content-panel="shared"
          ${sharedActive ? '' : 'hidden'}
        >
          <div class="panel-introduction">
            <span>
              <span class="eyebrow">Reusable song</span>
              <h3>Shared title and lyrics</h3>
            </span>
            <p>Edit the song once here. Every included hymnal reuses it unless that version has a custom override.</p>
          </div>
          <div class="form-grid canonical-fields">
            <label>
              <span>Amharic title</span>
              <input
                name="defaultTitle"
                type="text"
                maxlength="300"
                value="${escapeHtml(work.defaultTitle)}"
                required
                ${work.isDraft ? 'autofocus' : ''}
              >
            </label>
            <label>
              <span>English title</span>
              <input
                name="defaultEnglishTitle"
                type="text"
                maxlength="300"
                value="${escapeHtml(work.defaultEnglishTitle || '')}"
              >
            </label>
            <label class="span-2 canonical-lyrics-field">
              <span>Shared lyrics</span>
              <textarea
                class="lyrics-textarea"
                name="canonicalLyrics"
                spellcheck="true"
                required
              >${escapeHtml(work.canonicalLyrics || '')}</textarea>
            </label>
          </div>
          <details class="advanced-fields">
            <summary>Internal notes</summary>
            <label>
              <span class="sr-only">Internal notes</span>
              <textarea name="notes" maxlength="4000">${escapeHtml(
                work.notes || '',
              )}</textarea>
            </label>
          </details>
          ${
            canMerge
              ? `
                <details class="advanced-fields">
                  <summary>More actions</summary>
                  <button class="button button-quiet" id="open-merge" type="button">
                    Merge duplicate
                  </button>
                </details>
              `
              : ''
          }
        </section>

        ${versions
          .map((version) =>
            entrySection(
              version,
              entriesByVersion.get(version.id),
              work,
              state.activeContentView === version.id,
              canEditVersion(version, entriesByVersion.get(version.id)),
            ),
          )
          .join('')}
      </div>
    </form>
  `;

  const form = byId('content-form');
  if (!canEdit) {
    form
      .querySelectorAll('input, textarea, select, [data-remove-membership]')
      .forEach((control) => {
        control.disabled = true;
      });
  }
  form.addEventListener('input', markEditorDirty);

  const viewTabs = [...form.querySelectorAll('[data-content-view]')];
  const viewPanels = [...form.querySelectorAll('[data-content-panel]')];
  const activateContentView = (viewId, { focus = false } = {}) => {
    state.activeContentView = viewId;
    viewTabs.forEach((tab) => {
      const selected = tab.dataset.contentView === viewId;
      tab.setAttribute('aria-selected', String(selected));
      tab.tabIndex = selected ? 0 : -1;
      if (selected && focus) tab.focus();
    });
    viewPanels.forEach((panel) => {
      panel.hidden = panel.dataset.contentPanel !== viewId;
    });
    viewTabs
      .find((tab) => tab.dataset.contentView === viewId)
      ?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
  };

  viewTabs.forEach((tab, index) => {
    tab.addEventListener('click', () =>
      activateContentView(tab.dataset.contentView),
    );
    tab.addEventListener('keydown', (event) => {
      let nextIndex = null;
      if (event.key === 'ArrowRight') nextIndex = (index + 1) % viewTabs.length;
      if (event.key === 'ArrowLeft') {
        nextIndex = (index - 1 + viewTabs.length) % viewTabs.length;
      }
      if (event.key === 'Home') nextIndex = 0;
      if (event.key === 'End') nextIndex = viewTabs.length - 1;
      if (nextIndex === null) return;
      event.preventDefault();
      activateContentView(viewTabs[nextIndex].dataset.contentView, {
        focus: true,
      });
    });
  });

  const syncSharedReferences = () => {
    const title = form.elements.defaultTitle.value || 'Not entered yet';
    const englishTitle =
      form.elements.defaultEnglishTitle.value || 'Not entered yet';
    const lyrics =
      form.elements.canonicalLyrics.value || 'Lyrics have not been entered yet.';
    form.querySelectorAll('[data-shared-title]').forEach((element) => {
      element.textContent = title;
    });
    form.querySelectorAll('[data-shared-english-title]').forEach((element) => {
      element.textContent = englishTitle;
    });
    form.querySelectorAll('[data-shared-lyrics]').forEach((element) => {
      element.textContent = lyrics;
    });
    const editorTitle = elements.editorContent.querySelector(
      '.editor-heading-text h2',
    );
    const editorSubtitle = elements.editorContent.querySelector(
      '.editor-heading-text p',
    );
    if (editorTitle) editorTitle.textContent = title;
    if (editorSubtitle) {
      editorSubtitle.textContent =
        form.elements.defaultEnglishTitle.value ||
        work.canonicalKey ||
        'Not saved yet';
    }
  };
  form.elements.defaultTitle.addEventListener('input', syncSharedReferences);
  form.elements.defaultEnglishTitle.addEventListener(
    'input',
    syncSharedReferences,
  );
  form.elements.canonicalLyrics.addEventListener('input', syncSharedReferences);

  const updateMembershipSummary = () => {
    const count = [...form.querySelectorAll('[data-entry]')].filter(
      (section) =>
        section.dataset.existing === 'true' ||
        section.querySelector('[data-field="included"]')?.checked,
    ).length;
    byId('shared-membership-meta').textContent = `${count} ${
      count === 1 ? 'hymnal' : 'hymnals'
    }`;
  };

  const updateVersionPresentation = (section) => {
    const included =
      section.dataset.existing === 'true' ||
      section.querySelector('[data-field="included"]')?.checked;
    const useOverrides =
      section.querySelector('[data-field="useOverrides"]')?.checked === true;
    const number = section.querySelector('[data-field="entryNumber"]')?.value;
    const tab = viewTabs.find(
      (item) => item.dataset.contentView === section.dataset.version,
    );
    const tabMeta = tab?.querySelector('[data-version-tab-meta]');
    if (tabMeta) {
      tabMeta.textContent = !included
        ? 'Not included'
        : !number
          ? 'Number needed'
          : `#${number} · ${useOverrides ? 'Custom content' : 'Shared content'}`;
    }
    tab?.classList.toggle('is-included', Boolean(included));
    tab?.classList.toggle('has-overrides', Boolean(included && useOverrides));
    const membershipStatus = section.querySelector('[data-membership-status]');
    if (membershipStatus) {
      membershipStatus.textContent =
        section.dataset.membershipEditable === 'true'
          ? included
            ? 'Included'
            : 'Not included'
          : 'Read only';
      membershipStatus.classList.toggle('is-inactive', !included);
    }
  };

  form.querySelectorAll('[data-field="included"]').forEach((checkbox) => {
    if (checkbox.closest('[data-entry]').dataset.existing === 'true') return;
    checkbox.addEventListener('change', () => {
      const section = checkbox.closest('[data-entry]');
      section.classList.toggle('entry-inactive', !checkbox.checked);
      section.classList.toggle('entry-included', checkbox.checked);
      section.querySelector('.entry-fields').hidden = !checkbox.checked;
      section.querySelector('[data-not-included]').hidden = checkbox.checked;
      section
        .querySelectorAll(
          'input:not([data-field="included"]), textarea, select',
        )
        .forEach((field) => {
          const isOverrideField = Boolean(
            field.closest('[data-override-fields]'),
          );
          const useOverrides = section.querySelector(
            '[data-field="useOverrides"]',
          )?.checked;
          field.disabled =
            !checkbox.checked || (isOverrideField && !useOverrides);
        });
      updateVersionPresentation(section);
      updateMembershipSummary();
    });
  });

  form.querySelectorAll('[data-field="useOverrides"]').forEach((checkbox) => {
    checkbox.addEventListener('change', () => {
      const section = checkbox.closest('[data-entry]');
      const fields = section.querySelector('[data-override-fields]');
      fields.hidden = !checkbox.checked;
      fields.querySelectorAll('input, textarea').forEach((field) => {
        field.disabled = !checkbox.checked;
      });
      section
        .querySelector('[data-version-content-grid]')
        .classList.toggle('has-overrides', checkbox.checked);
      updateVersionPresentation(section);
    });
  });

  form.querySelectorAll('[data-field="entryNumber"]').forEach((input) => {
    input.addEventListener('input', () =>
      updateVersionPresentation(input.closest('[data-entry]')),
    );
  });

  form.querySelectorAll('[data-entry]').forEach(updateVersionPresentation);
  form.addEventListener(
    'invalid',
    (event) => {
      const panel = event.target.closest('[data-content-panel]');
      if (panel?.hidden) {
        activateContentView(panel.dataset.contentPanel);
      }
    },
    true,
  );
  form.querySelectorAll('[data-remove-membership]').forEach((button) => {
    button.addEventListener('click', () =>
      removeMembership(button.dataset.removeMembership),
    );
  });
  byId('open-merge')?.addEventListener('click', openMergeDialog);
  form.addEventListener('submit', saveContent);
};

const saveContent = async (event) => {
  event.preventDefault();
  const form = event.currentTarget;
  const submit = byId('save-song-button');
  const work = state.selectedWork;
  const entries = [...form.querySelectorAll('[data-entry]')]
    .filter((section) => {
      const include = section.querySelector('[data-field="included"]');
      return section.dataset.existing === 'true' || include.checked;
    })
    .map((section) => {
      const useOverrides = section.querySelector(
        '[data-field="useOverrides"]',
      )?.checked === true;
      return {
        id: section.dataset.entryId || null,
        version: section.dataset.version,
        entryNumber: section.querySelector('[data-field="entryNumber"]').value,
        useOverrides,
        titleOverride: useOverrides
          ? section.querySelector('[data-field="titleOverride"]').value
          : null,
        englishTitleOverride: useOverrides
          ? section.querySelector('[data-field="englishTitleOverride"]').value
          : null,
        lyricsOverride: useOverrides
          ? section.querySelector('[data-field="lyricsOverride"]').value
          : null,
        artist:
          section.querySelector('[data-field="artist"]')?.value || null,
        isActive:
          section.querySelector('[data-field="isActive"]')?.checked ?? true,
      };
    });

  if (entries.length === 0) {
    showToast('Choose at least one catalog edition.', true);
    return;
  }
  const payload = {
    defaultTitle: form.elements.defaultTitle.value,
    defaultEnglishTitle: form.elements.defaultEnglishTitle.value,
    canonicalLyrics: form.elements.canonicalLyrics.value,
    notes: form.elements.notes.value,
    entries,
    expectedUpdatedAt: work.updatedAt,
  };

  if (submit) {
    submit.disabled = true;
    submit.textContent = work.isDraft ? 'Creating...' : 'Saving...';
  }
  try {
    const response = work.isDraft
      ? await api(`/api/admin/works?catalog=${encodeURIComponent(state.catalog)}`, {
          method: 'POST',
          body: JSON.stringify(payload),
        })
      : await api(
          `/api/admin/works/${encodeURIComponent(
            work.id,
          )}?catalog=${encodeURIComponent(state.catalog)}`,
          {
            method: 'PATCH',
            body: JSON.stringify(payload),
          },
        );
    state.selectedWork = response.data;
    state.activeTab = 'content';
    state.editorDirty = false;
    showToast(work.isDraft ? 'Song created.' : 'Song saved.');
    await refreshCatalogData({ preserveSelection: true });
  } catch (error) {
    if (error.code === 'content_changed') {
      showToast(`${error.message}`, true);
    } else {
      showToast(error.message, true);
    }
  } finally {
    if (submit) {
      submit.disabled = false;
      submit.textContent = work.isDraft ? 'Create song' : 'Save changes';
    }
  }
};

const reloadWorkCollaboration = async (message) => {
  const response = await api(
    `/api/admin/works/${encodeURIComponent(
      state.selectedWork.id,
    )}?catalog=${encodeURIComponent(state.catalog)}`,
  );
  state.selectedWork = response.data;
  state.activeTab = 'workflow';
  state.editorDirty = false;
  renderEditor();
  await loadWorks();
  if (message) showToast(message);
};

const renderWorkflowTab = () => {
  const work = state.selectedWork;
  const collaboration = work.collaboration || {};
  const workflow = collaboration.workflow || { status: 'approved' };
  const comments = collaboration.comments || [];
  const assignmentText = (collaboration.assignments || []).length
    ? collaboration.assignments
        .map((assignment) => assignment.title)
        .join(', ')
    : 'No matching assignment is shown for this account.';
  byId('editor-tab-body').innerHTML = `
    <section class="workflow-panel">
      <div class="workflow-summary">
        <span class="badge ${
          workflow.status === 'approved'
            ? 'green'
            : workflow.status === 'changes_requested'
              ? 'red'
              : 'amber'
        }">${escapeHtml(workflowLabel(workflow.status))}</span>
        <div>
          <h3>Revision ${Number(workflow.revision || 0)}</h3>
          <p>${escapeHtml(
            workflow.reviewSummary ||
              (workflow.managed
                ? 'This song is tracked by the review workflow.'
                : 'This is approved baseline content. Its first edit will create a new draft.'),
          )}</p>
        </div>
      </div>
      <dl class="workflow-details">
        <div><dt>Assignment</dt><dd>${escapeHtml(assignmentText)}</dd></div>
        <div><dt>Last submitted</dt><dd>${escapeHtml(
          workflow.submittedAt ? formatDate(workflow.submittedAt) : 'Not submitted',
        )}</dd></div>
        <div><dt>Last reviewed</dt><dd>${escapeHtml(
          workflow.reviewedAt ? formatDate(workflow.reviewedAt) : 'Not reviewed',
        )}</dd></div>
      </dl>
      <div class="workflow-actions">
        ${
          collaboration.canSubmit
            ? '<button class="button button-primary" id="submit-review-button" type="button">Submit for review</button>'
            : ''
        }
        ${
          collaboration.canReview
            ? `
              <a class="button button-primary" href="/admin/review?catalog=${encodeURIComponent(
                state.catalog,
              )}&work=${encodeURIComponent(work.id)}">Open Review Console</a>
            `
            : ''
        }
      </div>
      <section class="comments-section">
        <div class="section-heading"><span><strong>Discussion</strong><span>Review notes stay attached to this song.</span></span></div>
        <div class="comment-list">
          ${
            comments.length
              ? comments
                  .map(
                    (comment) => `
                      <article class="comment">
                        <header><strong>${escapeHtml(
                          comment.author?.displayName || 'Team member',
                        )}</strong><time>${escapeHtml(formatDate(comment.createdAt))}</time></header>
                        <p>${escapeHtml(comment.body)}</p>
                      </article>
                    `,
                  )
                  .join('')
              : '<div class="empty-inline">No discussion yet.</div>'
          }
        </div>
        ${
          state.user?.legacy
            ? '<p class="form-error">Sign in with an individual account to comment.</p>'
            : `
              <form class="comment-form" id="comment-form">
                <label><span class="sr-only">Comment</span><textarea name="body" maxlength="4000" placeholder="Add a review note" required></textarea></label>
                <button class="button button-quiet" type="submit">Add comment</button>
              </form>
            `
        }
      </section>
    </section>
  `;

  byId('submit-review-button')?.addEventListener('click', async () => {
    try {
      await api(
        `/api/admin/works/${encodeURIComponent(work.id)}/submit?catalog=${encodeURIComponent(
          state.catalog,
        )}`,
        { method: 'POST' },
      );
      await reloadWorkCollaboration('Song submitted for review.');
    } catch (error) {
      showToast(error.message, true);
    }
  });
  byId('comment-form')?.addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      await api(
        `/api/admin/works/${encodeURIComponent(work.id)}/comments?catalog=${encodeURIComponent(
          state.catalog,
        )}`,
        {
          method: 'POST',
          body: JSON.stringify({ body: form.elements.body.value }),
        },
      );
      await reloadWorkCollaboration('Comment added.');
    } catch (error) {
      showToast(error.message, true);
      submit.disabled = false;
    }
  });
};

const removeMembership = async (entryId) => {
  const entry = state.selectedWork.entries.find((item) => item.id === entryId);
  if (!entry) return;
  const confirmed = await askConfirmation(
    'Remove from hymnal',
    `Remove this song from ${entry.nativeVersionLabel}? The shared song content will remain available to every other hymnal.${
      state.editorDirty ? ' Unsaved changes on this screen will be discarded.' : ''
    }`,
    'Remove membership',
  );
  if (!confirmed) return;
  try {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(
        state.selectedWork.id,
      )}/memberships/${encodeURIComponent(entry.id)}?catalog=${encodeURIComponent(
        state.catalog,
      )}`,
      {
        method: 'DELETE',
        body: JSON.stringify({
          expectedUpdatedAt: state.selectedWork.updatedAt,
        }),
      },
    );
    state.selectedWork = response.data;
    state.editorDirty = false;
    renderEditor();
    showToast(`Removed from ${entry.nativeVersionLabel}.`);
    await refreshCatalogData({ preserveSelection: true });
  } catch (error) {
    showToast(error.message, true);
  }
};

const renderHistoryTab = async () => {
  const body = byId('editor-tab-body');
  body.innerHTML = '<div class="loading-inline">Loading history...</div>';
  try {
    const response = await api(
      `/api/admin/audit?catalog=${encodeURIComponent(
        state.catalog,
      )}&workId=${encodeURIComponent(state.selectedWork.id)}`,
    );
    body.innerHTML = `
      <section>
        <div class="section-heading">
          <span>
            <strong>Change history</strong>
            <span>Recorded database changes for this song.</span>
          </span>
        </div>
        <div class="audit-list">
          ${
            response.data.length
              ? response.data
                  .map(
                    (record) => `
                      <article class="audit-row">
                        <strong>${escapeHtml(record.action.replaceAll('_', ' '))}</strong>
                        <span>${escapeHtml(record.actor)}</span>
                        <time datetime="${escapeHtml(record.createdAt)}">${escapeHtml(
                          formatDate(record.createdAt),
                        )}</time>
                      </article>
                    `,
                  )
                  .join('')
              : '<div class="empty-inline">No recorded changes yet.</div>'
          }
        </div>
      </section>
    `;
  } catch (error) {
    body.innerHTML = `<div class="empty-inline">${escapeHtml(
      error.message,
    )}</div>`;
  }
};

const openMergeDialog = async () => {
  elements.mergeSearch.value = '';
  elements.mergeDialog.showModal();
  await loadMergeCandidates();
};

const loadMergeCandidates = async () => {
  elements.mergeCandidates.innerHTML =
    '<div class="loading-inline">Finding compatible songs...</div>';
  const params = new URLSearchParams({
    catalog: 'sda',
    compatibleWith: state.selectedWork.id,
    q: elements.mergeSearch.value,
    pageSize: '30',
  });
  try {
    const response = await api(`/api/admin/works?${params}`);
    if (!response.data.length) {
      elements.mergeCandidates.innerHTML =
        '<div class="empty-inline">No compatible unlinked songs found.</div>';
      return;
    }
    elements.mergeCandidates.innerHTML = response.data
      .map(
        (work) => `
          <button class="candidate-row" type="button" data-candidate-id="${escapeHtml(
            work.id,
          )}">
            <span>
              <strong>${escapeHtml(work.defaultTitle)}</strong>
              <small>${escapeHtml(work.defaultEnglishTitle || work.canonicalKey)}</small>
            </span>
            <span class="entry-badges">${work.entries
              .map(editionBadge)
              .join('')}</span>
          </button>
        `,
      )
      .join('');
    elements.mergeCandidates
      .querySelectorAll('[data-candidate-id]')
      .forEach((button) => {
        button.addEventListener('click', () =>
          mergeWith(button.dataset.candidateId),
        );
      });
  } catch (error) {
    elements.mergeCandidates.innerHTML = `<div class="empty-inline">${escapeHtml(
      error.message,
    )}</div>`;
  }
};

const mergeWith = async (sourceWorkId) => {
  const candidate = state.works.find((work) => work.id === sourceWorkId);
  const confirmed = await askConfirmation(
    'Merge duplicate song records',
    'All non-conflicting hymnal memberships will move onto one canonical song. Use this only when both records are truly the same song.',
    'Merge records',
  );
  if (!confirmed) return;
  try {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(
        state.selectedWork.id,
      )}/merge?catalog=sda`,
      {
        method: 'POST',
        body: JSON.stringify({
          sourceWorkId,
          expectedUpdatedAt: state.selectedWork.updatedAt,
        }),
      },
    );
    state.selectedWork = response.data;
    elements.mergeDialog.close();
    showToast(
      candidate
        ? `${candidate.defaultTitle} now uses this canonical song.`
        : 'Duplicate records merged.',
    );
    await refreshCatalogData({ preserveSelection: true });
  } catch (error) {
    showToast(error.message, true);
  }
};

const askConfirmation = (title, message, actionLabel) =>
  new Promise((resolve) => {
    elements.confirmTitle.textContent = title;
    elements.confirmMessage.textContent = message;
    elements.confirmAccept.textContent = actionLabel;
    elements.confirmDialog.showModal();
    function finish(value) {
      elements.confirmDialog.close();
      elements.confirmAccept.removeEventListener('click', accept);
      elements.confirmCancel.removeEventListener('click', cancel);
      elements.confirmDialog.removeEventListener('cancel', cancelDialog);
      resolve(value);
    }
    const accept = () => finish(true);
    const cancel = () => finish(false);
    const cancelDialog = (event) => {
      event.preventDefault();
      finish(false);
    };
    elements.confirmAccept.addEventListener('click', accept);
    elements.confirmCancel.addEventListener('click', cancel);
    elements.confirmDialog.addEventListener('cancel', cancelDialog);
  });

const reloadSelectedWork = async (message) => {
  const response = await api(
    `/api/admin/works/${encodeURIComponent(
      state.selectedWork.id,
    )}?catalog=${encodeURIComponent(state.catalog)}`,
  );
  state.selectedWork = response.data;
  renderEditor();
  showToast(message);
  await refreshCatalogData({ preserveSelection: true });
};

const refreshDashboard = async () => {
  const response = await api('/api/admin/dashboard');
  state.dashboard = response.data;
  renderCatalogNavigation();
  renderStats();
  renderFilters();
};

const refreshCatalogData = async ({ preserveSelection = false } = {}) => {
  const selectedId = preserveSelection ? state.selectedWork?.id : null;
  await Promise.all([refreshDashboard(), loadWorks()]);
  if (selectedId) {
    const response = await api(
      `/api/admin/works/${encodeURIComponent(
        selectedId,
      )}?catalog=${encodeURIComponent(state.catalog)}`,
    );
    state.selectedWork = response.data;
    renderEditor();
  }
};

const assignmentScope = (assignment) => {
  const parts = [assignment.catalog === 'sda' ? 'SDA' : 'Hagerigna'];
  if (assignment.versionKey) parts.push(assignment.versionKey);
  if (assignment.categorySlug) parts.push(assignment.categorySlug);
  if (assignment.startNumber || assignment.endNumber) {
    parts.push(
      `#${assignment.startNumber || 1}-${assignment.endNumber || 'end'}`,
    );
  }
  return parts.join(' · ');
};

const renderWorkspaceTabs = () => {
  const tabs = [
    ['profile', 'My account'],
    ['assignments', 'Assignments'],
    ...(state.user?.permissions.review ? [['activity', 'Activity']] : []),
    ...(state.user?.permissions.manageUsers ? [['team', 'Team']] : []),
    ...(state.user?.permissions.createReleases ? [['releases', 'Releases']] : []),
  ];
  if (!tabs.some(([id]) => id === state.workspaceTab)) {
    state.workspaceTab = tabs[0][0];
  }
  elements.workspaceTabs.innerHTML = tabs
    .map(
      ([id, label]) => `
        <button class="tab-button" type="button" data-workspace-tab="${id}" aria-selected="${
          state.workspaceTab === id
        }">${label}</button>
      `,
    )
    .join('');
  elements.workspaceTabs
    .querySelectorAll('[data-workspace-tab]')
    .forEach((button) => {
      button.addEventListener('click', () => {
        state.workspaceTab = button.dataset.workspaceTab;
        renderWorkspaceTabs();
        loadWorkspacePanel();
      });
    });
};

const openTeamWorkspace = async (tab = 'assignments') => {
  state.workspaceTab = tab;
  renderWorkspaceTabs();
  elements.workspacePanel.innerHTML =
    '<div class="loading-inline">Loading workspace...</div>';
  elements.collaborationDialog.showModal();
  await loadWorkspacePanel();
};

const renderAssignmentsWorkspace = async () => {
  const [assignmentsResponse, usersResponse, categoriesResponse] = await Promise.all([
    api('/api/admin/assignments'),
    state.user.permissions.manageAssignments
      ? api('/api/admin/users')
      : Promise.resolve({ data: [] }),
    api('/api/admin/categories?catalog=sda'),
  ]);
  const assignments = assignmentsResponse.data;
  const versionOptions = (catalogId) =>
    (catalogSummary(catalogId)?.versions || [])
      .map(
        (version) =>
          `<option value="${escapeHtml(version.id)}">${escapeHtml(
            version.nativeLabel || version.label,
          )}</option>`,
      )
      .join('');
  const categoryOptions = categoriesResponse.data
    .map(
      (category) => `<option value="${escapeHtml(category.id)}">${escapeHtml(
        category.name_amharic || category.name,
      )} · ${category.start_number}-${category.end_number}</option>`,
    )
    .join('');
  elements.workspacePanel.innerHTML = `
    <section class="workspace-section">
      <div class="workspace-section-heading">
        <div><strong>Work assignments</strong><span>Editors can change only songs inside active scopes.</span></div>
      </div>
      ${
        state.user.permissions.manageAssignments
          ? `
            <form class="workspace-form assignment-form" id="assignment-form">
              <label><span>Assignment name</span><input name="title" maxlength="180" required></label>
              <label><span>Assignee</span><select name="assigneeId" required>
                <option value="">Choose a team member</option>
                ${usersResponse.data
                  .filter((user) => user.isActive && user.role === 'editor')
                  .map(
                    (user) => `<option value="${escapeHtml(user.id)}">${escapeHtml(
                      user.displayName,
                    )} · ${escapeHtml(user.role)}</option>`,
                  )
                  .join('')}
              </select></label>
              <label><span>Catalog</span><select name="catalog"><option value="sda">SDA Hymnal</option><option value="hagerigna">Hagerigna</option></select></label>
              <label><span>Hymnal version (optional)</span><select name="versionKey"><option value="">All versions</option>${versionOptions('sda')}</select></label>
              <label><span>Category (optional)</span><select name="categorySlug">
                <option value="">All categories</option>
                ${categoryOptions}
              </select></label>
              <label><span>First number</span><input name="startNumber" type="number" min="1"></label>
              <label><span>Last number</span><input name="endNumber" type="number" min="1"></label>
              <label><span>Due date (optional)</span><input name="dueAt" type="date"></label>
              <label class="span-2"><span>Instructions</span><textarea name="instructions" maxlength="4000"></textarea></label>
              <div class="form-actions span-2"><button class="button button-primary" type="submit">Create assignment</button></div>
            </form>
          `
          : ''
      }
      <div class="workspace-list">
        ${
          assignments.length
            ? assignments
                .map(
                  (assignment) => `
                    <article class="workspace-row">
                      <div><strong>${escapeHtml(assignment.title)}</strong><span>${escapeHtml(
                        assignmentScope(assignment),
                      )}</span><small>${escapeHtml(
                        assignment.assignee?.displayName || 'Unassigned',
                      )}</small></div>
                      <div class="row-actions">
                        <span class="badge ${assignment.status === 'active' ? 'green' : ''}">${escapeHtml(assignment.status)}</span>
                        ${
                          state.user.permissions.manageAssignments && assignment.status === 'active'
                            ? `<button class="button button-quiet" type="button" data-assignment-status="completed" data-assignment-id="${escapeHtml(assignment.id)}">Complete</button><button class="button button-quiet" type="button" data-assignment-status="cancelled" data-assignment-id="${escapeHtml(assignment.id)}">Cancel</button>`
                            : ''
                        }
                      </div>
                    </article>
                  `,
                )
                .join('')
            : '<div class="empty-inline">No assignments yet.</div>'
        }
      </div>
    </section>
  `;
  const assignmentForm = byId('assignment-form');
  const updateAssignmentScopeControls = () => {
    if (!assignmentForm) return;
    const catalogId = assignmentForm.elements.catalog.value;
    assignmentForm.elements.versionKey.innerHTML =
      `<option value="">All versions</option>${versionOptions(catalogId)}`;
    const category = assignmentForm.elements.categorySlug;
    category.value = '';
    category.disabled = catalogId !== 'sda';
    category.innerHTML =
      catalogId === 'sda'
        ? `<option value="">All categories</option>${categoryOptions}`
        : '<option value="">Categories are not used for Hagerigna</option>';
  };
  assignmentForm?.elements.catalog.addEventListener(
    'change',
    updateAssignmentScopeControls,
  );
  assignmentForm?.addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      await api('/api/admin/assignments', {
        method: 'POST',
        body: JSON.stringify({
          title: form.elements.title.value,
          assigneeId: form.elements.assigneeId.value,
          catalog: form.elements.catalog.value,
          versionKey: form.elements.versionKey.value || null,
          categorySlug: form.elements.categorySlug.value || null,
          startNumber: form.elements.startNumber.value || null,
          endNumber: form.elements.endNumber.value || null,
          dueAt: form.elements.dueAt.value || null,
          instructions: form.elements.instructions.value,
        }),
      });
      showToast('Assignment created.');
      await refreshDashboard();
      await renderAssignmentsWorkspace();
    } catch (error) {
      showToast(error.message, true);
      submit.disabled = false;
    }
  });
  elements.workspacePanel
    .querySelectorAll('[data-assignment-status]')
    .forEach((button) => {
      button.addEventListener('click', async () => {
        try {
          await api(
            `/api/admin/assignments/${encodeURIComponent(
              button.dataset.assignmentId,
            )}`,
            {
              method: 'PATCH',
              body: JSON.stringify({ status: button.dataset.assignmentStatus }),
            },
          );
          showToast(`Assignment ${button.dataset.assignmentStatus}.`);
          await refreshDashboard();
          await renderAssignmentsWorkspace();
        } catch (error) {
          showToast(error.message, true);
        }
      });
    });
};

const renderProfileWorkspace = async () => {
  elements.workspacePanel.innerHTML = `
    <section class="workspace-section profile-workspace">
      <div class="workspace-section-heading"><div><strong>${escapeHtml(
        state.user.displayName,
      )}</strong><span>${escapeHtml(state.user.email)} · ${escapeHtml(
        state.user.role,
      )}</span></div></div>
      <form class="workspace-form" id="password-form">
        <label><span>Current password</span><input name="currentPassword" type="password" maxlength="200" autocomplete="current-password" required></label>
        <label><span>New password</span><input name="newPassword" type="password" minlength="12" maxlength="200" autocomplete="new-password" required></label>
        <div class="form-actions span-2"><button class="button button-primary" type="submit">Change password</button></div>
      </form>
    </section>
  `;
  byId('password-form').addEventListener('submit', async (event) => {
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
      form.reset();
      showToast('Password changed. Other sessions were signed out.');
    } catch (error) {
      showToast(error.message, true);
      submit.disabled = false;
    }
  });
};

const renderActivityWorkspace = async () => {
  const response = await api('/api/admin/activity?pageSize=150');
  elements.workspacePanel.innerHTML = `
    <section class="workspace-section">
      <div class="workspace-section-heading"><div><strong>Team activity</strong><span>Account, assignment, review, discussion, and release actions.</span></div></div>
      <div class="workspace-list">
        ${
          response.data.length
            ? response.data
                .map(
                  (item) => `
                    <article class="workspace-row">
                      <div><strong>${escapeHtml(item.action.replaceAll('_', ' '))}</strong><span>${escapeHtml(item.actorName)}</span><small>${escapeHtml(item.entityType)}${item.entityId ? ` · ${escapeHtml(item.entityId)}` : ''}</small></div>
                      <time>${escapeHtml(formatDate(item.createdAt))}</time>
                    </article>
                  `,
                )
                .join('')
            : '<div class="empty-inline">No collaboration activity has been recorded yet.</div>'
        }
      </div>
    </section>
  `;
};

const renderTeamWorkspace = async () => {
  const response = await api('/api/admin/users');
  const users = response.data;
  elements.workspacePanel.innerHTML = `
    <section class="workspace-section">
      <div class="workspace-section-heading"><div><strong>Team accounts</strong><span>Use one account per person so audit and review history remain trustworthy.</span></div></div>
      <form class="workspace-form team-form" id="team-form">
        <label><span>Name</span><input name="displayName" maxlength="120" required></label>
        <label><span>Email</span><input name="email" type="email" maxlength="254" required></label>
        <label><span>Role</span><select name="role"><option value="editor">Editor</option><option value="reviewer">Reviewer</option><option value="owner">Owner</option></select></label>
        <label><span>Temporary password</span><input name="password" type="password" minlength="12" maxlength="200" required></label>
        <div class="form-actions span-2"><button class="button button-primary" type="submit">Create account</button></div>
      </form>
      <div class="workspace-list">
        ${users
          .map(
            (user) => `
              <article class="workspace-row team-row">
                <div><strong>${escapeHtml(user.displayName)}</strong><span>${escapeHtml(
                  user.email,
                )}</span><small>${escapeHtml(user.role)}</small></div>
                <div class="row-actions">
                  <select aria-label="Role for ${escapeHtml(user.displayName)}" data-user-role="${escapeHtml(user.id)}">
                    <option value="editor" ${user.role === 'editor' ? 'selected' : ''}>Editor</option>
                    <option value="reviewer" ${user.role === 'reviewer' ? 'selected' : ''}>Reviewer</option>
                    <option value="owner" ${user.role === 'owner' ? 'selected' : ''}>Owner</option>
                  </select>
                  ${
                    user.id === state.user.id
                      ? ''
                      : `<button class="button button-quiet" type="button" data-reset-user="${escapeHtml(user.id)}">Reset password</button>`
                  }
                  <button class="button button-quiet" type="button" data-toggle-user="${escapeHtml(user.id)}" data-user-active="${user.isActive}">${
                    user.isActive ? 'Disable' : 'Enable'
                  }</button>
                </div>
                ${
                  user.id === state.user.id
                    ? ''
                    : `
                      <form class="password-reset-form" data-password-reset-form="${escapeHtml(user.id)}" hidden>
                        <label>
                          <span>New temporary password</span>
                          <input name="password" type="password" minlength="12" maxlength="200" autocomplete="new-password" required>
                        </label>
                        <div class="row-actions">
                          <button class="button button-primary" type="submit">Reset and sign out sessions</button>
                          <button class="button button-quiet" type="button" data-cancel-password-reset>Cancel</button>
                        </div>
                      </form>
                    `
                }
              </article>
            `,
          )
          .join('')}
      </div>
    </section>
  `;
  byId('team-form').addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      await api('/api/admin/users', {
        method: 'POST',
        body: JSON.stringify({
          displayName: form.elements.displayName.value,
          email: form.elements.email.value,
          role: form.elements.role.value,
          password: form.elements.password.value,
        }),
      });
      showToast('Team account created.');
      await renderTeamWorkspace();
    } catch (error) {
      showToast(error.message, true);
      submit.disabled = false;
    }
  });
  elements.workspacePanel.querySelectorAll('[data-user-role]').forEach((select) => {
    select.addEventListener('change', async () => {
      try {
        await api(`/api/admin/users/${encodeURIComponent(select.dataset.userRole)}`, {
          method: 'PATCH',
          body: JSON.stringify({ role: select.value }),
        });
        showToast('Team role updated.');
        await renderTeamWorkspace();
      } catch (error) {
        showToast(error.message, true);
        await renderTeamWorkspace();
      }
    });
  });
  elements.workspacePanel.querySelectorAll('[data-toggle-user]').forEach((button) => {
    button.addEventListener('click', async () => {
      try {
        await api(`/api/admin/users/${encodeURIComponent(button.dataset.toggleUser)}`, {
          method: 'PATCH',
          body: JSON.stringify({ isActive: button.dataset.userActive !== 'true' }),
        });
        showToast('Team access updated.');
        await renderTeamWorkspace();
      } catch (error) {
        showToast(error.message, true);
      }
    });
  });
  elements.workspacePanel.querySelectorAll('[data-reset-user]').forEach((button) => {
    button.addEventListener('click', () => {
      const form = elements.workspacePanel.querySelector(
        `[data-password-reset-form="${CSS.escape(button.dataset.resetUser)}"]`,
      );
      form.hidden = false;
      form.elements.password.focus();
    });
  });
  elements.workspacePanel
    .querySelectorAll('[data-password-reset-form]')
    .forEach((form) => {
      form.addEventListener('submit', async (event) => {
        event.preventDefault();
        const submit = form.querySelector('[type="submit"]');
        submit.disabled = true;
      try {
        await api(
          `/api/admin/users/${encodeURIComponent(form.dataset.passwordResetForm)}`,
          {
            method: 'PATCH',
            body: JSON.stringify({ password: form.elements.password.value }),
          },
        );
        form.reset();
        form.hidden = true;
        showToast('Password reset. Existing sessions were signed out.');
      } catch (error) {
        showToast(error.message, true);
        submit.disabled = false;
      }
      });
      form
        .querySelector('[data-cancel-password-reset]')
        .addEventListener('click', () => {
          form.reset();
          form.hidden = true;
        });
    });
};

const downloadRelease = async (release) => {
  const response = await fetch(
    `/api/admin/releases/${encodeURIComponent(release.id)}/download`,
    { credentials: 'same-origin' },
  );
  if (!response.ok) {
    const body = await response.json();
    throw new Error(body.message || 'Release download failed.');
  }
  const blob = await response.blob();
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement('a');
  anchor.href = url;
  anchor.download = `wudase-content-${release.releaseKey}.zip`;
  anchor.click();
  URL.revokeObjectURL(url);
};

const renderReleasesWorkspace = async () => {
  const response = await api('/api/admin/releases');
  const releases = response.data;
  elements.workspacePanel.innerHTML = `
    <section class="workspace-section">
      <div class="workspace-section-heading"><div><strong>Approved releases</strong><span>Creation is blocked until every edited song is approved. Active releases feed production.</span></div></div>
      <form class="workspace-form release-form" id="release-form">
        <label><span>Release name</span><input name="versionLabel" maxlength="120" placeholder="August 2026 content" required></label>
        <label class="span-2"><span>Release note</span><textarea name="description" maxlength="2000"></textarea></label>
        <div class="form-actions span-2"><button class="button button-primary" type="submit">Create immutable release</button></div>
      </form>
      <div class="workspace-list">
        ${
          releases.length
            ? releases
                .map(
                  (release) => `
                    <article class="workspace-row release-row">
                      <div><strong>${escapeHtml(release.versionLabel)}</strong><span>${escapeHtml(
                        release.releaseKey,
                      )}</span><small>${escapeHtml(formatDate(release.createdAt))} · ${escapeHtml(
                        release.checksumSha256?.slice(0, 12) || 'no checksum',
                      )}</small></div>
                      <div class="row-actions">
                        ${release.isCurrent ? '<span class="badge green">Active</span>' : `<button class="button button-quiet" type="button" data-activate-release="${escapeHtml(release.id)}">Activate</button>`}
                        <button class="button button-quiet" type="button" data-download-release="${escapeHtml(release.id)}">Download ZIP</button>
                      </div>
                    </article>
                  `,
                )
                .join('')
            : '<div class="empty-inline">No release has been created yet.</div>'
        }
      </div>
    </section>
  `;
  byId('release-form').addEventListener('submit', async (event) => {
    event.preventDefault();
    const form = event.currentTarget;
    const submit = form.querySelector('[type="submit"]');
    submit.disabled = true;
    try {
      await api('/api/admin/releases', {
        method: 'POST',
        body: JSON.stringify({
          versionLabel: form.elements.versionLabel.value,
          description: form.elements.description.value,
        }),
      });
      showToast('Immutable release created.');
      await renderReleasesWorkspace();
    } catch (error) {
      const counts = error.details?.counts;
      showToast(
        counts
          ? `${error.message} ${Object.entries(counts)
              .map(([status, count]) => `${count} ${workflowLabel(status).toLowerCase()}`)
              .join(', ')}.`
          : error.message,
        true,
      );
      submit.disabled = false;
    }
  });
  elements.workspacePanel
    .querySelectorAll('[data-activate-release]')
    .forEach((button) => {
      button.addEventListener('click', async () => {
        try {
          await api(
            `/api/admin/releases/${encodeURIComponent(
              button.dataset.activateRelease,
            )}/activate`,
            { method: 'POST' },
          );
          showToast('Production content release activated.');
          await renderReleasesWorkspace();
        } catch (error) {
          showToast(error.message, true);
        }
      });
    });
  elements.workspacePanel
    .querySelectorAll('[data-download-release]')
    .forEach((button) => {
      button.addEventListener('click', async () => {
        try {
          const release = releases.find(
            (item) => item.id === button.dataset.downloadRelease,
          );
          await downloadRelease(release);
        } catch (error) {
          showToast(error.message, true);
        }
      });
    });
};

const loadWorkspacePanel = async () => {
  elements.workspacePanel.innerHTML =
    '<div class="loading-inline">Loading workspace...</div>';
  try {
    if (state.workspaceTab === 'profile') await renderProfileWorkspace();
    else if (state.workspaceTab === 'activity') await renderActivityWorkspace();
    else if (state.workspaceTab === 'team') await renderTeamWorkspace();
    else if (state.workspaceTab === 'releases') await renderReleasesWorkspace();
    else await renderAssignmentsWorkspace();
  } catch (error) {
    elements.workspacePanel.innerHTML = `<div class="empty-inline">${escapeHtml(
      error.message,
    )}</div>`;
  }
};

let searchTimer;
elements.search.addEventListener('input', () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => {
    state.query = elements.search.value.trim();
    state.page = 1;
    loadWorks();
  }, 260);
});

elements.versionFilter.addEventListener('change', () => {
  state.version = elements.versionFilter.value;
  state.membership = state.version === 'all' ? 'all' : 'included';
  state.page = 1;
  renderFilters();
  loadWorks();
});

elements.membershipFilter.addEventListener('change', () => {
  state.membership = elements.membershipFilter.value;
  state.page = 1;
  loadWorks();
});

elements.previousPage.addEventListener('click', () => {
  if (state.page <= 1) return;
  state.page -= 1;
  loadWorks();
});

elements.nextPage.addEventListener('click', () => {
  if (state.page >= state.totalPages) return;
  state.page += 1;
  loadWorks();
});

elements.refresh.addEventListener('click', () =>
  refreshCatalogData({ preserveSelection: Boolean(state.selectedWork?.id) }),
);
elements.newSong.addEventListener('click', showCreateEditor);
elements.manageEditions.addEventListener('click', openEditionManager);
elements.teamWorkspace.addEventListener('click', () => openTeamWorkspace());
elements.reviewQueue.addEventListener('click', () =>
  window.location.assign('/admin/review'),
);
elements.closeCollaborationDialog.addEventListener('click', () =>
  elements.collaborationDialog.close(),
);
elements.closeEditionDialog.addEventListener('click', () =>
  elements.editionDialog.close(),
);
elements.newEditionForm.addEventListener('click', resetEditionForm);
elements.editionForm.addEventListener('submit', saveEdition);
elements.editionForm.elements.publicationYear.addEventListener(
  'input',
  (event) => {
    if (
      state.editingEdition ||
      elements.editionForm.elements.versionKey.value.trim()
    ) {
      return;
    }
    const year = event.target.value.trim();
    if (year) {
      elements.editionForm.elements.versionKey.value = `${
        state.catalog === 'sda' ? 'sda' : 'hagerigna'
      }_${year}`;
    }
  },
);
elements.signOut.addEventListener('click', () => signOut());

let mergeSearchTimer;
elements.mergeSearch.addEventListener('input', () => {
  clearTimeout(mergeSearchTimer);
  mergeSearchTimer = setTimeout(loadMergeCandidates, 240);
});

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
    await enterStudio();
  } catch (error) {
    elements.authError.textContent =
      error.status === 401 ? 'The email or password is incorrect.' : error.message;
    elements.authError.hidden = false;
  } finally {
    submit.disabled = false;
  }
});

api('/api/admin/auth/session')
  .then((response) => {
    if (response.data.authenticated) return enterStudio();
    return null;
  })
  .catch((error) => {
    state.user = null;
    elements.studioView.hidden = true;
    elements.authView.hidden = false;
    elements.authError.textContent = error.message;
    elements.authError.hidden = false;
  });
