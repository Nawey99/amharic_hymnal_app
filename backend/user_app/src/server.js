import http from 'node:http';

import { PrismaClient } from '@prisma/client';

const port = Number(process.env.PORT ?? 8790);
const host = process.env.HOST ?? '127.0.0.1';
const databaseUrl =
  process.env.USER_APP_DATABASE_URL ??
  'postgresql://postgres@localhost:55432/wudase_user_app_dev';
const adminToken =
  process.env.USER_APP_ADMIN_TOKEN ??
  (process.env.NODE_ENV === 'production' ? '' : 'dev-admin-token');

const prisma = new PrismaClient({
  datasources: { db: { url: databaseUrl } },
});

const allowedStatuses = new Set([
  'open',
  'reviewing',
  'fixed',
  'closed',
  'duplicate',
]);

const sendJson = (response, statusCode, body) => {
  response.writeHead(statusCode, {
    'content-type': 'application/json; charset=utf-8',
    'access-control-allow-origin': '*',
    'access-control-allow-methods': 'GET, POST, PATCH, OPTIONS',
    'access-control-allow-headers':
      'content-type, authorization, x-admin-token',
    'cache-control': 'no-store',
  });
  response.end(JSON.stringify(body));
};

const sendHtml = (response, statusCode, html) => {
  response.writeHead(statusCode, {
    'content-type': 'text/html; charset=utf-8',
    'cache-control': 'no-store',
  });
  response.end(html);
};

const readJson = async (request) => {
  const chunks = [];
  for await (const chunk of request) {
    chunks.push(chunk);
  }
  if (chunks.length === 0) return {};
  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
};

const isAuthorized = (request, url) => {
  if (!adminToken) return false;
  const bearer = request.headers.authorization?.replace(/^Bearer\s+/i, '');
  const headerToken = request.headers['x-admin-token'];
  const queryToken = url.searchParams.get('token');
  return [bearer, headerToken, queryToken].includes(adminToken);
};

const serializeReport = (report) => ({
  id: report.id,
  title: report.title,
  description: report.description,
  severity: report.severity,
  status: report.status,
  appVersion: report.appVersion,
  platform: report.platform,
  diagnostics: report.diagnostics,
  createdAt: report.createdAt,
  updatedAt: report.updatedAt,
});

const getReports = async () => {
  const reports = await prisma.bugReport.findMany({
    orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
    take: 100,
  });
  return reports.map(serializeReport);
};

const escapeHtml = (value) =>
  String(value ?? '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');

const renderAdminPage = (reports, token) => `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Wudase Bug Reports</title>
  <style>
    body { margin: 0; font-family: system-ui, sans-serif; background: #111827; color: #f9fafb; }
    main { max-width: 1180px; margin: 0 auto; padding: 32px 20px; }
    h1 { margin: 0 0 20px; font-size: 28px; }
    table { width: 100%; border-collapse: collapse; background: #1f2937; border-radius: 10px; overflow: hidden; }
    th, td { text-align: left; padding: 12px; border-bottom: 1px solid #374151; vertical-align: top; }
    th { color: #a7f3d0; font-size: 12px; text-transform: uppercase; letter-spacing: .06em; }
    td { font-size: 14px; }
    select { background: #111827; color: #f9fafb; border: 1px solid #4b5563; border-radius: 8px; padding: 8px; }
    .muted { color: #9ca3af; }
    .desc { max-width: 380px; white-space: pre-wrap; }
  </style>
</head>
<body>
  <main>
    <h1>Wudase Bug Reports</h1>
    <table>
      <thead>
        <tr><th>Status</th><th>Severity</th><th>Title</th><th>Description</th><th>Platform</th><th>Created</th></tr>
      </thead>
      <tbody>
        ${reports
          .map(
            (report) => `<tr>
              <td>
                <select data-id="${escapeHtml(report.id)}">
                  ${[...allowedStatuses]
                    .map(
                      (status) =>
                        `<option value="${status}" ${
                          status === report.status ? 'selected' : ''
                        }>${status}</option>`,
                    )
                    .join('')}
                </select>
              </td>
              <td>${escapeHtml(report.severity)}</td>
              <td>${escapeHtml(report.title)}</td>
              <td class="desc">${escapeHtml(report.description)}</td>
              <td><span>${escapeHtml(report.platform)}</span><br><span class="muted">${escapeHtml(report.appVersion)}</span></td>
              <td>${escapeHtml(new Date(report.createdAt).toLocaleString())}</td>
            </tr>`,
          )
          .join('')}
      </tbody>
    </table>
  </main>
  <script>
    const token = ${JSON.stringify(token)};
    document.querySelectorAll('select[data-id]').forEach((select) => {
      select.addEventListener('change', async () => {
        await fetch('/api/admin/bug-reports/' + select.dataset.id + '/status', {
          method: 'PATCH',
          headers: { 'content-type': 'application/json', 'x-admin-token': token },
          body: JSON.stringify({ status: select.value }),
        });
      });
    });
  </script>
</body>
</html>`;

const server = http.createServer(async (request, response) => {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  const url = new URL(request.url ?? '/', `http://${request.headers.host}`);

  try {
    if (request.method === 'GET' && url.pathname === '/health') {
      await prisma.$queryRaw`select 1`;
      sendJson(response, 200, { ok: true });
      return;
    }

    if (request.method === 'POST' && url.pathname === '/api/bug-reports') {
      const body = await readJson(request);
      const title = String(body.title ?? '').trim();
      const description = String(body.description ?? '').trim();
      const severity = String(body.severity ?? 'normal').trim();

      if (title.length < 3 || description.length < 10) {
        sendJson(response, 400, { error: 'invalid_bug_report' });
        return;
      }

      const report = await prisma.bugReport.create({
        data: {
          title,
          description,
          severity: ['low', 'normal', 'high', 'critical'].includes(severity)
            ? severity
            : 'normal',
          appVersion: body.appVersion ? String(body.appVersion) : null,
          platform: body.platform ? String(body.platform) : null,
          diagnostics: body.diagnostics ?? {},
        },
      });

      sendJson(response, 201, { data: serializeReport(report) });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/api/admin/bug-reports') {
      if (!isAuthorized(request, url)) {
        sendJson(response, 401, { error: 'unauthorized' });
        return;
      }
      sendJson(response, 200, { data: await getReports() });
      return;
    }

    const statusMatch = url.pathname.match(
      /^\/api\/admin\/bug-reports\/([^/]+)\/status$/,
    );
    if (request.method === 'PATCH' && statusMatch) {
      if (!isAuthorized(request, url)) {
        sendJson(response, 401, { error: 'unauthorized' });
        return;
      }
      const body = await readJson(request);
      const status = String(body.status ?? '').trim();
      if (!allowedStatuses.has(status)) {
        sendJson(response, 400, { error: 'invalid_status' });
        return;
      }
      const report = await prisma.bugReport.update({
        where: { id: statusMatch[1] },
        data: { status },
      });
      sendJson(response, 200, { data: serializeReport(report) });
      return;
    }

    if (request.method === 'GET' && url.pathname === '/admin/bug-reports') {
      if (!isAuthorized(request, url)) {
        sendHtml(
          response,
          401,
          '<h1>Unauthorized</h1><p>Pass ?token=YOUR_ADMIN_TOKEN for local admin access.</p>',
        );
        return;
      }
      sendHtml(response, 200, renderAdminPage(await getReports(), adminToken));
      return;
    }

    sendJson(response, 404, { error: 'not_found' });
  } catch (error) {
    console.error(error);
    sendJson(response, 500, {
      error: 'internal_server_error',
      message: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(port, host, () => {
  console.log(`Wudase user app API listening on http://${host}:${port}`);
});

const shutdown = async () => {
  server.close();
  await prisma.$disconnect();
  process.exit(0);
};

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
