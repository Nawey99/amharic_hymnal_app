# Threat Model

Audit date: 2026-10-01.

## System

```text
Flutter app (Android, iOS, web, desktop)
   |  HTTPS, no credentials, JSON
   v
Hymnal API on Vercel (Express, one serverless function, region fra1)
   |-- Prisma, owner role ----> Supabase PostgreSQL (pooler)
   |-- S3 API, signs GetObject -> Supabase Storage, private bucket "hymnal-media"
   |-- REST ------------------> Upstash Redis (rate-limit counters)
   |-- JWKS ------------------> Supabase Auth (admin tokens only)

App download: API answers 302 -> 15-minute signed URL -> Supabase Storage (behind Cloudflare)

Operator browser --> /admin (static page) --> Supabase Auth (password) --> API /api/v1/admin/*
GitHub Actions --> Vercel deploy; daily pg_dump
Beta builds only --> Sentry
```

**Correction to the assumed architecture.** The brief names Cloudflare R2. The
signed URL the API issues points at `<project>.supabase.co/storage/v1/s3/…`,
so media is in **Supabase Storage**, reached through its S3-compatible
endpoint. Cloudflare appears only as Supabase's CDN (`Server: cloudflare`).
Sections of this audit that say "object storage" mean that bucket.

## Trust boundaries

| # | Boundary | What crosses it | Who is trusted |
| --- | --- | --- | --- |
| B1 | Device ↔ API | Catalogue JSON in; bug reports and view counts out | The app trusts the API completely for content. The API trusts nothing from the app. |
| B2 | Device ↔ storage | Media bytes via signed URL | The app verifies size and SHA-256 supplied by the API. |
| B3 | Other apps ↔ this app (Android/iOS) | Launcher intent, media buttons, media browser binding | Nothing external is trusted; no deep links exist. |
| B4 | Operator browser ↔ API | Supabase JWT in `Authorization` | The API verifies signature, issuer, audience and role. |
| B5 | API ↔ database, storage, Redis | Privileged credentials held in Vercel environment | Full trust; the API is the only path. |
| B6 | Scheduler ↔ API | `CRON_SECRET` | Shared secret (currently not reaching its handler, F-01). |
| B7 | CI ↔ production | Vercel token, direct database URL | GitHub secrets. |
| B8 | Developer workstation | `.env.production`, dumps, keystore | Whoever can read the disk (F-02, F-14). |

## Data classification

| Data | Class | Where | Client can read | Client can write |
| --- | --- | --- | --- | --- |
| Lyrics, titles, categories, edition list | Public | Bundled JSON, API, device cache | Yes | No |
| Audio, sheet-music pages | App-distributed, not secret | Private bucket, device cache | Yes, through the API | No |
| File sizes, checksums, file names | Public metadata | API | Yes | No |
| Storage keys, bucket name | Internal | Database, admin API only | Not from the public API (it is visible in the signed URL) | No |
| Favourites, history, settings | Personal, low sensitivity | Device only | n/a | n/a |
| Bug report text and optional contact | Personal | Device queue until sent, then database | Own device only | Create only |
| View counts, search text | Anonymous | Database | No | Create only |
| Admin audit log, user profiles | Internal | Database | No | No |
| Database URL, storage keys, cron secret, Redis token | Privileged | Vercel env, local files | No | No |
| Supabase anon key, project URL | Public by design | `/admin/app.js` | Yes | n/a |
| Upload keystore | Privileged | Local disk | No | No |

What the app **can** reach matches what it **should** reach: public content,
signed downloads, and two write-only endpoints. No difference was found between
intended and actual client access.

## Threat actors

| Actor | Capability | Target | Surface | Consequence if successful | Existing control | Remaining risk |
| --- | --- | --- | --- | --- | --- | --- |
| A. Ordinary user | Uses the app | Content | UI | None | n/a | None |
| B. Technical user | Reads app storage | Cached catalogue, media | App support directory | Copies content they already have | Content is not secret | None |
| C. Network observer of own device | Proxy with own CA | API traffic | HTTPS | Sees public JSON and their own report | TLS; no tokens in traffic | None; pinning would add nothing (see NETWORK-TLS-AUDIT.md) |
| D. APK decompiler | `strings`, `aapt2`, jadx | Secrets, endpoints | Release APK | Learns the API root and route names | No secret in the binary | Negligible (F-20) |
| E. iOS bundle inspector | Same, on IPA | Same | IPA | Same | Same | Not verified (REQUIRES MAC) |
| F. Local modifier | Patched app, rooted phone | Local flags, screenshots | Prefs, `FLAG_SECURE` | Removes screenshot block; flips cosmetic flags | No authorization depends on the client | Accepted: sheet music is not DRM content |
| G. Direct API caller | curl | Every route | `/api/v1/*`, `/api/*`, `/admin` | Reads public catalogue; posts reports and events | Validation, role gates | Report and analytics spam within limits |
| H. Automated caller | Scripts, many requests | Availability, cost | Unlimited read routes | Database load, Vercel usage | Limiters on costly routes; 60 s cache headers | F-12: catalogue routes unlimited; limiters fail open |
| I. Malicious third party | Sign-up, forged tokens, injection | Admin surface, database | Supabase Auth, admin routes | Content tampering | JWKS verification, role claim, parameterised SQL, RLS plus revoked grants | F-03: open sign-up leaves one claim between a stranger and the admin API |
| J. Media scraper | Calls download routes | All audio and sheet music | `/songs/:id/audio/file`, page routes | Bulk copy | 600 per minute limiter; 15-minute URLs | Accepted: the same files are given to every user |
| K. Local state manipulator | Edits prefs and cache files | App behaviour | SharedPreferences, `content_cache/*.json` | Their own app shows altered content | Nothing server-side depends on it | None |
| L. Someone with workstation or repo access | Reads local files, CI artifacts | Production credentials, dumps | Disk, GitHub artifacts | Full backend compromise | Files are untracked; repo is private | F-02, F-04, F-14, F-15 |

## What is trusted to the client

Nothing that matters. The client decides:

- whether to show the "please update" prompt (`AppUpdateService`); skipping it only leaves the user on an old build;
- whether the contribution link is shown (`contribution_unlocked`); it is a GitHub link;
- whether screenshots are blocked on the sheet-music screen; a courtesy, not a control;
- which edition is selected; every edition is public.

No role, entitlement, price or download permission is evaluated on the device.

## Attack surface summary

- **Mobile:** one exported launcher activity, one media-browser service, one media-button receiver, three leftover test activities (F-05). No deep links, URL schemes, WebView with app content, or exported providers.
- **API:** 53 paths in the public OpenAPI document. Anonymous: 21 read routes under `/api/v1`, 2 write routes, the legacy `/api` read routes, root health routes and the admin page shell. Authenticated: 24 admin route patterns. Shared-secret: 1 cron route.
- **Storage:** signed GET only.
- **Supply chain:** pub.dev, npm, Maven Central/Google, GitHub Actions, Vercel CLI.
- **People and machines:** one developer workstation, two GitHub repositories.
