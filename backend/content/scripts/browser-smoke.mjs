import { mkdir } from 'node:fs/promises';
import path from 'node:path';

import { chromium } from 'playwright';

const origin = String(process.env.CONTENT_STUDIO_ORIGIN ?? 'http://127.0.0.1:8787')
  .replace(/\/$/, '');
const email = process.env.CONTENT_STUDIO_TEST_EMAIL;
const password = process.env.CONTENT_STUDIO_TEST_PASSWORD;
if (!email || !password) {
  throw new Error(
    'Set CONTENT_STUDIO_TEST_EMAIL and CONTENT_STUDIO_TEST_PASSWORD.',
  );
}
const outputDirectory = path.resolve(
  process.env.CONTENT_STUDIO_SCREENSHOT_DIR ?? '.artifacts/content-studio',
);
await mkdir(outputDirectory, { recursive: true });

const executablePath =
  process.env.CHROME_PATH ??
  (process.platform === 'win32'
    ? 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe'
    : undefined);
const browser = await chromium.launch({ executablePath, headless: true });

const verify = async (name, viewport) => {
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  const errors = [];
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(`${origin}/admin/content`, { waitUntil: 'networkidle' });
  await page.locator('#admin-email').fill(email);
  await page.locator('#admin-password').fill(password);
  await page.locator('#auth-form button[type="submit"]').click();
  await page.locator('#studio-view').waitFor({ state: 'visible' });
  await page.locator('.song-row').first().waitFor({ state: 'visible' });
  const visibleSongCount = Number.parseInt(
    (await page.locator('#result-count').textContent()) ?? '',
    10,
  );
  if (!Number.isInteger(visibleSongCount) || visibleSongCount < 1) {
    throw new Error(`${name} did not render the database song count.`);
  }
  if (!(await page.locator('#auth-error').isHidden())) {
    throw new Error(`${name} reported an error after a successful login.`);
  }
  await page.locator('.song-row').first().click();
  await page.locator('#editor-content').waitFor({ state: 'visible' });
  if ((await page.locator('[data-tab="media"]').count()) !== 0) {
    throw new Error(`${name} still exposes media management in Content Studio.`);
  }
  if (/\bmedia\b/i.test(await page.locator('#editor-content').innerText())) {
    throw new Error(`${name} still exposes media details in Content Studio.`);
  }
  await page.goto(`${origin}/admin/content`, { waitUntil: 'networkidle' });
  await page.locator('#studio-view').waitFor({ state: 'visible' });
  await page.locator('#team-workspace-button').waitFor({ state: 'visible' });
  await page.locator('#team-workspace-button').click();
  await page.locator('#collaboration-dialog').waitFor({ state: 'visible' });
  await page.locator('[data-workspace-tab="assignments"]').click();
  await page.locator('#workspace-panel').waitFor({ state: 'visible' });
  const assignmentForm = page.locator('#assignment-form');
  await assignmentForm.waitFor({ state: 'visible' });
  const catalogSelect = assignmentForm.locator('[name="catalog"]');
  const versionSelect = assignmentForm.locator('[name="versionKey"]');
  const categorySelect = assignmentForm.locator('[name="categorySlug"]');
  const sdaVersionOptionCount = await versionSelect.locator('option').count();
  if (sdaVersionOptionCount < 4) {
    throw new Error(
      `${name} did not load the SDA hymnal version choices (${sdaVersionOptionCount} options).`,
    );
  }
  await catalogSelect.selectOption('hagerigna');
  if (
    (await versionSelect.locator('option[value="hagerigna"]').count()) !== 1 ||
    !(await categorySelect.isDisabled())
  ) {
    throw new Error(
      `${name} did not apply Hagerigna-specific assignment controls.`,
    );
  }
  await catalogSelect.selectOption('sda');
  if (await categorySelect.isDisabled()) {
    throw new Error(`${name} did not restore SDA category choices.`);
  }
  await page.locator('[data-workspace-tab="team"]').click();
  const teamForm = page.locator('#team-form');
  await teamForm.waitFor({ state: 'visible' });
  const resetButtons = page.locator('[data-reset-user]');
  if ((await resetButtons.count()) > 0) {
    await resetButtons.first().click();
    const resetForm = page.locator('[data-password-reset-form]:visible');
    await resetForm.waitFor({ state: 'visible' });
    if ((await resetForm.locator('input[type="password"]').count()) !== 1) {
      throw new Error(`${name} password reset is not using a masked field.`);
    }
    await resetForm.locator('[data-cancel-password-reset]').click();
    await resetForm.waitFor({ state: 'hidden' });
  }
  await page.locator('[data-workspace-tab="assignments"]').click();
  await assignmentForm.waitFor({ state: 'visible' });
  const panel = page.locator('#workspace-panel');
  const panelScroll = await panel.evaluate((element) => ({
    clientHeight: element.clientHeight,
    scrollHeight: element.scrollHeight,
  }));
  await panel.evaluate((element) => {
    element.scrollTop = element.scrollHeight;
  });
  await page.locator('#workspace-panel button[type="submit"]').waitFor({
    state: 'visible',
  });
  await panel.evaluate((element) => {
    element.scrollTop = 0;
  });
  const overflow = await page.evaluate(() => ({
    documentWidth: document.documentElement.scrollWidth,
    viewportWidth: document.documentElement.clientWidth,
    documentHeight: document.documentElement.scrollHeight,
    viewportHeight: document.documentElement.clientHeight,
  }));
  await page.screenshot({
    path: path.join(outputDirectory, `${name}.png`),
    fullPage: false,
  });
  if (errors.length > 0) {
    throw new Error(`${name} browser errors:\n${errors.join('\n')}`);
  }
  if (overflow.documentWidth > overflow.viewportWidth + 1) {
    throw new Error(
      `${name} has horizontal document overflow: ${JSON.stringify(overflow)}`,
    );
  }
  await page.locator('#close-collaboration-dialog').click();
  await page.locator('#collaboration-dialog').waitFor({ state: 'hidden' });
  await page.locator('#sign-out-button').click();
  await page.locator('#auth-view').waitFor({ state: 'visible' });
  await context.close();
  return { name, visibleSongCount, ...overflow, workspacePanel: panelScroll };
};

const verifyReviewConsole = async (name, viewport) => {
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  const errors = [];
  page.on('console', (message) => {
    if (message.type() === 'error') errors.push(message.text());
  });
  page.on('pageerror', (error) => errors.push(error.message));
  await page.goto(`${origin}/admin/review`, { waitUntil: 'networkidle' });
  await page.locator('#review-email').fill(email);
  await page.locator('#review-password').fill(password);
  await page.locator('#auth-form button[type="submit"]').click();
  await page.locator('#review-view').waitFor({ state: 'visible' });
  await page.locator('#review-workspace').waitFor({ state: 'visible' });
  await page.locator('#queue-list').waitFor({ state: 'visible' });

  await page.locator('#account-button').click();
  await page.locator('#account-dialog').waitFor({ state: 'visible' });
  if ((await page.locator('#password-form input[type="password"]').count()) !== 2) {
    throw new Error(`${name} does not expose both secure password fields.`);
  }
  await page.locator('#cancel-account').click();
  await page.locator('#account-dialog').waitFor({ state: 'hidden' });

  await page.locator('[data-workspace="media"]').click();
  await page.locator('#media-workspace').waitFor({ state: 'visible' });
  await page.locator('.media-result-row').first().waitFor({ state: 'visible' });
  await page.locator('.media-result-row').first().click();
  await page.locator('#add-media-button:not([disabled])').waitFor({
    state: 'visible',
  });
  if (await page.locator('#add-media-button').isDisabled()) {
    throw new Error(`${name} did not enable reviewer media management.`);
  }
  await page.locator('#add-media-button').click();
  await page.locator('#media-dialog').waitFor({ state: 'visible' });
  if (
    (await page.locator('#media-form [name="mediaType"] option').count()) < 3 ||
    (await page.locator('#media-form [name="relationType"] option').count()) < 2
  ) {
    throw new Error(`${name} did not load the reusable-media form options.`);
  }
  await page.locator('#cancel-media').click();
  await page.locator('#media-dialog').waitFor({ state: 'hidden' });

  const overflow = await page.evaluate(() => ({
    documentWidth: document.documentElement.scrollWidth,
    viewportWidth: document.documentElement.clientWidth,
    documentHeight: document.documentElement.scrollHeight,
    viewportHeight: document.documentElement.clientHeight,
  }));
  await page.screenshot({
    path: path.join(outputDirectory, `${name}.png`),
    fullPage: false,
  });
  if (errors.length > 0) {
    throw new Error(`${name} browser errors:\n${errors.join('\n')}`);
  }
  if (overflow.documentWidth > overflow.viewportWidth + 1) {
    throw new Error(
      `${name} has horizontal document overflow: ${JSON.stringify(overflow)}`,
    );
  }
  await page.locator('#sign-out-button').click();
  await page.locator('#auth-view').waitFor({ state: 'visible' });
  await context.close();
  return { name, ...overflow };
};

try {
  const results = [];
  results.push(await verify('desktop', { width: 1440, height: 1000 }));
  results.push(await verify('mobile', { width: 390, height: 844 }));
  results.push(
    await verifyReviewConsole('review-desktop', {
      width: 1440,
      height: 1000,
    }),
  );
  results.push(
    await verifyReviewConsole('review-mobile', { width: 390, height: 844 }),
  );
  console.log(JSON.stringify({ origin, outputDirectory, results }, null, 2));
} finally {
  await browser.close();
}
