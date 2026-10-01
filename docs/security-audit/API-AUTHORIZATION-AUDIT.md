# API Authentication and Authorization Audit

Audit date: 2026-10-01. Backend commit `ab3ed4f`. Live host
`https://amharichymnalbackend.vercel.app`.

Method: source review of the router, middleware, auth services and config, then
read-only live probes with no valid credential. No admin write was attempted
with a working token; none was available and none was sought.

## Authentication model

| Caller | Mechanism | Where enforced |
| --- | --- | --- |
| Mobile app | None. All app routes are anonymous by design. | n/a |
| Operator | Supabase access token (JWT) as `Authorization: Bearer` | `src/middleware/auth.ts`, `src/auth/supabase-jwt-auth-service.ts` |
| Vercel Cron | `Authorization: Bearer <CRON_SECRET>` | `src/controllers/maintenance-controller.ts` |
| Local development | Static `DEV_ADMIN_TOKEN` | Refused at boot when `NODE_ENV=production` (`config/index.ts:410-417`) |

### JWT handling (`supabase-jwt-auth-service.ts:47-67`)

| Check | Status | Evidence |
| --- | --- | --- |
| Signature against remote JWKS | Yes | `createRemoteJWKSet`, 10-minute cache, 30-second cooldown, 5-second timeout |
| Algorithm allow-list | Yes | `algorithms: ["ES256", "RS256"]`; `none` and HS256 cannot pass |
| Issuer | Yes | `issuer: this.issuer`; must be HTTPS in production |
| Audience | Yes | `audience`, default `authenticated` |
| Expiry | Yes | `jose` rejects expired tokens; `exp` and `sub` required |
| Clock skew | Library default (no tolerance configured) | — |
| Key rotation | Handled by JWKS refetch on unknown `kid` | — |
| Role source | `app_metadata.role`, else top-level `role`, else `USER` | `claimRole`, lines 15-30. Supabase's top-level `role` is `authenticated`, which maps to `USER`. `app_metadata` cannot be written by the user. |
| Header parsing | Strict regex, 8 KB cap | `auth.ts:6-15` |
| Refresh | Client side only, against Supabase | `admin-ui/sign-in.ts` |

Live results:

| Request to `/api/v1/admin/system` | Answer |
| --- | --- |
| No header | 401 `Authentication is required.` |
| `Bearer abc` | 401 `The access token is invalid or expired.` |
| JWT with `alg: none`, `app_metadata.role: ADMIN` | 403 from the Vercel edge (never reached the app) |
| JWT with `alg: HS256`, forged signature, `role: ADMIN` | 401 `The access token is invalid or expired.` |
| `Basic …` | 401 `The Authorization header is invalid.` |

## Authorization model

Every admin route is registered with three gates in order (`router.ts:240-245`):
`requireAuthenticationConfigured` (503 if auth is off), `requireAuthentication`
(401), then `requireRole` (403). There is no admin route without them. The
admin page at `/admin` is static HTML and JavaScript with no authority of its
own; bypassing it gains nothing.

| Role | May |
| --- | --- |
| `USER` (any signed-up account, F-03) | Nothing beyond anonymous access. A report sent with a valid token records the subject. |
| `MODERATOR` | Read reports, songs, categories, media, releases, analytics, link previews; update a report's status and note |
| `ADMIN` | All of the above plus every write, the audit log, system view and route table |

No authorization decision relies on a hidden URL, a client flag or the UI.
`MODERATOR` versus `ADMIN` on each route was compared with the router source;
it matches the table in the route inventory below.

## Route inventory

`V` = `language` and `version` query parameters, validated by a strict zod schema
(unknown keys are rejected). All responses are JSON unless noted.

### Anonymous, read

| Method | Path | Limiter | Cache | Notes |
| --- | --- | --- | --- | --- |
| GET | `/` | none | no-store | Service banner with version |
| GET | `/health`, `/health/live`, `/health/ready`, `/api/v1/health` | none | no-store | F-11 |
| GET | `/api/v1/openapi.json` | none | 300 s | F-26 |
| GET | `/api/v1/hymn-versions` | none | 60 s | |
| GET | `/api/v1/hymn-versions/:version` (+ `/releases/latest`) | none | 60 s | |
| GET | `/api/v1/manifest` | none | 60 s | Carries `release.minimumAppVersion` |
| GET | `/api/v1/categories` | none | 60 s | |
| GET | `/api/v1/songs` | none | 60 s | 56 KB; `page × pageSize ≤ 10 000` |
| GET | `/api/v1/songs/:songId` | none | 300 s | |
| GET | `/api/v1/songs/:songId/audio` | none | 60 s | Metadata only |
| GET | `/api/v1/downloads/sheet-music`, `/downloads/audio` | none | — | Bundle metadata; both report `available: false` today |
| GET | `/api/v1/downloads/sheet-music/pages` | search (60/min) | — | 170 KB: all 401 pages with size, checksum and download URL |
| GET | `/api/v1/search` | search (60/min) | 30 s | `q` 1–200 chars; LIKE wildcards escaped |
| GET | `/api/v1/sync` | sync (60/min) | private, no-store | `limit ≤ 500`; cursor validated against the requested window |
| GET, HEAD | `/api/v1/songs/:songId/audio/file`, `/api/v1/audio/:songId` | item (600/min) | private | 302 to signed URL |
| GET, HEAD | `/api/v1/songs/:songId/sheet-music/pages/:pageNumber/file` | item (600/min) | private | 302 to signed URL |
| GET, HEAD | `/api/v1/downloads/sheet-music/file`, `/downloads/audio/file`, `/audio/package/:releaseVersion` | download (20/min) | private | 404 today (`SHEET_MUSIC_NOT_AVAILABLE`, `AUDIO_PACKAGE_NOT_AVAILABLE`): no bundle is published |
| GET | `/api/*` legacy equivalents | as above | — | `Deprecation: true`; read-only; `/api/songs` returns 363 KB with lyrics and uses the search limiter |

### Anonymous, write

| Method | Path | Limiter | Body | Notes |
| --- | --- | --- | --- | --- |
| POST | `/api/v1/reports` | 20/hour | `category`, `message ≤ 4000`, optional `songId`, `contact ≤ 200`, `context` | Stores no IP or user agent |
| POST | `/api/v1/analytics/events` | 1000/hour | `eventType`, optional `songId`, `metadata` | Anonymous counts |

Body limit is 100 KB (`express.json`). Neither write route was exercised with a
valid body, to avoid adding rows to production.

### Shared secret

| Method | Path | Limiter | Notes |
| --- | --- | --- | --- |
| GET | `/api/v1/internal/maintenance` | 20/hour | Fails closed without `CRON_SECRET`; constant-time compare. **Unreachable with its own credential: F-01.** |

### Administrative (24 route patterns)

| Area | Read (role) | Write (role) |
| --- | --- | --- |
| Reports | list, get (MODERATOR) | PATCH status and note (MODERATOR) |
| Categories | list (MODERATOR) | PUT, DELETE (ADMIN) |
| Songs | list, get (MODERATOR) | PATCH (ADMIN) |
| Song links | previews, suggestions list (MODERATOR) | link, unlink, remove similar, generate, decide (ADMIN) |
| Renumber | preview (MODERATOR) | execute (ADMIN) |
| Audio link | candidates (ADMIN) | attach, detach (ADMIN) |
| Media, releases | list (MODERATOR) | none: read-only by design |
| Analytics | read (MODERATOR) | — |
| Minimum app version | read (MODERATOR) | PUT (ADMIN) |
| System, routes, audit log | read (ADMIN) | — |

Admin writes use a separate 600/hour limiter. Admin reads have none, and the
report and audit-log lists lack the offset bound the song list has
(`content-schemas.ts:201-220, 396-401`); this needs a valid token to matter.

Destructive operations, all `ADMIN` and audited: song merge on renumber
(withdraws a hymn and may delete its audio link row), linking two works as the
same (deletes one `works` row after copying its links), detaching audio (link
row only). No route uploads, replaces or deletes a stored object, and none
manages users or roles.

`PUT /admin/minimum-app-version` deserves a note: one request changes what every
installed app is told about needing an update. It is audited and reversible.

## Direct-access scenario

An attacker who never opens the app and talks to the API directly can:

- read everything the app can read: the full catalogue with lyrics for four editions, and metadata for every media file;
- obtain a 15-minute signed URL for any audio track or sheet page, at up to 600 per minute per address;
- post bug reports (20 per hour per address) and analytics events (1000 per hour per address);
- read service version, environment and memory figures from `/health`.

They cannot:

- reach any admin route (401);
- read or write the database through Supabase's Data API with the public key;
- list or read the bucket without a signature;
- change the limiter bucket with `X-Forwarded-For` (tested).

This is the same access the mobile app has, which is the intended design: the
content is public.

## CORS and CSRF

- **CORS is browser access control, not API authorization.** A non-browser client ignores it. The server additionally rejects requests carrying a disallowed `Origin` with 403 (`app.ts:46-58`); a caller simply omits the header.
- Production requires an explicit origin list (`config/index.ts:434-445`). Allowed methods are GET, HEAD, POST, OPTIONS, so a cross-origin page cannot preflight PATCH, PUT or DELETE to admin routes.
- Live: `Origin: https://evil.example` returned 403 with no `Access-Control-Allow-Origin`.
- **CSRF is not relevant.** No cookie is used anywhere; the admin token travels in a header that a cross-site form cannot set.

## Rate limiting

| Property | Finding |
| --- | --- |
| Identity | Client IP via `trust proxy` hops (default 1) |
| Store | Upstash Redis, required in production unless explicitly waived |
| Spoofing | `X-Forwarded-For`, `X-Real-IP`, `Forwarded` did not change the bucket in a 14-request test |
| Failure mode | `passOnStoreError: true`: if Redis is down, requests are allowed (F-12) |
| Shared addresses | A congregation on one Wi-Fi shares one bucket; limits were sized for that |
| Coverage gap | Catalogue read routes and `/health` have no limiter (F-12) |

Edge caching interacts with limits: an identical search URL repeated within 30
seconds was served from the Vercel cache (`X-Vercel-Cache: HIT`) and did not
consume budget.

## Security headers (live)

`Strict-Transport-Security: max-age=31536000; includeSubDomains`,
`X-Content-Type-Options: nosniff`, `X-Frame-Options: SAMEORIGIN`,
`Referrer-Policy: no-referrer`, `Cross-Origin-Opener-Policy` and
`Cross-Origin-Resource-Policy: same-origin`, a restrictive CSP, and no
`X-Powered-By`. `/admin` tightens the CSP further and adds a single
`connect-src` for the Supabase origin. Nothing is missing that matters for a
JSON API.

## Error disclosure

Validation errors return field path and message only. Unknown errors return a
generic code (`INTERNAL_SERVER_ERROR`, `DATABASE_ERROR`) with no stack, SQL or
path. Request logs record method, path without query string and a request id.
One input produced a 500 (F-16).

## Findings from this area

F-01, F-03, F-11, F-12, F-13, F-16, F-26. Details in SECURITY-FINDINGS.md.
