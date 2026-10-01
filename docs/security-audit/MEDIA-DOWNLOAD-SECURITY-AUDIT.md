# Media and Download Security Audit

Audit date: 2026-10-01.

## Storage architecture as found

Media is **not** in Cloudflare R2. The redirect the API issues points at
`https://<project>.supabase.co/storage/v1/s3/hymnal-media/…`: Supabase Storage,
through its S3-compatible endpoint, fronted by Cloudflare as a CDN. The backend
code is storage-agnostic (`S3StorageService`), so the R2 assumption in the brief
is simply out of date. Everything below was tested against the real bucket.

| Property | Finding | Evidence |
| --- | --- | --- |
| Bucket visibility | Private | Unsigned GET of a known key: 403 `AccessDenied`. `/storage/v1/object/public/hymnal-media/…`: `Bucket not found`. Anon-key bucket list: `[]`. |
| Access method | Presigned `GetObject`, SigV4 | `s3-storage-service.ts:169-191` |
| Lifetime | 900 seconds | `X-Amz-Expires=900`; `SIGNED_URL_TTL_SECONDS` default 900, range 60–86 400 |
| Scope | One object | Changing the path with the same signature: 403 |
| Method | GET only | `PUT` and `HEAD` with the GET URL: 403 |
| Signature check | Enforced | Altering 8 hex digits: 403 |
| Listing | Not possible | `?list-type=2` on the bucket path: 404 |
| Reuse | Any holder can use the URL until it expires, from any address | By design of presigned URLs |
| Expiry | Not waited out | NOT TESTED (would need a 15-minute wait; the mechanism is standard SigV4) |

### Object naming

`hymn-versions/<edition UUID>/releases/<release>/audio/tracks/<song id>/<file name>`

The path is predictable once one URL has been seen, and the edition UUID is in
public API responses. That does not matter: knowing a key gives nothing without
a signature, and the API will sign any published file for anyone who asks.

### Metadata visible on a download

`x-amz-meta-checksumsha256`, `x-amz-meta-mediatype`, `x-amz-meta-releaseversion`,
`ETag`, `Last-Modified`. The signed URL also shows the bucket name, the project
host and the storage access key **ID** (not the secret) in `X-Amz-Credential`.
All of this is normal for presigned URLs and none of it is a credential.

### Caching

- API redirect: `Cache-Control: private, max-age=0, must-revalidate`. The signed URL is never cached by a shared cache.
- Object: `public, max-age=31536000, immutable`, keyed by the full signed URL (`CF-Cache-Status: DYNAMIC` on the test), so it cannot be replayed from cache after expiry.
- The app does not store the redirect target (`local_media_cache_service.dart:179-180`).

## Protection level against the product requirement

The content is hymn audio and scanned sheet music that every user of a free app
may download. Nothing is paid, per-user or restricted. The implemented level
(private bucket, short signed URLs, per-address rate limit) is consistent with
"distributed through the app, not openly hot-linkable". DRM is not warranted,
and its absence is not a finding.

| Asset | Route | Protection | Assessment |
| --- | --- | --- | --- |
| Individual audio | `/songs/:id/audio/file`, `/audio/:id` | Signed URL, 600/min | Adequate |
| Sheet page | `/songs/:id/sheet-music/pages/:n/file` | Signed URL, 600/min | Adequate |
| Full audio bundle | `/downloads/audio/file` | 20/min | Not published (404) |
| Sheet-music bundle | `/downloads/sheet-music/file` | 20/min | Not published (404) |
| Page manifest | `/downloads/sheet-music/pages` | 60/min | Public metadata, 170 KB |
| Release manifest | `/manifest` | none | Public metadata |

A scraper can copy the whole library in a few minutes. That is the accepted
consequence of giving the same files to every user.

## Version isolation

| Check | Result |
| --- | --- |
| A 2004 song requested under `version=am-sda-1975` | 404 `SONG_NOT_FOUND` for metadata, audio file and sheet page |
| Object paths | Namespaced by edition UUID and release |
| App catalogue cache | One file per `<language>_<edition code>` (`edition_store.dart:114-117`); a stored copy is ignored if its `code` differs (`hymn_remote_data_source.dart:159`) |
| App media cache | Keyed by content SHA-256, deliberately shared between editions so a file used by two hymns is stored once |
| Favourites | Stored per edition (`favorite_hymns_by_version`) |
| Retired edition | `HYMN_VERSION_NOT_FOUND` deletes the stored copy (`:91-95`) |

Sharing media by checksum is safe because every edition is public; there is no
access level for one edition's file to leak across.

## Client download pipeline (`LocalMediaCacheService`)

| Concern | Finding | Evidence |
| --- | --- | --- |
| URL validation | `http` or `https` with an authority; any host | `media_reference.dart:73-77` (F-17) |
| Cleartext | Blocked on Android release by the manifest; iOS by ATS default | `AndroidManifest.xml:18`; no ATS exception in `Info.plist` |
| Redirects | Followed by `package:http`; target not stored | `:179-183` |
| Destination | `<app support>/media_cache/<type>/` | `_directoryFor`; type sanitised to `[A-Za-z0-9_-]` |
| File name, with checksum | `<sha256><ext>`; checksum must match `^[0-9a-f]{64}$`, extension `^\.[a-z0-9]{1,5}$` | `:26-27, 62-77, 273-279` |
| File name, without checksum | `<8-hex FNV hash>-<basename>` with everything outside `[A-Za-z0-9._-]` replaced | `:282-290` |
| Path traversal | Not possible: no path separator survives either branch, and the hash prefix means a basename of `..` cannot stand alone | Code |
| Server-supplied `fileName` | Used only to choose the extension | `_extensionFor` |
| Temporary file | `<target>.<microseconds>.part` in the same directory | `:173-175` |
| Atomic write | Rename after full verification; `.part` deleted on any error | `:228-234` |
| Partial download | Rejected if bytes ≠ `Content-Length` or ≠ API `sizeBytes` | `:204-214` |
| Integrity | SHA-256 streamed during download and compared before rename | `:189-218` |
| Corrupt cached file | Re-validated by size on every read; mismatch deletes it | `:139-147` |
| Duplicate download | An existing verified file is returned without a request | `:164-169` |
| Resume | Not implemented; each file restarts | By design, files are under 2 MB |
| Content type | Not checked against bytes; decoder failure is handled by the viewer | — |
| Size ceiling | None when the API gives no size (F-18) | `:193-198` |
| Concurrency | Six parallel files | `offline_media_download.dart:44` |
| Pruning | Files whose checksum no stored edition references are deleted; skipped entirely if any stored edition is unreadable | `hymn_remote_data_source.dart:195-208` |

### Is the checksum authoritative?

The checksum, the size and the download URL all come from the same API response.
So verification protects against corruption in transit, a wrong object in the
bucket, CDN tampering and a truncated file. It does **not** protect against a
compromised API, which could supply a matching checksum for malicious bytes.
That is the correct boundary for this design: the API is the root of trust and
nothing on the device can be more authoritative. The files are decoded as audio
and images, never executed.

Files without a checksum are not verified (`MediaSource.isVerifiable`). Every
file in the live sync response carried one.

## Archives

No ZIP or other archive is downloaded or extracted by the app. The Dart sources
contain no archive library and no extraction code, and the bundle routes return
404. **No zip-slip or decompression-bomb surface exists.**

## Catalogue storage (`FileEditionStore`)

Synced editions are written as JSON to `<app support>/content_cache/<key>.json`
with the key sanitised to `[A-Za-z0-9_-]`, using write-aside-and-rename. A
damaged file is treated as absent and re-synced. The content is public.

## Direct-access scenario

Someone who learns an object path, a media URL, a manifest URL or the signed-URL
pattern gains nothing beyond what the public API already hands out:

- a path without a signature is refused;
- a signed URL works for one object for at most 15 minutes;
- no bucket, listing or write capability is reachable;
- there is no content in the bucket that the API would refuse to sign, as far as the published catalogue shows. Whether the bucket also holds unpublished or withdrawn objects could not be checked (REQUIRES BACKEND ACCESS).

## Findings from this area

F-17, F-18 and F-25 (all INFO). No finding of LOW or above concerns media
delivery.
