# Backend Plan

## Content Backend

Local dev default: `http://localhost:8787`

- `GET /health`
- `GET /api/hymns?language=am&version=sda_new`
- `GET /api/hymns?language=am&version=sda_old`
- `GET /api/hymns?language=am&version=hagerigna`
- `GET /api/categories?version=sda_new|sda_old`
- `GET /sheet_music/<file>`

SDA and Hagerigna databases remain separate. SDA old/new entries reuse merged works where English title and lyrics match.

## User/App Backend

Local dev default: `http://localhost:8790`

- `GET /health`
- `POST /api/bug-reports`
- `GET /api/admin/bug-reports`
- `PATCH /api/admin/bug-reports/:id/status`
- `GET /admin/bug-reports?token=<USER_APP_ADMIN_TOKEN>`

Set `USER_APP_ADMIN_TOKEN` before deploying. The development fallback token is only for local use.
